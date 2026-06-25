import Phaser from "phaser";
import { settingsSystem } from "./SettingsSystem";

export class ReadableTextSystem {
  private static installed = false;

  static install(): void {
    if (this.installed) return;
    this.installed = true;
    const factory = Phaser.GameObjects.GameObjectFactory.prototype as Phaser.GameObjects.GameObjectFactory & {
      text: (x: number, y: number, text: string | string[], style?: Phaser.Types.GameObjects.Text.TextStyle) => Phaser.GameObjects.Text;
    };
    const original = factory.text;
    factory.text = function readableText(x, y, text, style = {}) {
      const nextStyle = { ...style };
      const raw = nextStyle.fontSize;
      const numeric = typeof raw === "number" ? raw : typeof raw === "string" ? Number.parseFloat(raw) : undefined;
      if (numeric && Number.isFinite(numeric)) {
        nextStyle.fontSize = `${settingsSystem.scaledFontSize(numeric)}px`;
      }
      return original.call(this, x, y, text, nextStyle);
    };
  }
}
