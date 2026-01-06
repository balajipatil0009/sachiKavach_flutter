import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sachi_app/services/arcgis_service.dart';

class HydroMapScreen extends StatefulWidget {
  const HydroMapScreen({super.key});

  @override
  State<HydroMapScreen> createState() => _HydroMapScreenState();
}

class _HydroMapScreenState extends State<HydroMapScreen> {
  ArcGISMapViewController? _mapViewController;
  
  // Graphics overlay to show user location (blue dot)
  final GraphicsOverlay _locationOverlay = GraphicsOverlay();
  Graphic? _locationGraphic;

  // Track if we are busy (e.g. locating)
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Initialize with Hydro API Key explicitly
    ArcGISService.initializeHydro();
  }

  /// Handles the "Home" button press - resets viewpoint to default or initial
  void _onHomePressed() {
    // If the map has an initial viewpoint, we can try to reset to it
    // Or just let the map be. For a WebMap, it usually has a stored initial state.
    // We can just re-load the map or, if we captured an initial viewpoint, go there.
    // For simplicity with Web Maps that have defined extents:
    // We could capture the initial viewpoint on load, OR just reloading the map is a blunt but effective reset.
    // However, a smoother way is resetting to the map's initial viewpoint if accessible.
    // Let's assume the Web Map's default view is what we want.
    final map = _mapViewController?.arcGISMap;
    if (map != null) {
        // There isn't a direct "reset" on the controller to the map's default.
        // But we can try to zoom to the map's initial viewpoint.
        // If not set, we can just zoom out to a default extent.
        // For now, let's just log or try to re-apply the map item which might reset it.
        // A better approach for "Home":
        if (map.initialViewpoint != null) {
          _mapViewController?.setViewpoint(map.initialViewpoint!);
        } else {
             // Fallback: World extent or similar
        }
    }
  }

  /// Handles the "Locate" button press
  Future<void> _onLocatePressed() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied')));
        return;
      } 

      // 2. Get Location
      Position position = await Geolocator.getCurrentPosition();
      
      // 3. Update Graphics Overlay
      final point = ArcGISPoint(
        x: position.longitude,
        y: position.latitude,
        spatialReference: SpatialReference.wgs84,
      );

      _updateLocationGraphic(point);

      // 4. Zoom to Location
      _mapViewController?.setViewpoint(
        Viewpoint.fromCenter(point, scale: 5000.0),
      );

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finding location: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We can use an AppBar or just have a fullscreen map with creating floating buttons.
      // User asked for "Top-Left Controls (Floating Column)".
      // So no AppBar or transparent AppBar might be best, but let's stick to standard Scaffold body for map
      // and use Stack for floating controls.
      body: Stack(
        children: [
          // 1. Full-screen Map View
          ArcGISMapView(
            controllerProvider: () {
              _mapViewController = ArcGISMapView.createController();
              return _mapViewController!;
            },
            onMapViewReady: () {
               final map = ArcGISService.getHydroMap();
               _mapViewController?.arcGISMap = map;
               _mapViewController?.graphicsOverlays.add(_locationOverlay);

               // Explicitly load the map to ensure we can access its properties
               map.load().then((_) {
                 if (mounted && map.loadStatus == LoadStatus.loaded) {
                   // If the map has a saved initial viewpoint, apply it
                   if (map.initialViewpoint != null) {
                      _mapViewController?.setViewpoint(map.initialViewpoint!);
                   } else if (map.operationalLayers.isNotEmpty) {
                     // Fallback: Try to zoom to the first layer if no initial viewpoint
                     final layer = map.operationalLayers.first;
                     layer.load().then((_) {
                        if (layer.fullExtent != null) {
                           _mapViewController?.setViewpointGeometry(layer.fullExtent!);
                        }
                     });
                   }
                 } else if (map.loadStatus == LoadStatus.failedToLoad) {
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to load map: ${map.loadError?.message}')),
                      );
                   }
                 }
               });
            },
          ),

          // 2. Top-Left Controls
          Positioned(
            top: 50, // Account for status bar
            left: 20,
            child: Column(
              children: [
                // Home Button
                FloatingActionButton.small(
                  heroTag: "home_btn",
                  onPressed: _onHomePressed,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(height: 10),
                // Locate Button
                FloatingActionButton.small(
                  heroTag: "locate_btn",
                  onPressed: _onLocatePressed,
                  backgroundColor: _isLocating ? Colors.grey[300] : null,
                  child: _isLocating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.my_location, color: Colors.blue), // Blue icon as requested somewhat (icon itself or button)
                      // User said "Use a blue circle icon to match the React simple-marker style" - this usually means the graphic on map
                      // But the button itself can also be indicative.
                ),
              ],
            ),
          ),

          // 3. Top-Right Controls
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: "layer_list_btn",
              onPressed: () {
                // Toggle Layer List Drawer/Modal
                showModalBottomSheet(
                  context: context, 
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(16),
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Layer List", style: Theme.of(context).textTheme.headlineSmall),
                        const Divider(),
                        // Add actual layer toggle logic here if we can access the layers from the map
                        Expanded(
                          child: ListView(
                            children: const [
                              ListTile(
                                leading: Icon(Icons.check_box),
                                title: Text("Hydro Layer (Default)"),
                              ),
                              ListTile(
                                leading: Icon(Icons.check_box_outline_blank),
                                title: Text("Other Layers..."),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                );
              },
              child: const Icon(Icons.layers),
            ),
          ),
          
          // Back Button (Optional but good for sub-pages)
          Positioned(
            top: 50,
            left: 80, // Next to the column
            child: FloatingActionButton.small(
               heroTag: "back_btn",
               backgroundColor: Colors.white,
               onPressed: () => Navigator.pop(context),
               child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
