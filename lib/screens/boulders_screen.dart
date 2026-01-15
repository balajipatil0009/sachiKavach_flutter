import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BouldersScreen extends StatefulWidget {
  const BouldersScreen({super.key});

  @override
  State<BouldersScreen> createState() => _BouldersScreenState();
}

class _BouldersScreenState extends State<BouldersScreen> {
  String _status = "Loading...";
  bool _isLoading = true;
  bool _isDanger = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Using same API endpoint as requested
      final response = await http.get(Uri.parse(
          'https://blynk.cloud/external/api/get?token=Y9zc_i2jPV9p7H3YS49h2MjGHQaX1AoQ&V0'));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        
        if (body == '1') {
          setState(() {
            _isDanger = true;
            _status = "Alert: Movement of boulders has been detected. Avoid approaching the riverbank.";
            _isLoading = false;
          });
        } else {
          // 0 or other values
          setState(() {
            _isDanger = false;
            _status = "No Movement Detected. ";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to fetch data. Status code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error connecting to service: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Boulders Monitor"),
        backgroundColor: _isLoading 
            ? Colors.grey 
            : (_isDanger ? Colors.redAccent : Colors.green),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text("Checking sensor data...", style: TextStyle(fontSize: 18)),
              ] else if (_errorMessage.isNotEmpty) ...[
                const Icon(Icons.error_outline, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchStatus,
                  child: const Text("Retry"),
                )
              ] else ...[
                Icon(
                  _isDanger ? Icons.warning_amber_rounded : Icons.landscape_rounded,
                  size: 100,
                  color: _isDanger ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 30),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isDanger ? Colors.red[900] : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                // const SizedBox(height: 20),
                // Text(
                //   _isDanger
                //       ? "Immediate caution advised in rocky areas."
                //       : "Area appears stable.",
                //   style: const TextStyle(fontSize: 16),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _fetchStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Status"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
