import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:station_app/InfoGathering/LocationsData.dart';
import 'package:station_app/controllers/station.dart';
import '../InfoGathering/LocationPicker.dart';

class SchedulePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the StationController
    final stationController = Get.find<StationController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("جدول عمل المحطة"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Obx(() {
        if (stationController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final locations = stationController.stationData['locations'] ?? [];

        if (locations.isEmpty) {
          return Center(child: Text("No Locations Found"));
        }

        return ListView.builder(
          itemCount: locations.length,
          itemBuilder: (context, index) {
            var location = locations[index];
            GeoPoint geoPoint = location['location'];
            Timestamp activeFrom = location['active_from'];
            Timestamp activeUntil = location['active_until'];
            String streetName = location['street_name'] ?? 'Unknown Street';

            return _buildLocationCard(
              context,
              index,
              geoPoint,
              activeFrom,
              activeUntil,
              streetName,
              stationController,
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          _showDialog(context, stationController);
        },
        child: Icon(Icons.change_circle_outlined, size: 45),
      ),
    );
  }

  Widget _buildLocationCard(
      BuildContext context,
      int index,
      GeoPoint geoPoint,
      Timestamp activeFrom,
      Timestamp activeUntil,
      String streetName,
      StationController stationController,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("  الموقع ${index + 1}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ListTile(
              title: Text("اختر الموقع على الخريطة"),
              trailing: Icon(Icons.map),
              subtitle: Text(streetName), // Show the street name
              onTap: () async {
                LatLng newLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationPickerMapScreen(),
                  ),
                );
                stationController.updateLocationField(index, 'location',
                    GeoPoint(newLocation.latitude, newLocation.longitude));
              },
            ),
            ListTile(
              title: Text("نشط في هذا الموقع"),
              trailing: Icon(Icons.timer),
              subtitle: Text("من: ${activeFrom.toDate().toLocal()}"),
              onTap: () async {
                TimeOfDay? newTime = await showTimePicker(
                    context: context,
                    initialTime:
                    TimeOfDay.fromDateTime(activeFrom.toDate()));
                if (newTime != null) {
                  stationController.updateLocationField(
                    index,
                    'active_from',
                    Timestamp.fromDate(_timeOfDayToDateTime(newTime)),
                  );
                }
              },
            ),
            ListTile(
              title: Text("نشط في هذا الموقع"),
              trailing: Icon(Icons.timer_off),
              subtitle: Text("إلى: ${activeUntil.toDate().toLocal()}"),
              onTap: () async {
                TimeOfDay? newTime = await showTimePicker(
                    context: context,
                    initialTime:
                    TimeOfDay.fromDateTime(activeUntil.toDate()));
                if (newTime != null) {
                  stationController.updateLocationField(
                    index,
                    'active_until',
                    Timestamp.fromDate(_timeOfDayToDateTime(newTime)),
                  );
                }
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  stationController.removeLocation(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDialog(
      BuildContext context, StationController stationController) async {
    await showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("تحذير"),
          content: Text("سيتم حذف جدول العمل هذا حتى تستطيع وضع جدول جديد"),
          actions: [
            TextButton(
              onPressed: () async {
                stationController.clearLocations();
                Get.to(() => LocationDetailsScreen(userId: stationController.stationId,));
              },
              child: Text("تأكيد"),
            ),
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text("إلغاء"),
            ),
          ],
        );
      },
    );
  }

  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }
}
