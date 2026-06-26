import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/products/product_model.dart';
import '../../features/auth/user_model.dart';
import '../services/api_service.dart';
import '../../features/products/category_model.dart';
import '../../features/feed/feed_post_model.dart';

enum AppMode { b2c, b2b }

class AppState extends ChangeNotifier {
  AppMode _currentMode = AppMode.b2c;
  bool _isLoggedIn = false;
  bool _isWaitingApproval = false;
  bool _isB2BVerified = false;
  double _minBillAmountB2C = 2000;
  
  List<Product> _wishlist = [];
  Map<String, int> _cart = {}; // ProductId -> Quantity
  List<Map<String, dynamic>> _history = [];
  List<Product> _products = [];
  List<CategoryItem> _categories = [];
  List<FeedPost> _feedPosts = [];
  List<Map<String, dynamic>> _deliverySlots = [];
  String? _token;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isFeedLoading = false;
  String? _currentTenant;
  String? _currentCity;
  List<Map<String, String>> _availableLocations = [];

  String? get currentTenant => _currentTenant;
  String? get currentCity => _currentCity;
  List<Map<String, String>> get availableLocations => _availableLocations;

  List<Product> get products => _products;
  List<Product> get newArrivals {
    final now = DateTime.now();
    return _products.where((p) {
      if (p.createdAt != null && now.difference(p.createdAt!).inDays <= 5) return true;
      if (p.updatedAt != null && now.difference(p.updatedAt!).inDays <= 5) return true;
      return false;
    }).toList();
  }

  List<CategoryItem> get categories => _categories;
  List<FeedPost> get feedPosts => _feedPosts;
  List<Map<String, dynamic>> get deliverySlots => _deliverySlots;
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _popupAds = [];
  List<Map<String, dynamic>> get banners => _banners;
  List<Map<String, dynamic>> get popupAds => _popupAds;

  bool _hasShownPopup = false;
  bool get hasShownPopup => _hasShownPopup;
  void markPopupAsShown() {
    _hasShownPopup = true;
    notifyListeners();
  }

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isFeedLoading => _isFeedLoading;


  AppMode get currentMode => _currentMode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isWaitingApproval => _isWaitingApproval;
  bool get isB2BVerified => _isB2BVerified;
  double get minBillAmountB2C => _minBillAmountB2C;
  List<Product> get wishlist => _wishlist;
  Map<String, int> get cart => _cart;
  List<Map<String, dynamic>> get history => _history;

  List<Map<String, dynamic>> _savedAddresses = [];
  List<Map<String, dynamic>> get savedAddresses => _savedAddresses;

  Future<void> fetchAddresses() async {
    if (_token == null) return;
    try {
      final List<dynamic> data = await ApiService.getAddresses(_token!);
      _savedAddresses = List<Map<String, dynamic>>.from(data);
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      print('Fetch addresses error: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) {
        logout();
      }
    }
  }

