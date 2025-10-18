import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:voxly_frontend/core/services/telegram_service.dart';

class LivekitService extends ChangeNotifier {
  static final internal = LivekitService();
  static LivekitService get instance => internal;

  final room = Room();

  bool isLoading = false;

  void setLoadingState(bool state) {
    isLoading = state;
    notifyListeners();
  }

  Future joinOrCreateRoom({required String roomName}) async {
    try {
      setLoadingState(true);

      final resp = await http.post(
        Uri.parse('http://localhost:3000/getToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomName': roomName,
          'userName':
              TelegramService.instance.initData.user.username ?? 'noname',
        }),
      );

      final data = jsonDecode(resp.body);
      final token = data['token'];
      final url = data['liveKitUrl'];

      final roomOptions = RoomOptions(adaptiveStream: true, dynacast: true);

      await room.prepareConnection(url, token);

      await room.connect(url, token, roomOptions: roomOptions);

      await room.localParticipant?.setMicrophoneEnabled(true);

      setLoadingState(false);
    } catch (error) {
      setLoadingState(false);

      if (kDebugMode) {
        print('Error: $error');
      }
    }
  }

  Future endCall() async {
    setLoadingState(true);

    await room.localParticipant?.setMicrophoneEnabled(false);
    await room.disconnect();

    setLoadingState(false);
  }
}
