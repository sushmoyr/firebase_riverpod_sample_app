import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_riverpod_sample_app/repositories/auth_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authControllerProvider = StateNotifierProvider<AuthController, User?>(
    (ref) => AuthController(ref.read)..appStarted());

class AuthController extends StateNotifier<User?> {
  final Reader _reader;

  AuthController(this._reader) : super(null) {
    _authStateChangesSubscription?.cancel();
    _authStateChangesSubscription = _reader(authRepositoryProvider)
        .authStateChanges
        .listen((event) => state = event);
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }

  StreamSubscription<User?>? _authStateChangesSubscription;

  void appStarted() async {
    final user = _reader(authRepositoryProvider).getCurrentUser();

    if (user == null) {
      await _reader(authRepositoryProvider).signInAnonymously();
    }
  }

  void signOut() async {
    await _reader(authRepositoryProvider).signOut();
  }
}
