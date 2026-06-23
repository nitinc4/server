import '../../core/constants/api_constants.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final List<OrderItem> items;
  final Map<String, dynamic> shippingAddress;
  final String paymentMethod;
  final String? pickupCode;
  final List<SellerPickup>? sellerPickups;
  final String? deliveryOtp;
  final String paymentStatus;
  final String? paymentScreenshot;
  final DateTime? paidAt;
  final DateTime createdAt;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? cashCollector;
  final Map<String, dynamic>? deliverySlot;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    this.pickupCode,
    this.sellerPickups,
    this.deliveryOtp,
    required this.paymentStatus,
    this.paymentScreenshot,
    this.paidAt,
    required this.createdAt,
    this.driver,
    this.cashCollector,
    this.deliverySlot,
    this.isReturn = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB Extended JSON format for _id
    String id = '';
    if (json['_id'] is Map) {
      id = json['_id']['\$oid'] ?? '';
    } else {
      id = json['_id'] ?? json['id'] ?? '';
    }

    // Handle MongoDB Extended JSON format for createdAt
    DateTime createdAt;
    if (json['createdAt'] is Map) {
      createdAt = DateTime.parse(json['createdAt']['\$date'] ?? DateTime.now().toIso8601String());
    } else {
      createdAt = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    }

    return OrderModel(
      id: id,
      orderNumber: json['orderNumber'] ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      status: json['orderStatus'] ?? json['status'] ?? 'Pending',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      items: (json['items'] as List? ?? []).map((i) => OrderItem.fromJson(i)).toList(),
      shippingAddress: json['shippingAddress'] ?? {},
      paymentMethod: json['paymentMethod'] ?? 'COD',
      pickupCode: json['pickupCode']?.toString(),
      sellerPickups: (json['sellerPickups'] as List? ?? [])
          .map((i) => SellerPickup.fromJson(i))
          .toList(),
      deliveryOtp: json['deliveryOtp']?.toString(),
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      paymentScreenshot: json['paymentScreenshot'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: createdAt,
      driver: json['driverId'] is Map ? json['driverId'] : null,
      cashCollector: json['cashPersonId'] is Map ? json['cashPersonId'] : null,
      deliverySlot: json['deliverySlot'] is Map ? json['deliverySlot'] : null,
      isReturn: json['isReturn'] ?? false,
    );
  }

  final bool isReturn;

  String get customerName => shippingAddress['name'] ?? 'Unknown';
  String get fullAddress => 
      "${shippingAddress['address'] ?? ''}, ${shippingAddress['city'] ?? ''}, ${shippingAddress['state'] ?? ''} - ${shippingAddress['pincode'] ?? ''}";
  String get customerPhone => shippingAddress['phone'] ?? 'N/A';
  double get lat => (shippingAddress['lat'] ?? 0).toDouble();
  double get lng => (shippingAddress['lng'] ?? 0).toDouble();

  List<SellerInfo> get uniqueSellers {
    final sellers = <String, SellerInfo>{};
    for (var item in items) {
      if (item.sellerId != null) {
        if (!sellers.containsKey(item.sellerId)) {
          sellers[item.sellerId!] = SellerInfo(
            id: item.sellerId!,
            name: item.sellerName ?? 'Unknown Seller',
            phone: item.sellerPhone,
            address: item.sellerAddress ?? 'No Address',
            lat: item.sellerLat,
            lng: item.sellerLng,
          );
        }
      }
    }

    if (sellers.isEmpty && items.isNotEmpty) {
      // Fallback for legacy orders that don't have seller snapshots
      return [SellerInfo(
        id: 'legacy_pickup',
        name: 'Zudo Seller',
        address: 'Pickup Location (Default Hub)',
        lat: pickupLat,
        lng: pickupLng,
      )];
    }

    return sellers.values.toList();
  }

  Map<String, List<OrderItem>> get itemsBySeller {
    final map = <String, List<OrderItem>>{};
    for (var item in items) {
      final sellerId = item.sellerId ?? 'unknown';
      if (!map.containsKey(sellerId)) map[sellerId] = [];
      map[sellerId]!.add(item);
    }
    return map;
  }

  double get pickupLat {
    for (var item in items) {
      if (item.sellerLat != null) return item.sellerLat!;
    }
    return 12.916285889042973; // Default location
  }

  double get pickupLng {
    for (var item in items) {
      if (item.sellerLng != null) return item.sellerLng!;
    }
    return 77.61023139447778; // Default location
  }

  SellerPickup? getSellerPickup(String sellerId) {
    if (sellerPickups == null || sellerPickups!.isEmpty) return null;
    try {
      return sellerPickups!.firstWhere((sp) => sp.sellerId == sellerId);
    } catch (_) {
      return null;
    }
  }
}

class SellerPickup {
  final String sellerId;
  final String status;
  final String? pickupCode;

  SellerPickup({
    required this.sellerId,
    required this.status,
    this.pickupCode,
  });

  factory SellerPickup.fromJson(Map<String, dynamic> json) {
    String sId = '';
    if (json['sellerId'] is Map) {
      sId = json['sellerId']['\$oid'] ?? '';
    } else {
      sId = json['sellerId']?.toString() ?? '';
    }
    return SellerPickup(
      sellerId: sId,
      status: json['status']?.toString() ?? 'Pending',
      pickupCode: json['pickupCode']?.toString(),
    );
  }
}

class SellerInfo {
  final String id;
  final String name;
  final String? phone;
  final String address;
  final double? lat;
  final double? lng;

  SellerInfo({
    required this.id,
    required this.name,
    this.phone,
    required this.address,
    this.lat,
    this.lng,
  });
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? image;
  final String? sellerId;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final double? sellerLat;
  final double? sellerLng;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.image,
    this.sellerId,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.sellerLat,
    this.sellerLng,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String productId = '';
    if (json['productId'] is Map) {
      productId = json['productId']['\$oid'] ?? '';
    } else {
      productId = json['productId'] ?? '';
    }

    final seller = json['seller'];
    String? sId;
    if (seller != null && seller['sellerId'] != null) {
      if (seller['sellerId'] is Map) {
        sId = seller['sellerId']['\$oid'];
      } else {
        sId = seller['sellerId'].toString();
      }
    }

    return OrderItem(
      productId: productId,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      image: ApiConstants.getFullImageUrl(json['image']),
      sellerId: sId,
      sellerName: seller?['name'],
      sellerPhone: seller?['phone'],
      sellerAddress: seller?['address'],
      sellerLat: seller != null ? (seller['lat'] ?? 0).toDouble() : null,
      sellerLng: seller != null ? (seller['lng'] ?? 0).toDouble() : null,
    );
  }
}
