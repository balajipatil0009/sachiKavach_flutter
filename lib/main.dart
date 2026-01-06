import 'package:flutter/material.dart';
import 'package:sachi_app/home_page.dart';

import 'package:sachi_app/services/arcgis_service.dart';

void main() {
  // Initialize ArcGIS with API Key globally
  ArcGISService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Performance overlay is global to the app
  bool _showPerformanceOverlay = false;

  void _togglePerformanceOverlay() {
    setState(() {
      _showPerformanceOverlay = !_showPerformanceOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart FloodGuard',
      showPerformanceOverlay: _showPerformanceOverlay,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
