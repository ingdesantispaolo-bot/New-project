import type Phaser from "phaser";
import { rewardSystem } from "../core/RewardSystem";
import { saveSystem } from "../core/SaveSystem";
import { startScene } from "../core/SceneNavigator";
import { resolveOutdoorPresentation } from "./outdoorAvatar";
import { createOutdoorWorldRequest, openOutdoorGodot } from "./outdoorGodotBridge";

// Ingresso UNICO al mondo esterno, condiviso da tutte le porte (varco della
// stanza, scorciatoia del menu, …): apre il modulo Godot se il bundle Web è
// presente, altrimenti ricade sul mondo esterno Phaser nativo. Così esiste una
// sola esperienza, coerente da qualunque punto si entri.

export function godotOutdoorUrl(): string {
  return import.meta.env.VITE_GODOT_OUTDOOR_URL ?? `${import.meta.env.BASE_URL}godot/outdoor/index.html`;
}

/** Sonda `index.wasm` (sentinella affidabile: niente fallback SPA sui file). */
export async function isGodotOutdoorAvailable(): Promise<boolean> {
  const probe = `${godotOutdoorUrl().replace(/index\.html$/, "")}index.wasm`;
  try {
    const response = await fetch(probe, { method: "HEAD", cache: "no-store" });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Apre il mondo esterno dalla scena data. Con bundle Godot presente naviga al
 * modulo Web (portando avatar + economia); altrimenti avvia la scena Phaser
 * nativa come fallback, con ritorno alla scena di partenza. Rilancia in caso di
 * errore imprevisto così il chiamante può ripristinare la sua UI.
 */
export async function openOutdoorWorld(scene: Phaser.Scene): Promise<void> {
  if (await isGodotOutdoorAvailable()) {
    saveSystem.load();
    const request = createOutdoorWorldRequest(
      saveSystem.data,
      rewardSystem.playerLevel(),
      window.location.href,
      undefined,
      resolveOutdoorPresentation(rewardSystem.playerLevel()),
    );
    openOutdoorGodot(godotOutdoorUrl(), request);
    return;
  }
  await startScene(scene, "OutdoorAdventureScene", { returnScene: scene.scene.key });
}
