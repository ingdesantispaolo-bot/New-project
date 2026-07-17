import type { ProceduralSpecialization } from "../../procedural/ProceduralTypes";
import type { RoomWall } from "../../scenes/procedural/RoomExplorer";

/**
 * Registro dei PONTI esplorabili del Relitto dei Primi (dati puri, nessuna logica).
 *
 * Ogni ponte è una configurazione dichiarativa consumata da
 * {@link ExplorableRoomScene} tramite il motore riusabile {@link RoomExplorer}:
 * niente motore nuovo per aggiungere una mappa, basta un oggetto qui.
 *
 * Il contenuto delle prove resta procedurale: il ponte definisce solo *dove*
 * si trovano le console e *quale focus* avviano. Le console con `targetArea`
 * (o `id === "exit"`) sono nodi di navigazione tra mappe, non allenamenti.
 */
export type AreaConsoleSpec = {
  id: string;
  /** Frame base nell'atlante "mission-consoles" (console_{assetId}_{active|resolved}). */
  assetId?: string;
  /** Focus procedurale avviato dalla console; assente per i nodi di navigazione. */
  focus?: ProceduralSpecialization;
  label: string;
  glyph: string;
  color: number;
  x: number;
  y: number;
  w: number;
  h: number;
  summary?: string;
  /** Nodo di navigazione: id del ponte di destinazione. `exit` senza target torna al menu. */
  targetArea?: string;
  /** Nodo di navigazione verso una scena non-esplorabile (es. la Storia). */
  targetScene?: string;
};

export type MapAreaDef = {
  id: string;
  label: string;
  /** Chiave texture dello sfondo; RoomExplorer ripiega su un pavimento a griglia se assente. */
  bgTexture: string;
  /** Tinta del pavimento placeholder finché lo sfondo non è caricato. */
  floorColor?: number;
  accent: number;
  worldW: number;
  worldH: number;
  walls: RoomWall[];
  consoles: AreaConsoleSpec[];
  /** Sovrappone i props ambientali condivisi. Off per aree con arte già ricca. */
  decorate?: boolean;
  /** Settori distinti da padroneggiare per sbloccare il ponte. 0 = aperto. */
  unlock?: number;
};

const WORLD_W = 1760;
const WORLD_H = 1120;

const perimeter = (): RoomWall[] => [
  { x: 0, y: 0, w: WORLD_W, h: 40 },
  { x: 0, y: WORLD_H - 40, w: WORLD_W, h: 40 },
  { x: 0, y: 0, w: 40, h: WORLD_H },
  { x: WORLD_W - 40, y: 0, w: 40, h: WORLD_H },
];

/** Nodi di navigazione comuni: ritorno al laboratorio + uscita al menu. */
const backToLab = (x: number, y: number): AreaConsoleSpec =>
  ({ id: "to-lab", assetId: "exit", label: "Ponte Centrale", glyph: "◆", color: 0x7ad7ff, x, y, w: 120, h: 150, summary: "Torna al nodo centrale del Relitto.", targetArea: "laboratorio" });
const areaExit = (x: number, y: number): AreaConsoleSpec =>
  ({ id: "exit", assetId: "exit", label: "Ritorno", glyph: "◇", color: 0xffd75e, x, y, w: 120, h: 150 });

/**
 * PONTE CENTRALE — hub principale. Mantiene la stanza collaudata,
 * con varchi verso i ponti del Relitto.
 */
