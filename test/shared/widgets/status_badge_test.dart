import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/status_badge.dart';

void main() {
  group('StatusBadge Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Success',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('Success'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders with custom padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Running',
              statusColor: Colors.blue,
              statusIcon: Icons.play_circle_outline,
              padding: EdgeInsets.all(16),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container),
      );
      expect(container.padding, const EdgeInsets.all(16));
    });

    testWidgets('uses default padding when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Error',
              statusColor: Colors.red,
              statusIcon: Icons.error_outline,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container),
      );
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    });

    testWidgets('renders different statuses correctly', (WidgetTester tester) async {
      final statuses = [
        ('Success', Colors.green, Icons.check_circle_outline),
        ('Error', Colors.red, Icons.error_outline),
        ('Running', Colors.blue, Icons.play_circle_outline),
        ('Waiting', Colors.orange, Icons.schedule),
        ('Canceled', Colors.grey, Icons.cancel_outlined),
      ];

      for (final (text, color, icon) in statuses) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusBadge(
                statusText: text,
                statusColor: color,
                statusIcon: icon,
              ),
            ),
          ),
        );

        expect(find.text(text), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, color.withOpacity(0.1));
        expect(decoration.border?.top.color, color);

        await tester.pumpAndSettle();
      }
    });

    testWidgets('has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Success',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('has proper icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Success',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
      expect(icon.size, 20);
      expect(icon.color, Colors.green);
    });

    testWidgets('has proper text styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Success',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Success'));
      expect(text.style?.fontSize, 14);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.color, Colors.green);
    });

    testWidgets('uses Row for layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              statusText: 'Success',
              statusColor: Colors.green,
              statusIcon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisSize, MainAxisSize.min);
    });
  });
}

