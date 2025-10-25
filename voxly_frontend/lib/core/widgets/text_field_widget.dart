import 'package:flutter/material.dart';
import 'package:voxly_frontend/core/themes/app_text_style.dart';

Widget textField({
  void Function(String)? onSubmitted,
  required TextEditingController controller,
  TextInputType? keyboardType,
  int? maxLines = 1,
  int? minLines,
}) {
  FocusNode focusNode = FocusNode();

  return SizedBox(
    height: 56.0,
    child: TextField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      onSubmitted: (value) {
        onSubmitted?.call(value);

        focusNode.requestFocus();
      },
      onTapOutside: (event) {
        focusNode.unfocus();
      },
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 18.0),
        filled: true,
        fillColor: Colors.transparent,
        hintText: 'Сообщение...',
        hintStyle: AppTextStyles.h3Theme.copyWith(
          fontSize: 16.0,
          color: Colors.white38,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.white38, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.white70, width: 1.5),
        ),
      ),
      style: AppTextStyles.h3Theme.copyWith(fontSize: 16.0),
    ),
  );
}
