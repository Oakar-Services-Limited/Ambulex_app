import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class MapMarker {
  final double lat;
  final double lon;
  final String label;
  final Color color;
  MapMarker(
      {required this.lat,
      required this.lon,
      required this.label,
      required this.color});
}

class MyMap extends StatefulWidget {
  final double lat;
  final double lon;
  final String username;
  final List<MapMarker>? markers;
  final List<LatLng>? routePoints;

  /// Usage:
  /// MyMap(
  ///   lat: ...,
  ///   lon: ...,
  ///   username: ...,
  ///   markers: [...],
  ///   routePoints: [LatLng(...), LatLng(...)],
  /// )
  const MyMap(
      {Key? key,
      required this.lat,
      required this.lon,
      required this.username,
      this.markers,
      this.routePoints})
      : super(key: key);

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late MapController mapController;
  late LatLng currentLocation;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    currentLocation = LatLng(widget.lat, widget.lon);
  }

  @override
  void didUpdateWidget(MyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      setState(() {
        currentLocation = LatLng(widget.lat, widget.lon);
      });
      mapController.move(currentLocation, 15.0);
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.markers ??
        [
          MapMarker(
              lat: widget.lat,
              lon: widget.lon,
              label: 'You',
              color: Colors.blue),
        ];
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Handle map tap if needed
              },
            ),
            children: [
              // OpenStreetMap tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ambulex.users',
                maxZoom: 19,
              ),
              // Current location marker
              MarkerLayer(
                markers: markers
                    .map((marker) => Marker(
                          point: LatLng(marker.lat, marker.lon),
                          width: 60,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: marker.color,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 48,
                                ),
                                child: Text(
                                  marker.label,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: marker.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              if (widget.routePoints != null && widget.routePoints!.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePoints!,
                      color: Colors.orange,
                      strokeWidth: 4,
                    ),
                  ],
                ),
            ],
          ),
          // Compact location info panel - top left only
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Location',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${widget.lat.toStringAsFixed(4)}, ${widget.lon.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Map controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: Column(
              children: [
                _buildMapControl(
                  icon: Icons.my_location,
                  onPressed: () {
                    mapController.move(currentLocation, 15.0);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControl(
                  icon: Icons.add,
                  onPressed: () {
                    final currentZoom = mapController.camera.zoom;
                    mapController.move(
                      mapController.camera.center,
                      (currentZoom + 1).clamp(5.0, 18.0),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapControl(
                  icon: Icons.remove,
                  onPressed: () {
                    final currentZoom = mapController.camera.zoom;
                    mapController.move(
                      mapController.camera.center,
                      (currentZoom - 1).clamp(5.0, 18.0),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
