import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:voxly_frontend/app.dart';

void main() => runApp(MyApp());

class JoinPage extends StatefulWidget {
  const JoinPage({super.key});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  final roomController = TextEditingController();
  final nameController = TextEditingController();

  void join() async {
    final roomName = roomController.text;
    final userName = nameController.text;

    try {
      final resp = await http.post(
        Uri.parse('http://localhost:3000/getToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomName': roomName, 'userName': userName}),
      );

      print('Body: ${resp.body}');

      final data = jsonDecode(resp.body);
      final token = data['token'];
      final url = data['liveKitUrl'];

      final roomOptions = RoomOptions(adaptiveStream: true, dynacast: true);

      final room = Room();

      await room.prepareConnection(url, token);

      await room.connect(url, token, roomOptions: roomOptions);

      await room.localParticipant?.setMicrophoneEnabled(true);

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => AudioRoomPage(room: room)));
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: roomController,
              decoration: InputDecoration(labelText: 'Room'),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            ElevatedButton(
              onPressed: join,
              child: Text('Join 1-on-1 audio chat'),
            ),
          ],
        ),
      ),
    ),
  );
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
