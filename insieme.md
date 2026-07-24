# Eli Quest — Piano operativo condiviso

Aggiornato al 24 luglio 2026.

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

### C-P5 — Strategia per completare il mondo 24

I mondi 21–23 sono tecnicamente completi. Resta il finale, che non parte finché
Opus non chiude il Gate E1 e non viene congelata la sequenza conclusiva.

#### Gate E1 — revisione Opus prima del finale

- [x] **Opus:** faglie/climi/insediamenti (21), cellula/flusso energetico/
  adattamento (22) e accordi/beni comuni/impatto (23) sono COMUNICATI dalle
  trasformazioni a cinque stadi (placche colore-clima + faglie; membrane +
  link energetici; cupole + anelli d'accordo), non decorativi. Trasferimento
  reale, NORA distinti, coerenza landmark/missioni/`environment_transform`.
  `world_semantics_audit` e `world_wave_e1_audit` verdi. **Nessuna correzione.**
- [x] **Opus:** struttura del mondo 24 **CONGELATA** in
  [docs/FINALE_SPEC.md](docs/FINALE_SPEC.md). Prova trasversale già disponibile
  come contratto: `ContentManager.build_final_transversal_exam(24, rng,
  mastery_by_subject)` — 12 sistemi (uno per materia) + nodo di sintesi di
  trasferimento, multi-formato, senza tempo, deterministico
  (`finale_transversal_audit` verde). Flusso unico: prova → convergenza dei 12
  sistemi → beat finale NORA (`NarrativeManager.FINAL_BEAT`) → riattivazione
  completa nave (`is_complete`) → ritorno al mondo.
- [ ] **Codex:** costruire il mondo 24 e `world_wave_e2_audit.gd` consumando la
  struttura congelata (Gate E2). Wiring nave: usare
  `build_final_transversal_exam` al livello 24 al posto dell'esame monomateria.

#### Gate E2 — Mondo 24 e finale

- [ ] **24 · Cuore dei Primi** — dodici settori riconoscibili che convergono nel
  Cuore; ogni prova finale accende un sistema e la conclusione apre la rotta.
- [ ] Creare asset, kit, reazione finale, `world_wave_e2_audit.gd` e cinque
  capture del mondo; rieseguire l’intera progressione 1→24.
- [ ] Verificare in un audit integrato convergenza dei dodici sistemi, beat NORA,
  riattivazione completa della nave e ritorno al mondo.

#### Procedura obbligatoria di ogni ondata

1. Congelare nomi, palette, topologia, landmark e trasformazione didattica.
2. Implementare composizione, corridoio nave, regioni e prop prima degli asset
   finali.
3. Creare underpaint e landmark; verificare trasparenza, scala e assenza di
   testo spurio.
4. Collegare palette, meteo, soundscape e reazione ambientale a cinque stadi.
5. Controllare interazione touch: tap sul POI, avvicinamento automatico e
   pulsante contestuale, senza dipendenza da `E`.
6. Eseguire audit semantico, audit di scena e regressioni delle ondate concluse.
7. Renderizzare desktop e tablet, ispezionare le immagini e fare almeno un
   passaggio correttivo su leggibilità, densità e coerenza.
8. Verificare HLOD, streaming, draw call e assenza di sovrapposizioni tra nave,
   landmark, acqua, muri e missioni.
9. Aggiornare questo file eliminando l’ondata conclusa e creare un commit
   autonomo prima di iniziare la successiva.

Definizione di completato per un mondo:

- topologia e silhouette riconoscibili senza leggere il titolo;
- landmark dominante e ingresso nave chiaramente individuabile;
- almeno tre famiglie di prop coerenti e nessun clutter legacy incongruo;
- trasformazione didattica visibile in cinque passi e persistente nel save;
- POI leggibili in ogni fase di luce e su viewport tablet;
- audit verdi e cinque capture approvate;
- budget Web e mobile rispettati.

### C-P6 — Pass AAA e consegna

- [ ] Riallineare `enigma_scene_audit.gd` al runtime per profili: non deve
  presumere dodici enigmi caricati nella stessa scena e deve verificare tap,
  avvicinamento e pulsante contestuale oltre alla tastiera.
- [ ] Regia, camera, animazioni, transizioni e sound design dei traguardi.
- [ ] Coerenza di art direction tra Eli, mondi, nave, NORA e UI.
- [ ] Compressione audio e texture senza perdita percettibile.
- [ ] Profili prestazionali per desktop, mobile e hardware scolastico.
- [ ] Test input, aspect ratio, leggibilità e accessibilità.
- [ ] Export Web riproducibile con smoke test della build pubblicabile.

## Compiti Opus

I contenuti base 9–24 sono già disponibili. Opus esegue un controllo mirato alla
fine di ogni ondata, senza modificare posizionamento o resa visuale.

> **Pronto per Codex.** Il lato CONTENUTI di ogni ondata è già pre-verificato:
> `world_semantics_audit` (trasformazioni non decorative e distinte, trigger di
> apprendimento, trasferimento con novità segnalata, NORA distinti, finale
> trasversale), `world_lesson_audit` (24 mondi) e `mission_event_director_audit`
> (raggiungibilità/non-blocco) sono **verdi**. Alla chiusura di ogni ondata basta
> rieseguirli sui mondi consegnati: il controllo semantico Opus si riduce a
> confermare che la resa di Codex rispetti questi contratti già validati.

- [ ] completare il Gate E1 descritto sopra prima che Codex inizi il mondo 24;
- [ ] aggiornare fixture e consumer insieme soltanto se una revisione cambia un
  contratto `WorldLessonCatalog`.

## Gate Codex ↔ Opus

Ogni ondata si chiude soltanto quando mondo visuale, contratto didattico,
trasformazione ambientale, input touch, capture e budget prestazionale sono
verdi insieme e Opus ha completato il controllo semantico previsto. Nessuna
ondata successiva parte con audit rossi.

Vincoli di responsabilità:

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso gate.

## Decisioni ancora da prendere

- [ ] Decidere quali mondi restano liberamente rivisitabili e come scala la
  difficoltà dopo il completamento.
- [ ] Definire fascia scolastica iniziale e curriculum di lancio.
- [ ] Decidere se tutte le 12 materie sono obbligatorie o configurabili.
- [ ] Validare con docenti il target scelta multipla ≤ 33%.
- [ ] Definire quantità minima di prove e distanza temporale necessarie per
  dichiarare consolidato un topic.
- [ ] Approvare struttura del finale trasversale prima del Gate E2.
- [ ] Fissare budget misurabili per FPS, memoria, download e caricamento sui
  dispositivi scolastici target.
- [ ] Stabilire prima di ogni ondata quali elementi richiedono asset originali
  e quali possono riusare componenti modulari senza perdere identità.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna produzione contemporanea di tutti i 24 mondi.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
