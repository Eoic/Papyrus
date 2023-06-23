import 'package:client/widgets/book/book.dart';
import 'package:client/widgets/search.dart';
import 'package:flutter/material.dart';

import '../models/book_data.dart';

class LibraryPage extends StatefulWidget {
  LibraryPage({ super.key });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool isSearchExpanded = false;

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
      appBar: AppBar(
        title: Text("All books"),
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => isSearchExpanded = !isSearchExpanded);
            },
            icon: const Icon(Icons.search),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.cloud_upload_rounded, size: 32,),
        shape: CircleBorder(),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("All books"),
              leading: Icon(Icons.stacked_bar_chart),
              onTap: () { print("Tapped"); },
              selected: true,
            ),
            ListTile(
              title: Text("Shelves"),
              leading: Icon(Icons.shelves),
              onTap: () { print("Shelves."); },
            ),
            ListTile(
              title: Text("Topics"),
              leading: Icon(Icons.topic),
              onTap: () { print("Topics."); },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
          child: Column(
            children: [
              if (isSearchExpanded)
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
