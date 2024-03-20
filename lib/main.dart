import 'package:ambulex_users/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Pages/Login.dart';
import 'dart:async';
import 'Components/Utils.dart';

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

  @override
  void initState() {
    Timer(const Duration(seconds: 2), () {
      getToken();
    });
    super.initState();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Timer(const Duration(seconds: 2), () {
          getToken();
        });
        break;
      case AppLifecycleState.inactive:
        // Handle this case
        break;
      case AppLifecycleState.paused:
        // Handle this case
        break;
      case AppLifecycleState.detached:
       Timer(const Duration(seconds: 2), () {
          getToken();
        });
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
    }
  }

  getToken() async {
    var token = await storage.read(key: "jwt");
    var decoded = parseJwt(token.toString());
    if (decoded["error"] == "Invalid token") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ambulex',
        home: Scaffold(
          body: Container(
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
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}
