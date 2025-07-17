import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ambulex_users/Components/MyDrawer.dart';
import 'package:ambulex_users/Components/Utils.dart';
import 'package:ambulex_users/Pages/Login.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ambulex_users/Components/Map.dart';
import 'package:latlong2/latlong.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final storage = const FlutterSecureStorage();
  List<dynamic> reports = [];
  bool isLoading = true;
  String userId = '';
  int currentPage = 0;
  int totalItems = 0;
  static const int pageSize = 10;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  static const String googleApiKey = 'AIzaSyBbEGhViFyDdJJcfl0Mgpv293jyNgTl364';

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMore && !isLoading) {
        _loadMoreReports();
      }
    }
  }

  Future<void> _loadMoreReports() async {
    if (!hasMore) return;
    currentPage++;
    await _loadReports(isLoadMore: true);
  }

  Future<void> _loadReports({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        isLoading = true;
        currentPage = 0;
      });
    }

    try {
      var token = await storage.read(key: "jwt");
      var decoded = parseJwt(token.toString());

      if (decoded == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return;
      }

      var phone;

      setState(() {
        phone = decoded["Phone"];
      });

      print("phone: $phone");

      final response = await http.get(
        Uri.parse(
            '${getUrl()}reports?phone=$phone&limit=$pageSize&offset=${currentPage * pageSize}'),
        headers: {'Content-Type': 'application/json'},
      );

      print("response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reports = data['data'];
          totalItems = data['total'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  int get totalPages => (totalItems / pageSize).ceil();

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      setState(() {
        currentPage++;
      });
      _loadReports();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _loadReports();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'gbv':
        return Icons.handshake;
      case 'me':
        return Icons.medical_services;
      default:
        return Icons.error_outline;
    }
  }

  // Helper to decode Google polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  Future<List<LatLng>> _fetchRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$googleApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          'Tap to view a Report',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.blue,
                size: 50,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reports found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () {
                              setState(() {
                                currentPage = 0;
                              });
                              return _loadReports();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final report = reports[index];
                                String displayAddress = report[
                                        'GeocodedAddress'] ??
                                    'Address: ${report['Address'] ?? 'Not available'}';

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => _showReportDetails(report),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    _getTypeIcon(
                                                        report['Type']),
                                                    color: _getStatusColor(
                                                        report['Status']),
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            report['Type'] ==
                                                                    'GBV'
                                                                ? 'GBV'
                                                                : 'ME',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: _getStatusColor(
                                                                    report[
                                                                        'Status'])
                                                                .withOpacity(
                                                                    0.7),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Text(
                                                            report['Status'],
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Only show Cancel Call button if status is 'Received'
                                                  if ((report['Status'] ?? '')
                                                          .toString()
                                                          .toLowerCase() ==
                                                      'received')
                                                    TextButton.icon(
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red.shade50,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 0),
                                                      ),
                                                      icon: const Icon(
                                                          Icons.cancel,
                                                          color: Colors.red,
                                                          size: 18),
                                                      label: const Text(
                                                        'Cancel Call',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        final confirm =
                                                            await showDialog<
                                                                bool>(
                                                          context: context,
                                                          builder: (context) =>
                                                              Dialog(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            elevation: 0,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(24),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                shape: BoxShape
                                                                    .rectangle,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black26,
                                                                    blurRadius:
                                                                        10.0,
                                                                    offset:
                                                                        const Offset(
                                                                            0.0,
                                                                            10.0),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .red
                                                                          .shade50,
                                                                      shape: BoxShape
                                                                          .circle,
                                                                    ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .cancel,
                                                                      size: 32,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          20),
                                                                  Text(
                                                                    'Cancel Call',
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          22,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          12),
                                                                  Text(
                                                                    'Are you sure you want to cancel and delete this call? This action cannot be undone.',
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      fontSize:
                                                                          15,
                                                                      color: Colors
                                                                              .grey[
                                                                          700],
                                                                    ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          24),
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(false),
                                                                          child:
                                                                              Text(
                                                                            'No',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              color: Colors.grey[600],
                                                                              fontSize: 16,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(true),
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                            padding:
                                                                                const EdgeInsets.symmetric(vertical: 12),
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(12),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            'Yes, Cancel',
                                                                            style:
                                                                                GoogleFonts.poppins(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          try {
                                                            final response =
                                                                await http
                                                                    .delete(
                                                              Uri.parse(
                                                                  '${getUrl()}reports/${report['ID']}'),
                                                              headers: {
                                                                'Content-Type':
                                                                    'application/json'
                                                              },
                                                            );
                                                            if (!mounted)
                                                              return;
                                                            if (response
                                                                    .statusCode ==
                                                                200) {
                                                              setState(() {
                                                                reports
                                                                    .removeAt(
                                                                        index);
                                                                totalItems--;
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Call cancelled and deleted.'),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(context)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Failed to delete call.'),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            if (!mounted)
                                                              return;
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Error deleting call.'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                displayAddress,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                timeago.format(
                                                  DateTime.parse(
                                                      report['createdAt']),
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (reports.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: currentPage > 0 ? _previousPage : null,
                            color: currentPage > 0 ? Colors.blue : Colors.grey,
                          ),
                          Text(
                            'Page ${currentPage + 1} of $totalPages',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed:
                                currentPage < totalPages - 1 ? _nextPage : null,
                            color: currentPage < totalPages - 1
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) async {
    String displayAddress = report['GeocodedAddress'] ??
        'Address: ${report['Address'] ?? 'Not available'}';
    final double? lat = report['Latitude'] != null
        ? double.tryParse(report['Latitude'].toString())
        : null;
    final double? lon = report['Longitude'] != null
        ? double.tryParse(report['Longitude'].toString())
        : null;
    final String username =
        report['User'] != null && report['User']['Name'] != null
            ? report['User']['Name']
            : 'You';

    final bool showERTeam =
        report['Status']?.toString().toLowerCase() == 'in progress' &&
            report['ERTeam'] != null &&
            report['ERTeam']['Latitude'] != null &&
            report['ERTeam']['Longitude'] != null;
    final double? erLat = showERTeam
        ? double.tryParse(report['ERTeam']['Latitude'].toString())
        : null;
    final double? erLon = showERTeam
        ? double.tryParse(report['ERTeam']['Longitude'].toString())
        : null;
    final String erName = showERTeam && report['ERTeam']['Name'] != null
        ? report['ERTeam']['Name']
        : 'ERTeam';

    final markers = <MapMarker>[];
    if (lat != null && lon != null) {
      markers
          .add(MapMarker(lat: lat, lon: lon, label: 'You', color: Colors.blue));
    }
    if (showERTeam && erLat != null && erLon != null) {
      markers.add(MapMarker(
          lat: erLat, lon: erLon, label: erName, color: Colors.orange));
    }

    List<LatLng>? routePoints;
    bool isLoadingRoute = false;

    if (showERTeam &&
        lat != null &&
        lon != null &&
        erLat != null &&
        erLon != null) {
      routePoints = await _fetchRoute(LatLng(erLat, erLon), LatLng(lat, lon));
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailsPage(
          report: report,
          markers: markers,
          routePoints: routePoints,
          showERTeam: showERTeam,
          displayAddress: displayAddress,
          username: username,
        ),
      ),
    );
  }
}

class TimelineItem {
  final String label;
  final String time;
  final IconData icon;

  TimelineItem(this.label, this.time, this.icon);
}

class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> report;
  final List<MapMarker> markers;
  final List<LatLng>? routePoints;
  final bool showERTeam;
  final String displayAddress;
  final String username;

  const ReportDetailsPage({
    Key? key,
    required this.report,
    required this.markers,
    required this.routePoints,
    required this.showERTeam,
    required this.displayAddress,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          'Report Details',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: (markers.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: routePoints == null && showERTeam
                          ? Center(child: CircularProgressIndicator())
                          : MyMap(
                              lat: markers[0].lat,
                              lon: markers[0].lon,
                              username: username,
                              markers: markers,
                              routePoints: routePoints,
                            ),
                    )
                  : SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  report['Type'] == 'GBV'
                      ? Icons.handshake
                      : Icons.medical_services,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency Report Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ReportDetailsPage._buildDetailSection(
              'Emergency Type',
              report['Type'] == 'GBV'
                  ? 'Gender Based Violence'
                  : 'Medical Emergency',
              Icons.emergency,
            ),
            ReportDetailsPage._buildDetailSection(
              'Status',
              report['Status'],
              Icons.info_outline,
            ),
            ReportDetailsPage._buildDetailSection(
              'Location',
              displayAddress,
              Icons.location_on,
            ),
            if (report['Latitude'] != null && report['Longitude'] != null)
              ReportDetailsPage._buildDetailSection(
                'Coordinates',
                'Lat: ${report['Latitude']}, Lon: ${report['Longitude']}',
                Icons.gps_fixed,
              ),
            if (report['Action'] != null)
              ReportDetailsPage._buildDetailSection(
                'Action Taken',
                report['Action'],
                Icons.medical_services,
              ),
            if (report['Description'] != null)
              ReportDetailsPage._buildDetailSection(
                'Description',
                report['Description'],
                Icons.description,
              ),
            ReportDetailsPage._buildTimelineSection(report),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailSection(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTimelineSection(Map<String, dynamic> report) {
    final timelineItems = [
      if (report['createdAt'] != null)
        TimelineItem('Reported', report['createdAt'], Icons.report),
      if (report['AssignedAt'] != null)
        TimelineItem('Assigned', report['AssignedAt'], Icons.assignment),
      if (report['DispatchTime'] != null)
        TimelineItem(
            'Dispatched', report['DispatchTime'], Icons.local_shipping),
      if (report['ArrivalTime'] != null)
        TimelineItem('Arrived', report['ArrivalTime'], Icons.check_circle),
      if (report['CompletedAt'] != null)
        TimelineItem('Completed', report['CompletedAt'], Icons.done_all),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Timeline',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...timelineItems
            .map((item) => ReportDetailsPage._buildTimelineItem(item))
            .toList(),
      ],
    );
  }

  static Widget _buildTimelineItem(TimelineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(item.icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            item.label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timeago.format(DateTime.parse(item.time)),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
