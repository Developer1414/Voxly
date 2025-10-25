import 'dart:math';

import 'package:telegram_web_app/telegram_web_app.dart';

extension TelegramInitDataExt on TelegramInitData {
  TelegramInitData withRandomUsername() {
    final random = Random();
    final number = random.nextInt(999999);
    final newUser = TelegramUser(
      id: user.id,
      firstname: user.firstname,
      lastname: user.lastname,
      username: 'flutter_telegram$number',
      languageCode: user.languageCode,
      allowsWriteToPm: user.allowsWriteToPm,
    );

    return TelegramInitData(
      user: newUser,
      chatInstance: chatInstance,
      chatType: chatType,
      queryId: queryId,
      authDate: authDate,
      hash: hash,
      raw: raw,
    );
  }
}
