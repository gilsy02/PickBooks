import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

enum ShelfSort { manual, recent, title }

/// 앱 전체 상태. 기기 안(SharedPreferences)에 JSON으로 저장한다.
class AppStore extends ChangeNotifier {
  static const _key = 'pickbooks_v1';
  SharedPreferences? _prefs;

  String nickname = '책읽는하루';
  String yes24Key = '';
  List<Book> books = [];
  List<Quote> quotes = [];
  List<Child> children = [];
  List<KidBook> kidBooks = [];
  String? selectedChildId;
  bool kidsMode = false;
  ShelfSort sort = ShelfSort.manual;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) {
      _seed();
      await _save();
    } else {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      nickname = j['nickname'] ?? nickname;
      yes24Key = j['yes24Key'] ?? '';
      books = (j['books'] as List).map((e) => Book.fromJson(e)).toList();
      quotes = (j['quotes'] as List).map((e) => Quote.fromJson(e)).toList();
      children = (j['children'] as List).map((e) => Child.fromJson(e)).toList();
      kidBooks = (j['kidBooks'] as List).map((e) => KidBook.fromJson(e)).toList();
      selectedChildId = j['selectedChildId'];
    }
    selectedChildId ??= children.isEmpty ? null : children.first.id;
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _key,
        jsonEncode({
          'nickname': nickname,
          'yes24Key': yes24Key,
          'books': books.map((e) => e.toJson()).toList(),
          'quotes': quotes.map((e) => e.toJson()).toList(),
          'children': children.map((e) => e.toJson()).toList(),
          'kidBooks': kidBooks.map((e) => e.toJson()).toList(),
          'selectedChildId': selectedChildId,
        }));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ---------- 모드 ----------
  void setKidsMode(bool v) {
    kidsMode = v;
    notifyListeners();
  }

  void setYes24Key(String v) {
    yes24Key = v.trim();
    _changed();
  }

  bool hasIsbn(String? isbn) => isbn != null && isbn.isNotEmpty && books.any((b) => b.isbn == isbn);

  void setNickname(String v) {
    nickname = v;
    _changed();
  }

  // ---------- 책 ----------
  List<Book> booksBy(BookStatus s) {
    final list = books.where((b) => b.status == s).toList();
    switch (sort) {
      case ShelfSort.recent:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case ShelfSort.title:
        list.sort((a, b) => a.title.compareTo(b.title));
      case ShelfSort.manual:
        break;
    }
    return list;
  }

  Book? bookById(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }

  void setSort(ShelfSort s) {
    sort = s;
    notifyListeners();
  }

  void addBook(Book b) {
    books.add(b);
    _changed();
  }

  void updateBook(Book b) => _changed();

  void moveBook(Book b, BookStatus to, {Book? before}) {
    if (b.status != to) {
      b.status = to;
      if (to == BookStatus.done) {
        b.finishedAt ??= DateTime.now();
        if (b.totalPages > 0) b.currentPage = b.totalPages;
      } else {
        b.finishedAt = null;
      }
    }
    books.remove(b);
    final idx = before == null ? -1 : books.indexOf(before);
    if (idx < 0) {
      books.add(b);
    } else {
      books.insert(idx, b);
    }
    _changed();
  }

  void deleteBook(Book b) {
    books.remove(b);
    quotes.removeWhere((q) => q.bookId == b.id);
    _changed();
  }

  // ---------- 문장 ----------
  List<Quote> quotesSorted() => quotes.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<Quote> quotesOf(String bookId) => quotesSorted().where((q) => q.bookId == bookId).toList();

  void addQuote(Quote q) {
    quotes.add(q);
    _changed();
  }

  void updateQuote(Quote q) => _changed();

  void deleteQuote(Quote q) {
    quotes.remove(q);
    _changed();
  }

  // ---------- 키즈 ----------
  Child? get selectedChild {
    for (final c in children) {
      if (c.id == selectedChildId) return c;
    }
    return null;
  }

  void selectChild(String id) {
    selectedChildId = id;
    _changed();
  }

  void addChild(String name) {
    final c = Child(id: newId(), name: name);
    children.add(c);
    selectedChildId = c.id;
    _changed();
  }

  void renameChild(Child c, String name) {
    c.name = name;
    _changed();
  }

  void deleteChild(Child c) {
    children.remove(c);
    kidBooks.removeWhere((k) => k.childId == c.id);
    if (selectedChildId == c.id) selectedChildId = children.isEmpty ? null : children.first.id;
    _changed();
  }

  List<KidBook> kidBooksOf(String? childId, {required bool toRead}) {
    final list = kidBooks.where((k) => k.childId == childId && k.toRead == toRead).toList();
    list.sort((a, b) => (b.lastRead ?? DateTime(0)).compareTo(a.lastRead ?? DateTime(0)));
    return list;
  }

  void addKidBook(KidBook k) {
    kidBooks.add(k);
    _changed();
  }

  void updateKidBook(KidBook k) => _changed();

  void deleteKidBook(KidBook k) {
    kidBooks.remove(k);
    _changed();
  }

  void readAgain(KidBook k) {
    k.readDates.add(DateTime.now());
    k.toRead = false;
    _changed();
  }

  /// 최근 12개월 월별 읽은 횟수 (오래된 달 → 이번 달)
  List<(DateTime, int)> monthlyCounts(String? childId) {
    final now = DateTime.now();
    final res = <(DateTime, int)>[];
    for (var i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      var c = 0;
      for (final k in kidBooks.where((k) => k.childId == childId)) {
        c += k.readDates.where((d) => d.year == m.year && d.month == m.month).length;
      }
      res.add((m, c));
    }
    return res;
  }

  /// 이번 주(또는 지난주)부터 거슬러 올라가며 끊기지 않고 읽은 주 수
  int streakWeeks(String? childId) {
    final dates = kidBooks.where((k) => k.childId == childId).expand((k) => k.readDates).toList();
    if (dates.isEmpty) return 0;
    DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
    final weeks = dates.map(weekStart).map((d) => d.millisecondsSinceEpoch).toSet();
    var w = weekStart(DateTime.now());
    if (!weeks.contains(w.millisecondsSinceEpoch)) w = DateTime(w.year, w.month, w.day - 7);
    var n = 0;
    while (weeks.contains(w.millisecondsSinceEpoch)) {
      n++;
      w = DateTime(w.year, w.month, w.day - 7);
    }
    return n;
  }

  Map<String, int> areaCounts(String? childId) {
    final m = {for (final a in kMindAreas) a: 0};
    for (final k in kidBooks.where((k) => k.childId == childId && !k.toRead)) {
      for (final a in k.areas) {
        m[a] = (m[a] ?? 0) + k.readCount.clamp(1, 99);
      }
    }
    return m;
  }

  // ---------- 데이터 관리 ----------
  Future<void> resetAll({bool withSample = false}) async {
    books = [];
    quotes = [];
    children = [];
    kidBooks = [];
    selectedChildId = null;
    if (withSample) _seed();
    selectedChildId = children.isEmpty ? null : children.first.id;
    _changed();
  }

  String exportJson() => jsonEncode({
        'nickname': nickname,
        'books': books.map((e) => e.toJson()).toList(),
        'quotes': quotes.map((e) => e.toJson()).toList(),
        'children': children.map((e) => e.toJson()).toList(),
        'kidBooks': kidBooks.map((e) => e.toJson()).toList(),
      });

  // ---------- 샘플 ----------
  void _seed() {
    final now = DateTime.now();
    Book b(String t, String a, String p, BookStatus s, {int total = 0, int cur = 0, String cat = '', int daysAgo = 0}) => Book(
        id: newId(), title: t, author: a, publisher: p, status: s, totalPages: total, currentPage: cur, category: cat,
        addedAt: now.subtract(Duration(days: daysAgo)), finishedAt: s == BookStatus.done ? now.subtract(Duration(days: daysAgo ~/ 2)) : null);
    books = [
      b('불편한 편의점', '김호연', '나무옆의자', BookStatus.reading, total: 268, cur: 166, cat: '소설', daysAgo: 12),
      b('지구 끝의 온실', '김초엽', '자이언트북스', BookStatus.reading, total: 392, cur: 70, cat: '소설', daysAgo: 5),
      b('월든', '헨리 데이비드 소로', '민음사', BookStatus.want, cat: '에세이', daysAgo: 20),
      b('코스모스', '칼 세이건', '사이언스북스', BookStatus.want, cat: '과학', daysAgo: 18),
      b('미드나잇 라이브러리', '매트 헤이그', '인플루엔셜', BookStatus.want, cat: '소설', daysAgo: 3),
      b('아몬드', '손원평', '창비', BookStatus.done, total: 264, cat: '소설', daysAgo: 90),
      b('데미안', '헤르만 헤세', '민음사', BookStatus.done, total: 232, cat: '소설', daysAgo: 70),
      b('소년이 온다', '한강', '창비', BookStatus.done, total: 216, cat: '소설', daysAgo: 60),
      b('어린 왕자', '앙투안 드 생텍쥐페리', '열린책들', BookStatus.done, total: 152, cat: '소설', daysAgo: 50),
      b('노인과 바다', '어니스트 헤밍웨이', '민음사', BookStatus.done, total: 152, cat: '소설', daysAgo: 40),
      b('여행의 이유', '김영하', '문학동네', BookStatus.done, total: 216, cat: '에세이', daysAgo: 30),
      b('달러구트 꿈 백화점', '이미예', '팩토리나인', BookStatus.done, total: 300, cat: '소설', daysAgo: 20),
    ];
    for (final x in books.where((x) => x.status == BookStatus.done)) {
      x.currentPage = x.totalPages;
    }
    final demian = books.firstWhere((x) => x.title == '데미안');
    quotes = [
      Quote(id: newId(), bookId: demian.id, text: '새는 알에서 나오려고 투쟁한다. 알은 세계이다. 태어나려는 자는 하나의 세계를 깨뜨려야 한다.',
          thought: '깨뜨린다는 말이 오래 남았다. 나도 지금 내 알을 깨고 있는 중일까.', createdAt: now.subtract(const Duration(days: 33))),
    ];
    final haru = Child(id: newId(), name: '하루');
    final seojun = Child(id: newId(), name: '서준');
    children = [haru, seojun];
    List<DateTime> days(List<int> ago) => ago.map((d) => now.subtract(Duration(days: d))).toList();
    kidBooks = [
      KidBook(id: newId(), childId: haru.id, title: '알사탕', author: '백희나', liked: true, readDates: days([1, 8, 20, 40]), areas: {'감정', '관계'}),
      KidBook(id: newId(), childId: haru.id, title: '수박 수영장', author: '안녕달', liked: true, readDates: days([5, 30]), areas: {'나', '생각과 세상'}),
      KidBook(id: newId(), childId: haru.id, title: '긴긴밤', author: '루리', liked: true, readDates: days([9]), areas: {'관계', '자라는 마음'}),
      KidBook(id: newId(), childId: haru.id, title: '마당을 나온 암탉', author: '황선미', readDates: days([60]), areas: {'자라는 마음', '나'}),
    ];
    // 성장 그래프용 기록
    final extra = [130, 125, 100, 95, 92, 70, 66, 64, 45, 44, 42, 28, 26, 24, 21, 15, 14, 3, 2];
    kidBooks.add(KidBook(id: newId(), childId: haru.id, title: '구름빵', author: '백희나', readDates: days(extra), areas: {'생각과 세상'}));
  }
}

final store = AppStore();
