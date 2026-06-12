import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final SecureStorageService _storage;
  final Completer<void> _initCompleter = Completer();

  Future<void> get initFuture => _initCompleter.future;

  AuthNotifier(this._authService, this._storage)
      : super(const AuthInitializing()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true) ?? '';
        await _storage.saveToken(token);
        state = AuthAuthenticated(user: user, token: token);
      } else {
        await _storage.deleteToken();
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    final credential =
        await _authService.signInWithEmailPassword(email, password);
    final user = credential.user!;
    final token = await user.getIdToken() ?? '';
    await _storage.saveToken(token);
    state = AuthAuthenticated(user: user, token: token);
  }

  Future<bool> signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    if (result == null) return false;
    final user = result.credential.user!;
    final token = await user.getIdToken() ?? '';

    debugPrint('══════════════════════════════════════════');
    debugPrint('[Auth] Firebase ID Token (${token.length} chars):');
    const chunkSize = 900;
    for (int i = 0; i < token.length; i += chunkSize) {
      debugPrint(token.substring(i, (i + chunkSize).clamp(0, token.length)));
    }
    debugPrint('══════════════════════════════════════════');

    await _storage.saveToken(token);
    state = AuthAuthenticated(user: user, token: token);
    return true;
  }

  Future<void> signUp(String name, String email, String password) async {
    await _authService.createUserWithEmailPassword(name, email, password);
    // Sign out immediately — user must verify email before first login
    await _authService.signOut();
    state = const AuthUnauthenticated();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _storage.deleteToken();
    state = const AuthUnauthenticated();
  }

  // Returns a fresh Firebase ID token, refreshing if needed. Use this for API calls.
  Future<String?> getValidToken() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token != null) {
      await _storage.saveToken(token);
      final current = state;
      if (current is AuthAuthenticated) {
        state = current.copyWith(token: token);
      }
    }
    return token;
  }
}
