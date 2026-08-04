import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không thể kết nối mạng.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Phiên thiết bị không hợp lệ.']);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'Bạn không có quyền thực hiện thao tác này.',
  ]);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Đã xảy ra lỗi không mong muốn.']);
}
