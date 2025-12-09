import 'package:foodbridge/models/donation.dart';

class DonationsState {
  final List<Donation> activeDonations;
  final bool isLoading;
  final String? error;

  DonationsState({
    this.activeDonations = const [],
    this.isLoading = false,
    this.error,
  });

  DonationsState copyWith({
    List<Donation>? activeDonations,
    bool? isLoading,
    String? error,
  }) {
    return DonationsState(
      activeDonations: activeDonations ?? this.activeDonations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}