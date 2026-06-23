import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../../features/auth/user_model.dart';
import '../../features/orders/order_model.dart';

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  UserModel? _currentUser;
  bool _isLoading = false;
  List<OrderModel> _assignedOrders = [];
  List<OrderModel> _deliveryHistory = [];
  
  // Tenancy
  String? _currentTenant;
  String? _currentCity;
  List<Map<String, dynamic>> _availableLocations = [];
  bool _isFetchingLocation = false;
  List<Map<String, dynamic>> _deliverySlots = [];

  List<dynamic> _salesCustomers = [];
  List<dynamic> _salesCatalog = [];
  List<dynamic> _salesCategories = [];

  List<dynamic> get salesCustomers => _salesCustomers;
  List<dynamic> get salesCatalog => _salesCatalog;
  List<dynamic> get salesCategories => _salesCategories;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  List<OrderModel> get assignedOrders => _assignedOrders;
  List<OrderModel> get deliveryHistory => _deliveryHistory;
  
  String? get currentTenant => _currentTenant;
  String? get currentCity => _currentCity;
  List<Map<String, dynamic>> get availableLocations => _availableLocations;
  bool get isFetchingLocation => _isFetchingLocation;
  List<Map<String, dynamic>> get deliverySlots => _deliverySlots;

  AppState() {
    _loadFromPrefs();
    fetchAvailableLocations();
  }

  Future<void> fetchAvailableLocations() async {
    try {
      final data = await ApiService.getAvailableLocations();
      _availableLocations = List<Map<String, dynamic>>.from(data);
      print('Available locations loaded: ${_availableLocations.map((l) => l['city']).toList()}');
      notifyListeners();
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  Future<void> fetchDeliverySlots() async {
    try {
      if (_token == null) return;
      final List<dynamic> data = await ApiService.getDeliverySlots(_token!);
      _deliverySlots = List<Map<String, dynamic>>.from(data).where((s) => s['isActive'] == true).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching delivery slots: $e');
    }
  }

  void setTenant(String dbName, String city) {
    _currentTenant = dbName;
    _currentCity = city;
    ApiService.setTenant(dbName);
    _saveToPrefs();
    
    // Refresh data if logged in
    if (_isLoggedIn) {
      fetchAssignedOrders();
      fetchDeliveryHistory();
    }
    notifyListeners();
  }

  Future<void> autoFetchLocation({bool force = false}) async {
    if (!force && _currentTenant != null) {
      return;
    }
    
    _isFetchingLocation = true;
    notifyListeners();
    try {
      // 1. Ensure available locations are loaded
      if (_availableLocations.isEmpty) await fetchAvailableLocations();
      
      // 2. Get current city name
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services disabled';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String rawCity = place.locality ?? '';
        if (rawCity.toLowerCase().contains('bangalore')) rawCity = 'Bengaluru';
        final detectedCity = rawCity;
        print('Detected city: $detectedCity');

        // 3. Match with available locations
        print('Attempting to match $detectedCity with ${_availableLocations.length} locations');
        
        String normalize(String name) {
          name = name.toLowerCase();
          if (name.contains('bangalore') || name.contains('bengaluru')) return 'bangalore';
          return name;
        }

        final match = _availableLocations.firstWhere(
          (loc) {
            final city = normalize(loc['city'] as String);
            final detected = normalize(detectedCity);
            return city.contains(detected) || detected.contains(city);
          },
          orElse: () => {},
        );

        if (match.isNotEmpty) {
          print('Match found! Setting tenant to: ${match['dbName']} (${match['city']})');
          setTenant(match['dbName'], match['city']);
        } else {
          print('No matching location found for: "$detectedCity"');
          print('Available locations were: ${_availableLocations.map((l) => l['city']).toList()}');
        }
      }
    } catch (e) {
      print('Auto fetch location error: $e');
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.login(email, password);
      if (response.containsKey('token')) {
        _token = response['token'];
        _currentUser = UserModel.fromJson(response);
        
        // For delivery app, only allow drivers
        if (_currentUser!.role == 'driver' || _currentUser!.role == 'delivery' || _currentUser!.role == 'seller') {
          _isLoggedIn = true;
          _saveToPrefs();
          await fetchAssignedOrders();
          startLocationSharing();
          return true;
        } else {
          _token = null;
          _currentUser = null;
          throw Exception('Access denied. Driver account required.');
        }
      }
      return false;
    } catch (e) {
      print('DEBUG: AppState.login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cashCollectorLogin(String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.loginCashCollector(phone, password);
      if (response['token'] != null) {
        _token = response['token'];
        _currentUser = UserModel.fromJson(response['user']);
        _isLoggedIn = true;
        await _saveToPrefs();
        await fetchAssignedOrders();
        return true;
      }
      return false;
    } catch (e) {
      print('DEBUG: AppState.cashCollectorLogin error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> salesLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.loginSales(email, password);
      if (response.containsKey('token')) {
        _token = response['token'];
        _currentUser = UserModel.fromJson(response);
        
        if (_currentUser!.role == 'sales') {
          _isLoggedIn = true;
          await _saveToPrefs();
          await fetchSalesCustomers();
          await fetchSalesCatalog();
          return true;
        } else {
          _token = null;
          _currentUser = null;
          throw Exception('Access denied. Sales account required.');
        }
      }
      return false;
    } catch (e) {
      print('DEBUG: AppState.salesLogin error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalesCustomers() async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.getSalesB2BStoreList(_token!);
      _salesCustomers = List<dynamic>.from(data);
    } catch (e) {
      print('DEBUG: Error fetching sales customers: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) {
        logout();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalesCatalog() async {
    _isLoading = true;
    notifyListeners();
    try {
      final catalogData = await ApiService.getAllProducts();
      _salesCatalog = List<dynamic>.from(catalogData);
      
      try {
        final categoriesData = await ApiService.getCategories();
        _salesCategories = List<dynamic>.from(categoriesData);
      } catch (catErr) {
        print('DEBUG: Error fetching sales categories: $catErr');
      }
    } catch (e) {
      print('DEBUG: Error fetching sales catalog: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> placeSalesOrderOnBehalf({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
    required String deliverySlot,
  }) async {
    if (_token == null) throw Exception('Not logged in');
    _isLoading = true;
    notifyListeners();
    try {
      final payload = {
        'customerId': customerId,
        'items': items,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'deliverySlot': deliverySlot,
      };
      await ApiService.placeSalesOrder(_token!, payload);
    } catch (e) {
      print('DEBUG: Error placing sales order: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await ApiService.getProfile(_token!);
      _currentUser = UserModel.fromJson(response);
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error fetching profile: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) logout();
    }
  }

  void logout() {
    print('DEBUG: AppState.logout() called from:\n${StackTrace.current}');
    _isLoggedIn = false;
    _token = null;
    _currentUser = null;
    _assignedOrders = [];
    stopLocationSharing();
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> fetchAssignedOrders() async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final isCashCollector = _currentUser?.role == 'cash_collector';
      final List<dynamic> data = isCashCollector
          ? await ApiService.getCashAssignedOrders(_token!)
          : await ApiService.getAssignedOrders(_token!);
          
      _assignedOrders = data.map((json) => OrderModel.fromJson(json)).toList();
      startLocationSharing();
      
      // Also fetch attendance
      if (!isCashCollector) {
        fetchAttendance();
      }
    } catch (e) {
      print('DEBUG: Error fetching assigned orders: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) {
        logout();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? sellerId}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ApiService.updateOrderStatus(_token!, orderId, status, sellerId: sellerId);
      
      // Update local orders
      await fetchAssignedOrders();
      await fetchDeliveryHistory();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeliveryHistory() async {
    if (_token == null) return;
    try {
      final List<dynamic> data = await ApiService.getDriverHistory(_token!);
      _deliveryHistory = data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching delivery history: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) logout();
    } finally {
      notifyListeners();
    }
  }

  Future<void> verifyReturnPickup(String orderId, String otp) async {
    if (_token == null) return;
    _isLoading = true; notifyListeners();
    try {
      await ApiService.returnPickup(_token!, orderId, otp);
      await fetchAssignedOrders();
    } catch (e) {
      print('Error return pickup: $e'); rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> verifyReturnDelivery(String orderId, String sellerId, String otp) async {
    if (_token == null) return;
    _isLoading = true; notifyListeners();
    try {
      await ApiService.returnDelivery(_token!, orderId, sellerId, otp);
      await fetchAssignedOrders();
    } catch (e) {
      print('Error return delivery: $e'); rethrow;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> updatePaymentInfo(String orderId, String screenshotUrl) async {
    if (_token == null) return;
    try {
      await ApiService.updatePaymentInfo(_token!, orderId, {
        'paymentScreenshot': screenshotUrl,
        'paymentStatus': 'Completed'
      });
      await fetchProfile();
      await fetchAssignedOrders();
    } catch (e) {
      print('Error updating payment info: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _depositHistory = [];
  List<Map<String, dynamic>> get depositHistory => _depositHistory;

  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> get attendanceHistory => _attendanceHistory;

  Future<void> fetchAttendance() async {
    if (_token == null) return;
    try {
      final data = await ApiService.getAttendance(_token!);
      _attendanceHistory = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching attendance history: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> markAttendance() async {
    if (_token == null) return false;
    try {
      await ApiService.markAttendance(_token!);
      await fetchAttendance();
      return true;
    } catch (e) {
      print('Error marking attendance: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> submitDeposit(double amount) async {
    if (_token == null) throw Exception('Not logged in');
    _isLoading = true;
    notifyListeners();
    try {
      final deposit = await ApiService.createDeposit(_token!, amount);
      await fetchDepositHistory();
      return deposit;
    } catch (e) {
      print('Error submitting deposit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyDeposit(String depositId, String otp) async {
    if (_token == null) throw Exception('Not logged in');
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.verifyDepositOtp(_token!, depositId, otp);
      await fetchDepositHistory();
      await fetchProfile(); // Refresh wallet balance
    } catch (e) {
      print('Error verifying deposit: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDepositHistory() async {
    if (_token == null) return;
    try {
      final data = await ApiService.getDepositHistory(_token!);
      _depositHistory = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching deposit history: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<String> uploadFile(File file) async {
    if (_token == null) throw Exception('Not logged in');
    return await ApiService.uploadFile(_token!, file);
  }

  // Persistence
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _token = prefs.getString('token');
    _currentTenant = prefs.getString('currentTenant');
    if (_currentTenant == '') _currentTenant = null;
    
    _currentCity = prefs.getString('currentCity');
    if (_currentCity == '') _currentCity = null;

    if (_currentTenant != null) ApiService.setTenant(_currentTenant);

    final userJson = prefs.getString('currentUser');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
    
    if (_isLoggedIn) {
      if (_currentUser?.role == 'sales') {
        fetchSalesCustomers();
        fetchSalesCatalog();
        fetchDeliverySlots();
      } else {
        fetchAssignedOrders();
        fetchDeliveryHistory();
      }
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setString('token', _token ?? '');
    await prefs.setString('currentTenant', _currentTenant ?? '');
    await prefs.setString('currentCity', _currentCity ?? '');
    if (_currentUser != null) {
      // Manual serialization since UserModel doesn't have toJson yet
      await prefs.setString('currentUser', jsonEncode({
        'id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'role': _currentUser!.role,
        'phone': _currentUser!.phone,
        'type': _currentUser!.type,
        'isVerified': _currentUser!.isVerified,
        'wallet': _currentUser!.wallet,
      }));
    } else {
      await prefs.remove('currentUser');
    }
  }

  // --- Live Location Tracking (Share location every 5 mins when active order is picked up) ---
  Timer? _locationTimer;

  void startLocationSharing() {
    if (_locationTimer != null) return; // Already running

    bool hasActiveOrders = _assignedOrders.any((o) =>
        o.status.toLowerCase() == 'out for delivery');

    if (!hasActiveOrders || _token == null) {
      stopLocationSharing();
      return;
    }

    print('DEBUG: Starting periodic live location sharing (every 5 minutes)...');
    _shareLocationNow(); // Update immediately first

    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _shareLocationNow();
    });
  }

  void stopLocationSharing() {
    if (_locationTimer != null) {
      print('DEBUG: Stopping live location sharing.');
      _locationTimer!.cancel();
      _locationTimer = null;
    }
  }

  Future<void> _shareLocationNow() async {
    if (_token == null) {
      stopLocationSharing();
      return;
    }
    
    final hasActiveDelivery = _assignedOrders.any((o) => 
        o.status.toLowerCase() == 'out for delivery');

    if (!hasActiveDelivery) {
      stopLocationSharing();
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG: GPS is disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG: Location permission denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (_token == null) {
        print('DEBUG: Location sharing aborted: token is null (logged out during fetch).');
        return;
      }
      print('DEBUG: Sharing location: Lat: ${position.latitude}, Lng: ${position.longitude}');
      await ApiService.updateLocation(_token!, position.latitude, position.longitude);
    } catch (e) {
      print('DEBUG: Error sharing location: $e');
    }
  }

  @override
  void dispose() {
    stopLocationSharing();
    super.dispose();
  }
}
