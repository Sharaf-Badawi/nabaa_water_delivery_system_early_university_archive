import 'dart:ui';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class VoucherCampaignPage extends StatefulWidget {
  @override
  _VoucherCampaignPageState createState() => _VoucherCampaignPageState();
}

class _VoucherCampaignPageState extends State<VoucherCampaignPage> {
  TextEditingController _budgetController = TextEditingController();
  TextEditingController _voucherValueController = TextEditingController();
  TextEditingController _expiryDateController = TextEditingController();
  TextEditingController _usersToReceiveController = TextEditingController();
  int totalEligibleUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchEligibleUsers();
  }

  Future<void> _fetchEligibleUsers() async {
    try {
      // Query users with `voucher_value == 0` or users without 'voucher_value'
      QuerySnapshot eligibleUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('voucher_value', isEqualTo: 0)
          .get();

      List<String> eligibleUsers = eligibleUsersSnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        totalEligibleUsers = eligibleUsers.length;
      });
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء استرجاع عدد المستخدمين المؤهلين', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حملة القسائم', style: TextStyle(fontFamily: 'Kufam', fontSize: 22)),
        backgroundColor: Color(0xFF0077B6),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField('الميزانية', _budgetController, TextInputType.number),
              SizedBox(height: 20),
              _buildInfoTile('عدد المستخدمين المؤهلين', '$totalEligibleUsers'),
              SizedBox(height: 20),
              _buildInputField('قيمة القسيمة', _voucherValueController, TextInputType.number),
              SizedBox(height: 20),
              _buildInputField('عدد المستخدمين لتلقي القسيمة', _usersToReceiveController, TextInputType.number),
              SizedBox(height: 20),
              _buildInputField('تاريخ انتهاء القسيمة (YYYY-MM-DD)', _expiryDateController, TextInputType.datetime),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submitCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0096C7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('إرسال الحملة', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, TextInputType keyboardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            filled: true,
            fillColor: Color(0xFFE1F5FE),
            prefixIcon: Icon(Icons.edit, color: Color(0xFF0077B6)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Card(
      color: Color(0xFFE1F5FE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCampaign() async {
    try {
      double budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      double voucherValue = double.tryParse(_voucherValueController.text.trim()) ?? 0.0;
      int usersToReceive = int.tryParse(_usersToReceiveController.text.trim()) ?? 0;
      DateTime expiryDate = DateTime.tryParse(_expiryDateController.text.trim()) ?? DateTime.now();

      if (budget <= 0 || voucherValue <= 0 || expiryDate.isBefore(DateTime.now()) || usersToReceive <= 0) {
        _showErrorSnackbar('تأكد من إدخال جميع الحقول بشكل صحيح');
        return;
      }

      int maxVouchers = usersToReceive;
      if ((voucherValue * usersToReceive) > budget) {
        _showErrorSnackbar('الميزانية غير كافية لتغطية القسائم المطلوبة');
        return;
      }

      // Initialize total vouchers distributed to zero
      int totalVouchersDistributed = 0;

      // Fetch users sorted by the oldest last order for half the vouchers
      int halfVouchers = maxVouchers ~/ 2;
      QuerySnapshot usersOldestOrderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('voucher_value', isEqualTo: 0)
          .orderBy('lastOrder', descending: false)
          .limit(halfVouchers)
          .get();

      List<Map<String, dynamic>> usersToNotify = [];
      WriteBatch batch = FirebaseFirestore.instance.batch();


      // Update vouchers for users with the oldest last order
      for (var userDoc in usersOldestOrderSnapshot.docs) {
        batch.update(userDoc.reference, {
          'voucher_value': voucherValue,
          'voucher_expiry_date': expiryDate,
        });
        print("===============================================");
        print(userDoc.id);
        print("===============================================");
        usersToNotify.add({
          'id': userDoc.id,
          'title_en': "Got a Voucher!!",
          'desc_en': "You Got a voucher of $voucherValue",
          'title_ar': "لديك قسيمة!",
          'desc_ar': "لقد حصلت على قسيمة بقيمة $voucherValue",
          'lang': "ar",
        });

        totalVouchersDistributed++;
      }

      int remainingVouchers = maxVouchers - totalVouchersDistributed;

      // Fetch users sorted by highest loyalty field for the remaining vouchers
      if (remainingVouchers > 0) {
        QuerySnapshot usersHighestLoyaltySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('voucher_value', isEqualTo: 0)
            .orderBy('loyalty', descending: true)
            .limit(remainingVouchers)
            .get();

        for (var userDoc in usersHighestLoyaltySnapshot.docs) {
          batch.update(userDoc.reference, {
            'voucher_value': voucherValue,
            'voucher_expiry_date': expiryDate,
          });
          print("===============================================");
          print(userDoc.id);
          print("===============================================");

          usersToNotify.add({
            'id': userDoc.id,

            'title_en': "Got a Voucher!!",
            'desc_en': "You Got a voucher of $voucherValue JD",
            'title_ar': "لديك قسيمة!",
            'desc_ar': "لقد حصلت على قسيمة بقيمة JD$voucherValue",
            'lang': "ar",
          });

          totalVouchersDistributed++;
        }
      }

      // Update the budget controller based on actual vouchers distributed
      setState(() {
        _budgetController.text = "${budget - (voucherValue * totalVouchersDistributed)}";
      });

      await batch.commit();

      // Send notifications to users
      if (usersToNotify.isNotEmpty) {
        await _sendNotificationsToCloud(usersToNotify);
      }

      Get.snackbar('نجاح', 'تم إرسال الحملة بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء إرسال الحملة');
    }
  }


  void _showErrorSnackbar(String message) {
    Get.snackbar('خطأ', message, backgroundColor: Colors.red, colorText: Colors.white);
  }

  Future<void> _sendNotificationsToCloud(List<Map<String, dynamic>> users) async {
    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendLocalizedNotification');
      final response = await callable.call({
        'users': users,
        'entity': 'users',
      });

      if (response.data['success']) {
        Get.snackbar('تم إرسال الإشعارات', 'تم إرسال إشعارات القسائم بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        _showErrorSnackbar('حدث خطأ أثناء إرسال الإشعارات');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء إرسال الإشعارات');
    }
  }

}
