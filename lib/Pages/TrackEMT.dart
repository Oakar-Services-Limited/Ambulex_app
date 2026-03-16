import 'dart:async';
import 'dart:convert';

import 'package:ambulex_users/Components/Map.dart';
import 'package:ambulex_users/Components/Utils.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;

class TrackEMTPage extends StatefulWidget {
  final String reportId;
  final double clientLat;
  final double clientLon;

  const TrackEMTPage({
    super.key,
    required this.reportId,
    required this.clientLat,
    required this.clientLon,
  });

  @override
  State<TrackEMTPage> createState() => _TrackEMTPageState();
}

class _TrackEMTPageState extends State<TrackEMTPage> {
  IO.Socket? _socket;
  double? _emtLat;
  double? _emtLon;
  bool _loadingInitial = true;
  String? _status;
  Timer? _staleTimer;
  bool _isStale = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialLocation();
    _connectSocket();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final url =
          Uri.parse('${getUrl()}api/reports/${widget.reportId}/emt-location');
      final resp = await http.get(
        url,
        headers: const {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (resp.statusCode == 200 || resp.statusCode == 203) {
        final data = jsonDecode(resp.body);
        final lat = (data['Latitude'] as num?)?.toDouble();
        final lon = (data['Longitude'] as num?)?.toDouble();
        if (lat != null && lon != null && mounted) {
          setState(() {
            _emtLat = lat;
            _emtLon = lon;
            _status = data['Status']?.toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch initial EMT location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
        });
      }
    }
  }

  void _connectSocket() {
    final base = getUrl();
    final uri = base.endsWith('/') ? base.substring(0, base.length - 1) : base;

    _socket = IO.io(
      uri,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setExtraHeaders({'Origin': uri})
          .build(),
    );

    _socket!.onConnect((_) {
      final roomName = 'report-${widget.reportId}';
      _socket!.emit('join-room', roomName);
    });

    _socket!.on('emt-location-update', (payload) {
      try {
        var data = payload;
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data['reportId'] != widget.reportId) return;

        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) return;

        if (!mounted) return;
        setState(() {
          _emtLat = lat;
          _emtLon = lon;
          _status = data['status']?.toString();
          _isStale = false;
        });

        _staleTimer?.cancel();
        _staleTimer = Timer(const Duration(seconds: 60), () {
          if (mounted) {
            setState(() {
              _isStale = true;
            });
          }
        });
      } catch (e) {
        debugPrint('Error handling emt-location-update: $e');
      }
    });

    _socket!.onError((err) {
      debugPrint('Socket error: $err');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <MapMarker>[];

    markers.add(
      MapMarker(
        lat: widget.clientLat,
        lon: widget.clientLon,
        label: 'You',
        color: Colors.blue,
      ),
    );

    if (_emtLat != null && _emtLon != null) {
      markers.add(
        MapMarker(
          lat: _emtLat!,
          lon: _emtLon!,
          label: _isStale ? 'EMT (last)' : 'EMT',
          color: _isStale ? Colors.grey : Colors.red,
        ),
      );
    }

    final centerLat = _emtLat ?? widget.clientLat;
    final centerLon = _emtLon ?? widget.clientLon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track EMT'),
      ),
      body: Stack(
        children: [
          MyMap(
            lat: centerLat,
            lon: centerLon,
            username: '',
            markers: markers,
            routePoints: _emtLat != null
                ? [
                    LatLng(widget.clientLat, widget.clientLon),
                    LatLng(_emtLat!, _emtLon!),
                  ]
                : null,
          ),
          if (_loadingInitial)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_status != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _isStale
                        ? 'EMT status: $_status (location may be outdated)'
                        : 'EMT status: $_status',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

