import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sachi_app/services/arcgis_service.dart';

class TablesMapScreen extends StatefulWidget {
  const TablesMapScreen({super.key});

  @override
  State<TablesMapScreen> createState() => _TablesMapScreenState();
}

class _TablesMapScreenState extends State<TablesMapScreen> {
  ArcGISMapViewController? _mapViewController;
  
  // Graphics overlay to show user location (blue dot)
  final GraphicsOverlay _locationOverlay = GraphicsOverlay();
  Graphic? _locationGraphic;

  // Track if we are busy (e.g. locating)
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Initialize with Tables API Key
    ArcGISService.initializeTables();
  }

  /// Handles the "Home" button press
  void _onHomePressed() {
    final map = _mapViewController?.arcGISMap;
    if (map != null) {
        if (map.initialViewpoint != null) {
          _mapViewController?.setViewpoint(map.initialViewpoint!);
        } else {
             // Fallback if needed
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
      body: Stack(
        children: [
          // 1. Full-screen Map View
          ArcGISMapView(
            controllerProvider: () {
              _mapViewController = ArcGISMapView.createController();
              return _mapViewController!;
            },
            onMapViewReady: () {
               final map = ArcGISService.getTablesMap();
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
                  heroTag: "home_btn_tables",
                  onPressed: _onHomePressed,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(height: 10),
                // Locate Button
                FloatingActionButton.small(
                  heroTag: "locate_btn_tables",
                  onPressed: _onLocatePressed,
                  backgroundColor: _isLocating ? Colors.grey[300] : null,
                  child: _isLocating 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),

          // 3. Top-Right Controls
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: "layer_list_btn_tables",
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
                                title: Text("Tables Layer (Default)"),
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
          
          // Back Button
          Positioned(
            top: 50,
            left: 80, 
            child: FloatingActionButton.small(
               heroTag: "back_btn_tables",
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
