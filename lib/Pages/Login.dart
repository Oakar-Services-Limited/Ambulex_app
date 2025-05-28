import 'package:ambulex_users/Components/ForgotPasswordDialog.dart';
import 'package:ambulex_users/Components/NavigationButton.dart';
import 'package:ambulex_users/Components/TextLarge.dart';
import 'package:ambulex_users/Components/TextOakar.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Settings.dart';
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
import 'package:ambulex_users/Components/ChangePasswordDialog.dart';

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
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Welcome Back",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (error.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: successful
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: successful ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (isLoading != null) Center(child: isLoading),
                    const SizedBox(height: 32),
                    MyTextInput(
                      title: 'Phone Number',
                      value: '',
                      type: TextInputType.phone,
                      onSubmit: (value) => setState(() => phone = value),
                      prefixIcon: Icons.phone,
                    ),
                    MyTextInput(
                      title: 'Password',
                      value: '',
                      type: TextInputType.visiblePassword,
                      onSubmit: (value) => setState(() => password = value),
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.blue,
                              size: 100,
                            );
                          });

                          try {
                            String formattedPhone = phone.startsWith("0")
                                ? "254${phone.substring(1)}"
                                : phone;

                            var res = await login(formattedPhone, password);

                            if (res.error == "system_password") {
                              setState(() {
                                isLoading = null;
                              });

                              // Handle system password case
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please change your system-generated password to a personal one',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );

                              // Show change password dialog
                              if (res.token != null) {
                                var decoded = parseJwt(res.token);
                                if (decoded != null &&
                                    decoded["UserID"] != null) {
                                  final result = await _handleSystemPassword(
                                      decoded["UserID"]);
                                  setState(() {
                                    if (result) {
                                      successful = true;
                                      error =
                                          "Password changed successfully. Please login with your new password.";
                                    } else {
                                      successful = false;
                                      error =
                                          "You must change your system-generated password to continue.";
                                    }
                                  });
                                } else {
                                  setState(() {
                                    successful = false;
                                    error =
                                        "Failed to get user information. Please try again.";
                                  });
                                }
                              } else {
                                setState(() {
                                  successful = false;
                                  error =
                                      "Failed to get user information. Please try again.";
                                });
                              }
                            } else if (res.error == null) {
                              setState(() {
                                isLoading = null;
                                successful = true;
                                error = res.success;
                              });

                              // Store the token and check subscription status
                              storage.write(key: 'jwt', value: res.token);
                              print('Token stored: ${res.token}');
                              messaging = FirebaseMessaging.instance;
                              messaging.getToken().then((token) async {
                                await sendTokenToBackend(token!);
                              });
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Home()));
                            } else {
                              setState(() {
                                isLoading = null;
                                successful = false;
                                error = res.error;
                              });
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = null;
                              successful = false;
                              error = "An error occurred. Please try again.";
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Register()),
                          ),
                          child: Text(
                            "Sign Up",
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const TextOakar(label: "Powered by \n Oakar Services"),
                  ],
                ),
              ),
            ],
          ),
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

  Future<bool> _handleSystemPassword(String userId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChangePasswordDialog(userId: userId);
      },
    );

    return result ?? false;
  }
}

Future<Message> login(String phone, String password) async {
  try {
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

    // Check if password starts with "Sys"
    if (password.startsWith("Sys")) {
      // First try to login to get the user ID
      final loginResponse = await http.post(
        Uri.parse("${getUrl()}users/login"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body:
            jsonEncode(<String, String>{'Phone': phone, 'Password': password}),
      );

      if (loginResponse.statusCode == 200) {
        var data = jsonDecode(loginResponse.body);
        return Message(
          token: data['token'],
          success: null,
          error: "system_password",
        );
      } else {
        return Message(
          token: null,
          success: null,
          error: "Invalid credentials",
        );
      }
    }

    final response = await http.post(
      Uri.parse("${getUrl()}users/login"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'Phone': phone, 'Password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 203) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      print("response error: ${response.statusCode}, ${response.body}");
      return Message(
        token: null,
        success: null,
        error: "Connection to server failed!",
      );
    }
  } catch (e) {
    print("login error: $e");
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
