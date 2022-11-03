import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer.dart';
import 'package:ambulex_app/Components/ReportButton.dart';
import 'package:flutter/material.dart';
import 'package:slider_button/slider_button.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    String location = 'Using current location Lon: 36.1578 Lat: -1.4552';
    return MaterialApp(
        title: "Home",
        home: Scaffold(
          appBar: AppBar(title: const Text("Home")),
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
                const SizedBox(
                  height: 10,
                ),
                Text(location),
                const SizedBox(
                  height: 10,
                ),
                Center(
                    child: SliderButton(
                  action: () {
                    setState(() {
                      location =
                          'Using saved location Lon: 36.1578 Lat: -1.4552';
                    });
                    location = 'Using saved location Lon: 36.1578 Lat: -1.4552';
                  },
                  label: const Text(
                    "Use saved location",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        fontSize: 16),
                  ),
                  icon: const Center(
                      child: Icon(
                    Icons.location_pin,
                    color: Colors.white,
                    size: 24,
                    semanticLabel: 'Current Location',
                  )),
                  buttonSize: 40,
                  height: 42,
                  radius: 40,
                  buttonColor: Colors.blue,
                  backgroundColor: Colors.orange,
                  highlightedColor: Colors.blue,
                  baseColor: Colors.white,
                )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: const <Widget>[
                      ReportButton(
                        label: "Gender Based Violence",
                        icon: Icons.handshake_sharp,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ReportButton(
                          label: "Medical Emergency",
                          icon: Icons.medical_services)
                    ],
                  ),
                )
              ]))),
        ));
  }
}
