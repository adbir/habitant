import 'package:flutter/material.dart';

/// Shows a [builder]-provided widget as a bottom sheet on narrow screens
/// (<640 px) and as a centred dialog on wide screens (≥640 px).
///
/// The builder receives the inner [BuildContext]. The [topPadding] compensates
/// for the drag handle that is only present in the sheet variant; pass 0 if
/// the content already manages its own top spacing.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double topPadding = 20,
}) {
  if (MediaQuery.sizeOf(context).width >= 640) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: builder(ctx),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: builder,
  );
}
