import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_utils.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onLeadingPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading: leading ?? (onLeadingPressed != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onLeadingPressed,
                child: const Icon(CupertinoIcons.back),
              )
            : null),
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
      );
    }

    return AppBar(
      title: Text(title),
      leading: leading ?? (onLeadingPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onLeadingPressed,
            )
          : null),
      actions: actions,
    );
  }
}
