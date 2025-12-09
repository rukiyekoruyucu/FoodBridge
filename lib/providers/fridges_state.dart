import 'package:geolocator/geolocator.dart';
import 'package:foodbridge/models/fridge.dart';

class FridgesState {
  final List<Fridge> fridges;
  final bool isLoading;
  final String? error;
  final Position? currentLocation;
  FridgesState({
    this.fridges = const [],
    this.isLoading = false,
    this.error,
    this.currentLocation,
  });

  FridgesState copyWith({
    List<Fridge>? fridges,
    bool? isLoading,
    String? error,
    Position? currentLocation,
  }) {
    return FridgesState(
      fridges: fridges ?? this.fridges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}