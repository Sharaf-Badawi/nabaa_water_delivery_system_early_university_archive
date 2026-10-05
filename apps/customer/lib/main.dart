import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:water_delivery_app/MainPages/HomePage.dart';
import 'package:water_delivery_app/MainPages/products.dart';
import 'package:water_delivery_app/contollers/lang.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'water_delivery_app',
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


  // Initialize LocaleController for centralized localization
  final LocaleController localeController = Get.put(LocaleController());

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  String? langCode = prefs.getString('language_code');
  if (langCode != null) {
    localeController.changeLocale(langCode);
  }
  if (isLoggedIn) {

    _fmctokenmanagment(prefs);
  }
await _requestNotificationPermissions();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Log the status of the user's notification settings
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permissions');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional notification permissions');
  } else {
    print('User denied notification permissions');
  }
}
Future<void> _fmctokenmanagment(SharedPreferences prefs) async {
  String? userToken = await FirebaseMessaging.instance.getToken();
  User? user = FirebaseAuth.instance.currentUser;

  if (user == null || userToken == null) return;

  String? savedToken = prefs.getString('user_token');
  if (savedToken == null || savedToken != userToken) {
    prefs.setString('user_token', userToken);
    String userId = user.uid;
    FirebaseFirestore.instance.collection('users').doc(userId).set({
      "notificationToken": userToken,
    }, SetOptions(merge: true));
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final LocaleController localeController = Get.find<LocaleController>();

    return GetMaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Almarai'),
      ),
      locale: localeController.locale.value,
      supportedLocales: [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate, // RTL support
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Use system locale if no saved preference exists
        return localeController.resolveLocale(locale, supportedLocales);
      },
      home: isLoggedIn ? Home() : ProductGridScreen(userId: ""),
    );
  }
}
