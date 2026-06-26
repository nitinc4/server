class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profilePicture;
  final String? type;
  final bool isVerified;
  final double wallet;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profilePicture,
    this.type,
    required this.isVerified,
    required this.wallet,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'driver',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      type: json['type'],
      isVerified: json['isVerified'] ?? false,
      wallet: (json['wallet'] ?? 0).toDouble(),
    );
  }
}
