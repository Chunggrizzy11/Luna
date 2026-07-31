import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/error/exception.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';

void main() {
  test(
    'malformed identity is deleted and reported as typed corruption',
    () async {
      final backend = _MalformedBackend();
      final storage = SecureStorageService(backend: backend);

      await expectLater(
        storage.readIdentity(),
        throwsA(
          isA<StorageException>().having(
            (error) => error.reason,
            'reason',
            StorageFailureReason.corruptIdentity,
          ),
        ),
      );
      expect(backend.deleteCalls, 1);
    },
  );

  test(
    'malformed identity cleanup failure remains typed and redacted',
    () async {
      final backend = _MalformedBackend(failDelete: true);
      final storage = SecureStorageService(backend: backend);

      await expectLater(
        storage.readIdentity(),
        throwsA(
          isA<StorageException>()
              .having(
                (error) => error.reason,
                'reason',
                StorageFailureReason.cleanupFailed,
              )
              .having(
                (error) => error.toString(),
                'safe message',
                isNot(contains('backend-delete-secret')),
              ),
        ),
      );
      expect(backend.deleteCalls, 1);
    },
  );
}

class _MalformedBackend implements SecureStorageBackend {
  _MalformedBackend({this.failDelete = false});

  final bool failDelete;
  int deleteCalls = 0;

  @override
  Future<void> delete(String key) async {
    deleteCalls += 1;
    if (failDelete) throw StateError('backend-delete-secret');
  }

  @override
  Future<String?> read(String key) async => '{not-json';

  @override
  Future<void> write(String key, String value) async {}
}
