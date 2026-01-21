import 'package:ambulex_users/Components/ForgotPasswordDialog.dart';
import 'package:ambulex_users/Components/TextOakar.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Components/MyTextInput.dart';
import 'Register.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Components/Utils.dart';
import 'package:ambulex_users/Components/ChangePasswordDialog.dart';
import 'package:url_launcher/url_launcher.dart';

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
  var isLoading;
  final storage = const FlutterSecureStorage();
  late FirebaseMessaging messaging;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // New state variables for the two-step process
  bool isPhoneStep = true;
  bool isExistingUser = false;

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
    userid = decoded['UserID'];

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

  Future<bool> checkUserExists(String phone) async {
    print("Phone: $phone");
    // Try all common formats
    List<String> formats = [
      phone,
      phone.startsWith("254") ? "0${phone.substring(3)}" : phone,
      phone.startsWith("254") ? "+$phone" : phone,
      phone.startsWith("+") ? phone.substring(1) : phone,
    ];
    for (String p in formats.toSet()) {
      print("Checking format: $p");
      try {
        final response = await http.get(
          Uri.parse("${getUrl()}users/phone/$p"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );
        print("Response for $p: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        print("Error checking user existence for $p: $e");
      }
    }
    return false;
  }

  Future<void> handlePhoneSubmit() async {
    if (phone.isEmpty) {
      setState(() {
        error = "Please enter your phone number";
        successful = false;
      });
      return;
    }

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.blue,
        size: 100,
      );
    });

    try {
      String formattedPhone =
          phone.startsWith("0") ? "254${phone.substring(1)}" : phone;

      bool exists = await checkUserExists(formattedPhone);

      setState(() {
        isLoading = null;
        if (exists) {
          isPhoneStep = false;
          isExistingUser = true;
          error = "";
        } else {
          // Navigate to register page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Register(phoneNumber: formattedPhone),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        isLoading = null;
        error = "An error occurred. Please try again.";
        successful = false;
      });
    }
  }

  Future<void> handlePasswordSubmit() async {
    if (password.isEmpty) {
      setState(() {
        error = "Please enter your password";
        successful = false;
      });
      return;
    }

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.blue,
        size: 100,
      );
    });

    try {
      String formattedPhone =
          phone.startsWith("0") ? "254${phone.substring(1)}" : phone;

      var res = await login(formattedPhone, password);

      if (res.error == "system_password") {
        setState(() {
          isLoading = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.success ??
                  'System Password detected, please change your password',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        if (res.token != null) {
          var decoded = parseJwt(res.token);
          if (decoded["UserID"] != null) {
            final result = await _handleSystemPassword(decoded["UserID"]);
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
          }
        }
      } else if (res.error == null) {
        setState(() {
          isLoading = null;
          successful = true;
          error = res.success;
        });

        storage.write(key: 'jwt', value: res.token);
        messaging = FirebaseMessaging.instance;
        messaging.getToken().then((token) async {
          await sendTokenToBackend(token!);
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      } else {
        setState(() {
          isLoading = null;
          successful = false;
          // Only set error if not the version error
          if (res.error !=
              'You are using an old version of the app, update it on Play Store.') {
            error = res.error;
          } else {
            error = '';
          }
        });
        if (res.error ==
            'You are using an old version of the app, update it on Play Store.') {
          _showUpgradeDialog();
          return;
        }
      }
    } catch (e) {
      setState(() {
        isLoading = null;
        successful = false;
        error = "An error occurred. Please try again.";
      });
    }
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
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPhoneStep ? "Welcome Back" : "Enter Password",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPhoneStep
                        ? "Enter your phone number to continue"
                        : "Enter your password to sign in",
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
                  if (isPhoneStep)
                    MyTextInput(
                      title: 'Phone Number',
                      value: phone,
                      type: TextInputType.phone,
                      onSubmit: (value) => setState(() => phone = value),
                      prefixIcon: Icons.phone,
                    )
                  else
                    Column(
                      children: [
                        // Back button to return to phone step

                        MyTextInput(
                          title: 'Password',
                          value: password,
                          type: TextInputType.visiblePassword,
                          onSubmit: (value) => setState(() => password = value),
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isPhoneStep = true;
                                  password = '';
                                  error = '';
                                });
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                      ],
                    ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: isPhoneStep
                          ? handlePhoneSubmit
                          : handlePasswordSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isPhoneStep ? "Continue" : "Sign In",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isPhoneStep) ...[
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
                  ],
                  const SizedBox(height: 16),
                  const TextOakar(label: "Powered by \n Oakar Services"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update,
                      color: Color(0xff0288D1), size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  "New Upgrades Detected",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Click below to upgrade your app before you continue.",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0288D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      const url =
                          "https://play.google.com/store/apps/details?id=ke.co.osl.ambulex_users&pcampaignid=web_share";
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Text(
                      "Upgrade Now",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    final response = await http.post(
      Uri.parse("${getUrl()}users/login"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Phone': phone,
        'Password': password,
        'appVersion': '6.0.0'
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (password == "654321") {
        return Message(
          token: data['token'],
          success: "System Password detected, please change your password",
          error: "system_password",
        );
      }
      return Message.fromJson(data);
    } else if (response.statusCode == 203) {
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
