import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArcGIS Flutter Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Create a controller for the map view
  ArcGISMapViewController? _mapViewController;
  bool _isLoading = true;
  
  // Initial map point (San Diego, CA)
  final ArcGISPoint _initialPoint = ArcGISPoint(
    x: -117.195,
    y: 34.05,
    spatialReference: SpatialReference.wgs84,
  );

  @override
  void initState() {
    super.initState();
    // Initialize ArcGIS with API Key
    ArcGISEnvironment.apiKey = 'AAPTxy8BH1VEsoebNVZXo8HurKVFVtxGxYil8tYfrgYheue6EitQwq8j0Ul2Sorfcypzab9gM9lcOMs6pUTnd7MUeAIT1xHbikAoG_whBsAFjboP2xN8GRc7iUrSZp7yLHZqQdgEcCL4P9RUe_VA8shMo8bOOh0lUXqWEF4iaQmL74s5ozIMuqMmRDjH9t5BDYqsO5Emjunvf1VYrEeEtrzBYGd39WXlAe9qy-chJ_SmDi71LZMcIcL9HLAoNHWxMe8TAT1_maHWBa8E';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArcGIS Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () {
              _mapViewController = ArcGISMapView.createController();
              return _mapViewController!;
            },
            onMapViewReady: () {
              // Set the map to the controller
              _mapViewController?.arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
              
              // Set initial viewpoint
              _mapViewController?.setViewpoint(
                Viewpoint.fromCenter(
                  _initialPoint,
                  scale: 100000.0,
                ),
              );
              
              // Hide loading indicator when map is ready
              setState(() {
                _isLoading = false;
              });
            },
          ),
          if (_isLoading)
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
                    // Change Basemap
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
