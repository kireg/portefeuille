// lib/core/data/repositories/settings_repository.dart
import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/constants.dart';

class SettingsRepository {
  dynamic _box;

  SettingsRepository({Box? box}) : _box = box;

  dynamic _ensureBox() {
    if (_box == null) {
      if (Hive.isBoxOpen(AppConstants.kSettingsBoxName)) {
        _box = Hive.box(AppConstants.kSettingsBoxName);
      } else {
        _box = _InMemoryStore();
      }
    }
    return _box;
  }

  dynamic get(String key, {dynamic defaultValue}) => _ensureBox().get(key, defaultValue: defaultValue);

  Future<void> put(String key, dynamic value) => Future.value(_ensureBox().put(key, value));

  Future<void> delete(String key) => Future.value(_ensureBox().delete(key));
}

/// Lightweight in-memory store used as a fallback in tests. Not a Hive Box.
class _InMemoryStore {
  final Map<dynamic, dynamic> _store = {};

  dynamic get(dynamic key, {dynamic defaultValue}) => _store.containsKey(key) ? _store[key] : defaultValue;

  Future<void> put(dynamic key, dynamic value) async {
    _store[key] = value;
  }

  Future<void> delete(dynamic key) async {
    _store.remove(key);
  }

  bool containsKey(dynamic key) => _store.containsKey(key);

  Future<int> clear() async {
    final count = _store.length;
    _store.clear();
    return count;
  }
}
