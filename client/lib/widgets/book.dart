import 'package:flutter/material.dart';
import '../models/book_data.dart';

class Book extends StatelessWidget {
  final BookData data;

  const Book({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image(
                  image: AssetImage(data.coverURL),
                  fit: BoxFit.cover,
                ),
              ),

            ),
            Text(data.title, overflow: TextOverflow.ellipsis,),
            Text(data.author, overflow: TextOverflow.ellipsis,),
          ],
        ),
      ),
      // title: Text(data.title),
      // subtitle: Text(data.author),
      // onTap: () {},
      // dense: true,
    );
  }
}
