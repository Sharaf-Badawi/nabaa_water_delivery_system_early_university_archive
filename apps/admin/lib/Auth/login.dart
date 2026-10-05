import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nabaaadmins/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool secure = true;
  bool _isLoading = false;

  late double w, h;

  @override
  Widget build(BuildContext context) {
    w = MediaQuery.of(context).size.width;
    h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: h,
        width: w,
        color: Colors.lightBlueAccent,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            children: [
              SizedBox(height: h * 0.16),
              Center(
                child: Text(
                  "نبعة", // Title of the app
                  style: TextStyle(
                      fontFamily: 'Kufam', color: Colors.white, fontSize: 50),
                ),
              ),
              Center(
                child: Text(
                  "معانا مافي عطش", // App tagline
                  style: TextStyle(
                      fontFamily: 'Kufam', color: Colors.white, fontSize: 12),
                ),
              ),
              SizedBox(height: h * 0.07),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "البريد الإلكتروني", // Email label in Arabic
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "أدخل البريد الإلكتروني"; // Error message in Arabic
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "contact@example.invalid",
                  fillColor: Colors.white,
                  filled: true,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              SizedBox(height: h * 0.03),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "كلمة المرور", // Password label in Arabic
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: secure, // Obscure the password
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "أدخل كلمة المرور"; // Password error message
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "كلمة المرور",
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          secure = !secure;
                        });
                      },
                      icon: Icon(secure ? Icons.visibility_off : Icons.visibility)),
                  filled: true,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
              SizedBox(height: h * 0.04),
              MaterialButton(
                color: Colors.white,
                onPressed: _isLoading ? null : _login, // Trigger login
                child: Container(
                  width: w * 0.6,
                  height: h * 0.07,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.blue)
                      : Text(
                    "تسجيل الدخول",
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          await _checkUserRole(user);
        }
      } on FirebaseAuthException catch (e) {
        Get.snackbar("خطأ", e.message.toString(),
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUserRole(User user) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('role') && userData['role'] == 'admin') {
        SharedPreferences prefs= await SharedPreferences.getInstance();
        prefs.setBool('logedin', true);
        Get.offAll(() => Home());
      } else {
        Get.snackbar("خطأ", "غير مصرح بالدخول", backgroundColor: Colors.red, colorText: Colors.white);
        await _auth.signOut();
      }
    } else {
      Get.snackbar("خطأ", "المستخدم غير موجود", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

}
