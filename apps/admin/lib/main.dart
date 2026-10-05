import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nabaaadmins/Auth/login.dart';
import 'package:nabaaadmins/Home.dart';
import 'package:nabaaadmins/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          // The original project values were removed before publication.
          // Supply local values with --dart-define when running this archive.
          apiKey: String.fromEnvironment(
            'FIREBASE_API_KEY',
            defaultValue: 'REPLACE_WITH_FIREBASE_API_KEY',
          ),
          appId: String.fromEnvironment(
            'FIREBASE_APP_ID',
            defaultValue: 'REPLACE_WITH_FIREBASE_APP_ID',
          ),
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
            defaultValue: 'REPLACE_WITH_FIREBASE_MESSAGING_SENDER_ID',
          ),
          projectId: String.fromEnvironment(
            'FIREBASE_PROJECT_ID',
            defaultValue: 'replace-with-firebase-project-id',
          )));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedin = false;

  @override
  void initState() {
    super.initState();
    checkForLogging();
  }

  Future<void> checkForLogging() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedin = prefs.getBool('logedin') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoggedin ? Home() : Login(),
    );
  }
}
