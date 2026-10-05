import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class privacypolicy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: Text(AppLocalizations.of(context)!.privacy_title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: Get.height*0.8,
              width: Get.width*0.98,
              child: ListView(children: [
                Text(AppLocalizations.of(context)!.privacy_policy)
              ],),
            ),
            Container(
              color: Colors.lightBlueAccent,
              width: Get.width,
              height: Get.height*0.083,
              child: MaterialButton(
                color: Colors.lightBlueAccent,
                onPressed: () {
Get.back();
                },child: Text(AppLocalizations.of(context)!.ok),),
            )
          ],)

    );
  }
}
