import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:station_app/controllers/station.dart';
import 'package:url_launcher/url_launcher.dart';

class CompletedOrdersPage extends StatelessWidget {
  final String stationId;

  CompletedOrdersPage({required this.stationId});

  @override
  Widget build(BuildContext context) {
    // Access the StationController
    final stationController = Get.find<StationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل الطلبات المكتملة'),
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the CompletedOrders collection where stationId matches
        stream: FirebaseFirestore.instance
            .collection('CompletedOrders')
            .where('stationId', isEqualTo: stationId)
            .orderBy('completedTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا توجد طلبات مكتملة'));
          }

          final completedOrders = snapshot.data!.docs;

          return Obx(() {
            if (stationController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }

            // Get total costs and commission from the controller
            double totalCosts = stationController.stationData['totalcosts'] ?? 0.0;
            double commission = stationController.stationData['commision'] ?? 0.0;
            double required_commission = stationController.stationData['required_commission'] ?? 0.0;

            return Column(
              children: [
                _buildSummaryHeader(totalCosts, commission, required_commission),
                Expanded(
                  child: ListView.builder(
                    itemCount: completedOrders.length,
                    itemBuilder: (context, index) {
                      final order = completedOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  // Build a summary header showing total costs and app commission
  Widget _buildSummaryHeader(double totalCosts, double commission , double required_commission) {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي العائد للمحطة:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalCosts.toStringAsFixed(2)} JD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عمولة التطبيق:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${commission.toStringAsFixed(2)} JD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العمولة المستحقة حاليا:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${required_commission.toStringAsFixed(2)} JD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build a card for each completed order
  Widget _buildOrderCard(QueryDocumentSnapshot order) {
    final orderData = order.data() as Map<String, dynamic>;

    String userId = orderData['userId'] ?? 'Unknown User';
    double totalCost = orderData['totalCost'] ?? 0.0;
    Timestamp completedTimestamp = orderData['completedTimestamp'];
    DateTime completedDate = completedTimestamp.toDate();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(completedDate);

    Map products = orderData['products'] ?? {};

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var userData = snapshot.data!;
        String firstName = userData['first_name'] ?? 'Unknown';
        String lastName = userData['last_name'] ?? 'User';
        String phoneNumber = userData['phone'] ?? 'No phone';

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
                _buildHeader('$firstName $lastName', totalCost, formattedDate, phoneNumber),
                SizedBox(height: 10),
                _buildProductList(products),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build header section with user name, total cost, completion date, and call button
  Widget _buildHeader(String userName, double totalCost, String date, String phoneNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم المستخدم: $userName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 5),
            Text(
              'تاريخ الانتهاء: $date',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              'رقم الهاتف: $phoneNumber',
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
        'عرض المنتجات (${products.length})',
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
                  return Text('جاري التحميل...');
                }
                var productData = snapshot.data!;
                String productTitle = productData['title'] ?? 'Unknown Product';
                return ListTile(
                  title: Text(productTitle),
                  trailing: Text('الكمية: $quantity'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // Function to call the user
  Future<void> _callStation(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    } else {
      Get.snackbar('Error', 'No phone number available for this station');
    }
  }
}
