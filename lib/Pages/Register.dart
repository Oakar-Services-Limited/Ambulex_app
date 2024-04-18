import 'package:ambulex_users/Components/Map.dart';
import 'package:ambulex_users/Components/MySelectInput.dart';
import 'package:ambulex_users/Components/NavigationButton.dart';
import 'package:ambulex_users/Components/TextLarge.dart';
import 'package:ambulex_users/Components/TextOakar.dart';
import 'package:ambulex_users/Pages/GettingStarted.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../Components/SubmitButton.dart';
import '../Components/MyTextInput.dart';
import 'Login.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Components/Utils.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String error = '';
  String phone = '';
  String name = '';
  String password = '';
  String email = '';
  String city = '';
  String address = '';
  String landmark = '';
  String buildingname = '';
  String houseno = '';
  String gender = '';
  double long = 0.0, lat = 0.0;
  late Position position;
  String location = '';
  bool successful = false;
  var isLoading = null;

  @override
  void initState() {
    getLocation();
    super.initState();
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
      title: "Register",
      home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: <Widget>[
            Center(
                child: Container(
                    constraints: const BoxConstraints.tightForFinite(),
                    child: SingleChildScrollView(
                        child: Form(
                            child: Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                          Image.asset('assets/images/logo.png'),
                          const TextLarge(label: "Register"),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                              child: SizedBox(
                                height: 250,
                                child: MyMap(
                                  lat: lat,
                                  lon: long,
                                ),
                              )),
                          MyTextInput(
                            title: 'Full Name',
                            value: '',
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                name = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Phone Number',
                            value: '',
                            type: TextInputType.phone,
                            onSubmit: (value) {
                              setState(() {
                                phone = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Email',
                            value: '',
                            type: TextInputType.emailAddress,
                            onSubmit: (value) {
                              setState(() {
                                email = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Password',
                            value: '',
                            type: TextInputType.visiblePassword,
                            onSubmit: (value) {
                              setState(() {
                                password = value;
                              });
                            }, lines: 1,
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
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Address',
                            value: '',
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                address = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Nearest Landmark',
                            value: '',
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                landmark = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'Building Name',
                            value: '',
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                buildingname = value;
                              });
                            }, lines: 1,
                          ),
                          MyTextInput(
                            title: 'House Number',
                            value: '',
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                houseno = value;
                              });
                            }, lines: 1,
                          ),
                          TextOakar(label: error, issuccessful: successful),
                          SubmitButton(
                            label: "Submit",
                            onButtonPressed: () async {
                              setState(() {
                                isLoading =
                                    LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.blue,
                                  size: 100,
                                );
                              });
                              var res = await register(
                                  name,
                                  phone,
                                  email,
                                  password,
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
                                  successful = true;

                                  error = res.success;
                                } else {
                                  successful = true;

                                  error = res.error;
                                }
                              });

                              if (res.error == null) {
                                Timer(const Duration(seconds: 2), () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const Login()));
                                });
                              }
                            },
                          ),
                          const NavigationButton(
                              label: "Login", object: Login()),
                          const TextOakar(
                              label: "Powered by \n Oakar Services Ltd.")
                        ])))))),
            Center(child: isLoading),
          ])),
    );
  }
}

Future<Message> register(
    String name,
    String phone,
    String email,
    String password,
    String gender,
    String city,
    String address,
    String landmark,
    String buildingname,
    String houseno,
    double lat,
    double lon) async {
  if (name == '') {
    return Message(
      token: null,
      success: null,
      error: "Please enter your name!",
    );
  }
  if (phone.length != 10) {
    return Message(
      token: null,
      success: null,
      error: "Invalid phone number!",
    );
  }
  if (password.length < 5) {
    return Message(
      token: null,
      success: null,
      error: "Password is too short!",
    );
  }

  final response = await http.post(
    Uri.parse('${getUrl()}users/register'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Name': name,
      'Phone': phone,
      'Email': email,
      'Password': password,
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
