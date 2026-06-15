import Phaser from "phaser";

export type TiledSceneTheme = "greenhouse" | "factory" | "archive";

type TiledObject = Phaser.Types.Tilemaps.TiledObject;

const mapKeys: Record<TiledSceneTheme, string> = {
  archive: "tiled-archive",
  factory: "tiled-factory",
  greenhouse: "tiled-greenhouse",
};

class TiledSceneRenderer {
  renderBackdrop(scene: Phaser.Scene, theme: TiledSceneTheme): void {
    if (!scene.cache.tilemap.exists(mapKeys[theme]) || !scene.textures.exists("eli-production-tileset")) {
      return;
    }
    const map = scene.make.tilemap({ key: mapKeys[theme] });
    const tileset = map.addTilesetImage("eli-production-tileset", "eli-production-tileset");
    if (!tileset) {
      return;
    }

    map.createLayer("floor", tileset, 0, 0)?.setAlpha(0.24).setDepth(0);
    map.createLayer("set_dressing", tileset, 0, 0)?.setAlpha(0.28).setDepth(0);
    map.createLayer("foreground_light", tileset, 0, 0)?.setAlpha(0.16).setDepth(0).setBlendMode(Phaser.BlendModes.ADD);
    this.renderProps(scene, theme, map);
  }

  private renderProps(scene: Phaser.Scene, theme: TiledSceneTheme, map: Phaser.Tilemaps.Tilemap): void {
    const objectLayer = map.getObjectLayer("layout");
    if (!objectLayer) {
      return;
    }
    objectLayer.objects.forEach((object) => {
      const id = this.runtimeId(object);
      if (theme === "greenhouse") {
        this.greenhouseProp(scene, id, object);
      } else if (theme === "factory") {
        this.factoryProp(scene, id, object);
      } else {
        this.archiveProp(scene, id, object);
      }
    });
  }

  private greenhouseProp(scene: Phaser.Scene, id: string, object: TiledObject): void {
    const rect = this.rect(object);
    if (id.startsWith("greenhouse:plant:")) {
      scene.add.ellipse(rect.cx, rect.cy + rect.height * 0.34, rect.width * 0.92, 26, 0x000000, 0.2).setDepth(0);
      scene.add.rectangle(rect.cx, rect.cy, rect.width * 0.9, rect.height * 0.78, 0x70d68a, 0.035).setStrokeStyle(2, 0x70d68a, 0.16).setDepth(0);
      scene.add.ellipse(rect.cx, rect.cy - rect.height * 0.35, rect.width * 0.88, 36, 0xf7d37a, 0.06).setStrokeStyle(1, 0xf7d37a, 0.22).setDepth(0);
      this.lightColumn(scene, rect.cx, rect.cy - 20, rect.width * 0.74, rect.height * 0.82, 0xf7d37a, 0);
    } else if (id === "greenhouse:dataPanel" || id === "greenhouse:objectivePanel") {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x0b221f, 0.16).setStrokeStyle(1, 0x70d68a, 0.18).setDepth(0);
    } else if (id === "greenhouse:graph") {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x071018, 0.32).setStrokeStyle(1, 0x70d68a, 0.22).setDepth(0);
    }
  }

  private factoryProp(scene: Phaser.Scene, id: string, object: TiledObject): void {
    const rect = this.rect(object);
    if (id.startsWith("factory:machine:")) {
      const isCenter = id === "factory:machine:8";
      scene.add.rectangle(rect.cx + 8, rect.cy + 10, rect.width, rect.height, 0x000000, 0.28).setDepth(0);
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x15202a, isCenter ? 0.26 : 0.34)
        .setStrokeStyle(2, isCenter ? 0xf6c85f : 0x8aa6b0, 0.24)
        .setDepth(0);
      scene.add.rectangle(rect.cx, rect.cy + rect.height * 0.34, rect.width * 0.82, 10, 0x0b1018, 0.56).setDepth(0);
    } else if (id === "factory:core") {
      scene.add.image(rect.cx, rect.cy, "soft-glow").setTint(0xf6c85f).setAlpha(0.18).setScale(2.4).setDepth(0);
      scene.add.circle(rect.cx, rect.cy, Math.max(rect.width, rect.height) * 0.42, 0xf6c85f, 0.06).setStrokeStyle(2, 0xf6c85f, 0.22).setDepth(0);
    } else if (id === "factory:controlPanel") {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x211d17, 0.16).setStrokeStyle(1, 0xf6c85f, 0.18).setDepth(0);
    }
  }

  private archiveProp(scene: Phaser.Scene, id: string, object: TiledObject): void {
    const rect = this.rect(object);
    if (id === "archive:shelves") {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x101521, 0.2).setStrokeStyle(2, 0x9f8cff, 0.18).setDepth(0);
      for (let y = rect.y + 54; y < rect.y + rect.height - 20; y += 76) {
        scene.add.rectangle(rect.cx, y, rect.width - 52, 14, 0x1b2030, 0.36).setDepth(0);
      }
    } else if (id.startsWith("archive:message:")) {
      scene.add.rectangle(rect.cx + 7, rect.cy + 8, rect.width, rect.height, 0x000000, 0.22).setDepth(0);
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x241b2a, 0.24).setStrokeStyle(1, 0x9f8cff, 0.22).setDepth(0);
      scene.add.rectangle(rect.x + 18, rect.y + 16, rect.width * 0.34, 3, 0xf7d37a, 0.34).setOrigin(0).setDepth(0);
    } else if (id === "archive:terminal") {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x0d1b26, 0.28).setStrokeStyle(2, 0x9f8cff, 0.22).setDepth(0);
    } else if (id.endsWith("Panel")) {
      scene.add.rectangle(rect.cx, rect.cy, rect.width, rect.height, 0x171925, 0.14).setStrokeStyle(1, 0x9f8cff, 0.14).setDepth(0);
    }
  }

  private lightColumn(scene: Phaser.Scene, x: number, y: number, width: number, height: number, color: number, depth: number): void {
    scene.add.triangle(x, y, -width / 2, -height / 2, width / 2, -height / 2, 0, height / 2, color, 0.045).setDepth(depth);
  }

  private rect(object: TiledObject): { x: number; y: number; width: number; height: number; cx: number; cy: number } {
    const x = object.x ?? 0;
    const y = object.y ?? 0;
    const width = object.width ?? 32;
    const height = object.height ?? 32;
    return { x, y, width, height, cx: x + width / 2, cy: y + height / 2 };
  }

  private runtimeId(object: TiledObject): string {
    const property = object.properties?.find((item: { name: string; value?: unknown }) => item.name === "runtimeId");
    return typeof property?.value === "string" ? property.value : object.name ?? "";
  }
}

export const tiledSceneRenderer = new TiledSceneRenderer();
