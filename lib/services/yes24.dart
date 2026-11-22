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

/// 출시판: 빌드 때 넣는 중계 서버 주소(YES24_PROXY_URL). 키는 서버에만 있다.
/// 테스트판: 중계 서버가 없으면 사용자가 설정에 넣은 개인 키로 YES24를 직접 부른다.
const kYes24ProxyUrl = String.fromEnvironment('YES24_PROXY_URL');
bool get hasYes24Proxy => kYes24ProxyUrl.startsWith('https://');

class Yes24Api {
  static const _base = 'apis.yes24.com';
  final String apiKey;
  final http.Client _client;
  Yes24Api(this.apiKey, {http.Client? client}) : _client = client ?? http.Client();

  /// 검색을 쓸 수 있는 상태인지 (중계 서버가 있거나 개인 키가 있음)
  static bool available(String userKey) => hasYes24Proxy || userKey.trim().isNotEmpty;

  Future<Map<String, dynamic>> _get(String path, Map<String, String> q) async {
    final useKey = apiKey.trim().isNotEmpty;
    if (!useKey && !hasYes24Proxy) throw Yes24Exception('YES24 키가 없어요. 프로필 > 도서 검색 설정에서 넣어 주세요.');
    final Uri uri;
    final headers = <String, String>{'Accept': 'application/json'};
    if (useKey) {
      uri = Uri.https(_base, path, q);
      headers['X-Api-Key'] = apiKey.trim();
    } else {
      final base = Uri.parse(kYes24ProxyUrl);
      uri = base.replace(path: path, queryParameters: q);
      headers['X-PickBooks-App'] = '1';
    }
    final res = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 12));
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
