import type { GymActivityKey, LogicGymActivityDefinition } from "./LogicGymTypes";

export const GYM_MIN_LEVEL = 1;
export const GYM_MAX_LEVEL = 8;
export const PAD_COLORS = [0xff5d7a, 0x6be7d6, 0xf6c85f, 0x70d68a, 0x9f8cff, 0xff9ad2];
export const CODE_SYMBOLS = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠"];

export const LOGIC_GYM_ACTIVITIES: LogicGymActivityDefinition[] = [
  { key: "tables", title: "Tabelline Reactor", glyph: "x", icon: "gym-tables", theme: "Matematica rapida", color: 0xf6c85f, desc: "Ricarica il reattore con prodotti, fattori mancanti e operazioni inverse. Combo alta = punteggio alto." },
  { key: "mental", title: "Calcolo Mentale", glyph: "+-", icon: "gym-mental", theme: "Aritmetica sprint", color: 0x5ec8ff, desc: "Risolvi somme, differenze, catene, doppi, meta e percentuali con strategie rapide. Il tempo pesa." },
  { key: "geo", title: "Geo Atlante", glyph: "◎", icon: "gym-geo", theme: "Capitali e continenti", color: 0x70d68a, desc: "Segui rotte, capitali e continenti. Ogni risposta precisa accende un nuovo pin sulla mappa." },
  { key: "geoPhysical", title: "Geo Rilievi", glyph: "△", icon: "gym-geo-physical", theme: "Geografia fisica", color: 0x9f8cff, desc: "Riconosci fiumi, laghi, montagne, deserti, mari e stretti. La mappa mostra forma, zona e traccia." },
  { key: "simon", title: "Sequenza Luminosa", glyph: "S", icon: "gym-simon", theme: "Memoria", color: 0x6be7d6, desc: "Guarda la sequenza di luci e ripetila. Si allunga a ogni turno!" },
  { key: "memory", title: "Memory delle Coppie", glyph: "M", icon: "gym-memory", theme: "Memoria", color: 0xff9ad2, desc: "Trova le coppie equivalenti (1/2 = 0,5, dog = cane…) con meno mosse possibili." },
  { key: "code", title: "Codice Segreto", glyph: "C", icon: "gym-code", theme: "Logica", color: 0xf6c85f, desc: "Indovina il codice nascosto deducendolo dagli indizi. Stile Mastermind." },
  { key: "seq", title: "Sequenze Logiche", glyph: "→", icon: "gym-seq", theme: "Logica", color: 0x70d68a, desc: "Scopri la regola e trova il termine che continua la serie." },
  { key: "balance", title: "Bilancia Logica", glyph: "=", icon: "gym-balance", theme: "Logica", color: 0xf6c85f, desc: "Deduci chi pesa di più (o di meno) mettendo in fila gli indizi." },
  { key: "flash", title: "Griglia Lampo", glyph: "!", icon: "gym-flash", theme: "Memoria", color: 0x6be7d6, desc: "Memorizza le caselle che lampeggiano e ricostruiscile. Aumentano ogni turno!" },
  { key: "firewall", title: "Firewall NORA", glyph: "FW", icon: "gym-firewall", theme: "Cyber-logica", color: 0x5ec8ff, desc: "Classifica segnali: consenti, blocca, quarantena o ispeziona seguendo regole crescenti." },
];

export type LogicGymLevelMetrics = {
  tablesTotal: number;
  tablesMaxFactor: number;
  mentalTotal: number;
  mentalNumberCap: number;
  geoTotal: number;
  geoPoolSize: number;
  physicalTotal: number;
  physicalPoolSize: number;
  simonPadCount: number;
  memoryPairCount: number;
  codeLength: number;
  codeMaxAttempts: number;
  rounds: number;
  maxSequenceLevel: number;
  flashGridSize: number;
  firewallRoundCount: number;
  firewallRuleCount: number;
};

export function logicGymLevelSubtitle(level: number): string {
  if (level <= 2) return "base guidata";
  if (level <= 4) return "attenzione stabile";
  if (level <= 6) return "deduzione rapida";
  return "sfida esperta";
}

export function logicGymActivityLevelLine(key: GymActivityKey, level: number, metrics: LogicGymLevelMetrics): string {
  switch (key) {
    case "tables": return `${metrics.tablesTotal} round · fattori fino a ${metrics.tablesMaxFactor} · ${level >= 5 ? "inverse e trucchi" : "prodotti rapidi"}`;
    case "mental": return `${metrics.mentalTotal} round · numeri fino a ${metrics.mentalNumberCap} · ${level >= 5 ? "percentuali e catene" : "strategie base"}`;
    case "geo": return `${metrics.geoTotal} round · ${metrics.geoPoolSize} mete · ${level >= 5 ? "capitali inverse" : "continenti e capitali"}`;
    case "geoPhysical": return `${metrics.physicalTotal} round · ${metrics.physicalPoolSize} elementi · ${level >= 5 ? "indizi e posizione" : "tipo e continente"}`;
    case "simon": return `${metrics.simonPadCount} luci · ritmo ${level >= 6 ? "rapido" : "guidato"}`;
    case "memory": return `${metrics.memoryPairCount} coppie · ${level >= 5 ? "associazioni miste" : "associazioni base"}`;
    case "code": return `${metrics.codeLength} simboli · ${metrics.codeMaxAttempts} tentativi`;
    case "seq": return `${metrics.rounds} schemi · regole fino a profondità ${metrics.maxSequenceLevel}`;
    case "balance": return `${metrics.rounds} deduzioni · ${level >= 8 ? "anche dati insufficienti" : "ordine logico"}`;
    case "flash": return `${metrics.flashGridSize}x${metrics.flashGridSize} · memoria ${level >= 7 ? "sequenziale" : "spaziale"}`;
    case "firewall": return `${metrics.firewallRoundCount} segnali · ${metrics.firewallRuleCount} regole`;
  }
}
