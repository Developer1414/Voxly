import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';
import 'package:voxly_frontend/core/widgets/button_widget.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final livekitProvider = Provider.of<LivekitService>(context, listen: true);

    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 150),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: switch (livekitProvider.state) {
            CallState.disconnected ||
            CallState.connecting ||
            CallState.error => KeyedSubtree(
              key: ValueKey(CallState.error),
              child: diconnectedOrErrorPage(livekitProvider),
            ),
            CallState.connected => KeyedSubtree(
              key: ValueKey(CallState.connected),
              child: connectedPage(livekitProvider),
            ),
            CallState.waitingForMatch => KeyedSubtree(
              key: ValueKey(CallState.waitingForMatch),
              child: waitingForMatchPage(livekitProvider),
            ),
            CallState.inCall => KeyedSubtree(
              key: ValueKey(CallState.inCall),
              child: inCallPage(livekitProvider),
            ),
          },
        ),
      ),
    );
  }

  Widget inCallPage(LivekitService livekitProvider) {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');

      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));

      if (duration.inHours > 0) {
        return '$hours:$minutes:$seconds';
      }
      return '$minutes:$seconds';
    }

    return Column(
      spacing: 20.0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          formatDuration(livekitProvider.sessionTime.elapsed),
          style: AppTextStyles.h2Theme.copyWith(
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
        ),
        ButtonWidget(
          onTap: () => livekitProvider.cancelFind(),
          label: 'Завершить',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ButtonWidget(
              onTap: () async => await livekitProvider.setMicrophoneState(),
              child: Icon(
                livekitProvider.room.localParticipant!.isMicrophoneEnabled()
                    ? Icons.mic_rounded
                    : Icons.mic_off_rounded,
                size: 30.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget waitingForMatchPage(LivekitService livekitProvider) {
    return Column(
      spacing: 20.0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40.0,
          height: 40.0,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeCap: StrokeCap.round,
            strokeWidth: 7.0,
          ),
        ),
        Text(
          'Ищем собеседника...',
          style: AppTextStyles.h3Theme.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: ButtonWidget(
            onTap: () => livekitProvider.cancelFind(),
            label: 'Отменить поиск',
          ),
        ),
      ],
    );
  }

  Widget diconnectedOrErrorPage(LivekitService livekitProvider) {
    return Column(
      spacing: 10.0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: SizedBox(
            width: 40.0,
            height: 40.0,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeCap: StrokeCap.round,
              strokeWidth: 7.0,
            ),
          ),
        ),
        Text(
          'Подключение...',
          style: AppTextStyles.h2Theme,
          textAlign: TextAlign.center,
        ),
        Text(
          'Пожалуйста, подождите.',
          style: AppTextStyles.h3Theme.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget connectedPage(LivekitService livekitProvider) {
    return Column(
      spacing: 40.0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              'Voxly',
              style: AppTextStyles.h1Theme.copyWith(fontSize: 60.0),
              textAlign: TextAlign.center,
            ),
            Text(
              'Анонимный аудио-чат',
              style: AppTextStyles.h3Theme.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SizedBox(
            width: 450.0,
            child: ButtonWidget(
              onTap: () => livekitProvider.findMatch(),
              label: 'Начать звонок',
              isLoading: livekitProvider.state == CallState.waitingForMatch,
            ),
          ),
        ),
      ],
    );
  }
}
