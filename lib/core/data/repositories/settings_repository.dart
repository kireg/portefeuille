// lib/core/data/repositories/settings_repository.dart
import 'package:hive/hive.dart';
import 'package:portefeuille/core/utils/constants.dart';

class SettingsRepository {
  final Box _box;

  SettingsRepository({Box? box}) : _box = box ?? Hive.box(AppConstants.kSettingsBoxName);

  dynamic get(String key, {dynamic defaultValue}) => _box.get(key, defaultValue: defaultValue);

  Future<void> put(String key, dynamic value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);
}

