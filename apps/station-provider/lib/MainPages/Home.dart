import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_app/MainPages/AccountPage.dart';
import 'package:station_app/OrdersPage.dart';
import 'package:station_app/MainPages/SchedulePage.dart';
import 'package:station_app/controllers/station.dart';

class Home extends StatefulWidget {
  final String userId;

  const Home({super.key, required this.userId});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Track the selected index
@override
  void initState() {
  Get.put(StationController(widget.userId));

 // Ensure the controller is instantiated
    // TODO: implement initState
    super.initState();
  }
  // List of pages corresponding to the BottomNavigationBar items
  late List<Widget> _pages;

  // Handle bottom nav bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _pages  = <Widget>[
      OrdersScreen(stationId: widget.userId,),
      SchedulePage(),
      AccountPage(),
    ];
    return Scaffold(
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.grey[300],
        selectedItemColor: Colors.white,
        backgroundColor: Colors.lightBlueAccent[700],

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(

            backgroundColor: Colors.white,
            icon: Icon(Icons.water_drop_outlined),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'الجدول',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'الحساب',
          ),
        ],
        currentIndex: _selectedIndex, // Current selected index
        onTap: _onItemTapped, // Handle tap
      ),
    );
  }
}
