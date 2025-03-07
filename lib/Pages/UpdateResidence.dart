// ignore_for_file: use_build_context_synchronously, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:ambulex/Components/Map.dart';
import 'package:ambulex/Components/TextOakar.dart';
import 'package:ambulex/Pages/Login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/MyDrawer.dart';
import 'package:flutter/material.dart';
import '../Components/SubmitButton.dart';
import '../Components/MyTextInput.dart';
import '../Components/Utils.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class UpdateResidence extends StatefulWidget {
  const UpdateResidence({super.key});

  @override
  State<StatefulWidget> createState() => _UpdateResidenceState();
}

class _UpdateResidenceState extends State<UpdateResidence> {
  final storage = const FlutterSecureStorage();
  String location = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  double long1 = 0.0, lat1 = 0.0;
  late StreamSubscription<Position> positionStream;
  String email = '';
  String city = '';
  String address = '';
  String landmark = '';
  String buildingname = '';
  String houseno = '';
  String error = '';
  String email1 = '';
  String city1 = '';
  String address1 = '';
  String landmark1 = '';
  String buildingname1 = '';
  String houseno1 = '';
  String id = '';
  var isLoading;

  @override
  void initState() {
    super.initState();
    checkGps();
    getToken();
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

    setState(() {
      long = position.longitude;
      lat = position.latitude;
      location = 'Current location Lat: $lat Lon: $long';
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 10, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        long = position.longitude;
        lat = position.latitude;
      });
    });
  }

  Future<bool> getToken() async {
    var token = await storage.read(key: "erjwt");
    var decoded = decodeJwtToken(token.toString());

    if (decoded != null) {
      if (decoded["error"] == "Invalid token") {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return false;
      } else {
        setState(() {
          id = decoded["UserID"];
          email1 = decoded["Email"];
          city1 = decoded["City"];
          address1 = decoded["Address"];
          landmark1 = decoded["Landmark"];
          buildingname1 = decoded["BuildingName"];
          houseno1 = decoded["HouseNumber"];
          lat = double.parse(decoded["Latitude"]);
          long = double.parse(decoded["Longitude"]);
          location =
              "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}";
        });
        return true;
      }
    } else
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        drawer: const Drawer(child: MyDrawer()),
        body: Stack(children: [
          SingleChildScrollView(
              child: Column(children: <Widget>[
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: SizedBox(
                  height: 250,
                  child: MyMap(
                    lat: lat,
                    lon: long,
                  ),
                )),
            Text(location),
            TextOakar(label: error),
            MyTextInput(
              title: 'Email',
              value: email1,
              type: TextInputType.emailAddress,
              onSubmit: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            MyTextInput(
              title: 'City',
              value: city1,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  city = value;
                });
              },
            ),
            MyTextInput(
              title: 'Address',
              value: address1,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  address = value;
                });
              },
            ),
            MyTextInput(
              title: 'Nearest Landmark',
              value: landmark1,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  landmark = value;
                });
              },
            ),
            MyTextInput(
              title: 'Building Name',
              value: buildingname1,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  buildingname = value;
                });
              },
            ),
            MyTextInput(
              title: 'House Number',
              value: houseno1,
              type: TextInputType.text,
              onSubmit: (value) {
                setState(() {
                  houseno = value;
                });
              },
            ),
            SubmitButton(
              label: "Submit",
              onButtonPressed: () async {
                setState(() {
                  isLoading = LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.blue,
                    size: 100,
                  );
                });
                var res = await update(
                  id,
                  email == '' ? email1 : email,
                  city == '' ? city1 : city,
                  address == '' ? address1 : address,
                  landmark == '' ? landmark1 : landmark,
                  buildingname == '' ? buildingname1 : buildingname,
                  houseno == '' ? houseno1 : houseno,
                  lat == 0.0 ? lat1 : lat,
                  long == 0.0 ? long1 : long,
                );
                setState(() {
                  isLoading = null;
                  if (res.error == null) {
                    error = res.success;
                  } else {
                    error = res.error;
                  }
                });

                if (res.error == null) {
                  Timer(const Duration(seconds: 2), () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Login()));
                  });
                }
              },
            ),
          ])),
          Center(child: isLoading),
        ]));
  }
}

Future<Message> update(
    String id,
    String email,
    String city,
    String address,
    String landmark,
    String buildingname,
    String houseno,
    double lat,
    double lon) async {
  if (lat == 0.0 || lon == 0.0) {
    return Message(
      token: null,
      success: null,
      error: "Location not acquired! Please turn on your location.",
    );
  }
  if (id == '' ||
      email == '' ||
      city == '' ||
      address == '' ||
      landmark == '' ||
      buildingname == '' ||
      houseno == '') {
    return Message(
      token: null,
      success: null,
      error: "All fields are required!",
    );
  }

  final response = await http.put(
    Uri.parse('${getUrl()}users/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Email': email,
      'City': city,
      'Address': address,
      'Landmark': landmark,
      'BuildingName': buildingname,
      'HouseNumber': houseno,
      'Latitude': lat,
      'Longitude': lon
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 203) {
    return Message.fromJson(jsonDecode(response.body));
  } else {
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

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}
