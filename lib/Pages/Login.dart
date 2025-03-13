import 'package:ambulex_users/Components/ForgotPasswordDialog.dart';
import 'package:ambulex_users/Components/NavigationButton.dart';
import 'package:ambulex_users/Components/TextLarge.dart';
import 'package:ambulex_users/Components/TextOakar.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TextEditingController _phoneController = TextEditingController();

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
    var decoded = parseJwt(usertoken.toString());
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: <Widget>[
            Center(
              child: Container(
                constraints: const BoxConstraints.tightForFinite(),
                child: SingleChildScrollView(
                  child: Form(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset('assets/images/logo.png'),
                          Text(
                            "Login",
                            style: GoogleFonts.lato(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            error,
                            style: TextStyle(
                                color: successful ? Colors.green : Colors.red),
                          ),
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
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isLoading =
                                    LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.blue,
                                  size: 100,
                                );
                              });

                              String formattedPhone = phone.startsWith("0")
                                  ? "254${phone.substring(1)}"
                                  : phone;

                              var res = await login(formattedPhone, password);

                              setState(() {
                                isLoading = null;
                                if (res.error == null) {
                                  successful = true;
                                  error = res.success;

                                  checkSubscriptionStatus();
                                } else {
                                  successful = false;
                                  error = res.error;
                                }
                              });
                              if (res.error == null) {
                                await storage.write(
                                    key: 'jwt', value: res.token);
                                print('Token stored: ${res.token}');
                                messaging = FirebaseMessaging.instance;
                                messaging.getToken().then((token) async {
                                  await sendTokenToBackend(token!);
                                });
                              } else {}
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text(
                              "Login",
                              style: GoogleFonts.lato(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                ),
                              ),
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
                                ),
                              ),
                            ],
                          ),
                          const TextOakar(label: "Powered by \n Oakar Services")
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(child: isLoading),
          ]),
        ),
      ),
    );
  }

  Future<void> checkSubscriptionStatus() async {
    var token = await storage.read(key: "jwt");
    var decoded = parseJwt(token.toString());
    var userid;

    if (decoded != null) {
      setState(() {
        phone = decoded["Phone"];
        userid = decoded["UserID"]!;
      });
    }

    print("Checking subscription status for user ID: $userid");
    final response = await http.get(
      Uri.parse('${getUrl()}payments/user/$userid'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print("Response status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print("Response data here: $data");
      if (data['data'] != null && data['data'].isNotEmpty) {
        print("User is subscribed.");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Home()));
      } else {
        print("User is not subscribed.");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Subscribe()));
      }
    } else {
      print('Failed to check subscription status: ${response.statusCode}');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Subscribe()));
    }
  }
}

Future<Message> login(String phone, String password) async {
  // if (phone.length != 10) {
  //   return Message(
  //     token: null,
  //     success: null,
  //     error: "Invalid phone number!",
  //   );
  // }
  if (phone.length != 12) {
    return Message(
      token: null,
      success: null,
      error: "Invalid phone number!",
    );
  }
  print("Phone: $phone");
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
