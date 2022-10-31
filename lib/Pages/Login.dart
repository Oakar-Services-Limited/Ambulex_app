import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 44, 24, 44),
                      child: Text("Login",
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                    const TextInput(title: 'Full Name'),
                    const TextInput(title: 'Phone Number'),
                    const TextInput(title: 'Password'),
                    const SubmitButton(label: "Login"),

                  ])))),
    );
  }
}

class TextInput extends StatefulWidget {
  final String title;

  const TextInput({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Column(
          children: <Widget>[
            SizedBox(
                width: double.infinity,
                child: Text(widget.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ))),
            SizedBox(
              height: 10,
            ),
            const TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                border: OutlineInputBorder(),
                filled: false,
              ),
            )
          ],
        ));
  }
}

class SubmitButton extends StatefulWidget {
  final String label;
  const SubmitButton({super.key, required this.label});

  @override
  State<StatefulWidget> createState() => _SubmitButton();
}

class _SubmitButton extends State<SubmitButton> {

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(44),
        child:  ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: const Size.fromHeight(50), // NEW
      ),
      onPressed: () {},
      child: Text(widget.label,style: TextStyle(fontSize: 18),
      ),
    ),
   );
  }
}
