import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sharoni/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final currentUser = _repository.currentUser;
    state = AsyncValue.data(currentUser);

    _repository.authStateChanges.listen((data) {
      state = AsyncValue.data(data.session?.user);
    });
  }

  Future<void> signUp(String email, String password, String username) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.signUp(email: email, password: password, username: username);
    } catch (e) {
      state = previousState; // Revert to previous state so UI doesn't blow up
      rethrow; // Rethrow so LoginPage can show SnackBar
    }
  }

  Future<void> signIn(String email, String password) async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      await _repository.signIn(email: email, password: password);
    } catch (e) {
      state = previousState; // Revert to previous state
      rethrow; // Rethrow so LoginPage can show SnackBar
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _repository.resetPassword(email);
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
