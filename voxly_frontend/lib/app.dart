import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voxly_frontend/core/services/livekit_service.dart';
import 'package:voxly_frontend/features/lobby/pages/lobby_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LivekitService>(create: (_) => LivekitService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: LobbyPage(),
      ),
    );
  }
}
