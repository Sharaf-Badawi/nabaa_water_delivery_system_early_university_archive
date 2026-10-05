import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StopStationsPage extends StatefulWidget {
  @override
  _StopStationsPageState createState() => _StopStationsPageState();
}

class _StopStationsPageState extends State<StopStationsPage> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إيقاف المحطات', style: TextStyle(fontFamily: 'Kufam', fontSize: 22)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن المحطة',
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> stations = snapshot.data!.docs.where((station) {
                  String stationName = station['name']?.toString().toLowerCase() ?? "";
                  return stationName.contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> stationData = stations[index].data() as Map<String, dynamic>;
                    bool isStopped = stationData.containsKey('stopped') ? stationData['stopped'] : false;
                    String stationName = stationData['name'] ?? 'اسم المحطة غير متوفر';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      child: ListTile(
                        leading: Icon(
                          isStopped ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: isStopped ? Colors.redAccent : Colors.greenAccent,
                          size: 40,
                        ),
                        title: Text(
                          stationName,
                          style: TextStyle(
                            fontFamily: 'Kufam',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(isStopped ? 'متوقفة' : 'نشطة',
                            style: TextStyle(
                              color: isStopped ? Colors.red : Colors.green,
                              fontSize: 16,
                            )),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStopped ? Colors.green : Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () => _toggleStationStatus(stations[index].id, isStopped),
                          child: Text(isStopped ? 'تفعيل' : 'إيقاف'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStationStatus(String stationId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('stations').doc(stationId).set({
        'stopped': !currentStatus,
      } ,SetOptions(merge: true));

      Get.snackbar('نجاح', currentStatus ? 'تم تفعيل المحطة' : 'تم إيقاف المحطة',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث حالة المحطة',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
