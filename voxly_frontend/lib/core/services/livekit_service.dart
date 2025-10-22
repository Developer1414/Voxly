import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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

  Stopwatch sessionTime = Stopwatch();

  Timer? _sessionTimer;

  void _setState(CallState newState, {String? error}) {
    if (_state == newState && error == null) return;

    _state = newState;
    _errorMessage = error;

    if (error != null) {
      showAlertWindow('Ошибка', error);
    }

    notifyListeners();
  }

  void connect() {
    if (_state != CallState.disconnected) return;

    _setState(CallState.connecting);

    try {
      socket = IO.io(
        kDebugMode
            ? 'http://localhost:3000'
            : 'wss://voxly-audio.ru/ws', //'https://voxly-backend.onrender.com',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setPath('/ws/socket.io/')
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
      _setState(CallState.connected);
    });

    socket.onDisconnect((_) {
      _cleanUpCall(notify: false);
      _setState(CallState.disconnected);
    });

    socket.onConnectError((err) {
      _setState(
        CallState.error,
      ); // , error: 'Не удалось подключиться к серверу.'
    });

    socket.on('cancelled_find', (data) async {
      _setState(CallState.connected);

      await _cleanUpCall(notify: true);
    });

    socket.on('error', (data) {
      final message = data?['message'] ?? 'Произошла неизвестная ошибка.';
      _setState(CallState.error, error: 'Ошибка от сервера: $message');
    });

    socket.on('waiting', (_) {
      _setState(CallState.waitingForMatch);
    });

    socket.on('match', (data) async {
      try {
        final mapData = data as Map<String, dynamic>;
        final match = MatchData.fromJson(mapData);

        partnerUsername = match.partner;

        await _connectToLiveKitRoom(match.liveKitUrl, match.token);
      } catch (e) {
        _setState(CallState.error, error: 'Ошибка получения данных о комнате.');
      }
    });

    socket.on('ended', (_) async {
      await _cleanUpCall(notify: true);
      _setState(CallState.connected, error: 'Собеседник завершил звонок.');
    });
  }

  void findMatch() {
    if (_state != CallState.connected) {
      showAlertWindow(
        'Ошибка',
        'Нельзя начать поиск, текущее состояние: $_state',
      );

      return;
    }

    final name = TelegramService.instance.getUsername();

    socket.emit('find', {'userName': name});

    _setState(CallState.waitingForMatch);
  }

  Future<void> endCall() async {
    if (_state != CallState.inCall) return;

    socket.emit('end');

    await _cleanUpCall(notify: true);

    _setState(CallState.connected);
  }

  void cancelFind() => socket.emit('cancel_find');

  Future<void> setMicrophoneState() async {
    await room.localParticipant?.setMicrophoneEnabled(
      !room.localParticipant!.isMicrophoneEnabled(),
    );

    notifyListeners();
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

      sessionTime
        ..reset()
        ..start();

      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (sessionTime.isRunning) {
          notifyListeners();
        }
      });
    } catch (e) {
      socket.emit('end');

      _setState(
        CallState.error,
        error: "Не удалось подключиться к комнате: $e",
      );
    }
  }

  Future<void> _cleanUpCall({bool notify = true}) async {
    if (room.connectionState == ConnectionState.connected) {
      await room.disconnect();
    }

    _sessionTimer?.cancel();
    _sessionTimer = null;

    sessionTime.stop();

    partnerUsername = null;

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanUpCall();

    if (socket.connected) {
      socket.dispose();
    }

    room.dispose();
    super.dispose();
  }
}
