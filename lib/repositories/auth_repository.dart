import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_riverpod_sample_app/general_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'custom_exception.dart';

abstract class BaseAuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> signInAnonymously();
  User? getCurrentUser();
  Future<void> signOut();
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read));

class AuthRepository implements BaseAuthRepository {
  final Reader _read;

  AuthRepository(this._read);

  @override
  Stream<User?> get authStateChanges => _read(firebaseAuthProvider).authStateChanges();

  @override
  Future<void> signInAnonymously() async {
    try {
      await _read(firebaseAuthProvider).signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

  @override
  User? getCurrentUser() {
    try {
      return _read(firebaseAuthProvider).currentUser;
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _read(firebaseAuthProvider).signOut();
      signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

}