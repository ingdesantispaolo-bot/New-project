import type { ProceduralSpecialization } from "../../procedural/ProceduralTypes";

export type MenuRect = {
  id: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
};

export type FocusOption = { id: ProceduralSpecialization; label: string };
export type FocusButtonSpec = MenuRect & { focus: ProceduralSpecialization };
export type ShortcutButtonSpec = MenuRect & {
  sceneKey: string;
  fill: number;
  stroke?: number;
  failureMessage?: string;
};

export const focusOptions: FocusOption[] = [
  { id: "matematica", label: "Focus matematica" },
  { id: "italiano", label: "Focus italiano" },
  { id: "inglese", label: "Focus inglese" },
  { id: "elettronica", label: "Focus circuiti" },
  { id: "coding", label: "Focus coding" },
  { id: "musica", label: "Focus musica" },
  { id: "fisica", label: "Focus fisica" },
  { id: "latino", label: "Focus latino" },
];

export function palestraFocusButtons(): FocusButtonSpec[] {
  return focusOptions.map((focus, index) => {
    const col = index % 4;
    const row = Math.floor(index / 4);
    return {
      id: `focus-${focus.id}`,
      focus: focus.id,
      label: focus.label.replace("Focus ", ""),
      x: 236 + col * 150,
      y: 522 + row * 46,
      width: 142,
      height: 40,
    };
  });
}

export function palestraShortcutButtons(): ShortcutButtonSpec[] {
  return [
    {
      id: "shortcut-codex",
      label: "📖 Codex",
      sceneKey: "CodexScene",
      x: 222,
      y: 620,
      width: 168,
      height: 44,
      fill: 0x1f4a44,
      stroke: 0x6be7d6,
      failureMessage: "Non sono riuscito ad aprire il Codex. Riprova tra un istante.",
    },
    {
      id: "shortcut-world",
      label: "🕹️ Mappa viva",
      sceneKey: "ExplorableRoomScene",
      x: 406,
      y: 620,
      width: 170,
      height: 44,
      fill: 0x24344a,
      stroke: 0x7ad7ff,
      failureMessage: "Non sono riuscito ad aprire la mappa esplorabile. Riprova tra un istante.",
    },
    {
      id: "shortcut-outdoor",
      label: "🌄 Avventura",
      sceneKey: "OutdoorAdventureScene",
      x: 594,
      y: 620,
      width: 178,
      height: 44,
      fill: 0x1f3f2f,
      stroke: 0x8fe0a4,
      failureMessage: "Non sono riuscito ad aprire l'avventura esterna. Riprova tra un istante.",
    },
    {
      id: "shortcut-shop",
      label: "🛍️ Bottega",
      sceneKey: "RewardShopScene",
      x: 790,
      y: 620,
      width: 170,
      height: 44,
      fill: 0x3a3220,
      stroke: 0xf6c85f,
      failureMessage: "Non sono riuscito ad aprire la Bottega. Riprova tra un istante.",
    },
    { id: "shortcut-close", label: "Chiudi", sceneKey: "close", x: 1010, y: 620, width: 180, height: 44, fill: 0x263743 },
  ];
}

export function rectsOverlap(a: MenuRect, b: MenuRect, gap = 0): boolean {
  const aLeft = a.x - a.width / 2 - gap;
  const aRight = a.x + a.width / 2 + gap;
  const aTop = a.y - a.height / 2 - gap;
  const aBottom = a.y + a.height / 2 + gap;
  const bLeft = b.x - b.width / 2;
  const bRight = b.x + b.width / 2;
  const bTop = b.y - b.height / 2;
  const bBottom = b.y + b.height / 2;
  return aLeft < bRight && aRight > bLeft && aTop < bBottom && aBottom > bTop;
}
