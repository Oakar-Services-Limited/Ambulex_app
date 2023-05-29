// ignore_for_file: use_function_type_syntax_for_parameters

import 'dart:convert';
import 'package:ambulex_app/Components/SubmitButton.dart';
import 'package:ambulex_app/Pages/News.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_map_polyline_new/google_map_polyline_new.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Utils.dart';

class MyHomePage extends StatefulWidget {
  final double mylat;
  final double mylon;
  final double dlat;
  final double dlon;
  final String id;
  final String customerID;

  const MyHomePage(
      {Key? key,
      required this.mylat,
      required this.mylon,
      required this.dlat,
      required this.dlon,
      required this.id,
      required this.customerID})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _polylineCount = 1;
  final Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  final Completer<GoogleMapController> _controller = Completer();
  final GoogleMapPolyline _googleMapPolyline =
      GoogleMapPolyline(apiKey: "AIzaSyBbEGhViFyDdJJcfl0Mgpv293jyNgTl364");
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
  );

  //Polyline patterns
  List<List<PatternItem>> patterns = <List<PatternItem>>[
    <PatternItem>[], //line
    <PatternItem>[PatternItem.dash(30.0), PatternItem.gap(20.0)], //dash
    <PatternItem>[PatternItem.dot, PatternItem.gap(10.0)], //dot
    <PatternItem>[
      //dash-dot
      PatternItem.dash(30.0),
      PatternItem.gap(20.0),
      PatternItem.dot,
      PatternItem.gap(20.0)
    ],
  ];
  late LatLng _currentLocation;
  late LatLng _mapInitLocation;
  late LatLng _destinationLocation;
  late LatLng _originLocation;
  double? _bearing = 0.0;
  double heading = 0.0;
  bool _loading = false;
  String status = "Pending";
  String label = "Get Directions";
  // String status = "Complete";
  // String label = "File Report";
  Set<Marker> markers = Set();
  var myLoc = null;
  var iLoc = null;
  var dLoc = null;

  //sensors
  bool _hasPermissions = false;
  List<LatLng> _coordinates = [];

  late final String token;

  _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _currentLocation = LatLng(widget.mylat, widget.mylon);
      _destinationLocation = LatLng(widget.mylat, widget.mylon);
      _originLocation = LatLng(widget.dlat, widget.dlon);
    });
    FlutterCompass.events!.listen((event) {
      setState(() {
        _bearing = event.heading;
      });
    });

    addMarkers();
    var loc = _determinePosition();
    loc.then((value) => {
          setState(() {
            _currentLocation = LatLng(value.latitude, value.longitude);
          }),
        });

    setState(() {
      _mapInitLocation = LatLng(
          (_destinationLocation.latitude + _originLocation.latitude) / 2,
          (_destinationLocation.longitude + _originLocation.longitude) / 2);
    });
    _getLocationUpdates();
    // This status is returning as pending despite the above function returning complete.
  }

  //Get polyline with Location (latitude and longitude)
  _getPolylinesWithLocation(LatLng start, LatLng end) async {
    sendCoordinatesToApi(
        [_originLocation.latitude, _originLocation.longitude],
        [_destinationLocation.latitude, _destinationLocation.longitude],
        widget.id);

  
    _setLoadingMenu(true);
    List<LatLng>? coordinates =
        await _googleMapPolyline.getCoordinatesWithLocation(
            origin: start, destination: end, mode: RouteMode.driving);
    setState(() {
      _polylines.clear();
    });
    setState(() {
      _coordinates = coordinates!;
    });
    _addPolyline(coordinates);
    _setLoadingMenu(false);
  }

  _addPolyline(List<LatLng>? coordinates) async {
    PolylineId id = PolylineId("poly$_polylineCount");
    Polyline polyline = Polyline(
        polylineId: id,
        patterns: patterns[0],
        color: Colors.blueAccent,
        points: coordinates!,
        width: 10,
        onTap: () {});

    if (coordinates.length > 1) {
      double bearing = Geolocator.bearingBetween(
          coordinates[0].latitude,
          coordinates[0].longitude,
          coordinates[1].latitude,
          coordinates[1].longitude);

      setState(() {
        heading = bearing;
      });
      setState(() {
        _bearing = bearing;
        _polylines[id] = polyline;
        _polylineCount++;
      });

      GoogleMapController googleMapController = await _controller.future;
      googleMapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 18,
            bearing: bearing,
            target: LatLng(coordinates[0].latitude, coordinates[0].longitude),
          ),
        ),
      );
    }
  }

  _setLoadingMenu(bool status) {
    setState(() {
      _loading = status;
    });
  }

  _getLocationUpdates() async {
    GoogleMapController googleMapController = await _controller.future;
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(
            position.latitude,
            position.longitude,
          );
        });

        if (status == "Enroute") {
          checkLocation(
              _coordinates,
              LatLng(
                position.latitude,
                position.longitude,
              ));
          print("now status changed to $status");
        }
      }
    });

    print("now status changed to $status");
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cont) {
        return Stack(
          children: [
            GoogleMap(
                markers: {
                  myLoc != null
                      ? Marker(
                          markerId: MarkerId(_currentLocation.toString()),
                          position: _currentLocation,
                          rotation: heading - _bearing!,
                          infoWindow: const InfoWindow(
                            title: 'ERT Location',
                            snippet: 'ERT Location',
                          ),
                          icon: myLoc,
                        )
                      : const Marker(markerId: MarkerId("")),
                  iLoc != null
                      ? Marker(
                          markerId: MarkerId(_destinationLocation.toString()),
                          position: _destinationLocation,
                          rotation: 0,
                          infoWindow: const InfoWindow(
                            title: 'Client Location',
                            snippet: 'Client Location',
                          ),
                          icon: iLoc)
                      : const Marker(markerId: MarkerId("")),
                  dLoc != null
                      ? Marker(
                          markerId: MarkerId(_originLocation.toString()),
                          position: _originLocation,
                          rotation: 0,
                          infoWindow: const InfoWindow(
                            title: 'ERT Location',
                            snippet: 'ERT Location',
                          ),
                          icon: dLoc)
                      : const Marker(markerId: MarkerId("")),
                },
                onMapCreated: _onMapCreated,
                mapType: MapType.normal,
                polylines: Set<Polyline>.of(_polylines.values),
                initialCameraPosition:
                    CameraPosition(target: _mapInitLocation, zoom: 10)),
            status != "Enroute"
                ? Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: SubmitButton(
                        label: label,
                        onButtonPressed: () {
                          if (status == "Pending") {
                            setState(() {
                              status = "Enroute";
                              label = "File Report";
                            });
                            print("this code works status $status.");
                            _getPolylinesWithLocation(
                                _currentLocation, _destinationLocation);
                          } else if (status == "Complete") {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => News()));
                          }
                        }))
                : const SizedBox(),
          ],
        );
      },
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

