import { audioManager } from "./AudioManager";

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
    document.addEventListener("visibilitychange", () => this.update(), { passive: true });
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
  }

  private static registerServiceWorker(): void {
    if (!("serviceWorker" in navigator)) {
      return;
    }
    window.addEventListener("load", () => {
      const base = import.meta.env.BASE_URL;
      const scriptUrl = new URL(`${base}sw.js`, window.location.href);
      navigator.serviceWorker.register(scriptUrl, { scope: base }).catch(() => {
        // Offline caching is optional; the game remains playable online.
      });
    }, { once: true });
  }
}
