import 'package:ambulex_appv1/Pages/About.dart';
import 'package:ambulex_appv1/Pages/Home.dart';
import 'package:ambulex_appv1/Pages/Settings.dart';
import 'package:ambulex_appv1/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../Pages/News.dart';

class NavigationDrawer2 extends StatelessWidget {
  const NavigationDrawer2({super.key});

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
                decoration: const BoxDecoration(color: Colors.white),
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
                'Logout',
                style: style,
              ),
              onTap: () {
                final store = new FlutterSecureStorage();
                store.deleteAll();
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MyApp()));
              },
            ),
            ListTile(
              title: Text(
                'News',
                style: style,
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const News()));
              },
            ),
          ],
        ));
  }
}
