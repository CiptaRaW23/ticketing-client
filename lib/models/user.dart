class User {
  final int id;
  final String username;
  final String name;
  final String? address;
  final String role;
  final String status;
  final String? createdAt;
  final String? lastLoginAt;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.address,
    required this.role,
    required this.status,
    this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'customer',
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] as String?,
      lastLoginAt: json['lastLoginAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'address': address,
      'role': role,
      'status': status,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'admin';
}
