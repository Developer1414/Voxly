import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:voxly_frontend/core/themes/app_colors.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';

class ButtonWidget extends StatefulWidget {
  ButtonWidget({
    super.key,
    this.isLoading = false,
    Color? color,
    double? fontSize,
    EdgeInsets? padding,
    required this.onTap,
    required this.label,
  }) : color = color ?? AppColors.buttonColor,
       fontSize = fontSize ?? AppTextStyles.buttonTextTheme.fontSize!,
       padding = padding ?? EdgeInsets.all(20.0);

  final bool isLoading;

  final VoidCallback onTap;

  final String label;

  final Color color;

  final double fontSize;

  final EdgeInsets padding;

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  bool _isTapped = false;

  double randomAngle = 0.0;
  double randomScale = 0.0;

  double getRandomNumber(double min, double max) {
    final random = Random();
    return min + random.nextDouble() * (max - min);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) {
        setState(() {
          randomAngle = getRandomNumber(-0.05, 0.05);
          randomScale = getRandomNumber(0.90, 0.95);

          _isTapped = true;
        });
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      onTapUp: (details) {
        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByVector3(
            _isTapped
                ? Vector3(randomScale, randomScale, 1.0)
                : Vector3(1.0, 1.0, 1.0),
          )
          ..rotate(Vector3(0.0, 0.0, 1.0), _isTapped ? randomAngle : 0.0),
        duration: Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: widget.color,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack,
          child: widget.isLoading
              ? CircularProgressIndicator(
                  color: Colors.white,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 5.0,
                )
              : Text(
                  widget.label,
                  style: AppTextStyles.buttonTextTheme.copyWith(
                    fontSize: widget.fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
