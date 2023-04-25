import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: const SafeArea(child: Placeholder()), // body: ,
    );
  }
}
