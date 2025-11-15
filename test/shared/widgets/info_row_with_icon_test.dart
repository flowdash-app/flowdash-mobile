import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/info_row_with_icon.dart';

void main() {
  group('InfoRowWithIcon Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.calendar_today,
              label: 'Created',
              value: '15/11/2025',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('15/11/2025'), findsOneWidget);
    });

    testWidgets('renders with subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.calendar_today,
              label: 'Created',
              value: '15/11/2025',
              subtitle: '2 days ago',
            ),
          ),
        ),
      );

      expect(find.text('Created'), findsOneWidget);
      expect(find.text('15/11/2025'), findsOneWidget);
      expect(find.text('2 days ago'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.calendar_today,
              label: 'Created',
              value: '15/11/2025',
            ),
          ),
        ),
      );

      expect(find.text('2 days ago'), findsNothing);
    });

    testWidgets('renders different icons correctly', (WidgetTester tester) async {
      const icons = [
        Icons.cloud,
        Icons.update,
        Icons.tag,
        Icons.access_time,
      ];

      for (final icon in icons) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InfoRowWithIcon(
                icon: icon,
                label: 'Test',
                value: 'Value',
              ),
            ),
          ),
        );

        expect(find.byIcon(icon), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('renders empty string values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.label,
              label: '',
              value: '',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.label), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2)); // label and value
    });

    testWidgets('handles long text gracefully', (WidgetTester tester) async {
      const longValue = 'This is a very long value that should wrap properly without causing overflow';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.description,
              label: 'Description',
              value: longValue,
            ),
          ),
        ),
      );

      expect(find.text(longValue), findsOneWidget);
    });

    testWidgets('has proper icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.calendar_today,
              label: 'Created',
              value: '15/11/2025',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.calendar_today));
      expect(icon.size, 20);
    });

    testWidgets('has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRowWithIcon(
              icon: Icons.calendar_today,
              label: 'Created',
              value: '15/11/2025',
              subtitle: '2 days ago',
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Created'));
      expect(labelText.style?.fontSize, 12);
      expect(labelText.style?.fontWeight, FontWeight.w500);

      final valueText = tester.widget<Text>(find.text('15/11/2025'));
      expect(valueText.style?.fontSize, 14);
      expect(valueText.style?.fontWeight, FontWeight.w500);

      final subtitleText = tester.widget<Text>(find.text('2 days ago'));
      expect(subtitleText.style?.fontSize, 12);
    });
  });
}

