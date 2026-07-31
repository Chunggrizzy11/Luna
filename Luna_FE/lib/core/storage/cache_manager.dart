import '../config/app_constant.dart';
import 'local_database.dart';

class CacheManager {
  CacheManager({LocalDatabase? database, DateTime Function()? now})
    : _database = database ?? LocalDatabase(),
      _now = now ?? DateTime.now;

  final LocalDatabase _database;
  final DateTime Function() _now;

  Future<void> put<T>(
    String key,
    T value, {
    Duration ttl = AppConstant.defaultCacheTtl,
  }) => _database.put(key, _CacheEntry(value, _now().add(ttl)));

  Future<T?> get<T>(String key) async {
    final entry = await _database.get<_CacheEntry>(key);
    if (entry == null) return null;
    if (!_now().isBefore(entry.expiresAt)) {
      await _database.delete(key);
      return null;
    }
    return entry.value is T ? entry.value as T : null;
  }

  Future<void> remove(String key) => _database.delete(key);

  Future<void> clear() => _database.clear();
}

class _CacheEntry {
  const _CacheEntry(this.value, this.expiresAt);

  final Object? value;
  final DateTime expiresAt;
}
