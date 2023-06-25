import 'package:client/pages/stubPage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

class DrawerTile extends ListTile {
  final int index;

  const DrawerTile({
    super.key,
    required super.leading,
    required super.title,
    required super.onTap,
    required super.selected,
    required this.index,
  });
}

class ScaffoldWithDrawerTabItem {
  final Icon icon;
  final String label;
  final String initialLocation;

  const ScaffoldWithDrawerTabItem({
    required this.label,
    required this.icon,
    required this.initialLocation,
  });

  ListTile createDrawerTile({
    required int index,
    required bool selected,
    required void Function(int index) onTap
  }) {
    return DrawerTile(
      index: index,
      leading: icon,
      selected: selected,
      title: Text(label),
      onTap: () => onTap(index),
    );
  }
}

class ScaffoldWithDrawer extends StatefulWidget {
  final Widget child;
  final List<ScaffoldWithDrawerTabItem> tabs;

  const ScaffoldWithDrawer({
    super.key,
    required this.child,
    required this.tabs
  });

  @override
  State<ScaffoldWithDrawer> createState() => _ScaffoldWithDrawer();
}

class _ScaffoldWithDrawer extends State<ScaffoldWithDrawer> {
  int locationToTabIndex(String location) {
    final index = widget.tabs.indexWhere((tab) => location.startsWith(tab.initialLocation));
    return index < 0 ? 0 : index;
  }

  int get currentIndex => locationToTabIndex(GoRouter.of(context).location);

  void onItemTapped(BuildContext context, int tabIndex) {
    if (tabIndex != currentIndex) {
      // FIXME: Single pop() call to close the drawer does not work.
      context.pop();
      context.pop();
      context.go(widget.tabs[tabIndex].initialLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      appBar: AppBar(
        // title: Text(widget.addBarTitle),
        titleSpacing: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          children: widget.tabs.mapIndexed(
            (index, tab) => tab.createDrawerTile(
              index: index,
              onTap: (int index) => onItemTapped(context, index),
              selected: currentIndex == index,
            )
          ).toList(),
        ),
      ),
    );
  }
}