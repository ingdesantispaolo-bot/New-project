import { audioManager } from "./AudioManager";
import { EventBus, GameEvents } from "./EventBus";

export class ViewportSystem {
  private static installed = false;
  private static orientationOverlay?: HTMLElement;

  static install(): void {
    if (this.installed || typeof window === "undefined" || typeof document === "undefined") {
      return;
    }
    this.installed = true;
    this.applyViewportFlags();
    this.createOrientationOverlay();
    this.update();
    window.addEventListener("resize", () => this.update(), { passive: true });
    window.addEventListener("orientationchange", () => window.setTimeout(() => this.update(), 120), { passive: true });
    document.addEventListener("visibilitychange", () => {
      this.update();
      EventBus.emit(document.hidden ? GameEvents.RuntimePauseRequested : GameEvents.RuntimeResumeRequested, "visibility");
    }, { passive: true });
    window.addEventListener("blur", () => EventBus.emit(GameEvents.RuntimePauseRequested, "blur"), { passive: true });
    window.addEventListener("focus", () => EventBus.emit(GameEvents.RuntimeResumeRequested, "focus"), { passive: true });
    window.addEventListener("pagehide", () => EventBus.emit(GameEvents.RuntimePauseRequested, "pagehide"), { passive: true });
    document.addEventListener("contextmenu", (event) => event.preventDefault());
    document.addEventListener("dragstart", (event) => event.preventDefault());
    audioManager.installUnlockListeners();
    this.registerServiceWorker();
  }

  private static applyViewportFlags(): void {
    document.documentElement.classList.add("eli-quest-runtime");
  }

  private static createOrientationOverlay(): void {
    const overlay = document.createElement("div");
    overlay.id = "orientation-warning";
    overlay.setAttribute("aria-live", "polite");
    overlay.innerHTML = `
      <div class="orientation-card">
        <div class="orientation-mark">ELI QUEST</div>
        <h1>Ruota il tablet</h1>
        <p>La sala dell'Accademia è progettata per giocare in orizzontale, con console grandi e testi leggibili.</p>
      </div>
    `;
    document.body.appendChild(overlay);
    this.orientationOverlay = overlay;
  }

  private static update(): void {
    const coarsePointer = window.matchMedia?.("(pointer: coarse)").matches ?? false;
    const smallViewport = Math.min(window.innerWidth, window.innerHeight) < 820;
    const tabletLike = coarsePointer || smallViewport;
    const portrait = window.innerHeight > window.innerWidth;
    document.body.classList.toggle("tablet-mode", tabletLike);
    document.body.classList.toggle("portrait-blocked", tabletLike && portrait);
    this.orientationOverlay?.classList.toggle("visible", tabletLike && portrait);
    EventBus.emit(tabletLike && portrait ? GameEvents.RuntimePauseRequested : GameEvents.RuntimeResumeRequested, "orientation");
  }

  private static registerServiceWorker(): void {
    if (!("serviceWorker" in navigator)) {
      return;
    }

    if (import.meta.env.DEV) {
      this.clearDevelopmentServiceWorker();
      return;
    }

    window.addEventListener("load", () => {
      const base = import.meta.env.BASE_URL;
      const scriptUrl = new URL(`${base}sw.js`, window.location.href);
      const buildId = import.meta.env.VITE_BUILD_REF ?? import.meta.env.VITE_BUILD_TIME ?? "local-build";
      scriptUrl.searchParams.set("v", buildId);

      // Reload only when a NEW worker takes control of a page that was already
      // controlled: never on first install, never mid-game without consent.
      const wasControlled = Boolean(navigator.serviceWorker.controller);
      let reloadingForUpdate = false;
      navigator.serviceWorker.addEventListener("controllerchange", () => {
        if (!wasControlled || reloadingForUpdate) {
          return;
        }
        reloadingForUpdate = true;
        window.location.reload();
      });

      navigator.serviceWorker.register(scriptUrl, {
        scope: base,
        updateViaCache: "none",
      }).then((registration) => {
        this.watchForWaitingWorker(registration);
        registration.update().catch(() => {
          // The browser will retry future update checks.
        });
        // Check again when the app regains focus (a tablet left open for days
        // would otherwise never learn about new versions), at most every 15'.
        let lastCheck = Date.now();
        document.addEventListener("visibilitychange", () => {
          if (document.hidden || Date.now() - lastCheck < 15 * 60_000) {
            return;
          }
          lastCheck = Date.now();
          registration.update().catch(() => undefined);
        }, { passive: true });
      }).catch(() => {
        // Offline caching is optional; the game remains playable online.
      });
    }, { once: true });
  }

  /** Shows a consent banner when a new version is installed and waiting. */
  private static watchForWaitingWorker(registration: ServiceWorkerRegistration): void {
    if (registration.waiting && navigator.serviceWorker.controller) {
      this.showUpdateBanner(registration);
      return;
    }
    registration.addEventListener("updatefound", () => {
      const incoming = registration.installing;
      incoming?.addEventListener("statechange", () => {
        if (incoming.state === "installed" && navigator.serviceWorker.controller) {
          this.showUpdateBanner(registration);
        }
      });
    });
  }

  private static showUpdateBanner(registration: ServiceWorkerRegistration): void {
    if (document.getElementById("update-banner")) {
      return;
    }
    const banner = document.createElement("div");
    banner.id = "update-banner";
    banner.setAttribute("role", "status");
    banner.innerHTML = `
      <span class="update-banner-text">Nuova versione disponibile</span>
      <button type="button" class="update-banner-apply">Aggiorna ora</button>
      <button type="button" class="update-banner-later" aria-label="Rimanda">Più tardi</button>
    `;
    banner.querySelector(".update-banner-apply")?.addEventListener("click", () => {
      banner.remove();
      // controllerchange (sopra) ricarica la pagina quando il worker si attiva.
      registration.waiting?.postMessage({ type: "SKIP_WAITING" });
    });
    banner.querySelector(".update-banner-later")?.addEventListener("click", () => {
      banner.remove();
    });
    document.body.appendChild(banner);
  }

  private static clearDevelopmentServiceWorker(): void {
    window.addEventListener("load", () => {
      navigator.serviceWorker.getRegistrations()
        .then((registrations) => Promise.all(registrations.map((registration) => registration.unregister())))
        .catch(() => undefined);
      if ("caches" in window) {
        caches.keys()
          .then((keys) => Promise.all(keys
            .filter((key) => key.startsWith("eli-quest-"))
            .map((key) => caches.delete(key))))
          .catch(() => undefined);
      }
    }, { once: true });
  }
}
