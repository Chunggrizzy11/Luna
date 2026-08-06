import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  throw StateError('socketServiceProvider must be overridden at root');
});
