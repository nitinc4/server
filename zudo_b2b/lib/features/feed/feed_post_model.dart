class FeedPost {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final String? imageUrl;
  final int? discountPercent;
  final String? offerCode;
  final DateTime createdAt;

  FeedPost({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    this.imageUrl,
    this.discountPercent,
    this.offerCode,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    String sName = 'Zudo Official';
    String sId = '';
    if (json['sellerId'] != null) {
      if (json['sellerId'] is Map) {
        sName = json['sellerId']['businessName'] ?? json['sellerId']['name'] ?? 'Zudo Official';
        sId = json['sellerId']['_id']?.toString() ?? json['sellerId']['id']?.toString() ?? '';
      } else {
        sId = json['sellerId'].toString();
      }
    }
    return FeedPost(
      id: json['_id'] ?? '',
      sellerId: sId,
      sellerName: sName,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      discountPercent: json['discountPercent'],
      offerCode: json['offerCode'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
