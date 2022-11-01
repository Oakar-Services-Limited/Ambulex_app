import 'package:ambulex_app/Components/NavigationButton.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Components/TextOakar.dart';
import 'package:flutter/material.dart';
import '../Components/SubmitButton.dart';
import '../Components/TextInput.dart';
import 'Register.dart';

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
                          const TextInput(title: 'Phone Number'),
                          const TextInput(title: 'Password'),
                          const SubmitButton(label: "Login",onButtonPressed: null,),
                          const NavigationButton(label: "Register", object:Register()),
                          const TextOakar(
                              label: "Powered by \n Oakar Services Ltd.")
                        ]))))))
          ])),
    );
  }
}
