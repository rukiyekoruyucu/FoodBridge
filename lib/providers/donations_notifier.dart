import 'package:flutter_riverpod/legacy.dart';

import 'package:foodbridge/services/donation_api_service.dart';
import 'donations_state.dart'; 

final donationApiServiceProvider = StateProvider((ref) => DonationApiService());

class DonationsNotifier extends StateNotifier<DonationsState>{
  final DonationApiService _donationApi;
  
  DonationsNotifier(this._donationApi) : super(DonationsState());

  Future<void> requestItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _donationApi.requestItem(itemId);

      state = state.copyWith(isLoading: false);
    }catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> respondToRequest(String donationId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _donationApi.respondToRequest(donationId, status);

      state = state.copyWith(isLoading: false);
    }catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }

  }

  Future <void> fetchDonations() async{
    state = state.copyWith(isLoading: true, error: null);
    try{

      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false);
    }catch(e){
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  Future<void> confirmPickup(String donationId) async{
    state = state.copyWith(isLoading: true, error: null);
    try{
      await _donationApi.confirmPickup(donationId);

      await fetchDonations();

      state = state.copyWith(isLoading: false);
    }catch(e){
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
      rethrow;
    }
  }
}
  
final donationsProvider = StateNotifierProvider<DonationsNotifier, DonationsState>((ref) {
  return DonationsNotifier(ref.watch(donationApiServiceProvider));

});
