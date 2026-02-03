import 'package:flutter/material.dart';
import 'package:papyrus/models/annotation.dart';
import 'package:papyrus/models/book.dart';
import 'package:papyrus/models/book_shelf_relation.dart';
import 'package:papyrus/models/book_tag_relation.dart';
import 'package:papyrus/models/bookmark.dart';
import 'package:papyrus/models/note.dart';
import 'package:papyrus/models/reading_goal.dart';
import 'package:papyrus/models/reading_session.dart';
import 'package:papyrus/models/series.dart';
import 'package:papyrus/models/shelf.dart';
import 'package:papyrus/models/tag.dart';

/// Comprehensive sample data for development and testing.
class SampleData {
  SampleData._();

  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));
  static DateTime _hoursAgo(int hours) =>
      DateTime.now().subtract(Duration(hours: hours));

  // ============================================================
  // Books (15 books)
  // ============================================================

  static List<Book> get books {
    return [
      Book(
        id: 'book-1',
        title: 'The Pragmatic Programmer',
        subtitle: 'Your Journey to Mastery',
        author: 'David Thomas',
        coAuthors: ['Andrew Hunt'],
        isbn13: '978-0135957059',
        publicationDate: DateTime(2019, 9, 13),
        publisher: 'Addison-Wesley Professional',
        language: 'en',
        pageCount: 352,
        description:
            'The Pragmatic Programmer is one of those rare tech books you\'ll read, re-read, and read again over the years.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 264,
        currentPosition: 0.75,
        isFavorite: true,
        rating: 5,
        addedAt: _daysAgo(90),
        startedAt: _daysAgo(30),
        lastReadAt: _hoursAgo(2),
      ),
      Book(
        id: 'book-2',
        title: 'Clean Code',
        subtitle: 'A Handbook of Agile Software Craftsmanship',
        author: 'Robert C. Martin',
        isbn13: '978-0132350884',
        publicationDate: DateTime(2008, 8, 1),
        publisher: 'Prentice Hall',
        language: 'en',
        pageCount: 464,
        description:
            'Even bad code can function. But if code isn\'t clean, it can bring a development organization to its knees.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
        fileFormat: BookFormat.pdf,
        readingStatus: ReadingStatus.completed,
        currentPage: 464,
        currentPosition: 1.0,
        isFavorite: true,
        rating: 5,
        addedAt: _daysAgo(180),
        startedAt: _daysAgo(120),
        completedAt: _daysAgo(60),
        lastReadAt: _daysAgo(60),
      ),
      Book(
        id: 'book-3',
        title: 'Dune',
        author: 'Frank Herbert',
        isbn13: '978-0441172719',
        publicationDate: DateTime(1965, 8, 1),
        publisher: 'Ace',
        language: 'en',
        pageCount: 688,
        description:
            'Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 310,
        currentPosition: 0.45,
        seriesId: 'series-1',
        seriesNumber: 1,
        addedAt: _daysAgo(60),
        startedAt: _daysAgo(14),
        lastReadAt: _daysAgo(1),
      ),
      Book(
        id: 'book-4',
        title: '1984',
        author: 'George Orwell',
        isbn13: '978-0451524935',
        publicationDate: DateTime(1949, 6, 8),
        publisher: 'Signet Classic',
        language: 'en',
        pageCount: 328,
        description:
            'Among the seminal texts of the 20th century, Nineteen Eighty-Four is a rare work that grows more haunting as its futuristic purgatory becomes more real.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
        isPhysical: true,
        physicalLocation: 'Bookshelf A, Row 2',
        readingStatus: ReadingStatus.completed,
        currentPage: 328,
        currentPosition: 1.0,
        rating: 4,
        addedAt: _daysAgo(365),
        startedAt: _daysAgo(300),
        completedAt: _daysAgo(280),
        lastReadAt: _daysAgo(280),
      ),
      Book(
        id: 'book-5',
        title: 'Design Patterns',
        subtitle: 'Elements of Reusable Object-Oriented Software',
        author: 'Erich Gamma',
        coAuthors: ['Richard Helm', 'Ralph Johnson', 'John Vlissides'],
        isbn13: '978-0201633610',
        publicationDate: DateTime(1994, 10, 31),
        publisher: 'Addison-Wesley Professional',
        language: 'en',
        pageCount: 416,
        description:
            'Capturing a wealth of experience about the design of object-oriented software, four top-notch designers present a catalog of simple and succinct solutions.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
        fileFormat: BookFormat.pdf,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 83,
        currentPosition: 0.2,
        addedAt: _daysAgo(45),
        startedAt: _daysAgo(21),
        lastReadAt: _daysAgo(7),
      ),
      Book(
        id: 'book-6',
        title: 'The Hobbit',
        author: 'J.R.R. Tolkien',
        isbn13: '978-0547928227',
        publicationDate: DateTime(1937, 9, 21),
        publisher: 'Mariner Books',
        language: 'en',
        pageCount: 300,
        description:
            'Bilbo Baggins is a hobbit who enjoys a comfortable, unambitious life, rarely traveling any farther than his pantry or cellar.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        isFavorite: true,
        seriesId: 'series-2',
        seriesNumber: 0,
        addedAt: _daysAgo(30),
      ),
      Book(
        id: 'book-7',
        title: 'Refactoring',
        subtitle: 'Improving the Design of Existing Code',
        author: 'Martin Fowler',
        isbn13: '978-0134757599',
        publicationDate: DateTime(2018, 11, 20),
        publisher: 'Addison-Wesley Professional',
        language: 'en',
        pageCount: 448,
        description:
            'For more than twenty years, experienced programmers worldwide have relied on Martin Fowler\'s Refactoring to improve the design of existing code.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386925632i/44936.jpg',
        fileFormat: BookFormat.mobi,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 269,
        currentPosition: 0.6,
        addedAt: _daysAgo(60),
        startedAt: _daysAgo(30),
        lastReadAt: _daysAgo(3),
      ),
      Book(
        id: 'book-8',
        title: 'Sapiens',
        subtitle: 'A Brief History of Humankind',
        author: 'Yuval Noah Harari',
        isbn13: '978-0062316097',
        publicationDate: DateTime(2015, 2, 10),
        publisher: 'Harper',
        language: 'en',
        pageCount: 464,
        description:
            '100,000 years ago, at least six human species inhabited the earth. Today there is just one. Us. Homo sapiens.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 394,
        currentPosition: 0.85,
        isFavorite: true,
        rating: 5,
        addedAt: _daysAgo(45),
        startedAt: _daysAgo(21),
        lastReadAt: _hoursAgo(5),
      ),
      Book(
        id: 'book-9',
        title: 'Neuromancer',
        author: 'William Gibson',
        isbn13: '978-0441569595',
        publicationDate: DateTime(1984, 7, 1),
        publisher: 'Ace',
        language: 'en',
        pageCount: 271,
        description:
            'The Matrix is a world within the world, a global consensus-hallucination, the representation of every byte of data in cyberspace.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        addedAt: _daysAgo(14),
      ),
      Book(
        id: 'book-10',
        title: 'Atomic Habits',
        subtitle: 'An Easy & Proven Way to Build Good Habits & Break Bad Ones',
        author: 'James Clear',
        isbn13: '978-0735211292',
        publicationDate: DateTime(2018, 10, 16),
        publisher: 'Avery',
        language: 'en',
        pageCount: 320,
        description:
            'No matter your goals, Atomic Habits offers a proven framework for improving—every day.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
        isPhysical: true,
        physicalLocation: 'Bookshelf B, Row 1',
        readingStatus: ReadingStatus.completed,
        currentPage: 320,
        currentPosition: 1.0,
        isFavorite: true,
        rating: 5,
        addedAt: _daysAgo(200),
        startedAt: _daysAgo(180),
        completedAt: _daysAgo(150),
        lastReadAt: _daysAgo(150),
      ),
      Book(
        id: 'book-11',
        title: 'The Linux Command Line',
        subtitle: 'A Complete Introduction',
        author: 'William Shotts',
        isbn13: '978-1593279523',
        publicationDate: DateTime(2019, 3, 5),
        publisher: 'No Starch Press',
        language: 'en',
        pageCount: 480,
        description:
            'The Linux Command Line takes you from your very first terminal keystrokes to writing full programs in Bash.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436.jpg',
        fileFormat: BookFormat.pdf,
        readingStatus: ReadingStatus.inProgress,
        currentPage: 144,
        currentPosition: 0.3,
        addedAt: _daysAgo(90),
        startedAt: _daysAgo(60),
        lastReadAt: _daysAgo(14),
      ),
      Book(
        id: 'book-12',
        title: 'Foundation',
        author: 'Isaac Asimov',
        isbn13: '978-0553293357',
        publicationDate: DateTime(1951, 5, 1),
        publisher: 'Spectra',
        language: 'en',
        pageCount: 244,
        description:
            'For twelve thousand years the Galactic Empire has ruled supreme. Now it is dying. But only Hari Seldon, creator of the revolutionary science of psychohistory, can see into the future.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        seriesId: 'series-3',
        seriesNumber: 1,
        addedAt: _daysAgo(7),
      ),
      Book(
        id: 'book-13',
        title: 'Dune Messiah',
        author: 'Frank Herbert',
        isbn13: '978-0593098233',
        publicationDate: DateTime(1969, 6, 1),
        publisher: 'Ace',
        language: 'en',
        pageCount: 352,
        description:
            'Dune Messiah continues the story of Paul Atreides, better known as Muad\'Dib, and his reign as emperor of the known universe.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1472680751i/44492285.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        seriesId: 'series-1',
        seriesNumber: 2,
        addedAt: _daysAgo(7),
      ),
      Book(
        id: 'book-14',
        title: 'Children of Dune',
        author: 'Frank Herbert',
        isbn13: '978-0593098240',
        publicationDate: DateTime(1976, 4, 1),
        publisher: 'Ace',
        language: 'en',
        pageCount: 444,
        description:
            'The children of Paul Atreides awaken to their own destiny as their father\'s empire begins to fragment and crumble.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1564063404i/44492286.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        seriesId: 'series-1',
        seriesNumber: 3,
        addedAt: _daysAgo(7),
      ),
      Book(
        id: 'book-15',
        title: 'The Two Towers',
        author: 'J.R.R. Tolkien',
        isbn13: '978-0547928203',
        publicationDate: DateTime(1954, 11, 11),
        publisher: 'Mariner Books',
        language: 'en',
        pageCount: 352,
        description:
            'The Fellowship was scattered. Some were bracing hopelessly for war against the ancient evil of Sauron.',
        coverUrl:
            'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071217i/15241.jpg',
        fileFormat: BookFormat.epub,
        readingStatus: ReadingStatus.notStarted,
        currentPosition: 0.0,
        seriesId: 'series-2',
        seriesNumber: 2,
        addedAt: _daysAgo(30),
      ),
    ];
  }

  // ============================================================
  // Shelves (8 shelves: 3 default + 5 custom)
  // ============================================================

  static List<Shelf> get shelves {
    final now = DateTime.now();
    return [
      Shelf(
        id: 'shelf-1',
        name: 'Currently reading',
        description: 'Books I am reading right now',
        colorHex: '#4CAF50',
        icon: Icons.menu_book,
        isDefault: true,
        sortOrder: 0,
        bookCount: 4,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386925632i/44936.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: _hoursAgo(2),
      ),
      Shelf(
        id: 'shelf-2',
        name: 'Want to read',
        description: 'My reading backlog',
        colorHex: '#2196F3',
        icon: Icons.bookmark_outline,
        isDefault: true,
        sortOrder: 1,
        bookCount: 6,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1472680751i/44492285.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: _daysAgo(1),
      ),
      Shelf(
        id: 'shelf-3',
        name: 'Finished',
        description: 'Books I have completed',
        colorHex: '#9C27B0',
        icon: Icons.check_circle_outline,
        isDefault: true,
        sortOrder: 2,
        bookCount: 3,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: _daysAgo(7),
      ),
      Shelf(
        id: 'shelf-4',
        name: 'Technical',
        description: 'Programming and software development books',
        colorHex: '#FF9800',
        icon: Icons.code,
        sortOrder: 3,
        bookCount: 5,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1401432508i/4099.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436202607i/3735293.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386925632i/44936.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: _daysAgo(3),
      ),
      Shelf(
        id: 'shelf-5',
        name: 'Fiction',
        description: 'Novels and fiction books',
        colorHex: '#E91E63',
        icon: Icons.auto_stories,
        sortOrder: 4,
        bookCount: 4,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071216i/5907.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1546071217i/15241.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: _daysAgo(5),
      ),
      Shelf(
        id: 'shelf-6',
        name: 'Sci-Fi',
        description: 'Science fiction and space opera',
        colorHex: '#00BCD4',
        icon: Icons.rocket_launch,
        sortOrder: 5,
        bookCount: 5,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554437249i/6088007.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417900846i/29579.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1472680751i/44492285.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: _daysAgo(10),
      ),
      Shelf(
        id: 'shelf-7',
        name: 'Non-Fiction',
        description: 'History, science, and self-help',
        colorHex: '#795548',
        icon: Icons.school,
        sortOrder: 6,
        bookCount: 2,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1655988385i/40121378.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: _daysAgo(5),
      ),
      Shelf(
        id: 'shelf-8',
        name: 'Reference',
        description: 'Books for quick reference and lookup',
        colorHex: '#607D8B',
        icon: Icons.library_books,
        sortOrder: 7,
        bookCount: 2,
        coverPreviewUrls: [
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348027904i/85009.jpg',
          'https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1344692678i/11724436.jpg',
        ],
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: _daysAgo(14),
      ),
    ];
  }

  // ============================================================
  // Tags (5 tags / topics)
  // ============================================================

  static List<Tag> get tags {
    return [
      Tag(
        id: 'tag-1',
        name: 'Programming',
        colorHex: '#FF9800',
        description: 'Software development and coding',
        createdAt: _daysAgo(90),
      ),
      Tag(
        id: 'tag-2',
        name: 'Science Fiction',
        colorHex: '#00BCD4',
        description: 'Sci-fi novels and stories',
        createdAt: _daysAgo(90),
      ),
      Tag(
        id: 'tag-3',
        name: 'Classic',
        colorHex: '#795548',
        description: 'Timeless literary works',
        createdAt: _daysAgo(90),
      ),
      Tag(
        id: 'tag-4',
        name: 'Productivity',
        colorHex: '#4CAF50',
        description: 'Self-improvement and habits',
        createdAt: _daysAgo(60),
      ),
      Tag(
        id: 'tag-5',
        name: 'Fantasy',
        colorHex: '#9C27B0',
        description: 'Fantasy novels and world-building',
        createdAt: _daysAgo(45),
      ),
    ];
  }

  // ============================================================
  // Series (3 series)
  // ============================================================

  static List<Series> get seriesList {
    return [
      Series(
        id: 'series-1',
        name: 'Dune',
        description:
            'The epic science fiction saga set on the desert planet Arrakis',
        author: 'Frank Herbert',
        totalBooks: 6,
        isComplete: true,
        createdAt: _daysAgo(60),
        updatedAt: _daysAgo(7),
      ),
      Series(
        id: 'series-2',
        name: 'The Lord of the Rings',
        description: 'The classic fantasy trilogy by J.R.R. Tolkien',
        author: 'J.R.R. Tolkien',
        totalBooks: 3,
        isComplete: true,
        createdAt: _daysAgo(30),
        updatedAt: _daysAgo(30),
      ),
      Series(
        id: 'series-3',
        name: 'Foundation',
        description: 'Isaac Asimov\'s epic science fiction series',
        author: 'Isaac Asimov',
        totalBooks: 7,
        isComplete: true,
        createdAt: _daysAgo(7),
        updatedAt: _daysAgo(7),
      ),
    ];
  }

  // ============================================================
  // Book-Shelf Relations
  // ============================================================

  static List<BookShelfRelation> get bookShelfRelations {
    return [
      // Currently reading (shelf-1)
      BookShelfRelation(
        bookId: 'book-1',
        shelfId: 'shelf-1',
        addedAt: _daysAgo(30),
      ),
      BookShelfRelation(
        bookId: 'book-3',
        shelfId: 'shelf-1',
        addedAt: _daysAgo(14),
      ),
      BookShelfRelation(
        bookId: 'book-7',
        shelfId: 'shelf-1',
        addedAt: _daysAgo(30),
      ),
      BookShelfRelation(
        bookId: 'book-8',
        shelfId: 'shelf-1',
        addedAt: _daysAgo(21),
      ),

      // Want to read (shelf-2)
      BookShelfRelation(
        bookId: 'book-6',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(30),
      ),
      BookShelfRelation(
        bookId: 'book-9',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(14),
      ),
      BookShelfRelation(
        bookId: 'book-12',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(7),
      ),
      BookShelfRelation(
        bookId: 'book-13',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(7),
      ),
      BookShelfRelation(
        bookId: 'book-14',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(7),
      ),
      BookShelfRelation(
        bookId: 'book-15',
        shelfId: 'shelf-2',
        addedAt: _daysAgo(30),
      ),

      // Finished (shelf-3)
      BookShelfRelation(
        bookId: 'book-2',
        shelfId: 'shelf-3',
        addedAt: _daysAgo(60),
      ),
      BookShelfRelation(
        bookId: 'book-4',
        shelfId: 'shelf-3',
        addedAt: _daysAgo(280),
      ),
      BookShelfRelation(
        bookId: 'book-10',
        shelfId: 'shelf-3',
        addedAt: _daysAgo(150),
      ),

      // Technical (shelf-4)
      BookShelfRelation(
        bookId: 'book-1',
        shelfId: 'shelf-4',
        addedAt: _daysAgo(90),
      ),
      BookShelfRelation(
        bookId: 'book-2',
        shelfId: 'shelf-4',
        addedAt: _daysAgo(180),
      ),
      BookShelfRelation(
        bookId: 'book-5',
        shelfId: 'shelf-4',
        addedAt: _daysAgo(45),
      ),
      BookShelfRelation(
        bookId: 'book-7',
        shelfId: 'shelf-4',
        addedAt: _daysAgo(60),
      ),
      BookShelfRelation(
        bookId: 'book-11',
        shelfId: 'shelf-4',
        addedAt: _daysAgo(90),
      ),

      // Fiction (shelf-5)
      BookShelfRelation(
        bookId: 'book-3',
        shelfId: 'shelf-5',
        addedAt: _daysAgo(60),
      ),
      BookShelfRelation(
        bookId: 'book-4',
        shelfId: 'shelf-5',
        addedAt: _daysAgo(365),
      ),
      BookShelfRelation(
        bookId: 'book-6',
        shelfId: 'shelf-5',
        addedAt: _daysAgo(30),
      ),
      BookShelfRelation(
        bookId: 'book-15',
        shelfId: 'shelf-5',
        addedAt: _daysAgo(30),
      ),

      // Sci-Fi (shelf-6)
      BookShelfRelation(
        bookId: 'book-3',
        shelfId: 'shelf-6',
        addedAt: _daysAgo(60),
      ),
      BookShelfRelation(
        bookId: 'book-9',
        shelfId: 'shelf-6',
        addedAt: _daysAgo(14),
      ),
      BookShelfRelation(
        bookId: 'book-12',
        shelfId: 'shelf-6',
        addedAt: _daysAgo(7),
      ),
      BookShelfRelation(
        bookId: 'book-13',
        shelfId: 'shelf-6',
        addedAt: _daysAgo(7),
      ),
      BookShelfRelation(
        bookId: 'book-14',
        shelfId: 'shelf-6',
        addedAt: _daysAgo(7),
      ),

      // Non-Fiction (shelf-7)
      BookShelfRelation(
        bookId: 'book-8',
        shelfId: 'shelf-7',
        addedAt: _daysAgo(45),
      ),
      BookShelfRelation(
        bookId: 'book-10',
        shelfId: 'shelf-7',
        addedAt: _daysAgo(200),
      ),

      // Reference (shelf-8)
      BookShelfRelation(
        bookId: 'book-5',
        shelfId: 'shelf-8',
        addedAt: _daysAgo(45),
      ),
      BookShelfRelation(
        bookId: 'book-11',
        shelfId: 'shelf-8',
        addedAt: _daysAgo(90),
      ),
    ];
  }

  // ============================================================
  // Book-Tag Relations
  // ============================================================

  static List<BookTagRelation> get bookTagRelations {
    return [
      // Programming (tag-1)
      BookTagRelation(
        bookId: 'book-1',
        tagId: 'tag-1',
        createdAt: _daysAgo(90),
      ),
      BookTagRelation(
        bookId: 'book-2',
        tagId: 'tag-1',
        createdAt: _daysAgo(180),
      ),
      BookTagRelation(
        bookId: 'book-5',
        tagId: 'tag-1',
        createdAt: _daysAgo(45),
      ),
      BookTagRelation(
        bookId: 'book-7',
        tagId: 'tag-1',
        createdAt: _daysAgo(60),
      ),
      BookTagRelation(
        bookId: 'book-11',
        tagId: 'tag-1',
        createdAt: _daysAgo(90),
      ),

      // Science Fiction (tag-2)
      BookTagRelation(
        bookId: 'book-3',
        tagId: 'tag-2',
        createdAt: _daysAgo(60),
      ),
      BookTagRelation(
        bookId: 'book-9',
        tagId: 'tag-2',
        createdAt: _daysAgo(14),
      ),
      BookTagRelation(
        bookId: 'book-12',
        tagId: 'tag-2',
        createdAt: _daysAgo(7),
      ),
      BookTagRelation(
        bookId: 'book-13',
        tagId: 'tag-2',
        createdAt: _daysAgo(7),
      ),
      BookTagRelation(
        bookId: 'book-14',
        tagId: 'tag-2',
        createdAt: _daysAgo(7),
      ),

      // Classic (tag-3)
      BookTagRelation(
        bookId: 'book-3',
        tagId: 'tag-3',
        createdAt: _daysAgo(60),
      ),
      BookTagRelation(
        bookId: 'book-4',
        tagId: 'tag-3',
        createdAt: _daysAgo(365),
      ),
      BookTagRelation(
        bookId: 'book-6',
        tagId: 'tag-3',
        createdAt: _daysAgo(30),
      ),
      BookTagRelation(
        bookId: 'book-12',
        tagId: 'tag-3',
        createdAt: _daysAgo(7),
      ),

      // Productivity (tag-4)
      BookTagRelation(
        bookId: 'book-10',
        tagId: 'tag-4',
        createdAt: _daysAgo(200),
      ),

      // Fantasy (tag-5)
      BookTagRelation(
        bookId: 'book-6',
        tagId: 'tag-5',
        createdAt: _daysAgo(30),
      ),
      BookTagRelation(
        bookId: 'book-15',
        tagId: 'tag-5',
        createdAt: _daysAgo(30),
      ),
    ];
  }

  // ============================================================
  // Annotations
  // ============================================================

  static List<Annotation> get annotations {
    return [
      // Book 1: The Pragmatic Programmer
      Annotation(
        id: 'ann-1',
        bookId: 'book-1',
        selectedText:
            'There are two ways of constructing a software design: One way is to make it so simple that there are obviously no deficiencies.',
        color: HighlightColor.yellow,
        location: const BookLocation(
          chapter: 1,
          chapterTitle: 'A Pragmatic Philosophy',
          pageNumber: 15,
          percentage: 0.05,
        ),
        note: 'Great insight about software design approaches',
        createdAt: _daysAgo(25),
      ),
      Annotation(
        id: 'ann-2',
        bookId: 'book-1',
        selectedText:
            'Don\'t live with broken windows. Fix bad designs, wrong decisions, and poor code when you see them.',
        color: HighlightColor.green,
        location: const BookLocation(
          chapter: 1,
          chapterTitle: 'A Pragmatic Philosophy',
          pageNumber: 23,
          percentage: 0.08,
        ),
        createdAt: _daysAgo(24),
      ),
      Annotation(
        id: 'ann-3',
        bookId: 'book-1',
        selectedText:
            'DRY—Don\'t Repeat Yourself. Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.',
        color: HighlightColor.pink,
        location: const BookLocation(
          chapter: 2,
          pageNumber: 58,
          percentage: 0.19,
        ),
        createdAt: _daysAgo(20),
      ),

      // Book 2: Clean Code
      Annotation(
        id: 'ann-4',
        bookId: 'book-2',
        selectedText:
            'Clean code is simple and direct. Clean code reads like well-written prose.',
        color: HighlightColor.yellow,
        location: const BookLocation(
          chapter: 1,
          chapterTitle: 'Clean Code',
          pageNumber: 12,
          percentage: 0.03,
        ),
        createdAt: _daysAgo(90),
      ),
      Annotation(
        id: 'ann-5',
        bookId: 'book-2',
        selectedText:
            'The ratio of time spent reading versus writing is well over 10 to 1.',
        color: HighlightColor.orange,
        location: const BookLocation(
          chapter: 1,
          pageNumber: 18,
          percentage: 0.05,
        ),
        note: 'This is why readability matters so much',
        createdAt: _daysAgo(88),
      ),

      // Book 3: Dune
      Annotation(
        id: 'ann-6',
        bookId: 'book-3',
        selectedText:
            'I must not fear. Fear is the mind-killer. Fear is the little-death that brings total obliteration.',
        color: HighlightColor.purple,
        location: const BookLocation(
          chapter: 1,
          pageNumber: 8,
          percentage: 0.01,
        ),
        note: 'The Litany Against Fear - iconic!',
        createdAt: _daysAgo(12),
      ),
    ];
  }

  // ============================================================
  // Notes
  // ============================================================

  static List<Note> get notes {
    return [
      Note(
        id: 'note-1',
        bookId: 'book-1',
        title: 'Key Takeaways from Chapter 1',
        content:
            'The pragmatic philosophy emphasizes taking responsibility for your work and career. Key points:\n\n'
            '• Own your mistakes and learn from them\n'
            '• Don\'t make excuses, provide solutions\n'
            '• Be a catalyst for change\n'
            '• Remember the big picture while working on details',
        tags: ['summary', 'important'],
        isPinned: true,
        createdAt: _daysAgo(25),
        updatedAt: _daysAgo(20),
      ),
      Note(
        id: 'note-2',
        bookId: 'book-1',
        title: 'DRY Principle Applications',
        content:
            'Ways to apply the DRY principle in daily coding:\n\n'
            '1. Extract common logic into functions\n'
            '2. Use configuration files instead of hardcoded values\n'
            '3. Create reusable components\n'
            '4. Avoid copy-paste coding\n'
            '5. Document decisions in one place',
        location: const BookLocation(chapter: 2, pageNumber: 58),
        tags: ['principle', 'practice'],
        createdAt: _daysAgo(20),
      ),
      Note(
        id: 'note-3',
        bookId: 'book-2',
        title: 'Naming Conventions Checklist',
        content:
            'When naming variables, functions, and classes:\n\n'
            '□ Use intention-revealing names\n'
            '□ Avoid disinformation\n'
            '□ Make meaningful distinctions\n'
            '□ Use pronounceable names\n'
            '□ Use searchable names\n'
            '□ Avoid encodings',
        tags: ['checklist', 'naming'],
        createdAt: _daysAgo(85),
      ),
    ];
  }

  // ============================================================
  // Bookmarks
  // ============================================================

  static List<Bookmark> get bookmarks {
    return [
      Bookmark(
        id: 'bm-1',
        bookId: 'book-1',
        position: 0.75,
        pageNumber: 264,
        chapterTitle: 'Chapter 5: Bend, or Break',
        note: 'Current reading position',
        createdAt: _hoursAgo(2),
      ),
      Bookmark(
        id: 'bm-2',
        bookId: 'book-3',
        position: 0.45,
        pageNumber: 310,
        chapterTitle: 'The Sleeper Awakes',
        createdAt: _daysAgo(1),
      ),
      Bookmark(
        id: 'bm-3',
        bookId: 'book-8',
        position: 0.85,
        pageNumber: 394,
        note: 'Left off here',
        colorHex: '#4CAF50',
        createdAt: _hoursAgo(5),
      ),
    ];
  }

  // ============================================================
  // Reading Sessions (30+ sessions over past month)
  // ============================================================

  static List<ReadingSession> get readingSessions {
    final sessions = <ReadingSession>[];
    var sessionId = 1;

    // Generate sessions for the past 30 days
    for (var day = 0; day < 30; day++) {
      final date = _daysAgo(day);

      // Skip some days to make it realistic
      if (day % 7 == 6) continue; // Skip Sundays
      if (day == 5 || day == 12 || day == 19) continue; // Random skips

      // Morning session (book-1 or book-8)
      if (day % 2 == 0) {
        final startTime = DateTime(date.year, date.month, date.day, 7, 30);
        sessions.add(
          ReadingSession(
            id: 'session-${sessionId++}',
            bookId: day % 4 == 0 ? 'book-8' : 'book-1',
            startTime: startTime,
            endTime: startTime.add(Duration(minutes: 25 + (day % 15))),
            startPosition: 0.6 + (day * 0.005),
            endPosition: 0.62 + (day * 0.005),
            pagesRead: 8 + (day % 5),
            deviceType: 'tablet',
            deviceName: 'iPad',
            createdAt: startTime,
          ),
        );
      }

      // Evening session (book-3 or book-7)
      if (day < 20) {
        final startTime = DateTime(date.year, date.month, date.day, 21, 0);
        sessions.add(
          ReadingSession(
            id: 'session-${sessionId++}',
            bookId: day % 3 == 0 ? 'book-7' : 'book-3',
            startTime: startTime,
            endTime: startTime.add(Duration(minutes: 35 + (day % 20))),
            startPosition: 0.3 + (day * 0.007),
            endPosition: 0.32 + (day * 0.007),
            pagesRead: 12 + (day % 8),
            deviceType: 'phone',
            deviceName: 'Pixel',
            createdAt: startTime,
          ),
        );
      }
    }

    return sessions;
  }

  // ============================================================
  // Reading Goals (4 active + 2 completed)
  // ============================================================

  static List<ReadingGoal> get readingGoals {
    final now = DateTime.now();
    return [
      // Active goals
      ReadingGoal(
        id: 'goal-1',
        title: 'Yearly reading goal',
        type: GoalType.books,
        targetValue: 12,
        currentValue: 3,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 12, 31),
        isActive: true,
        isRecurring: true,
      ),
      ReadingGoal(
        id: 'goal-2',
        title: 'Daily reading habit',
        type: GoalType.minutes,
        targetValue: 30,
        currentValue: 45,
        period: GoalPeriod.daily,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
        isActive: true,
        isRecurring: true,
        streak: 5,
      ),
      ReadingGoal(
        id: 'goal-3',
        title: 'Weekly pages',
        type: GoalType.pages,
        targetValue: 100,
        currentValue: 65,
        period: GoalPeriod.weekly,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(Duration(days: 7 - now.weekday)),
        isActive: true,
        isRecurring: false,
      ),
      ReadingGoal(
        id: 'goal-4',
        title: 'Summer reading challenge',
        goalDescription: 'Read 5 books during summer vacation',
        type: GoalType.books,
        targetValue: 5,
        currentValue: 2,
        period: GoalPeriod.custom,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 2, 0),
        isActive: true,
        isRecurring: false,
      ),
      // Completed goals
      ReadingGoal(
        id: 'goal-5',
        title: 'Q1 reading goal',
        type: GoalType.books,
        targetValue: 6,
        currentValue: 6,
        period: GoalPeriod.custom,
        startDate: DateTime(now.year, 1, 1),
        endDate: DateTime(now.year, 3, 31),
        isActive: false,
        isRecurring: false,
        isArchived: true,
        completedAt: DateTime(now.year, 3, 15),
      ),
      ReadingGoal(
        id: 'goal-6',
        title: 'Last year reading time',
        type: GoalType.minutes,
        targetValue: 6000,
        currentValue: 6000,
        period: GoalPeriod.yearly,
        startDate: DateTime(now.year - 1, 1, 1),
        endDate: DateTime(now.year - 1, 12, 31),
        isActive: false,
        isRecurring: true,
        isArchived: true,
        completedAt: DateTime(now.year - 1, 12, 20),
      ),
    ];
  }
}
