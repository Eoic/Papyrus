import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:client/models/book_data.dart';

class Book extends StatefulWidget {
  final String id;
  final BookData data;

  const Book({super.key, required this.id, required this.data});

  @override
  State<Book> createState() => _BookState();
}

class _BookState extends State<Book> with SingleTickerProviderStateMixin {
  bool isFinished = false;
  late Animation animation;
  late Animation backgroundAnimation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    isFinished = widget.data.isFinished;
    animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    animation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green[500],
    ).animate(animationController)..addListener(() => setState(() {}));

    backgroundAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.green[100],
    ).animate(animationController)..addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      animationController.forward();
    } else {
      animationController.reverse();
    }

    return GridTile(
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () {
          context.pushNamed(
            'BOOK_DETAILS',
            pathParameters: {"bookId": widget.id},
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
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
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline),
                          SizedBox(width: 8),
                          Text("View details"),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isFinished = !isFinished;
                          context.pop();
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            !isFinished
                                ? Icons.check_box_outline_blank_rounded
                                : Icons.check_box_rounded,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFinished
                                ? "Mark as unfinished"
                                : "Mark as finished",
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.add_to_photos_rounded),
                          SizedBox(width: 8),
                          Text("Add to shelf"),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.download_rounded),
                          SizedBox(width: 8),
                          Text("Export"),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 8),
                          Text("Delete from library"),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
                        image: AssetImage(widget.data.coverURL),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.circle,
                        color: backgroundAnimation.value,
                        // size: 0,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        Icons.check_circle,
                        color: animation.value,
                        // size: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(widget.data.title, overflow: TextOverflow.ellipsis),
            Text(
              widget.data.author,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }
}
