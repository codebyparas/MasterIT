import 'package:learningdart/services/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get currentUser;

  // ADD THIS: Auth state changes stream
  Stream<AuthUser?> get authStateChanges;

  Future<void> initialize();
  
  Future<AuthUser> logIn({
    required String email,
    required String password,
  });

  Future<AuthUser> createUser({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> sendEmailNotification();
}
