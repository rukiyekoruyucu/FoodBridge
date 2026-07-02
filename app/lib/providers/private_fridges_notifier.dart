import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:foodbridge/providers/private_fridges_state.dart';
import 'package:foodbridge/services/private_fridge_api_service.dart';

class PrivateFridgesNotifier extends StateNotifier<PrivateFridgesState> {
  final PrivateFridgeApiService _api;

  PrivateFridgesNotifier(this._api) : super(PrivateFridgesState.initial());

  String _prettyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map) {
        final msg =
            data['message'] ??
            data['error'] ??
            data['details'] ??
            data['errors'];
        if (msg != null) return 'HTTP $status: $msg';
      }
      return 'HTTP $status: ${e.message}';
    }
    return e.toString();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fridges = await _api.listMyPrivateFridges();
      state = state.copyWith(isLoading: false, fridges: fridges);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _prettyError(e));
    }
  }

  Future<void> create({
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _api.createPrivateFridge(
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      state = state.copyWith(
        isLoading: false,
        fridges: [created, ...state.fridges],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _prettyError(e));
    }
  }

  Future<void> update(
    String id, {
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _api.updatePrivateFridge(
        id,
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      final newList = state.fridges
          .map((f) => f.id == id ? updated : f)
          .toList();
      state = state.copyWith(isLoading: false, fridges: newList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _prettyError(e));
    }
  }

  Future<void> remove(String id) async {
    final prev = state.fridges;
    state = state.copyWith(fridges: prev.where((f) => f.id != id).toList());
    try {
      await _api.deletePrivateFridge(id);
    } catch (e) {
      // geri al
      state = state.copyWith(fridges: prev, error: _prettyError(e));
    }
  }
}

final privateFridgesProvider =
    StateNotifierProvider<PrivateFridgesNotifier, PrivateFridgesState>((ref) {
      return PrivateFridgesNotifier(PrivateFridgeApiService());
    });
