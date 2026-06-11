import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitializing extends AuthState {
  const AuthInitializing();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  AuthAuthenticated copyWith({User? user, String? token}) => AuthAuthenticated(
        user: user ?? this.user,
        token: token ?? this.token,
      );
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
