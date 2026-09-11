// Chiude i formati-firma PRIMA del bake. 11 settembre 2026.
//
//   node scripts/verifica-firme.mjs
//
// `ExerciseInteraction` valida tutti questi contratti, ma scoprirlo da Godot
// costa un giro di audit; questo rifà gli stessi conti sulla sorgente in mezzo
// secondo. Al primo giro ha trovato due griglie su tre ancora aperte.
//
// Controlla anche tre cose che il validatore NON sa controllare, e che sono il
// vero lavoro di chi scrive:
//
//  - **griglia**: un nome sottostringa di un altro (fa scattare tutti e due) e
//    un indizio che nomina più di un attributo (il parser tiene l'ultimo);
//  - **mystery_sample**: che nessuna prova SOLA basti a chiudere il caso. Se la
//    prima mossa identifica già il campione, l'indagine finisce subito e la
//    lezione — servono più prove indipendenti — non viene mai imparata;
//  - **machine_path**: che il percorso dichiarato arrivi davvero al traguardo
//    senza incepparsi su una divisione;
//  - **timeline**: che due eventi non finiscano a meno del 2% della scala l'uno
//    dall'altro. Sono due punti diversi per la storia e lo stesso punto per un
//    dito: la guardia di Godot li rifiuta, e qui si vede prima.

import { CODING_FIRME } from "./banks/coding-firme.mjs";
import { LOGICA_FIRME } from "./banks/logica-firme.mjs";
import { ELETTRONICA_FIRME } from "./banks/elettronica-firme.mjs";
import { MUSICA_FIRME } from "./banks/musica-firme.mjs";
import { SCIENZE_FIRME } from "./banks/scienze-firme.mjs";
import { STORIA_FIRME } from "./banks/storia-firme.mjs";
import { LATINO_FIRME } from "./banks/latino-firme.mjs";

const LOTTI = {
  coding: CODING_FIRME, logica: LOGICA_FIRME, elettronica: ELETTRONICA_FIRME,
  musica: MUSICA_FIRME, scienze: SCIENZE_FIRME, storia: STORIA_FIRME, latino: LATINO_FIRME,
};

let problemi = 0;
const rotto = (m) => { console.log("   ROTTO — " + m); problemi += 1; };

function permutazioni(a) {
  if (a.length <= 1) return [a];
  const out = [];
  a.forEach((x, i) => {
    for (const p of permutazioni([...a.slice(0, i), ...a.slice(i + 1)])) out.push([x, ...p]);
  });
  return out;
}

// ---------------------------------------------------------------- griglia
function controllaGriglia(it) {
  const { soggetti, attributi, indizi, soluzione } = it;
  const nomi = [...soggetti, ...attributi];
  for (const a of nomi) for (const b of nomi) {
    if (a !== b && b.includes(a)) rotto(`«${a}» è sottostringa di «${b}»`);
  }
  indizi.forEach((ind, i) => {
    const quanti = attributi.filter((a) => ind.text.includes(a)).length;
    if (quanti !== 1) rotto(`indizio ${i + 1} nomina ${quanti} attributi`);
    if (ind.text.trim().length < 12) rotto(`indizio ${i + 1} troppo corto`);
  });
  // stessa lettura del validatore: si rileggono le frasi, non la struttura
  const regge = (frase, ass) => {
    const nominati = soggetti.filter((s) => frase.includes(s));
    let colonna = "";
    for (const a of attributi) if (frase.includes(a)) colonna = a;
    if (colonna === "" || nominati.length === 0) return true;
    if (frase.includes(" non ")) return nominati.every((n) => ass[n] !== colonna);
    return nominati.some((n) => ass[n] === colonna);
  };
  const valide = permutazioni(attributi).filter((perm) => {
    const ass = {};
    soggetti.forEach((s, i) => { ass[s] = perm[i]; });
    return indizi.every((ind) => regge(ind.text, ass));
  });
  if (valide.length !== 1) return rotto(`${valide.length} soluzioni invece di una`);
  if (!soggetti.every((s, i) => valide[0][i] === soluzione[s])) {
    rotto("la soluzione unica non è quella dichiarata");
  }
  return `${soggetti.length}×${soggetti.length}, ${indizi.length} indizi, chiusa`;
}

// --------------------------------------------------------- mystery_sample
function controllaMistero(it) {
  const { samples, tests, results, answer, minTests } = it;
  const impronte = new Map();
  for (const s of samples) {
    const imp = tests.map((t) => String(results[s.id]?.[t.id] ?? "")).join("|");
    if (imp.includes("|" + "".padEnd(0))) { /* nulla */ }
    for (const t of tests) {
      if (!String(results[s.id]?.[t.id] ?? "").trim()) rotto(`manca ${s.id}/${t.id}`);
    }
    if (impronte.has(imp)) rotto(`${impronte.get(imp)} e ${s.id} reagiscono identici`);
    impronte.set(imp, s.id);
  }
  // la regola in più: nessuna prova singola deve isolare il campione nascosto
  const scorciatoie = tests.filter((t) => {
    const osservato = String(results[answer]?.[t.id] ?? "");
    return samples.every((s) => s.id === answer || String(results[s.id]?.[t.id] ?? "") !== osservato);
  });
  if (scorciatoie.length) {
    rotto(`la prova «${scorciatoie[0].id}» da sola chiude il caso: l'indagine finisce alla prima mossa`);
  }
  if (minTests < 2) rotto("minTests sotto due: si può rispondere dopo una prova sola");
  return `${samples.length} materiali × ${tests.length} prove, impronte distinte, nessuna scorciatoia`;
}

