export type AssetKind = "background" | "atlas" | "map";
export type AssetSourceTool = "generated" | "ldtk" | "tiled" | "aseprite" | "texturepacker";

export interface ProductionAsset {
  id: string;
  kind: AssetKind;
  sourceTool: AssetSourceTool;
  runtimeKey: string;
  sourcePath: string;
  optimizedPath: string;
  notes: string;
}

export const productionAssets: ProductionAsset[] = [
  {
    id: "painted-backgrounds",
    kind: "background",
    sourceTool: "generated",
    runtimeKey: "bg-*-painted",
    sourcePath: "src/assets/images/*-painted-bg.png",
    optimizedPath: "src/assets/images/*-painted-bg.webp",
    notes: "Fondali pittorici esportati in WebP/AVIF tramite scripts/optimize-assets.mjs.",
  },
  {
    id: "eli-quest-atlas",
    kind: "atlas",
    sourceTool: "texturepacker",
    runtimeKey: "eli-atlas",
    sourcePath: "scripts/build-visual-assets.mjs",
    optimizedPath: "src/assets/sprites/eli-quest-atlas.webp",
    notes: "Atlas TexturePacker-compatible. Sostituibile con export Aseprite/TexturePacker reale mantenendo frame names stabili.",
  },
  {
    id: "academy-lab-map",
    kind: "map",
    sourceTool: "ldtk",
    runtimeKey: "academy-lab-map",
    sourcePath: "src/assets/maps/academy-lab.ldtk.json",
    optimizedPath: "src/assets/maps/academy-lab.ldtk.json",
    notes: "Contratto iniziale per passare hotspot e layer da codice a map editor.",
  },
];
