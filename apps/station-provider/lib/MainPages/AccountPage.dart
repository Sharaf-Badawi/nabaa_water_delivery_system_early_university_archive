import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:station_app/Auth/Login.dart';
import 'package:station_app/MainPages/OrdersHistory.dart';
import 'package:station_app/controllers/station.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the StationController globally
    final StationController stationController = Get.find<StationController>();
bool isStopped = stationController.stationData['stopped'] ?? false;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text("معلومات المحطة"),
        centerTitle: true,
      ),
      body: Obx(() {
        // Show loading indicator if data is being fetched
        if (stationController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        // Display the account page content
        final stationData = stationController.stationData;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Station Name Edit Field
                Card(
                  color: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildEditableField(
                          "اسم المحطة",
                          stationData['name'] ?? 'Unknown Station',
                              (value) => stationController.updateStationData('name', value),
                        ),
                        SizedBox(height: 20),
                        _buildEditableField(
                          "رقم هاتف المحطة",
                          stationData['phone'] ?? 'No phone available',
                              (value) => stationController.updateStationData('phone', value),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Orders History Button
                ElevatedButton(
                  onPressed: () {
                    Get.to(() => CompletedOrdersPage(stationId: stationController.stationId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    elevation: 5,
                  ),
                  child: Text(
                    "سجل الطلبات",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                // Sign Out Button
                ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Get.offAll(() => Login());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    elevation: 5,
                  ),
                  child: Text(
                    "تسجيل الخروج",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

// Add this immediately after the "Log Out" button
                if (isStopped) ...[
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "المحطة متوقفة",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],


              ],
            ),

          ),
        );
      }),
    );
  }

  // Reusable editable text field widget
  Widget _buildEditableField(String label, String value, Function(String) onSave) {
    final TextEditingController controller = TextEditingController(text: value);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (newValue) {
              onSave(newValue);
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.save, color: Colors.lightBlueAccent),
          onPressed: () => onSave(controller.text),
        ),
      ],
    );
  }
}
