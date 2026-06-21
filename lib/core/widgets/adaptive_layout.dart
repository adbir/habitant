import 'package:flutter/material.dart';

/// Constrains [child] to 1920 px on large screens; returned as-is below 840 px.
class AdaptiveLayout extends StatelessWidget {
  final Widget child;

  const AdaptiveLayout({super.key, required this.child});

  static const double _breakpoint = 840;
  static const double _maxContentWidth = 1920;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) return child;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: child,
          ),
        );
      },
    );
  }
}
