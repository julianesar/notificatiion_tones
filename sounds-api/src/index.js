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

    // /v1/categories  -> devuelve iconUrl construido desde app_config.cdn_base
    if (url.pathname === "/v1/categories") {
      const cacheReq = new Request(url.toString()); // clave válida (URL completa)

      const fetcher = async () => {
        // lee cdn_base como haces en /v1/tones
        const cdnRow = await env.DB.prepare("SELECT value FROM app_config WHERE key='cdn_base'").first();
        const cdnBaseRaw = cdnRow?.value || "";
        const cdnBase = String(cdnBaseRaw).replace(/\/+$/, ""); // quita slash final

        const rs = await env.DB
          .prepare("SELECT category_id AS id, title, icon_rel_path FROM categories ORDER BY sort_order, title")
          .all();
        const results = rs?.results || [];

        // construye datos con iconUrl (o null si no hay ruta)
        const data = results.map(r => {
          const rel = r.icon_rel_path || null;
          let iconUrl = null;
          if (rel) {
            const relClean = String(rel).replace(/^\/+/, ""); // quita slash inicial
            iconUrl = cdnBase ? `${cdnBase}/${relClean}` : `/${relClean}`;
          }
          return {
            id: r.id,
            title: r.title,
            iconUrl,
          };
        });

        // ETag: count + firstId + lastId (seguro sin updated_at)
        const first = results.length ? results[0].id : "";
        const last  = results.length ? results[results.length - 1].id : "";
        const etag  = `"cat-${results.length}-${first}-${last}"`;

        const res = json({ data }, { ttl: 300, etag });
        const h = new Headers(res.headers);
        for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
        return new Response(res.body, { headers: h, status: 200 });
      };

      if (!bypassCache) {
        return withCache(cacheReq, fetcher);
      }
      // nocache=1 -> no cache
      return fetcher();
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
        const cdnBaseRaw = cdn?.value || "";
        const cdnBase = String(cdnBaseRaw).replace(/\/+$/, "");

        const { results } = await env.DB.prepare(
          `SELECT tone_id AS id, title, rel_path, requires_attribution AS req_attr, attribution_text
           FROM tones WHERE category_id = ? ORDER BY title LIMIT ? OFFSET ?`
        ).bind(category, limit, offset).all();

        const data = results.map(r => ({
          id: r.id,
          title: r.title,
          url: cdnBase ? `${cdnBase}/${String(r.rel_path).replace(/^\/+/, '')}` : `/${r.rel_path}`,
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
