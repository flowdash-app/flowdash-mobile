import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_error_state.dart';

void main() {
  group('FullPageErrorState Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Failed to load',
              message: 'An error occurred while loading data',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('An error occurred while loading data'), findsOneWidget);
    });

    testWidgets('renders with custom icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.warning_amber,
              iconColor: Colors.orange,
              title: 'Warning',
              message: 'This is a warning message',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber));
      expect(icon.color, Colors.orange);
    });

    testWidgets('uses red[300] as default icon color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, Colors.red[300]);
    });

    testWidgets('renders with action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Failed to load',
              message: 'An error occurred',
              actionButton: ElevatedButton(
                onPressed: () {},
                child: const Text('Retry'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not render action button when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('is centered on screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      // Check that Center widget exists with Column inside
      expect(find.byType(Center), findsNWidgets(2)); // Scaffold + FullPageErrorState
      expect(find.ancestor(
        of: find.byType(Column),
        matching: find.byType(Center),
      ), findsOneWidget);
    });

    testWidgets('has proper icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 64);
    });

    testWidgets('has proper title styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Failed to load',
              message: 'Error message',
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Failed to load'));
      expect(titleText.style?.fontSize, 20);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.textAlign, TextAlign.center);
    });

    testWidgets('has proper message styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      final messageText = tester.widget<Text>(find.text('Error message'));
      expect(messageText.style?.fontSize, 14);
      expect(messageText.textAlign, TextAlign.center);
    });

    testWidgets('has 32px padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: 'Error message',
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(Column),
          matching: find.byType(Padding),
        ).first,
      );
      expect(padding.padding, const EdgeInsets.all(32.0));
    });

    testWidgets('handles long messages without overflow', (WidgetTester tester) async {
      const longMessage = 'This is a very long error message that should wrap properly across multiple lines without causing any overflow issues in the full page error state widget';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageErrorState(
              icon: Icons.error_outline,
              title: 'Error',
              message: longMessage,
            ),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

