import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estate.dart';
import '../models/estate_section.dart';
import '../models/tea_entry.dart';
import '../models/user_profile.dart';
import '../models/weather_data.dart';
import '../models/worker.dart';
import '../notifiers/estate_notifier.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
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

/// Workers for a given estateId — cached across tab switches.
final workersProvider =
    FutureProvider.family<List<Worker>, String>((ref, estateId) async {
  final token = ref.read(authTokenProvider)!;
  return ref.read(apiServiceProvider).listWorkers(token, estateId);
});

final weatherServiceProvider =
    Provider<WeatherService>((_) => WeatherService());

/// Weather for an estate location string. Cached until the location changes.
final weatherProvider =
    FutureProvider.family<WeatherData?, String>((ref, location) async {
  if (location.trim().isEmpty) return null;
  return ref.read(weatherServiceProvider).fetchWeather(location);
});

/// Tea entries for an estate. Pass (estateId, date) — date null fetches all.
final teaEntriesProvider =
    FutureProvider.family<List<TeaEntry>, (String, String?)>(
  (ref, params) async {
    final token = ref.read(authTokenProvider)!;
    final (estateId, date) = params;
    return ref
        .read(apiServiceProvider)
        .listTeaEntries(token, estateId, date: date);
  },
);

/// Sections for a given estateId.
final sectionsProvider =
    FutureProvider.family<List<EstateSection>, String>((ref, estateId) async {
  final token = ref.read(authTokenProvider)!;
  return ref.read(apiServiceProvider).listSections(token, estateId);
});
