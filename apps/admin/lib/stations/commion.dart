import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:url_launcher/url_launcher.dart';

class CommissionPage extends StatefulWidget {
  @override
  _CommissionPageState createState() => _CommissionPageState();
}

class _CommissionPageState extends State<CommissionPage> {
  TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  double totalCommission = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العمولة',
            style: TextStyle(fontFamily: 'Kufam', fontSize: 22)),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('إجمالي العمولة المطلوبة: 0.00 دينار',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black));
                }

                double total = snapshot.data!.docs.fold(
                    0.0,
                    (sum, station) =>
                        sum + (station['required_commission'] ?? 0).toDouble());
                return Text(
                    'إجمالي العمولة المطلوبة: ${total.toStringAsFixed(2)} دينار',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black));
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => _demandCommissionForAllStations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text('طلب العمولة من جميع المحطات',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('stations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> stations =
                    snapshot.data!.docs.where((station) {
                  double requiredCommission =
                      (station['required_commission'] ?? 0).toDouble();
                  String stationName =
                      station['name']?.toString().toLowerCase() ?? "";
                  return requiredCommission > 0 &&
                      stationName.contains(searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> stationData =
                        stations[index].data() as Map<String, dynamic>;
                    String stationId = stations[index].id;
                    String stationName =
                        stationData['name'] ?? 'اسم المحطة غير متوفر';
                    String phone = stationData['phone'];

                    double requiredCommission =
                        (stationData['required_commission'] ?? 0).toDouble();

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      child: ListTile(
                        title: Text(
                          stationName,
                          style: TextStyle(
                            fontFamily: 'Kufam',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        leading: IconButton(
                            onPressed: () async {
                              try {
                                final Uri launchUri = Uri(
                                  scheme: 'tel',
                                  path: phone,
                                );
                                await launchUrl(launchUri);
                              } catch (e) {
                                print(e);
                              }
                            },
                            icon: Icon(Icons.phone)),
                        subtitle: TextFormField(
                          initialValue: requiredCommission.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'تحديث العمولة المطلوبة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onFieldSubmitted: (value) =>
                              _updateRequiredCommission(
                                  stationId, double.tryParse(value) ?? 0.0),
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

  Future<void> _demandCommissionForAllStations() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('stations').get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      List<Map<String, dynamic>> stationsToNotify = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> stationData = doc.data() as Map<String, dynamic>;
        double commision = (stationData['commision'] ?? 0).toDouble();
        double requiredCommission =
            (stationData['required_commission'] ?? 0).toDouble();
        double newRequiredCommission =
            _roundToNearestQuarter(commision + requiredCommission);

        batch.update(doc.reference, {
          'required_commission': newRequiredCommission,
          'commision': 0.0,
        });
        stationsToNotify.add({
          'id': doc.id,
          'title_en': "Commission Requested",
          'desc_en': "The commission of ${newRequiredCommission.toStringAsFixed(
              2)} JOD has been requested.",
          'title_ar': "تم طلب العمولة",
          'desc_ar': "تم طلب العمولة بمبلغ ${newRequiredCommission
              .toStringAsFixed(2)} دينار.",
          'lang': stationData['lang'] ?? 'ar',
        });
      }

      await batch.commit();
      await _sendNotificationsToCloud(stationsToNotify);
      Get.snackbar('نجاح', 'تم طلب العمولة من جميع المحطات بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء طلب العمولة',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _updateRequiredCommission(
      String stationId, double newCommission) async {
    await FirebaseFirestore.instance
        .collection('stations')
        .doc(stationId)
        .update({
      'required_commission': newCommission,
    });
    List<Map<String, dynamic>> stationsToNotify = [
      {
        'id': stationId,
        'title_en': "تم تحديث العمولة",
        'desc_en':
        "تم تحديث العمولة المطلوبة إلى ${newCommission.toStringAsFixed(2)} دينار.",

        'title_ar': "تم تحديث العمولة",
        'desc_ar':
            "تم تحديث العمولة المطلوبة إلى ${newCommission.toStringAsFixed(2)} دينار.",
        'lang':  'ar',
      }
    ];
    await _sendNotificationsToCloud(stationsToNotify);
  }

  Future<void> _sendNotificationsToCloud(
      List<Map<String, dynamic>> stations) async {
    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendLocalizedNotification');
      final response = await callable.call({
        'users': stations,
        'entity': 'stations',
      });
      if (response.data['success']) {
        Get.snackbar('تم إرسال الإشعارات', 'تم إرسال إشعارات العمولة بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الإشعارات',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء إرسال الإشعارات',
          backgroundColor: Colors.red, colorText: Colors.white);
      print('Error calling cloud function: $e');
    }
  }

  double _roundToNearestQuarter(double value) {
    double mod = (value * 100) % 5;
    if (mod >= 2.5) {
      return value + ((5 - mod) / 100);
    } else {
      return value - (mod / 100);
    }
  }
}
