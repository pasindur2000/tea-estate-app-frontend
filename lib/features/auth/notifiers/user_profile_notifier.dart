import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/api_service.dart';

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final ApiService _api;

  UserProfileNotifier(this._api) : super(null);

  Future<void> loadProfile(String token) async {
    final profile = await _api.getMe(token);
    state = profile;
  }

  void clear() => state = null;
}
