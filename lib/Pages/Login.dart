import 'package:ambulex/Components/ForgotPasswordDialog.dart';
import 'package:ambulex/Components/NavigationButton.dart';
import 'package:ambulex/Components/TextLarge.dart';
import 'package:ambulex/Components/TextOakar.dart';
import 'package:ambulex/Pages/Home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Components/SubmitButton.dart';
import '../Components/MyTextInput.dart';
import 'Register.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Components/Utils.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<Login> {
    String userid = '';

  String phone = '';
  String password = '';
  String error = '';
  bool successful = false;
  var isLoading = null;
  final storage = const FlutterSecureStorage();
  late FirebaseMessaging messaging;

  void resetPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ForgotPasswordDialog();
      },
    );
  }

  Future<void> sendTokenToBackend(String token) async {
    var usertoken = await storage.read(key: "jwt");
    var decoded = decodeJwtToken(usertoken.toString());
    userid = decoded?['UserID'];

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

    @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Login",
      home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: <Widget>[
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
                          TextOakar(label: error, issuccessful: successful),
                          MyTextInput(
                            title: 'Phone Number',
                            value: '',
                            type: TextInputType.phone,
                            onSubmit: (value) {
                              setState(() {
                                phone = value;
                              });
                            },
                          ),
                          MyTextInput(
                            title: 'Password',
                            value: '',
                            type: TextInputType.visiblePassword,
                            onSubmit: (value) {
                              setState(() {
                                password = value;
                              });
                            },
                          ),
                          SubmitButton(
                            label: "Login",
                            onButtonPressed: () async {
                              setState(() {
                                isLoading =
                                    LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.blue,
                                  size: 100,
                                );
                              });

                              var res = await login(phone, password);
                             
                              setState(() {
                                isLoading = null;
                                if (res.error == null) {
                                  successful = true;
                                  error = res.success;
                                } else {
                                  successful = false;
                                  error = res.error;
                                }
                              });
                              if (res.error == null) {
                                await storage.write(
                                    key: 'jwt', value: res.token);
                                 messaging = FirebaseMessaging.instance;
                                messaging.getToken().then((token) async {
                                  await sendTokenToBackend(token!);
                                });
                                Timer(const Duration(seconds: 2), () {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const Home()));
                                });
                              } else {}
                            },
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const Register()));
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(color: Colors.white),
                                  )),
                              TextButton(
                                  onPressed: () {
                                    resetPassword();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text(
                                    "Reset Password",
                                    style: TextStyle(color: Colors.white),
                                  )),
                            ],
                          ),
                          const TextOakar(label: "Powered by \n Oakar Services")
                        ])))))),
            Center(child: isLoading),
          ])),
    );
  }
}

Future<Message> login(String phone, String password) async {
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
    Uri.parse("${getUrl()}users/login"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'Phone': phone, 'Password': password}),
  );

  if (response.statusCode == 200 || response.statusCode == 203) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Message.fromJson(jsonDecode(response.body));
  } else {
    print("response error: ${response.statusCode}, ${response.body}");
    // If the server did not return a 200 OK response,
    // then throw an exception.
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
