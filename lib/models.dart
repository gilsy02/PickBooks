enum BookStatus { reading, want, done }

extension BookStatusX on BookStatus {
  String get label => switch (this) {
        BookStatus.reading => '읽는 중',
        BookStatus.want => '읽고 싶은 책',
        BookStatus.done => '완독한 책',
      };
}

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

class Book {
  String id;
  String title;
  String author;
  String publisher;
  String? coverUrl;
  String? coverPath;
  String? spineUrl;
  String? link;
  String? isbn;
  String category;
  int totalPages;
  int currentPage;
  BookStatus status;
  DateTime addedAt;
  DateTime? finishedAt;
  int rating; // 0~5
  int colorSeed;

  Book({
    required this.id,
    required this.title,
    this.author = '',
    this.publisher = '',
    this.coverUrl,
    this.coverPath,
    this.spineUrl,
    this.link,
    this.isbn,
    this.category = '',
    this.totalPages = 0,
    this.currentPage = 0,
    this.status = BookStatus.want,
    DateTime? addedAt,
    this.finishedAt,
    this.rating = 0,
    int? colorSeed,
  })  : addedAt = addedAt ?? DateTime.now(),
        colorSeed = colorSeed ?? title.hashCode;

  double get progress => totalPages <= 0 ? 0 : (currentPage / totalPages).clamp(0, 1).toDouble();

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'author': author, 'publisher': publisher,
        'coverUrl': coverUrl, 'coverPath': coverPath, 'spineUrl': spineUrl, 'link': link, 'isbn': isbn, 'category': category,
        'totalPages': totalPages, 'currentPage': currentPage, 'status': status.name,
        'addedAt': addedAt.toIso8601String(), 'finishedAt': finishedAt?.toIso8601String(),
        'rating': rating, 'colorSeed': colorSeed,
      };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'], title: j['title'], author: j['author'] ?? '', publisher: j['publisher'] ?? '',
        coverUrl: j['coverUrl'], coverPath: j['coverPath'], spineUrl: j['spineUrl'], link: j['link'], isbn: j['isbn'], category: j['category'] ?? '',
        totalPages: j['totalPages'] ?? 0, currentPage: j['currentPage'] ?? 0,
        status: BookStatus.values.byName(j['status'] ?? 'want'),
        addedAt: _dt(j['addedAt']), finishedAt: _dt(j['finishedAt']),
        rating: j['rating'] ?? 0, colorSeed: j['colorSeed'],
      );
}

class Quote {
  String id;
  String bookId;
  String text;
  String thought;
  int? page;
  DateTime createdAt;

  Quote({required this.id, required this.bookId, required this.text, this.thought = '', this.page, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() =>
      {'id': id, 'bookId': bookId, 'text': text, 'thought': thought, 'page': page, 'createdAt': createdAt.toIso8601String()};

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
      id: j['id'], bookId: j['bookId'], text: j['text'], thought: j['thought'] ?? '', page: j['page'], createdAt: _dt(j['createdAt']));
}

class Child {
  String id;
  String name;
  Child({required this.id, required this.name});
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Child.fromJson(Map<String, dynamic> j) => Child(id: j['id'], name: j['name']);
}

/// 머릿속 영역
const kMindAreas = ['나', '감정', '관계', '생각과 세상', '자라는 마음'];

class KidBook {
  String id;
  String childId;
  String title;
  String author;
  String? coverUrl;
  String? coverPath;
  bool toRead;
  bool liked;
  List<DateTime> readDates;
  Set<String> areas;
  int colorSeed;

  KidBook({
    required this.id,
    required this.childId,
    required this.title,
    this.author = '',
    this.coverUrl,
    this.coverPath,
    this.toRead = false,
    this.liked = false,
    List<DateTime>? readDates,
    Set<String>? areas,
    int? colorSeed,
  })  : readDates = readDates ?? [],
        areas = areas ?? {},
        colorSeed = colorSeed ?? title.hashCode;

  int get readCount => readDates.length;
  DateTime? get lastRead => readDates.isEmpty ? null : (readDates.toList()..sort()).last;

  Map<String, dynamic> toJson() => {
        'id': id, 'childId': childId, 'title': title, 'author': author, 'coverUrl': coverUrl, 'coverPath': coverPath,
        'toRead': toRead, 'liked': liked, 'readDates': readDates.map((e) => e.toIso8601String()).toList(),
        'areas': areas.toList(), 'colorSeed': colorSeed,
      };

  factory KidBook.fromJson(Map<String, dynamic> j) => KidBook(
        id: j['id'], childId: j['childId'], title: j['title'], author: j['author'] ?? '', coverUrl: j['coverUrl'],
        coverPath: j['coverPath'], toRead: j['toRead'] ?? false, liked: j['liked'] ?? false,
        readDates: (j['readDates'] as List? ?? []).map((e) => DateTime.parse(e as String)).toList(),
        areas: (j['areas'] as List? ?? []).cast<String>().toSet(), colorSeed: j['colorSeed'],
      );
}
