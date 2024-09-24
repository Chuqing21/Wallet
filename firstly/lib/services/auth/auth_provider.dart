import 'auth_user.dart';

abstract class AuthProvider {
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<AuthUser> register({
    required String email,
    required String password,
  });

  //Future<void> sendEmailVerification();
  Future<void> logout();
  AuthUser? get currentUser;
  Future<void> initialize();
}
