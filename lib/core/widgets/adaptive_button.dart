import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_utils.dart';

class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isLoading;

  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return CupertinoButton(
        onPressed: isLoading ? null : onPressed,
        color: isDestructive ? CupertinoColors.destructiveRed : null,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CupertinoActivityIndicator(),
              )
            : Text(label),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : null,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
