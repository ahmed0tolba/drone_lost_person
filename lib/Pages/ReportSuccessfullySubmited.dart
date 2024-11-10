import 'dart:convert';

import 'package:baseerapp/Pages/MonitorPage.dart';
import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:baseerapp/Pages/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_application_499/Pages/HomePage.dart';
import 'package:baseerapp/pages/my_button.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import "package:http/http.dart" as http;
import 'HomePage.dart';
import 'components/my_textfield.dart';

class ReportSuccessfullySubmited extends StatelessWidget {
  const ReportSuccessfullySubmited({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
            child: Center(
          child: Column(children: [
            //empty space in the top
            const SizedBox(height: 50),
            const Icon(
              Icons.check_circle_outlined,
              color: Colors.greenAccent,
              size: 200.0,
              semanticLabel: 'Submitted successfully',
            ),
            const Text(
              "Report Successfully Submited",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontFamily: 'Bona Nova',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            // logo

            //empty space after the icon

            //Log In Text title
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => Report()));
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(color: Colors.grey),
                child: const Text("Create New Report"),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MonitorPage()));
              },
              child: Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(color: Colors.grey),
                child: const Text("View All Reports"),
              ),
            ),
          ]),
        )));
  }
}
