import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:voxly_frontend/app.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/core/services/telegram_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TelegramService.instance.init();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await LivekitService.instance.connectToWebsocket();
  });

  runApp(MyApp());
}

class AudioRoomPage extends StatefulWidget {
  const AudioRoomPage({super.key, required this.room});

  final Room room;

  @override
  State<AudioRoomPage> createState() => _AudioRoomPageState();
}

class _AudioRoomPageState extends State<AudioRoomPage> {
  late final EventsListener<RoomEvent> listener = widget.room.createListener();

  @override
  void initState() {
    super.initState();
    widget.room.addListener(_onChange);

    listener
      ..on<RoomDisconnectedEvent>((_) {})
      ..on<ParticipantConnectedEvent>((e) {
        print("participant joined: ${e.participant.identity}");
      });
  }

  @override
  void dispose() {
    listener.dispose();
    widget.room.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Audio Room: ${widget.room.name}'),
      actions: [
        IconButton(
          onPressed: () async {
            await widget.room.disconnect();

            Navigator.pop(context);
          },
          icon: Icon(Icons.close_rounded),
        ),
      ],
    ),
    body: Scaffold(
      body: Center(
        child: Column(
          spacing: 20.0,
          children: [
            Text('Connected!'),
            Text('Members: ${widget.room.remoteParticipants.length}'),
          ],
        ),
      ),
    ),
  );
}
