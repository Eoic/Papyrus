import 'package:flutter/material.dart';

class StubPage extends StatelessWidget {
  final String title;

  const StubPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('Something'),
    //   ),
    //   floatingActionButton: FloatingActionButton(
    //     onPressed: () {  },
    //     child: Text("Hello"),
    //   ),
    //   body: SafeArea(
    //     child: Text(title)
    //   )
    // );
    // return ;
  }
}
