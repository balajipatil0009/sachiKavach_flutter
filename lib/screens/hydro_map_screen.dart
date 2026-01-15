
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
    // Initialize with Hydro API Key
    ArcGISService.initializeHydro();
  }

  /// Handles the "Home" button press
  void _onHomePressed() {
    final map = _mapViewController?.arcGISMap;
    if (map != null) {
        if (map.initialViewpoint != null) {
          _mapViewController?.setViewpoint(map.initialViewpoint!);
        } else {
             // Fallback
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
               // 1. Get the Map from Service (Loads via Portal Item ID)
               final map = ArcGISService.getHydroMap();
               _mapViewController?.arcGISMap = map;
               _mapViewController?.graphicsOverlays.add(_locationOverlay);

               // 2. Handling Layers (as per Algorithm)
               // "In Flutter, you often listen to the load status or await the load"
               map.load().then((_) {
                 if (mounted && map.loadStatus == LoadStatus.loaded) {
                   // Access operational layers and ensure visibility
                   for (var layer in map.operationalLayers) {
                      debugPrint("Layer: ${layer.name}");
                      layer.isVisible = true; // Algorithm Step 4: Force Visibility
                   }

                   // Zoom Logic (aligned with Algorithm Step 2/3 implication of map usage)
                   // If the Web Map has an initial viewpoint, the view usually respects it automatically
                   // when set to the controller. However, explicit setting is often safer in Flutter SDK.
                  // Zoom Strategy: Priority to Layer Content
                  if (map.operationalLayers.isNotEmpty) {
                      debugPrint("HydroMap: Found layers. Prioritizing Layer Zoom over Map Viewpoint.");
                      final layer = map.operationalLayers.first;
                      
                      layer.load().then((_) {
                         debugPrint("HydroMap: Layer '${layer.name}' loaded. Status: ${layer.loadStatus}");
                         
                         if (mounted && layer.fullExtent != null) {
                            debugPrint("HydroMap: Zooming to '${layer.name}' extent: ${layer.fullExtent}");
                            _mapViewController?.setViewpointGeometry(layer.fullExtent!);
                         } else {
                            debugPrint("HydroMap: Layer fullExtent is null. Falling back to map viewpoint.");
                             if (map.initialViewpoint != null) {
                                _mapViewController?.setViewpoint(map.initialViewpoint!);
                             }
                         }
                      });
                   } else if (map.initialViewpoint != null) {
                      _mapViewController?.setViewpoint(map.initialViewpoint!);
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
                  heroTag: "home_btn_hydro",
                  onPressed: _onHomePressed,
                  child: const Icon(Icons.home),
                ),
                const SizedBox(height: 10),
                // Locate Button
                FloatingActionButton.small(
                  heroTag: "locate_btn_hydro",
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
              heroTag: "layer_list_btn_hydro",
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
               heroTag: "back_btn_hydro",
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