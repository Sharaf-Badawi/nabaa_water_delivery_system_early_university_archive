import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:water_delivery_app/LegalPages/privacypolicy.dart';
import 'package:water_delivery_app/LegalPages/terms&conditions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class HelpPage extends StatelessWidget {
  // URLs for the privacy policy and terms and conditions


  // Email address for technical support
  final String supportEmail = 'contact@example.invalid';

  // Launch the Gmail app with a predefined email and subject
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Technical Help'
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // If the email app cannot be launched, copy to clipboard
        _copyToClipboard(context);
      }
    } catch (e) {
      print(e);
      // If an error occurs, copy to clipboard
      _copyToClipboard(context);
    }
  }

  // Function to copy email to the clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.email_copied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.help),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information text with clickable links using TextSpan
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(text: AppLocalizations.of(context)!.app_questions,style: TextStyle(fontFamily: 'Almarai')),
                  TextSpan(
                    text: AppLocalizations.of(context)!.privacy_title,
                    style: TextStyle(color: Colors.blue,fontFamily: 'Almarai'),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        Get.to(() => privacypolicy());
                      },
                  ),
                  TextSpan(text: AppLocalizations.of(context)!.and,style: TextStyle(fontFamily: 'Almarai')),
                  TextSpan(
                    text: AppLocalizations.of(context)!.terms_title,
                    style: TextStyle(color: Colors.blue,fontFamily: 'Almarai'),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        Get.to(() => termsAndConditions());
                      },
                  ),
                  TextSpan(text: AppLocalizations.of(context)!.further,style: TextStyle(fontFamily: 'Almarai')),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Divider for separation
            Divider(color: Colors.grey),
            SizedBox(height: 20),
            // Contact section
            Text(
              AppLocalizations.of(context)!.tech_support,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.tech_problem,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => _copyToClipboard(context),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    supportEmail,
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
