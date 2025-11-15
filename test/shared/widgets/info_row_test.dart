import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/info_row.dart';

void main() {
  group('InfoRow Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Status',
              value: 'Active',
            ),
          ),
        ),
      );

      expect(find.text('Status:'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders with custom label width', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Status',
              value: 'Active',
              labelWidth: 150,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.text('Status:'),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 150);
    });

    testWidgets('uses default label width when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Status',
              value: 'Active',
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.text('Status:'),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 100);
    });

    testWidgets('renders empty string values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Empty',
              value: '',
            ),
          ),
        ),
      );

      expect(find.text('Empty:'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('renders long text values', (WidgetTester tester) async {
      const longValue = 'This is a very long text value that should wrap properly when displayed in the info row widget without causing overflow issues';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Long Text',
              value: longValue,
            ),
          ),
        ),
      );

      expect(find.text('Long Text:'), findsOneWidget);
      expect(find.text(longValue), findsOneWidget);
    });

    testWidgets('uses SelectableText for value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'ID',
              value: '12345',
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Status',
              value: 'Active',
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Status:'));
      expect(labelText.style?.fontSize, 12);
      expect(labelText.style?.fontWeight, FontWeight.w500);

      final valueText = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(valueText.style?.fontSize, 12);
    });
  });
}

