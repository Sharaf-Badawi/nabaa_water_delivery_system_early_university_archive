import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nabaaadmins/stations/commion.dart';
import 'package:nabaaadmins/stations/offstations.dart';

class StationsPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المحطات',
            style: TextStyle(fontFamily: 'Kufam', fontSize: 22)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        width: Get.width,
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
            _buildActionButton(
              text: 'إضافة محطة',
              color: Colors.greenAccent,
              icon: Icons.add_circle_outline,
              onTap: () => _showAddStationDialog(context),
            ),

            SizedBox(height: 20),
            _buildActionButton(
              text: 'إيقاف محطة',
              color: Colors.redAccent,
              icon: Icons.pause_circle_filled,
              onTap: () {
                Get.to(() => StopStationsPage());

              },
            ),
            SizedBox(height: 20),
            _buildActionButton(
                text: 'المالية', color: Color(0xff114C87), icon: Icons.monetization_on, onTap: () => Get.to(() => CommissionPage()) ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(width: 10),
            Text(
              text,
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
    );
  }

  void _showAddStationDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'إضافة محطة',
      backgroundColor: Colors.white,
      radius: 20,
      content: Column(
        children: [
          _buildInputField(
            controller: _usernameController,
            hintText: 'اسم المستخدم',
            icon: Icons.person,
          ),
          SizedBox(height: 10),
          _buildInputField(
            controller: _passwordController,
            hintText: 'كلمة المرور',
            icon: Icons.lock,
            obscureText: true,
          ),
        ],
      ),
      textConfirm: 'إضافة',
      textCancel: 'إلغاء',
      onConfirm: () {
        _addStation();
        Get.back();
      },
      onCancel: () {},
      confirmTextColor: Colors.white,
      buttonColor: Colors.blueAccent,
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _addStation() async {
    String email = _usernameController.text.trim() + "@local.com";
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(
          userCredential.user!.uid).set({
        'email': email,
        'role': 'station',
      });

      Get.snackbar('نجاح', 'تمت إضافة المحطة بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);

      _usernameController.clear();
      _passwordController.clear();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إضافة المحطة',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
