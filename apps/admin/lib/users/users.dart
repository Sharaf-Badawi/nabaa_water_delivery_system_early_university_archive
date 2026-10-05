import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  TextEditingController _queryController = TextEditingController();
  List<Map<String, dynamic>> usersData = [];
   bool stopStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text('إدارة المستخدم', style: TextStyle(fontFamily: 'Kufam', fontSize: 22)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(

              controller: _queryController,
              decoration: InputDecoration(
                filled: true,
                hintText: 'ابحث بالبريد الإلكتروني أو الهاتف',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25)
                  ,borderSide: BorderSide(color: Colors.white)
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(

              onPressed: _queryUser,
              child: Text('بحث', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            usersData.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: usersData.length,
                itemBuilder: (context, index) {
                  return _buildUserInfo(usersData[index]);
                },
              ),
            )
                : Text('لا توجد بيانات مستخدم للعرض', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Future<void> _queryUser() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _queryController.text.trim())
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: _queryController.text.trim())
            .get();
      }

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          usersData = snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      } else {
        Get.snackbar('خطأ', 'المستخدم غير موجود', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء البحث عن المستخدم', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildUserInfo(Map<String, dynamic> userData) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blueAccent, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${userData['first_name'] ?? 'غير متوفر'} ${userData['last_name'] ?? ''}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blueAccent, size: 25),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${userData['email'] ?? 'غير متوفر'}',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blueAccent, size: 25),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${userData['phone'] ?? 'غير متوفر'}',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteUser(userData['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text('حذف', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _stopUser(userData['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:isStopped(userData) ? Colors.orange :   Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(isStopped(userData) ? Icons.pause_circle_filled : Icons.not_started_rounded, color: Colors.white),
                    label: Text(isStopped(userData) ? 'تفعيل' : 'إيقاف', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUserOrders(userData['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.shopping_bag, color: Colors.white),
                    label: Text('الطلبات', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

bool isStopped(Map<String , dynamic> userData){
    if(userData.containsKey('stop')){
      return userData['stop'];
    }
    return false;
}
  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      setState(() {
        usersData.removeWhere((user) => user['id'] == userId);
      });
      Get.snackbar('نجاح', 'تم حذف المستخدم بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حذف المستخدم', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _stopUser(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      bool currentStatus = (userSnapshot.data() as Map<String, dynamic>)['stop'] ?? false;
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'stop': !currentStatus});
      Get.snackbar('نجاح', currentStatus ? 'تم تفعيل المستخدم' : 'تم إيقاف المستخدم', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء تغيير حالة المستخدم', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  Future<void> _showUserOrders(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              var orderData = snapshot.docs[index].data() as Map<String, dynamic>;
              String orderId = snapshot.docs[index].id;
              return ListTile(
                title: Text('طلب رقم: $orderId', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('تفاصيل الطلب: ${orderData['totalCost'] ?? 'غير متوفر'}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteOrder(orderId),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء عرض الطلبات', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
      Get.snackbar('نجاح', 'تم حذف الطلب بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حذف الطلب', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

}
