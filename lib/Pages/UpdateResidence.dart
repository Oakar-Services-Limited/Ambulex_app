// ignore_for_file: use_build_context_synchronously, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:ambulex_users/Components/Map.dart';
import 'package:ambulex_users/Components/TextOakar.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Login.dart';
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
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:geocoding/geocoding.dart';

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
  String name = '';
  String email = '';
  String city = '';
  String address = 'Fetching location...';
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
    });

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

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
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
    var token = await storage.read(key: "jwt");
    var decoded = parseJwt(token.toString());

    if (decoded != null) {
      if (decoded["error"] == "Invalid token") {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return false;
      } else {
        setState(() {
          id = decoded["UserID"] ?? '';
          name = decoded["Name"] ?? '';
          email1 = decoded["Email"] ?? '';
          city1 = decoded["City"] ?? '';
          address1 = decoded["Address"] ?? '';
          landmark1 = decoded["Landmark"] ?? '';
          buildingname1 = decoded["BuildingName"] ?? '';
          houseno1 = decoded["HouseNumber"] ?? '';
          lat = double.tryParse(decoded["Latitude"]?.toString() ?? '0') ?? 0.0;
          long =
              double.tryParse(decoded["Longitude"]?.toString() ?? '0') ?? 0.0;
          location = decoded["Latitude"] != null && decoded["Longitude"] != null
              ? "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}"
              : "Location not set";
        });
        return true;
      }
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          "Update Residence",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
        ],
      ),
      drawer: const Drawer(child: MyDrawer()),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  _buildContactInfoCard(),
                  const SizedBox(height: 20),
                  _buildAddressCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
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
                          address1,
                          city1,
                        );
                        setState(() {
                          isLoading = null;
                          error = res.error ?? res.success;
                        });

                        if (res.error == null) {
                          Timer(const Duration(seconds: 2), () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Home()));
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Update Details",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading != null)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(child: isLoading),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              address,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.6,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Location Map',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            Expanded(
                              child: MyMap(lat: lat, lon: long, username: name),
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
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          MyTextInput(
            title: 'Email',
            value: email1,
            type: TextInputType.emailAddress,
            onSubmit: (value) => setState(() => email = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Residence Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Detected Address',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text(
              address,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
          MyTextInput(
            title: 'City',
            value: city1,
            type: TextInputType.text,
            onSubmit: (value) => setState(() => city = value),
          ),
          MyTextInput(
            title: 'Address',
            value: address1,
            type: TextInputType.text,
            onSubmit: (value) => setState(() => address = value),
          ),
          MyTextInput(
            title: 'Nearest Landmark',
            value: landmark1,
            type: TextInputType.text,
            onSubmit: (value) => setState(() => landmark = value),
          ),
          MyTextInput(
            title: 'Building Name',
            value: buildingname1,
            type: TextInputType.text,
            onSubmit: (value) => setState(() => buildingname = value),
          ),
          MyTextInput(
            title: 'House Number',
            value: houseno1,
            type: TextInputType.text,
            onSubmit: (value) => setState(() => houseno = value),
          ),
        ],
      ),
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
    double lon,
    String address1,
    String city1) async {
  if (lat == 0.0 || lon == 0.0) {
    return Message(
      token: null,
      success: null,
      error: "Location not acquired! Please turn on your location.",
    );
  }

  // Get geocoded address before updating
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      // Update address with geocoded information if not manually entered
      if (address == address1) {
        // If address hasn't been changed manually
        address = [place.street, place.subLocality, place.locality]
            .where((element) => element != null && element.isNotEmpty)
            .join(', ');
      }
      // Update city if not manually entered
      if (city == city1) {
        // If city hasn't been changed manually
        city = place.locality ?? city;
      }
    }
  } catch (e) {
    print('Error getting geocoded address: $e');
    // Continue with update even if geocoding fails
  }

  // Ensure all values are non-null before sending
  final Map<String, dynamic> updateData = {
    'Email': email.trim(),
    'City': city.trim(),
    'Address': address.trim(),
    'Landmark': landmark.trim(),
    'BuildingName': buildingname.trim(),
    'HouseNumber': houseno.trim(),
    'Latitude': lat,
    'Longitude': lon,
    'GeocodedAddress': address.trim(),
  };

  // Check if any required field is empty
  if (updateData.values.any(
      (value) => value == null || (value is String && value.trim().isEmpty))) {
    return Message(
      token: null,
      success: null,
      error: "All fields are required!",
    );
  }

  try {
    final response = await http.put(
      Uri.parse('${getUrl()}users/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200 || response.statusCode == 203) {
      final decodedResponse = jsonDecode(response.body);
      return Message(
        token: decodedResponse['token'],
        success: decodedResponse['success'],
        error: decodedResponse['error'],
      );
    } else {
      return Message(
        token: null,
        success: null,
        error: "Connection to server failed! Status: ${response.statusCode}",
      );
    }
  } catch (e) {
    print('Error during update: $e');
    return Message(
      token: null,
      success: null,
      error: "Connection error: ${e.toString()}",
    );
  }
}

class Message {
  final dynamic token;
  final dynamic success;
  final dynamic error;

  Message({
    this.token,
    this.success,
    this.error,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}
