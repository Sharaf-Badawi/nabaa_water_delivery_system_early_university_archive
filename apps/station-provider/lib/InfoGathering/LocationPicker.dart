import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerMapScreen extends StatefulWidget {
  @override
  _LocationPickerMapScreenState createState() => _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  LatLng _center = LatLng(32.5514, 35.8515); // Default starting location
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إختر الموقع")),
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (CameraPosition position) {
              // Update the center position as the map moves
              _center = position.target;
            },
          ),
          // Centered pin icon
          Center(
            child: Icon(Icons.location_on_outlined, size: 50, color: Colors.lightBlueAccent),
          ),
          // Save location button
          Positioned(

            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent,foregroundColor: Colors.white),
                            onPressed: () {
                // Pass the current map center coordinates when button is pressed
                Navigator.pop(context, _center);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Text("تأكيد",style: TextStyle(fontSize: 16),),
                  Icon(Icons.check,size: 25,)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
