import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:station_app/controllers/station.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersScreen extends StatefulWidget {
  final String stationId; // Pass station ID based on the logged-in station
  OrdersScreen({required this.stationId});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isProcessing = false; // To prevent duplicate button presses
  String _sortBy = 'None'; // Default sorting option
  final stationController = Get.find<StationController>();

  @override
  void initState() {
    super.initState();
    _monitorNewOrders();
  }

  // Monitor new orders with status 'Pending' for this station
  void _monitorNewOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('stationId', isEqualTo: widget.stationId)
        .where('status',
            isEqualTo: 'Pending') // Listen for orders in 'Pending' status
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            // A new order has been added; send a notification using OneSignal
          }
        }
      }
    });
  }

  // Function to send a new order notification using OneSignal REST API

  // Launch Google Maps with the user's location
  void _launchMaps(LatLng location) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      Get.snackbar('خطأ', 'خطأ لا يمكن الذهاب لجوجل مابس');
    }
  }

  // Launch Dialer with user's phone number
  Future<void> _callStation(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    } else {
      Get.snackbar('خطأ', 'خطا الحصول على رقم الهاتف');
    }
  }

  // Accept the order and update its status to "InProgress"
  Future<void> _acceptOrder(String orderId) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      DocumentSnapshot userdocs = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'InProgress',
      });
      String userId = userdocs['userId'];
      await _sendNotification(
        providerId: userId,
        entity: "users",
        title_en: "Order Accepted",
        description_en: "Your Order got Accepted!",
        title: "تم قبول الطلب!",
        description: "لقد تم قبول طلبك!",
      );
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ قبول الطلب');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _sendNotification({
    required String providerId,
    required String entity,
    required String title,
    required String description,
    required String title_en,
    required String description_en,
  }) async {
    const String cloudFunctionUrl = String.fromEnvironment(
      'NOTIFICATION_FUNCTION_URL',
      defaultValue: 'https://example.invalid/sendNotification',
    );
    try {
      final response = await http.post(Uri.parse(cloudFunctionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'providerId': providerId,
            'entity': entity,
            'title': title,
            'description': description,
            'title_en': title_en,
            'description_en': description_en
          }));
      if (response.statusCode == 200)
        print("success");
      else
        print(response.body);
    } catch (e) {
      print("Error: $e");
    }
  }

  // Reject the order and update its status to "Rejected"
  Future<void> _rejectOrder(String orderId) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      DocumentSnapshot userdocs = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      String userId = userdocs['userId'];
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'Rejected',
      });
      await _sendNotification(
          providerId: userId,
          entity: "users",
          title_en: "Order Rejected",
          description_en: "Your Order Got Rejected!",
          title: "تم رفض الطلب!",
          description: "لقد تم رفض طلبك!");
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ رفض الطلب');
      print(e);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Mark the order as completed
  Future<void> _completeOrder(String orderId) async {
    setState(() {
      _isProcessing = true;
    });

    try {

      // Fetch the order data
      DocumentSnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderSnapshot.exists) {
        Get.snackbar('خطأ', 'خطا ايجاد الطلب');
        return;
      }

      // Extract order data
      Map<String, dynamic> orderData =
          orderSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> products = orderData['products'] ?? {};
      double orderTotalCost = orderData['totalCost'] ?? 0.0;

      double commissionToAdd = 0.0;

      // Calculate the commission for each product
      for (String productId in products.keys) {
        int quantity = products[productId];

        // Commission: quantity * 0.06
        commissionToAdd += quantity * stationController.stationData['equity'];
      }

      // Update the order status to "Finished"
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'Finished',
      });

      // Add the completed timestamp
      orderData['completedTimestamp'] = FieldValue.serverTimestamp();

      // Add the order to CompletedOrders collection
      await FirebaseFirestore.instance
          .collection('CompletedOrders')
          .add(orderData);

      // Update the station data through the controller
      stationController.updateStationData(
        'commision',
        (stationController.stationData['commision'] ?? 0.0) + commissionToAdd,
      );

      stationController.updateStationData(
        'totalcosts',
        (stationController.stationData['totalcosts'] ?? 0.0) + orderTotalCost,
      );

      // Notify the user about the completion
      String userId = orderData['userId'];
      await _sendNotification(
          providerId: userId,
          entity: "users",
          title_en: "Order Delivered!",
          description_en: "Your Order has been delivered successfully!",
          title: "تم توصيل الطلب!",
          description: "لقد تم توصيل طلبك!");
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ انهاء الطلب');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الترتيب حسب: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  items: [
                    DropdownMenuItem(value: 'None', child: Text('بلا')),
                    DropdownMenuItem(value: 'Quantity', child: Text('الكمية')),
                    DropdownMenuItem(value: 'TotalCost', child: Text('المبلغ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('stationId', isEqualTo: widget.stationId)
                  .where('status', whereIn: ['Pending', 'InProgress']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return Center(child: Text('No orders available'));
                }
                orders = _sortOrders(orders);
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    var userId = order['userId'];
                    var status = order['status'];
                    var totalCost = order['totalCost'];
                    var orderId = order.id;
                    var discount = order['discount'] ?? 0.0; // Get the discount amount

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        var userData = userSnapshot.data!;
                        var userName =
                            '${userData['first_name'] ?? 'Unknown'} ${userData['last_name'] ?? 'Unknown'}';
                        var userPhone = userData['phone'] ?? 'N/A';
                        var apanum = userData['apartment_num'] ?? 'غير محدد';
                        var userBuilding =
                            userData['buildingName'] ?? 'Unknown Building';
                        var userFloor = userData['floor'] ?? 'N/A';
                        var userLocation = userData['location'];

                        if (userLocation == null) {
                          return Center(child: Text('User location not available'));
                        }

                        return Card(
                          margin: EdgeInsets.all(10),
                          color: Colors.lightBlue[50],
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الاسم:  $userName',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('المبنى: $userBuilding الطابق: $userFloor رقم الشقة: $apanum'),
                                Text('التكلفة:  $totalCost دينار '),
                                SizedBox(height: 10),
                                _buildProductList(order),
                                SizedBox(height: 20),
                                _buildActionButtons(
                                  context,
                                  status,
                                  orderId,
                                  userPhone,
                                  LatLng(userLocation.latitude, userLocation.longitude),
                                  stationController,
                                  discount, // Pass discount to the action buttons
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );


  }

  // Display list of products in the order
  Widget _buildProductList(QueryDocumentSnapshot order) {
    Map products = order['products'] ?? {};
    double discount = order['discount'] ?? 0.0;
    double totalCost = order['totalCost'] ?? 0.0;
    if (products.isEmpty) {
      return Text('No products available');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (discount > 0)
        Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'خصم: ${discount.toStringAsFixed(2)} دينار',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products.keys.elementAt(index);
          var quantity = products[product];
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .doc(product)
                .get(),
            builder: (context, productSnapshot) {
              if (!productSnapshot.hasData) return SizedBox.shrink();
              var productData = productSnapshot.data!;
              return Text(
                'طلب (${index + 1}) : ${productData['title']} - الكمية: $quantity',
                style: TextStyle(color: Colors.blue),
              );
            },
          );
        },
      ),
      if (discount > 0)
        Text(
          'المبلغ بعد الخصم: ${totalCost} دينار',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        )
    ]);
  }

  void _updateCommission(double discount, StationController stationController) {
    print("====================================");
    print(discount);
    print("====================================");

    double commissionToDeduct = discount ;
    print("====================================");
print(commissionToDeduct);
    print("====================================");
    print("====================================");
print( (stationController.stationData['commision'] ?? 0.0) - commissionToDeduct);
    stationController.updateStationData(
      'commision',
      (stationController.stationData['commision'] ?? 0.0) - commissionToDeduct,
    );
  }

  List<QueryDocumentSnapshot> _sortOrders(List<QueryDocumentSnapshot> orders) {
    if (_sortBy == 'Quantity') {
      orders.sort((a, b) {
        int totalA =
            (a['products'] as Map).values.reduce((sum, qty) => sum + qty);
        int totalB =
            (b['products'] as Map).values.reduce((sum, qty) => sum + qty);
        return totalB.compareTo(totalA); // Descending
      });
    } else if (_sortBy == 'TotalCost') {
      orders.sort(
          (a, b) => b['totalCost'].compareTo(a['totalCost'])); // Descending
    }
    return orders; // No sorting if 'None'
  }

  // Build action buttons based on order status
  Widget _buildActionButtons(
    BuildContext context,
    String status,
    String orderId,
    String userPhone,
    LatLng userLocation,
    StationController stationController,
    double discount,
  ) {
    if (status == 'Pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: _isProcessing ? null : () => _rejectOrder(orderId),
          ),
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: _isProcessing
                ? null
                : () {
                    _acceptOrder(orderId);

                  },
          ),
          IconButton(
            icon: Icon(Icons.map, color: Colors.blue),
            onPressed: () => _launchMaps(userLocation),
          ),
        ],
      );
    } else if (status == 'InProgress') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.phone, color: Colors.green),
            onPressed: () => _callStation(userPhone),
          ),
          IconButton(
            icon: Icon(Icons.map, color: Colors.blue),
            onPressed: () => _launchMaps(userLocation),
          ),
          ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () {
                    _completeOrder(orderId);
                    if (discount > 0) {
                      _updateCommission(discount, stationController);
                    }
                  },
            child: Text('إكمال الطلب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }
}
