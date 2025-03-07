// ignore_for_file: file_names, library_private_types_in_public_api

import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../Scroll/NewsScrollController.dart';

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
    // flutterLocalNotificationsPlugin.cancelAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "News",
        home: Scaffold(
          // Puts appbar at the top of the page
          appBar: AppBar(title: const Text("News")),
          //Adds a navigation menu at the side
          drawer: const Drawer(child: MyDrawer()),
          body: const Column(children: <Widget>[
            Align(
                alignment: Alignment.topCenter,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      "News List",
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ))),
            // Creates a scrollable list of client calls below
            Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: InfiniteNewsScrollPaginatorDemo()),
            SizedBox(
              height: 12,
            )
          ]),
        ));
  }
}



//comment