// ----------------------------------------------------------- machine_path
function controllaCatena(it) {
  const per = Object.fromEntries(it.machines.map((m) => [m.id, m]));
  if (it.machines.length <= it.slotCount) rotto("niente macchine alternative da scartare");
  if (it.solution.length !== it.slotCount) rotto("soluzione di lunghezza diversa dai posti");
  let v = it.start;
  for (const id of it.solution) {
    const m = per[id];
    if (!m) return rotto(`macchina inesistente: ${id}`);
    if (m.op === "divide") {
      if (v % m.value !== 0) return rotto(`il percorso si inceppa: ${v} non è divisibile per ${m.value}`);
      v = v / m.value;
    } else if (m.op === "multiply") v *= m.value;
    else if (m.op === "add") v += m.value;
    else v -= m.value;
  }
  if (v !== it.target) return rotto(`il percorso arriva a ${v}, non a ${it.target}`);
  return `${it.start} → ${it.target} in ${it.slotCount} stadi`;
}

// ------------------------------------------------------------------ porte
function controllaPorte(it) {
  if (it.righe.length !== 4) rotto("tavola incompleta");
  const combo = new Set(it.righe.map((r) => `${r.a}${r.b}`));
  if (combo.size !== 4) rotto("una combinazione manca o è ripetuta");
  const accese = it.righe.filter((r) => it.soluzione[r.id]).length;
  if (accese === 0 || accese === 4) rotto(`porta degenere: ${accese} casi accesi su quattro`);
  return `${accese} casi accesi su quattro`;
}

// --------------------------------------------------------------- timeline
const TIMELINE_MIN_SEPARAZIONE = 0.02;

function controllaLinea(it) {
  const { min, max, targets, answer } = it;
  const estensione = max - min;
  if (estensione <= 0) return rotto("scala vuota o rovesciata");
  if (targets.length < 2 || targets.length > 6) rotto(`${targets.length} eventi: fuori dalla scala 2..6`);
  const ids = new Set();
  for (const t of targets) {
    if (!t.id || ids.has(t.id)) rotto(`evento con id vuoto o duplicato: ${t.id}`);
    ids.add(t.id);
    if (!String(t.label ?? "").trim()) rotto(`evento «${t.id}» senza etichetta`);
    if (t.value < min || t.value > max) rotto(`«${t.id}» fuori scala: ${t.value}`);
  }
  if (!ids.has(answer)) rotto(`la risposta «${answer}» non è uno degli eventi`);
  const pos = targets.map((t) => (t.value - min) / estensione).sort((a, b) => a - b);
  let minimo = 1;
  for (let i = 1; i < pos.length; i += 1) minimo = Math.min(minimo, pos[i] - pos[i - 1]);
  if (minimo < TIMELINE_MIN_SEPARAZIONE) {
    return rotto(`due eventi a ${(minimo * 100).toFixed(1)}% della scala: si sovrappongono sotto un dito`);
  }
  return `${targets.length} eventi, il più vicino al ${(minimo * 100).toFixed(0)}% della scala`;
}

// -------------------------------------------------------- verb_decoder
function controllaDecodificatore(it) {
  const assi = { time: "timeChoices", mood: "moodChoices", form: "forms" };
  for (const [asse, campo] of Object.entries(assi)) {
    const scelte = it[campo] ?? [];
    if (scelte.length < 3 || scelte.length > 6) rotto(`${campo}: ${scelte.length} scelte, fuori dalla scala 3..6`);
    const ids = new Set();
    for (const s of scelte) {
      if (!s.id || ids.has(s.id)) rotto(`${campo}: id vuoto o duplicato «${s.id}»`);
      if (!String(s.label ?? "").trim()) rotto(`${campo}: «${s.id}» senza etichetta`);
      ids.add(s.id);
    }
    if (!ids.has(it.solution?.[asse])) rotto(`la soluzione ${asse} «${it.solution?.[asse]}» non è fra le scelte`);
    if (!String(it.hints?.[asse] ?? "").trim()) rotto(`manca l'indizio per ${asse}`);
  }
  if (!Array.isArray(it.segments) || it.segments.length !== 2) rotto("la frase va spezzata in due segmenti");
  if (!String(it.discovery ?? "").trim()) rotto("manca la scoperta narrativa");
  const forma = (it.forms ?? []).find((f) => f.id === it.solution?.form);
  return forma ? `«${it.segments[0]} ${forma.label} ${it.segments[1]}»` : "";
}

const CONTROLLI = {
  griglia: controllaGriglia, mystery_sample: controllaMistero,
  machine_path: controllaCatena, porte: controllaPorte, timeline: controllaLinea,
  verb_decoder: controllaDecodificatore,
};

for (const [materia, lotto] of Object.entries(LOTTI)) {
  const daControllare = lotto.filter((it) => CONTROLLI[it.format]);
  if (!daControllare.length) continue;
  console.log(`\n${materia.toUpperCase()}`);
  for (const it of daControllare) {
    const esito = CONTROLLI[it.format](it);
    console.log(`  ${it.format.padEnd(15)} f${it.difficulty} ${it.topic.padEnd(18)} ${esito ?? ""}`);
  }
}
console.log(problemi === 0
  ? "\nTutte le firme chiuse: nessun problema."
  : `\n${problemi} problemi da correggere prima del bake.`);
process.exit(problemi === 0 ? 0 : 1);
