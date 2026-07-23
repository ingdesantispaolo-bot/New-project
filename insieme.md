# Eli Quest — Piano operativo condiviso

Aggiornato al 23 luglio 2026.

Questo file contiene soltanto lavoro aperto e decisioni da valutare, divisi tra
**Codex** e **Opus**. Non è un registro delle attività concluse.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)

## Obiettivo

Completare un gioco Godot in cui apprendimento, missioni, mondi, NORA e
riattivazione della nave costituiscono un unico ciclo. Ogni livello apre un mondo
distinto; le prove esterne preparano l’esame nella nave; gli esiti didattici
trasformano visivamente mondo e nave.

L’ordine P5→P6 è vincolante.

---

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance ed export.

### C-P5 — Produzione visuale dei mondi

- [ ] ondata A: mondi 3–4;
- [ ] ondata B: mondi 5–8;
- [ ] ondata C: mondi 9–12;
- [ ] ondata D: mondi 13–20;
- [ ] ondata E: mondi 21–24 e finale.

Per ogni mondo:

- [ ] silhouette e topologia proprie;
- [ ] materiali, vegetazione o architettura proprie;
- [ ] luce, meteo e soundscape propri;
- [ ] landmark principale e ingresso nave autorati;
- [ ] almeno una trasformazione ambientale legata all’apprendimento;
- [ ] HLOD, streaming e budget Web verificati;
- [ ] capture di riferimento approvata.

### C-P6 — Pass AAA e consegna

- [ ] Regia, camera, animazioni, transizioni e sound design per i traguardi.
- [ ] Coerenza di art direction tra Eli, mondi, nave, NORA e UI.
- [ ] Compressione audio, texture e pacchetto Web senza perdita percettibile.
- [ ] Profili prestazionali per desktop, mobile e hardware scolastico.
- [ ] Test input, aspect ratio e accessibilità.
- [ ] Export Web riproducibile con smoke test della build pubblicabile.

---

## Compiti Opus

Opus è responsabile di progressione, save, didattica, contenuti, narrativa,
contratti dati, selezione adattiva e audit semantici.

### O-P5 — Contenuti dei mondi 3–24

Per ogni ondata:

- [ ] curriculum e prerequisiti;
- [ ] mission grammar ed event pool;
- [ ] briefing, debrief e beat NORA;
- [ ] manuale dei nuovi concetti;
- [ ] prove finali di copertura e trasferimento;
- [ ] criteri per la trasformazione ambientale;
- [ ] audit didattici e di raggiungibilità.

Opus consegna un’ondata soltanto quando quella precedente ha superato il gate
integrato con Codex.

### O-P6 — Validazione

- [ ] Report locale utile: copertura, confidenza, ritenzione, aiuti e tempo.
- [ ] Configurazione per fascia scolastica, curriculum e materie attive.
- [ ] Piano di playtest con studenti, docenti e revisori disciplinari.
- [ ] Guardrail contro grinding, ansia, timer impropri e ricompense che falsano
  la mastery.
- [ ] Audit completo di save migration e compatibilità dei profili esistenti.

---

## Gate ancora aperti Codex ↔ Opus

| Gate | Consegna Opus | Lavoro Codex | Verifica finale |
|---|---|---|---|
| G5 Ondata | curriculum e mission grammar | mondo visuale completo | audit + capture + performance |

Regole:

- Codex non calcola mastery, ricompense o gate nella UI;
- Opus non decide posizionamento visuale o budget di rendering;
- un cambio di contratto richiede aggiornamento di fixture e consumer nello
  stesso gate;
- nessuna ondata successiva parte con audit rossi nell’ondata corrente.

## Decisioni ancora da valutare

- [ ] Confermare nomi e temi definitivi dei 24 mondi.
- [ ] Decidere quali mondi restano liberamente rivisitabili e come scala la loro
  difficoltà dopo il completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤33%.
- [ ] Definire la quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Approvare la mappa provvisoria dei mondi 13–24 e il finale trasversale.
- [ ] Fissare budget misurabili per FPS, memoria, download e tempi di caricamento
  sui dispositivi scolastici target.
- [ ] Decidere priorità tra nuovi asset originali e riuso modulare per ogni
  ondata di mondi.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna produzione contemporanea di tutti i 24 mondi.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
