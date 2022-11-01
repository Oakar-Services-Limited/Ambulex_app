import 'package:ambulex_app/Pages/About.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:ambulex_app/Pages/Settings.dart';
import 'package:ambulex_app/main.dart';
import 'package:flutter/material.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

    return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue,
            Colors.lightBlue,
          ],
        )),
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: const EdgeInsets.all(0),
          children: [
            DrawerHeader(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                  image: AssetImage("assets/images/bg.png"),
                  fit: BoxFit.cover,
                )),
                child: Center(child: Image.asset('assets/images/logo.png'))),
            ListTile(
              title: const Text(
                'Home',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const Home()));
              },
            ),
            ListTile(
              title: Text(
                'Settings',
                style: style,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Settings()));
              },
            ),
            ListTile(
              title: Text(
                'About',
                style: style,
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const About()));
              },
            ),
            ListTile(
              title: Text(
                'Exit',
                style: style,
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MyApp()));
              },
            ),
          ],
        ));
  }
}
