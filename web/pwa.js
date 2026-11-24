// Release service worker only; a missing generated worker must not affect debug.
(() => {
  if (!('serviceWorker' in navigator) || !window.isSecureContext) return;
  const url = new URL('mihrab-sw.js', document.baseURI);
  window.addEventListener('load', async () => {
    try {
      const response = await fetch(url, {cache: 'no-store'});
      if (!response.ok || !/javascript/.test(response.headers.get('content-type') || '')) return;
      const registration = await navigator.serviceWorker.register(url, {
        scope: new URL('./', url).pathname, updateViaCache: 'none'
      });
      // A new release waits until all existing app windows close. Do not
      // reload while the user is reading Quran or entering diary data.
      registration.update().catch(() => {});
    } catch (error) {
      console.warn('MIHRAB offline setup unavailable', error);
    }
  }, {once: true});
})();
