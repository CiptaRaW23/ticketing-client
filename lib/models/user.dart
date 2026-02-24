class User {
  final int id;
  final String username;
  final String name;
  final String? address;
  final String role;
  final String status;
  final String? createdAt;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.address,
    required this.role,
    required this.status,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      address: json['address'],
      role: json['role'],
      status: json['status'],
      createdAt: json['createdAt'],
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
    };
  }
}
