import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_empty_state.dart';

void main() {
  group('FullPageEmptyState Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.text('No workflows found'), findsOneWidget);
      expect(find.text('Create workflows to get started'), findsOneWidget);
    });

    testWidgets('renders with action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
              actionButton: ElevatedButton(
                onPressed: () {},
                child: const Text('Add Workflow'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add Workflow'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not render action button when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
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
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
            ),
          ),
        ),
      );

      // Check that Center widget exists with Column inside
      expect(find.byType(Center), findsNWidgets(2)); // Scaffold + FullPageEmptyState
      expect(find.ancestor(
        of: find.byType(Column),
        matching: find.byType(Center),
      ), findsOneWidget);
    });

    testWidgets('has proper icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.work_outline));
      expect(icon.size, 64);
    });

    testWidgets('has proper title styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
            ),
          ),
        ),
      );

      final titleFinder = find.text('No workflows found');
      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.fontSize, 20);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.textAlign, TextAlign.center);
    });

    testWidgets('has proper message styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
            ),
          ),
        ),
      );

      final messageFinder = find.text('Create workflows to get started');
      final messageText = tester.widget<Text>(messageFinder);
      expect(messageText.style?.fontSize, 14);
      expect(messageText.textAlign, TextAlign.center);
    });

    testWidgets('has 32px padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
              message: 'Create workflows to get started',
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
      const longMessage = 'This is a very long message that should wrap properly across multiple lines without causing any overflow issues in the full page empty state widget';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FullPageEmptyState(
              icon: Icons.work_outline,
              title: 'No workflows found',
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