const laboratorio: MapAreaDef = {
  id: "laboratorio",
  label: "Ponte Centrale",
  bgTexture: "action-room-bg",
  accent: 0x6be7d6,
  decorate: true,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: [
    ...perimeter(),
    { x: 520, y: 470, w: 70, h: 240 },
    { x: 1170, y: 470, w: 70, h: 240 },
  ],
  consoles: [
    { id: "math", assetId: "math", focus: "matematica", label: "Matematica", glyph: "➗", color: 0x6be7d6, x: 250, y: 250, w: 120, h: 150, summary: "Grafici, vincoli, calcolo e passaggi controllati." },
    { id: "italian", assetId: "italian", focus: "italiano", label: "Italiano", glyph: "✒️", color: 0x9f8cff, x: 710, y: 210, w: 120, h: 150, summary: "Frasi, log, nessi logici e significato operativo." },
    { id: "english", assetId: "english", focus: "inglese", label: "Inglese", glyph: "🌍", color: 0x7ad7ff, x: 1180, y: 250, w: 120, h: 150, summary: "Comandi autentici, lessico utile e comprensione reale." },
    { id: "coding", assetId: "coding", focus: "coding", label: "Coding", glyph: "💻", color: 0x7cf6a6, x: 320, y: 840, w: 120, h: 150, summary: "Sequenze, debug, cicli, condizioni e robot." },
    { id: "circuit", assetId: "electronics", focus: "elettronica", label: "Circuiti", glyph: "⚡", color: 0xf6c85f, x: 1180, y: 840, w: 120, h: 150, summary: "Componenti, corrente, protezione e diagnosi graduale." },
    { id: "music", assetId: "music", focus: "musica", label: "Musica", glyph: "🎵", color: 0xff9d5c, x: 760, y: 900, w: 120, h: 150, summary: "Note, pentagramma, ritmo e lettura rapida." },
    { id: "physics", assetId: "physics", focus: "fisica", label: "Fisica", glyph: "F", color: 0x9ff5e9, x: 1490, y: 250, w: 120, h: 150, summary: "Forze, grandezze, unità, relazioni e ragionamento." },
    { id: "storia", assetId: "story", label: "Il Relitto", glyph: "◇", color: 0xffd75e, x: 480, y: 240, w: 120, h: 150, summary: "La scoperta della nave dei Primi e della mente che la custodisce: NORA.", targetScene: "CampaignScene" },
    { id: "spedizione", assetId: "progressive", focus: "libera", label: "Spedizione", glyph: "◆", color: 0xf6c85f, x: 960, y: 800, w: 132, h: 160, summary: "Il portale centrale: una missione generata che attraversa tutti i ponti del Relitto." },
    { id: "to-serra", assetId: "exit", label: "Bio-ponte", glyph: "◇", color: 0x7cf6a6, x: 300, y: 560, w: 120, h: 150, summary: "Giardino sospeso dei Primi: colture, ambiente e dati.", targetArea: "serra-bio" },
    { id: "to-circuiti", assetId: "exit", label: "Reattore", glyph: "◆", color: 0xf6c85f, x: 680, y: 560, w: 120, h: 150, summary: "Camera del cuore-nave: energia, condotti e diagnosi.", targetArea: "cantiere-circuiti" },
    { id: "to-osservatorio", assetId: "exit", label: "Ponte di Comando", glyph: "◇", color: 0x9f8cff, x: 890, y: 560, w: 120, h: 150, summary: "Carte stellari dei Primi, fisica, orbite e segnali.", targetArea: "osservatorio" },
    { id: "to-musica", assetId: "exit", label: "Motore a Risonanza", glyph: "◆", color: 0xff9d5c, x: 1100, y: 560, w: 120, h: 150, summary: "Strumento-motore della nave: onde, ritmo e ascolto.", targetArea: "sala-musica" },
    { id: "to-archivio", assetId: "exit", label: "Data-core", glyph: "◇", color: 0x7ad7ff, x: 1460, y: 560, w: 120, h: 150, summary: "Memoria della nave: lingue, testi e codici.", targetArea: "archivio-biblioteca" },
    { id: "to-biblioteca", assetId: "exit", label: "Sala dei Glifi", glyph: "◆", color: 0xd8a24a, x: 1620, y: 560, w: 120, h: 150, summary: "Parete dei Primi: latino, glifi e radici antiche.", targetArea: "biblioteca-classica" },
    { id: "outdoor-gate", assetId: "portal", label: "Varco Esterno", glyph: "🌄", color: 0x8fe0a4, x: 1420, y: 900, w: 136, h: 162, summary: "Esci dal Relitto: mappa esterna procedurale, biomi, tesori e pericoli giorno/notte.", targetScene: "OutdoorAdventureScene" },
    { id: "exit", assetId: "nora", label: "NORA", glyph: "◇", color: 0xffd75e, x: 1620, y: 900, w: 120, h: 150, summary: "La mente della nave: scorciatoie, progressi e strumenti." },
  ],
};

/**
 * BIO-PONTE — giardino sospeso dei Primi.
 * Tema natura + dati: focus su matematica, fisica e italiano.
 */
