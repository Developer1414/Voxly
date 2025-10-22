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
    this.label,
    this.child,
  }) : assert(
         label != null || child != null,
         'ButtonWidget must have either a label or a child.',
       ),
       color = color ?? AppColors.buttonColor,
       fontSize = fontSize ?? AppTextStyles.h2Theme.fontSize!,
       padding = padding ?? const EdgeInsets.all(20.0);

  final bool isLoading;
  final VoidCallback onTap;

  final String? label;
  final Widget? child;

  final Color color;
  final double fontSize;
  final EdgeInsets padding;

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  bool _isTapped = false;

  double _randomAngle = 0.0;
  double _randomScale = 0.0;

  double getRandomNumber(double min, double max) {
    final random = Random();
    return min + random.nextDouble() * (max - min);
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const CircularProgressIndicator(
        color: Colors.white,
        strokeCap: StrokeCap.round,
        strokeWidth: 5.0,
      );
    }

    if (widget.child != null) {
      return widget.child!;
    }

    return Text(
      widget.label!,
      style: AppTextStyles.h2Theme.copyWith(fontSize: widget.fontSize),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = widget.isLoading ? null : widget.onTap;

    return GestureDetector(
      onTap: effectiveOnTap,
      onTapDown: (details) {
        if (!widget.isLoading) {
          setState(() {
            _randomAngle = getRandomNumber(-0.05, 0.05);
            _randomScale = getRandomNumber(0.90, 0.95);

            _isTapped = true;
          });
        }
      },
      onTapCancel: () {
        if (!_isTapped) return;

        setState(() {
          _isTapped = false;
        });
      },
      onTapUp: (details) {
        if (!_isTapped) return;

        setState(() {
          _isTapped = false;
        });
      },
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..scaleByVector3(
            _isTapped
                ? Vector3(_randomScale, _randomScale, 1.0)
                : Vector3(1.0, 1.0, 1.0),
          )
          ..rotate(Vector3(0.0, 0.0, 1.0), _isTapped ? _randomAngle : 0.0),
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: widget.color,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutBack,
          child: _buildContent(),
        ),
      ),
    );
  }
}
