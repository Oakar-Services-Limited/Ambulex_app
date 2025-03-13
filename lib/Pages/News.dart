// ignore_for_file: file_names, library_private_types_in_public_api

import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../Scroll/NewsScrollController.dart';
import 'package:google_fonts/google_fonts.dart';

class News extends StatefulWidget {
  const News({super.key});

  @override
  State<StatefulWidget> createState() => _NewsState();
}

class _NewsState extends State<News> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String name = '';
  String title = '';
  String type = '';

  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
  var isLoading;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News"),
        backgroundColor: Colors.blue,
      ),
      drawer: const Drawer(child: MyDrawer()),
      body: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Text(
                  "News List",
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: InfiniteNewsScrollPaginatorDemo(),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}