// Create UpdatePage.dart file
import 'package:flutter/material.dart';

class UpdatePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حدِِث التطبيق')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 100, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'يرجى تحديث التطبيق. تواصل مع المسؤول ليزودك بالنسخة الاحدث',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
