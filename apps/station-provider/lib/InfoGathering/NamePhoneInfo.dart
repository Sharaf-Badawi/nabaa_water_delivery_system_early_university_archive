import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_app/Auth/consent.dart';
import 'package:station_app/InfoGathering/LocationsData.dart';

class AddStationInfo extends StatefulWidget {
  final String userId;

  AddStationInfo({required this.userId});

  @override
  _AddStationInfoState createState() => _AddStationInfoState();
}

class _AddStationInfoState extends State<AddStationInfo> {
  final _formKey = GlobalKey<FormState>();
  final _stationNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(title: Text("معلومات المحطة"),backgroundColor: Colors.lightBlue,),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _stationNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'أدخل اسم المحطة';
                  }
                  return null;
                },
                cursorColor: Colors.black,
                decoration: InputDecoration(

                  filled:  true,
                  fillColor:  Colors.white,
                  labelText: "اسم المحطة",
                  labelStyle: TextStyle(color: Colors.black,fontSize: 14),

                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.lightBlueAccent))
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المحطة';
                  }
                  if(value.length  > 10 || value.length < 10 )
                    return "يرجى إدخال رقم صحيح";
                  return null;
                },
                cursorColor: Colors.black,
                decoration: InputDecoration(

                    filled:  true,
                    fillColor:  Colors.white,
                    labelText: "رقم هاتف المحطة",
                    labelStyle: TextStyle(color: Colors.black,fontSize: 14),

                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),borderSide: BorderSide(color: Colors.white)),
                    focusedBorder: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.lightBlueAccent))
                ),
              ),
              SizedBox(height: 32.0),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.white),
                                    onPressed: _saveStationInfo,
                                    child: Text("حفظ"),
                                  ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveStationInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Save station info in Firestore
      await FirebaseFirestore.instance.collection('stations')
          .doc(widget.userId)
          .set({
        'name': _stationNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'locations' : FieldValue.arrayUnion([]),
        'commision' : 0.0,
        'totalcosts' : 0.0,
        'required_commission' : 0.0,
'stopped': false,
        'equity' : 0.06,
        'notificationToken' : await FirebaseMessaging.instance.getToken()
      });

      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) =>
          ConsentPage(userId: widget.userId),));
      // After saving, navigate to Home page
    }
  }
}
