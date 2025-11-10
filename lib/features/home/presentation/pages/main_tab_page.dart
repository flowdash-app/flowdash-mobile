import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/home/presentation/pages/home_tab_content.dart';
import 'package:flowdash_mobile/features/workflows/presentation/pages/workflows_page.dart';
import 'package:flowdash_mobile/features/instances/presentation/pages/instances_page.dart';
import 'package:flowdash_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

class MainTabPage extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const MainTabPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends ConsumerState<MainTabPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(MainTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Log tab change analytics
    final analytics = ref.read(analyticsServiceProvider);
    final tabNames = ['home', 'workflows', 'instances', 'settings'];
    analytics.logEvent(
      name: 'tab_changed',
      parameters: {
        'tab_index': index,
        'tab_name': tabNames[index],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTabContent(),
          WorkflowsPage(),
          InstancesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        selectedFontSize: 14,
        unselectedFontSize: 12,
        selectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 24,
        ),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Workflows',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Instances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

