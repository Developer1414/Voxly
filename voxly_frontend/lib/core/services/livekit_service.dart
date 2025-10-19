import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:voxly_frontend/core/services/telegram_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LivekitService extends ChangeNotifier {
  static final internal = LivekitService();
  static LivekitService get instance => internal;

  final room = Room();

  late IO.Socket socket;

  bool isLoading = false;
  bool _connected = false;

  bool get isConnected => _connected;

  void setLoadingState(bool state) {
    isLoading = state;
    notifyListeners();
  }

  Future connectToWebsocket() async {
    if (_connected) return;

    try {
      socket = IO.io(
        'http://localhost:3000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      socket.onConnect((_) {
        _connected = true;

        setLoadingState(false);

        print('Socket.IO connected');
      });

      socket.onDisconnect((_) {
        _connected = false;

        print('Socket.IO disconnected, will try reconnect');
      });

      socket.onConnectError((err) {
        _connected = false;

        setLoadingState(true);

        print('Socket.IO connection error: $err');
      });

      socket.on('waiting', (_) {
        print('Ожидание собеседника...');
      });

      socket.on('match', (data) async {
        final d = data is String ? jsonDecode(data) : data;
        await _connectRoom(d['liveKitUrl'], d['token']);
      });

      socket.on('ended', (_) async {
        await room.disconnect();
        notifyListeners();
      });

      socket.connect();
    } catch (e) {
      _connected = false;

      setLoadingState(true);

      print('Failed to connect: $e');

      await Future.delayed(Duration(seconds: 3));

      reconnectToWebsocket();
    }
  }

  void reconnectToWebsocket() {
    if (!_connected) connectToWebsocket();
  }

  @override
  void dispose() {
    disconnectFromWebsocket();
    super.dispose();
  }

  void disconnectFromWebsocket() {
    setLoadingState(true);

    _connected = false;

    socket.disconnect();

    print('disconnected');

    setLoadingState(false);
  }

  void findMatch() {
    setLoadingState(true);

    final name = TelegramService.instance.initData.user.username ?? 'noname';

    socket.emit('find', {'userName': name});
  }

  Future _connectRoom(String url, String token) async {
    await room.connect(url, token);
    await room.localParticipant?.setMicrophoneEnabled(true);

    setLoadingState(false);
  }

  Future endCall() async {
    setLoadingState(true);

    socket.emit('end');

    await room.disconnect();

    setLoadingState(false);
  }
}
