import { noraPresence } from "./NoraPresence";

// Compatibility facade: existing scenes still call `noraChip.say`, but the
// implementation is now the persistent companion presence.
class NoraChip {
  say(scene: Phaser.Scene, text: string, tone: "info" | "success" | "warning" = "info"): void {
    noraPresence.speak(scene, text, tone);
  }
}

export const noraChip = new NoraChip();
