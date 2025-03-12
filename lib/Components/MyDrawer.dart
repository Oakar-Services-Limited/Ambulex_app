import 'package:ambulex_users/Pages/About.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Settings.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:ambulex_users/Pages/UpdateResidence.dart';
import 'package:ambulex_users/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Pages/News.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

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
                'Update Residence',
                style: style,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UpdateResidence()));
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
                'News',
                style: style,
              ),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const News()));
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
                'Subscriptions',
                style: style,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) =>  Subscribe()));
              },
            ),
            ListTile(
              title: Text(
                'Logout',
                style: style,
              ),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString("jwt", "");
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MyApp()));
              },
            ),
          ],
        ));
  }
}
