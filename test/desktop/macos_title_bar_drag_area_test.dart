import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Kelivo/desktop/macos_title_bar_drag_area.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  testWidgets('renders a DragToMoveArea strip at the title bar height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MacOSTitleBarDragArea())),
    );

    expect(find.byType(DragToMoveArea), findsOneWidget);

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(MacOSTitleBarDragArea),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.height, MacOSTitleBarDragArea.defaultHeight);
  });
}
