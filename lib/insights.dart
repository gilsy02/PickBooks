import 'models.dart';
import 'store.dart';

/// AI 없이 기록만으로 만드는 규칙 기반 분석. (AI 기능은 이후 이 자리를 대체/보강)
class Insight {
  final String title;
  final String body;
  const Insight(this.title, this.body);
}

String _kNum(int n) {
  const w = ['영', '한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉', '열'];
  return n >= 0 && n <= 10 ? w[n] : '$n';
}

Map<String, int> _catCount(Iterable<Book> books) {
  final m = <String, int>{};
  for (final b in books) {
    if (b.category.isEmpty) continue;
    m[b.category] = (m[b.category] ?? 0) + 1;
  }
  return m;
}

(String, int)? topCategory(Iterable<Book> books) {
  final m = _catCount(books);
  if (m.isEmpty) return null;
  final e = m.entries.reduce((a, b) => a.value >= b.value ? a : b);
  return (e.key, e.value);
}

class ReaderProfile {
  final String headline;
  final String summary;
  final List<Insight> items;
  const ReaderProfile(this.headline, this.summary, this.items);
}

ReaderProfile buildProfile(AppStore s) {
  final done = s.books.where((b) => b.status == BookStatus.done).toList();
  final reading = s.books.where((b) => b.status == BookStatus.reading).toList();
  final items = <Insight>[];
  if (done.isEmpty) {
    return const ReaderProfile('이제 막 서재를 채우기 시작했어요', '완독한 책이 쌓이면 어떤 독자인지 조금씩 보여 드릴게요.', []);
  }
  final top = topCategory(done);
  if (top != null) {
    items.add(Insight('끌리는 책', '다 읽은 책 ${_kNum(done.length)} 권 중 ${_kNum(top.$2)} 권이 ${top.$1}이에요.'));
  }
  final rated = done.where((b) => b.rating > 0).toList();
  final five = rated.where((b) => b.rating == 5).toList();
  final pagesAvg = done.where((b) => b.totalPages > 0).map((b) => b.totalPages).fold<int>(0, (a, b) => a + b) ~/
      (done.where((b) => b.totalPages > 0).length.clamp(1, 9999));
  var way = '서재에 꽂은 책 ${s.books.length}권 중 ${done.length}권을 끝까지 읽었어요.';
  if (pagesAvg > 0) way += ' 다 읽은 책은 평균 $pagesAvg쪽이에요.';
  if (rated.isNotEmpty) {
    way += five.isEmpty ? ' 별 다섯 개는 아직 아껴 두고 있어요.' : ' 별 다섯 개는 「${five.first.title}」에 남겼어요.';
  }
  items.add(Insight('읽는 방식', way));

  final qCount = <String, int>{};
  for (final q in s.quotes) {
    qCount[q.bookId] = (qCount[q.bookId] ?? 0) + 1;
  }
  if (qCount.isNotEmpty) {
    final topQ = qCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final b = s.bookById(topQ.key);
    if (b != null) items.add(Insight('기록의 결', '문장을 가장 많이 담은 책은 「${b.title}」(${topQ.value}개)예요. 담은 문장은 모두 ${s.quotes.length}개예요.'));
  }

  final since = DateTime.now().subtract(const Duration(days: 61));
  final recent = s.books.where((b) => b.addedAt.isAfter(since)).toList();
  final recentTop = topCategory(recent);
  if (recentTop != null) {
    final shift = top != null && recentTop.$1 != top.$1 ? '${top.$1}에서 ${recentTop.$1}(으)로 옮겨 가는 중이에요.' : '여전히 ${recentTop.$1}에 머물고 있어요.';
    items.add(Insight('요즘의 결', '지난 두 달 동안 ${recent.length}권을 담았고, $shift'));
  }

  final ratio = done.length / s.books.length;
  String headline;
  String summary;
  if (reading.length >= 3) {
    headline = '여러 권을 펼쳐 두고 오가는 독자예요';
    summary = '지금 ${reading.length}권을 함께 읽고 있어요. 그날의 마음에 맞는 책을 고르는 편이에요.';
  } else if (s.quotes.length >= done.length && s.quotes.isNotEmpty) {
    headline = '천천히 걸으며 오래 머무는 독자예요';
    summary = '빠르게 넘기기보다 한 문장 앞에 오래 서 있는 분이에요.';
  } else if (ratio >= 0.5) {
    headline = '한 번 펼친 책은 끝까지 가는 독자예요';
    summary = '서재의 절반 이상을 완독했어요. 시작한 이야기를 끝까지 따라가요.';
  } else {
    headline = '읽고 싶은 마음을 넉넉히 모으는 독자예요';
    summary = '읽고 싶은 책이 서재를 채우고 있어요. 다음 한 권이 기다리고 있어요.';
  }
  return ReaderProfile(headline, summary, items);
}

/// 이번 주 추천: 읽고 싶은 책 중에서 주마다 순서를 바꿔 최대 5권 + 기록 기반 이유
class Pick {
  final Book book;
  final String reason;
  const Pick(this.book, this.reason);
}

int weekOfYear(DateTime d) => (d.difference(DateTime(d.year)).inDays ~/ 7) + 1;

List<Pick> weeklyPicks(AppStore s) {
  final want = s.books.where((b) => b.status == BookStatus.want).toList();
  if (want.isEmpty) return [];
  final w = weekOfYear(DateTime.now());
  want.sort((a, b) => ((a.id.hashCode ^ w) & 0xffff).compareTo((b.id.hashCode ^ w) & 0xffff));
  final done = s.books.where((b) => b.status == BookStatus.done).toList();
  final top = topCategory(done);
  final quoted = s.quotes.isNotEmpty ? s.bookById(s.quotesSorted().first.bookId) : null;
  return want.take(5).map((b) {
    final days = DateTime.now().difference(b.addedAt).inDays;
    String reason;
    if (top != null && b.category == top.$1) {
      reason = '완독한 책 중 ${top.$2}권이 ${top.$1}이에요.\n가장 오래 머문 결과 같은 쪽의 책이에요.';
    } else if (quoted != null && b.category.isNotEmpty && b.category == quoted.category) {
      reason = '「${quoted.title}」에서 문장을 담아 두셨어요.\n같은 ${b.category} 서가의 다음 한 권이에요.';
    } else if (days >= 14) {
      reason = '서재에 담아 둔 지 $days일이 지났어요.\n이번 주에 펼쳐 볼까요?';
    } else {
      reason = '최근에 담아 둔 책이에요.\n관심이 식기 전에 첫 장을 넘겨 보세요.';
    }
    return Pick(b, reason);
  }).toList();
}
