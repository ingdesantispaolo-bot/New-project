const BUILD_ID = "2026.09.05-web-loader-5";
const CACHE_VERSION = "v195-web-loader";
const STATIC_CACHE = `eli-quest-static-${CACHE_VERSION}`;
const RUNTIME_CACHE = `eli-quest-runtime-${CACHE_VERSION}`;
const APP_SHELL = ["./manifest.webmanifest", "./eli-quest-icon.svg"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(APP_SHELL)),
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then(async (keys) => {
        const staleKeys = keys.filter((key) => key.startsWith("eli-quest-") && key !== STATIC_CACHE && key !== RUNTIME_CACHE);
        await Promise.all(staleKeys.map((key) => caches.delete(key)));
        await self.clients.claim();
      }),
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") {
    self.skipWaiting();
    return;
  }
  if (event.data?.type === "GET_BUILD_ID" && event.ports?.[0]) {
    event.ports[0].postMessage({ buildId: BUILD_ID, cacheVersion: CACHE_VERSION });
    return;
  }
  // Svuotamento su richiesta: lo chiede il lanciatore quando si accorge che la
  // build e' cambiata. Cancellare le cache dalla pagina si potrebbe anche fare
  // da fuori, ma farlo qui e' l'unico modo di essere sicuri che accada PRIMA
  // che il worker risponda alla prossima richiesta con quello che ha in mano.
  if (event.data?.type === "PURGE") {
    event.waitUntil?.(purgeAll());
    purgeAll();
  }
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") {
    return;
  }

  if (isHtmlRequest(event.request)) {
    event.respondWith(networkFirst(event.request));
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.pathname.endsWith("/build.json")) {
    event.respondWith(networkFirst(event.request));
    return;
  }
  if (requestUrl.pathname.includes("/godot/outdoor/")) {
    event.respondWith(
      requestUrl.pathname.endsWith(".html")
        ? networkFirst(event.request)
        : cacheFirst(event.request),
    );
    return;
  }

  event.respondWith(cacheFirst(event.request));
});

function isHtmlRequest(request) {
  return request.mode === "navigate" || request.headers.get("accept")?.includes("text/html");
}

async function networkFirst(request) {
  try {
    const response = await fetch(request, { cache: "no-store" });
    if (isCacheable(response)) {
      const cache = await caches.open(RUNTIME_CACHE);
      await cache.put(request, response.clone());
    }
    return response;
  } catch {
    const cached = await caches.match(request);
    return cached ?? caches.match("./");
  }
}

async function purgeAll() {
  const keys = await caches.keys();
  await Promise.all(
    keys.filter((key) => key.startsWith("eli-quest-")).map((key) => caches.delete(key)),
  );
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }
  // **`reload` e non `default`.** Un fallimento di cache qui succede una volta
  // sola per build: subito dopo un aggiornamento, quando le cache vecchie sono
  // state cancellate. Se in quel momento si lasciasse decidere alla cache HTTP
  // del browser, `index.pck` — che ha SEMPRE lo stesso indirizzo — potrebbe
  // arrivare identico a ieri, e il giocatore riscaricherebbe la copia vecchia
  // credendo di aggiornare. E' il buco che rendeva il controllo di versione una
  // formalita'.
  const response = await fetch(request, { cache: "reload" });
  if (isCacheable(response)) {
    const cache = await caches.open(RUNTIME_CACHE);
    await cache.put(request, response.clone());
  }
  return response;
}

function isCacheable(response) {
  return response && response.status === 200 && response.type !== "opaque";
}
