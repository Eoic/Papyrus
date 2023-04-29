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
        onLongPress: () {
          showModalBottomSheet(
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(18.0)
              )
            ),
            context: context,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8,),
                          Text("View details")
                        ],
                      )
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.check_box_rounded),
                          SizedBox(width: 8,),
                          Text("Mark as finished")
                        ],
                      )
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.download),
                          SizedBox(width: 8,),
                          Text("Download as file")
                        ],
                      )
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8,),
                          Text("Delete from library")
                        ],
                      )
                    )
                  ],
                ),
              );
            }
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Image(
                        image: AssetImage(data.coverURL),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.check_circle,
                        color: data.isFinished ? Colors.green[500] : Colors.transparent,
                      ),
                    )
                  ],
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
