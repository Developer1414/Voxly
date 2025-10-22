import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voxly_frontend/app.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/core/services/telegram_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TelegramService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LivekitService>(create: (_) => LivekitService()),
      ],
      child: MyApp(),
    ),
  );
}
