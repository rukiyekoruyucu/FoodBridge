import 'package:dio/dio.dart';
import 'package:foodbridge/core/api_client.dart';
import 'package:foodbridge/models/donation.dart';

class DonationApiService {
  final Dio _dio = apiClient;

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final v = data['data'] ?? data['items'] ?? data['results'];
      if (v is List) return v;
    }
    return const [];
  }

  Future<void> requestDonation({required int itemId, String? type}) async {
    try {
      await apiClient.post(
        '/donations/request',
        data: {
          'itemId': itemId,
          if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) {
        throw Exception("Zaten bu bağış için istek attın.");
      }
      throw Exception(_msg(e));
    }
  }

  Future<void> rejectRequest({required int donationId, String? reason}) async {
    try {
      await _dio.post(
        '/donations/$donationId/reject',
        data: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_msg(e));
    }
  }

  Future<List<Donation>> listItemRequests({required int itemId}) async {
    final res = await _dio.get('/donations/items/$itemId/requests');
    final list = _asList(res.data);
    return list
        .map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> acceptRequest({required int donationId}) async {
    await _dio.post('/donations/$donationId/accept');
  }

  Future<void> confirmPickup({required int donationId}) async {
    await _dio.post('/donations/$donationId/confirm-pickup');
  }

  Future<List<Donation>> listMyDonations() async {
    final res = await _dio.get('/donations/me');
    final list = _asList(res.data);
    return list
        .map((e) => Donation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m != null) return m.toString();
    }
    if (data is String) return data;
    return e.message ?? 'İstek başarısız.';
  }
}