// KINDLY CHECK THIS CODE BELOW
  // void checkLocation(List<LatLng>? coords, LatLng pos) {
  //   var coordinates = coords;
  //   if (coordinates!.length > 1) {
  //     double dx = (coordinates[1].longitude - pos.longitude).abs();
  //     double dy = (coordinates[1].latitude - pos.latitude).abs();
  //     print("the value of dx is $dx and dy is $dy");

  //     if (coordinates[0] == _originLocation) {
  //       print(
  //           "the Coordinates[0] is ${coordinates[0]} and _originLocation is $_originLocation");
  //       _getPolylinesWithLocation(pos, LatLng(widget.dlat, widget.dlon));
  //     } else if (dx <= 0.0009 && dy <= 0.0009) {
  //       print("dx is $dx and dy is $dy in three decimal places");
  //     } else if (dx <= 0.00009 && dy <= 0.00009) {
  //       coordinates.removeAt(0);
  //       print("the removed coordinates are $coordinates");
  //       print(
  //           "current location is $_currentLocation and origin location is $_originLocation");
  //       setState(() {
  //         _currentLocation = coordinates[0];
  //       });
  //     } else if (dx >= 0.5 && dy >= 0.5) {
  //       print("the items is bigger");
  //       _getPolylinesWithLocation(pos, LatLng(widget.dlat, widget.dlon));
  //     } else {
  //       coordinates.removeAt(0);
  //       coordinates.insert(0, pos);
  //       setState(() {
  //         _currentLocation = pos;
  //       });
  //       print(
  //           "here you go $_currentLocation, $_destinationLocation, $_originLocation");
  //     }
  //     setState(() {
  //       _coordinates = coordinates;
  //     });
  //     _addPolyline(coordinates);
  //   }
  //   // When current location is at destination...

  //   else {
  //     setState(() {
  //       status = "Complete";
  //     });
  //     print("the status now is complete $status");
  //   }
  // }

  void checkLocation(List<LatLng>? coords, LatLng pos) {
    var coordinates = coords;
    if (coordinates!.length > 1) {
      print("the status should be changed to $status");
      _getPolylinesWithLocation(pos, LatLng(widget.dlat, widget.dlon));
    } else {
      setState(() {
        status = "Complete";
      });
    }
  }

  addMarkers() async {
    myLoc = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size.fromHeight(100)),
      "assets/images/gps.png",
    );

    dLoc = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size.fromHeight(100)),
      "assets/images/dicon.png",
    );

    iLoc = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size.fromHeight(100)),
      "assets/images/cicon.png",
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Location Permission Required'),
          ElevatedButton(
            child: const Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          )
        ],
      ),
    );
  }

  sendCoordinatesToApi(start, end, id) async {
    final response = await post(
      Uri.parse("${getUrl()}rides/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'ReportID': id,
        'StartDate': '',
        'EndDate': '',
        'RideStatus': 'In Progress',
        'StartnEndCoordinates': [start, end]
      }),
    );

    Map responseList = json.decode(response.body);
    print("the reportid is $id and customer id");
    token = responseList["token"];
    sendCurrentLocationToApi(_currentLocation, token);
  }

  sendCurrentLocationToApi(LatLng currentLocation, String token) {
    const interval = Duration(seconds: 1);
    Timer.periodic(interval, (timer) {
      try {
        put(
          Uri.parse("${getUrl()}rides/$token"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'CurrentCoordinates': [
              currentLocation.latitude,
              currentLocation.longitude
            ],
          }),
        );
        print("the current location is $currentLocation");
      } catch (e) {
        print(e);
      }
    });
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;
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
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  return await Geolocator.getCurrentPosition();
}
