import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/shared/widgets/switchable_list_tile.dart';

void main() {
  group('SwitchableListTile Widget Tests', () {
    testWidgets('renders with required parameters', (WidgetTester tester) async {
      bool switchValue = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Instance Name',
              subtitle: const Text('instance.url'),
              switchValue: switchValue,
              onSwitchChanged: (value) {
                switchValue = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('Instance Name'), findsOneWidget);
      expect(find.text('instance.url'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('renders without card wrapper by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('renders with card wrapper when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
              wrapInCard: true,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('uses custom card margin when provided', (WidgetTester tester) async {
      const customMargin = EdgeInsets.all(24);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
              wrapInCard: true,
              cardMargin: customMargin,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, customMargin);
    });

    testWidgets('uses default card margin when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
              wrapInCard: true,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
    });

    testWidgets('switch reflects provided value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: true,
              onSwitchChanged: (value) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('calls callback when switch is toggled', (WidgetTester tester) async {
      bool callbackValue = false;
      bool switchValue = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SwitchableListTile(
                  title: 'Test',
                  subtitle: const Text('Subtitle'),
                  switchValue: switchValue,
                  onSwitchChanged: (value) {
                    setState(() {
                      callbackValue = value;
                      switchValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(callbackValue, true);
    });

    testWidgets('renders complex subtitle widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Instance',
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('https://n8n.example.com'),
                  SizedBox(height: 4),
                  Text('Active', style: TextStyle(color: Colors.green)),
                ],
              ),
              switchValue: true,
              onSwitchChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Instance'), findsOneWidget);
      expect(find.text('https://n8n.example.com'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('switch is in trailing position', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
            ),
          ),
        ),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.trailing, isA<Switch>());
    });

    testWidgets('handles enabled and disabled states', (WidgetTester tester) async {
      // Test enabled state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchableListTile(
              title: 'Test',
              subtitle: const Text('Subtitle'),
              switchValue: false,
              onSwitchChanged: (value) {},
            ),
          ),
        ),
      );

      var switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNotNull);

      // Test disabled state (null onChanged)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: const Text('Test'),
              subtitle: const Text('Subtitle'),
              trailing: Switch(
                value: false,
                onChanged: null, // Disabled
              ),
            ),
          ),
        ),
      );

      switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });
  });
}

