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

      setState(() {
        userId = decoded["Phone"];
      });

      final response = await http.get(
        Uri.parse(
            '${getUrl()}reports?Phone=$userId&limit=$pageSize&offset=${currentPage * pageSize}'),
        headers: {'Content-Type': 'application/json'},
      );

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
      case 'completed':
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          'My Reports',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Container(
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
              child: isLoading && reports.isEmpty
                  ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.blue,
                        size: 50,
                      ),
                    )
                  : reports.isEmpty
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showReportDetails(report),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _getTypeIcon(report['Type']),
                                              color: _getStatusColor(
                                                  report['Status']),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              report['Type'] == 'GBV'
                                                  ? 'Gender Based Violence'
                                                  : 'Medical Emergency',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        report['Status'])
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _getStatusColor(
                                                      report['Status']),
                                                ),
                                              ),
                                              child: Text(
                                                report['Status'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: _getStatusColor(
                                                      report['Status']),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
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
                                            DateTime.parse(report['createdAt']),
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

  void _showReportDetails(Map<String, dynamic> report) {
    String displayAddress = report['GeocodedAddress'] ??
        'Address: ${report['Address'] ?? 'Not available'}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTypeIcon(report['Type']),
                      color: _getStatusColor(report['Status']),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Emergency Report Details',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(report['Status']),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildDetailSection(
                  'Emergency Type',
                  report['Type'] == 'GBV'
                      ? 'Gender Based Violence'
                      : 'Medical Emergency',
                  Icons.emergency,
                ),
                _buildDetailSection(
                  'Status',
                  report['Status'],
                  Icons.info_outline,
                ),
                _buildDetailSection(
                  'Location',
                  displayAddress,
                  Icons.location_on,
                ),
                if (report['Latitude'] != null && report['Longitude'] != null)
                  _buildDetailSection(
                    'Coordinates',
                    'Lat: ${report['Latitude']}, Lon: ${report['Longitude']}',
                    Icons.gps_fixed,
                  ),
                if (report['Action'] != null)
                  _buildDetailSection(
                    'Action Taken',
                    report['Action'],
                    Icons.medical_services,
                  ),
                if (report['Description'] != null)
                  _buildDetailSection(
                    'Description',
                    report['Description'],
                    Icons.description,
                  ),
                _buildTimelineSection(report),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, IconData icon) {
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

  Widget _buildTimelineSection(Map<String, dynamic> report) {
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
        ...timelineItems.map((item) => _buildTimelineItem(item)).toList(),
      ],
    );
  }

  Widget _buildTimelineItem(TimelineItem item) {
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

class TimelineItem {
  final String label;
  final String time;
  final IconData icon;

  TimelineItem(this.label, this.time, this.icon);
}
