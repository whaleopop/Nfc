/// User model
class User {
  final String id;  // UUID from backend
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phone;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      phone: json['phone'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'phone': phone,
      'role': role,
    };
  }

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    return parts;
  }
}
