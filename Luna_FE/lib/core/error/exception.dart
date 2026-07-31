enum StorageFailureReason {
  readFailed,
  writeFailed,
  deleteFailed,
  corruptIdentity,
  cleanupFailed,
}

class StorageException implements Exception {
  const StorageException(this.message, {required this.reason});

  final String message;
  final StorageFailureReason reason;

  @override
  String toString() => message;
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => message;
}
