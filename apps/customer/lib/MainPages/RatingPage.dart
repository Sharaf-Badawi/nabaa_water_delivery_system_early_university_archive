import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DeliveryConfirmationPage extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  DeliveryConfirmationPage({required this.orderDoc});

  @override
  _DeliveryConfirmationPageState createState() => _DeliveryConfirmationPageState();
}

class _DeliveryConfirmationPageState extends State<DeliveryConfirmationPage> {
  late Future<DocumentSnapshot> stationFuture; // Future for station data
 String  lang = "ar";
  @override
  void initState() {
    super.initState();
    _lang();
    stationFuture = _fetchStationDetails(); // Initialize future to fetch station data
  }

  // Fetch station details
  Future<DocumentSnapshot> _fetchStationDetails() async {
    String stationId = widget.orderDoc['stationId'];
    return await FirebaseFirestore.instance.collection('stations').doc(stationId).get();
  }
 Future<void> _lang() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
setState(() {
  lang = prefs.getString('language_code') ?? 'ar' ;
});
 }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: stationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching station details'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Station not found'));
          }

          // Station details
          var stationData = snapshot.data!;
          String stationName = stationData['name'];
          double totalCost = widget.orderDoc['totalCost'];

          return _buildConfirmationScreen(stationName, totalCost);
        },
      ),
    );
  }

  // Confirmation screen UI
  Widget _buildConfirmationScreen(String stationName, double totalCost) {
    return Container(
      decoration: BoxDecoration(color: Colors.lightBlueAccent),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Delivery confirmation title
          Text(
            "${AppLocalizations.of(context)!.delivery_completed} $stationName!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          // Total cost display
          Text(
            "${AppLocalizations.of(context)!.total_cost} $totalCost ${AppLocalizations.of(context)!.jd}",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          SizedBox(height: 10),
          _buildProductList(widget.orderDoc['products']), // Product list
          SizedBox(height: 30),
          // Back to home button
          ElevatedButton(
            onPressed: () {
              _completeDelivery(); // Call the modified method to delete the order and navigate back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "${AppLocalizations.of(context)!.ok}",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Product list UI
  Widget _buildProductList(Map<String, dynamic> products) {
    return Column(
      children: products.keys.map((productId) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(color: Colors.blue);
            }
            if (snapshot.hasError) {
              return Text('Error fetching product data');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('Product not found');
            }

            var productData = snapshot.data!.data() as Map<String, dynamic>;
            String title = 'Unknown Product';
              if(lang == 'en')
                title = productData['title_en'] ?? 'Unknown Product';
              else
                 title = productData['title'] ?? 'Unknown Product';



            return ListTile(
              title: Text(title, style: TextStyle(color: Colors.white)),
              subtitle: Text(
                "${AppLocalizations.of(context)!.quantity} ${products[productId]}",
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  // Complete the delivery process by deleting the order doc and navigating to home
  Future<void> _completeDelivery() async {
    try {
      // Delete the order document from Firestore
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderDoc.id).delete();



      // Navigate to the home page after confirmation
      Get.offAll(() => Home());
    } catch (e) {
      // Handle errors during deletion
      Get.snackbar('Error', 'Failed to delete the order. Please try again.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
