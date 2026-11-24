(() => {
  let promptEvent = null;
  let registration = null;
  const timers = new Map();

  const standalone = () =>
    matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;

  const clearTimers = () => {
    for (const id of timers.values()) clearTimeout(id);
    timers.clear();
  };

  const showViaSwOrPage = async (title, body, tag) => {
    try {
      const reg = registration || (await navigator.serviceWorker?.ready);
      if (reg?.showNotification) {
        await reg.showNotification(title, {
          body,
          tag: tag || 'mihrab',
          icon: 'icons/Icon-192.png',
          badge: 'icons/Icon-192.png',
          renotify: true,
        });
        return true;
      }
    } catch (_) {}
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        body,
        tag: tag || 'mihrab',
        icon: 'icons/Icon-192.png',
      });
      return true;
    }
    return false;
  };

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    promptEvent = event;
  });
  window.addEventListener('appinstalled', () => {
    promptEvent = null;
  });

  window.mihrabPwa = {
    status: () =>
      JSON.stringify({
        online: navigator.onLine,
        installed: standalone(),
        installable: !!promptEvent,
        offlineReady: !!navigator.serviceWorker?.controller,
        updateAvailable: !!registration?.waiting,
        secure: window.isSecureContext,
        notificationPermission:
          'Notification' in window ? Notification.permission : 'unsupported',
        geo: 'geolocation' in navigator,
      }),

    install: async () => {
      if (!promptEvent) return false;
      const event = promptEvent;
      promptEvent = null;
      try {
        await event.prompt();
        return (await event.userChoice).outcome === 'accepted';
      } catch (_) {
        return false;
      }
    },

    checkUpdate: async () => {
      try {
        await registration?.update();
        return true;
      } catch (_) {
        return false;
      }
    },

    /** @returns {Promise<string>} granted | denied | default | unsupported */
    requestNotifications: async () => {
      if (!('Notification' in window)) return 'unsupported';
      if (Notification.permission === 'granted') return 'granted';
      if (Notification.permission === 'denied') return 'denied';
      try {
        const result = await Notification.requestPermission();
        return result || 'default';
      } catch (_) {
        return 'denied';
      }
    },

    notificationPermission: () =>
      'Notification' in window ? Notification.permission : 'unsupported',

    /** Show immediately (needs permission). */
    showNotification: async (title, body, tag) => {
      if (!('Notification' in window)) return false;
      if (Notification.permission !== 'granted') {
        const p = await window.mihrabPwa.requestNotifications();
        if (p !== 'granted') return false;
      }
      return showViaSwOrPage(String(title || 'MIHRAB'), String(body || ''), String(tag || 'mihrab'));
    },

    /**
     * Schedule local reminders while the page/PWA is open.
     * itemsJson: [{"id":1,"title":"...","body":"...","atMs":1234567890}, ...]
     * Browsers do not allow reliable multi-hour alarms when the tab is killed;
     * timers run in this page and fire via Service Worker when possible.
     */
    scheduleReminders: async (itemsJson) => {
      clearTimers();
      let items = [];
      try {
        items = typeof itemsJson === 'string' ? JSON.parse(itemsJson) : itemsJson || [];
      } catch (_) {
        return 0;
      }
      const now = Date.now();
      let count = 0;
      for (const item of items) {
        const at = Number(item.atMs);
        if (!Number.isFinite(at) || at <= now) continue;
        const delay = Math.min(at - now, 2147483647); // setTimeout max ~24d
        const id = String(item.id ?? at);
        const handle = setTimeout(() => {
          timers.delete(id);
          showViaSwOrPage(item.title || 'MIHRAB', item.body || '', id);
        }, delay);
        timers.set(id, handle);
        count += 1;
      }
      try {
        localStorage.setItem('mihrab_web_reminders', JSON.stringify(items));
      } catch (_) {}
      return count;
    },

    clearReminders: () => {
      clearTimers();
      try {
        localStorage.removeItem('mihrab_web_reminders');
      } catch (_) {}
      return true;
    },

    /** GPS: returns JSON {lat,lng,accuracy} or throws message string */
    getPosition: () =>
      new Promise((resolve, reject) => {
        if (!('geolocation' in navigator)) {
          reject('Геолокация не поддерживается');
          return;
        }
        if (!window.isSecureContext) {
          reject('GPS доступен только по HTTPS');
          return;
        }
        navigator.geolocation.getCurrentPosition(
          (pos) => {
            resolve(
              JSON.stringify({
                lat: pos.coords.latitude,
                lng: pos.coords.longitude,
                accuracy: pos.coords.accuracy,
              })
            );
          },
          (err) => {
            const map = {
              1: 'Разрешите доступ к геолокации в браузере',
              2: 'Не удалось определить координаты',
              3: 'Таймаут определения GPS',
            };
            reject(map[err.code] || err.message || 'Ошибка GPS');
          },
          { enableHighAccuracy: false, timeout: 20000, maximumAge: 60000 }
        );
      }),
  };

  // Re-arm timers after refresh if permission already granted
  window.addEventListener('load', () => {
    try {
      if (!('Notification' in window) || Notification.permission !== 'granted') return;
      const raw = localStorage.getItem('mihrab_web_reminders');
      if (raw) window.mihrabPwa.scheduleReminders(raw);
    } catch (_) {}
  });

  if (!('serviceWorker' in navigator) || !window.isSecureContext) return;

  const url = new URL('mihrab-sw.js', document.baseURI);
  window.addEventListener(
    'load',
    async () => {
      try {
        registration = await navigator.serviceWorker.getRegistration(
          new URL('./', url).pathname
        );
        if (!registration) {
          const response = await fetch(url, { cache: 'no-store' });
          if (!response.ok) return;
          registration = await navigator.serviceWorker.register(url, {
            scope: new URL('./', url).pathname,
            updateViaCache: 'none',
          });
        }
        registration.update().catch(() => {});
      } catch (error) {
        console.warn('MIHRAB SW unavailable', error);
      }
    },
    { once: true }
  );
})();
