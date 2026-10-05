import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  var locale = Rx<Locale?>(null); // Will be initialized later

  @override
  void onInit() async {
    super.onInit();
    await _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLanguageCode = prefs.getString('language_code');

    if (savedLanguageCode != null) {
      // Use saved language preference
      changeLocale(savedLanguageCode);
    } else {
      // Use device language if no saved preference
      Locale deviceLocale = Get.deviceLocale ?? Locale('en'); // Fallback to English
      locale.value = deviceLocale;
      Get.updateLocale(deviceLocale);
    }
  }

  void changeLocale(String languageCode) async {
    Locale newLocale = Locale(languageCode);
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Locale? resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
    if (deviceLocale == null) return supportedLocales.first;

    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }
}
