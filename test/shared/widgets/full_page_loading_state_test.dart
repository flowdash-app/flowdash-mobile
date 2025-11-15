import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_loading_state.dart';

void main() {
  group('FullPageLoadingState Widget Tests', () {
    testWidgets('renders with no message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders with message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: 'Loading workflows...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading workflows...'), findsOneWidget);
    });

    testWidgets('is centered on screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: 'Loading...',
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('has proper message styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: 'Loading workflows...',
            ),
          ),
        ),
      );

      final messageText = tester.widget<Text>(find.text('Loading workflows...'));
      expect(messageText.style?.fontSize, 14);
      expect(messageText.style?.color, Colors.grey);
    });

    testWidgets('has 16px spacing between spinner and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: 'Loading...',
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Column),
        ),
      );
      final sizedBox = column.children[1] as SizedBox;
      expect(sizedBox.height, 16);
    });

    testWidgets('renders different messages', (WidgetTester tester) async {
      final messages = [
        'Loading workflows...',
        'Loading instances...',
        'Fetching data...',
        'Please wait...',
      ];

      for (final message in messages) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FullPageLoadingState(
                message: message,
              ),
            ),
          ),
        );

        expect(find.text(message), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pump(); // Just pump once, not pumpAndSettle
      }
    });

    testWidgets('handles empty string message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: '',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('handles long messages without overflow', (WidgetTester tester) async {
      const longMessage = 'This is a very long loading message that should display properly without causing overflow';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: longMessage,
            ),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('column has proper alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageLoadingState(
              message: 'Loading...',
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}

