import 'dart:async';
import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Components/TextOakar.dart';
import 'package:ambulex_app/Pages/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final storage = new FlutterSecureStorage();
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
  var isLoading = null;

  @override
  void initState() {
    getToken();
    checkGps();
    super.initState();
  }

  getToken() async {
    var token = await storage.read(key: "jwt");
    var decoded = parseJwt(token.toString());
    if (decoded["error"] == "Invalid token") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    } else {
       print(decoded);
      setState(() {
        id = decoded["UserID"];
      });
    }
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

    setState(() {
      long = position.longitude;
      lat = position.latitude;
      location = 'Current location Lat: ' +
          lat.toString() +
          ' Lon: ' +
          long.toString();
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 10, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      print(position.longitude); //Output: 80.24599079
      print(position.latitude); //Output: 29.6593457

      setState(() {
        long = position.longitude;
        lat = position.latitude;
      });
    });
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
                                        type: TextInputType.emailAddress,
                                        onSubmit: (value) {
                                          setState(() {
                                            email = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'City',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            city = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Address',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            address = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Nearest Landmark',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            landmark = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'Building Name',
                                        type: TextInputType.text,
                                        onSubmit: (value) {
                                          setState(() {
                                            buildingname = value;
                                          });
                                        },
                                      ),
                                      MyTextInput(
                                        title: 'House Number',
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
