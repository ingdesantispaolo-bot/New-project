# Eli Quest — Piano operativo condiviso

Aggiornato al 24 luglio 2026.

Questo file contiene soltanto lavoro aperto o decisioni ancora da prendere.
Il lavoro operativo parte dal pass C-P6.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export.

### C-P6 — Pass AAA e consegna

Il playthrough integrato è verde su desktop e viewport tablet: boot → mondo →
missione touch → nave → esame → mondo successivo. Sono verdi anche progressione
naturale 1→24, finale trasversale e rivisitazione del mondo 24. Opus può quindi
procedere con la revisione didattica finale senza attendere altri gate.

Procedere in quest’ordine:

1. [ ] Rifinire regia, camera, animazioni, transizioni e sound design dei
   traguardi, con priorità a riattivazioni della nave e finale.
2. [ ] Verificare coerenza di art direction tra Eli, 24 mondi, nave, NORA e UI;
   correggere soltanto incoerenze visibili nelle capture o nel playthrough.
3. [ ] Comprimere audio e texture senza perdita percettibile e misurare peso
   finale del download.
4. [ ] Profilare FPS, memoria, caricamenti, streaming e draw call su desktop,
   Web e hardware scolastico/tablet reale.
5. [ ] Completare test di input touch, aspect ratio, leggibilità, contrasto,
   riduzione movimento e accessibilità.
6. [ ] Produrre export Web riproducibile ed eseguire smoke test della build
   pubblicabile.
7. [ ] Eseguire la suite finale completa, aggiornare i documenti di consegna e
   creare il commit/release candidate.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso;
- nessun errore Godot bloccante o perdita di stato;
- UI leggibile alle viewport target;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

> **Gate E2 · finale verificato.** Il mondo 24 e il finale trasversale funzionano
> come un solo flusso: prova dei 12 sistemi + sintesi → Cuore a 5 fasi →
> riattivazione completa della nave (`is_complete`, integrità NORA 1.0, memoria 24)
> → beat finale NORA → ritorno giocabile. Verdi: `world_wave_e2_audit`,
> `finale_transversal_audit`, `nora_arc_audit`, e l'intero percorso
> (`world_semantics_audit`, `world_lesson_audit`, `progression_1to24_audit`).
> Nessuna correzione richiesta. La revisione didattica del punto 1 qui sotto è la
> ripassata **dopo** il playthrough manuale C-P6.

1. [ ] Rieseguire la revisione didattica finale sui 24 mondi e sul finale
   trasversale dopo il playthrough C-P6; segnalare soltanto problemi che cambiano
   comprensione, trasferimento, difficoltà o relazione con NORA.
2. [ ] Validare la distribuzione reale dei formati di esercizio e proporre
   correzioni dove la scelta multipla resta dominante nell’esperienza giocata.
3. [ ] Preparare una matrice sintetica livello → competenze → evidenze richieste
   → apparato riattivato, utilizzabile da docenti e test pilota.
4. [ ] Aggiornare fixture e consumer insieme soltanto se una revisione cambia un
   contratto `WorldLessonCatalog` o `ContentManager`.

## Gate Codex ↔ Opus

Il release candidate si chiude soltanto quando runtime, contenuti, input touch,
accessibilità, performance ed export sono verdi insieme.

Vincoli di responsabilità:

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso commit.
- Nessuna correzione di polish deve indebolire il significato didattico della
  trasformazione del mondo o della riattivazione della nave.

## Decisioni ancora da prendere

- [ ] Decidere come scala la difficoltà nelle rivisitazioni dopo il
  completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤ 33%.
- [ ] Definire quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Fissare budget misurabili per FPS, memoria, download e caricamento sui
  dispositivi scolastici target.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
