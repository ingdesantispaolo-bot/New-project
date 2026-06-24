const CACHE_VERSION = "v2-auto-update";
const STATIC_CACHE = `eli-quest-static-${CACHE_VERSION}`;
const RUNTIME_CACHE = `eli-quest-runtime-${CACHE_VERSION}`;
const APP_SHELL = ["./manifest.webmanifest", "./eli-quest-icon.svg"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then(async (keys) => {
        const staleKeys = keys.filter((key) => key.startsWith("eli-quest-") && key !== STATIC_CACHE && key !== RUNTIME_CACHE);
        const shouldReloadOpenClients = staleKeys.length > 0;
        await Promise.all(staleKeys.map((key) => caches.delete(key)));
        await self.clients.claim();
        if (shouldReloadOpenClients) {
          const clients = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
          clients.forEach((client) => {
            if ("navigate" in client) {
              client.navigate(client.url);
            }
          });
        }
      }),
  );
});

self.addEventListener("message", (event) => {
  if (event.data?.type === "SKIP_WAITING") {
    self.skipWaiting();
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

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  if (isCacheable(response)) {
    const cache = await caches.open(RUNTIME_CACHE);
    await cache.put(request, response.clone());
  }
  return response;
}

function isCacheable(response) {
  return response && response.status === 200 && response.type !== "opaque";
}
