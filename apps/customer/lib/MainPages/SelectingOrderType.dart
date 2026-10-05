import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/AuthPages/Login.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'dart:math';
import 'package:water_delivery_app/contollers/productController.dart';
import 'package:water_delivery_app/MainPages/manual.dart';



class SelectingOrderType extends StatefulWidget {
  final String userId;

  SelectingOrderType({required this.userId});

  @override
  _SelectingOrderTypeState createState() => _SelectingOrderTypeState();
}

class _SelectingOrderTypeState extends State<SelectingOrderType> {
  List<Map<String, dynamic>> availableStations = [];
  final ProductController productController = Get.find(); // GetX controller
  String? userFloor; // To store user's floor
  GeoPoint? userLocation;
  bool isLoading = false;// Store user location
  bool isVoucherActive = false; double voucherValue = 0.0; DateTime? voucherExpiryDate;

  @override
  void initState() {
    super.initState();
    checkuserLogingin();
    _checkExistingOrder();
    _loadUserData(); // Load user data
    _fetchVoucherData();
  }
  Future<void> _fetchVoucherData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(widget.userId).get();
SharedPreferences prefs = await SharedPreferences.getInstance();
      if (userDoc.exists) {
        double currentVoucherValue = userDoc['voucher_value'] ?? 0.0;
        bool isVoucherActive = prefs.getBool('isVoucherActive') ?? false;
        Timestamp? expiryTimestamp = userDoc['voucher_expiry_date'];

        DateTime now = DateTime.now();
        DateTime? expiryDate = expiryTimestamp?.toDate();

        if (expiryDate != null && expiryDate.isBefore(now)) {
          await FirebaseFirestore.instance.collection('users').doc(
              widget.userId).update({
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



    Future<void> checkuserLogingin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if( FirebaseAuth.instance.currentUser == null || !isLoggedIn){
      _showLoginginDialog();
    }

  }
  Future<void> _showLoginginDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,

          child: AlertDialog(
            backgroundColor: Colors.lightBlueAccent,
            title: Text(AppLocalizations.of(context)!.no_account,style: TextStyle(color: Colors.white),),
            content: Container(
              height: 50,
              child: Text(AppLocalizations.of(context)!.dont_worry,style: TextStyle(fontSize: 15,color: Colors.white),),),
            actions: [
              TextButton(
                onPressed: () {
                  Get.offAll(() =>
                      Login());
                },
                child: Text(AppLocalizations.of(context)!.ok,style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkExistingOrder() async {
    try {
      QuerySnapshot existingOrderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: 'Pending') // Check for pending orders
          .limit(1)
          .get();

      if (existingOrderSnapshot.docs.isNotEmpty) {
        // User has an active pending order
        _showOrderExistsDialog();
      }
    } catch (e) {

    }
  }
Future<void> savefirstorder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getBool('had_ordered') == null)
      prefs.setBool('had_ordered', true);
}
  Future<void> _showOrderExistsDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,

          child: AlertDialog(
            title: Text(AppLocalizations.of(context)!.order_in_progress),
            content: Text(AppLocalizations.of(context)!.already_order),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.offAll(() =>
                      Home());
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        // Fetch user location and floor
        setState(() {
          userLocation = userDoc['location'];
          userFloor = userDoc['floor'];
        });
      } else {

      }
    } catch (e) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:isLoading ? Center(child: CircularProgressIndicator(color: Colors.white,),) :  Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent.shade700 , Colors.lightBlueAccent.shade200] , begin: Alignment.topLeft, end: Alignment.bottomRight)
          ),
        child: ListView(

          children: [
            Padding(
              padding: EdgeInsets.only(top: 100, bottom: 150),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.choosing_delivery,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => ManualStationSelection(userId: widget.userId));
                    },
                    child: Text(AppLocalizations.of(context)!.manual_selection,
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 70, vertical: 20)),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await automaticStationSelection();
                    },
                    child: Text(AppLocalizations.of(context)!.automatic_selection,
                        style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 70, vertical: 20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> automaticStationSelection() async {
    if (userFloor == null || userLocation == null) {
      Get.snackbar('Error', 'User data is missing',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      // Fetch available stations from Firestore
      QuerySnapshot stationsSnapshot =
      await FirebaseFirestore.instance.collection('stations').get();

      if (stationsSnapshot.docs.isEmpty) {
        Get.snackbar(AppLocalizations.of(context)!.error,
            AppLocalizations.of(context)!.no_station,
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      availableStations = stationsSnapshot.docs.map((doc) {
        var stationData = doc.data() as Map<String, dynamic>;
        stationData['stationId'] = doc.id;
        return stationData;
      }).toList();

      var bestStation = _selectBestStation(userLocation!);

      if (bestStation != null) {
        _showConfirmationDialog(bestStation);
      } else {
        Get.snackbar(AppLocalizations.of(context)!.no_station,
            AppLocalizations.of(context)!.no_suitable_station,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {

    }
  }

  Map<String, dynamic>? _selectBestStation(GeoPoint userLocation) {
    Map<String, dynamic>? bestStation;
    double bestScore = -1;

    for (var station in availableStations) {
      List<dynamic> locations = station['locations'];
      for (var location in locations) {
        // Check station active time
        if (!_isStationActive(
            location['active_from'], location['active_until'])) continue;
        if(station.containsKey('stopped') && station['stopped'] ){
            continue;
        }
        GeoPoint stationLocation = location['location'];
        List<dynamic> products = location['products'];
        double distance = calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            stationLocation.latitude,
            stationLocation.longitude);
        double cost = _calculateTotalCost(products);

        if (cost == -1) continue; // Skip if products are not available

        double score = _calculateStationScore(distance, cost);
        if (score > bestScore) {
          bestScore = score;
          bestStation = {
            'stationName': station['name'],
            'stationId': station['stationId'],
            'distance': distance,
            'totalCost': cost,
            'location': stationLocation,
          };
        }
      }
    }

    return bestStation;
  }

  bool _isStationActive(Timestamp activeFrom, Timestamp activeUntil) {
    TimeOfDay currentTime = TimeOfDay.now();
    TimeOfDay start = _extractTimeFromTimestamp(activeFrom);
    TimeOfDay end = _extractTimeFromTimestamp(activeUntil);
    return _isTimeInRange(currentTime, start, end);
  }

  double _calculateTotalCost(List<dynamic> products) {
    double totalCost = 0.0;
    List<dynamic> selectedProductIds =
    productController.selectedProducts.keys.toList();

    for (String productId in selectedProductIds) {
      var product = products.firstWhere((p) => p['product_id'] == productId,
          orElse: () => null);
      if (product == null) return -1; // Product not available

      int productQuantity = productController.selectedProducts[productId] ?? 1;
      if (product['floor_prices'] == null ||
          product['floor_prices'][userFloor] == null) return -1;

      totalCost += product['floor_prices'][userFloor] * productQuantity;
    }

    return totalCost;
  }

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

  double _calculateStationScore(double distance, double cost) {
    return (0.6 * (1 / distance)) + (0.4 * (1 / cost)); // Weighted formula
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Earth's radius in meters
    double phi1 = lat1 * (pi / 180);
    double phi2 = lat2 * (pi / 180);
    double deltaPhi = (lat2 - lat1) * (pi / 180);
    double deltaLambda = (lon2 - lon1) * (pi / 180);

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c / 1000; // Return distance in kilometers
  }

  void _showConfirmationDialog(Map<String, dynamic> station) {
    double totalCost = station['totalCost'];
    double discount = 0.0;

    if (isVoucherActive && voucherValue > 0 && (voucherExpiryDate == null || voucherExpiryDate!.isAfter(DateTime.now()))) {
      double maxDiscount = totalCost / 2;
      discount = voucherValue > maxDiscount ? maxDiscount : voucherValue;
      totalCost -= discount;
    }

    Get.defaultDialog(
      backgroundColor: Colors.lightBlueAccent,
      titleStyle: TextStyle(color: Colors.white),
      title: '${AppLocalizations.of(context)!.station_selected}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${AppLocalizations.of(context)!.selection_desc}',
              style: TextStyle(color: Colors.white)),
          SizedBox(height: 10),
          Text('${AppLocalizations.of(context)!.station} ${station['stationName']}',
              style: TextStyle(color: Colors.white)),
          Text('${AppLocalizations.of(context)!.distance} ${station['distance'].toStringAsFixed(2)} ${AppLocalizations.of(context)!.km}',
              style: TextStyle(color: Colors.white)),
          if (discount > 0)
            Text('${AppLocalizations.of(context)!.discount} ${discount.toStringAsFixed(2)} JD', style: TextStyle(color: Colors.white)),
          Text('${AppLocalizations.of(context)!.total_cost} ${totalCost.toStringAsFixed(2)} ${AppLocalizations.of(context)!.jd}',
              style: TextStyle(color: Colors.white)),
        ],
      ),
      textConfirm: '${AppLocalizations.of(context)!.confirm_order}',
      textCancel: '${AppLocalizations.of(context)!.cancel}',
      buttonColor: Colors.black,
      cancelTextColor: Colors.black,
      onConfirm: () {
        savefirstorder();
        _placeOrder(station, totalCost, discount);
        Get.offAll(() => Home());
      },

    );
  }


  Future<void> _placeOrder(Map<String, dynamic> station, double totalCost, double discount) async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      int currentLoyalty = userDoc['loyalty'] ?? 0;
      int totalQuantity = productController.selectedProducts.values.fold<int>(0, (int sum, quantity) => sum + (quantity as int));
      int newLoyalty = currentLoyalty + totalQuantity;

      double newVoucherValue = voucherValue - discount;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      batch.set(orderRef, {
        'userId': widget.userId,
        'stationId': station['stationId'],
        'totalCost': totalCost,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
        'products': productController.selectedProducts,
        'discount': discount, // Include discount in the order document
      });

      batch.update(userRef, {
        'loyalty': newLoyalty,
        'lastOrder': FieldValue.serverTimestamp(),
        'voucher_value': newVoucherValue, // Update voucher value
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

      Get.snackbar('', '${AppLocalizations.of(context)!.order_placing}', backgroundColor: Colors.green, colorText: Colors.white, duration: Duration(seconds: 6));
      Get.offAll(() => Home()); // Navigate to Home screen
    } catch (error) {
      Get.snackbar('Error', '${AppLocalizations.of(context)!.order_error}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> _sendNotificationToProvider({
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
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'providerId': providerId,
          'entity' : entity,
          'title': title,
          'description': description,
          'title_en' : title_en,
          'description_en' : description_en
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully!');
      } else {
        print('Failed to send notification. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending notification: $error');
    }
  }
}
