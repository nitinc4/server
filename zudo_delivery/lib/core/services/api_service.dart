import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static String? _currentTenant;
  static void setTenant(String? tenant) => _currentTenant = tenant;

  static String get baseUrl => ApiConstants.baseUrl;

  static Map<String, String> _getHeaders([String? token]) {
    print('DEBUG: ApiService using tenant: $_currentTenant');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (_currentTenant != null) 'x-tenant-id': _currentTenant!,
    };
  }

  static Future<List<dynamic>> getAvailableLocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tenancy/locations'),
      headers: _getHeaders(),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to fetch available locations');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('DEBUG: Attempting login for $email at $baseUrl/auth/driver-login');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/driver-login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    print('DEBUG: Response Status: ${response.statusCode}');
    if (response.body.trim().startsWith('<')) {
      throw Exception('Server returned HTML error. Check backend URL.');
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to parse server response.');
    }
  }

  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  // Delivery Specific API Calls
  static Future<Map<String, dynamic>> loginCashCollector(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/cash-collector-login'),
      headers: _getHeaders(),
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAssignedOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/driver/assigned'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getCashAssignedOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/assigned-cash'),
      headers: _getHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateLocation(String token, double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/drivers/location'),
      headers: _getHeaders(token),
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update live location');
  }

  static Future<List<dynamic>> getDeliverySlots(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/deliveries/slots'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> updateOrderStatus(String token, String orderId, String status, {String? sellerId}) async {
    final body = {'status': status};
    if (sellerId != null) {
      body['sellerId'] = sellerId;
    }
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _getHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update order status');
  }

  static Future<List<dynamic>> getDriverHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/driver/history'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> returnPickup(String token, String orderId, String otp) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/return-pickup'),
      headers: _getHeaders(token),
      body: jsonEncode({'otp': otp}),
    );
    if (response.statusCode >= 300) throw Exception('Failed to verify return pickup: ${response.body}');
  }

  static Future<void> returnDelivery(String token, String orderId, String sellerId, String otp) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/return-delivery'),
      headers: _getHeaders(token),
      body: jsonEncode({'sellerId': sellerId, 'otp': otp}),
    );
    if (response.statusCode >= 300) throw Exception('Failed to verify return dropoff: ${response.body}');
  }

  static Future<Map<String, dynamic>> updatePaymentInfo(String token, String orderId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/payment'),
      headers: _getHeaders(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to update payment info');
  }

  static Future<String> uploadFile(String token, File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers.addAll(_getHeaders(token));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    }
    throw Exception('Failed to upload file');
  }

  static Future<Map<String, dynamic>> createDeposit(String token, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deposits'),
      headers: _getHeaders(token),
      body: jsonEncode({'amount': amount}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyDepositOtp(String token, String depositId, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deposits/verify'),
      headers: _getHeaders(token),
      body: jsonEncode({'depositId': depositId, 'otp': otp}),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getDepositHistory(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/deposits/my'),
      headers: _getHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAttendance(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/attendance'),
      headers: _getHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> markAttendance(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/drivers/attendance/mark'),
      headers: _getHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> loginSales(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getSalesB2BStoreList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/sales/my-b2b'),
      headers: _getHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> placeSalesOrder(String token, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.body.trim().startsWith('<')) {
      throw Exception('Server error: Received HTML instead of JSON');
    }
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['message'] ?? 'Request failed with status ${response.statusCode}');
  }
}
