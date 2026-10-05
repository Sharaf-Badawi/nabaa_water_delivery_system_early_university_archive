import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking internet connection
import 'package:url_launcher/url_launcher.dart';
import 'package:water_delivery_app/AuthPages/Login.dart';
import 'package:water_delivery_app/AuthPages/NamePage.dart';
import 'package:water_delivery_app/LegalPages/HelpPage.dart';
import 'package:water_delivery_app/MainPages/Account.dart';
import 'package:water_delivery_app/MainPages/PastOrders.dart';
import 'package:water_delivery_app/MainPages/choicescreen.dart';
import 'package:water_delivery_app/MainPages/coordinates.dart';
import 'package:water_delivery_app/MainPages/vouchers.dart';
import 'package:water_delivery_app/contollers/lang.dart';
import 'RatingPage.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late GoogleMapController mapController;
  final LatLng _initialPosition =
      const LatLng(32.5514, 35.8515); // Irbid coordinates
  User? user = FirebaseAuth.instance.currentUser;
  String fullName = "Loading...";
  String phoneNumber = "Loading...";
  DocumentSnapshot? currentOrder; // Store current order
  LatLng? stationLocation;
  String? stationName;
  String? stationPhoneNumber;
  bool isOffline = false; // Check for offline status
  StreamSubscription?
      _orderStreamSubscription; // Subscription for Firestore listener

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    fetchUserData();
    listenToOrderUpdates(); // Real-time order listener
  }

  @override
  void dispose() {
    _orderStreamSubscription?.cancel(); // Cancel Firestore listener if active
    mapController.dispose(); // Dispose the map controller
    super.dispose();
  }

  // Check internet connection using connectivity_plus
  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        isOffline = connectivityResult == ConnectivityResult.none;
      });
    }
  }

  // Fetch user details from Firestore with error handling
  Future<void> fetchUserData() async {
    try {
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userData.exists) {
          if (mounted) {
            String? firstName = userData['first_name'];
            String? lastName = userData['last_name'];
            String? phone = userData['phone'];

            // Check if any field is missing or the user doesn't have a document
            if (firstName == null || lastName == null || phone == null) {
              // Redirect or prompt user to update their profile
              _showProfileIncompleteDialog();
            } else {
              setState(() {
                fullName = "$firstName $lastName";
                phoneNumber = phone;
              });
            }
          }
        } else {
          // If user document does not exist, redirect to profile update
          _showProfileIncompleteDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar("Error",
            "Failed to fetch user data. Please check your connection.");
      }
    }
  }

  // Show a dialog when the profile is incomplete
  void _showProfileIncompleteDialog() {
    Get.defaultDialog(
      backgroundColor: Colors.lightBlueAccent,
      titleStyle: TextStyle(color: Colors.white),
      middleTextStyle: TextStyle(color: Colors.white),
      onWillPop: () async {
        return false;
      },
      title: AppLocalizations.of(context)!.incomplete_profile,
      middleText: AppLocalizations.of(context)!.please_complete,
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.offAll(() => UsernamePage(
              user: user,
            )); // Navigate to Account Page to update profile
      },
      textConfirm: AppLocalizations.of(context)!.ok,
      barrierDismissible: false,
    );
  }

  // Listen for real-time order updates from Firestore
  void listenToOrderUpdates() {
    if (user != null) {
      _orderStreamSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user!.uid)
          .where('status',
              whereIn: ['Pending', 'InProgress', 'Rejected', 'Finished'])
          .snapshots()
          .listen((QuerySnapshot snapshot) async {
            if (snapshot.docs.isNotEmpty) {
              DocumentSnapshot orderDoc = snapshot.docs.first;
              String status = orderDoc['status'];

              if (status == 'Rejected') {
                await _handleOrderRejection(orderDoc);
              }

              if (status == 'Finished') {
                Get.offAll(() => DeliveryConfirmationPage(
                      orderDoc: orderDoc,
                    ));
              } else {
                _fetchStationDetails(
                    orderDoc); // Fetch station details for accepted or pending orders
              }
            } else {
              if (mounted) {
                setState(() {
                  currentOrder = null; // No active orders
                });
              }
            }
          });
    }
  }





  Future<void> _handleOrderRejection(DocumentSnapshot orderDoc) async {
    try {

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderDoc.id)
          .delete();

      Get.defaultDialog(
        buttonColor: Colors.white,
        title: AppLocalizations.of(context)!.order_rejected,
        middleText: AppLocalizations.of(context)!.order_declined_msg,
        onWillPop: () async {
          return false;
        },
        barrierDismissible: false,
        backgroundColor: Colors.lightBlueAccent,
        textConfirm: AppLocalizations.of(context)!.ok,
        confirmTextColor: Colors.black,
        onConfirm: () async {
          setState(() {
            currentOrder = null;
          });
          Get.back(); // Close the dialog
        },
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to handle order rejection.");
    }
  }

  // Fetch station details based on current order with error handling
  Future<void> _fetchStationDetails(DocumentSnapshot orderDoc) async {
    try {
      String stationId = orderDoc['stationId'];
      String status = orderDoc['status'];

      DocumentSnapshot stationDoc = await FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .get();

      if (stationDoc.exists) {
        Map<String, dynamic> locationData =
            stationDoc['locations'][0]; // Assuming first location
        GeoPoint stationGeoPoint = locationData['location'];

        if (mounted) {
          setState(() {
            currentOrder = orderDoc;
            stationLocation =
                LatLng(stationGeoPoint.latitude, stationGeoPoint.longitude);
            stationName = stationDoc['name'];
            stationPhoneNumber = stationDoc['phone'];
          });
        }

        if (status == 'Pending') {
          _showPendingOrderWidget(); // Show pending order widget
        }
      }
    } catch (e) {}
  }

  // Cancel the order and delete it from Firestore
  Future<void> _cancelOrder() async {
    try {
      if (currentOrder != null) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(currentOrder!.id)
            .delete();
        if (mounted) {
          setState(() {
            currentOrder = null; // Reset current order
          });
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to cancel the order.");
    }
  }

  Future<void> _callStation() async {
    try {
      if (stationPhoneNumber != null) {
        final Uri launchUri = Uri(scheme: 'tel', path: stationPhoneNumber);
        await launchUrl(launchUri);
      } else {
        Get.snackbar('Error', 'No phone number available for this station');
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to call the station.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            myLocationEnabled: true,
            markers: currentOrder != null ? _buildMarkers() : {},
          ),
          if (isOffline) // Display a banner when offline
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildOfflineBanner(),
            ),
          Positioned(
            top: 40.0,
            left: Get.locale?.languageCode == 'en' ? 10.0 : null,
            right: Get.locale?.languageCode == 'ar' ? 10.0 : null,
            child: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, size: 30.0, color: Colors.black),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: currentOrder != null && currentOrder!['status'] == 'InProgress'
                ? _buildOrderInfoCard(context) // Show the pending order widget
                : (currentOrder != null
                    ? _showPendingOrderWidget()
                    : _buildPlaceOrderButton()),
          ),
        ],
      ),
    );
  }

  // Offline banner
  Widget _buildOfflineBanner() {
    return Container(
      color: Colors.red,
      padding: EdgeInsets.all(10),
      child: Center(
        child: Text(
          'No internet connection. You are offline.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Build the order info card
  Widget _buildOrderInfoCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 25,
                child: Icon(Icons.water_drop_outlined, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName ?? "Station Name",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Row(
                      children: [
                        SizedBox(width: 8),
                        Text(
                          '${currentOrder!['totalCost']} JD',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _callStation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.call_driver),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the pending order widget with better error handling and null safety
  Widget _showPendingOrderWidget() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 25,
                child: Icon(Icons.hourglass_empty, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display station name safely with null fallback
                    Text(
                      stationName ?? "Station Name",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Row(
                      children: [
                        SizedBox(width: 8),
                        // Display total cost with fallback to 0 if null
                        Text(
                          '${currentOrder?['totalCost'] ?? 0} JD',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Linear progress indicator for pending orders
          LinearProgressIndicator(
            backgroundColor: Colors.white,
            color: Colors.lightBlue,
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.pending_order,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 16),
          // Cancel order button with error handling
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _cancelOrder();
                    } catch (e) {
                      Get.snackbar("Error", "Failed to cancel order.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the drawer
  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent.shade700 , Colors.lightBlueAccent.shade200], begin: Alignment.topLeft, end: Alignment.bottomRight)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  phoneNumber,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle_outlined),
            title: Text(AppLocalizations.of(context)!.account),
            onTap: () => Get.to(() => AccountPage()),
          ),
          ListTile(
            leading: Icon(Icons.water_drop_outlined),
            title: Text(AppLocalizations.of(context)!.last_orders),
            onTap: () => Get.to(() => UserOrdersPage(userId: user!.uid)),
          ),ListTile(
            leading: Icon(Icons.card_giftcard),
            title: Text(AppLocalizations.of(context)!.vouchers),
            onTap: () => Get.to(() => VoucherPage(userId: user!.uid,))),

          ListTile(
            leading: Icon(Icons.language),
            title: Text(AppLocalizations.of(context)!.languages),
            onTap: () => _showLanguageDialog(context),
          ),ListTile(
            leading: Icon(Icons.help_outline_sharp),
            title: Text(AppLocalizations.of(context)!.help),
            onTap: () =>Get.to(() => HelpPage()),
          ),
          ListTile(
            leading: Icon(Icons.logout_outlined),
            title: Text(AppLocalizations.of(context)!.sign_out),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('had_ordered', false);
              await prefs.setBool('is_logged_in', false);
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => Login()); // Redirect to login page
            },
          ),
        ],
      ),
    );
  }

  // Build the station marker on the map
  Set<Marker> _buildMarkers() {
    if (stationLocation != null) {
      if (mounted) {
        return {
          Marker(
            markerId: MarkerId('station'),
            position: stationLocation!,
            infoWindow: InfoWindow(
              title: stationName ?? "Station Name",
              snippet: 'Cost: ${currentOrder!['totalCost']} JD',
            ),
          ),
        };
      }
      return {};
    } else {
      return {};
    }
  }

  // Function to place an order
  Future<void> _placeOrder() async {
    if (user != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if(prefs.getBool('had_ordered') == null || prefs.getBool('had_ordered') == false)
        Get.to(() => MapScreen(userId: user!.uid));
      else if (prefs.getBool('had_ordered') == true)
        Get.to(() => ChoiceScreen(userId: user!.uid));
    } else {
      Get.snackbar("Error", "User not logged in.");
    }
  }

  // Build "Order Now" button
  Widget _buildPlaceOrderButton() {
    return FloatingActionButton.extended(
      onPressed: currentOrder == null ? _placeOrder : null,
      label: Text(AppLocalizations.of(context)!.order_now),
      icon: Icon(Icons.shopping_cart),
      backgroundColor: Colors.blue,
    );
  }

  // Function to show the language selection dialog
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.choose_language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English'),
                onTap: () {
                  _changeLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('العربية'),
                onTap: () {
                  _changeLanguage('ar');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Change language function
  void _changeLanguage(String languageCode) {
    LocaleController localeController = Get.find<LocaleController>();
    localeController.changeLocale(languageCode);
    FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      "lang" : languageCode
    }, SetOptions(merge: true));
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('language_code', languageCode);
    });
  }

}
