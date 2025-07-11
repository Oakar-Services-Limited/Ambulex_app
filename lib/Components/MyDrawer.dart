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
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ambulex_users/Components/Utils.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? referralCode;
  bool isLoadingReferral = false;

  @override
  void initState() {
    super.initState();
    _fetchReferralCode();
  }

  Future<void> _fetchReferralCode() async {
    setState(() {
      isLoadingReferral = true;
    });
    final storage = FlutterSecureStorage();
    String? token = await storage.read(key: "jwt");
    String? userId;
    if (token != null) {
      final decoded = parseJwt(token);
      userId = decoded["UserID"];
    }
    print('Debug: userId from JWT = ${userId}');
    if (userId != null) {
      try {
        final response =
            await http.get(Uri.parse('${getUrl()}users/$userId/referral-code'));
        print('Debug: API response status = ${response.statusCode}');
        print('Debug: API response body = ${response.body}');
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            referralCode = data['referralCode'];
          });
          print('Debug: referralCode fetched = ${referralCode ?? 'null'}');
        }
      } catch (e) {
        print('Debug: Exception in _fetchReferralCode: $e');
      }
    }
    setState(() {
      isLoadingReferral = false;
    });
  }

  void _shareApp() {
    final code = referralCode ?? '';
    print('Debug: referralCode when sharing = $code');
    final shareText =
        'Join Ambulex! Use my referral code: $code. Download the app here: https://play.google.com/store/apps/details?id=ke.co.osl.ambulex_users&pcampaignid=web_share';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
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
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                          child: Image.asset('assets/images/logo.png',
                              height: 48)),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      isLoadingReferral
                          ? const CircularProgressIndicator(color: Colors.white)
                          : referralCode != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text('Your Referral Code:',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 11)),
                                    const SizedBox(height: 1),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(referralCode!,
                                          style: const TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2)),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        print(
                                            'Debug: referralCode in UI = ${referralCode!}');
                                        return SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                )
                              : Container(),
                    ],
                  ),
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Settings()));
              },
            ),
            _createDrawerItem(
              context,
              title: 'Share App',
              icon: Icons.share,
              onTap: _shareApp,
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
      ),
    );
  }

  Widget _createDrawerItem(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.blue.shade300,
      hoverColor: Colors.blue.shade400,
      selectedColor: Colors.blue.shade500,
    );
  }
}
