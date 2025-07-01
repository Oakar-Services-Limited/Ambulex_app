// ignore_for_file: file_names, unused_import, avoid_init_to_null, prefer_typing_uninitialized_variables, empty_catches

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
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class Register extends StatefulWidget {
  final String? phoneNumber;

  const Register({super.key, this.phoneNumber});

  @override
  State<StatefulWidget> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  bool _showMap = false;
  final storage = const FlutterSecureStorage();
  late FirebaseMessaging messaging;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String referralCode = '';

  @override
  void initState() {
    getLocation();
    super.initState();
    if (widget.phoneNumber != null) {
      phone = widget.phoneNumber!;
      _phoneController.text = phone;
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
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      _buildLocationSection(),
                      if (error.isNotEmpty) _buildErrorMessage(),
                      _buildSectionHeader(
                          "Personal Information", Icons.person_outline),
                      MyTextInput(
                        title: 'Full Name',
                        value: name,
                        type: TextInputType.text,
                        onSubmit: (value) => setState(() => name = value),
                        // prefixIcon: Icons.person,
                      ),
                      MyTextInput(
                        title: 'Phone Number',
                        value: phone,
                        type: TextInputType.phone,
                        onSubmit: (value) => setState(() => phone = value),
                        // prefixIcon: Icons.phone,
                      ),
                      MyTextInput(
                        title: 'Email',
                        value: email,
                        type: TextInputType.emailAddress,
                        onSubmit: (value) => setState(() => email = value),
                        //prefixIcon: Icons.email,
                      ),
                      MySelectInput(
                        label: 'Gender',
                        onSubmit: (value) => setState(() => gender = value),
                        list: const ['Male', 'Female'],
                        value: gender,
                      ),
                      _buildSectionHeader("Account Security", Icons.security),
                      MyTextInput(
                        title: 'Password',
                        value: password,
                        type: TextInputType.visiblePassword,
                        onSubmit: (value) => setState(() => password = value),
                        //prefixIcon: Icons.lock_outline,
                        //isPassword: true,
                      ),
                      MyTextInput(
                        title: 'Referral Code (optional)',
                        value: referralCode,
                        type: TextInputType.text,
                        onSubmit: (value) =>
                            setState(() => referralCode = value),
                      ),
                      _buildSectionHeader("Address Details", Icons.location_on),
                      MyTextInput(
                        title: 'City',
                        value: city,
                        type: TextInputType.text,
                        onSubmit: (value) => setState(() => city = value),
                        //prefixIcon: Icons.location_city,
                      ),
                      MyTextInput(
                        title: 'Address',
                        value: address,
                        type: TextInputType.text,
                        onSubmit: (value) => setState(() => address = value),
                        // prefixIcon: Icons.home,
                      ),
                      MyTextInput(
                        title: 'Nearest Landmark',
                        value: landmark,
                        type: TextInputType.text,
                        onSubmit: (value) => setState(() => landmark = value),
                        //prefixIcon: Icons.place,
                      ),
                      MyTextInput(
                        title: 'Building Name',
                        value: buildingname,
                        type: TextInputType.text,
                        onSubmit: (value) =>
                            setState(() => buildingname = value),
                        // prefixIcon: Icons.apartment,
                      ),
                      MyTextInput(
                        title: 'House Number',
                        value: houseno,
                        type: TextInputType.text,
                        onSubmit: (value) => setState(() => houseno = value),
                        // prefixIcon: Icons.home_work,
                      ),
                      const SizedBox(height: 32),
                      _buildSubmitSection(),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
              if (isLoading != null)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: Center(child: isLoading),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          ),
        ),
        Text(
          "Create Account",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                "Location Access",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "We collect your location data to help emergency responders reach you quickly during emergencies.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          if (location.isNotEmpty)
            Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: Icon(
                  _showMap ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                label: Text(
                  _showMap ? "Hide Map" : "View Map",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_showMap) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MyMap(lat: lat, lon: long, username: name),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: successful ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error,
        style: TextStyle(
          color: successful ? Colors.green : Colors.red,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            isLoading = LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.blue,
              size: 100,
            );
          });

          String formattedPhone =
              phone.startsWith("0") ? "254${phone.substring(1)}" : phone;

          var res = await register(
              name,
              formattedPhone,
              email,
              password,
              gender,
              city,
              address,
              landmark,
              buildingname,
              houseno,
              lat,
              long,
              referralCode);
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
                  context, MaterialPageRoute(builder: (_) => const Login()));
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          "Create Account",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account? ",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              ),
              child: Text(
                "Sign In",
                style: GoogleFonts.poppins(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const TextOakar(label: "Powered by \n Oakar Services Ltd."),
        const SizedBox(height: 24),
      ],
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
    double lon,
    [String? referralCode]) async {
  try {
    if (name == '') {
      return Message(
        token: null,
        success: null,
        error: "Please enter your name!",
      );
    }
    if (phone.length != 12) {
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
        'Longitude': lon,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
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
  } catch (e) {
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
