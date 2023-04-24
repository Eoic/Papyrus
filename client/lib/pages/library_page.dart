import 'package:client/widgets/book.dart';
import 'package:client/widgets/search.dart';
import 'package:flutter/material.dart';

import '../models/book_data.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({ super.key });

  var books = [
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg"
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg"
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Library")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.upload_file_outlined),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
          child: Column(
            children: [
              const Search(),
              const SizedBox(height: 12,),
              Expanded(child: GridView.count(
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: books.map((data) => Book(data: data)).toList(),
                crossAxisCount: 3,
                childAspectRatio: 0.5,
                // itemCount: books.length,
                // itemBuilder: (context, index) {
                //   return Book(data: books[index]);
                // }
              ))
            ],
          ),
        ),
      ),
    );
  }
}
