import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sachi_app/services/arcgis_service.dart';

class ReliefMapScreen extends StatefulWidget {
  const ReliefMapScreen({super.key});

  @override
  State<ReliefMapScreen> createState() => _ReliefMapScreenState();
}

class _ReliefMapScreenState extends State<ReliefMapScreen> {
  ArcGISMapViewController? _mapViewController;
  
  // Graphics overlay to show user location (blue dot)
  final GraphicsOverlay _locationOverlay = GraphicsOverlay();
  Graphic? _locationGraphic;

  // Track if we are busy (e.g. locating)
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    // Initialize with Relief API Key
    ArcGISService.initializeRelief();
  }

  /// Handles the "Home" button press
  void _onHomePressed() {
    final map = _mapViewController?.arcGISMap;
    if (map != null) {
        if (map.initialViewpoint != null) {
          _mapViewController?.setViewpoint(map.initialViewpoint!);
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

  void _scanLayerRecursive(Layer layer, int depth) {
      final indent = "  " * depth;
      debugPrint("$indent LAYER: ${layer.name} (${layer.runtimeType})");
      debugPrint("$indent   INFO: $layer");
      
      if (layer is GroupLayer) {
          debugPrint("$indent   GROUP: Scanning ${layer.layers.length} children...");
          for (final subLayer in layer.layers) {
              _scanLayerRecursive(subLayer, depth + 1);
          }
      } else if (layer is FeatureLayer) {
          if (layer.featureTable is ServiceFeatureTable) {
              final table = layer.featureTable as ServiceFeatureTable;
              debugPrint("$indent   FOUND URL: ${table.uri}");
          }
      } else if (layer is ServiceImageTiledLayer) {
           debugPrint("$indent   FOUND INFO: $layer");
           // Valid for manual observation if URL is in string
      } else if (layer is ArcGISMapImageLayer) {
           debugPrint("$indent   FOUND URL: ${layer.uri}");
      }
  }

  Future<void> _handleTap(Offset screenPoint) async {
    if (_mapViewController == null) return;

    // Identify features at the tapped location
    final identifyResults = await _mapViewController!.identifyLayers(
      screenPoint: screenPoint,
      tolerance: 12.0,
      returnPopupsOnly: false,
    );

    if (identifyResults.isEmpty) return;

    for (final result in identifyResults) {
      for (final element in result.geoElements) {
         // Check for "Name" attribute or similar common name fields case-insensitively
         final attributes = element.attributes;
         String? name;
         
         // Try finding 'Name', 'name', 'NAME' etc.
         for (final key in attributes.keys) {
           if (key.toLowerCase() == 'name') {
             name = attributes[key]?.toString();
             break;
           }
         }

         if (name != null && name.isNotEmpty) {
           if (mounted) _showPopup(name);
           return; // Show only the first match
         }
      }
    }
  }

  void _showPopup(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Relief Site"),
        content: Text("Name: $name"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
            onTap: _handleTap, 
            
            onMapViewReady: () {
               final map = ArcGISService.getReliefMap();
               _mapViewController?.arcGISMap = map;
               _mapViewController?.graphicsOverlays.add(_locationOverlay);

               map.load().then((_) {
                 if (mounted && map.loadStatus == LoadStatus.loaded) {
                   // DEBUG SCANNER: Check EVERYTHING for the URL via Recursion
                   debugPrint("--- RELIEF MAP LAYER SCAN (RECURSIVE) ---");
                   for (final layer in map.operationalLayers) {
                      _scanLayerRecursive(layer, 0);
                   }
                   debugPrint("--- END SCAN ---");

                   if (map.initialViewpoint != null) {
                      _mapViewController?.setViewpoint(map.initialViewpoint!);
                   } else if (map.operationalLayers.isNotEmpty) {
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

          // 2. Bottom-Right Controls (Home & Locate)
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                // Home Button
                FloatingActionButton.small(
                  heroTag: "relief_home_btn",
                  onPressed: _onHomePressed,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(height: 10),
                // Locate Button
                FloatingActionButton.small(
                  heroTag: "relief_locate_btn",
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
              heroTag: "relief_layer_list_btn",
              onPressed: () {
                // Toggle Layer List Drawer/Modal
                showModalBottomSheet(
                  context: context, 
                  builder: (ctx) {
                    final layers = _mapViewController?.arcGISMap?.operationalLayers ?? [];
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          height: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Layer List", style: Theme.of(context).textTheme.headlineSmall),
                              const Divider(),
                              Expanded(
                                child: layers.isEmpty 
                                  ? const Center(child: Text("No layers found."))
                                  : ListView.builder(
                                      itemCount: layers.length,
                                      itemBuilder: (context, index) {
                                        final layer = layers[index];
                                        return CheckboxListTile(
                                          title: Text(layer.name.isNotEmpty ? layer.name : "Layer $index"),
                                          value: layer.isVisible,
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              layer.isVisible = value ?? true;
                                            });
                                            // Force map update if needed, though property binding should handle it
                                            setState(() {}); 
                                          },
                                        );
                                      },
                                    ),
                              )
                            ],
                          ),
                        );
                      }
                    );
                  }
                );
              },
              child: const Icon(Icons.layers),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 20, 
            child: FloatingActionButton.small(
               heroTag: "relief_back_btn",
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
