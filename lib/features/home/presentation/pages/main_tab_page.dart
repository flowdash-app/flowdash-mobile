import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void didUpdateWidget(MainTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);

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

    // Navigate to corresponding route
    switch (index) {
      case 0:
        const HomeRoute().go(context);
        break;
      case 1:
        const HomeWorkflowsRoute().go(context);
        break;
      case 2:
        const HomeInstancesRoute().go(context);
        break;
      case 3:
        const HomeSettingsRoute().go(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
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

