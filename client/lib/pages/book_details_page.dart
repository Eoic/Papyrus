import 'package:client/widgets/book/book_annotations.dart';
import 'package:client/widgets/book/book_details.dart';
import 'package:client/widgets/book/book_notes.dart';
import 'package:flutter/material.dart';

class BookDetailsPage extends StatelessWidget {
  final String? id;

  const BookDetailsPage({
    super.key,
    required this.id
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details',),
              Tab(text: 'Annotations',),
              Tab(text: 'Notes',),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookDetails(),
            BookAnnotations(),
            BookNotes(),
          ],
        ),
      ),
    );
  }
}
