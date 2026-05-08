import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_utils.dart';

class AdaptiveLoadingIndicator extends StatelessWidget {
  final String? message;

  const AdaptiveLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class AdaptiveDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? positiveButtonLabel;
  final String? negativeButtonLabel;
  final VoidCallback? onPositive;
  final VoidCallback? onNegative;

  const AdaptiveDialog({
    super.key,
    required this.title,
    required this.message,
    this.positiveButtonLabel,
    this.negativeButtonLabel,
    this.onPositive,
    this.onNegative,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (negativeButtonLabel != null)
            CupertinoDialogAction(
              onPressed: onNegative ?? () => Navigator.pop(context),
              child: Text(negativeButtonLabel!),
            ),
          if (positiveButtonLabel != null)
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: onPositive ?? () => Navigator.pop(context),
              child: Text(positiveButtonLabel!),
            ),
        ],
      );
    }

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (negativeButtonLabel != null)
          TextButton(
            onPressed: onNegative ?? () => Navigator.pop(context),
            child: Text(negativeButtonLabel!),
          ),
        if (positiveButtonLabel != null)
          TextButton(
            onPressed: onPositive ?? () => Navigator.pop(context),
            child: Text(positiveButtonLabel!),
          ),
      ],
    );
  }
}
