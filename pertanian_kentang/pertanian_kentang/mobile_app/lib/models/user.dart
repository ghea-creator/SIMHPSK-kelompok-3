class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? farmName;
  final String role;
  final String status;
  final String approval;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.farmName,
    required this.role,
    required this.status,
    required this.approval,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      farmName: json['farm_name'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      approval: json['approval'] as String? ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'farm_name': farmName,
      'role': role,
      'status': status,
      'approval': approval,
    };
  }
}
