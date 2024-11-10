import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/ViewSearchResult.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'MonitorPage.dart';

String reportname = "";
String name = "";
String status = "";
String submitdate = "",
    acceptdate = "",
    finishdate = "",
    bestimage = "",
    result_lat = "",
    result_lng = "";
int rejected = 0, conf = 0;

List<Map<String, String>> listOfColumns = [];

//import 'package:flutter_application_499/Pages/ViewSearchResult.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';
dynamic email = "", admin = "";
Future<void> loadSessionVariable(context) async {
  email = await SessionManager().get("email");
  admin = await SessionManager().get("admin");
  List<dynamic>? args = ModalRoute.of(context)!.settings.arguments as List?;
  reportname = args![0] as String;
  print(reportname);
}

class MonitorPageOne extends StatefulWidget {
  MonitorPageOne({super.key});

  @override
  State<MonitorPageOne> createState() => _MonitorPageOneState();
}

final _client = http.Client();
CameraTargetBounds boundingbox = CameraTargetBounds(LatLngBounds(
    northeast: LatLng(27.6683619, 85.3101895),
    southwest: LatLng(27.6683619, 85.3101895)));
String originaltasknumber = '';
LatLng mapcenter = const LatLng(21.41814863010781, 39.81368911279372);

List<LatLng> polylinepointsList = [];

List<Polyline> polylineList = [
  // const Polyline(
  //     polylineId: PolylineId("1"),
  //     points: [
  //       LatLng(31.110484, 72.384598),
  //       LatLng(31.110484, 75.384598),
  //       LatLng(35.110484, 79.384598)
  //     ],
  //     color: Colors.green)
];

Set<Marker> markers = Set();
List<Marker> markersList = [
  // const Marker(
  //   markerId: MarkerId('Marker1'),
  //   position: LatLng(32.195476, 74.2023563),
  //   // infoWindow: InfoWindow(title: 'Business 1'),
  //   // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  // ),
];

late GoogleMapController mapController;

class _MonitorPageOneState extends State<MonitorPageOne> {
  @override
  void initState() {
    super.initState();
    loadSessionVariable(context).then((listMap) {
      getReport(context).then((listMap) {
        setState(() {});
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    polylinepointsList = [];
    polylineList = [];
    polylineList.clear();
    setState(() {});
    // getroute().then((listMap) {
    //   setState(() {});
    // });
  }

  Future<void> getReport(context) async {
    try {
      http.Response response = await _client.post(Uri.parse(
          "http://127.0.0.1:13000/getreport?reportname=$reportname&admin=$admin&email=$email"));
      var responseDecoded = jsonDecode(response.body);
      print(responseDecoded);
      name = responseDecoded['name'];
      status = responseDecoded['status'];
      submitdate = responseDecoded['submitdate'];
      acceptdate = responseDecoded['acceptdate'];
      finishdate = responseDecoded['finishdate'];
      rejected = responseDecoded['rejected'];
      conf = responseDecoded['conf'];
      bestimage = responseDecoded['bestimage'];
      result_lat = responseDecoded['result_lat'];
      result_lng = responseDecoded['result_lng'];
      if (result_lat != "") {
        mapcenter = LatLng(double.parse(result_lat), double.parse(result_lng));
        markersList = [
          Marker(
            markerId: MarkerId('Marker1'),
            position: LatLng(mapcenter.latitude, mapcenter.longitude),
            // infoWindow: InfoWindow(title: 'Business 1'),
            // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        ];
      }
      if (responseDecoded['same_color_images'].length > 0) {
        listOfColumns = [];
        for (int k = 0; k < responseDecoded['same_color_images'].length; k++) {
          listOfColumns.add({
            "same color image": responseDecoded['same_color_images'][k] ?? "",
          });
        }
      } else {
        listOfColumns = [];
      }
    } on Exception catch (_) {}
  }

  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    _selectedIndex = index;
    if (index == 0) {
      // If "home" button is tapped (index 0), navigate to the home page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const HomePage()), // Navigate to ReportPage
      );
    } else if (index == 1) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Report()), // Navigate to ReportPage
      );
    } else if (index == 2) {
      // If "Report" button is tapped (index 1), navigate to the Report page
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MonitorPage()), // Navigate to ReportPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 233, 234),

      appBar: AppBar(
        backgroundColor: const Color(0xffc60223),
        title: const Center(
          child: Text(
            "Monitor lost child reports",
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
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        child: Column(children: [
          const SizedBox(height: 30, width: 20),
          Text(
            "$name's Report : ",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 30, width: 20),
          if (status == "found")
            Column(children: [
              Text(
                "We found your child.",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Text(
                "This picture shows your child:",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              if (conf > 0)
                Image.network(
                  "http://127.0.0.1:13000/${bestimage}",
                  height: MediaQuery.of(context).size.height / 4,
                ),
              if (conf == 0)
                for (var i = 0; i < listOfColumns.length; i++)
                  Image.network(
                    "http://127.0.0.1:13000/TestingImages/${listOfColumns[i]["same color image"]!}",
                    height: MediaQuery.of(context).size.height / 4,
                  ),
              const SizedBox(height: 30, width: 20),
              Text(
                "The time this picture was taken:",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              Text(
                finishdate,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Text(
                "Confidence : $conf",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 30, width: 20),
              Container(
                width: 300,
                height: 300,
                child: GoogleMap(
                  cameraTargetBounds: boundingbox,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: mapcenter,
                    zoom: 6.0,
                  ),
                  markers: Set.from(markersList),
                  polylines: Set.from(polylineList),
                ),
              ),
            ])
        ]),
      ))),

      //-------------------------------end of body----------------------------

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xffc60223), // Color of selected item
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
