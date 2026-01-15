import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a help request with the current user location.
  /// Returns null if successful, or an error message string if failed.
  Future<String?> sendHelpRequest() async {
    try {
      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // 2. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 3. Create data payload
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Unknown User';
      final userEmail = prefs.getString('user_email') ?? 'Unknown Email';

      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'user_name': userName,
        'user_email': userEmail,
      };

      // 4. Send to Firestore
      await _firestore.collection('help_requests').add(data);

      return null; // Success
    } catch (e) {
      if (kDebugMode) {
        print('Error sending help request: $e');
      }
      return 'Failed to send help request: $e';
    }
  }
}
