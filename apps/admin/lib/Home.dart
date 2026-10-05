import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nabaaadmins/Auth/login.dart';
import 'package:nabaaadmins/marketing/vouchers.dart';
import 'package:nabaaadmins/stations/stationManagment.dart';
import 'package:nabaaadmins/users/users.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 1,
                  childAspectRatio: 3,
                  mainAxisSpacing: 20,
                  children: [
                    _buildCategoryCard(
                      context,
                      title: 'المحطات',
                      icon: Icons.storefront,
                      color: Colors.blue[700]!,
                      onTap: () => Get.to(() => StationsPage()),
                    ),
                    _buildCategoryCard(
                      context,
                      title: 'المستخدمين',
                      icon: Icons.people,
                      color: Colors.blue[500]!,
                      onTap: () => Get.to(() => UserManagementPage()),
                    ),
                    _buildCategoryCard(
                      context,
                      title: 'القسائم',
                      icon: Icons.local_offer,
                      color: Colors.blue[300]!,
                      onTap: () => Get.to(() => VoucherCampaignPage()),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () {
                  Get.defaultDialog(
                    title: "تسجيل الخروج",
                    middleText: "Are you sure you want to sign out?",
                    textCancel: "Cancel",
                    textConfirm: "Yes",
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      Get.offAll(() => Login());
                    },
                  );
                },
                child: Text('تسجيل الخروج', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        color: color,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Kufam',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
