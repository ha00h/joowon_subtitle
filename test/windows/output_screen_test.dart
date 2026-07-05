import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joowon_subtitle/windows/output/output_screen.dart';

void main() {
  testWidgets('OutputScreen hides mouse cursor', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OutputScreen()),
      ),
    );

    final mouseRegion = tester.widget<MouseRegion>(
      find.descendant(
        of: find.byType(OutputScreen),
        matching: find.byType(MouseRegion),
      ),
    );
    expect(mouseRegion.cursor, SystemMouseCursors.none);
  });
}