const serraBio: MapAreaDef = {
  id: "serra-bio",
  label: "Bio-ponte",
  bgTexture: "area-serra-bio",
  floorColor: 0x0c2416,
  accent: 0x7cf6a6,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  // Il centro della serra è pavimento libero; le vasche dipinte sono sul
  // perimetro, quindi bastano i muri perimetrali (niente box interni fittizi).
  walls: perimeter(),
  // Coordinate allineate agli alloggiamenti dipinti nello sfondo (dock template:
  // console a (630/1130, 360/720), archi-porta a (880,560) e (880,880)).
  consoles: [
    { id: "math", assetId: "math", focus: "matematica", label: "Dati Colture", glyph: "➗", color: 0x6be7d6, x: 630, y: 360, w: 120, h: 150, summary: "Misure, proporzioni e crescita delle colture dei Primi." },
    { id: "italian", assetId: "italian", focus: "italiano", label: "Registro Bio", glyph: "✒️", color: 0x9f8cff, x: 1130, y: 360, w: 120, h: 150, summary: "Log di coltivazione e istruzioni operative." },
    { id: "physics", assetId: "physics", focus: "fisica", label: "Ambiente", glyph: "F", color: 0x9ff5e9, x: 630, y: 720, w: 120, h: 150, summary: "Luce, temperatura, umidità: grandezze e relazioni." },
    { id: "music", assetId: "music", focus: "musica", label: "Bio-ritmi", glyph: "🎵", color: 0xff9d5c, x: 1130, y: 720, w: 120, h: 150, summary: "Cicli, pattern e lettura ordinata." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

/**
 * REATTORE — camera del cuore-nave (accenti oro). Perimetro con
 * condotti e pannelli dipinti, centro libero.
 */
const cantiereCircuiti: MapAreaDef = {
  id: "cantiere-circuiti",
  label: "Reattore",
  bgTexture: "area-cantiere-circuiti",
  unlock: 1,
  floorColor: 0x0c1a1f,
  accent: 0xf6c85f,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: perimeter(),
  consoles: [
    { id: "circuit", assetId: "electronics", focus: "elettronica", label: "Condotti", glyph: "⚡", color: 0xf6c85f, x: 630, y: 360, w: 120, h: 150, summary: "Componenti, corrente, protezione e diagnosi." },
    { id: "math", assetId: "math", focus: "matematica", label: "Misure", glyph: "➗", color: 0x6be7d6, x: 1130, y: 360, w: 120, h: 150, summary: "Letture, unità e calcolo delle grandezze." },
    { id: "coding", assetId: "coding", focus: "coding", label: "Logica", glyph: "💻", color: 0x7cf6a6, x: 630, y: 720, w: 120, h: 150, summary: "Condizioni, sequenze e controllo del sistema." },
    { id: "physics", assetId: "physics", focus: "fisica", label: "Energia", glyph: "F", color: 0x9ff5e9, x: 1130, y: 720, w: 120, h: 150, summary: "Tensione, potenza e trasformazioni." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

/**
 * PONTE DI COMANDO — sala stellare dei Primi (accenti viola). Le carte
 * stellari sono dipinte sul perimetro: le console restano nel centro aperto.
 */
const osservatorio: MapAreaDef = {
  id: "osservatorio",
  label: "Ponte di Comando",
  bgTexture: "area-osservatorio",
  unlock: 2,
  floorColor: 0x0b1226,
  accent: 0x9f8cff,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: perimeter(),
  consoles: [
    { id: "physics", assetId: "physics", focus: "fisica", label: "Rotte", glyph: "F", color: 0x9ff5e9, x: 630, y: 360, w: 120, h: 150, summary: "Moto, forze, energia e lettura dei dati." },
    { id: "math", assetId: "math", focus: "matematica", label: "Carte Stellari", glyph: "➗", color: 0x6be7d6, x: 1130, y: 360, w: 120, h: 150, summary: "Distanze, proporzioni e traiettorie." },
    { id: "english", assetId: "english", focus: "inglese", label: "Protocolli", glyph: "🌍", color: 0x7ad7ff, x: 630, y: 720, w: 120, h: 150, summary: "Istruzioni scientifiche in inglese operativo." },
    { id: "music", assetId: "music", focus: "musica", label: "Segnali", glyph: "🎵", color: 0xff9d5c, x: 1130, y: 720, w: 120, h: 150, summary: "Pattern periodici, frequenze e lettura ordinata." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

/**
 * MOTORE A RISONANZA — strumento-motore della nave. Gli elementi di risonanza
 * sono dipinti sul perimetro: le console restano nel centro aperto.
 */
const salaMusica: MapAreaDef = {
  id: "sala-musica",
  label: "Motore a Risonanza",
  bgTexture: "area-sala-musica",
  unlock: 3,
  floorColor: 0x14100a,
  accent: 0xff9d5c,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: perimeter(),
  consoles: [
    { id: "music", assetId: "music", focus: "musica", label: "Risonanza", glyph: "🎵", color: 0xff9d5c, x: 630, y: 360, w: 120, h: 150, summary: "Onde, ritmo, note e lettura rapida." },
    { id: "math", assetId: "math", focus: "matematica", label: "Ritmo", glyph: "➗", color: 0x6be7d6, x: 1130, y: 360, w: 120, h: 150, summary: "Frazioni, tempo e intervalli." },
    { id: "italian", assetId: "italian", focus: "italiano", label: "Testi", glyph: "✒️", color: 0x9f8cff, x: 630, y: 720, w: 120, h: 150, summary: "Comprensione, nessi e significato dei brani." },
    { id: "english", assetId: "english", focus: "inglese", label: "Audio EN", glyph: "🌍", color: 0x7ad7ff, x: 1130, y: 720, w: 120, h: 150, summary: "Etichette e comandi audio in inglese." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

/**
 * DATA-CORE — memoria della nave (strutture dati dipinte sul perimetro).
 * Hub delle lingue: italiano, inglese e log/codici.
 */
const archivioBiblioteca: MapAreaDef = {
  id: "archivio-biblioteca",
  label: "Data-core",
  bgTexture: "area-archivio-biblioteca",
  unlock: 4,
  floorColor: 0x0d1420,
  accent: 0x7ad7ff,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: perimeter(),
  consoles: [
    { id: "italian", assetId: "italian", focus: "italiano", label: "Frammenti", glyph: "✒️", color: 0x9f8cff, x: 630, y: 360, w: 120, h: 150, summary: "Comprensione, coesione e lessico preciso." },
    { id: "english", assetId: "english", focus: "inglese", label: "Traduzioni", glyph: "🌍", color: 0x7ad7ff, x: 1130, y: 360, w: 120, h: 150, summary: "Comandi, lessico e comprensione reale." },
    { id: "coding", assetId: "coding", focus: "coding", label: "Log & Codici", glyph: "💻", color: 0x7cf6a6, x: 630, y: 720, w: 120, h: 150, summary: "Tracing, variabili e debug dei registri." },
    { id: "math", assetId: "math", focus: "matematica", label: "Indici", glyph: "➗", color: 0x6be7d6, x: 1130, y: 720, w: 120, h: 150, summary: "Ordinamento, codici e passaggi controllati." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

/**
 * SALA DEI GLIFI — parete di scrittura aliena dei Primi. Casa del Latino come
 * lingua antica del Relitto, con discipline affini e numeri antichi.
 */
const bibliotecaClassica: MapAreaDef = {
  id: "biblioteca-classica",
  label: "Sala dei Glifi",
  bgTexture: "area-biblioteca-classica",
  unlock: 2,
  floorColor: 0x1a1408,
  accent: 0xd8a24a,
  decorate: false,
  worldW: WORLD_W,
  worldH: WORLD_H,
  walls: perimeter(),
  consoles: [
    { id: "latin", assetId: "latin", focus: "latino", label: "Lingua dei Primi", glyph: "◇", color: 0xd8a24a, x: 630, y: 360, w: 120, h: 150, summary: "Declinazioni, verbo, casi, lessico e sintassi della lingua dei Primi." },
    { id: "italian", assetId: "italian", focus: "italiano", label: "Grammatica", glyph: "✒️", color: 0x9f8cff, x: 1130, y: 360, w: 120, h: 150, summary: "Analisi, comprensione e lessico preciso." },
    { id: "english", assetId: "english", focus: "inglese", label: "Radici Comuni", glyph: "🌍", color: 0x7ad7ff, x: 630, y: 720, w: 120, h: 150, summary: "Lessico e radici condivise col latino." },
    { id: "math", assetId: "math", focus: "matematica", label: "Numeri Antichi", glyph: "➗", color: 0x6be7d6, x: 1130, y: 720, w: 120, h: 150, summary: "Calcolo, misure e ordine dei passaggi." },
    backToLab(880, 560),
    areaExit(880, 880),
  ],
};

export const MAP_AREAS: Record<string, MapAreaDef> = {
  laboratorio,
  "serra-bio": serraBio,
  "cantiere-circuiti": cantiereCircuiti,
  osservatorio,
  "sala-musica": salaMusica,
  "archivio-biblioteca": archivioBiblioteca,
  "biblioteca-classica": bibliotecaClassica,
};

export const DEFAULT_AREA_ID = "laboratorio";

export function getMapArea(id?: string): MapAreaDef {
  return (id && MAP_AREAS[id]) || MAP_AREAS[DEFAULT_AREA_ID];
}
