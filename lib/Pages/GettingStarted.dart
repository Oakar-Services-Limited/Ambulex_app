// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:ambulex_appv1/Components/Map.dart';
import 'package:ambulex_appv1/Components/MySelectInput.dart';
import 'package:ambulex_appv1/Components/TextLarge.dart';
import 'package:ambulex_appv1/Components/TextOakar.dart';
import 'package:ambulex_appv1/Pages/Login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/SubmitButton.dart';
import '../Components/MyTextInput.dart';
import '../Components/Utils.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GettingStarted extends StatefulWidget {
  const GettingStarted({super.key});

  @override
  State<StatefulWidget> createState() => _GettingStartedState();
}

class _GettingStartedState extends State<GettingStarted> {
  String location = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
  String email = '';
  String city = '';
  String address = '';
  String landmark = '';
  String buildingname = '';
  String houseno = '';
  String error = '';
  String id = '';
  String gender = '';
  dynamic isLoading;

  @override
  void initState() {
    getLocation();

    getToken();
    super.initState();
  }

  getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt");
    if (token!.isNotEmpty) {
      var decoded = parseJwt(token.toString());
      setState(() {
        id = decoded["UserID"];
      });
    }
  }

  getLocation() async {
    try {
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
        print(position.longitude); //Output: 80.24599079
        print(position.latitude); //Output: 29.6593457

        setState(() {
          long = position.longitude;
          lat = position.latitude;
        });
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Getting Started",
      home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: <Widget>[
            Center(
                child: Container(
                    constraints: const BoxConstraints.tightForFinite(),
                    child: SingleChildScrollView(
                        child: Form(
                            child: Center(
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      const SizedBox(
                                        height: 100,
                                      ),
                                      Image.asset('assets/images/logo.png'),
                                      const TextLarge(label: "Getting Started"),
                                      Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 0, 24, 0),
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
                                        value: '',
                                        type: TextInputType.emailAddress,
                                        onSubmit: (value) {
                                          setState(() {
                                            email = value;
                                          });
                                        },
                                      ),
                                      MySelectInput(
                                          label: 'Gender',
                                          onSubmit: (value) {
                                            setState(() {
                                              gender = value;
                                            });
                                          },
                                          list: const ['Male', 'Female'],
                                          value: gender),
                                      MyTextInput(
                                        title: 'City',
                                        value: '',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            city = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Address',
                                        value: '',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            address = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Nearest Landmark',
                                        value: '',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            landmark = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Building Name',
                                        value: '',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            buildingname = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'House Number',
                                        value: '',
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
                                            isLoading = LoadingAnimationWidget
                                                .staggeredDotsWave(
                                              color: Colors.blue,
                                              size: 100,
                                            );
                                          });
                                          var res = await update(
                                              id,
                                              email,
                                              gender,
                                              city,
                                              address,
                                              landmark,
                                              buildingname,
                                              houseno,
                                              lat,
                                              long);
                                          setState(() {
                                            isLoading = null;
                                            if (res.error == null) {
                                              error = res.success;
                                            } else {
                                              error = res.error;
                                            }
                                          });

                                          if (res.error == null) {
                                            Timer(const Duration(seconds: 2),
                                                () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          const Login()));
                                            });
                                          }
                                        },
                                      ),
                                    ])))))),
            Center(child: isLoading),
          ])),
    );
  }
}

Future<Message> update(
    String id,
    String email,
    String gender,
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
    Uri.parse('${getUrl()}users/${id}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Email': email,
      'Gender': gender,
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
    print(response.body);
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
