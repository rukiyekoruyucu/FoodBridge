import 'package:foodbridge/models/private_fridge.dart';

class PrivateFridgesState {
  final bool isLoading;
  final String? error;
  final List<PrivateFridge> fridges;

  const PrivateFridgesState({
    required this.isLoading,
    required this.error,
    required this.fridges,
  });

  factory PrivateFridgesState.initial() {
    return const PrivateFridgesState(
      isLoading: false,
      error: null,
      fridges: [],
    );
  }

  PrivateFridgesState copyWith({
    bool? isLoading,
    String? error,
    List<PrivateFridge>? fridges,
    bool clearError = false,
  }) {
    return PrivateFridgesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fridges: fridges ?? this.fridges,
    );
  }
}
