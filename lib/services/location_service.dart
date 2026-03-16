import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Requests location permissions and retrieves the user's current address.
  /// Throws an exception if permissions are denied or service is disabled.
  static Future<String> getCurrentAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled. We cannot proceed.
      // Ask the user to enable them.
      throw Exception('Location services are disabled. Please enable them in settings.');
    }

    // 2. Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in system settings.');
    }

    // 3. Get the current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Retrieve placemarks (address) from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Build a readable address
        // Example: "1600 Amphitheatre Parkway, Mountain View, CA 94043"
        List<String> addressParts = [];
        if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        
        if (addressParts.isNotEmpty) {
           return addressParts.join(', ');
        }
        
        return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      } else {
        return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      debugPrint('[LocationService] Error getting address: $e');
      throw Exception('Failed to get current location: $e');
    }
  }
}
