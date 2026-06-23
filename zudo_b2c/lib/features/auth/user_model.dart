class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profilePicture;
  final String? businessName;
  final String? businessAddress;
  final String? gstNumber;
  final bool isVerified;
  final bool isWaitingApproval;
  final Map<String, dynamic>? bankDetails;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profilePicture,
    this.businessName,
    this.businessAddress,
    this.gstNumber,
    required this.isVerified,
    required this.isWaitingApproval,
    this.bankDetails,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'b2c',
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      businessName: json['businessName'],
      businessAddress: json['businessAddress'],
      gstNumber: json['gstNumber'],
      isVerified: json['isVerified'] ?? false,
      isWaitingApproval: json['isWaitingApproval'] ?? false,
      bankDetails: json['bankDetails'] as Map<String, dynamic>?,
    );
  }
}
