import 'package:ambulex_app/Components/NavigationButton.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Components/TextOakar.dart';
import 'package:ambulex_app/Pages/GettingStarted.dart';
import 'package:flutter/material.dart';
import '../Components/SubmitButton.dart';
import '../Components/TextInput.dart';
import 'Login.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';


class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<StatefulWidget> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  String error = '';
  String phone = '';
  String name = '';
  String password = '';
  var isLoading = null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Register",
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
                          const TextLarge(label: "Register"),
                          TextOakar(label: error),
                          TextInput(
                            title: 'Full Name',
                            onSubmit: (value) {
                              setState(() {
                                name = value;
                              });
                            },
                          ),
                          TextInput(
                            title: 'Phone Number',
                            onSubmit: (value) {
                              setState(() {
                                phone = value;
                              });
                            },
                          ),
                          TextInput(
                            title: 'Password',
                            onSubmit: (value) {
                              setState(() {
                                password = value;
                              });
                            },
                          ),
                          SubmitButton(
                            label: "Submit",
                            onButtonPressed: () async {
                              setState(() {
                                isLoading =
                                    LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.blue,
                                  size: 100,
                                );
                              });
                              var res = await register(name, phone, password);
                              setState(() {
                                isLoading = null;
                                if (res.error == null) {
                                  error = res.success;
                                } else {
                                  error = res.error;
                                }
                              });

                              if(res.error == null){
                                Timer(const Duration(seconds: 2), () {
                                 Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const GettingStarted()));
                                });
                              }

                             
                            },
                          ),
                          const NavigationButton(
                              label: "Login", object: Login()),
                          const TextOakar(
                              label: "Powered by \n Oakar Services Ltd.")
                        ])))))),
            Center(child: isLoading),
          ])),
    );
  }
}

Future<Message> register(String name, String phone, String password) async {
    if (name == '') {
    return Message(
      token: null,
      success: null,
      error: "Please enter your name!",
    );
  }
   if (phone.length != 10) {
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
    Uri.parse('http://192.168.1.114:3002/api/users/register'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'Phone': phone, 'Password': password, 'Name': name}),
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
