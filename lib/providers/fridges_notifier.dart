import 'package:riverpod/legacy.dart';

import 'package:foodbridge/services/fridge_api_service.dart';
import 'package:foodbridge/services/location_service.dart';
import 'fridges_state.dart';

class FridgesNotifier extends StateNotifier<FridgesState> {
  final FridgeApiService _fridgeApi;
  final LocationService _locationService;

  FridgesNotifier(this._fridgeApi, this._locationService) : super(FridgesState());

  Future<void> loadFridgesNearMe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final position = await _locationService.getCurrentLocation();
      final fridges = await _fridgeApi.fetchFridgesNearMe(
        position.latitude,
        position.longitude,
      );
      state = state.copyWith(
        fridges: fridges,
        currentLocation: position,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
}

final fridgesProvider = StateNotifierProvider<FridgesNotifier, FridgesState>((ref) {
  return FridgesNotifier(FridgeApiService(), LocationService());
});