import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyMap extends StatefulWidget {
  final double lat;
  final double lon;

  const MyMap({Key? key, required this.lat, required this.lon})
      : super(key: key);

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late WebViewController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();
    controller = WebViewController.fromPlatformCreationParams(params);

    setupWebViewController();
  }

  void setupWebViewController() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Handle progress updates
          },
          onPageStarted: (String url) {
            // Handle page start
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Prevent external navigation
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_generateMapHTML());
  }

  String _generateMapHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Location Map</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
        }
        #map {
            height: 100vh;
            width: 100%;
        }
        .map-container {
            position: relative;
            width: 100%;
            height: 100vh;
        }
        .location-info {
            position: absolute;
            top: 10px;
            left: 10px;
            background: white;
            padding: 10px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            z-index: 1000;
            font-size: 12px;
        }
    </style>
    <script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBbEGhViFyDdJJcfl0Mgpv293jyNgTl364"></script>
</head>
<body>
    <div class="map-container">
        <div class="location-info">
            <strong>Your Location:</strong><br>
            Latitude: ${widget.lat.toStringAsFixed(6)}<br>
            Longitude: ${widget.lon.toStringAsFixed(6)}
        </div>
        <div id="map"></div>
    </div>
    
    <script>
        function initMap() {
            const location = { lat: ${widget.lat}, lng: ${widget.lon} };
            
            const map = new google.maps.Map(document.getElementById("map"), {
                zoom: 15,
                center: location,
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                mapTypeControl: true,
                streetViewControl: true,
                fullscreenControl: true,
                zoomControl: true
            });
            
            const marker = new google.maps.Marker({
                position: location,
                map: map,
                title: "Your Location",
                animation: google.maps.Animation.DROP
            });
            
            const infoWindow = new google.maps.InfoWindow({
                content: '<div style="padding: 10px;"><h3>Your Location</h3><p>Latitude: ${widget.lat.toStringAsFixed(6)}</p><p>Longitude: ${widget.lon.toStringAsFixed(6)}</p></div>'
            });
            
            marker.addListener("click", () => {
                infoWindow.open(map, marker);
            });
            
            // Auto-open info window
            infoWindow.open(map, marker);
        }
        
        // Initialize map when page loads
        window.onload = initMap;
    </script>
</body>
</html>
    ''';
  }

  @override
  void didUpdateWidget(covariant MyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      // Reload the map with new coordinates
      controller.loadHtmlString(_generateMapHTML());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: WebViewWidget(controller: controller),
          ),
          if (isLoading)
            Center(
              child: LoadingAnimationWidget.horizontalRotatingDots(
                  color: Colors.blue, size: 100),
            ),
        ],
      ),
    );
  }
}
