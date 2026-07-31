class LocalDatabase {
  final Map<String, Object?> _records = <String, Object?>{};

  Future<void> put(String key, Object? value) async {
    _records[key] = value;
  }

  Future<T?> get<T>(String key) async {
    final value = _records[key];
    return value is T ? value : null;
  }

  Future<void> delete(String key) async {
    _records.remove(key);
  }

  Future<void> clear() async {
    _records.clear();
  }
}
