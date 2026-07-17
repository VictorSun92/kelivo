import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Transparent macOS title-bar interaction strip.
///
/// Restores drag-to-move under [fullSizeContentView]. Double-click-to-zoom is
/// handled natively by TitleBarInteractionView in
/// macos/Runner/MainFlutterWindow.swift.
class MacOSTitleBarDragArea extends StatelessWidget {
  const MacOSTitleBarDragArea({super.key});

  /// Must match the title-bar height reserved by the accessory view in
  /// macos/Runner/MainFlutterWindow.swift.
  static const double defaultHeight = 40;

  @override
  Widget build(BuildContext context) {
    return const DragToMoveArea(
      child: SizedBox(height: defaultHeight, width: double.infinity),
    );
  }
}
