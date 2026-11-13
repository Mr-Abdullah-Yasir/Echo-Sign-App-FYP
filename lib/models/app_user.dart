class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      passwordSalt: map['password_salt'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
