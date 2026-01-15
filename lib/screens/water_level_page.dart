import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sachi_app/services/water_level_service.dart';

class WaterLevelPage extends StatefulWidget {
  const WaterLevelPage({super.key});

  @override
  State<WaterLevelPage> createState() => _WaterLevelPageState();
}

class _WaterLevelPageState extends State<WaterLevelPage> {
  final WaterLevelService _service = WaterLevelService();
  Map<String, int> _levels = {'level1': 0, 'level2': 0, 'level3': 0};
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Auto-refresh every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final data = await _service.fetchWaterLevels();
    if (mounted) {
      setState(() {
        _levels = data;
        _isLoading = false;
      });
    }
  }

  // Determine color based on the logic provided:
  // key 3 = 1 -> all red
  // key 2 = 1 -> 1,2 red, 3 green
  // key 1 = 1 -> 1 red, others green
  Color _getLevelColor(int levelIndex) {
    int l1 = _levels['level1'] ?? 0;
    int l2 = _levels['level2'] ?? 0;
    int l3 = _levels['level3'] ?? 0;

    if (l3 == 1) {
      return Colors.red; // All red
    } else if (l2 == 1) {
      if (levelIndex == 3) return Colors.green;
      return Colors.red; // 1 and 2 red
    } else if (l1 == 1) {
      if (levelIndex == 1) return Colors.red;
      return Colors.green; // 2 and 3 green
    } else {
      return Colors.green; // All safe
    }
  }

  String _getStatusText() {
    int l1 = _levels['level1'] ?? 0;
    int l2 = _levels['level2'] ?? 0;
    int l3 = _levels['level3'] ?? 0;
    
    if (l3 == 1) return "Water level at Zone 3 has breached the risk level.";
    if (l2 == 1) return "Water level at Zone 2 has breached the risk level.";
    if (l1 == 1) return "Water level at Zone 1 has breached the risk level.";
    return "NO Danger Detected";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Levels"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: _getStatusText().contains("NORMAL") ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusText().contains("NORMAL") ? Colors.green : Colors.red, 
                        width: 2
                      )
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusText().contains("NORMAL") ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Visual Indicators - Stacked vertically as water levels usually are
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLevelIndicator("Zone 3 at Danger", 3),
                        _buildLevelIndicator("Zone 2 at Danger", 2),
                        _buildLevelIndicator("Zone 1 at Danger", 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelIndicator(String label, int levelIndex) {
    Color color = _getLevelColor(levelIndex);
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Text(
              "$levelIndex",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                color == Colors.red ? "DANGER" : "SAFE",
                 style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
