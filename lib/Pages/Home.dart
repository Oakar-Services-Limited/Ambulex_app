import 'package:ambulex_app/Components/AlertDialog.dart';
import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer.dart';
import 'package:ambulex_app/Components/ReportButton.dart';
import 'package:flutter/material.dart';
import 'package:slider_button/slider_button.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String location = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;

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

    LocationSettings locationSettings = LocationSettings(
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
        title: "Home",
        home: Scaffold(
          appBar: AppBar(title: const Text("Home")),
          drawer: const Drawer(child: NavigationDrawer()),
          body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
                const Map(),
                const SizedBox(
                  height: 10,
                ),
                Text(location),
                const SizedBox(
                  height: 10,
                ),
                Center(
                    child: SliderButton(
                  action: () {
                    setState(() {
                      location =
                          'Using saved location Lon: 36.1578 Lat: -1.4552';
                    });
                    location = 'Using saved location Lon: 36.1578 Lat: -1.4552';
                  },
                  label: const Text(
                    "Use saved location",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 16),
                  ),
                  icon: const Center(
                      child: Icon(
                    Icons.location_pin,
                    color: Colors.white,
                    size: 24,
                    semanticLabel: 'Current Location',
                  )),
                  buttonSize: 40,
                  height: 42,
                  radius: 40,
                  buttonColor: Colors.blue,
                  backgroundColor: Colors.orange,
                  highlightedColor: Colors.blue,
                  baseColor: Colors.white,
                )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: <Widget>[
                      ReportButton(
                        label: "Gender Based Violence",
                        icon: Icons.handshake_sharp,
                        color1: const Color.fromARGB(255, 251, 189, 107),
                        color2: Colors.deepOrange,
                        onButtonPressed: () {
                          report("GBV", long, lat);
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ReportButton(
                          label: "Medical Emergency",
                          icon: Icons.medical_services,
                          color1: const Color.fromARGB(255, 251, 107, 225),
                          color2: Colors.red,
                          onButtonPressed: () {
                            report("ME", long, lat);
                          }),
                     MyAlertDialog(type: "Gender Based Violence")     
                    ],
                  ),
                )
              ]))
              
              ),
        ));
  }
}

Future<Message> report(String type, double lon, double lat) async {
  final response = await http.post(
    Uri.parse('http://192.168.1.114:3002/api/reports/create'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Phone': '0714816920',
      'Type': type,
      'Latitude': lat,
      'Longitude': lon
    }),
  );

  print(response.body);

  if (response.statusCode == 200 || response.statusCode == 203) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Message.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    return Message(
      token: null,
      success: null,
      error: "Connection to server failed!",
    );
  }
  // return Message(
  //   token: null,
  //   success: null,
  //   error: "Connection to server failed!",
  // );
}

class Message {
  var token;
  var success;
  var error;

  Message({
    required this.token,
    required this.success,
    required this.error,
  });

  factory Message.fromJson(json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  return await Geolocator.getCurrentPosition();
}
