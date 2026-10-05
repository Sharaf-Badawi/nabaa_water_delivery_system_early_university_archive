import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UsernamePage extends StatefulWidget {
  final User? user; // Passing the user object from sign-up
  UsernamePage({required this.user});

  @override
  _UsernamePageState createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  late double w, h;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

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
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: h * 0.1),
                  child: Text(
                    "نبعة", // Do not translate the brand name
                    style: TextStyle(
                      fontFamily: 'Kufam',
                      color: Colors.white,
                      fontSize: 50,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "معانا مافي عطش", // Do not translate this slogan
                  style: TextStyle(
                    fontFamily: 'Kufam',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: h * 0.1),
                  child: Text(
                    AppLocalizations.of(context)!
                        .please_enter_your_information, // "Please Enter Your Information"
                    style: TextStyle(
                      fontSize: 23,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.06, vertical: h * 0.02),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.phone_number;
                    if (value.length != 10)
                      return AppLocalizations.of(context)!.valid_phone;
                    return null;
                  },
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    hintText: "07XXXXXXXX", // "Phone Number"
                    fillColor: Colors.white,
                    filled: true,
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.please_enter_name;
                    return null;
                  },
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .first_name, // "First Name"
                    fillColor: Colors.white,
                    filled: true,
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    right: w * 0.06,
                    left: w * 0.06,
                    top: h * 0.02,
                    bottom: h * 0.05),
                child: TextFormField(
                  controller: _lastNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return AppLocalizations.of(context)!.please_enter_name;
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:
                        AppLocalizations.of(context)!.last_name, // "Last Name"
                    fillColor: Colors.white,
                    filled: true,
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.2),
                child: MaterialButton(
                  color: Colors.white,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String? lang = Get.locale!.languageCode ;
                      String uid = widget.user!.uid;
                      await _firestore.collection('users').doc(uid).set({
                        'first_name': _firstNameController.text.trim(),
                        'last_name': _lastNameController.text.trim(),
                        'phone': _phoneNumberController.text.trim(),
                        'email': widget
                            .user!.email
                        ,
                        'lang' : lang ?? 'ar',
                         'notificationToken' : await FirebaseMessaging.instance.getToken(),
                        'lastOrder' : DateTime.now(),
                         'loyalty' : 0,
                        'stop' : false,
                        'voucher_value' : 0.0
// Store email from Google sign-in
                      });

                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('is_logged_in', true);
                      Get.off(() => Home(
                         ));
                    }
                  },
                  child: Container(
                    width: w * 0.6,
                    height: h * 0.07,
                    alignment: Alignment.center,
                    child: Text(
                      AppLocalizations.of(context)!.enter, // "Enter"
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
