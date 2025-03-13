// ignore_for_file: use_build_context_synchronously, file_names, unused_import, avoid_init_to_null, prefer_typing_uninitialized_variables

import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:ambulex_users/Components/Map.dart';
import 'package:ambulex_users/Components/ReportButton.dart';
import 'package:ambulex_users/Components/Utils.dart';
import 'package:ambulex_users/Pages/GettingStarted.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:ambulex_users/Pages/Register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

final Uri _url = Uri.parse('tel://+254702898989');

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = const FlutterSecureStorage();

  String location = '';
  String phone = '';
  String id = '';
  String category = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
  var isLoading = null;

  @override
  void initState() {
    getLocation();
    authenticateUser();
    super.initState();
  }

  authenticateUser() async {
    try {
      var token = await storage.read(key: "jwt");
      var decoded = parseJwt(token.toString());

      if (decoded != null) {
        setState(() {
          phone = decoded["Phone"];
          id = decoded["UserID"]!;
          location =
              "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}";
        });
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {}
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
        } else if (permission == LocationPermission.deniedForever) {
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        getLocation();
      }
    } else {}

    setState(() {
      //refresh the UI
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    long = position.longitude;
    lat = position.latitude;

    setState(() {
      location = 'Current location Lat: $lat Lon: $long';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Home",
        home: Scaffold(
            appBar: AppBar(
              title: Text("Home",
                  style: GoogleFonts.lato(
                    fontSize: 24,
                  )),
              backgroundColor: Colors.blue,
            ),
            drawer: const Drawer(child: MyDrawer()),
            floatingActionButton: FloatingActionButton(
                elevation: 10.0,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                onPressed: () {
                  _launchUrl();
                },
                child: const Icon(Icons.call)),
            body: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Column(
                  children: [
                    Flexible(
                        flex: 2,
                        fit: FlexFit.tight,
                        child: MyMap(
                          lat: lat,
                          lon: long,
                        )),
                    Text(location, style: GoogleFonts.lato(fontSize: 16)),
                    const SizedBox(
                      height: 10,
                    ),
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: ReportButton(
                        label: "Gender Based Violence",
                        icon: Icons.handshake_sharp,
                        color1: Colors.orange,
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.blue,
                              size: 100,
                            );
                          });
                          var res = await report(
                            id,
                            context,
                            phone,
                            "GBV",
                            long,
                            lat,
                            category,
                          );
                          setState(() {
                            isLoading = null;
                          });

                          if (res.error == null) {
                            _showSuccessDialog("Gender Based Violence");
                          } else {
                            _showSnackbar(res.error);
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: ReportButton(
                        label: "Medical Emergency",
                        icon: Icons.medical_services,
                        color1: Colors.red,
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.blue,
                              size: 100,
                            );
                          });
                          var res = await report(
                              id, context, phone, "ME", long, lat, category);
                          setState(() {
                            isLoading = null;
                          });

                          if (res.error == null) {
                            _showSuccessDialog("Medical Emergency");
                          } else {
                            _showSnackbar(res.error);
                          }
                        },
                      ),
                    )
                  ],
                ),
                Center(child: isLoading),
              ]),
            )));
  }

  void _showSuccessDialog(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(type),
        content: const Text('Call for help received. Help is on the way!!'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}

Future<Message> report(String userid, var context, String phone, String type,
    double lon, double lat, String category) async {
  print("Phone: $phone");
  print("Type: $type");
  print("Lon: $lon");
  print("Lat: $lat");
  print("Category: $category");
  print("Userid: $userid");
  if (phone == '') {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const Login()));
  }

  if (lat == 0.0 || lon == 0.0) {
    return Message(
      token: null,
      success: null,
      error: "Location not acquired! Please turn on your location.",
    );
  }

  final response = await http.post(
    Uri.parse('${getUrl()}reports/create'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Phone': phone,
      'Type': type,
      'Latitude': lat,
      'Longitude': lon,
      'Status': 'Received',
      'UserID': userid
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 203) {
    print("Response body emer: ${response.body}");
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
