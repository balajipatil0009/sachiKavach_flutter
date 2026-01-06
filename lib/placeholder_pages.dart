import 'package:flutter/material.dart';
import 'package:sachi_app/screens/hydro_map_screen.dart';
import 'package:sachi_app/screens/risk_zones_map_screen.dart';
import 'package:sachi_app/screens/tables_map_screen.dart';


class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "$title Page",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text("Under Construction"),
          ],
        ),
      ),
    );
  }
}

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: "Weather");
  }
}



class RiskZonesPage extends StatelessWidget {
  const RiskZonesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const RiskZonesMapScreen();
  }
}

class HydroLayersPage extends StatelessWidget {
  const HydroLayersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const HydroMapScreen();
  }
}

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const TablesMapScreen();
  }
}
