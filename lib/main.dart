import 'package:flutter/material.dart';
import 'Pages/Login.dart';
import 'Pages/Register.dart';
import 'Pages/GettingStarted.dart';
import 'dart:async';

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
    
    Timer(const Duration(seconds: 2), () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    });


    return MaterialApp(
        title: 'Ambulex',
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset('assets/images/logo.png'),
                  const Text(
                    'Emergency Response System',
                    style: TextStyle(fontSize: 20.0),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
