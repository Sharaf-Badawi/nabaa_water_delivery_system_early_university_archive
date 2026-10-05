import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:station_app/Auth/Login.dart';
import 'package:station_app/Auth/UpdateApp.dart';
import 'package:station_app/MainPages/Home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:station_app/controllers/station.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      // The original project values were removed before publication.
      // Supply local values with --dart-define when running this archive.
      apiKey: const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'REPLACE_WITH_FIREBASE_API_KEY',
      ),
      appId: const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: 'REPLACE_WITH_FIREBASE_APP_ID',
      ),
      messagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: 'REPLACE_WITH_FIREBASE_MESSAGING_SENDER_ID',
      ),
      projectId: const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'replace-with-firebase-project-id',
      ),
    ),
  );
await _requestNotificationPermission();
  // Ensure SharedPreferences is ready
  SharedPreferences prefs = await SharedPreferences.getInstance();
String appVersion = "1.0.0";
  String requieredVersion = await getRequieredVersion(appVersion);
  // Check if user is logged in
  if(requieredVersion != appVersion){
    runApp(MyApp(user: null, isUpdateRequered : true));
  }
  else{
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String stationId = user.uid; // Unique identifier for the provider
      await _manageFCMToken(stationId, prefs);
    }

    runApp(MyApp(user: user, isUpdateRequered : false));
  }
}
Future<void> _requestNotificationPermission() async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notification permission granted.");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("Provisional notification permission granted.");
  } else {
    print("Notification permission denied.");
  }
}
Future<String> getRequieredVersion(String appVersion) async{
  DocumentSnapshot docs= await FirebaseFirestore.instance.collection("systemElements").doc("station_config").get();
  if(docs.exists){
    var data = docs.data() as Map<String , dynamic>;
    return data['required_version'];
  }
  return appVersion;
}

// Function to manage the FCM token
Future<void> _manageFCMToken(String stationId, SharedPreferences prefs) async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the current FCM token
  String? currentToken = await messaging.getToken();

  if (currentToken == null) {
    print("FCM token is null. Ensure Firebase Messaging is properly set up.");
    return;
  }

  // Check if the token is already stored in SharedPreferences
  String? storedToken = prefs.getString("fcm_token");

  if (storedToken == null || storedToken != currentToken) {
    // Update SharedPreferences
    await prefs.setString("fcm_token", currentToken);

    // Update Firestore with the new token
    await FirebaseFirestore.instance
        .collection("stations") // Adjust collection name as per your structure
        .doc(stationId) // Document ID is the station ID
        .set(
      {"notificationToken": currentToken},
      SetOptions(merge: true), // Merge to avoid overwriting other fields
    );

    print("FCM token updated in Firestore and SharedPreferences.");
  } else {
    print("FCM token is already up-to-date.");
  }
}

class MyApp extends StatelessWidget {
  final User? user;
final bool isUpdateRequered;


  MyApp({this.user, this.isUpdateRequered = false});

  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: 'Station App',
      locale: Locale('ar'),
      supportedLocales: [
        Locale('ar', ''),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        return Locale('ar'); // Always use Arabic
      },
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Almarai'),
        primarySwatch: Colors.blue,
      ),
      home: isUpdateRequered ? UpdatePage() :   (user == null ? Login() : Home(userId: user!.uid)),
    );
  }
}
