enum UserRole {
  student,
  teacher,
  librarian,
}

class User {
  final int? id;
  final String username;
  final String? password; // null for students/teachers
  final UserRole role;
  final String? email;
  final String? phone;

  User({
    this.id,
    required this.username,
    this.password,
    required this.role,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role.name,
      'email': email,
      'phone': phone,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      email: map['email'] as String?,
      phone: map['phone'] as String?,
    );
  }
}

