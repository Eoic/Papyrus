import 'package:flutter/material.dart';
import 'package:papyrus/data/sample_data.dart';
import 'package:papyrus/models/book.dart' as models;
import 'package:papyrus/widgets/book/book.dart' as widgets;
import 'package:papyrus/widgets/search.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _AllBooksState();
}

class _AllBooksState extends State<BooksPage> {
  bool isSearchExpanded = false;

  late List<models.Book> books;

  @override
  void initState() {
    super.initState();
    books = SampleData.books;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All books"),
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => isSearchExpanded = !isSearchExpanded);
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        shape: const CircleBorder(),
        child: const Icon(Icons.cloud_upload_rounded, size: 32),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
          child: Column(
            children: [
              if (isSearchExpanded) const Search(),

              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  crossAxisCount: 3,
                  childAspectRatio: 0.5,
                  children: [
                    ...books
                        .asMap()
                        .map(
                          (index, data) => MapEntry(
                            index,
                            widgets.Book(id: index.toString(), data: data),
                          ),
                        )
                        .values,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
