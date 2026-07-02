import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodbridge/services/donation_api_service.dart';
import 'donations_state.dart';

final donationApiServiceProvider = Provider((ref) => DonationApiService());

class DonationsNotifier extends StateNotifier<DonationsState> {
  final DonationApiService _api;
  DonationsNotifier(this._api) : super(DonationsState());

  // Kullanıcının kendi bağış geçmişi
  Future<void> fetchMyDonations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _api.listMyDonations();
      state = state.copyWith(activeDonations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Donor tarafı: item'a gelen istekleri çek
  Future<void> fetchItemRequests(int itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _api.listItemRequests(itemId: itemId);
      state = state.copyWith(activeDonations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> reject(int donationId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.rejectRequest(donationId: donationId, reason: reason);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Needy (veya trade): istek at
  Future<void> requestDonation(int itemId, {String type = 'DONATION'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.requestDonation(itemId: itemId, type: type);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Donor: kabul
  Future<void> accept(int donationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.acceptRequest(donationId: donationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // İki taraf: confirm-pickup (backend içinde iki tarafı da handle ediyor)
  Future<void> confirmPickup(int donationId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.confirmPickup(donationId: donationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final donationsProvider =
    StateNotifierProvider<DonationsNotifier, DonationsState>((ref) {
      return DonationsNotifier(ref.watch(donationApiServiceProvider));
    });
