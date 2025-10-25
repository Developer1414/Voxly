import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';
import 'package:voxly_frontend/core/widgets/button_widget.dart';
import 'package:voxly_frontend/core/themes/app_spacing.dart';
import 'package:voxly_frontend/core/widgets/text_field_widget.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  static TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final livekitProvider = Provider.of<LivekitService>(context, listen: true);

    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: switch (livekitProvider.state) {
            CallState.disconnected ||
            CallState.connecting ||
            CallState.error => KeyedSubtree(
              key: const ValueKey(CallState.error),
              child: diconnectedOrErrorPage(livekitProvider),
            ),
            CallState.connected => KeyedSubtree(
              key: const ValueKey(CallState.connected),
              child: connectedPage(livekitProvider),
            ),
            CallState.waitingForMatch => KeyedSubtree(
              key: const ValueKey(CallState.waitingForMatch),
              child: waitingForMatchPage(livekitProvider),
            ),
            CallState.inCall => KeyedSubtree(
              key: const ValueKey(CallState.inCall),
              child: inCallPage(livekitProvider),
            ),
          },
        ),
      ),
    );
  }

  Widget inCallPage(LivekitService livekitProvider) {
    bool microphoneOn =
        (livekitProvider.room.localParticipant?.isMicrophoneEnabled() ?? false);

    //bool speakerOn = (livekitProvider.room.speakerOn ?? false);
    //test

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
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.m,
          children: [
            Padding(
              padding: AppSpacing.allL,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(livekitProvider.sessionTime.elapsed),
                    style: AppTextStyles.h2Theme.copyWith(
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ButtonWidget(
                    onTap: () => livekitProvider.endCall(),
                    padding: AppSpacing.allS,
                    child: Icon(Icons.exit_to_app_rounded, size: 24.0),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.m,
              children: [
                ButtonWidget(
                  onTap: () async => await livekitProvider.setMicrophoneState(),
                  color: microphoneOn
                      ? Colors.deepPurpleAccent
                      : Colors.redAccent,
                  child: Icon(
                    livekitProvider.state != CallState.inCall
                        ? Icons.mic_off_rounded
                        : microphoneOn
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    size: 32.0,
                  ),
                ),
                // ButtonWidget(
                //   onTap: () async => await livekitProvider.changeOutputDevice(),
                //   color: speakerOn ? Colors.deepPurpleAccent : Colors.redAccent,
                //   child: Icon(
                //     livekitProvider.state != CallState.inCall
                //         ? Icons.phone_iphone_rounded
                //         : speakerOn
                //         ? Icons.speaker_phone_rounded
                //         : Icons.phone_iphone_rounded,
                //     size: 32.0,
                //   ),
                // ),
              ],
            ),
          ],
        ),
        Expanded(child: Container()),

        Container(
          height: 500.0,
          padding: AppSpacing.allM,
          margin: const EdgeInsets.only(
            left: AppSpacing.l,
            right: AppSpacing.l,
            bottom: AppSpacing.l,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            color: const Color.fromARGB(255, 91, 65, 26),
          ),
          child: Column(
            spacing: AppSpacing.s,
            children: [
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final roomMessages = livekitProvider.roomMessages.reversed
                        .toList();

                    return SelectableText(
                      roomMessages[index],
                      style: AppTextStyles.h3Theme.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 10.0),
                  itemCount: livekitProvider.roomMessages.length,
                ),
              ),
              textField(
                controller: messageController,
                onSubmitted: (text) => livekitProvider.sendMessage(text),
              ),
            ],
          ),
        ),

        // AnimatedContainer(
        //   width: 550.0,
        //   curve: Curves.easeInOutBack,
        //   duration: const Duration(milliseconds: 200),
        //   child: Stack(
        //     children: [
        //       Container(
        //         padding: AppSpacing.allM,
        //         margin: const EdgeInsets.only(
        //           left: AppSpacing.l,
        //           right: AppSpacing.l,
        //           bottom: AppSpacing.l,
        //         ),
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.circular(25.0),
        //           color: const Color.fromARGB(255, 91, 65, 26),
        //         ),
        //         child: Align(
        //           alignment: Alignment.centerLeft,
        //           child: AnimatedSwitcher(
        //             duration: const Duration(milliseconds: 150),
        //             transitionBuilder:
        //                 (Widget child, Animation<double> animation) {
        //                   return FadeTransition(
        //                     opacity: animation,
        //                     child: child,
        //                   );
        //                 },
        //             child: livekitProvider.isGeneratingStartQuestion
        //                 ? Row(
        //                     mainAxisAlignment: MainAxisAlignment.center,
        //                     spacing: AppSpacing.m,
        //                     children: [
        //                       const SizedBox(
        //                         width: 30.0,
        //                         height: 30.0,
        //                         child: CircularProgressIndicator(
        //                           color: Colors.white,
        //                           strokeCap: StrokeCap.round,
        //                           strokeWidth: 5.5,
        //                         ),
        //                       ),
        //                       Text(
        //                         'Генерация ИИ подсказки...',
        //                         style: AppTextStyles.h3Theme.copyWith(),
        //                       ),
        //                     ],
        //                   )
        //                 : Column(
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     spacing: AppSpacing.xxs,
        //                     children: [
        //                       if (livekitProvider.aiHint.isSuccessfully) ...[
        //                         Text(
        //                           'Начните разговор с вопроса:',
        //                           style: AppTextStyles.h3Theme.copyWith(
        //                             fontSize: 15.0,
        //                             color: Colors.white70,
        //                           ),
        //                         ),
        //                       ],
        //                       Text(
        //                         livekitProvider.aiHint.hint,
        //                         style: AppTextStyles.h2Theme.copyWith(
        //                           fontSize: 18.0,
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //           ),
        //         ),
        //       ),
        //       if (!livekitProvider.isGeneratingStartQuestion) ...[
        //         Transform.translate(
        //           offset: Offset(-10.0, -20.0),
        //           child: Align(
        //             alignment: Alignment.topRight,
        //             child: ButtonWidget(
        //               onTap: () async =>
        //                   await livekitProvider.setStartQuestion(),
        //               padding: EdgeInsets.all(12.0),
        //               child: Icon(Icons.replay_rounded, size: 28.0),
        //             ),
        //           ),
        //         ),
        //       ],
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget waitingForMatchPage(LivekitService livekitProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.m,
      children: [
        const SizedBox(
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
          padding: const EdgeInsets.only(top: AppSpacing.xs),
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
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: const SizedBox(
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
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.xxl,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
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
