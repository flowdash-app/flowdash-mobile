import 'package:flowdash_mobile/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  Future<String?> getAuthToken();
}
