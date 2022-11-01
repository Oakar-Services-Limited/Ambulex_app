import 'package:ambulex_app/Pages/About.dart';
import 'package:ambulex_app/Pages/Home.dart';
import 'package:ambulex_app/Pages/Settings.dart';
import 'package:ambulex_app/main.dart';
import 'package:flutter/material.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text('Drawer Header'),
        ),
        ListTile(
          title: const Text('Home'),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const Home()));
          },
        ),
        ListTile(
          title: const Text('Settings'),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const Settings()));
          },
        ),
        ListTile(
          title: const Text('About'),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const About()));
          },
        ),
        ListTile(
          title: const Text('Exit'),
          onTap: () {
           Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MyApp()));
          },
        ),
      ],
    ));
  }
}
