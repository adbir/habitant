import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform_utils.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
        navigationBar: appBar as ObstructingPreferredSizeWidget?,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: body),
              if (bottomNavigationBar != null)
                SafeArea(
                  top: false,
                  child: bottomNavigationBar!,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
  }
}
