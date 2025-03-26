import 'package:ambulex_users/Pages/About.dart';
import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:ambulex_users/Pages/Settings.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:ambulex_users/Pages/UpdateResidence.dart';
import 'package:ambulex_users/Pages/News.dart';
import 'package:ambulex_users/Pages/Reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue, // Match the Subscribe page theme
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
                  Image.asset('assets/images/logo.png',
                      height: 80), // Adjust height as needed
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
            icon: Icons.home,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Subscription',
            icon: Icons.subscriptions,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => Subscribe()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'My Reports',
            icon: Icons.history,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Reports()),
              );
            },
          ),
          _createDrawerItem(
            context,
            title: 'News',
            icon: Icons.article,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const News()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'My Details',
            icon: Icons.person,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UpdateResidence()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'About',
            icon: Icons.info,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const About()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Settings',
            icon: Icons.settings,
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Settings()));
            },
          ),
          _createDrawerItem(
            context,
            title: 'Logout',
            icon: Icons.logout,
            onTap: () async {
              const store = FlutterSecureStorage();
              store.deleteAll();
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Login()));
            },
          ),
        ],
      ),
    );
  }

  Widget _createDrawerItem(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white), // Add icon to the list item
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.blue.shade300, // Match the Subscribe page theme
      hoverColor: Colors.blue.shade400, // Match the Subscribe page theme
      selectedColor: Colors.blue.shade500, // Match the Subscribe page theme
    );
  }
}
