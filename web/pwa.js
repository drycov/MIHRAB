(() => {
  let promptEvent, registration;
  const standalone = () => matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
  window.addEventListener('beforeinstallprompt', event => {
    event.preventDefault();
    promptEvent = event;
  });
  window.addEventListener('appinstalled', () => { promptEvent = null; });
  window.mihrabPwa = {
    status: () => JSON.stringify({
      online: navigator.onLine,
      installed: standalone(),
      installable: !!promptEvent,
      offlineReady: !!navigator.serviceWorker?.controller,
      updateAvailable: !!registration?.waiting
    }),
    install: async () => {
      if (!promptEvent) return false;
      const event = promptEvent;
      promptEvent = null;
      try { await event.prompt(); return (await event.userChoice).outcome === 'accepted'; }
      catch (_) { return false; }
    },
    checkUpdate: async () => {
      try { await registration?.update(); return true; }
      catch (_) { return false; }
    }
  };
  if (!('serviceWorker' in navigator) || !window.isSecureContext) return;
  const url = new URL('mihrab-sw.js', document.baseURI);
  window.addEventListener('load', async () => {
    // Recover an existing registration even when starting offline.
    try {
      registration = await navigator.serviceWorker.getRegistration(new URL('./', url).pathname);
      if (!registration) {
        const response = await fetch(url, {cache: 'no-store'});
        if (!response.ok || !/javascript/.test(response.headers.get('content-type') || '')) return;
        registration = await navigator.serviceWorker.register(url, {
          scope: new URL('./', url).pathname, updateViaCache: 'none'
        });
      }
      registration.update().catch(() => {});
    } catch (error) { console.warn('MIHRAB offline setup unavailable', error); }
  }, {once: true});
})();
