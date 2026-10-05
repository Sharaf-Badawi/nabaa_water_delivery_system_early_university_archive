import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:water_delivery_app/MainPages/products.dart';

class HouseDetailsScreen extends StatefulWidget {
  final String userId;

  HouseDetailsScreen({required this.userId});

  @override
  _HouseDetailsScreenState createState() => _HouseDetailsScreenState();
}

class _HouseDetailsScreenState extends State<HouseDetailsScreen> {
  final TextEditingController _buildingNameController = TextEditingController();
  TextEditingController _apratmentnumbercontroller = TextEditingController();
  String? _selectedFloor;
  List<String> floors = ['G', '1', '2', '3', '4'];
  GlobalKey<FormState> key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadHouseDetails(); // Load previous details if available
  }

  // Load previous house details from Firestore
  Future<void> _loadHouseDetails() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        _buildingNameController.text = userDoc['buildingName'] ?? '';
        _apratmentnumbercontroller.text = userDoc['apartment_num'] ?? '';
        // Load building name
        _selectedFloor = userDoc['floor'] ?? null; // Load selected floor
      });
    }
  }

  // Save house details to Firestore
  Future<void> saveHouseDetails(
      String buildingName, String floor, String userId, String apartnum) async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentReference userDoc = _firestore.collection('users').doc(userId);

    return userDoc.update({
      'buildingName': buildingName,
      'floor': floor,
      'apartment_num': apartnum
    }).catchError((error) {
      userDoc.set({
        'buildingName': buildingName,
        'floor': floor,
        'apartment_num': apartnum
      });
    });
  }

  // Clear selected products from SharedPreferences

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.house_details),
      ),
      body: Form(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Building Name Input
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return AppLocalizations.of(context)!.enter_building;
                  return null;
                },
                controller: _buildingNameController,
                decoration: InputDecoration(
                    labelStyle: TextStyle(color: Colors.lightBlueAccent),
                    labelText: AppLocalizations.of(context)!.building_name,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent))),
              ),

              SizedBox(height: 20),
              TextFormField(
                controller: _apratmentnumbercontroller,
                decoration: InputDecoration(
                    labelStyle: TextStyle(color: Colors.lightBlueAccent),
                    labelText: AppLocalizations.of(context)!.apartment_number,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent))),
              ),

              SizedBox(height: 20),
              // Floor Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFloor,
                items: floors.map((String floor) {
                  return DropdownMenuItem<String>(
                    value: floor,
                    child: Text(floor),
                  );
                }).toList(),
                decoration: InputDecoration(
                    focusColor: Colors.lightBlueAccent,
                    labelStyle: TextStyle(color: Colors.lightBlueAccent),
                    labelText: AppLocalizations.of(context)!.select_floor,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent))),
                onChanged: (value) {
                  setState(() {
                    _selectedFloor = value;
                  });
                },
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  if (_selectedFloor != null &&
                          _buildingNameController.text.isNotEmpty ||
                      key.currentState!.validate()) {
                    String apratmentnumber = '';
                    if (_apratmentnumbercontroller.text.isEmpty)
                      apratmentnumber = "غير محدد";
                    else
                      apratmentnumber = _apratmentnumbercontroller.text;
                    // Save house details
                    await saveHouseDetails(_buildingNameController.text,
                        _selectedFloor!, widget.userId, apratmentnumber);

                    // Clear previously selected products
                    Get.to(() => ProductGridScreen(userId: widget.userId));
                    // Navigate to the ProductGridScreen
                    // Navigator.of(context).push(MaterialPageRoute(
                    //     builder: (context) => ProductGridScreen(
                    //       userId: widget.userId,
                    //     )));
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
