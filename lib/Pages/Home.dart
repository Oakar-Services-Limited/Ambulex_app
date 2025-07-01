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
import 'package:geocoding/geocoding.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';

final Uri _url = Uri.parse('tel://+254702898989');

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? subscriptionInfo;
  String location = '';
  String phone = '';
  String id = '';
  String category = '';
  String name = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  late StreamSubscription<Position> positionStream;
  var isLoading = null;
  String address = 'Fetching location...';

  @override
  void initState() {
    getLocation();
    authenticateUser();
    super.initState();
  }

  Future<Map<String, dynamic>?> getSubscriptionInfo(String userid) async {
    try {
      print('Subscription User ID: $userid');
      final response =
          await http.get(Uri.parse('${getUrl()}subscriptions/user/$userid'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load subscription info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription info: $e');
      return null;
    }
  }

  Future<void> fetchSubscriptionInfo(String userid) async {
    final response = await getSubscriptionInfo(userid);
    if (response != null &&
        response['data'] != null &&
        response['data'].isNotEmpty) {
      print('Subscription Info: $response');
      setState(() {
        subscriptionInfo = response['data'][0]; // Access the first subscription
      });
    } else {
      setState(() {
        subscriptionInfo = {};
      });
      print('Failed to fetch subscription info');
    }
  }

  authenticateUser() async {
    try {
      var token = await storage.read(key: "jwt");
      var decoded = parseJwt(token.toString());

      setState(() {
        phone = decoded["Phone"];
        id = decoded["UserID"]!;
        name = decoded["Name"];
        location =
            "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}";
      });
      await fetchSubscriptionInfo(id);

      // Check subscription status after fetching
      if (subscriptionInfo == null ||
          subscriptionInfo?['status'] != 'active') {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Subscribe()));
        }
      }
        } catch (e) {
      print('Error in authenticateUser: $e');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
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

  Future<void> getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    long = position.longitude;
    lat = position.latitude;

    // Get address from coordinates
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          address = '${place.street}, ${place.subLocality}, ${place.locality}';
          location = 'Lat: $lat, Lon: $long';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        address = 'Unable to fetch address';
        location = 'Lat: $lat, Lon: $long';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Home",
        home: Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: Text("Ambulex",
                  style: GoogleFonts.lato(
                    fontSize: 24,
                  )),
              backgroundColor: Colors.blue,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    storage.delete(key: "jwt");
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const Login()));
                  },
                ),
              ],
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
            body: SafeArea(
                child: SingleChildScrollView(
                    child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                    _buildSubscriptionCard(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Divider(height: 8, color: Colors.blue),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 0),
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      insetPadding: const EdgeInsets.all(16),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.6,
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Location Map',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: MyMap(lat: lat, lon: long, username: phone),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View on Map'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ReportButton(
                      label: "Gender Based Violence",
                      icon: Icons.handshake_sharp,
                      color1: Colors.orange,
                      onButtonPressed: () async {
                        if (subscriptionInfo?['status'] != 'active') {
                          _showSubscriptionDialog();
                        } else {
                          _showEmergencyConfirmation("GBV", () async {
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
                          });
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ReportButton(
                      label: "Medical Emergency",
                      icon: Icons.medical_services,
                      color1: Colors.red,
                      onButtonPressed: () async {
                        if (subscriptionInfo?['status'] != 'active') {
                          _showSubscriptionDialog();
                        } else {
                          _showEmergencyConfirmation("ME", () async {
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
                              "ME",
                              long,
                              lat,
                              category,
                            );
                            setState(() {
                              isLoading = null;
                            });

                            if (res.error == null) {
                              _showSuccessDialog("Medical Emergency");
                            } else {
                              _showSnackbar(res.error);
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
                Center(child: isLoading),
              ]),
            )))));
  }

  Widget _buildSubscriptionCard() {
    final bool isActive = subscriptionInfo?['status'] == 'active';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [Colors.blue.shade400, Colors.blue.shade700]
                : [Colors.grey.shade400, Colors.grey.shade700],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.verified : Icons.warning_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Status',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subscriptionInfo?['status']?.toUpperCase() ??
                          'NO SUBSCRIPTION',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildSubscriptionDetail(
              'Amount Paid',
              'Ksh${subscriptionInfo?['amountPaid'] ?? '0.00'}',
              Icons.payment,
            ),
            const SizedBox(height: 16),
            _buildSubscriptionDetail(
              'Valid Until',
              _formatDate(subscriptionInfo?['endDate']),
              Icons.event,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildSubscriptionDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
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

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Subscription Required',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Text(
            'You need an active subscription to use this service.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Subscribe()),
                );
              },
              child: Text(
                'Subscribe Now',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyConfirmation(String type, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            type == "GBV"
                ? 'Report Gender Based Violence?'
                : 'Report Medical Emergency?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: type == "GBV" ? Colors.orange : Colors.red,
            ),
          ),
          content: Text(
            'Are you sure you want to report this emergency? Emergency services will be dispatched to your location.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == "GBV" ? Colors.orange : Colors.red,
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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

  // Get geocoded address
  String geocodedAddress = '';
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      geocodedAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}';
    }
  } catch (e) {
    print('Error getting geocoded address: $e');
    geocodedAddress = 'Unable to fetch address';
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
      'UserID': userid,
      'GeocodedAddress': geocodedAddress, // Add the geocoded address
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
