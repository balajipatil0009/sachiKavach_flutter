import 'package:flutter/material.dart';
import 'package:sachi_app/home_page.dart';

import 'package:sachi_app/services/arcgis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachi_app/screens/onboarding_screen.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize ArcGIS with API Key globally
  ArcGISService.initialize();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final hasUser = prefs.containsKey('user_name') && prefs.containsKey('user_email');

  runApp(MyApp(showOnboarding: !hasUser));
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

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
      home: widget.showOnboarding ? const OnboardingScreen() : const HomePage(),
    );
  }
}
