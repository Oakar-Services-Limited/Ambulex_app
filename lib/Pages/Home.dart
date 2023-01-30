import 'package:ambulex_app/Components/AlertDialog.dart';
import 'package:ambulex_app/Components/DropDownSpinnerDummy.dart';
import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer2.dart';
import 'package:ambulex_app/Components/ReportButton.dart';
import 'package:ambulex_app/Pages/GettingStarted.dart';
import 'package:ambulex_app/Pages/Login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:slider_button/slider_button.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Components/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _url = Uri.parse('tel://+254702898989');

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = new FlutterSecureStorage();
  String location = '';
  String phone = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
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
      if (decoded["Latitude"] == null || decoded["Latitude"] == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GettingStarted()));
      } else {
        setState(() {
          phone = decoded["Phone"];
          lat = double.parse(decoded["Latitude"]) ?? 0.0;
          long = double.parse(decoded["Longitude"]) ?? 0.0;
          location =
              "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}";
        });
      }
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
    long = position.longitude;
    lat = position.latitude;

    setState(() {
      location = 'Current location Lat: $lat Lon: $long';
    });

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high, //accuracy of the location data
      distanceFilter: 1, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        long = position.longitude;
        lat = position.latitude;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Home",
        home: Scaffold(
            appBar: AppBar(title: const Text("Home")),
            drawer: const Drawer(child: NavigationDrawer2()),
            floatingActionButton: FloatingActionButton(
                elevation: 10.0,
                child: Icon(Icons.call),
                backgroundColor: Colors.blue,
                onPressed: () {
                  _launchUrl();
                }),
            body: Stack(children: [
              Container(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  children: [
                    Flexible(
                        flex: 2,
                        fit: FlexFit.tight,
                        child: MyMap(
                          lat: lat,
                          lon: long,
                        )),
                    Text(location),
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
                          var res =
                              await report(context, phone, "GBV", long, lat);
                          setState(() {
                            isLoading = null;
                          });

                          if (res.error == null) {
                            dialog(context, "Gender Based Violence");
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
                            DropDownSpinner(context, "Emergency Response DropDown");
                            // setState(() {
                            //   isLoading =
                            //       LoadingAnimationWidget.staggeredDotsWave(
                            //     color: Colors.blue,
                            //     size: 100,
                            //   );
                            // });

                            // var res =
                            //     await report(context, phone, "ME", long, lat);
                            // setState(() {
                            //   isLoading = null;
                            // });
                            //
                            // print("THER ERROR IS "+ res.error);
                            //
                            // if (res.error != null) {
                            //   DropDownSpinner(type: 'EMR',);
                            // }
                          }),
                    )
                  ],
                ),
              )),
              Center(child: isLoading),
            ])));
  }
}

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}

Future<Message> report(
    var context, String phone, String type, double lon, double lat) async {
  if (phone == '') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
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
      'ER_ID': ''
    }),
  );

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

Future<dynamic> dialog(dynamic context, String type) {
  return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text(type),
            content: const Text(
                'Your report was submitted successfully. Please be patient our emergency response team has been notified.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              ),
            ],
          ));
}

Future<dynamic> DropDownSpinner(dynamic context, String type) {
  List listItem = ["one", "two", "three"];
  String currentItem = listItem[index];

  return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(type),
        content: DropdownButton(
          hint: Text("Select Items"),
          dropdownColor: Colors.grey,
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 36,
          isExpanded: true,
          underline: SizedBox(),
          style: TextStyle(
              color: Colors.black,
              fontSize: 22
          ),
          value: currentItem,
          onChanged: (newValue) {
            currentItem = newValue.toString();
          },
          items: listItem.map((valueItem){
            return DropdownMenuItem(
              value: valueItem,
              child: Text(valueItem),
            );
          }).toList(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],

      ));
}
