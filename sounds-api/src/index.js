function json(data, { ttl = 300, etag } = {}) {
  const headers = {
    "content-type": "application/json; charset=utf-8",
    // navegador y edge cachean (s-maxage para edge); ajusta a gusto
    "cache-control": `public, max-age=${ttl}, s-maxage=${ttl}, stale-while-revalidate=120`,
  };
  if (etag) headers["etag"] = etag;
  return new Response(JSON.stringify(data), { headers, status: 200 });
}

function corsHeaders(origin) {
  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "GET, OPTIONS",
    "access-control-allow-headers": "Content-Type",
    "vary": "Origin",
  };
}

// Usa el propio Request (URL completa) como clave de caché
async function withCache(cacheRequest, fetcher) {
  const cache = caches.default;
  let res = await cache.match(cacheRequest);
  if (res) return res;
  res = await fetcher();
  // la respuesta ya viene con cache-control desde json()
  await cache.put(cacheRequest, res.clone());
  return res;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = env.ALLOWED_ORIGIN || "*";

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders(origin) });
    }

    // Salud
    if (url.pathname === "/v1/health") {
      return new Response("ok", { headers: corsHeaders(origin) });
    }

    // Permite saltar cache con ?nocache=1
    const bypassCache = url.searchParams.has("nocache");

    // /v1/categories
    if (url.pathname === "/v1/categories") {
      const cacheReq = new Request(url.toString()); // clave válida (URL completa)

      if (!bypassCache) {
        return withCache(
          cacheReq,
          async () => {
            const rs = await env.DB
              .prepare("SELECT category_id AS id, title FROM categories ORDER BY sort_order, title")
              .all();
            const results = rs?.results || [];

            // ETag seguro sin usar .at()
            const first = results.length ? results[0].id : "";
            const last  = results.length ? results[results.length - 1].id : "";
            const etag  = `"cat-${results.length}-${first}-${last}"`;

            const res = json({ data: results }, { ttl: 300, etag });
            const h = new Headers(res.headers);
            for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
            return new Response(res.body, { headers: h, status: 200 });
          }
        );
      }

      // sin cache (nocache=1)
      const rs = await env.DB
        .prepare("SELECT category_id AS id, title FROM categories ORDER BY sort_order, title")
        .all();
      const results = rs?.results || [];
      const res = json({ data: results }, { ttl: 0 });
      const h = new Headers(res.headers);
      for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
      return new Response(res.body, { headers: h, status: 200 });
    }

    // /v1/tones?category=annoying&limit=100&offset=0
    if (url.pathname === "/v1/tones") {
      const category = url.searchParams.get("category");
      if (!category) {
        return new Response("Missing category", { status: 400, headers: corsHeaders(origin) });
      }

      const limit = Math.min(Number(url.searchParams.get("limit") || 100), 200);
      const offset = Math.max(Number(url.searchParams.get("offset") || 0), 0);

      const fetcher = async () => {
        const cdn = await env.DB.prepare("SELECT value FROM app_config WHERE key='cdn_base'").first();
        const cdnBase = cdn?.value || "";

        const { results } = await env.DB.prepare(
          `SELECT tone_id AS id, title, rel_path, requires_attribution AS req_attr, attribution_text
           FROM tones WHERE category_id = ? ORDER BY title LIMIT ? OFFSET ?`
        ).bind(category, limit, offset).all();

        const data = results.map(r => ({
          id: r.id,
          title: r.title,
          url: cdnBase + "/" + r.rel_path,
          requiresAttribution: !!r.req_attr,
          attributionText: r.attribution_text || null,
        }));

        const etag = `"tones-${category}-${data.length}-${offset}"`;
        const res = json(
          { data, paging: { limit, offset, nextOffset: data.length === limit ? offset + limit : null } },
          { ttl: 300, etag }
        );
        const h = new Headers(res.headers);
        for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
        return new Response(res.body, { headers: h, status: 200 });
      };

      if (bypassCache) {
        return fetcher();
      }
      // cachea por la URL completa (incluye category/limit/offset)
      return withCache(new Request(url.toString()), fetcher);
    }

    return new Response("Not found", { status: 404, headers: corsHeaders(origin) });
  },
};
