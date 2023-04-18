import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: ElevatedButton(
        onPressed: () {
          context.go("/dashboard/details");
        },
        child: Text("Details"),
      ), // body: ,
    );
  }
}
