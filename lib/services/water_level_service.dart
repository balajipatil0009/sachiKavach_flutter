import 'package:http/http.dart' as http;
import 'dart:convert';

class WaterLevelService {
  // API Endpoints
  final String _level1Url = "https://blynk.cloud/external/api/get?token=Y9zc_i2jPV9p7H3YS49h2MjGHQaX1AoQ&V1";
  final String _level2Url = "https://blynk.cloud/external/api/get?token=Y9zc_i2jPV9p7H3YS49h2MjGHQaX1AoQ&V2";
  final String _level3Url = "https://blynk.cloud/external/api/get?token=Y9zc_i2jPV9p7H3YS49h2MjGHQaX1AoQ&V3";

  // Fetch water levels
  // Returns a Map with keys 'level1', 'level2', 'level3' and boolean values indicating if water is detected (true) or not (false).
  Future<Map<String, int>> fetchWaterLevels() async {
    try {
      final response1 = await http.get(Uri.parse(_level1Url));
      final response2 = await http.get(Uri.parse(_level2Url));
      final response3 = await http.get(Uri.parse(_level3Url));

      if (response1.statusCode == 200 &&
          response2.statusCode == 200 &&
          response3.statusCode == 200) {
        
        // Parse the body as integer (API returns 0 or 1)
        int val1 = int.tryParse(response1.body) ?? 0;
        int val2 = int.tryParse(response2.body) ?? 0;
        int val3 = int.tryParse(response3.body) ?? 0;

        return {
          'level1': val1,
          'level2': val2,
          'level3': val3,
        };
      } else {
        throw Exception("Failed to load water levels");
      }
    } catch (e) {
      print("Error fetching water levels: $e");
      // Return default safe values or rethrow
      return {
        'level1': 0,
        'level2': 0,
        'level3': 0,
      };
    }
  }
}
