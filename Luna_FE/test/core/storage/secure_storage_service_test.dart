import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/error/exception.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

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

  test('backend read failures map to a redacted typed failure', () async {
    final storage = SecureStorageService(
      backend: _ThrowingBackend(readError: 'read-backend-secret'),
    );

    await expectLater(
      storage.readIdentity(),
      throwsA(
        isA<StorageException>()
            .having(
              (error) => error.reason,
              'reason',
              StorageFailureReason.readFailed,
            )
            .having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('read-backend-secret')),
            ),
      ),
    );
  });

  test('backend write failures map to a redacted typed failure', () async {
    final storage = SecureStorageService(
      backend: _ThrowingBackend(writeError: 'write-backend-secret'),
    );

    await expectLater(
      storage.writeIdentity(_identity),
      throwsA(
        isA<StorageException>()
            .having(
              (error) => error.reason,
              'reason',
              StorageFailureReason.writeFailed,
            )
            .having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('write-backend-secret')),
            ),
      ),
    );
  });

  test('backend delete failures map to a redacted typed failure', () async {
    final storage = SecureStorageService(
      backend: _ThrowingBackend(deleteError: 'delete-backend-secret'),
    );

    await expectLater(
      storage.clearIdentity(),
      throwsA(
        isA<StorageException>()
            .having(
              (error) => error.reason,
              'reason',
              StorageFailureReason.deleteFailed,
            )
            .having(
              (error) => error.toString(),
              'safe message',
              isNot(contains('delete-backend-secret')),
            ),
      ),
    );
  });
}

const _identity = DeviceIdentity(
  deviceId: 'device-1',
  token: 'issued-token',
  role: DeviceRole.owner,
);

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

class _ThrowingBackend implements SecureStorageBackend {
  _ThrowingBackend({this.readError, this.writeError, this.deleteError});

  final String? readError;
  final String? writeError;
  final String? deleteError;

  @override
  Future<void> delete(String key) async {
    if (deleteError != null) throw StateError(deleteError!);
  }

  @override
  Future<String?> read(String key) async {
    if (readError != null) throw StateError(readError!);
    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    if (writeError != null) throw StateError(writeError!);
  }
}
