import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estate.dart';
import '../services/secure_storage_service.dart';

class EstateNotifier extends StateNotifier<Estate?> {
  final SecureStorageService _storage;
  final Completer<void> _initCompleter = Completer();

  Future<void> get initFuture => _initCompleter.future;

  EstateNotifier(this._storage) : super(null) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = await _storage.loadEstate();
    } catch (_) {
      state = null;
    } finally {
      _initCompleter.complete();
    }
  }

  Future<void> selectEstate(Estate estate) async {
    await _storage.saveEstate(estate);
    state = estate;
  }

  Future<void> clearEstate() async {
    await _storage.deleteEstate();
    state = null;
  }
}
