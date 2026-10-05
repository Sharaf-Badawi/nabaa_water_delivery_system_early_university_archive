import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StationController extends GetxController {
  var stationData = {}.obs; // Reactive map to store station data
  var isLoading = true.obs; // Reactive boolean to track loading state

  final String stationId; // Pass station ID dynamically if needed

  StationController(this.stationId);

  @override
  void onInit() {
    super.onInit();
    fetchStationData(); // Fetch data when controller is initialized
  }

  Future<void> fetchStationData() async {
    try {
      isLoading.value = true;

      // Fetch the document from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('stations') // Your collection name
          .doc(stationId) // Use the station ID dynamically
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract the required fields
        stationData.value = {
          "name": data['name'],
          "phone": data['phone'],
          "commision": data['commision'],
          "totalcosts": data['totalcosts'],
          "locations": data['locations'],
          "required_commission" : data['required_commission'],// Store the entire locations array
          "equity" : data['equity'] ?? 0.06,
          "stopped" : data['stopped'] ?? false
        };
      } else {
        print("Station not found");
      }
    } catch (e) {
      print("Error fetching station data: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> updateStationData(String field, dynamic value) async {
    try {
      isLoading.value = true;

      // Ensure Firestore is updated with the correct type
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .update({field: value});

      // Update local state reactively
      stationData[field] = value;
      Get.snackbar('Success', '$field updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update $field: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLocationField(int index, String field, dynamic value) async {
    try {
      isLoading.value = true;
      var locations = List<Map<String, dynamic>>.from(stationData['locations']);
      locations[index][field] = value;
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .update({'locations': locations});
      stationData['locations'] = locations; // Update local state reactively
    } catch (e) {
      Get.snackbar('Error', 'Failed to update $field');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeLocation(int index) async {
    try {
      isLoading.value = true;
      var locations = List<Map<String, dynamic>>.from(stationData['locations']);
      locations.removeAt(index);
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .update({'locations': locations});
      stationData['locations'] = locations; // Update local state reactively
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete location');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearLocations() async {
    try {
      isLoading.value = true;
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(stationId)
          .update({'locations': []});
      stationData['locations'] = []; // Clear local state
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear locations');
    } finally {
      isLoading.value = false;
    }
  }

}
