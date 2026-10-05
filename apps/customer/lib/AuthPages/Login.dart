import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_delivery_app/AuthPages/NamePage.dart';
import 'package:water_delivery_app/AuthPages/SignUp.dart';
import 'package:water_delivery_app/LegalPages/privacypolicy.dart';
import 'package:water_delivery_app/LegalPages/terms&conditions.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  void _resetPassword(String email, BuildContext context) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(AppLocalizations.of(context)!.enter_email)),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.password_reset)),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user found with that email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the Google authentication flow
    await GoogleSignIn().signOut();
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      // The user canceled the sign-in process
      return Future.error("Sign-in process was canceled");
    }

    // Obtain the Google authentication details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a Firebase credential using the Google token
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign the user into Firebase with the Google credential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    // Save the login state using SharedPreferences


    // Check if the user's profile data already exists in Firestore
    DocumentSnapshot userProfile = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    //Map<String, dynamic> data = userProfile.data() as Map<String, dynamic>;
    if (userProfile.exists ){//&& data.containsKey("first_name") && data.containsKey("last_name") && data.containsKey("phone")) {
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

  late double w, h;
  bool secure1 = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
              child: ListView(children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: h * 0.16),
                    child: Text(
                      "نبعة", // Keep unchanged
                      style: TextStyle(
                          fontFamily: 'Kufam', color: Colors.white, fontSize: 50),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "معانا مافي عطش", // Keep unchanged
                    style: TextStyle(
                        fontFamily: 'Kufam', color: Colors.white, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: w * 0.06, top: h * 0.07,right: w * 0.06,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.email, // Use translated string
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                  child: TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!.enter_email; // Use translated string
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
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: w * 0.06,
                    right: w * 0.06,

                    top: h * 0.03,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.password, // Use translated string
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: secure1,
                    validator: validatepassword,
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
                      hintText: AppLocalizations.of(context)!.password, // Use translated string
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
                  padding: EdgeInsets.only(right: w * 0.06, top: h * 0.01,left: w * 0.06),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
_resetPassword(_emailController.text, context);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.forgot_password, // Use translated string
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.008),
                  child: RichText(
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
                            style: TextStyle(fontSize: 12) ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.privacy_title,
                          style: TextStyle(color: Colors.blue[900],fontSize: 12),
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
                      right:w*0.2,left:w*0.2,top:h*0.01),
                  child: MaterialButton(
                    color: Colors.white,
                    onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {

                            UserCredential userCredential = await _auth
                                .signInWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            User? user = userCredential.user;

                            if (user != null && !user.emailVerified) {
                              // Prompt the user to verify their email
                              Get.snackbar(AppLocalizations.of(context)!.email_verification,
                                  AppLocalizations.of(context)!.please_check_your_email_for_verification);
                              return;
                            }


                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_logged_in', true);
                            // If email is verified, proceed to the username page or home
                            Get.off(() =>
                                Home());
                          }
                          on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              Get.snackbar(AppLocalizations.of(context)!.user_not_found, '',backgroundColor: Colors.blue[800]);
                              print('No user found with this email.');
                            } else if (e.code == 'wrong-password') {
                              // Handle incorrect password error
                              Get.snackbar(AppLocalizations.of(context)!.wrong_pass, '',backgroundColor: Colors.blue[800]);

                              print('Wrong password provided for this user.');
                            } else {
                              // Handle other FirebaseAuth errors
                              print('Sign-in failed: ${e.message}');
                            }
                          }

                          catch (e) {
                            print("Login failed: $e");
                          }
                        }


                    },
                    child: Container(
                      width: w * 0.6,
                      height: h * 0.07,
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.sign_in, // Use translated string
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ),
                Center(child: Padding(padding: EdgeInsets.only(top: h*0.02),child: Text(AppLocalizations.of(context)!.or,style: TextStyle(fontSize: 15),),)),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: w * 0.2, vertical: h * 0.02),
                  child: MaterialButton(
                    color: Colors.white,
                    onPressed: () {
                      signInWithGoogle();
                    },
                    child: Container(
                      width: w * 0.6,
                      height: h * 0.07,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.dont_have_account, // Use translated string
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                    InkWell(
                      onTap: () {
                        Get.off(() => SignUp());
                      },
                      child: Text(
                        AppLocalizations.of(context)!.register, // Use translated string
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    )
                  ],
                ),
              ]),
            )));
  }

  String? validatepassword(String? password){
    if(password == null || password.isEmpty){
      return AppLocalizations.of(context)!.enter_password;
    }
    if(!RegExp(r'[A-Z]').hasMatch(password)){
      return AppLocalizations.of(context)!.password_uppercase;
    }
    if(!RegExp(r'[a-z]').hasMatch(password)){
      return AppLocalizations.of(context)!.password_lowercase;
    }
    if(!RegExp(r'\d').hasMatch(password)){
      return AppLocalizations.of(context)!.password_digit;
    }
    if(password.length < 8){
      return AppLocalizations.of(context)!.password_min_length;
    }
   return null;
  }
}
