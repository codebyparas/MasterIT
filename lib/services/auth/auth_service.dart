import 'package:learningdart/services/auth/auth_user.dart';
import 'package:learningdart/services/auth/auth_provider.dart';
import 'package:learningdart/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider{
  final AuthProvider provider;
  AuthService(this.provider);
  factory AuthService.firebase()=>AuthService(FirebaseAuthProvider());
  
  // ADD THIS: Auth state changes stream delegation
  @override
  Stream<AuthUser?> get authStateChanges => provider.authStateChanges;
  
  @override
  Future<AuthUser> createUser({required String email, required String password}) => provider.createUser(email: email, password: password);
  
  @override
  AuthUser? get currentUser => provider.currentUser;
  
  @override
  Future<AuthUser> logIn({required String email, required String password}) => provider.logIn(email: email, password: password);
  
  @override
  Future<void> logout() => provider.logout();
  
  @override
  Future<void> sendEmailNotification() => provider.sendEmailNotification();
  
  @override
  Future<void> initialize() => provider.initialize();
}
