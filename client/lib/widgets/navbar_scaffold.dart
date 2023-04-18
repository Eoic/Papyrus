import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBarTabItem extends BottomNavigationBarItem {
  final String initialLocation;

  ScaffoldWithNavBarTabItem({
    required this.initialLocation,
    required super.icon,
    super.label
  });
}

class ScaffoldWithBottomNavBar extends StatefulWidget {
  final Widget child;
  final List<ScaffoldWithNavBarTabItem> tabs;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.child,
    required this.tabs
  });

  @override
  State<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBar();
}

class _ScaffoldWithBottomNavBar extends State<ScaffoldWithBottomNavBar> {
  int locationToTabIndex(String location) {
    final index = widget.tabs.indexWhere((tab) => location.startsWith(tab.initialLocation));
    return index < 0 ? 0 : index;
  }

  int get currentIndex => locationToTabIndex(GoRouter.of(context).location);

  void onItemTapped(BuildContext context, int tabIndex) {
    if (tabIndex != currentIndex) {
      context.go(widget.tabs[tabIndex].initialLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        items: widget.tabs,
        onTap: (index) => onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}