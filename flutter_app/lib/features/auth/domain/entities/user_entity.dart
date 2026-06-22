class UserEntity {
  final int id;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final String role;
  final bool isVerified;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureUrl,
    required this.role,
    required this.isVerified,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profilePictureUrl: json['profile_picture_url'],
      role: json['role'] ?? 'user',
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'profile_picture_url': profilePictureUrl,
        'role': role,
        'is_verified': isVerified,
      };
}
