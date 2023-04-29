import 'package:client/widgets/book/book.dart';
import 'package:client/widgets/search.dart';
import 'package:flutter/material.dart';

import '../models/book_data.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({ super.key });

  var books = [
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: true
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg",
      isFinished: false
    ),
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: false
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg",
      isFinished: true
    ),
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: true,
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg",
      isFinished: false
    ),
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: false,
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg",
      isFinished: false
    ),
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: false,
    ),
    BookData(
      title: "The Pillars of The Earth",
      author: "Ken Follet",
      coverURL: "assets/images/book_placeholder_2.jpg",
      isFinished: false,
    ),
    BookData(
      title: "The Lord of the Rings",
      author: "J. R. R. Tolkien",
      coverURL: "assets/images/book_placeholder.jpg",
      isFinished: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.upload_file_outlined, size: 32,),
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
                crossAxisCount: 3,
                childAspectRatio: 0.5,
                children: [
                  ...books
                    .asMap()
                    .map((index, data) => MapEntry(
                      index,
                      Book(id: index.toString(), data: data)
                    )
                  ).values.toList(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
