'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "version.json": "5399f578a865f063c83a1e7f4ecee330",
"index.html": "d60d4e942829dee56ca296af2fcea81c",
"/": "d60d4e942829dee56ca296af2fcea81c",
"main.dart.js": "1a9a1299a09185b86f881daf0753050c",
"flutter.js": "a85fcf6324d3c4d3ae3be1ae4931e9c5",
"favicon.png": "efbb1a1934015b8648451b288c5f97db",
"icons/favicon-16x16.png": "2370db5b8ae4df7926bbc512d4add6b0",
"icons/favicon.ico": "0fe4c415480298aeb36d947072142e49",
"icons/apple-icon.png": "2e332074ec1da5ec27d348f01f679244",
"icons/apple-icon-144x144.png": "d4eaf5cc2a5c82eb1aaeaf9f79f229aa",
"icons/android-icon-192x192.png": "6bdda42e037a5653dc84f43bcbf15ccd",
"icons/apple-icon-precomposed.png": "2e332074ec1da5ec27d348f01f679244",
"icons/apple-icon-114x114.png": "54b44958fbdc76ddfb4dd7238057a3c5",
"icons/ms-icon-310x310.png": "90a1f02d9eeaf42f907929adb73648e3",
"icons/Icon-192.png": "92c379ac16b5ece9653394fae2f8aaa5",
"icons/Icon-maskable-192.png": "92c379ac16b5ece9653394fae2f8aaa5",
"icons/ms-icon-144x144.png": "d4eaf5cc2a5c82eb1aaeaf9f79f229aa",
"icons/apple-icon-57x57.png": "30af4ae8d1e268beb2ccf63dc8d8e25e",
"icons/apple-icon-152x152.png": "ea449de5add8ce5bd2b6590773e4b767",
"icons/ms-icon-150x150.png": "474cf1e40c19c9f9cf018bf0e494827b",
"icons/android-icon-72x72.png": "205e4ed8e1f42518a4a9658cae70a168",
"icons/android-icon-96x96.png": "6018f1f463d0c57fda981434b93bfc0c",
"icons/android-icon-36x36.png": "945dd057e914fd04501cb2e446eb0117",
"icons/apple-icon-180x180.png": "71f84132167a5d5c08c630cc664bcf77",
"icons/favicon-96x96.png": "6018f1f463d0c57fda981434b93bfc0c",
"icons/manifest.json": "b58fcfa7628c9205cb11a1b2c3e8f99a",
"icons/android-icon-48x48.png": "586db72060f5aa7332729cc5f33aaf62",
"icons/apple-icon-76x76.png": "0065ad2da3034b58b69148f08342d429",
"icons/apple-icon-60x60.png": "68ea4c794b4f857b0d18c19d6e4cdb7a",
"icons/Icon-maskable-512.png": "487281eebc3b1608dbac74f0115cc3a5",
"icons/browserconfig.xml": "653d077300a12f09a69caeea7a8947f8",
"icons/android-icon-144x144.png": "d4eaf5cc2a5c82eb1aaeaf9f79f229aa",
"icons/apple-icon-72x72.png": "205e4ed8e1f42518a4a9658cae70a168",
"icons/apple-icon-120x120.png": "1e448dc18fccef35f76111ba2930040c",
"icons/Icon-512.png": "487281eebc3b1608dbac74f0115cc3a5",
"icons/favicon-32x32.png": "85dee573d2d4d93e0ee2dfa700d68012",
"icons/ms-icon-70x70.png": "564bf70edd45d08d840013f64621fffa",
"manifest.json": "87f94f8fc322c0988d3a367f1b90b902",
"assets/AssetManifest.json": "6845d1c4d3d2034a6f066daf5da34e21",
"assets/NOTICES": "05c1442fdd253d1a3eff0168473cc6ca",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"assets/shaders/ink_sparkle.frag": "26c8cb1edf4b8906098b498d1aedb207",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/assets/images/pizza.jpg": "ad5a19413f83906863d5765a7fd6c590",
"assets/assets/images/burger.jpg": "e41744739e09d8b99bbbcca87d94234d",
"canvaskit/canvaskit.js": "97937cb4c2c2073c968525a3e08c86a3",
"canvaskit/profiling/canvaskit.js": "c21852696bc1cc82e8894d851c01921a",
"canvaskit/profiling/canvaskit.wasm": "371bc4e204443b0d5e774d64a046eb99",
"canvaskit/canvaskit.wasm": "3de12d898ec208a5f31362cc00f09b9e"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
"index.html",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
