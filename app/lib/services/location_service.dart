import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<void> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Konum servisleri kapalı');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Konum izni reddedildi');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Konum izni kalıcı reddedildi (Ayarlar)');
    }
  }

  Future<Position> getCurrentLocation() async {
    await _ensurePermission();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}