  Future<bool> addAddress(Map<String, dynamic> address) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.addAddress(_token!, address);
      _savedAddresses = List<Map<String, dynamic>>.from(data);
      _saveToPrefs();
      notifyListeners();
      return true;
    } catch (e) {
      print('CRITICAL: Add address error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    if (_token == null) return false;
    try {
      final List<dynamic> data = await ApiService.deleteAddress(_token!, addressId);
      _savedAddresses = List<Map<String, dynamic>>.from(data);
      _saveToPrefs();
      notifyListeners();
      return true;
    } catch (e) {
      print('Delete address error: $e');
      return false;
    }
  }


  AppState() {
    _loadFromPrefs();
  }

  Future<void> fetchBanners() async {
    try {
      if (_token != null) {
        final List<dynamic> data = await ApiService.getBanners(_token!);
        _banners = List<Map<String, dynamic>>.from(data);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching banners: $e');
    }
  }

  Future<void> fetchPopupAds() async {
    try {
      if (_token != null) {
        final List<dynamic> data = await ApiService.getPopupAds(_token!);
        _popupAds = List<Map<String, dynamic>>.from(data);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching popup ads: $e');
    }
  }

  Future<void> fetchFeedPosts() async {
    _isFeedLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getFeed();
      _feedPosts = data.map((json) => FeedPost.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching feed posts: $e');
    } finally {
      _isFeedLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final List<dynamic> data = await ApiService.getCategories();
      _categories = data.map((json) => CategoryItem.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await ApiService.getProducts();
      _products = data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.register(userData);
      if (response.containsKey('token')) {
        _isLoggedIn = true;
        _token = response['token'];
        _currentUser = UserModel.fromJson(response['user'] ?? response);
        _currentMode = _currentUser!.role == 'b2b' ? AppMode.b2b : AppMode.b2c;
        // MOQ enforcement removed — minimum bill amount checked at checkout
        _isWaitingApproval = _currentUser!.isWaitingApproval;
        _isB2BVerified = _currentUser!.isVerified;
        _saveToPrefs();
        registerFcmTokenProperly();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      print('Attempting login for: $email');
      final response = await ApiService.login(email, password);
      print('Login response: $response');
      
      if (response.containsKey('token')) {
        _isLoggedIn = true;
        _token = response['token'];
        _currentUser = UserModel.fromJson(response['user'] ?? response);
        _currentMode = _currentUser!.role == 'b2b' ? AppMode.b2b : AppMode.b2c;
        // MOQ enforcement removed — minimum bill amount checked at checkout
        _isWaitingApproval = _currentUser!.isWaitingApproval;
        _isB2BVerified = _currentUser!.isVerified;
        print('Login Success: User Role: ${_currentUser!.role}, Verified: $_isB2BVerified');
        _saveToPrefs();
        registerFcmTokenProperly();
        notifyListeners();
        return true;
      }
      print('Login Failed: No token in response');
      return false;
    } catch (e) {
      print('Login Exception: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>?> signInWithGoogle(String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await ApiService.googleLogin({
        'email': googleUser.email,
        'name': googleUser.displayName,
        'role': role,
      });

      if (response.containsKey('newUser')) {
        return response; // Contains {newUser: true, email, name}
      }

      if (response.containsKey('token')) {
        _isLoggedIn = true;
        _token = response['token'];
        _currentUser = UserModel.fromJson(response['user'] ?? response);
        _currentMode = _currentUser!.role == 'b2b' ? AppMode.b2b : AppMode.b2c;
        _isWaitingApproval = _currentUser!.isWaitingApproval;
        _isB2BVerified = _currentUser!.isVerified;
        _saveToPrefs();
        registerFcmTokenProperly();
        notifyListeners();
        return response;
      }
      return null;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await ApiService.getProfile(_token!);
      _currentUser = UserModel.fromJson(response['user'] ?? response);
      _currentMode = _currentUser!.role == 'b2b' ? AppMode.b2b : AppMode.b2c;
      _isWaitingApproval = _currentUser!.isWaitingApproval;
      _isB2BVerified = _currentUser!.isVerified;
      notifyListeners();
    } catch (e) {
      print('Fetch profile error: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) {
        logout();
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.updateProfile(_token!, data);
      _currentUser = UserModel.fromJson(response['user'] ?? response);
      notifyListeners();
    } catch (e) {
      print('Update profile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  Future<bool> fetchTenantByPincode(String pincode) async {
    print('AppState: Fetching tenant for pincode: $pincode');
    try {
      final data = await ApiService.findTenantByPincode(pincode);
      print('AppState: Tenant found: ${data['dbName']} (${data['city']})');
      _currentTenant = data['dbName'];
      _currentCity = data['city'];
      ApiService.tenantId = _currentTenant;
      _saveToPrefs();
      notifyListeners();
      // Refresh data for new tenant
      fetchProducts();
      fetchCategories();
      fetchFeedPosts();
      fetchProducts();
      fetchDeliverySlots();
      fetchPopupAds();
      fetchMinimumBilling();
      return true;
    } catch (e) {
      print('AppState: Error fetching tenant by pincode: $e');
      _currentTenant = null;
      _currentCity = null;
      ApiService.tenantId = null;
      _saveToPrefs();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAvailableLocations() async {
    try {
      final List<dynamic> data = await ApiService.getAvailableLocations();
      _availableLocations = data.map((item) => {
        'city': item['city'].toString(),
        'dbName': item['dbName'].toString(),
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching available locations: $e');
    }
  }

  void setTenant(String dbName, String city) {
    _currentTenant = dbName;
    _currentCity = city;
    ApiService.tenantId = dbName;
    _saveToPrefs();
    notifyListeners();
    // Refresh data for new tenant
    fetchProducts();
    fetchCategories();
    fetchFeedPosts();
    fetchMinimumBilling();
  }

  Future<void> reportUnservedLocation(String pincode, {String? email, String? phone}) async {
    try {
      await ApiService.reportUnservedLocation(pincode, email: email, phone: phone);
    } catch (e) {
      print('Error reporting unserved location: $e');
    }
  }

  Future<void> fetchMinimumBilling() async {
    if (_currentTenant == null) return;
    try {
      final data = await ApiService.getMinimumBilling();
      _minBillAmountB2C = (data['minimumBillAmountB2C'] ?? 2000).toDouble();
      notifyListeners();
    } catch (e) {
      print('Error fetching minimum billing: $e');
    }
  }

  void logout() {
    _isLoggedIn = false;
    _isWaitingApproval = false;
    _isB2BVerified = false;
    _currentMode = AppMode.b2c;
    _token = null;
    _currentUser = null;
    _saveToPrefs();
    notifyListeners();
  }

  void startB2BOnboarding() {
    _isLoggedIn = true;
    _currentMode = AppMode.b2b;
    _isWaitingApproval = true;
    _saveToPrefs();
    notifyListeners();
  }

  void setMode(AppMode mode) {
    _currentMode = mode;
    // MOQ enforcement removed — minimum bill amount checked at checkout
    _saveToPrefs();
    notifyListeners();
  }

  // _enforceMOQ removed — replaced by minimum bill amount check at checkout



  void verifyB2B() {
    _isWaitingApproval = false;
    _isB2BVerified = true;
    _saveToPrefs();
    notifyListeners();
  }

  void bypassApproval() {
    _isWaitingApproval = false;
    _isB2BVerified = true;
    _saveToPrefs();
    notifyListeners();
  }

  // Wishlist Logic
  void toggleWishlist(Product product) {
    if (_wishlist.any((p) => p.id == product.id)) {
      _wishlist.removeWhere((p) => p.id == product.id);
    } else {
      _wishlist.add(product);
    }
    _saveToPrefs();
    notifyListeners();
  }

  bool isInWishlist(String productId) => _wishlist.any((p) => p.id == productId);

  // Cart Logic
  void addToCart(String productId) {
    // productId is actually cartKey which can be 'id_variant'
    final parts = productId.split('_');
    final id = parts[0];
    final variant = parts.length > 1 ? parts[1] : null;
    
    // Find product stock
    try {
      final product = _products.firstWhere((p) => p.id == id);
      int maxStock = product.stock;
      if (variant != null && product.variants.isNotEmpty) {
        maxStock = product.variants.firstWhere((v) => v.sizeName == variant).stock;
      }
      
      int currentQty = _cart[productId] ?? 0;
      if (currentQty < maxStock) {
        _cart[productId] = currentQty + 1;
        _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      // If product not found, just add
      _cart[productId] = (_cart[productId] ?? 0) + 1;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    if (_cart.containsKey(productId)) {
      if (_cart[productId]! > 1) {
        _cart[productId] = _cart[productId]! - 1;
      } else {
        _cart.remove(productId);
      }
    }
    _saveToPrefs();
    notifyListeners();
  }

  void deleteFromCart(String productId) {
    _cart.remove(productId);
    _saveToPrefs();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _saveToPrefs();
    notifyListeners();
  }

  double get cartTotal {
    double total = 0;
    final bool isB2B = _currentMode == AppMode.b2b;
    _cart.forEach((key, qty) {
      try {
        final parts = key.split('_');
        final id = parts[0];
        final variant = parts.length > 1 ? parts[1] : null;
        final product = products.firstWhere((p) => p.id == id);
        final price = product.getPriceForQuantity(qty, isB2B, variant);
        total += price * qty;
      } catch (e) {}
    });
    return total;
  }

  // Order History Logic
  Future<void> fetchOrders() async {
    if (_token == null) return;
    try {
      final List<dynamic> data = await ApiService.getMyOrders(_token!);
      _history = List<Map<String, dynamic>>.from(data);
      _saveToPrefs();
      notifyListeners();
    } catch (e) {
      print('Fetch orders error: $e');
      if (e.toString().contains('Not authorized') || e.toString().contains('Session expired')) {
        logout();
      }
    }
  }

  Future<bool> returnOrderItem({required String orderId, required String itemId, required String reason, String? comment, File? imageFile}) async {
    if (_token == null) return false;
    _isLoading = true; notifyListeners();
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ApiService.uploadFile(imageFile);
      }
      final success = await ApiService.returnOrderItem(_token!, orderId, itemId, reason, comment: comment, imageUrl: imageUrl);
      if (success) {
        await fetchOrders();
      }
      return success;
    } catch (e) {
      print('Return order item error: $e');
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> placeOrder(Map<String, dynamic> shippingAddress, String paymentMethod, [String? deliverySlot]) async {
    if (_cart.isEmpty || _token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> items = [];
      final bool isB2B = _currentMode == AppMode.b2b;
      _cart.forEach((key, qty) {
        final parts = key.split('_');
        final id = parts[0];
        final variant = parts.length > 1 ? parts[1] : null;
        final product = products.firstWhere((p) => p.id == id);
        final price = product.getPriceForQuantity(qty, isB2B, variant);
        items.add({
          'productId': id,
          'product': id,
          'variantSize': variant,
          'name': variant != null ? '${product.name} - $variant' : product.name,
          'quantity': qty,
          'price': price,
          'image': product.imageUrl
        });
      });

      final orderData = {
        'items': items,
        'totalAmount': cartTotal,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'orderStatus': 'Pending',
        'paymentStatus': 'Pending',
        if (deliverySlot != null) 'deliverySlot': deliverySlot,
      };

      await ApiService.placeOrder(_token!, orderData);
      clearCart();
      await fetchOrders();
      return true;
    } catch (e) {
      print('Place order error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> returnOrder({
    required String orderId,
    required String reason,
    required String comment,
    File? imageFile,
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ApiService.uploadFile(imageFile);
      }

      await ApiService.updateOrderStatus(_token!, orderId, {
        'status': 'Returned',
        'returnReason': reason,
        'returnComment': comment,
        'returnImage': imageUrl,
      });

      await fetchOrders();
      return true;
    } catch (e) {
      print('Return order error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? getFirstProductInCart() {
    if (_cart.isEmpty) return null;
    final firstKey = _cart.keys.first;
    final firstId = firstKey.split('_').first;
    for (var p in _products) {
      if (p.id == firstId) {
        return p.name;
      }
    }
    return null;
  }

  String? _activeFcmToken;
  String? get activeFcmToken => _activeFcmToken;

  Future<void> registerFcmTokenProperly() async {
    if (_token == null || _currentUser == null) return;
    
    String? fcmToken;
    try {
      print('FCM: Requesting notification permission...');
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('FCM: Permission Status: ${settings.authorizationStatus}');
      
      fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM: Real token fetched: $fcmToken');
    } catch (e) {
      print('FCM: Failed to get real token ($e). Falling back to mock token.');
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      fcmToken = "mock-fcm-token-${_currentUser!.role}-${_currentUser!.email}";
    }

    print('FCM: Registering token on server: $fcmToken');
    _activeFcmToken = fcmToken;
    await ApiService.registerFcmToken(_token!, fcmToken);
  }

  // Persistence
  Future<void> _loadFromPrefs() async {
    print('Loading state from prefs...');
    final prefs = await SharedPreferences.getInstance();
    
    // Load Wishlist
    final wishlistData = prefs.getString('wishlist');
    if (wishlistData != null) {
      // Wishlist items will be matched after products are fetched or during display
      _wishlist = []; 
    }

    // Load Cart
    final cartData = prefs.getString('cart');
    if (cartData != null) {
      _cart = Map<String, int>.from(jsonDecode(cartData));
    }

    // Load History
    final historyData = prefs.getString('history');
    if (historyData != null) {
      _history = List<Map<String, dynamic>>.from(jsonDecode(historyData));
    }



    // Load Persistence
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _isWaitingApproval = prefs.getBool('isWaitingApproval') ?? false;
    _isB2BVerified = prefs.getBool('isB2BVerified') ?? false;
    _token = prefs.getString('token');
    
    final modeStr = prefs.getString('currentMode');
    if (modeStr != null) {
      _currentMode = AppMode.values.firstWhere((e) => e.name == modeStr, orElse: () => AppMode.b2c);
    }

    final userStr = prefs.getString('user');
    if (userStr != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userStr));
    }

    _currentTenant = prefs.getString('currentTenant');
    if (_currentTenant != null && _currentTenant!.isEmpty) _currentTenant = null;
    _currentCity = prefs.getString('currentCity');
    if (_currentCity != null && _currentCity!.isEmpty) _currentCity = null;

    ApiService.tenantId = _currentTenant;

    print('State loaded: isLoggedIn=$_isLoggedIn, user=${_currentUser?.email}, mode=$_currentMode, tenant=$_currentTenant');

    // Fetch data that needs tenant context
    fetchProducts();
    fetchCategories();
    fetchFeedPosts();
    
    if (_isLoggedIn && _token != null) {
      fetchOrders();
      fetchAddresses();
      registerFcmTokenProperly();
      fetchBanners();
      fetchPopupAds();
      fetchDeliverySlots();
      fetchMinimumBilling();
    }
    
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    print('Saving state to prefs: isLoggedIn=$_isLoggedIn, mode=$_currentMode');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setBool('isWaitingApproval', _isWaitingApproval);
    await prefs.setBool('isB2BVerified', _isB2BVerified);
    await prefs.setString('currentMode', _currentMode.name);
    await prefs.setString('token', _token ?? '');
    
    if (_currentUser != null) {
      await prefs.setString('user', jsonEncode({
        '_id': _currentUser!.id,
        'name': _currentUser!.name,
        'email': _currentUser!.email,
        'role': _currentUser!.role,
        'isVerified': _isB2BVerified,
        'isWaitingApproval': _isWaitingApproval,
      }));
    }

    await prefs.setString('currentTenant', _currentTenant ?? '');
    await prefs.setString('currentCity', _currentCity ?? '');
    await prefs.setString('wishlist', jsonEncode(_wishlist.map((p) => p.id).toList()));
    await prefs.setString('cart', jsonEncode(_cart));
    await prefs.setString('history', jsonEncode(_history));
  }
}
