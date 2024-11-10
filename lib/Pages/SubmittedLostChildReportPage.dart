import 'package:flutter/material.dart';
//import 'package:flutter_application_499/Pages/ViewSearchResult.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';

class SubmittedLostChildReportPage extends StatelessWidget {
  const SubmittedLostChildReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 233, 234),

      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "Submitted Lost Child Report Page",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Bona Nova',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // link to profile
            },
            icon: const Icon(
              Icons.person,
              color: Colors.white, // Change the color to white
            ),
          ),
        ],
      ),
      //------------------------------- body ----------------------------

      //-------------------------------end of body----------------------------

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor:
            Color.fromARGB(255, 221, 191, 196), // Color of selected item
        unselectedItemColor: Colors.grey, // Color of unselected item
        selectedLabelStyle: const TextStyle(
            color: Color(0xffc60223)), // Style for selected label
        unselectedLabelStyle:
            const TextStyle(color: Colors.grey), // Style for unselected label
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
