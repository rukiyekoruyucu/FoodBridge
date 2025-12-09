import 'package:foodbridge/utils/api_client.dart';

class DonationApiService{

  Future<Map<String, dynamic>> requestItem(String itemId) async{
    final response = await apiClient.post('/donations/request', data: {
      'itemId': itemId,
    });

    return response.data;
  }

  Future<Map<String, dynamic>> respondToRequest(String donationId, String status) async{
    final response = await apiClient.put('/donationId/$donationId/respond', data: {
      'status': status,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> confirmPickup(String donationId) async{
    final response = await apiClient.post('/donations/$donationId/confirm-pickup');
    return response.data;
  }
}