// This is a service worker file for Flutter web
'use strict';

const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {
  "version.json": "1",
  "index.html": "1",
  "main.dart.js": "1",
  "flutter.js": "1",
  "favicon.png": "1",
  "icons/Icon-192.png": "1",
  "icons/Icon-maskable-192.png": "1",
  "icons/Icon-maskable-512.png": "1",
  "icons/Icon-512.png": "1",
  "manifest.json": "1",
  "assets/AssetManifest.json": "1",
  "assets/FontManifest.json": "1",
  "assets/NOTICES": "1",
  "assets/shaders/ink_sparkle.frag": "1",
};

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (cacheName) {
      return Promise.all(
        cacheName.map(function (name) {
          if (name !== CACHE_NAME) {
            return caches.delete(name);
          }
        })
      );
    })
  );
});

self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') return;

  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);

  if (key == '') key = 'index.html';

  if (RESOURCES[key]) {
    event.respondWith(caches.open(CACHE_NAME).then(function (cache) {
      return cache.match(event.request).then(function (response) {
        if (response) return response;

        return fetch(event.request).then(function (response) {
          cache.put(event.request, response.clone());
          return response;
        });
      });
    }));
  }
});

