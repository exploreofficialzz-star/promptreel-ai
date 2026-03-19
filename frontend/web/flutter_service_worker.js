'use strict';

// ── PromptReel AI — Flutter Web Service Worker ────────────────────────────────
// This file is required by flutter build web for offline/PWA support.
// Flutter's build tool rewrites the CACHE_NAME and RESOURCES map at build time.
// Keep this file as-is; the build tool merges generated assets into it.

const CACHE_NAME = 'promptreel-ai-cache-v1';

// Resources to pre-cache (Flutter build tool fills this in)
const RESOURCES = {
  '/': 'index.html',
  'flutter_bootstrap.js': '',
  'manifest.json': '',
};

// Install — cache shell resources
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(
        Object.keys(RESOURCES)
          .filter((key) => key !== '/')
      );
    })
  );
});

// Activate — clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) =>
      Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      )
    )
  );
  return self.clients.claim();
});

// Fetch — network-first for API calls, cache-first for app shell
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Always go network for API calls
  if (url.hostname.includes('onrender.com') || url.pathname.startsWith('/api/')) {
    event.respondWith(fetch(event.request));
    return;
  }

  // Cache-first for static app shell
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return cached || fetch(event.request).then((response) => {
        if (response && response.status === 200 && response.type === 'basic') {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      });
    })
  );
});
