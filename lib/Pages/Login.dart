import 'package:ambulex_app/Components/NavigationButton.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Components/TextOakar.dart';
import 'package:ambulex_app/Pages/Home.dart';
import '../Components/SubmitButton.dart';
import '../Components/TextInput.dart';
import 'Register.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Login",
      home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
                child: Container(
                    constraints: const BoxConstraints.tightForFinite(),
                    child: SingleChildScrollView(
                        child: Form(
                            child: Center(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                          Image.asset('assets/images/logo.png'),
                          const TextLarge(label: "Login"),
                           TextInput(title: 'Phone Number',
                            onSubmit: (value) {},
                          ),
                           TextInput(title: 'Password',
                            onSubmit: (value) {},
                          ),
                          SubmitButton(
                            label: "Login",
                            onButtonPressed: () {
                              login();
                              // Navigator.push(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (_) => const Home()));
                            },
                          ),
                          const NavigationButton(
                              label: "Register", object: Register()),
                          const TextOakar(
                              label: "Powered by \n Oakar Services Ltd.")
                        ]))))))
          ])),
    );
  }
}

Future<Message> login() async {
  final response = await http.post(
    Uri.parse('http://192.168.1.140:8001/api/users/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'Phone': "0714816920", 'Password': '123456'}),
  );

  print(response);

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Message.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    return  Message(
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
