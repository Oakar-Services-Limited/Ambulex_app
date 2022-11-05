import 'package:ambulex_app/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'Pages/Login.dart';
import 'Pages/Register.dart';
import 'Pages/GettingStarted.dart';
import 'dart:async';
import 'Components/Utils.dart';

void main() {
  runApp(MaterialApp(
    home: const MyApp(), // Becomes the route named '/'.
    routes: <String, WidgetBuilder>{
      '/login': (context) => const Login(),
      '/register': (context) => const Register(),
      '/gettingstarted': (context) => const GettingStarted(),
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = new FlutterSecureStorage();

    getToken() async {
      var token = await storage.read(key: "jwt");
      var decoded = parseJwt(token.toString());
      if (decoded["error"] == "Invalid token") {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Login()));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Home()));
      }
    }

    Timer(const Duration(seconds: 2), () {
      getToken();
    });

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
