// src/index.js
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

async function withCache(cacheRequest, fetcher) {
  const cache = caches.default;
  let res = await cache.match(cacheRequest);
  if (res) return res;
  res = await fetcher();
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

    const bypassCache = url.searchParams.has("nocache");

    // helper: obtiene cdnBase (prioriza env var CDN_BASE, luego DB app_config)
    const getCdnBase = async () => {
      const envCdn = (env.CDN_BASE || "").toString().trim();
      if (envCdn) return envCdn.replace(/\/+$/, "");
      const cdnRow = await env.DB.prepare("SELECT value FROM app_config WHERE key='cdn_base'").first();
      const cdnBaseRaw = cdnRow?.value || "";
      return String(cdnBaseRaw).replace(/\/+$/, "");
    };

    // helper: obtiene categories_version (string) desde app_config
    const getCategoriesVersion = async () => {
      const row = await env.DB.prepare("SELECT value FROM app_config WHERE key='categories_version'").first();
      return row?.value ? String(row.value) : "0";
    };

    // /v1/categories
    if (url.pathname === "/v1/categories") {
      const cacheReq = new Request(url.toString());

      const fetcher = async () => {
        const cdnBase = await getCdnBase();
        const categoriesVersion = await getCategoriesVersion();

        // Trae categories e intenta leer tones_count si existe
        const r = await env.DB
          .prepare("SELECT category_id AS id, title, icon_rel_path, tones_count FROM categories ORDER BY sort_order, title")
          .all();
        const results = r?.results || [];

        // Detectar si hay alguna row sin tones_count (null/undefined)
        let needCounts = false;
        for (const row of results) {
          if (row.tones_count === null || typeof row.tones_count === "undefined") {
            needCounts = true;
            break;
          }
        }

        // Si hace falta, obtener counts con una sola query GROUP BY
        const countsMap = {};
        if (needCounts) {
          const cr = await env.DB.prepare("SELECT category_id, COUNT(*) AS cnt FROM tones GROUP BY category_id").all();
          const crow = cr?.results || [];
          for (const c of crow) countsMap[c.category_id] = Number(c.cnt || 0);
        }

        const data = results.map(row => {
          const rel = row.icon_rel_path || null;
          let iconUrl = null;
          if (rel) {
            const relClean = String(rel).replace(/^\/+/, "");
            iconUrl = cdnBase ? `${cdnBase}/${relClean}` : `/${relClean}`;
          }

          const tonesCount = (row.tones_count !== null && typeof row.tones_count !== "undefined")
            ? Number(row.tones_count)
            : (countsMap[row.id] !== undefined ? countsMap[row.id] : 0);

          return {
            id: row.id,
            title: row.title,
            iconUrl,
            tonesCount
          };
        });

        const first = results.length ? results[0].id : "";
        const last  = results.length ? results[results.length - 1].id : "";
        const etag  = `"cat-${results.length}-${first}-${last}-v${categoriesVersion}"`;

        const res = json({ data }, { ttl: 300, etag });
        const h = new Headers(res.headers);
        for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
        return new Response(res.body, { headers: h, status: 200 });
      };

      if (!bypassCache) return withCache(cacheReq, fetcher);
      return fetcher();
    }

    // /v1/tones?category=...&limit=...&offset=...
    if (url.pathname === "/v1/tones") {
      const category = url.searchParams.get("category");
      if (!category) {
        return new Response("Missing category", { status: 400, headers: corsHeaders(origin) });
      }

      const limit = Math.min(Number(url.searchParams.get("limit") || 100), 200);
      const offset = Math.max(Number(url.searchParams.get("offset") || 0), 0);

      const fetcher = async () => {
        const cdnBase = await getCdnBase();

        const q = await env.DB.prepare(
          `SELECT tone_id AS id, title, rel_path, requires_attribution AS req_attr, attribution_text, duration_ms
           FROM tones WHERE category_id = ? ORDER BY title LIMIT ? OFFSET ?`
        ).bind(category, limit, offset).all();

        const results = q?.results || [];

        const data = results.map(r => {
          const relPath = r.rel_path || null;
          const urlPath = relPath ? (cdnBase ? `${cdnBase}/${String(relPath).replace(/^\/+/, '')}` : `/${relPath}`) : null;

          const durationMsRaw = (typeof r.duration_ms !== 'undefined' && r.duration_ms !== null)
            ? Number(r.duration_ms)
            : null;

          const durationSeconds = durationMsRaw !== null ? (durationMsRaw / 1000) : null;

          return {
            id: r.id,
            title: r.title,
            url: urlPath,
            requiresAttribution: !!r.req_attr,
            attributionText: r.attribution_text || null,
            duration: durationSeconds
          };
        });

        const etag = `"tones-${category}-${data.length}-${offset}"`;
        const res = json(
          { data, paging: { limit, offset, nextOffset: data.length === limit ? offset + limit : null } },
          { ttl: 300, etag }
        );
        const h = new Headers(res.headers);
        for (const [k, v] of Object.entries(corsHeaders(origin))) h.set(k, v);
        return new Response(res.body, { headers: h, status: 200 });
      };

      if (bypassCache) return fetcher();
      return withCache(new Request(url.toString()), fetcher);
    }

    return new Response("Not found", { status: 404, headers: corsHeaders(origin) });
  },
};
