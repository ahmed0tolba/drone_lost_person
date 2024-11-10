import 'package:flutter/material.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';

class ViewSearchResult extends StatelessWidget {
  const ViewSearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 233, 234),

      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "View Search Result",
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
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20, width: 20),
            Container(
              height: 680,
              width: 350,
              decoration: (BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Color.fromARGB(197, 253, 253, 253),
              )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: Text(
                            "sara's Report ",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontFamily: 'Bona Nova',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 70, width: 30),
                ],
              ),
            ),
          ],
        ),
      ),
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
