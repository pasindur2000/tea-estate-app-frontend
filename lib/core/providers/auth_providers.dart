import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estate.dart';
import '../models/user_profile.dart';
import '../notifiers/estate_notifier.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/notifiers/auth_notifier.dart';
import '../../features/auth/notifiers/user_profile_notifier.dart';
import '../../features/auth/services/auth_service.dart';

final authServiceProvider = Provider<FirebaseAuthService>(
  (_) => FirebaseAuthService(),
);

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(secureStorageProvider),
  ),
);

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(ref.read(apiServiceProvider)),
);

final estateNotifierProvider = StateNotifierProvider<EstateNotifier, Estate?>(
  (ref) => EstateNotifier(ref.read(secureStorageProvider)),
);

/// Convenience: read the current Firebase ID token. Null when unauthenticated.
final authTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated ? authState.token : null;
});
