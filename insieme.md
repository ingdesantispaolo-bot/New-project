# Eli Quest — Piano operativo condiviso

Aggiornato al 29 luglio 2026.

Questo file contiene **soltanto** lavoro aperto, decisioni e regole condivise.
I resoconti dei lavori chiusi stanno nel *Registro dei lavori C-P6* in
[docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md), insieme alle misure:
qui non si archivia, qui si lavora.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)
- [Design minigiochi](docs/MINIGAMES_DESIGN.md)
- [Baseline release candidate + registro](docs/RELEASE_CANDIDATE.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export.

### C-P6 — Verifiche manuali e consegna

1. [x] Playthrough manuale dei mondi acquatici e dei mondi 1, 7, 13, 19 e 24.
2. [x] Feel e juice dei renderer non-MC (snap, collegamenti, errori).
3. [x] Regia, camera, animazioni, transizioni e sound design dei traguardi.
4. [x] Incoerenze di art direction osservabili durante il playthrough.
5. [ ] **Profilare su hardware scolastico/tablet REALE** e confermare i budget
   già fissati e misurati in browser (`docs/RELEASE_CANDIDATE.md`).
6. [ ] **Provare su tablet REALE** comandi touch, viewport landscape e portrait,
   leggibilità, contrasto elevato e riduzione movimento.
7. [x] Smoke test in un browser reale dell'export Web.
8. [ ] Correggere i difetti osservati in 1–7, rieseguire la suite e approvare il
   commit come release candidate pubblicabile.

I punti 5 e 6 sono le uniche verifiche che nessuno dei due agenti può eseguire:
richiedono un dispositivo fisico. Il punto 8 dipende da entrambi. Gli esiti dei
punti chiusi sono nel registro.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso o errore Godot bloccante — verificato con
  `npm run audit:godot`, che considera verde un audit solo se non stampa
  asserzioni fallite (l'exit code di Godot non le riflette);
- nessuna perdita di stato e nessun soft-lock da acqua, tool o anomalie;
- UI leggibile alle viewport target e con riduzione movimento/contrasto validati;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

1. [x] Revisione didattica finale sui 24 mondi e sul finale trasversale.
2. [x] Distribuzione reale dei formati nell'esperienza giocata, materia per
   materia.
3. [x] Profondità, distrattori e qualità dei livelli alti.
4. [x] Fixture e consumer aggiornati insieme ai contratti toccati.
5. [x] Rivisitazioni come ripasso mirato (decisione 3).
6. [x] Criterio di consolidamento a tempo reale (decisione 4).

Nessun compito Opus aperto. Misure ed esiti sono nel registro; i guard-rail
vivono negli audit (`format_mix`, `content_depth`, `revisit`, `topic_evidence`).

## Gate Codex ↔ Opus

Il release candidate si chiude soltanto quando runtime, contenuti, input touch,
accessibilità, performance ed export sono verdi insieme.

- Codex non calcola mastery, ricompense o gate nella UI.
- Opus non decide posizionamento visuale o budget di rendering.
- Un cambio di contratto aggiorna fixture e consumer nello stesso commit.
- Nessuna correzione di polish deve indebolire il significato didattico della
  trasformazione del mondo o della riattivazione della nave.
- Nessun nemico o strumento può sottrarre mastery, consumare energia didattica o
  bloccare gli eventi minimi necessari al gate.

## Decisioni prese (29 luglio)

Sono vincoli per entrambi: una proposta che le contraddice va discussa, non
implementata.

1. **Fascia di lancio: 10–13 anni** (fine primaria + medie). È l'arco che i
   contenuti coprono davvero, quindi la rampa resta com'è: mondi 1–12
   introduzione (difficoltà 1→3), mondi 13–24 approfondimento (3→4). Nel save è
   `config.schoolBand = "primaria-secondaria-1"`.
2. **Tutte e 12 le materie sono obbligatorie**: 24 mondi = 12 materie × 2
   comparse e il finale accende i dodici sistemi. `LearningConfig.activeSubjects`
   resta un aggancio per sperimentazioni in classe, non una configurazione
   supportata dal gate di consegna.
3. **Rivisitazioni = ripasso mirato**: nel mondo che si torna a visitare le prove
   sono quelle di quel mondo, con priorità agli argomenti deboli e in scadenza.
   Nessuna banda di difficoltà 5. L'esame dell'apparato resta al rango.
4. **Consolidato = 3 corrette in sessioni distinte, con ≥ 3 giorni tra la prima e
   l'ultima.** Non è un requisito del gate: un mondo resta completabile in un
   pomeriggio. È lo stato dichiarato nel Manuale e nel report.
5. **Scelta multipla: tetto 33%, target ~20%** (misurato: 17%). La validazione
   con i docenti resta un riscontro sul campo, non un blocco.
6. **Budget prestazionali confermati** ai valori di `performance_budget`. Resta
   solo la verifica su tablet fisico (punto C-P6 #5).

## Difetti corretti dopo segnalazione (29 luglio)

Un ordinamento dell'esame di matematica è arrivato **già risolto**: gli elementi
erano presentati nell'ordine giusto e bastava premerli in fila. Cercandone altri
della stessa famiglia — la presentazione che regala la risposta — ne sono emersi
tre, tutti misurati sull'esperienza giocata:

- **ordinamenti già risolti**: 355 su 7.532 (4,7%), esami compresi. Ora il
  rimescolamento non può restituire la soluzione e il contratto
  (`ExerciseInteraction.validate`) rifiuta un ordinamento presentato ordinato;
- **caccia all'errore prevedibile**: la riga sbagliata era la terza nel 56% dei
  casi e in sei materie *sempre* la terza. Dove le righe sono affermazioni
  indipendenti ora vengono rimescolate a ogni partita (con la spiegazione
  rinumerata); dove l'ordine è il ragionamento — codice, passaggi di un calcolo,
  premesse di un sillogismo — sono stati autorati sei spec con l'errore in
  posizioni diverse;
- **posizione della risposta nei banchi piccoli**: logica al 45% in terza
  posizione, scienze al 42% in seconda. Al bake la posizione ora ruota per
  materia: tutte tra il 23% e il 28%.

Guard-rail: `giveaway_audit.gd`. La colonna destra degli abbinamenti non può più
risultare allineata alla sinistra (si risolveva riga per riga).

## Rischi noti

- **L'export in `public/godot/outdoor/` invecchia più in fretta dei contenuti.**
  Dopo ogni cambio di banchi, selezione o formati va rigenerato il PCK, altrimenti
  lo smoke in browser verifica l'esperienza precedente.
- **Banchi piccoli in cinque materie** (musica 29 item, storia 30, scienze e
  logica 38, coding 42): la varietà giocata regge perché la maggior parte dei nodi
  viene dai minigiochi, ma alla seconda o terza rigiocata di un mondo la
  ripetizione si farà sentire.
- **Nessuna prova con bambini o docenti.** Tutte le misure sono strutturali:
  dicono che l'esperienza è varia, progressiva e onesta, non che è piacevole.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
