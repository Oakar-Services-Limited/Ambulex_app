import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ambulex/Pages/Home.dart';
import 'package:ambulex/Pages/Login.dart';
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
      authenticateUser();
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
      authenticateUser();
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.deepOrangeAccent,
        size: 100,
      );
    });
    await Future.delayed(const Duration(seconds: 2));
    String? token = prefs.getString("jwt");
    try {
      var token = await storage.read(key: "erjwt");
      var decoded = decodeJwtToken(token.toString());

      if (decoded == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      } else {
        userid = decoded['UserID'];
        name = decoded['Name'];

        await storage.write(key: "userid", value: userid);

        // Get the FCM token
        messaging = FirebaseMessaging.instance;
        messaging.getToken().then((token) async {
          await sendTokenToBackend(token!, userid);
        });

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Home()));
      }
    } catch (e) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
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
                    style: TextStyle(fontSize: 28, color: Colors.blue),
                  ),
                ),
                if (!permission)
                  TextButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Location Permission'),
                        content: const Text(
                          'This app collects location data only when the application is in use.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Cancel'),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              requestLocationPermission();
                              Navigator.pop(context, 'OK');
                            },
                            child: const Text('Grant Permissions'),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Review App Permissions",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Center(
            child: isLoading,
          ),
        ],
      ),
    );
  }
}
