import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/section_header.dart';

void main() {
  group('SectionHeader Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
            ),
          ),
        ),
      );

      expect(find.text('Workflows'), findsOneWidget);
    });

    testWidgets('renders with subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              subtitle: 'Automated workflows from your n8n instance',
            ),
          ),
        ),
      );

      expect(find.text('Workflows'), findsOneWidget);
      expect(find.text('Automated workflows from your n8n instance'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
            ),
          ),
        ),
      );

      expect(find.text('Automated workflows'), findsNothing);
    });

    testWidgets('renders with action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              actionButton: TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('View All'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('does not render action button when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders with both subtitle and action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              subtitle: 'Automated workflows',
              actionButton: TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Workflows'), findsOneWidget);
      expect(find.text('Automated workflows'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('has proper title styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Workflows'));
      expect(titleText.style?.fontSize, 20);
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('has proper subtitle styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              subtitle: 'Automated workflows',
            ),
          ),
        ),
      );

      final subtitleText = tester.widget<Text>(find.text('Automated workflows'));
      expect(subtitleText.style?.fontSize, 12);
      expect(subtitleText.style?.color, Colors.grey);
    });

    testWidgets('uses Row for layout with proper alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              actionButton: TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('title column has proper alignment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('handles long titles without overflow', (WidgetTester tester) async {
      const longTitle = 'This is a very long section title that should wrap properly';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: longTitle,
            ),
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles long subtitles without overflow', (WidgetTester tester) async {
      const longSubtitle = 'This is a very long section subtitle that should wrap properly without causing any issues';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Title',
              subtitle: longSubtitle,
            ),
          ),
        ),
      );

      expect(find.text(longSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('action button tap is responsive', (WidgetTester tester) async {
      bool buttonTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              actionButton: TextButton(
                onPressed: () {
                  buttonTapped = true;
                },
                child: const Text('View All'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(buttonTapped, true);
    });

    testWidgets('has 4px spacing between title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Workflows',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(Column),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 4);
    });
  });
}

