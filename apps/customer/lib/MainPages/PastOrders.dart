import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserOrdersPage extends StatefulWidget {
  final String userId; // Pass the user ID

  UserOrdersPage({required this.userId});

  @override
  _UserOrdersPageState createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _completedOrders = [];
  String lang = 'ar';


  Future<void> _lang()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
setState(() {
  lang = prefs.getString('language_code') ?? 'ar';

});  }

  @override
  void initState() {
    super.initState();
    _lang();
    _fetchUserOrders();
  }

  // Fetch user completed orders from Firestore
  Future<void> _fetchUserOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('CompletedOrders')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('completedTimestamp', descending: true) // Sort by completion date
          .get();

      setState(() {
        _completedOrders = ordersSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching user orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.orders_history),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _completedOrders.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.empty_orders))
          : ListView.builder(
        itemCount: _completedOrders.length,
        itemBuilder: (context, index) {
          var order = _completedOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  // Build a card for each completed order
  Widget _buildOrderCard(QueryDocumentSnapshot order) {
    var orderData = order.data() as Map<String, dynamic>;

    String stationId = orderData['stationId'] ?? 'Unknown Station';
    double totalCost = orderData['totalCost'] ?? 0.0;
    Timestamp completedTimestamp = orderData['completedTimestamp'];
    DateTime completedDate = completedTimestamp.toDate();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(completedDate);

    Map products = orderData['products'] ?? {};

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('stations').doc(stationId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var stationData = snapshot.data!;
        String stationName = stationData['name'] ?? 'Unknown Station';
        String stationPhone = stationData['phone'] ?? 'No phone';

        return Card(
          margin: EdgeInsets.all(10),
          elevation: 5,
          shadowColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(stationName, totalCost, formattedDate, stationPhone),
                SizedBox(height: 10),
                _buildProductList(products),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build header section with station name, total cost, and completion date
  Widget _buildHeader(String stationName, double totalCost, String date, String phoneNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.station_name}:$stationName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 5),
            Text(
              '${AppLocalizations.of(context)!.deliveredIn}: $date',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              '${AppLocalizations.of(context)!.phone_number}: $phoneNumber',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Column(
          children: [
            Text(
              '$totalCost JD',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            IconButton(
              icon: Icon(Icons.phone, color: Colors.green),
              onPressed: () => _callStation(phoneNumber),
            ),
          ],
        ),
      ],
    );
  }

  // Build a collapsible/expandable product list for each order
  Widget _buildProductList(Map products) {
    if (products.isEmpty) {
      return Text('لا توجد منتجات');
    }

    return ExpansionTile(
      title: Text(
        '${AppLocalizations.of(context)!.show_products} (${products.length})',
        style: TextStyle(color: Colors.blueAccent),
      ),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var productId = products.keys.elementAt(index);
            var quantity = products[productId];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(AppLocalizations.of(context)!.loading);
                }
                var productData = snapshot.data!;
                String productTitle = 'Unknown Product';
                if(lang == 'en')
                 productTitle = productData['title_en'] ?? 'Unknown Product';
                else
                 productTitle = productData['title'] ?? 'Unknown Product';
                return ListTile(
                  title: Text(productTitle),
                  trailing: Text('${AppLocalizations.of(context)!.quantity} $quantity'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Function to call the station
  Future<void> _callStation(String stationPhoneNumber) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: stationPhoneNumber,
      );
      await launchUrl(launchUri);
    } catch(e) {
      Get.snackbar('Error', 'No phone number available for this station');
    }
  }
}
