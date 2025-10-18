import 'package:flutter/foundation.dart';
import 'package:telegram_web_app/telegram_web_app.dart';

class TelegramService {
  TelegramService._();

  static final internal = TelegramService._();
  static TelegramService get instance => internal;

  late final TelegramInitData initData;

  Future init() async {
    try {
      if (TelegramWebApp.instance.isSupported) {
        TelegramWebApp.instance.ready();

        await Future.delayed(
          const Duration(seconds: 1),
          TelegramWebApp.instance.expand,
        );

        initData = kDebugMode
            ? TelegramWebAppFake().initData
            : TelegramWebApp.instance.initData;

        TelegramWebApp.instance.enableClosingConfirmation();
        TelegramWebApp.instance.disableVerticalSwipes();
      } else {
        initData = TelegramInitData.fake();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error happened in Flutter while loading Telegram $e");
      }

      await Future.delayed(const Duration(milliseconds: 200));

      init();
    }
  }
}
