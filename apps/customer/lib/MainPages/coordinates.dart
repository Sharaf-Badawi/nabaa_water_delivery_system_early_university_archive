import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:water_delivery_app/MainPages/residentinfo.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final String userId;

  MapScreen({required this.userId});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _selectedLocation;
  LatLng? _previousLocation;
  bool _isOffline = false;
  bool _isDisposed = false;
  GoogleMapController? _mapController;

  final LatLng _irbidNorthWestBoundary = LatLng(32.6250, 35.6500); // NW corner
  final LatLng _irbidSouthEastBoundary = LatLng(32.4000, 35.9500); // SE corner

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _initializeMap();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (!_isDisposed) {
      setState(() {
        _isOffline = connectivityResult == ConnectivityResult.none;
      });
    }
  }

  Future<void> _initializeMap() async {
    try {
      LatLng? previousLocation = await getPreviousLocation(widget.userId);
      if (!_isDisposed) {
        setState(() {
          _previousLocation = previousLocation;
          _selectedLocation = _previousLocation ?? LatLng(32.5514, 35.8515);
        });
      }
      if (_previousLocation != null) {
        _moveCameraToLocation(_previousLocation!, zoomLevel: 17);
      }
    } catch (e) {
      print("Error initializing map: $e");
    }
  }

  bool _isLocationInIrbid(LatLng location) {
    return location.latitude <= _irbidNorthWestBoundary.latitude &&
        location.latitude >= _irbidSouthEastBoundary.latitude &&
        location.longitude >= _irbidNorthWestBoundary.longitude &&
        location.longitude <= _irbidSouthEastBoundary.longitude;
  }

  Future<void> saveLocation(LatLng location, String userId) async {
    if (!_isLocationInIrbid(location)) {
      Get.snackbar('', 'Selected location is outside Irbid Governorate',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      FirebaseFirestore _firestore = FirebaseFirestore.instance;
      DocumentReference userDoc = _firestore.collection('users').doc(userId);

      await userDoc.set({
        'location': GeoPoint(location.latitude, location.longitude),
        'locationSet': true,
      }, SetOptions(merge: true));
    } catch (e) {
      Get.snackbar('Error', 'Failed to save location',
          backgroundColor: Colors.red, colorText: Colors.white);
      print("Error saving location: $e");
    }
  }

  Future<LatLng?> getPreviousLocation(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc['locationSet'] == true) {
        GeoPoint location = userDoc['location'];
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      print("Error getting previous location: $e");
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('', AppLocalizations.of(context)!.location_enabled,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar('', AppLocalizations.of(context)!.location_denied,
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      LatLng currentLocation;

      if (lastKnown != null) {
        currentLocation = LatLng(lastKnown.latitude, lastKnown.longitude);
      } else {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(
          Duration(seconds: 10),
          onTimeout: () =>
          throw Exception('Unable to retrieve location within timeout'),
        );
        currentLocation = LatLng(position.latitude, position.longitude);
      }

      if (!_isDisposed) {
        _moveCameraToLocation(currentLocation, zoomLevel: 17);
      }
    } catch (e) {
      if (!_isDisposed) {
        Get.snackbar('', 'Failed to retrieve current location',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
      print("Error getting current location: $e");
    }
  }

  void _moveCameraToLocation(LatLng location, {double zoomLevel = 14}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoomLevel),
      );
      if (!_isDisposed) {
        setState(() {
          _selectedLocation = location;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? LatLng(32.5514, 35.8515),
              zoom: _previousLocation != null ? 17 : 14,
            ),
            onCameraMove: (position) {
              if (!_isDisposed) {
                setState(() {
                  _selectedLocation = position.target;
                });
              }
            },
            onMapCreated: (controller) {
              _mapController = controller;
              if (_previousLocation != null) {
                _moveCameraToLocation(_previousLocation!);
              }
            },
          ),
          Center(
            child: Icon(Icons.location_on_outlined,
                size: 40.0, color: Colors.lightBlueAccent),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.all(10),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.error_connectivity,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              icon: Icon(Icons.my_location),
              label: Text(AppLocalizations.of(context)!.current_location),
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
              onPressed: () async {
                if (_isOffline) {
                  Get.snackbar(
                      '', AppLocalizations.of(context)!.error_connectivity,
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }

                if (_selectedLocation != null &&
                    _isLocationInIrbid(_selectedLocation!)) {
                  await saveLocation(_selectedLocation!, widget.userId);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        HouseDetailsScreen(userId: widget.userId),
                  ));
                } else {
                  Get.snackbar(
                      '', AppLocalizations.of(context)!.irbid_borders,
                      backgroundColor: Colors.red, colorText: Colors.white);
                }
              },
              label: Text(AppLocalizations.of(context)!.confirm_location),
              icon: Icon(Icons.check),
            ),
          ),
        ],
      ),
    );
  }
}
