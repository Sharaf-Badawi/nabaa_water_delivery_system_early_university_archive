import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart'; // For reverse geocoding
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // For GetX state management
import 'package:station_app/InfoGathering/LocationPicker.dart';
import 'package:station_app/InfoGathering/ProducProviding.dart';
import 'package:station_app/MainPages/Home.dart';
import 'package:station_app/controllers/station.dart';

import '../controllers/ChoosedProductProvidedController.dart'; // Your GetX controller

class LocationDetailsScreen extends StatefulWidget {
  final String userId;

  LocationDetailsScreen({required this.userId});

  @override
  _LocationDetailsScreenState createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  late ProductController productController; // Late initialization


  int _locationCount = 1; // Default to 1 location
  List<LatLng> _selectedLocations = [];
  List<TimeOfDay> _activeFromTimes = [];
  List<TimeOfDay> _activeUntilTimes = [];
  List<String> _streetNames = []; // Store street names for each location

  @override
  void initState() {
    super.initState();
    productController = Get.put(ProductController()); // Ensure the controller is instantiated
    _initializeLocations(_locationCount); // Initialize the data
  }

  // Helper method to initialize lists based on the selected location count
  void _initializeLocations(int count) {
    _selectedLocations = List.generate(count, (_) => LatLng(32.5514, 35.8515)); // Default location
    _activeFromTimes = List.generate(count, (_) => TimeOfDay.now());
    _activeUntilTimes = List.generate(count, (_) => TimeOfDay.now());
    _streetNames = List.generate(count, (_) => ""); // Initialize empty street names
  }

  // Reverse geocoding method to get street name from coordinates
  Future<void> _getStreetName(int index) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocations[index].latitude,
        _selectedLocations[index].longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          _streetNames[index] = placemarks[0].street ?? "Unknown street";
        });
      }
    } catch (e) {
      print("Error getting street name: $e");
      setState(() {
        _streetNames[index] = "Street not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(title: Text("إعداد جداول العمل"), backgroundColor: Colors.lightBlue),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("عدد المواقع التي تغطيها المحطة في اليوم: "),
                DropdownButton<int>(
                  value: _locationCount,
                  items: List.generate(10, (index) => index + 1) // Dropdown for 1 to 10 locations
                      .map((value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  ))
                      .toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _locationCount = newValue;
                        _initializeLocations(_locationCount); // Reinitialize the lists
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _locationCount,
              itemBuilder: (context, index) {
                return _buildLocationCard(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.lightBlueAccent,
        onPressed: () {
          saveLocationsToFirestore();
        },
        child: Icon(Icons.check),
      ),
    );
  }

  // Method to build a location card
  Widget _buildLocationCard(int index) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("  الموقع ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              title: Text("اختر الموقع على الخريطة"),
              trailing: Icon(Icons.map),
              subtitle: Text(_streetNames[index]), // Display street name
              onTap: () async {
                LatLng location = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LocationPickerMapScreen()), // Implement your map picker here
                );
                setState(() {
                  _selectedLocations[index] = location;
                });
                _getStreetName(index); // Fetch the street name after selecting the location
              },
            ),
            ListTile(
              title: Text("نشط في هذا الموقع "),
              trailing: Icon(Icons.timer),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: _activeFromTimes[index]);
                if (picked != null) {
                  setState(() {
                    _activeFromTimes[index] = picked;
                  });
                }
              },
              subtitle: Text("من: ${_activeFromTimes[index].format(context)}"),
            ),
            ListTile(
              title: Text("نشط في هذا الموقع "),
              trailing: Icon(Icons.timer_off),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(context: context, initialTime: _activeUntilTimes[index]);
                if (picked != null) {
                  setState(() {
                    _activeUntilTimes[index] = picked;
                  });
                }
              },
              subtitle: Text("إلى: ${_activeUntilTimes[index].format(context)}"),
            ),
            // Redirect to product selection screen for this location
            ListTile(
              title: Text("إختر المنتجات وتسعيرها في هذا الموقع"),
              trailing: Icon(Icons.arrow_forward_ios_outlined),
              onTap: () async {
                // Navigate to the product selection screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductSelectionScreen(
                      locationIndex: index, // Pass the current location index
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Convert TimeOfDay to DateTime
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // Save the collected data to Firestore
  void saveLocationsToFirestore() async {
    for (int i = 0; i < _locationCount; i++) {
      DateTime activeFromDateTime = _timeOfDayToDateTime(_activeFromTimes[i]);
      DateTime activeUntilDateTime = _timeOfDayToDateTime(_activeUntilTimes[i]);

      Timestamp activeFromTimestamp = Timestamp.fromDate(activeFromDateTime);
      Timestamp activeUntilTimestamp = Timestamp.fromDate(activeUntilDateTime);

      // Get selected products for the current location from the GetX controller
      Map<String, Map<String, double>> selectedProducts = productController.getSelectedProductsForLocation(i);

      await FirebaseFirestore.instance.collection('stations').doc(widget.userId).update({
        'locations': FieldValue.arrayUnion([
          {
            'location': GeoPoint(_selectedLocations[i].latitude, _selectedLocations[i].longitude),
            'active_from': activeFromTimestamp,
            'active_until': activeUntilTimestamp,
            'street_name': _streetNames[i], // Save the street name
            'products': selectedProducts.entries.map((entry) {
              return {
                'product_id': entry.key,
                'floor_prices': entry.value,
              };
            }).toList(), // Save selected products for this location
          }
        ])
      });
    }

    // Navigate to Home page after saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Home(userId: widget.userId)),
    );
  }
}
