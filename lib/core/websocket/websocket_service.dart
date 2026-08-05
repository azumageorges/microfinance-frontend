import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketNotification {
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketNotification({
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory WebSocketNotification.fromJson(Map<String, dynamic> json) {
    return WebSocketNotification(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<WebSocketNotification> _notificationController =
      StreamController<WebSocketNotification>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool _disposed = false;

  Stream<WebSocketNotification> get notifications =>
      _notificationController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _isConnected;

  void connect(String baseUrl, String token) {
    if (_isConnected || _disposed) return;

    // Convertit http(s) → ws(s)
    final wsUrl = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final uri = Uri.parse('$wsUrl/ws/websocket?token=$token');

    if (kDebugMode) {
      debugPrint('[WS] Connecting to $uri');
    }

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _connectionController.add(true);

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      if (kDebugMode) {
        debugPrint('[WS] Connected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WS] Connection failed: $e');
      }
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void _handleMessage(dynamic message) {
    if (_disposed) return;
    try {
      final jsonData = json.decode(message as String) as Map<String, dynamic>;
      final notification = WebSocketNotification.fromJson(jsonData);
      if (kDebugMode) {
        debugPrint('[WS] Notification: ${notification.type}');
      }
      _notificationController.add(notification);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WS] Parse error: $e');
      }
    }
  }

  void _onError(Object error) {
    if (kDebugMode) {
      debugPrint('[WS] Error: $error');
    }
    _isConnected = false;
    if (!_disposed) _connectionController.add(false);
  }

  void _onDone() {
    if (kDebugMode) {
      debugPrint('[WS] Connection closed');
    }
    _isConnected = false;
    if (!_disposed) _connectionController.add(false);
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    if (!_disposed) _connectionController.add(false);
    if (kDebugMode) {
      debugPrint('[WS] Disconnected');
    }
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _notificationController.close();
    _connectionController.close();
  }
}
