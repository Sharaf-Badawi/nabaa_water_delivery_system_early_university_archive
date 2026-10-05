import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'package:http/http.dart' as http;
import 'package:water_delivery_app/contollers/productController.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:water_delivery_app/main.dart';

class ManualStationSelection extends StatefulWidget {
  final String userId;

  ManualStationSelection({required this.userId});

  @override
  _ManualStationSelectionState createState() => _ManualStationSelectionState();
}

class _ManualStationSelectionState extends State<ManualStationSelection> {
  List<Map<String, dynamic>> availableStations = [];
  List<Map<String, dynamic>> filteredStations = []; // For search functionality
  LatLng? userSavedLocation;
  String? userFloor; // To store the user's floor
  String searchQuery = ''; // For search input
  final ProductController productController = Get.find();
  bool isLoading = false; // GetX controller for products
  bool isVoucherActive = false;
  double voucherValue = 0.0;
  DateTime? voucherExpiryDate;
  String lang = 'ar';

  @override
  void initState() {
    super.initState();
    _checkExistingOrder();
    _loadUserSavedLocation();
    _fetchVoucherData();
    getPreference();
  }
Future<void> getPreference() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      lang = prefs.getString('language_code') ?? 'ar';
    });
}
  // Function to check for any existing orders
  Future<void> _checkExistingOrder() async {
    try {
      QuerySnapshot existingOrderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status',
              whereIn: ['Pending', 'InProgress']) // Check for pending orders
          .limit(1)
          .get();

      if (existingOrderSnapshot.docs.isNotEmpty) {
        _showOrderExistsDialog(); // If an active order exists
      } else {
        fetchAvailableStations(); // Fetch stations if no active orders
      }
    } catch (e) {
      Get.snackbar('Error',
          'Failed to check existing orders. Please check your connection.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _fetchVoucherData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (userDoc.exists) {
        double currentVoucherValue = userDoc['voucher_value'] ?? 0.0;
        bool isVoucherActive = prefs.getBool('isVoucherActive') ?? false;
        Timestamp? expiryTimestamp = userDoc['voucher_expiry_date'];

        DateTime now = DateTime.now();
        DateTime? expiryDate = expiryTimestamp?.toDate();

        if (expiryDate != null && expiryDate.isBefore(now)) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'voucher_value': 0.0,
          });
          voucherValue = 0.0;
          voucherExpiryDate = expiryDate;
        } else {
          voucherValue = currentVoucherValue;
          voucherExpiryDate = expiryDate;
        }

        setState(() {
          this.isVoucherActive = isVoucherActive;
        });
      }
    } catch (e) {
      print('Error fetching voucher data: $e');
    }
  }

  Future<void> _showOrderExistsDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.order_in_progress),
          content: Text('${AppLocalizations.of(context)!.already_order}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(() => Home());
              },
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserSavedLocation() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        if (userDoc['location'] != null) {
          GeoPoint location = userDoc['location'];
          setState(() {
            userSavedLocation = LatLng(location.latitude, location.longitude);
          });
        }

        if (userDoc['floor'] != null) {
          setState(() {
            userFloor = userDoc['floor'];
          });
          fetchAvailableStations(); // Fetch stations once we have user's floor data
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Add search logic to filter stations
  void _filterStations(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStations =
            availableStations; // Show all stations if no search query
      } else {
        filteredStations = availableStations
            .where((station) => station['stationName']
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> fetchAvailableStations() async {
    if (userSavedLocation == null || userFloor == null) return;

    try {
      TimeOfDay currentTime = TimeOfDay.now();
      QuerySnapshot stationsSnapshot =
          await FirebaseFirestore.instance.collection('stations').get();
      List<Map<String, dynamic>> fetchedStations = [];

      for (var station in stationsSnapshot.docs) {
        List<dynamic> locations = station['locations'];

        for (var location in locations) {
          Timestamp activeFrom = location['active_from'];
          Timestamp activeUntil = location['active_until'];
          GeoPoint stationLocation = location['location'];

          TimeOfDay start = _extractTimeFromTimestamp(activeFrom);
          TimeOfDay end = _extractTimeFromTimestamp(activeUntil);

          if (_isTimeInRange(currentTime, start, end) && !station['stopped']) {
            double distance = calculateDistance(
              userSavedLocation!.latitude,
              userSavedLocation!.longitude,
              stationLocation.latitude,
              stationLocation.longitude,
            );

            if (distance <= 10000) {
              List<dynamic> products = location['products'];
              bool allProductsAvailable = _checkProductsAvailable(products);

              if (allProductsAvailable) {
                fetchedStations.add({
                  'stationId': station.id,
                  'stationName': station['name'],
                  'distance': distance,
                  'location': stationLocation,
                  'products': products,
                });
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          availableStations = fetchedStations;
          filteredStations =
              fetchedStations; // Set filtered stations initially to all stations
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch stations.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  bool _checkProductsAvailable(List<dynamic> products) {
    List<dynamic> selectedProductIds =
        productController.selectedProducts.keys.toList();
    for (String productId in selectedProductIds) {
      if (!products.any((product) => product['product_id'] == productId)) {
        return false;
      }
    }
    return true;
  }

  // Extract TimeOfDay from Firestore Timestamp
  TimeOfDay _extractTimeFromTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  bool _isTimeInRange(TimeOfDay currentTime, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  // Calculate distance in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Earth's radius in meters
    double phi1 = lat1 * (pi / 180);
    double phi2 = lat2 * (pi / 180);
    double deltaPhi = (lat2 - lat1) * (pi / 180);
    double deltaLambda = (lon2 - lon1) * (pi / 180);

    double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
        cos(phi1) * cos(phi2) * (sin(deltaLambda / 2) * sin(deltaLambda / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c / 1000; // Return distance in kilometers
  }

  // Show pricing and confirmation dialog with product details
  Future<void> _showPricingDialog(Map<String, dynamic> station) async {
    double totalCost = _calculateTotalCost(station['products']);
    double discount = 0.0;

    if (isVoucherActive &&
        voucherValue > 0 &&
        (voucherExpiryDate == null ||
            voucherExpiryDate!.isAfter(DateTime.now()))) {
      double maxDiscount = totalCost / 2;
      discount = voucherValue > maxDiscount ? maxDiscount : voucherValue;
      totalCost -= discount;
    }

    List<Map<String, dynamic>> productDetails =
        await _getProductDetails(station['products']); // Fetch titles

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.lightBlueAccent,
          title: Text(AppLocalizations.of(context)!.chosen_station,
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${AppLocalizations.of(context)!.do_you_want_station} ${station['stationName']} ${AppLocalizations.of(context)!.question}',
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 10),
                Text("${AppLocalizations.of(context)!.products}: ",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Column(
                  children: productDetails.map((product) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${product['title']} (${product['quantity']})',
                            style: TextStyle(color: Colors.white)),
                        Text('${product['cost']} JD',
                            style: TextStyle(color: Colors.white)),
                      ],
                    );
                  }).toList(),
                ),
                Divider(color: Colors.white),
                if (discount > 0)
                  Text(
                      '${AppLocalizations.of(context)!.discount} ${discount.toStringAsFixed(2)} JD',
                      style: TextStyle(color: Colors.white)),
                Text(
                    '${AppLocalizations.of(context)!.total_cost} ${totalCost.toStringAsFixed(2)} JD',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                savefirstorder(); // Close dialog
                await _placeOrder(station, totalCost, discount);
              },
              child: Text(AppLocalizations.of(context)!.confirm_order,
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Retrieve product details including quantity and cost
  Future<List<Map<String, dynamic>>> _getProductDetails(
      List<dynamic> products) async {
    List<Map<String, dynamic>> productDetails = [];
    List<dynamic> selectedProductIds =
        productController.selectedProducts.keys.toList();

    for (String productId in selectedProductIds) {
      var product = products.firstWhere((p) => p['product_id'] == productId,
          orElse: () => null);
      int productQuantity = productController.selectedProducts[productId] ?? 1;

      // Fetch the product title from Firestore using product ID
      var productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (product != null && productDoc.exists) {
        // Get product title from the document
        String productTitle =lang == 'ar' ?  productDoc['title'] : productDoc['title_en']?? 'No Title';

        // Get the cost from station's floor prices
        double cost = product['floor_prices'][userFloor] * productQuantity;

        // Add product details to the list
        productDetails.add({
          'title': productTitle,
          'quantity': productQuantity,
          'cost': cost,
        });
      }
    }

    return productDetails;
  }

  // Calculate total cost based on selected products and their prices
  double _calculateTotalCost(List<dynamic> products) {
    double totalCost = 0.0;
    List<dynamic> selectedProductIds =
        productController.selectedProducts.keys.toList();

    for (String productId in selectedProductIds) {
      var product = products.firstWhere((p) => p['product_id'] == productId,
          orElse: () => null);
      int productQuantity = productController.selectedProducts[productId] ?? 1;

      if (product != null &&
          product['floor_prices'] != null &&
          product['floor_prices'][userFloor] != null) {
        totalCost += product['floor_prices'][userFloor] * productQuantity;
      }
    }

    return totalCost;
  }

  // Place the order after confirmation
  // Place the order after confirmation
  Future<void> _placeOrder(
      Map<String, dynamic> station, double totalCost, double discount) async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      int currentLoyalty = userDoc['loyalty'] ?? 0;
      int totalQuantity = productController.selectedProducts.values
          .fold<int>(0, (int sum, quantity) => sum + (quantity as int));
      int newLoyalty = currentLoyalty + totalQuantity;

      double newVoucherValue = voucherValue - discount;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference orderRef =
          FirebaseFirestore.instance.collection('orders').doc();
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      batch.set(orderRef, {
        'userId': widget.userId,
        'stationId': station['stationId'],
        'totalCost': totalCost,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'products': productController.selectedProducts,
        'discount': discount,
      });

      batch.update(userRef, {
        'loyalty': newLoyalty,
        'lastOrder': FieldValue.serverTimestamp(),
        'voucher_value': newVoucherValue,
      });

      await batch.commit();

      // Notify the provider via the Cloud Function
      await _sendNotificationToProvider(
        providerId: station['stationId'],
        entity: 'stations',
        title: 'طلب جديد!',
        description: 'لديك طلب بقيمة ${totalCost}',
        title_en: 'New Order!',
        description_en: 'You have a new order worth ${totalCost} JD.',
      );

      Get.snackbar('', '${AppLocalizations.of(context)!.order_placing}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 6));
      Get.offAll(() => Home()); // Navigate to Home screen
    } catch (error) {
      Get.snackbar('Error', '${AppLocalizations.of(context)!.order_error}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> savefirstorder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('had_ordered') == null)
      prefs.setBool('had_ordered', true);
  }

  Future<void> _sendNotificationToProvider({
    required String providerId,
    required String entity,
    required String title,
    required String description,
    required String title_en,
    required String description_en,
  }) async {
    const String cloudFunctionUrl =
      String.fromEnvironment(
        'NOTIFICATION_FUNCTION_URL',
        defaultValue: 'https://example.invalid/sendNotification',
      );

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'providerId': providerId,
          'entity': entity,
          'title': title,
          'description': description,
          'title_en': title_en,
          'description_en': description_en
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully!');
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending notification: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(AppLocalizations.of(context)!.select_station),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    cursorColor: Colors.lightBlueAccent,
                    onChanged: _filterStations,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: AppLocalizations.of(context)!.search_station,
                      prefixIcon: Icon(Icons.search),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredStations.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.lightBlueAccent,
                            color: Colors.white,
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredStations.length,
                          itemBuilder: (context, index) {
                            var station = filteredStations[index];
                            return Card(
                              child: ListTile(
                                title: Text(station['stationName']),
                                subtitle: Text(
                                    '${AppLocalizations.of(context)!.distance} ${(station['distance']).toStringAsFixed(2)} km'),
                                onTap: () {
                                  _showPricingDialog(
                                      station); // Show pricing dialog with product details
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
