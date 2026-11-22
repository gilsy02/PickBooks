import 'dart:convert';
import 'package:http/http.dart' as http;

/// YES24 Open API 결과 한 권
class Yes24Book {
  final String title;
  final String author;
  final String publisher;
  final String? isbn13;
  final int pages;
  final String? cover;
  final String? sideCover;
  final String category;
  final String? link;
  final String? publishDate;

  Yes24Book({
    required this.title,
    required this.author,
    required this.publisher,
    this.isbn13,
    this.pages = 0,
    this.cover,
    this.sideCover,
    this.category = '',
    this.link,
    this.publishDate,
  });

  factory Yes24Book.fromJson(Map<String, dynamic> j) => Yes24Book(
        title: (j['title'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        publisher: (j['publisher'] ?? '').toString(),
        isbn13: j['isbn13']?.toString(),
        pages: (j['pages'] as num?)?.toInt() ?? 0,
        cover: _https(j['cover']),
        sideCover: _https(j['sideCover']),
        category: (j['goodsSortNm'] ?? '').toString(),
        link: j['mobileLink']?.toString() ?? j['link']?.toString(),
        publishDate: j['publishDate']?.toString(),
      );

  static String? _https(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return s.startsWith('http://') ? s.replaceFirst('http://', 'https://') : s;
  }
}

class Yes24Exception implements Exception {
  final String message;
  Yes24Exception(this.message);
  @override
  String toString() => message;
}

/// https://apis.yes24.com  (X-Api-Key 헤더 인증)
/// 키는 앱 설정에 사용자가 직접 넣는다. 공개 저장소·설치 파일에는 넣지 않는다.
class Yes24Api {
  static const _base = 'apis.yes24.com';
  final String apiKey;
  final http.Client _client;
  Yes24Api(this.apiKey, {http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(String path, Map<String, String> q) async {
    if (apiKey.trim().isEmpty) throw Yes24Exception('YES24 키가 없어요. 프로필 > 도서 검색 설정에서 넣어 주세요.');
    final res = await _client
        .get(Uri.https(_base, path, q), headers: {'X-Api-Key': apiKey.trim(), 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (res.statusCode == 401) throw Yes24Exception('YES24 키가 맞지 않아요. 키를 다시 확인해 주세요.');
    if (res.statusCode == 429) throw Yes24Exception('오늘 검색 횟수를 다 썼어요. 잠시 뒤 다시 시도해 주세요.');
    if (res.statusCode == 404) return {'items': []};
    if (body == null || body['success'] != true) {
      throw Yes24Exception('검색에 실패했어요 (${res.statusCode} ${body?['errorCode'] ?? ''}).');
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : {'items': []};
  }

  Future<List<Yes24Book>> search(String query, {int page = 1}) async {
    final d = await _get('/v1/goods/itemList', {
      'query': query,
      'category': 'BOOK',
      'sort': 'RELATION',
      'page': '$page',
      'pageSize': '20',
      'detail': 'Y',
    });
    final items = (d['items'] as List?) ?? [];
    return items.whereType<Map<String, dynamic>>().map(Yes24Book.fromJson).where((b) => b.title.isNotEmpty).toList();
  }

  Future<Yes24Book?> byIsbn(String isbn13) async {
    final d = await _get('/v1/goods/itemDetail', {'searchType': 'ISBN13', 'query': isbn13, 'detail': 'Y'});
    // 단건 응답은 data.data 이거나 data.items 일 수 있다.
    final inner = d['data'];
    if (inner is Map<String, dynamic>) return Yes24Book.fromJson(inner);
    if (inner is List && inner.isNotEmpty) return Yes24Book.fromJson(inner.first as Map<String, dynamic>);
    final items = d['items'];
    if (items is List && items.isNotEmpty) return Yes24Book.fromJson(items.first as Map<String, dynamic>);
    return null;
  }
}
