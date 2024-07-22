import 'package:ambulex_appv1/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Pages/Login.dart';
import 'dart:async';
import 'Components/Utils.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = const FlutterSecureStorage();
  bool permission = false;
  dynamic isLoading;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      getToken();
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
      getToken();
    } else if (status == PermissionStatus.denied) {
      openAppSettings();
    } else {
      openAppSettings();
    }
  }

  getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = LoadingAnimationWidget.fallingDot(
        color: Colors.deepOrangeAccent,
        size: 100,
      );
    });
    await Future.delayed(Duration(seconds: 2));
    String? token = prefs.getString("jwt");
    try {
      if (token!.isNotEmpty) {
        var decoded = parseJwt(token.toString());
        if (decoded["error"] == "Invalid token") {
          setState(() {
            isLoading = null;
          });
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Login()));
        } else {
          setState(() {
            isLoading = null;
          });
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Home()));
        }
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ambulex',
        home: Scaffold(
          body: Stack(
            children: [
              Container(
                child: Center(
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
                          )),
                      if (!permission)
                        TextButton(
                            onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: const Text('Location Permission'),
                                    content: const Text(
                                        'This app collects location data only when the application is in use.'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'Cancel'),
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
                              padding:
                                  const EdgeInsets.fromLTRB(24, 12, 24, 12),
                              decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text(
                                "Review App Permissions",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ))
                    ],
                  ),
                ),
              ),
              Center(
                child: isLoading,
              )
            ],
          ),
        ));
  }
}
