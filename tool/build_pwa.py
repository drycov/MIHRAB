#!/usr/bin/env python3
"""Generate a release-versioned, scope-local offline app shell."""
import hashlib
import json
import sys
from pathlib import Path
from urllib.parse import quote

root = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web")
required = ["index.html", "flutter_bootstrap.js", "main.dart.js", "manifest.json"]
for name in required:
    if not (root / name).is_file():
        raise SystemExit(f"Missing release asset: {name}")
# Only deploy artifacts, not remote Quran/audio API responses or user data.
paths = sorted(p for p in root.rglob("*") if p.is_file()
               and p.name not in {"mihrab-sw.js", "flutter_service_worker.js"}
               and p.suffix not in {".map"})
digest = hashlib.sha256()
for p in paths:
    digest.update(p.relative_to(root).as_posix().encode())
    digest.update(b"\0")
    digest.update(hashlib.sha256(p.read_bytes()).digest())
version = digest.hexdigest()[:20]
assets = ["./" + quote(p.relative_to(root).as_posix(), safe="/") for p in paths]
template = r"""
const PREFIX = 'mihrab-shell:' + self.registration.scope + ':';
const CACHE = PREFIX + __VERSION__;
const ASSETS = __ASSETS__;
const urls = new Set(ASSETS.map(p => new URL(p, self.registration.scope).href));
self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    try {
      // Fetch fresh release files; do not activate a partial shell.
      for (const path of ASSETS) {
        const request = new Request(new URL(path, self.registration.scope), {cache: 'reload'});
        const response = await fetch(request);
        if (!response.ok || response.redirected ||
            (!path.endsWith('.html') && /text\/html/i.test(response.headers.get('content-type') || ''))) {
          throw new Error('Invalid release asset: ' + path);
        }
        await cache.put(request, response);
      }
    } catch (error) {
      await caches.delete(CACHE);
      throw error;
    }
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      if (name.startsWith(PREFIX) && name !== CACHE) await caches.delete(name);
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (!url.href.startsWith(self.registration.scope) || url.origin !== self.location.origin) return;
  if (request.headers.has('range')) return;
  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE);
      // Keep index and static assets from the same release until activation.
      if (urls.has(url.href)) {
        const exact = await cache.match(url.href);
        if (exact) return exact;
      }
      if (url.pathname === new URL('./', self.registration.scope).pathname) {
        const index = await cache.match(new URL('index.html', self.registration.scope));
        if (index) return index;
      }
      try { return await fetch(request); }
      catch (_) { return (await cache.match(new URL('index.html', self.registration.scope))) || Response.error(); }
    })());
    return;
  }
  if (urls.has(url.href)) {
    event.respondWith(caches.open(CACHE).then(async cache => (await cache.match(request)) || fetch(request)));
  }
});
"""
(root / "mihrab-sw.js").write_text(template.replace("__VERSION__", json.dumps(version))
                                  .replace("__ASSETS__", json.dumps(assets)), encoding="utf-8")
print(f"MIHRAB PWA shell {version}: {len(assets)} assets")
