# Eli Quest — Piano operativo condiviso

Aggiornato al 23 luglio 2026.

Questo file contiene soltanto lavoro aperto o decisioni ancora da prendere.
L’ordine P5 → P6 è vincolante.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)

## Obiettivo

Completare un gioco Godot in cui apprendimento, missioni, mondi, NORA e
riattivazione della nave costituiscono un unico ciclo. Ogni livello apre un
mondo distinto; le prove esterne preparano l’esame nella nave; gli esiti
didattici trasformano visivamente mondo e nave.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance ed export.

### C-P5 — Mondi ancora da produrre

- [ ] Ondata C: mondi 9–12.
- [ ] Ondata D: mondi 13–20.
- [ ] Ondata E: mondi 21–24 e finale.

Per ogni mondo dell’ondata corrente:

- [ ] silhouette e topologia proprie;
- [ ] materiali, vegetazione o architettura proprie;
- [ ] luce, meteo e soundscape propri;
- [ ] landmark principale e ingresso nave autorati;
- [ ] trasformazione ambientale collegata a `environmentTransform`;
- [ ] interazione completa senza dipendere dal tasto `E`;
- [ ] HLOD, streaming e budget Web/mobile verificati;
- [ ] capture desktop, tablet con HUD e landmark approvata;
- [ ] audit dell’ondata e regressioni precedenti verdi.

### C-P6 — Pass AAA e consegna

- [ ] Regia, camera, animazioni, transizioni e sound design dei traguardi.
- [ ] Coerenza di art direction tra Eli, mondi, nave, NORA e UI.
- [ ] Compressione audio e texture senza perdita percettibile.
- [ ] Profili prestazionali per desktop, mobile e hardware scolastico.
- [ ] Test input, aspect ratio, leggibilità e accessibilità.
- [ ] Export Web riproducibile con smoke test della build pubblicabile.

## Compiti Opus

Non ci sono pacchetti contenutistici aperti assegnati a Opus. Opus interviene
soltanto se una delle prossime ondate rivela:

- [ ] un contratto `WorldLessonCatalog` non consumabile dal runtime;
- [ ] un topic, prerequisito o testo NORA da correggere dopo revisione docente;
- [ ] una prova di trasferimento non compatibile con la topologia del mondo;
- [ ] una modifica semantica che richiede aggiornamento coordinato di fixture e
  consumer.

## Gate Codex ↔ Opus

Ogni ondata si chiude soltanto quando mondo visuale, contratto didattico,
trasformazione ambientale, input touch, capture e budget prestazionale sono
verdi insieme. Nessuna ondata successiva parte con audit rossi.

Vincoli di responsabilità:

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso gate.

## Decisioni ancora da prendere

- [ ] Confermare nomi e temi definitivi dei 24 mondi.
- [ ] Decidere quali mondi restano liberamente rivisitabili e come scala la
  difficoltà dopo il completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤ 33%.
- [ ] Definire quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Approvare mappa e finale trasversale dei mondi 13–24.
- [ ] Fissare budget misurabili per FPS, memoria, download e caricamento sui
  dispositivi scolastici target.
- [ ] Decidere priorità tra asset originali e riuso modulare per ogni ondata.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna produzione contemporanea di tutti i 24 mondi.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
