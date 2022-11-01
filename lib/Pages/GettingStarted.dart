import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:flutter/material.dart';
import '../Components/SubmitButton.dart';
import '../Components/TextInput.dart';

class GettingStarted extends StatefulWidget {
  const GettingStarted({super.key});

  @override
  State<StatefulWidget> createState() => _GettingStartedState();
}

class _GettingStartedState extends State<GettingStarted> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Getting Started",
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
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      const SizedBox(
                                        height: 100,
                                      ),
                                      Image.asset('assets/images/logo.png'),
                                      const TextLarge(label: "Getting Started"),
                                      const Map(),
                                      const TextInput(title: 'City'),
                                      const TextInput(title: 'Street/Address'),
                                      const TextInput(
                                          title: 'Nearest Landmark'),
                                      const TextInput(title: 'Building Name'),
                                      const TextInput(title: 'House Number'),
                                      SubmitButton(
                                        label: "Submit",
                                        onButtonPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const Home()));
                                        },
                                      ),
                                    ]))))))
          ])),
    );
  }
}
