import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static String? _tenantId;
  static set tenantId(String? id) => _tenantId = id;

  static Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (_tenantId != null) {
      headers['x-tenant-id'] = _tenantId!;
    }
    return headers;
  }
  static dynamic _processResponse(http.Response response, String defaultError) {
    if (response.statusCode == 401) {
      throw Exception('Not authorized: Session expired');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw Exception(defaultError);
  }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/user-login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': 'b2c',
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/google-login'),
      headers: _getHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode(userData),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<String?> uploadFile(File file) async {
    try {
      print('Starting upload for file: ${file.path} to: ${ApiConstants.baseUrl}/upload');
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/upload'));
      
      // Use fromPath but ensure we handle potential errors
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        file.path,
        // mimetype is optional but can help
      ));
      
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      
      print('Upload Status Code: ${response.statusCode}');
      print('Upload Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload Exception: $e');
      return null;
    }
  }

  static String get baseUrl => ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(token),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to fetch profile'));
  }

  static Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to update profile'));
  }
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/categories'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<List<dynamic>> getBanners(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/banners'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getPopupAds(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/popup-ads'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getFeed() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/feed'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>> placeOrder(String token, Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/orders'),
      headers: _getHeaders(token),
      body: jsonEncode(orderData),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to place order: ${response.body}'));
  }

  static Future<List<dynamic>> getMyOrders(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/orders/myorders'),
      headers: _getHeaders(token),
    );
    return List<dynamic>.from(_processResponse(response, 'Failed to fetch orders'));
  }

  static Future<Map<String, dynamic>> createReview(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reviews'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to create review'));
  }

  static Future<List<dynamic>> getProductReviews(String productId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reviews/product/$productId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch reviews');
  }

  static Future<List<dynamic>> getAddresses(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/addresses'),
      headers: _getHeaders(token),
    );
    return List<dynamic>.from(_processResponse(response, 'Failed to fetch addresses'));
  }

  static Future<List<dynamic>> addAddress(String token, Map<String, dynamic> address) async {
    final url = '${ApiConstants.baseUrl}/auth/addresses';
    print('Add Address Request URL: $url');
    print('Add Address Request Body: ${jsonEncode(address)}');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(token),
      body: jsonEncode(address),
    );
    
    print('Add Address Response Status: ${response.statusCode}');
    print('Add Address Response Body: ${response.body}');
    
    return List<dynamic>.from(_processResponse(response, 'Failed to add address: ${response.statusCode} - ${response.body}'));
  }

  static Future<List<dynamic>> deleteAddress(String token, String addressId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/auth/addresses/$addressId'),
      headers: _getHeaders(token),
    );
    return List<dynamic>.from(_processResponse(response, 'Failed to delete address'));
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String token, String orderId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/status'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to update order status: ${response.body}'));
  }

  static Future<bool> returnOrderItem(String token, String orderId, String itemId, String reason, {String? comment, String? imageUrl}) async {
    final body = {'returnReason': reason};
    if (comment != null && comment.isNotEmpty) body['returnComment'] = comment;
    if (imageUrl != null && imageUrl.isNotEmpty) body['returnImage'] = imageUrl;

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/items/$itemId/return'),
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> findTenantByPincode(String pincode) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tenancy/find/$pincode'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Location not served yet');
  }

  static Future<List<dynamic>> getAvailableLocations() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tenancy/locations'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch locations');
  }

  static Future<Map<String, dynamic>> getMinimumBilling() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/commissions/public/minimum-billing'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'minimumBillAmountB2B': 2000, 'minimumBillAmountB2C': 500};
  }

  static Future<List<dynamic>> getDeliverySlots(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/deliveries/slots'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> reportUnservedLocation(String pincode, {String? email, String? phone}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tenancy/report-unserved'),
      headers: _getHeaders(),
      body: jsonEncode({
        'pincode': pincode,
        'email': email,
        'phone': phone,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to report unserved location');
    }
  }

  static Future<Map<String, dynamic>> getDriverLocation(String token, String orderId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/driver-location'),
      headers: _getHeaders(token),
    );
    return Map<String, dynamic>.from(_processResponse(response, 'Failed to fetch driver location: ${response.body}'));
  }

  static Future<void> registerFcmToken(String token, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/register-token'),
        headers: _getHeaders(token),
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode != 200) {
        print('FCM registration failed: ${response.body}');
      }
    } catch (e) {
      print('FCM registration error: $e');
    }
  }

  static Future<void> triggerExitNotification(String? fcmToken, String type, {String? productName}) async {
    try {
      if (fcmToken == null) return;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/trigger-exit'),
        headers: _getHeaders(),
        body: jsonEncode({
          'fcmToken': fcmToken,
          'type': type,
          'productName': productName,
        }),
      );
      if (response.statusCode != 200) {
        print('FCM trigger failed: ${response.body}');
      }
    } catch (e) {
      print('FCM trigger error: $e');
    }
  }
}
