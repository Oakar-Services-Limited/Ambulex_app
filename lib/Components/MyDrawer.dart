import 'package:ambulex_users/Pages/About.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:ambulex_users/Pages/Settings.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:ambulex_users/Pages/UpdateResidence.dart';
import 'package:ambulex_users/Pages/News.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            Colors.blueAccent,
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', height: 80),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _createDrawerItem(
            context,
            title: 'Home',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Update Residence',
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UpdateResidence()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'About',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const About()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'News',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const News()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Settings()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Subscriptions',
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => Subscribe()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Logout',
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString("jwt", "");
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Login()));
            },
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.blue.shade300,
      hoverColor: Colors.blue.shade400,
      selectedColor: Colors.blue.shade500,
    );
  }
}
