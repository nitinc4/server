import '../../core/constants/api_constants.dart';

class CategoryItem {
  final String id;
  final String name;
  final String imageUrl;
  final List<SubCategoryItem> subCategories;

  CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subCategories,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: ApiConstants.getFullImageUrl(json['imageUrl'] ?? ''),
      subCategories: (json['subCategories'] as List? ?? [])
          .map((s) => SubCategoryItem.fromJson(s))
          .toList(),
    );
  }
}

class SubCategoryItem {
  final String id;
  final String name;
  final String imageUrl;

  SubCategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory SubCategoryItem.fromJson(Map<String, dynamic> json) {
    return SubCategoryItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: ApiConstants.getFullImageUrl(json['imageUrl'] ?? ''),
    );
  }
}
