import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// iOS web engines may report browser chrome as part of bottom padding.
/// Preserve normal home-indicator clearance, but reject excessive padding
/// for the root navigation bar only. Native platforms are untouched.
class WebNavigationInsets extends StatelessWidget {
  const WebNavigationInsets({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return child;
    }
    final media = MediaQuery.of(context);
    // Preserve keyboard insets and all other edges. Do not manufacture
    // padding when the browser already excludes the system safe area.
    final bottom = media.padding.bottom.clamp(0.0, 34.0).toDouble();
    final viewBottom = media.viewPadding.bottom.clamp(0.0, 34.0).toDouble();
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(bottom: bottom),
        viewPadding: media.viewPadding.copyWith(bottom: viewBottom),
      ),
      child: child,
    );
  }
}
