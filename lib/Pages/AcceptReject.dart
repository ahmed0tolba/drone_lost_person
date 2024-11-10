import 'dart:html';

import 'package:baseerapp/pages/HomePage.dart';
import 'package:baseerapp/pages/ViewSearchResult.dart';
import 'package:baseerapp/pages/report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
//import 'package:flutter_application_499/Pages/ViewSearchResult.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'MonitorPage.dart';
import 'MonitorPageOne.dart';

dynamic email = "", admin = "";

bool model_is_being_trained = true;
String server_message = "";

class AcceptReject extends StatefulWidget {
  AcceptReject({super.key});

  @override
  State<AcceptReject> createState() => _AcceptRejectState();
}

final _client = http.Client();
List<Map<String, String>> listOfColumns = [];

class _AcceptRejectState extends State<AcceptReject> {
  Future<void> loadSessionVariable(context) async {
    email = await SessionManager().get("email");
    admin = await SessionManager().get("admin");
    http.Response response = await _client
        .post(Uri.parse("http://127.0.0.1:13000/gettrainingstatus"));
    var responseDecoded = jsonDecode(response.body);
    model_is_being_trained = responseDecoded['model_is_being_trained'] ?? false;
    server_message = responseDecoded['message'] ?? "";
    // print(model_is_being_trained);
    Future.delayed(const Duration(seconds: 5), () {
      loadSessionVariable(context).then((listMap) {
        getReports(context).then((listMap) {
          setState(() {});
        });
      });
    });
  }

  Future<void> acceptrequestsearch(context) async {
    http.Response response = await _client.post(Uri.parse(
        "http://127.0.0.1:13000/acceptrequestsearch?adminemail=$email"));
    var responseDecoded = jsonDecode(response.body);
    // print(responseDecoded);
    if (responseDecoded['started_training'] ||
        responseDecoded['already_training']) {
      model_is_being_trained = true;
      Future.delayed(const Duration(seconds: 5), () {
        loadSessionVariable(context).then((listMap) {
          setState(() {});
        });
      });
    }
  }

  Future<void> deletereport(context, report_name) async {
    http.Response response = await _client.post(Uri.parse(
        "http://127.0.0.1:13000/deletereport?report_name=$report_name&adminemail=$email"));
    // var responseDecoded = jsonDecode(response.body);
    // print(responseDecoded);
  }

  Future<void> getReports(context) async {
    try {
      http.Response response = await _client.post(Uri.parse(
          "http://127.0.0.1:13000/getreports?email=$email&admin=$admin"));
      var responseDecoded = jsonDecode(response.body);
      if (responseDecoded['name_list'].length > 0) {
        listOfColumns = [];
        for (int k = 0; k < responseDecoded['name_list'].length; k++) {
          listOfColumns.add({
            "Child Name": responseDecoded['name_list'][k] ?? "",
            "Report Name": responseDecoded['reportname_list'][k] ?? "",
            "status": responseDecoded['status_list'][k] ?? "",
            "submitdate":
                responseDecoded['submitdate_list'][k].split('.')[0] ?? "",
            "acceptdate": responseDecoded['acceptdate_list'][k] ?? "",
            "finishdate": responseDecoded['finishdate_list'][k] ?? "",
            // "rejected": responseDecoded['rejected_list'][k] ?? 0
          });
        }
        // }
      } else {
        listOfColumns = [];
      }
    } on Exception catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    loadSessionVariable(context).then((listMap) {
      listOfColumns = [];
      getReports(context).then((listMap) {
        setState(() {});
      });
    });
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
      body: Center(
          child: SingleChildScrollView(
              child: Column(children: [
        const SizedBox(height: 30, width: 20),
        SizedBox(
            width: 350,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var i = 0; i < listOfColumns.length; i++)
                  (Container(
                      height: 150,
                      width: 350,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: (BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color.fromARGB(197, 253, 253, 253),
                      )),
                      child: Column(
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  height: 30,
                                  width: 100,
                                  margin: const EdgeInsets.all(20.0),
                                  child: Text(
                                    listOfColumns[i]["Child Name"]!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontFamily: 'Bona Nova',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 150,
                                  margin: const EdgeInsets.all(20.0),
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MonitorPageOne(),
                                            settings: RouteSettings(arguments: [
                                              listOfColumns[i]["Report Name"]
                                            ])),
                                      );
                                    },
                                    style: const ButtonStyle(
                                      alignment: Alignment
                                          .centerRight, // <-- had to set alignment
                                    ),
                                    child: const Text("View report"),
                                  ),
                                )
                              ]),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Container(
                                  height: 40,
                                  width: 100,
                                  margin: const EdgeInsets.all(20.0),
                                  child: Text(
                                    listOfColumns[i]["submitdate"]!,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Bona Nova',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 150,
                                  margin: const EdgeInsets.all(20.0),
                                  child: GestureDetector(
                                    // onTap: _enabled ? _onTap : null,
                                    onTap: model_is_being_trained
                                        ? null
                                        : () async {
                                            await deletereport(
                                                    context,
                                                    listOfColumns[i]
                                                        ["Report Name"])
                                                .then((value) =>
                                                    getReports(context).then(
                                                        (value) =>
                                                            setState(() {})));
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.red,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Delete Report",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // child: TextButton(
                                  //   onPressed:
                                  //       enable_started_training ? _onTap : null,
                                  //   onPressed: () async {
                                  //     await acceptrequestsearch(context,
                                  //         listOfColumns[i]["Report Name"]);
                                  //   },
                                  //   style: const ButtonStyle(
                                  //     alignment: Alignment
                                  //         .centerRight, // <-- had to set alignment
                                  //   ),
                                  //   child: const Text("Accept Report"),
                                  // ),
                                )
                              ]),
                        ],
                      ))),
                Container(
                  width: 300,
                  height: 80,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10)),

                  // color: Colors.blue,
                  child: Center(
                    child: GestureDetector(
                      // onTap: _enabled ? _onTap : null,
                      onTap: model_is_being_trained
                          ? null
                          : () async {
                              await acceptrequestsearch(context)
                                  .then((value) => setState(() {}));
                            },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: model_is_being_trained
                              ? Text(
                                  "Training & searching",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 47, 150, 0)),
                                )
                              : Text(
                                  "Start Training",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 47, 150, 0)),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  height: 120,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10)),

                  // color: Colors.blue,
                  child: Center(
                      child: Text(
                    server_message,
                    style: TextStyle(
                        fontSize: 18, color: Color.fromARGB(255, 47, 150, 0)),
                  )),
                ),
              ],
            ))
      ]))),

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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Monitoring',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
