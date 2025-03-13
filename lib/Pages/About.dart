import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:ambulex_users/Components/TextLarge.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<StatefulWidget> createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        backgroundColor: Colors.blue,
      ),
      drawer: const Drawer(child: MyDrawer()),
      body: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextLarge(label: "Introduction"),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Text(
                  "Ambulex Solutions is a Kenyan start-up that seeks to have a significant socio-economic impact in Kenya by contributing to the healthcare system to give residents of low-income areas access to affordable and timely emergency medical care, saving lives and giving people a second chance at life and a chance to be active participants in their communities.",
                  style: GoogleFonts.lato(fontSize: 16),
                ),
              ),
              TextLarge(label: "Scope"),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Text(
                  "Ambulex through this mobile application offers emergency response services for the following incidences:",
                  style: GoogleFonts.lato(fontSize: 16),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Text(
                  "GENDER BASED VIOLENCE",
                  style: GoogleFonts.lato(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Text(
                  "MEDICAL EMERGENCIES",
                  style: GoogleFonts.lato(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
