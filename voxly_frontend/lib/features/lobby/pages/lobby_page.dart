import 'package:flutter/material.dart' hide ConnectionState;
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';
import 'package:voxly_frontend/core/widgets/button_widget.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final livekitProvider = Provider.of<LivekitService>(context, listen: true);

    return livekitProvider.room.connectionState != ConnectionState.connected
        ? Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonWidget(
                    onTap: () async => await livekitProvider.joinOrCreateRoom(
                      roomName: 'room-${DateTime.now().microsecondsSinceEpoch}',
                    ),
                    label: 'Start Call',
                    isLoading: livekitProvider.isLoading,
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            body: Center(
              child: Column(
                spacing: 20.0,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    livekitProvider.room.name ?? 'no name room',
                    style: AppTextStyles.buttonTextTheme,
                  ),
                  ButtonWidget(
                    onTap: () async => await livekitProvider.joinOrCreateRoom(
                      roomName: 'room-${DateTime.now().microsecondsSinceEpoch}',
                    ),
                    label: 'End Call',
                    isLoading: livekitProvider.isLoading,
                  ),
                ],
              ),
            ),
          );
  }
}
