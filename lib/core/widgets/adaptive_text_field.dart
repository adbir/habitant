import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_utils.dart';

class AdaptiveTextField extends StatelessWidget {
  final String placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;

  const AdaptiveTextField({
    super.key,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
    );
  }
}
