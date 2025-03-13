// ignore_for_file: file_names, prefer_typing_uninitialized_variables
import 'dart:async';
import 'dart:convert';

import 'package:ambulex_users/Components/MyTextInput.dart';
import 'package:ambulex_users/Components/SubmitButton.dart';
import 'package:ambulex_users/Components/TextResponse.dart';
import 'package:ambulex_users/Components/TextSmall.dart';
import 'package:ambulex_users/Components/Utils.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgetPasswordDialogState();
}

class _ForgetPasswordDialogState extends State<ForgotPasswordDialog> {
  String email = '';
  var isLoading;
  String error = '';
  final storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: TextSmall(
                  label:
                      "Enter your email address to receive a password reset link.",
                ),
              ),
              const SizedBox(height: 16),
              MyTextInput(
                value: '',
                type: TextInputType.emailAddress,
                onSubmit: (value) {
                  setState(() {
                    email = value;
                  });
                },
                title: 'Email',
              ),
              Center(
                child: isLoading ?? const SizedBox(),
              ),
              TextResponse(
                label: error,
              ),
              Align(
                alignment: Alignment.center,
                child: SubmitButton(
                  label: "Send Reset Link",
                  onButtonPressed: () async {
                    setState(() {
                      isLoading = LoadingAnimationWidget.horizontalRotatingDots(
                        color: const Color.fromARGB(248, 186, 12, 47),
                        size: 25,
                      );
                    });
                    var res = await recoverPassword(email);
                    setState(() {
                      isLoading = null;
                      if (res.error == null) {
                        error = res.success;
                        Timer(const Duration(seconds: 1), () {
                          Navigator.of(context).pop();
                        });
                      } else {
                        error = res.error;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Message> recoverPassword(String email) async {
  if (email.isEmpty || !EmailValidator.validate(email)) {
    return Message(
      token: null,
      success: null,
      error: "Please enter a valid email address.",
    );
  }

  try {
    final response = await post(
      Uri.parse("${getUrl()}users/forgot"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Email': email,
      }),
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
  } catch (e) {
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
