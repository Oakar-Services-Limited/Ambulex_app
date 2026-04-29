// ignore_for_file: use_build_context_synchronously, file_names, unused_import, avoid_init_to_null, prefer_typing_uninitialized_variables

import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:ambulex_users/Components/Map.dart';
import 'package:ambulex_users/Components/ReportButton.dart';
import 'package:ambulex_users/Components/Utils.dart';
import 'package:ambulex_users/Pages/GettingStarted.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:ambulex_users/Pages/Register.dart';
import 'package:ambulex_users/Pages/Reports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ambulex_users/Pages/Subscribe.dart';

final Uri _url = Uri.parse('tel://+254702898989');

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? subscriptionInfo;
  String location = '';
  String phone = '';
  String id = '';
  String category = '';
  String name = '';
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  double long = 0.0, lat = 0.0;
  StreamSubscription<Position>? positionStream;
  var isLoading = null;
  String address = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    getLocation();
    authenticateUser();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLiveClientLocation(String reportId) async {
    // Cancel any existing stream first
    await positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    positionStream = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((Position pos) async {
      try {
        await http.post(
          Uri.parse('${getUrl()}reports/$reportId/client-location'),
          headers: const {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'Latitude': pos.latitude,
            'Longitude': pos.longitude,
          }),
        );
      } catch (e) {
        // Swallow errors to avoid breaking the stream
        debugPrint('Failed to send client live location: $e');
      }
    });
  }

  Future<Map<String, dynamic>?> getSubscriptionInfo(String userid) async {
    try {
      print('Subscription User ID: $userid');
      final response =
          await http.get(Uri.parse('${getUrl()}subscriptions/user/$userid'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load subscription info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription info: $e');
      return null;
    }
  }

  Future<void> fetchSubscriptionInfo(String userid) async {
    final response = await getSubscriptionInfo(userid);
    if (!mounted) return;
    if (response != null &&
        response['data'] != null &&
        response['data'].isNotEmpty) {
      print('Subscription Info: $response');
      setState(() {
        subscriptionInfo = response['data'][0]; // Access the first subscription
      });
    } else {
      setState(() {
        subscriptionInfo = {};
      });
      print('Failed to fetch subscription info');
    }
  }

  authenticateUser() async {
    try {
      var token = await storage.read(key: "jwt");
      var decoded = parseJwt(token.toString());

      if (!mounted) return;
      setState(() {
        phone = decoded["Phone"];
        id = decoded["UserID"]!;
        name = decoded["Name"];
        location =
            "Saved location Lat: ${decoded['Latitude']} Lon: ${decoded['Longitude']}";
      });
      await fetchSubscriptionInfo(id);

      // Check subscription status after fetching
      if (!mounted) return;
      if (subscriptionInfo == null || subscriptionInfo?['status'] != 'active') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Subscribe()));
      }
    } catch (e) {
      print('Error in authenticateUser: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
        } else if (permission == LocationPermission.deniedForever) {
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        getLocation();
      }
    } else {}

    if (!mounted) return;
    setState(() {
      //refresh the UI
    });
  }

  Future<void> getLocation() async {
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      long = position.longitude;
      lat = position.latitude;

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
        if (!mounted) return;
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            address = '${place.street}, ${place.subLocality}, ${place.locality}';
            location = 'Lat: $lat, Lon: $long';
          });
        }
      } catch (e) {
        print('Error getting address: $e');
        if (!mounted) return;
        setState(() {
          address = 'Unable to fetch address';
          location = 'Lat: $lat, Lon: $long';
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (!mounted) return;
      setState(() {
        address = 'Unable to fetch location';
        location = 'Location unavailable';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Home",
        home: Scaffold(
            appBar: AppBar(
              foregroundColor: Colors.white,
              title: Text("Ambulex",
                  style: GoogleFonts.lato(
                    fontSize: 24,
                  )),
              backgroundColor: Colors.blue,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    storage.delete(key: "jwt");
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const Login()));
                  },
                ),
              ],
            ),
            drawer: const Drawer(child: MyDrawer()),
            floatingActionButton: FloatingActionButton(
                elevation: 10.0,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                onPressed: () {
                  _launchUrl();
                },
                child: const Icon(Icons.call)),
            body: SafeArea(
                child: SingleChildScrollView(
                    child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Column(
                  children: [
                    _buildSubscriptionCard(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Divider(height: 8, color: Colors.blue),
                            const SizedBox(height: 4),
                            Text(
                              address,
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 0),
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      insetPadding: const EdgeInsets.all(16),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.6,
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Location Map',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: MyMap(
                                                  lat: lat,
                                                  lon: long,
                                                  username: phone),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View on Map'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ReportButton(
                      label: "Gender Based Violence",
                      icon: Icons.handshake_sharp,
                      color1: Colors.orange,
                      onButtonPressed: () async {
                        if (subscriptionInfo?['status'] != 'active') {
                          _showSubscriptionDialog();
                        } else if (!_canMakeEmergencyReport()) {
                          _showResponseLimitDialog();
                        } else {
                          _showEmergencyConfirmation("GBV", () async {
                            if (!mounted) return;
                            setState(() {
                              isLoading =
                                  LoadingAnimationWidget.staggeredDotsWave(
                                color: Colors.blue,
                                size: 100,
                              );
                            });
                            var res = await report(
                              id,
                              context,
                              phone,
                              "GBV",
                              long,
                              lat,
                              category,
                            );
                            if (!mounted) return;
                            setState(() {
                              isLoading = null;
                            });

                            if (!mounted) return;
                            if (res.error == null) {
                              if (res.token != null) {
                                _startLiveClientLocation(
                                    res.token.toString());
                              }
                              _showSuccessDialog("Gender Based Violence");
                              // Refresh subscription info to update response count
                              await fetchSubscriptionInfo(id);
                            } else {
                              // Check if it's a response limit error
                              if (res.error.contains('limit') || res.error.contains('Response limit')) {
                                _showResponseLimitDialog();
                                await fetchSubscriptionInfo(id);
                              } else {
                                _showSnackbar(res.error);
                              }
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ReportButton(
                      label: "Medical Emergency",
                      icon: Icons.medical_services,
                      color1: Colors.red,
                      onButtonPressed: () async {
                        if (subscriptionInfo?['status'] != 'active') {
                          _showSubscriptionDialog();
                        } else if (!_canMakeEmergencyReport()) {
                          _showResponseLimitDialog();
                        } else {
                          _showEmergencyConfirmation("ME", () async {
                            if (!mounted) return;
                            setState(() {
                              isLoading =
                                  LoadingAnimationWidget.staggeredDotsWave(
                                color: Colors.blue,
                                size: 100,
                              );
                            });
                            var res = await report(
                              id,
                              context,
                              phone,
                              "ME",
                              long,
                              lat,
                              category,
                            );
                            if (!mounted) return;
                            setState(() {
                              isLoading = null;
                            });

                            if (!mounted) return;
                            if (res.error == null) {
                              if (res.token != null) {
                                _startLiveClientLocation(
                                    res.token.toString());
                              }
                              _showSuccessDialog("Medical Emergency");
                              // Refresh subscription info to update response count
                              await fetchSubscriptionInfo(id);
                            } else {
                              // Check if it's a response limit error
                              if (res.error.contains('limit') || res.error.contains('Response limit')) {
                                _showResponseLimitDialog();
                                await fetchSubscriptionInfo(id);
                              } else {
                                _showSnackbar(res.error);
                              }
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
                Center(child: isLoading),
              ]),
            )))));
  }

  bool _canMakeEmergencyReport() {
    if (subscriptionInfo?['status'] != 'active') return false;
    
    final maxResponses = subscriptionInfo?['maxResponses'];
    final responsesUsed = subscriptionInfo?['responsesUsed'] ?? 0;
    
    // Unlimited packages (null or -1 means unlimited)
    if (maxResponses == null || maxResponses == -1) return true;
    
    // Limited packages - check if within limit
    return responsesUsed < maxResponses;
  }

  int _getRemainingResponses() {
    final maxResponses = subscriptionInfo?['maxResponses'];
    final responsesUsed = subscriptionInfo?['responsesUsed'] ?? 0;
    
    if (maxResponses == null || maxResponses == -1) {
      return -1; // Unlimited
    }
    
    return maxResponses - responsesUsed;
  }

  void _showResponseLimitDialog() {
    final maxResponses = subscriptionInfo?['maxResponses'];
    final packageName = subscriptionInfo?['packageName'] ?? 'your package';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              Text(
                'Response Limit Reached',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have used all $maxResponses emergency responses for your $packageName.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Options:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Upgrade to a package with more responses',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              Text(
                '• Wait for your subscription to renew',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Subscribe()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Upgrade Package',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionCard() {
    final bool isSubscriptionLoading = subscriptionInfo == null;
    final bool isActive = subscriptionInfo?['status'] == 'active';
    final int remainingResponses = _getRemainingResponses();
    final dynamic responsesUsedRaw = subscriptionInfo?['responsesUsed'];
    final dynamic maxResponsesRaw = subscriptionInfo?['maxResponses'];
    final int responsesUsed = responsesUsedRaw is int ? responsesUsedRaw : 0;
    final int? maxResponses = maxResponsesRaw is int ? maxResponsesRaw : null;
    final String remainingText = remainingResponses >= 0
        ? '$remainingResponses / $maxResponses'
        : 'Unlimited';
    final bool hasLimitedResponses =
        isActive && maxResponses != null && maxResponses > 0;
    final double responsesProgress = hasLimitedResponses
        ? (responsesUsed / maxResponses).clamp(0.0, 1.0)
        : 0.0;
    final gradientColors = isSubscriptionLoading
        ? [Colors.blue.shade300, Colors.blue.shade600]
        : (isActive
            ? [Colors.blue.shade400, Colors.blue.shade700]
            : [Colors.grey.shade400, Colors.grey.shade700]);
    final statusText = isSubscriptionLoading
        ? 'LOADING...'
        : (subscriptionInfo?['status']?.toUpperCase() ?? 'NO SUBSCRIPTION');
    final String amountPaidText = 'Ksh${subscriptionInfo?['amountPaid'] ?? '0.00'}';
    final String packageName =
        subscriptionInfo?['packageName']?.toString() ?? 'No package selected';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Icon(
                    isSubscriptionLoading
                        ? Icons.hourglass_top_rounded
                        : (isActive ? Icons.verified : Icons.warning_rounded),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Paid',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      amountPaidText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 26),
            LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                final int columns = w < 360 ? 1 : (w < 520 ? 2 : 3);
                const double spacing = 12;

                final double totalSpacing = spacing * (columns - 1);
                final double cardWidth = (w - totalSpacing) / columns;

                final cards = <Widget>[
                  SizedBox(
                    width: cardWidth,
                    child: _buildMiniStatCard(
                      icon: Icons.payment,
                      label: 'Amount Paid',
                      value: 'Ksh${subscriptionInfo?['amountPaid'] ?? '0.00'}',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMiniStatCard(
                      icon: Icons.event,
                      label: 'Valid Until',
                      value: _formatDate(subscriptionInfo?['endDate']),
                    ),
                  ),
                  if (isActive && subscriptionInfo?['maxResponses'] != null)
                    SizedBox(
                      width: cardWidth,
                      child: _buildMiniStatCard(
                        icon: Icons.emergency,
                        label: 'Responses Remaining',
                        value: remainingText,
                      ),
                    ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: cards,
                );
              },
            ),
            if (hasLimitedResponses) ...[
              const SizedBox(height: 14),
              Text(
                'Usage Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: responsesProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.92),
                  ),
                ),
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Subscribe(openPackages: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upgrade, color: Colors.white, size: 18),
                  label: Text(
                    'Update Subscription',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String type) {
    if (!mounted) return;
    final isGBV = type.toLowerCase().contains('gender');
    final icon = isGBV ? Icons.handshake : Icons.medical_services;
    final color = isGBV ? Colors.orange : Colors.red;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                type,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Call for help received. Help is on the way!!',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Reports())),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSubscriptionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Subscription Required',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Text(
            'You need an active subscription to use this service.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Subscribe()),
                );
              },
              child: Text(
                'Subscribe Now',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyConfirmation(String type, Function onConfirm) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            type == "GBV"
                ? 'Report Gender Based Violence?'
                : 'Report Medical Emergency?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: type == "GBV" ? Colors.orange : Colors.red,
            ),
          ),
          content: Text(
            'Are you sure you want to report this emergency? Emergency services will be dispatched to your location.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: type == "GBV" ? Colors.orange : Colors.red,
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}

Future<Message> report(String userid, var context, String phone, String type,
    double lon, double lat, String category) async {
  print("Phone: $phone");
  print("Type: $type");
  print("Lon: $lon");
  print("Lat: $lat");
  print("Category: $category");
  print("Userid: $userid");

  if (phone == '') {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const Login()));
  }

  if (lat == 0.0 || lon == 0.0) {
    return Message(
      token: null,
      success: null,
      error: "Location not acquired! Please turn on your location.",
    );
  }

  // Get geocoded address
  String geocodedAddress = '';
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      geocodedAddress =
          '${place.street}, ${place.subLocality}, ${place.locality}';
    }
  } catch (e) {
    print('Error getting geocoded address: $e');
    geocodedAddress = 'Unable to fetch address';
  }

  final response = await http.post(
    Uri.parse('${getUrl()}reports/create'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'Phone': phone,
      'Type': type,
      'Latitude': lat,
      'Longitude': lon,
      'Status': 'Received',
      'UserID': userid,
      'GeocodedAddress': geocodedAddress, // Add the geocoded address
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 203) {
    print("Response body emer: ${response.body}");
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Message.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    return Message(
      token: null,
      success: null,
      error: "Connection to server failed!",
    );
  }
}

class Message {
  var token;
  var success;
  var error;

  Message({
    required this.token,
    required this.success,
    required this.error,
  });

  factory Message.fromJson(json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }
  return await Geolocator.getCurrentPosition();
}
