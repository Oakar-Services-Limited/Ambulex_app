import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:flutter/material.dart';
import '../Components/TextInput.dart';
import '../Components/SubmitButton.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Settings",
        home: Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          drawer: const Drawer(child: NavigationDrawer()),
          body: Container(
             decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SingleChildScrollView(
                  child: Column(children: <Widget>[
            const Map(),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text("Lon: 36.56695 Lat: -1.25854"),
            ),
            const TextInput(title: 'Phone Number'),
            const TextInput(title: 'City'),
            const TextInput(title: 'Street/Address'),
            const TextInput(title: 'Nearest Landmark'),
            const TextInput(title: 'Building Name'),
            const TextInput(title: 'House Number'),
            SubmitButton(
              label: "Submit",
              onButtonPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const Home()));
              },
            ),
          ]))),
        ));
  }
}
