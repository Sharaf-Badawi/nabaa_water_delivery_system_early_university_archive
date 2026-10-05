import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/AuthPages/Login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:water_delivery_app/AuthPages/NamePage.dart';
import 'package:water_delivery_app/LegalPages/privacypolicy.dart';
import 'package:water_delivery_app/LegalPages/terms&conditions.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart'; // Import the localization

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the Google authentication flow
    await GoogleSignIn().signOut();
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      // The user canceled the sign-in process
      return Future.error("Sign-in process was canceled");
    }

    // Obtain the Google authentication details
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a Firebase credential using the Google token
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign the user into Firebase with the Google credential
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // Save the login state using SharedPreferences

    // Check if the user's profile data already exists in Firestore
    DocumentSnapshot userProfile = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    Map<String, dynamic> data = userProfile.data() as Map<String, dynamic>;

    if (userProfile.exists &&
        data.containsKey("first_name") &&
        data.containsKey("last_name") &&
        data.containsKey("phone")) {
      // If profile data exists, navigate to the Home page
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      Get.off(() => Home());
    } else {
      await GoogleSignIn().signOut();
      // If profile data doesn't exist, navigate to the Username page to complete the profile
      Get.off(() => UsernamePage(user: userCredential.user));
    }

    // Return the UserCredential object once the user is signed in
    return userCredential;
  }

  final _formKey = GlobalKey<FormState>();
  late double w, h;
  bool secure1 = true, secure2 = true;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
                padding: EdgeInsets.only(top: h * 0.05),
                child: Text(
                  "نبعة",
                  style: TextStyle(
                      fontFamily: 'Kufam', color: Colors.white, fontSize: 50),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: h * 0.07),
              child: Center(
                child: Text(
                  "معانا مافي عطش",
                  style: TextStyle(
                      fontFamily: 'Kufam', color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: TextFormField(
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.enter_email;
                    }

                    // Regular expression for email validation
                    final RegExp emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

                    // Check if the email format is correct
                    if (!emailRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.valid_email;
                    }
                    return null;

                    // (Optional) Check for specific domain (e.g., must be Gmail)
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
                  keyboardType: TextInputType.emailAddress),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06, vertical: h * 0.02),
              child: TextFormField(
                controller: _phoneNumberController,
                validator: validatePhoneNumber,
                decoration: InputDecoration(
                  hintText: "07XXXXXXXX",
                  // "Phone Number"
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.06,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                      width: w * 0.4,
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return AppLocalizations.of(context)!
                                .please_enter_name;
                          return null;
                        },
                        maxLength: 15,
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: AppLocalizations.of(context)!.first_name,
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
                      )),
                  Container(
                      width: w * 0.4,
                      child: TextFormField(
                        maxLength: 15,
                        controller: _lastNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return AppLocalizations.of(context)!
                                .please_enter_name;
                          return null;
                        },
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: AppLocalizations.of(context)!.last_name,
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
                      ))
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06, vertical: h * 0.02),
              child: TextFormField(
                controller: _passwordController,
                obscureText: secure1,
                validator: validatePassword,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          secure1 = !secure1;
                        });
                      },
                      icon: secure1
                          ? Icon(Icons.visibility_off)
                          : Icon(Icons.visibility)),
                  hintText: AppLocalizations.of(context)!.create_password,
                  // Translated text
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
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: w * 0.06, left: w * 0.06, bottom: h * 0.02),
              child: TextFormField(
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!
                        .enter_password; // Translated text
                  }
                  if (value != _passwordController.text) {
                    return AppLocalizations.of(context)!
                        .password_mismatch; // Translated text
                  }
                  return null;
                },
                obscureText: secure2,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          secure2 = !secure2;
                        });
                      },
                      icon: secure2
                          ? Icon(Icons.visibility_off)
                          : Icon(Icons.visibility)),
                  hintText: AppLocalizations.of(context)!.confirm_password,
                  // Translated text
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
            ),
            Padding(
              padding: EdgeInsets.only(
                  right: w * 0.06, top: h * 0.0001, left: w * 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.of(context)!.have_account,
                    // Translated text
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                  InkWell(
                    onTap: () {
                      Get.off(() => Login());
                    },
                    child: Text(AppLocalizations.of(context)!.sign_in,
                        // Translated text
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06, vertical: h * 0.008),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    TextSpan(
                        text: AppLocalizations.of(context)!.guarantee,
                        style: TextStyle(fontSize: 12)),
                    TextSpan(
                      text: AppLocalizations.of(context)!.terms_title,
                      style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.to(() => termsAndConditions());
                        },
                    ),
                    TextSpan(
                        text: AppLocalizations.of(context)!.and,
                        style: TextStyle(fontSize: 12)),
                    TextSpan(
                      text: AppLocalizations.of(context)!.privacy_title,
                      style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Get.to(() => privacypolicy());
                        },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  left: w * 0.2, right: w * 0.2, top: h * 0.002),
              child: MaterialButton(
                color: Colors.white,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      // Create a user with email and password
                      UserCredential userCredential =
                          await _auth.createUserWithEmailAndPassword(
                        email: _phoneController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      User? user = userCredential.user;

                      // Ensure the user is created before proceeding
                      if (user != null) {
                        // Send email verification
                        await user.sendEmailVerification();
String? lang = Get.locale!.languageCode;
                        // Store user information in Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .set({
                          'first_name': _firstNameController.text.trim(),
                          'last_name': _lastNameController.text.trim(),
                          'phone': _phoneNumberController.text.trim(),
                          'email': user.email,
                          'lang' : lang,
                          'notificationToken' : FirebaseMessaging.instance.getToken(),
                          'lastOrder' : DateTime.now(),
                          'loyalty' : 0,
                          'stop' : false,
                          'voucher_value' : 0.0
                          // Store the email from the user object
                        });

                        // Notify the user to verify their email
                        Get.snackbar('Verify Email',
                            'A verification email has been sent. Please verify your email.',
                            backgroundColor: Colors.blue[800]);

                        // Redirect to the login page after successful sign-up
                        Get.off(() => Login());
                      }
                      ;
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'email-already-in-use') {
                        // Handle email already in use error
                        Get.snackbar(
                            AppLocalizations.of(context)!.email_is_used,
                            AppLocalizations.of(context)!.chhose_another_email,
                            backgroundColor: Colors.blue[800]);
                        print('The email is already in use.');
                      } else {
                        // Handle other possible FirebaseAuth errors
                        Get.snackbar('Failed to sign up', '${e.message}',
                            backgroundColor: Colors.blue[800]);
                        print('Failed to sign up: ${e.message}');
                      }
                    } catch (e) {
                      Get.snackbar('Failed to sign up', '${e}',
                          backgroundColor: Colors.blue[800]);

                      print("Sign-up failed: $e");
                    }
                  }
                },
                child: Container(
                  width: w * 0.6,
                  height: h * 0.07,
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.sign_up,
                    // Translated text
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ),
            Center(
                child: Padding(
              padding: EdgeInsets.only(top: h * 0.01),
              child: Text(
                AppLocalizations.of(context)!.or,
                style: TextStyle(fontSize: 15),
              ),
            )),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: w * 0.2, vertical: h * 0.01),
              child: MaterialButton(
                color: Colors.white,
                onPressed: () async {
                  signInWithGoogle();
                },
                child: Container(
                  width: w * 0.6,
                  height: h * 0.07,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.sign_up_with_google,
                        // Translated text
                        style: TextStyle(fontSize: 13),
                      ),
                      Image.asset("assets/images/Google_Icons-09-512.jpeg")
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enter_phone; // Translated text
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return AppLocalizations.of(context)!.valid_phone; // Translated text
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.enter_password; // Translated text
    }
    if (value.length < 8) {
      return AppLocalizations.of(context)!
          .password_min_length; // Translated text
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return AppLocalizations.of(context)!
          .password_uppercase; // Translated text
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return AppLocalizations.of(context)!
          .password_lowercase; // Translated text
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return AppLocalizations.of(context)!.password_digit; // Translated text
    }
    return null;
  }
}
