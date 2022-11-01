import 'package:ambulex_app/Components/Map.dart';
import 'package:ambulex_app/Components/NavigationDrawer.dart';
import 'package:ambulex_app/Components/TextLarge.dart';
import 'package:flutter/material.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<StatefulWidget> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "About",
        home: Scaffold(
          appBar: AppBar(title: const Text("About")),
          drawer: const Drawer(child: NavigationDrawer()),
          body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(children: const <Widget>[
                TextLarge(label: "Introduction"),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12,24,12),
                  child: Text(
                      "Ambulex Solutions is a Kenyan start-up that seeks to have a significant socio-economic impact in Kenya by contributing to the healthcare system to give residents of low-income areas access to affordable and timely emergency medical care, saving lives and giving people a second chance at life and a chance to be active participants in their communities."),
                ),
                TextLarge(label: "Scope"),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Text(
                      "Ambulex through this mobile application offers emergency response services for the following incidences"),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Text("GENDER BASED VIOLENCE"),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Text("MEDICAL EMERGENCIES",
                  textAlign: TextAlign.left,),
                ),
              ])),
        ));
  }
}
