import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/env.dart';
import '../utils/logger.dart';

class SocketService {
  SocketService(this._tokenProvider) {
    _init();
  }

  final Future<String?> Function() _tokenProvider;
  IO.Socket? _socket;
  final _sosAlertController = StreamController<void>.broadcast();
  final _sosAcknowledgedController = StreamController<void>.broadcast();

  Stream<void> get onSosAlert => _sosAlertController.stream;
  Stream<void> get onSosAcknowledged => _sosAcknowledgedController.stream;

  void _init() {
    _socket = IO.io(
      '${Env.apiBaseUrl}/sync',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      AppLogger().info('Socket connected');
    });

    _socket?.onDisconnect((_) {
      AppLogger().info('Socket disconnected');
    });

    _socket?.on('sos-alert', (_) {
      _sosAlertController.add(null);
    });

    _socket?.on('sos-acknowledged', (_) {
      _sosAcknowledgedController.add(null);
    });
  }

  Future<void> connect() async {
    final token = await _tokenProvider();
    if (token == null || token.isEmpty) return;
    
    _socket?.auth = {'token': token};
    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.dispose();
    _sosAlertController.close();
    _sosAcknowledgedController.close();
  }
}
