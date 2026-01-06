import 'package:flutter/material.dart';
import 'package:sachi_app/map_page.dart'; // Import for MapPage
import 'package:sachi_app/map_page.dart'; // Import for MapPage
import 'package:sachi_app/placeholder_pages.dart';
import 'package:sachi_app/screens/boulders_screen.dart';
import 'package:sachi_app/screens/relief_map_screen.dart';
import 'package:sachi_app/screens/weather_screen.dart';
import 'package:sachi_app/screens/water_level_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0), // Increased edge padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center header
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Smart FloodGuard",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Color(0xFF3F51B5), size: 32),
                        onPressed: () {
                          // TODO: Implement Help
                          showDialog(
                            context: context,
                            builder: (context) => const AlertDialog(
                              title: Text("Help"),
                              content: Text("Help and Support information will go here."),
                            ),
                          );
                        },
                      ),
                      const Text(
                        "Help",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16, // Reduced spacing
                  mainAxisSpacing: 16, // Reduced spacing
                  childAspectRatio: 0.85, 
                  children: [
                    _buildMenuButton(
                      context,
                      "Weather",
                      Icons.cloud,
                      const WeatherScreen(),
                    ),
                    _buildMenuButton(
                      context,
                      "Water Level",
                      Icons.water,
                      const WaterLevelPage(),
                    ),
                    _buildMenuButton(
                      context,
                      "Risk Zones",
                      Icons.warning_amber,
                      const RiskZonesPage(),
                    ),
                    _buildMenuButton(
                      context,
                      "Hydro Layers",
                      Icons.layers,
                      const HydroLayersPage(),
                    ),
                    _buildMenuButton(
                      context,
                      "Relief Sites",
                      Icons.health_and_safety,
                      const ReliefMapScreen(), 
                    ),
                    _buildMenuButton(
                      context,
                      "Boulders movement",
                      Icons.terrain,
                      const BouldersScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, IconData icon, Widget page) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Ensure text is centered
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Slightly reduced padding to balance spacing
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4472C4), // Blue color from image
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 48, 
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8), // Reduced gap between box and text
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Wrapper for MapPage to handle the performance overlay state locally if needed,
// or just pass defaults.
class MapPageRoute extends StatefulWidget {
  const MapPageRoute({super.key});

  @override
  State<MapPageRoute> createState() => _MapPageRouteState();
}

class _MapPageRouteState extends State<MapPageRoute> {
  bool _showPerformanceOverlay = false;

  void _togglePerformanceOverlay() {
    setState(() {
      _showPerformanceOverlay = !_showPerformanceOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We need to wrap this in a Theme/Scaffold context if MapPage expects it,
    // but MapPage returns a Scaffold, so it's fine.
    // However, MapPage relies on being inside a MaterialApp that has showPerformanceOverlay set.
    // Since we are pushing a new route, we can't easily change the MaterialApp property from here 
    // without a global state management.
    // For now, the performance overlay toggle inside MapPage might not work as expected 
    // if it relies on the parent MaterialApp rebuilding.
    // BUT, looking at main.dart, the toggle rebuilds MyApp.
    // If we navigate away from MyApp's home, we are still in the same MaterialApp.
    // But `Navigator.push` puts us on a stack.
    // The `showPerformanceOverlay` property is on `MaterialApp`.
    // So to toggle it from a child page, we need to lift the state up or use a global.
    
    // For this specific task, I will disable the performance overlay toggle functionality 
    // for the "Relief Sites" navigation path to keep it simple, 
    // or I'll just pass a dummy callback and false.
    // The user asked for the map page.
    
    return MapPage(
      onTogglePerformance: () {
         // Show a snackbar saying it's disabled in this view or implement global state later.
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Performance overlay toggle only available from root debug view")),
         );
      },
      showPerformanceOverlay: false,
    );
  }
}
