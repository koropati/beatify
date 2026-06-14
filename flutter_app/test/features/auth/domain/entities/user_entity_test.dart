import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity.fromJson', () {
    test('maps all fields including profile_picture_url', () {
      final user = UserEntity.fromJson({
        'id': 7,
        'username': 'dewa',
        'email': 'dewa@test.com',
        'profile_picture_url': 'http://x/img.jpg',
        'role': 'admin',
        'is_verified': true,
      });

      expect(user.id, 7);
      expect(user.username, 'dewa');
      expect(user.email, 'dewa@test.com');
      expect(user.profilePictureUrl, 'http://x/img.jpg');
      expect(user.role, 'admin');
      expect(user.isVerified, true);
    });

    test('applies defaults when role and is_verified are missing', () {
      final user = UserEntity.fromJson({
        'id': 1,
        'username': 'u',
        'email': 'u@test.com',
      });

      expect(user.profilePictureUrl, isNull);
      expect(user.role, 'user');
      expect(user.isVerified, false);
    });
  });
}
