import 'package:flutter/material.dart';
import 'package:voxly_frontend/core/widgets/button_widget.dart';

class LobbyPage extends StatelessWidget {
  const LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ButtonWidget(onTap: () {}, label: 'Start Call')],
        ),
      ),
    );
  }
}
