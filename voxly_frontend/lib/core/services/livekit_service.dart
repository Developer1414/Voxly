import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:voxly_frontend/app.dart';
import 'package:voxly_frontend/core/models/livekit_model.dart';
import 'package:voxly_frontend/core/services/telegram_service.dart';
import 'package:voxly_frontend/core/widgets/alert_window.dart';

enum CallState {
  disconnected,
  connecting,
  connected,
  waitingForMatch,
  inCall,
  error,
}

class LivekitService extends ChangeNotifier {
  static final internal = LivekitService();
  static LivekitService get instance => internal;

  final room = Room();
  late IO.Socket socket;

  var _state = CallState.disconnected;
  CallState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? partnerUsername;

  void _setState(CallState newState, {String? error}) {
    if (_state == newState && error == null) return;

    _state = newState;
    _errorMessage = error;

    notifyListeners();
  }

  void connect() {
    if (_state != CallState.disconnected) return;

    _setState(CallState.connecting);

    try {
      socket = IO.io(
        kDebugMode
            ? 'http://localhost:3000'
            : 'https://voxly-backend.onrender.com',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _registerSocketEvents();

      socket.connect();
    } catch (e) {
      _setState(
        CallState.error,
        error: 'Не удалось инициализировать сокет: $e',
      );
    }
  }

  void _registerSocketEvents() {
    socket.onConnect((_) {
      print('Socket.IO: Подключено.');
      _setState(CallState.connected);
    });

    socket.onDisconnect((_) {
      print('Socket.IO: Отключено.');
      _cleanUpCall(notify: false);
      _setState(CallState.disconnected);
    });

    socket.onConnectError((err) {
      print('Socket.IO: Ошибка подключения: $err');
      _setState(CallState.error, error: 'Не удалось подключиться к серверу.');
    });

    socket.on('error', (data) {
      final message = data?['message'] ?? 'Произошла неизвестная ошибка.';
      print('Socket.IO: Ошибка от сервера: $message');
      _setState(CallState.error, error: message);
    });

    socket.on('waiting', (_) {
      print('Сервер: Ожидание собеседника...');
      _setState(CallState.waitingForMatch);
    });

    socket.on('match', (data) async {
      print('Data: $data');

      try {
        final mapData = data as Map<String, dynamic>;
        final match = MatchData.fromJson(mapData);

        print('Сервер: Собеседник найден! Партнер: ${match.partner}');
        partnerUsername = match.partner;
        await _connectToLiveKitRoom(match.liveKitUrl, match.token);
      } catch (e) {
        print(
          'Ошибка парсинга MatchData (вероятно, неверный формат данных): $e',
        );
        _setState(CallState.error, error: 'Ошибка получения данных о комнате.');
      }
    });

    socket.on('ended', (_) async {
      print('Сервер: Собеседник завершил звонок.');
      await _cleanUpCall();
      _setState(CallState.connected, error: 'Собеседник завершил звонок.');
    });
  }

  void findMatch() {
    if (_state != CallState.connected) {
      showAletWindow(
        'Ошибка',
        'Нельзя начать поиск, текущее состояние: $_state',
      );

      return;
    }

    final name = TelegramService.instance.getUsername();

    socket.emit('find', {'userName': name});
  }

  Future<void> endCall() async {
    if (_state != CallState.inCall) return;

    socket.emit('end');

    await _cleanUpCall();

    _setState(CallState.connected);
  }

  Future<void> _connectToLiveKitRoom(String url, String token) async {
    try {
      await room.connect(
        url,
        token,
        // ignore: deprecated_member_use
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      await room.localParticipant?.setMicrophoneEnabled(true);

      _setState(CallState.inCall);
    } catch (e) {
      print("LiveKit: Ошибка подключения к комнате: $e");

      socket.emit('end');

      _setState(CallState.error, error: "Не удалось подключиться к комнате.");
    }
  }

  Future<void> _cleanUpCall({bool notify = true}) async {
    if (room.connectionState == ConnectionState.connected) {
      await room.disconnect();
    }

    partnerUsername = null;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    socket.dispose();
    room.dispose();
    super.dispose();
  }
}
