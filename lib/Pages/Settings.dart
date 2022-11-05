import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:flutter/material.dart';
import '../Components/MyTextInput.dart';
import '../Components/SubmitButton.dart';
import '../Components/Utils.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String location = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
  var isLoading = null;

  @override
  void initState() {
    checkGps();
    super.initState();
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
        } else if (permission == LocationPermission.deniedForever) {
          print("'Location permissions are permanently denied");
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        getLocation();
      }
    } else {
      print("GPS Service is not enabled, turn on GPS location");
    }

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print(position.longitude); //Output: 80.24599079
    print(position.latitude); //Output: 29.6593457

    long = position.longitude;
    lat = position.latitude;

    setState(() {
      location = 'Current location Lat: ' +
          lat.toString() +
          ' Lon: ' +
          long.toString();
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 100, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      print(position.longitude); //Output: 80.24599079
      print(position.latitude); //Output: 29.6593457

      long = position.longitude;
      lat = position.latitude;

      setState(() {
        //refresh UI on update
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Settings",
        home: Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          drawer: const Drawer(child: NavigationDrawer()),
          body: Container(
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
            MyMap(
              lat: lat,
              lon: long,
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Lon: 36.56695 Lat: -1.25854"),
            ),
            MyTextInput(
              title: 'Phone Number',
              type: TextInputType.phone,
              onSubmit: (value) {},
            ),
            MyTextInput(
              title: 'City',
              type: TextInputType.text,
              onSubmit: (value) {},
            ),
            MyTextInput(
              title: 'Street/Address',
              type: TextInputType.text,
              onSubmit: (value) {},
            ),
            MyTextInput(
              title: 'Nearest Landmark',
              type: TextInputType.text,
              onSubmit: (value) {},
            ),
            MyTextInput(
              title: 'Building Name',
              type: TextInputType.text,
              onSubmit: (value) {},
            ),
            MyTextInput(
              title: 'House Number',
              type: TextInputType.text,
              onSubmit: (value) {},
            ),
            SubmitButton(
              label: "Submit",
              onButtonPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const Home()));
              },
            ),
          ]))),
        ));
  }
}
