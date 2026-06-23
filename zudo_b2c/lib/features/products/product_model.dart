import '../../core/constants/api_constants.dart';

class PriceTier {
  final int minQty;
  final double price;

  PriceTier({required this.minQty, required this.price});

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      minQty: json['minQty'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class ProductVariant {
  final String sizeName;
  final double mrp;
  final double price;
  final int stock;
  final List<PriceTier> priceTiers;

  ProductVariant({
    required this.sizeName,
    required this.mrp,
    required this.price,
    required this.stock,
    required this.priceTiers,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    var tiersList = json['priceTiers'] as List? ?? [];
    List<PriceTier> tiers = tiersList.map((t) => PriceTier.fromJson(t)).toList();
    double parsedPrice = double.tryParse(json['price']?.toString() ?? '') ?? (json['price'] is num ? (json['price'] as num).toDouble() : 0.0);
    double parsedMrp = double.tryParse(json['mrp']?.toString() ?? '') ?? (json['mrp'] is num ? (json['mrp'] as num).toDouble() : parsedPrice);
    
    return ProductVariant(
      sizeName: json['sizeName']?.toString() ?? json['packetSize']?.toString() ?? json['size']?.toString() ?? json['name']?.toString() ?? '',
      mrp: parsedMrp,
      price: parsedPrice,
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? (json['stock'] is num ? (json['stock'] as num).toInt() : 0),
      priceTiers: tiers,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final double price;
  final double b2bPrice;
  final int moq;
  final String unit;
  final String imageUrl;
  final double rating;
  final String? sellerName;
  final String? sellerId;
  final List<PriceTier> priceTiers;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.b2bPrice,
    required this.moq,
    required this.unit,
    required this.imageUrl,
    required this.rating,
    this.sellerName,
    this.sellerId,
    this.priceTiers = const [],
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
    this.stock = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['image'] ?? json['imageUrl'] ?? '';
    String? sName;
    String? sId;
    if (json['sellerId'] != null) {
      if (json['sellerId'] is Map) {
        sName = json['sellerId']['businessName'] ?? json['sellerId']['name'];
        sId = json['sellerId']['_id']?.toString() ?? json['sellerId']['id']?.toString();
      } else {
        sId = json['sellerId'].toString();
      }
    }

    var tiersList = json['priceTiers'] as List? ?? [];
    List<PriceTier> tiers = tiersList.map((t) => PriceTier.fromJson(t)).toList();
    
    var variantsList = json['variants'] as List?;
    if (variantsList == null || variantsList.isEmpty) {
      variantsList = json['b2c'] as List? ?? json['b2b'] as List? ?? [];
    }
    List<ProductVariant> parsedVariants = variantsList.map((v) => ProductVariant.fromJson(v)).toList();

    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is String) return DateTime.tryParse(date);
      if (date is Map && date['\$date'] != null) return DateTime.tryParse(date['\$date']);
      return null;
    }

    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['categoryId']?['name'] ?? 'General',
      subCategory: json['subCategoryId']?['name'] ?? '',
      price: (json['price'] ?? 0).toDouble() > 0 ? (json['price'] ?? 0).toDouble() : (parsedVariants.isNotEmpty ? parsedVariants.first.price : 0.0),
      b2bPrice: (json['b2bPrice'] ?? 0).toDouble() > 0 ? (json['b2bPrice'] ?? 0).toDouble() : (parsedVariants.isNotEmpty ? parsedVariants.first.price : 0.0),
      moq: json['moq'] ?? 1,
      unit: json['unit'] ?? 'pcs',
      imageUrl: ApiConstants.getFullImageUrl(imageUrl),
      rating: (json['rating'] ?? 0).toDouble(),
      sellerName: sName ?? json['sellerName'],
      sellerId: sId,
      priceTiers: tiers,
      variants: parsedVariants,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      stock: ((json['stock'] is num) ? (json['stock'] as num).toInt() : (int.tryParse(json['stock']?.toString() ?? '') ?? 0)) > 0 ? ((json['stock'] is num) ? (json['stock'] as num).toInt() : (int.tryParse(json['stock']?.toString() ?? '') ?? 0)) : (parsedVariants.isNotEmpty ? parsedVariants.first.stock : 0),
    );
  }
  
  double getPriceForQuantity(int quantity, bool isB2B, [String? variantSize]) {
    double basePrice = price;
    double baseB2BPrice = b2bPrice;
    List<PriceTier> activeTiers = priceTiers;

    if (variantSize != null && variants.isNotEmpty) {
      final variant = variants.firstWhere((v) => v.sizeName == variantSize, orElse: () => variants.first);
      basePrice = variant.price;
      baseB2BPrice = variant.price;
      activeTiers = variant.priceTiers;
    }

    if (!isB2B) return basePrice;
    
    if (activeTiers.isEmpty) return baseB2BPrice;
    
    // Sort tiers by minQty descending
    final sortedTiers = List<PriceTier>.from(activeTiers);
    sortedTiers.sort((a, b) => b.minQty.compareTo(a.minQty));
    
    for (var tier in sortedTiers) {
      if (quantity >= tier.minQty) {
        return tier.price;
      }
    }
    
    return baseB2BPrice;
  }

  double getMrp([String? variantSize]) {
    if (variantSize != null && variants.isNotEmpty) {
      final variant = variants.firstWhere((v) => v.sizeName == variantSize, orElse: () => variants.first);
      return variant.mrp > 0 ? variant.mrp : variant.price;
    }
    return price;
  }

  String getNormalizedPriceString(double currentPrice, String? variantSize) {
    if (variantSize == null || variantSize.isEmpty) return '';
    final size = variantSize.toLowerCase().replaceAll(' ', '');
    double factor = 1.0;
    String baseUnit = unit.toLowerCase() == 'ml' || unit.toLowerCase() == 'ltr' || unit.toLowerCase() == 'l' ? 'Ltr' : 'kg';
    
    final RegExp regex = RegExp(r'([\d.]+)([a-zA-Z]+)');
    final match = regex.firstMatch(size);
    if (match != null) {
      double value = double.tryParse(match.group(1)!) ?? 1.0;
      String currentUnit = match.group(2)!;
      
      if (currentUnit == 'g' || currentUnit == 'gm' || currentUnit == 'gms') {
        factor = 1000 / value;
        baseUnit = 'kg';
      } else if (currentUnit == 'kg' || currentUnit == 'kgs') {
        factor = 1 / value;
        baseUnit = 'kg';
      } else if (currentUnit == 'ml') {
        factor = 1000 / value;
        baseUnit = 'Ltr';
      } else if (currentUnit == 'l' || currentUnit == 'ltr' || currentUnit == 'ltrs') {
        factor = 1 / value;
        baseUnit = 'Ltr';
      }
    }
    if (factor == 1.0) return ''; // No need to show if it's already 1kg/1ltr
    
    double normalizedPrice = currentPrice * factor;
    return '(₹${normalizedPrice.toStringAsFixed(0)} / $baseUnit)';
  }
}

// Mock data removed. Products are fetched from DB.

