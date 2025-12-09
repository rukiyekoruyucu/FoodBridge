import 'package:geolocator/geolocator.dart';
import 'dart:io';

class LocationService {
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable the services');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, change it in your settings.');
    }
    return true;
  }

  Future<Position> getCurrentLocation() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      final LocationSettings locationSettings;

      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: false,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
        );
      }

      return await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);

  }catch (e) {
      rethrow;
}
  }
}