import 'package:flutter/material.dart';

/// Centers [child] in a 1920 px-capped column on large screens.
///
/// Below [_breakpoint] (840 px) the child is returned as-is. Above it the
/// child sits in a three-column Row: two equal [Spacer]s flank a [SizedBox]
/// whose width is clamped to [_maxContentWidth]. Both flanking columns are
/// invisible; only the gutters beyond 1920 px are ever visible.
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            SizedBox(
              width: constraints.maxWidth.clamp(0.0, _maxContentWidth),
              child: child,
            ),
            const Spacer(),
          ],
        );
      },
    );
  }
}
