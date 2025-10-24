import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:voxly_frontend/core/models/livekit_model.dart';
import 'package:voxly_frontend/core/services/ai_service.dart';
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

  AiHintModel aiHint = AiHintModel.init();

  Stopwatch sessionTime = Stopwatch();

  Timer? _sessionTimer;

  bool isGeneratingStartQuestion = true;

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
        kDebugMode ? 'http://localhost:3000' : 'https://voxly-audio.ru',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .setPath('/socket.io/')
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

  Future setStartQuestion() async {
    isGeneratingStartQuestion = true;
    notifyListeners();

    aiHint = await AiService.instance.request(
      """Пожалуйста, сгенерируй один максимально простой, веселый и «зумерский» вопрос для начала разговора с незнакомцем в анонимном голосовом чате. Вопрос должен быть лёгким, мгновенно понятным, не требовать глубоких размышлений, создавать непринуждённую дружелюбную атмосферу и быть уникальным, неожиданным, отличаться от обычных «Как дела?». В ответе предоставь только сам вопрос, без лишнего текста и объяснений.""",
    );

    isGeneratingStartQuestion = false;
    notifyListeners();
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

  void endCall() {
    if (_state != CallState.inCall) return;

    showAlertWindow(
      'Подтверждение',
      'Вы действительно хотите выйти из звонка?',
      alertButtons: [
        AlertButton(
          label: 'Да',
          color: Colors.redAccent,
          isCloseAlert: true,
          onTap: () async {
            socket.emit('end');

            await _cleanUpCall(notify: true);

            _setState(CallState.connected);
          },
        ),
        AlertButton(
          label: 'Нет',
          color: Colors.green,
          onTap: () {},
          isCloseAlert: true,
        ),
      ],
    );
  }

  void cancelFind() => socket.emit('cancel_find');

  Future<void> setMicrophoneState() async {
    await room.localParticipant?.setMicrophoneEnabled(
      !room.localParticipant!.isMicrophoneEnabled(),
    );

    notifyListeners();
  }

  Future<void> changeOutputDevice() async {
    await room.setSpeakerOn(!room.speakerOn!);

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

      await setStartQuestion();
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
