import 'dart:async';
import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:flutter/material.dart';
import '../Components/SubmitButton.dart';
import '../Components/TextInput.dart';
import '../Components/Utils.dart';
import 'package:geolocator/geolocator.dart';

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
                                      Map(lat: lat, lon: long,),
                                       TextInput(title: 'City',type: TextInputType.text ,onSubmit: (value){
              },),
                                       TextInput(
                                          title: 'Nearest Landmark',
                                          type: TextInputType.text,
                                        onSubmit: (value) {},
                                      ),
                                       TextInput(title: 'Building Name',
                                       type: TextInputType.text,
                                        onSubmit: (value) {},
                                      ),
                                       TextInput(title: 'House Number',
                                       type: TextInputType.text,
                                        onSubmit: (value) {},
                                      ),
                                      SubmitButton(
                                        label: "Submit",
                                        onButtonPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const Home()));
                                        },
                                      ),
                                    ]))))))
          ])),
    );
  }
}
