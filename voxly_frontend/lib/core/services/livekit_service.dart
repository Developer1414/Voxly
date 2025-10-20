import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:voxly_frontend/core/models/livekit_model.dart';
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// НЕОБХОДИМЫЙ ИМПОРТ МОДЕЛИ (убедитесь, что файл livekit_models.dart существует)
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// Для примера. Замените на ваш способ получения имени пользователя.
class TelegramServiceLivekit {
  static final instance = TelegramServiceLivekit();
  String get username => 'flutter_user_${DateTime.now().millisecond}';
}

/// Перечисление для удобного управления состоянием в UI.
enum CallState {
  disconnected, // Нет подключения к серверу
  connecting, // Идет подключение к серверу
  connected, // Подключено к серверу, ожидание действий
  waitingForMatch, // В очереди на поиск собеседника
  inCall, // В процессе звонка
  error, // Произошла ошибка
}

class LivekitService extends ChangeNotifier {
  static final internal = LivekitService();
  static LivekitService get instance => internal;

  final room = Room();
  // Делаем late, так как инициализация происходит в connect()
  late IO.Socket socket;

  // --- Улучшенное управление состоянием ---
  var _state = CallState.disconnected;
  CallState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? partnerUsername;

  // Приватный сеттер для централизованного обновления состояния и UI
  void _setState(CallState newState, {String? error}) {
    if (_state == newState && error == null) return;
    _state = newState;
    _errorMessage = error;
    notifyListeners(); // Уведомляем UI об изменениях
  }

  /// Инициализирует и подключается к сокет-серверу.
  void connect() {
    // Предотвращаем повторное подключение
    if (_state != CallState.disconnected) return;

    _setState(CallState.connecting);

    try {
      socket = IO.io(
        'http://localhost:3000', // Укажите ваш IP-адрес, если запускаете на реальном устройстве
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // Управляем подключением вручную
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

  /// Регистрирует все обработчики событий сокета.
  void _registerSocketEvents() {
    socket.onConnect((_) {
      print('Socket.IO: Подключено.');
      _setState(CallState.connected);
    });

    socket.onDisconnect((_) {
      print('Socket.IO: Отключено.');
      _cleanUpCall(notify: false); // Очищаем данные звонка без уведомления UI
      _setState(CallState.disconnected);
    });

    socket.onConnectError((err) {
      print('Socket.IO: Ошибка подключения: $err');
      _setState(CallState.error, error: 'Не удалось подключиться к серверу.');
    });

    // Обработка ошибок, приходящих от сервера
    socket.on('error', (data) {
      final message = data?['message'] ?? 'Произошла неизвестная ошибка.';
      print('Socket.IO: Ошибка от сервера: $message');
      _setState(CallState.error, error: message);
    });

    socket.on('waiting', (_) {
      print('Сервер: Ожидание собеседника...');
      _setState(CallState.waitingForMatch);
    });

    // !!! ИСПРАВЛЕННЫЙ ОБРАБОТЧИК ДЛЯ ИЗБЕЖАНИЯ ОШИБКИ ТАЙП-КАСТИНГА !!!
    socket.on('match', (data) async {
      print('Data: $data');

      try {
        // Socket.IO клиент уже парсит JSON в Map<String, dynamic>.
        // Мы явно приводим тип и передаем его в фабрику модели.

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
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    socket.on('ended', (_) async {
      print('Сервер: Собеседник завершил звонок.');
      await _cleanUpCall();
      // Возвращаемся в состояние "подключен", показывая сообщение
      _setState(CallState.connected, error: 'Собеседник завершил звонок.');
    });
  }

  /// Ищет собеседника.
  void findMatch() {
    if (_state != CallState.connected) {
      print('Нельзя начать поиск, текущее состояние: $_state');
      return;
    }
    final name = TelegramServiceLivekit.instance.username;
    socket.emit('find', {'userName': name});
    // Состояние изменится на waitingForMatch после ответа от сервера
  }

  /// Завершает текущий звонок.
  Future<void> endCall() async {
    if (_state != CallState.inCall) return;

    socket.emit('end'); // Уведомляем сервер, чтобы он оповестил партнера
    await _cleanUpCall();
    _setState(CallState.connected); // Возвращаемся в состояние ожидания
  }

  /// Подключается к комнате LiveKit.
  Future<void> _connectToLiveKitRoom(String url, String token) async {
    try {
      await room.connect(
        url,
        token,
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );
      await room.localParticipant?.setMicrophoneEnabled(true);
      _setState(CallState.inCall);
    } catch (e) {
      print("LiveKit: Ошибка подключения к комнате: $e");
      // Также уведомим сервер о разрыве, если LiveKit не подключился
      socket.emit('end');
      _setState(
        CallState.error,
        error: "Не удалось подключиться к видео-комнате.",
      );
    }
  }

  /// Отключается от комнаты LiveKit и сбрасывает связанные данные.
  Future<void> _cleanUpCall({bool notify = true}) async {
    if (room.connectionState == ConnectionState.connected) {
      await room.disconnect();
    }
    partnerUsername = null;
    if (notify) {
      notifyListeners();
    }
  }

  /// Полностью отключается от сервера.
  @override
  void dispose() {
    print("Disposing LivekitService");
    socket.dispose();
    room.dispose();
    super.dispose();
  }
}
