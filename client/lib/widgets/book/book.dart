import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/models/book_data.dart';

class Book extends StatelessWidget {
  final String id;
  final BookData data;

  const Book({
    super.key,
    required this.id,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          context.pushNamed('BOOK_DETAILS', params: {"bookId": id });
        },
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
            const SizedBox(height: 2,),
            Text(data.title, overflow: TextOverflow.ellipsis,),
            Text(data.author,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
