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
             TextInput(title: 'Phone Number',
                  onSubmit: (value) {},
                ),
             TextInput(title: 'City',
                  onSubmit: (value) {},
                ),
             TextInput(title: 'Street/Address',
                  onSubmit: (value) {},
                ),
             TextInput(title: 'Nearest Landmark',
                  onSubmit: (value) {},
                ),
             TextInput(title: 'Building Name',
                  onSubmit: (value) {},
                ),
             TextInput(title: 'House Number',
                  onSubmit: (value) {},
                ),
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
