import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final VoidCallback onTogglePerformance;
  final bool showPerformanceOverlay;

  const MapPage({
    super.key,
    required this.onTogglePerformance,
    required this.showPerformanceOverlay,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Create a controller for the map view
  ArcGISMapViewController? _mapViewController;
  bool _isMapLoading = true;
  bool _isFetchingLocation = true;
  ArcGISPoint? _userLocation;
  
  // Default map point (San Diego, CA) - used as fallback
  final ArcGISPoint _defaultPoint = ArcGISPoint(
    x: -117.195,
    y: 34.05,
    spatialReference: SpatialReference.wgs84,
  );

  // Graphics overlay for the blue dot
  final GraphicsOverlay _locationOverlay = GraphicsOverlay();
  Graphic? _locationGraphic;

  @override
  void initState() {
    super.initState();
    // Initialize ArcGIS with API Key
    ArcGISEnvironment.apiKey = 'AAPTxy8BH1VEsoebNVZXo8HurJ7BZH8TTjkwjihsZ8pLjndyFcQ0EQq2mdA6IWBNOIGgBeeE2bIl34XlFf3sLnO_hTrU9Bhxdq7PvriXYVkMkFV1qoBYRu-L19q9KmnqEDNY52DlarvUmpHlBpAZqMnXO5JtmgHldC2bMexjAtQtyYlnwS50chQmvEOt_3FEP82OCKJnIIOUbq03ORuJA_rAUSC4mOVCdlqjQQtNSyit4Mqev66SAepxh3t4WPNCeEXwAT1_sDEh4a0h';
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    debugPrint("Fetching location before map load...");
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions are denied");
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied");
        return;
      } 

      debugPrint("Permissions granted. Fetching position...");
      Position position = await Geolocator.getCurrentPosition();
      debugPrint("Position found: ${position.latitude}, ${position.longitude}");
      
      if (mounted) {
        setState(() {
          _userLocation = ArcGISPoint(
            x: position.longitude,
            y: position.latitude,
            spatialReference: SpatialReference.wgs84,
          );
        });
        _updateLocationGraphic(_userLocation!);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _updateLocationGraphic(ArcGISPoint point) {
    if (_locationGraphic == null) {
      final symbol = SimpleMarkerSymbol(
        style: SimpleMarkerSymbolStyle.circle,
        color: Colors.blue,
        size: 12.0,
      );
      symbol.outline = SimpleLineSymbol(
        style: SimpleLineSymbolStyle.solid,
        color: Colors.white,
        width: 2.0,
      );
      
      _locationGraphic = Graphic(
        geometry: point,
        symbol: symbol,
      );
      _locationOverlay.graphics.add(_locationGraphic!);
    } else {
      _locationGraphic!.geometry = point;
    }
  }

  // Helper to re-fetch location manually (for the button)
  Future<void> _recenterLocation() async {
    try {
       Position position = await Geolocator.getCurrentPosition();
       final point = ArcGISPoint(
          x: position.longitude,
          y: position.latitude,
          spatialReference: SpatialReference.wgs84,
       );
       
       _updateLocationGraphic(point);

       if (_mapViewController != null) {
        _mapViewController!.setViewpoint(
          Viewpoint.fromCenter(
            point,
            scale: 5000.0,
          ),
        );
       }
    } catch (e) {
      debugPrint("Error recentering: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArcGIS Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(widget.showPerformanceOverlay ? Icons.speed : Icons.speed_outlined),
            tooltip: 'Toggle Performance Overlay',
            onPressed: widget.onTogglePerformance,
          ),
        ],
      ),
      body: _isFetchingLocation 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Finding your location..."),
              ],
            ),
          )
        : Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () {
              _mapViewController = ArcGISMapView.createController();
              return _mapViewController!;
            },
            onMapViewReady: () async {
              // Set the map to the controller
              _mapViewController?.arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
              
              // Add graphics overlay for location dot
              _mapViewController?.graphicsOverlays.add(_locationOverlay);

              // Set initial viewpoint to user location if available, else default
              final initialPoint = _userLocation ?? _defaultPoint;
              
              _mapViewController?.setViewpoint(
                Viewpoint.fromCenter(
                  initialPoint,
                  scale: 5000.0, // Zoomed in scale
                ),
              );

              // Hide map loading indicator immediately
              if (mounted) {
                setState(() {
                  _isMapLoading = false;
                });
              }
            },
          ),
          if (_isMapLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // Zoom In
                    final currentScale = _mapViewController?.scale ?? 100000.0;
                    _mapViewController?.setViewpointScale(currentScale / 2);
                  },
                  heroTag: 'zoom_in',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Zoom Out
                    final currentScale = _mapViewController?.scale ?? 100000.0;
                    _mapViewController?.setViewpointScale(currentScale * 2);
                  },
                  heroTag: 'zoom_out',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Change Basemap to Navigation (Roads)
                    _mapViewController?.arcGISMap?.basemap = Basemap.withStyle(BasemapStyle.arcGISNavigation);
                  },
                  heroTag: 'navigation',
                  child: const Icon(Icons.directions_car),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Recenter on Current Location
                    _recenterLocation();
                    // Also try to reset autoPanMode just in case
                    _mapViewController?.locationDisplay.autoPanMode = LocationDisplayAutoPanMode.recenter;
                  },
                  heroTag: 'my_location',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Change Basemap to Satellite
                    _mapViewController?.arcGISMap?.basemap = Basemap.withStyle(BasemapStyle.arcGISImagery);
                  },
                  heroTag: 'satellite',
                  child: const Icon(Icons.satellite_alt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
