import 'dart:convert';

import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Components/Utils.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  bool permission = false;
  dynamic isLoading;
  final storage = const FlutterSecureStorage();
  String userid = '';
  String name = '';
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      await authenticateUser();
      setState(() {
        permission = true;
      });
    } else {
      setState(() {
        permission = false;
      });
    }
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      await authenticateUser();
    } else {
      openAppSettings();
    }
  }

  Future<void> sendTokenToBackend(String token, String userid) async {
    final response = await post(
      Uri.parse("${getUrl()}fcmtoken/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'FCMToken': token, 'UserID': userid}),
    );

    if (response.statusCode == 200) {
      print('Token registered successfully');
    } else {
      print('Failed to register token');
    }
  }

  Future<void> authenticateUser() async {
    try {
      var token = await storage.read(key: "jwt");
      if (token == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return;
      }

      var decoded = parseJwt(token.toString());
      if (decoded != null) {
        setState(() {
          userid = decoded["UserID"];
          name = decoded["Name"];
        });

        // Check subscription status
        bool hasActiveSubscription = await checkSubscriptionStatus(userid);
        if (!hasActiveSubscription) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Subscribe()));
          return;
        }

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Home()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {
      print('Error in authenticateUser: $e');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  Future<void> showPermissionDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 32,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Location Permission Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ambulex needs access to location to:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionPoint(
                icon: Icons.emergency,
                text: 'Locate you during emergencies',
              ),
              _buildPermissionPoint(
                icon: Icons.local_hospital,
                text: 'Find nearest emergency responders',
              ),
              _buildPermissionPoint(
                icon: Icons.route,
                text: 'Provide accurate navigation',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Not Now',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        requestLocationPermission();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Allow Access',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionPoint({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/images/logo.png'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    'Emergency Response \n System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading != null) Center(child: isLoading),
                if (!permission)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: showPermissionDialog,
                      icon: const Icon(Icons.location_on),
                      label: const Text("Enable Location Services",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
