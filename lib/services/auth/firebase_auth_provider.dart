import 'package:firebase_core/firebase_core.dart';
import 'package:learningdart/firebase_options.dart';
import 'package:learningdart/services/auth/auth_user.dart';
import 'package:learningdart/services/auth/auth_provider.dart';
import 'package:learningdart/services/auth/auth_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, FirebaseAuthException, User;

class FirebaseAuthProvider implements AuthProvider {
  
  // ADD THIS: Auth state changes stream implementation
  @override
  Stream<AuthUser?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges().map((User? user) {
      return user != null ? AuthUser.fromFirebase(user) : null;
    });
  }

  @override
  Future<AuthUser> createUser({required String email, required String password}) async {
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      final user=currentUser;
      if(user!=null){
        return user;
      }else{
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch(e){
      if (e.code == "weak-password") {
        throw WeakPasswordAuthException();
      } else if(e.code == "email-already-in-use"){
        throw EmailAlreadyInUseAuthException();
      } else if(e.code=="invalid-email"){
        throw InvalidCredentialsAuthException();
      }else{
        throw GenericAuthException();
      }
    } catch(_){
      throw GenericAuthException();
    }
  }

  @override
  AuthUser? get currentUser{
    final user=FirebaseAuth.instance.currentUser;
    if(user !=null){
      return AuthUser.fromFirebase(user);
    }else{
      return null;
    }
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) async {
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      final user=currentUser;
      if(user!=null){
        return user;
      }else{
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch(e){
      if (e.code == "invalid-credential") {
        throw InvalidCredentialsAuthException();
      } else{
        throw GenericAuthException();
      }
    } catch(_){
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logout() async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      await FirebaseAuth.instance.signOut();
    }else{
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<void> sendEmailNotification() async {
    final user=FirebaseAuth.instance.currentUser;
    if(user!=null){
      await user.sendEmailVerification();
    }else{
      throw UserNotFoundAuthException();
    }
  }
  
  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}
