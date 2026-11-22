// 픽북스 YES24 중계 서버 (Cloudflare Workers)
// - YES24 API 키는 서버 비밀값(YES24_API_KEY)에만 둔다. 앱에는 키가 없다.
// - 앱이 쓰는 두 API(검색, ISBN 상세)만 통과시키고 나머지는 막는다.
// - 같은 요청은 하루 동안 캐시해 YES24 호출 수를 줄인다(서비스 제공 범위 내 캐싱).
// - 간단한 남용 방지: 앱이 보내는 X-PickBooks-App 헤더 확인(완전한 보안은 아님) + 쿼리 길이 제한.

const ALLOWED = {
  '/v1/goods/itemList': ['query', 'category', 'sort', 'page', 'pageSize', 'detail'],
  '/v1/goods/itemDetail': ['searchType', 'query', 'detail'],
};

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET') return json(405, 'METHOD');
    const url = new URL(request.url);
    const allowed = ALLOWED[url.pathname];
    if (!allowed) return json(404, 'NOT_FOUND');
    if (request.headers.get('X-PickBooks-App') !== '1') return json(403, 'FORBIDDEN');

    const upstream = new URL('https://apis.yes24.com' + url.pathname);
    for (const k of allowed) {
      const v = url.searchParams.get(k);
      if (v !== null) upstream.searchParams.set(k, v.slice(0, 100));
    }
    if (!upstream.searchParams.get('query')) return json(400, 'PARAM');

    const cache = caches.default;
    const cacheKey = new Request(upstream.toString(), { method: 'GET' });
    const hit = await cache.match(cacheKey);
    if (hit) return hit;

    const res = await fetch(upstream.toString(), {
      headers: { 'X-Api-Key': env.YES24_API_KEY, Accept: 'application/json' },
    });
    const body = await res.text();
    const out = new Response(body, {
      status: res.status,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': res.ok ? 'public, max-age=86400' : 'no-store',
      },
    });
    if (res.ok) ctx.waitUntil(cache.put(cacheKey, out.clone()));
    return out;
  },
};

function json(status, code) {
  return new Response(JSON.stringify({ success: false, errorCode: code, data: null }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
