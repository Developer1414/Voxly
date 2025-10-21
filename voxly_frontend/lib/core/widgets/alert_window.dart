import 'package:flutter/material.dart';
import 'package:voxly_frontend/app.dart';
import 'package:voxly_frontend/core/themes/app_colors.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';
import 'package:voxly_frontend/core/widgets/button_widget.dart';

void showAlertWindow(
  String title,
  String message, {
  bool isCanPop = true,
  List<Widget> alertButtons = const [],
}) {
  BuildContext? context = navigatorKey.currentContext;

  if (context == null) return;

  print('hello');

  showDialog(
    context: context,
    builder: (_) {
      return GestureDetector(
        onTap: () => isCanPop ? Navigator.of(context).pop() : null,
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor.withAlpha(130),
          body: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.0),
                margin: EdgeInsets.all(25.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: const Color.fromARGB(255, 219, 224, 236),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20.0,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.notificationTitleTextTheme,
                    ),
                    Text(message, style: AppTextStyles.alertMainTextTheme),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: alertButtons.isEmpty
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: ButtonWidget(
                                onTap: () => Navigator.of(context).pop(),
                                label: 'Закрыть',
                                color: Colors.green,
                                padding: EdgeInsets.all(15.0),
                                fontSize: 22.0,
                              ),
                            )
                          : Row(spacing: 20.0, children: alertButtons),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
