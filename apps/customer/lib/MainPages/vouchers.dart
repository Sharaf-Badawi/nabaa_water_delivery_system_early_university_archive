import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class VoucherPage extends StatefulWidget {
  final String userId;

  VoucherPage({required this.userId});

  @override
  _VoucherPageState createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  bool isVoucherActive = false;
  double voucherValue = 0.0;
  DateTime? voucherExpiryDate;

  @override
  void initState() {
    super.initState();
    _loadVoucherStatus();
    _fetchVoucherData();
  }

  Future<void> _loadVoucherStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isVoucherActive = prefs.getBool('isVoucherActive') ?? false;
    });
  }

  Future<void> _saveVoucherStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVoucherActive', status);
  }

  Future<void> _fetchVoucherData() async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        double currentVoucherValue = userDoc['voucher_value'] ?? 0.0;
        Timestamp? expiryTimestamp = userDoc['voucher_expiry_date'];

        DateTime now = DateTime.now();
        DateTime? expiryDate = expiryTimestamp?.toDate();

        if (expiryDate != null && expiryDate.isBefore(now)) {
          await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
            'voucher_value': 0.0,
          });
          voucherValue = 0.0;
          voucherExpiryDate = null;
        } else {
          voucherValue = currentVoucherValue;
          voucherExpiryDate = expiryDate;
        }

        setState(() {});
      }
    } catch (e) {
      print('Error fetching voucher data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: Text(
          "${AppLocalizations.of(context)!.voucher_details}",
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.lightBlue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shadowColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.voucher_activation,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Switch(
                        value: isVoucherActive,
                        onChanged: (value) {
                          setState(() {
                            isVoucherActive = value;
                            _saveVoucherStatus(value);
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  Divider(color: Colors.blueAccent.shade100, thickness: 1.5),
                  SizedBox(height: 20),
                  _infoRow(AppLocalizations.of(context)!.voucher_value, 'JD ${voucherValue.toStringAsFixed(2)}'),
                  SizedBox(height: 15),
                  _infoRow(
                    AppLocalizations.of(context)!.expiry_date,
                    voucherExpiryDate != null
                        ? DateFormat.yMMMMd().format(voucherExpiryDate!)
                        : AppLocalizations.of(context)!.no_expiry_date,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}
