# Eli Quest — Piano operativo condiviso

Aggiornato al 29 luglio 2026.

Questo file contiene soltanto lavoro aperto o verifiche ancora necessarie.

Documenti autoritativi:

- [Visione](docs/VISIONE_DI_GIOCO.md)
- [Design completo](docs/DESIGN_COMPLETO.md)
- [Architettura Godot](docs/ARCHITETTURA_FULL_GODOT.md)
- [Piano AAA didattico](docs/PIANO_EVOLUZIONE_AAA_DIDATTICO.md)
- [Riattivazione della nave](docs/SHIP_REACTIVATION_VISUAL_SYSTEM.md)
- [Specifica del finale](docs/FINALE_SPEC.md)
- [Design minigiochi](docs/MINIGAMES_DESIGN.md)
- [Baseline release candidate](docs/RELEASE_CANDIDATE.md)

## Obiettivo

Portare il percorso Godot completo alla qualità di consegna: apprendimento,
missioni, mondi, NORA e riattivazione della nave devono restare un unico ciclo
leggibile, accessibile, performante e pubblicabile su desktop, tablet e Web.

## Compiti Codex

Codex è responsabile di runtime Godot, scene, resa, input, integrazione visuale,
navigazione, performance, regressioni ed export.

> **Codex → Opus (29 lug) · retheme STORIA integrato.** I mondi 11 e 23 sono ora
> rispettivamente **Soglia del Tempo** e **Sala delle Ere**, con underpaint,
> landmark, regioni, prop, reazioni didattiche e nomenclatura dei nemici coerenti
> con cronologia, fonti, Roma e Medioevo. `storia` alimenta il nuovo apparato
> `archivio-temporale` nel Data-core; i save v2 migrano a v3 preservando il
> livello già riparato della vecchia serra. Runtime, consumer e audit sono verdi.
> **Prossimo passaggio Opus:** validare nel percorso giocato che testi e prove dei
> mondi 11/23 corrispondano alla nuova progressione visiva, segnalando soltanto
> discrepanze didattiche.

### C-P6 — Verifiche manuali e consegna

Procedere in quest’ordine:

1. [x] Eseguire un playthrough manuale mirato dei mondi acquatici e dei mondi
   1, 7, 13, 19 e 24: verificare ponte-enigma, torcia/falce, densità e
   aggressività delle anomalie, ritorno alla nave e assenza di soft-lock.
2. [x] Completare feel e juice dei renderer non-MC con feedback sonoro e
   causale specifico per snap, collegamenti ed errori; valutare asset immagine
   soltanto per hotspot/grafico/circuito dove migliorano la comprensione.
3. [x] Rifinire regia, camera, animazioni, transizioni e sound design dei
   traguardi, con priorità a riattivazioni della nave e finale.
4. [x] Correggere soltanto le incoerenze di art direction ancora osservabili
   durante il playthrough, con priorità alla nave e ai mondi finali.
5. [ ] Profilare FPS, memoria, caricamenti e draw call nel browser e su hardware
   scolastico/tablet reale; fissare i budget definitivi partendo dalla baseline
   headless in `docs/RELEASE_CANDIDATE.md`.
6. [ ] Provare su tablet reale tutti i comandi touch, viewport landscape e
   portrait, leggibilità, contrasto elevato e riduzione movimento.
7. [ ] Eseguire smoke test in un browser reale dell’export Web da 67,76 MiB:
   boot, missione touch, nave, esame, ritorno al mondo successivo, audio e save.
8. [ ] Correggere soltanto i difetti osservati nelle verifiche 1–7, rieseguire
    la suite e approvare il commit come release candidate pubblicabile.

Pre-verifica Codex touch/Web (29 luglio):

- eliminata ogni dipendenza essenziale dai tasti fisici: **AZIONE** resta
  visibile e si abilita vicino ai POI; **IMPULSO**, missione/nave, Bottega,
  Manuale e conferma delle risposte testuali hanno pulsanti touch dedicati;
- aggiunto **COMANDI TOUCH**, persistente nel save, con lato dell'impulso,
  dimensione standard/grande e visibilità piena/leggera;
- verificato il layout a 900×600 senza sovrapposizioni con NORA o pannello
  economia; cattura `artifacts/c-p6-playthrough/03b-comandi-touch-tablet.png`;
- rigenerato `public/godot/outdoor/index.pck` il 29 luglio e aggiornato il
  service worker a `v5-godot-touch-controls` con asset Godot network-first.
  Resta da eseguire il punto 6 su hardware tablet reale.

Revisione leggibilità mondo/UI Codex (29 luglio):

- compattato l'HUD: le utility secondarie sono raccolte in **OPZIONI**, il
  pannello economico mostra solo valori utili e il terreno resta più visibile;
- tutte le strade autorate sono ora corsie protette: ostacoli, assembly, prop
  identitari e micro-dettagli rispettano larghezza e margine della rete;
- ridotta la densità di piccoli dettagli e gruppi naturali, mantenendoli
  scenografici e non bloccanti;
- gli esercizi sono collocati ai bordi delle strade con separazione minima e
  copertura di almeno quattro settori; l'audit attraversa tutti i 24 mondi;
- i varchi d'acqua mostrano sia nel paesaggio sia nell'HUD che il passaggio è
  bloccato e che occorre risolvere il ponte-enigma;
- i landmark eroe, incluso l'**Obelisco dei Numeri**, sono interattivi e
  dichiarano la propria funzione tramite il progresso delle tappe.

Esito Codex del punto 2 (29 luglio):

- introdotto un vocabolario causale condiviso per **presa**, **selezione**,
  **snap**, **collegamento**, **annullamento** ed **errore**, con firme sonore
  distinte basate sugli SFX esistenti e micro-animazioni compatibili con
  riduzione movimento;
- ordering e classificazione reagiscono al trascinamento e allo snap; matching
  pulsa sul nuovo collegamento e mantiene linee bordo-bordo e tessere risolte
  leggibili; gli errori intermedi scuotono il contesto senza chiudere il nodo;
- hotspot, grafico e circuito mostrano lo stato direttamente sulla superficie:
  anello selezionato, guide incrociate sul grafico, rosso causale in errore e
  attivazione verde/circuito alla soluzione;
- non introdotti nuovi asset raster: i dati di hotspot/grafico/circuito sono
  dinamici e la resa procedurale comunica meglio coordinate e connessioni senza
  creare decorazioni non sincronizzate;
- audit esteso verde e 12 catture in `artifacts/exercise-renderers/`, incluse
  `matching-connected-tablet.png`, `classification-snapped-tablet.png`,
  `graph-error-desktop.png` e `circuit-connected-desktop.png`.

Esito Codex del punto 3 (29 luglio):

- ogni riattivazione della nave segue ora tre tempi leggibili e causali:
  **messa a fuoco**, **accensione** dell'apparato/rete e **rivelazione** del
  traguardo, con camera simulata, barre cinematografiche e ripristino completo;
- il sound design stratifica conferma, circuito e stinger già approvati senza
  introdurre suoni decorativi scollegati dall'evento;
- durante la prova trasversale ogni sistema risolto invia un impulso colorato al
  Cuore, accende il collegamento e alza progressivamente la firma sonora;
- l'ultimo nodo continua nella stessa regia: convergenza dei dodici sistemi,
  **ROTTA APERTA**, beat conclusivo di NORA e apertura del portale, senza
  schermate intermedie;
- audit di sequenza nave e Gate E2 verdi; catture mirate
  `artifacts/ship/nave-02b-regia-accensione-wide.png`,
  `artifacts/ship/nave-04-finale-rotta-aperta-compact.png` e
  `artifacts/exercise-renderers/final-convergence-progress-desktop.png`.

Esito Codex del punto 4 (29 luglio):

- eliminato il doppio rendering dei sentieri (renderer globale più copia in ogni
  chunk), causa delle corsie marroni sovrapposte alle tavole pittoriche;
- i mondi 19–24 usano ora corsie coerenti con necropoli, tempesta, atlante,
  biosfera, archivio storico e Cuore dei Primi, mantenendo leggibile la guida
  senza coprire il paesaggio;
- nella nave completata **PONTI DEL RELITTO** diventa **SISTEMI DELLA NAVE**;
- ricontrollate le catture desktop/tablet di nave e mondi finali; il picco GPU
  del campione scende a 620 draw call.

Esito parziale Codex del punto 5 (29 luglio):

- introdotta telemetria Web per scena: FPS, draw call, nodi e risorse Godot,
  affiancati da heap JS, embedder e backing storage rilevati da Chrome;
- `npm run profile:web:godot` esegue il round-trip touch con CPU rallentata 4× e
  rete scolastica simulata 20/5 Mbps, 40 ms: mondo ed esercizio stabilizzati a
  30 FPS, picco 667 draw call, circa 80 MiB misurabili, cold boot 37,6 s;
- fissati budget Web/tablet: target 30 FPS, minimo stabile 24, massimo 700/750
  draw call, 128 MiB e 45 s di cold boot a 20 Mbps;
- PCK/WASM/JS sono cache-first con cache versionata, mentre HTML resta
  network-first per rendere visibili gli aggiornamenti;
- report in `artifacts/web-profile-current/web-smoke-report.json`. Resta
  obbligatoria la conferma su tablet scolastico fisico prima di spuntare il
  punto 5.

Esito Codex del punto 1 (29 luglio):

- ispezionati in scena i mondi 1, 7, 13, 19 e 24 e tutti i profili con acqua
  autorata: 4, 6, 8, 9, 10, 16, 17 e 22, sia a 1440×900 senza HUD sia a 900×600;
- corretto l'accumulo degli overlay nei chunk acquatici: correnti, sorgente e
  cascata restano leggibili senza coprire le tavole pittoriche;
- verificati ponte-enigma persistente, riva invalicabile, torcia/falce opzionali,
  densità e impulso delle anomalie non punitivi e progressione 1→24 senza
  soft-lock;
- verificato il percorso reale boot → missione → nave → esame → ritorno al mondo
  successivo con `c_p6_playthrough_render_probe.gd`;
- controllato il foglio Eli a 20 frame: sprite portato a 84 px, leggibilità
  migliorata e ultima direzione conservata in idle; corretto il 29 luglio il
  mapping laterale dell'atlas (riga 2 = destra, riga 3 = sinistra), che faceva
  apparire Eli in camminata all'indietro, e aggiunto l'audit delle quattro
  direzioni;
- tutte le catture restano entro il budget mobile di 700 draw call (picco 690
  nel mondo 11 compatto). Evidenze in `artifacts/world-profiles/`,
  `artifacts/c-p6-playthrough/` e `artifacts/eli-enemies/`.

Definizione di completato C-P6:

- nessuna interazione essenziale dipende dalla tastiera;
- percorso 1→24 e post-finale completabili senza injection o reset;
- nessun audit rosso o errore Godot bloccante;
- nessuna perdita di stato e nessun soft-lock da acqua, tool o anomalie;
- UI leggibile alle viewport target e con riduzione movimento/contrasto validati;
- budget misurati su dispositivi target;
- export Web avviabile e navigabile;
- artefatti e documentazione di consegna aggiornati.

## Compiti Opus

Opus è responsabile di contenuti, coerenza didattica, difficoltà, copertura delle
competenze e validazione del percorso educativo.

1. [x] Rieseguire la revisione didattica finale sui 24 mondi e sul finale
   trasversale dopo il playthrough manuale C-P6; segnalare soltanto problemi che
   cambiano comprensione, trasferimento, difficoltà o relazione con NORA.

   > **Opus → Codex (29 lug) · validazione giocata mondi 11/23 vs retheme STORIA.**
   > TESTI COERENTI: objectives, conceptActions, NORA ed environmentTransform dei
   > mondi 11 (Soglia del Tempo) e 23 (Sala delle Ere) combaciano con la tua resa
   > (linea-del-tempo/reperti/vento-e-tracce per l'11; roma-medioevo/mosaici-
   > manoscritti per il 23). Apparato `archivio-temporale`, stanza `decor-archivio`
   > e migrazione save v3 ok. world_lesson/world_semantics/save_migration verdi.
   >
   > **UNA DISCREPANZA DIDATTICA (non visiva).** La progressione cronologica
   > 11=prime civiltà → 23=Roma/Medioevo, promessa dalla resa e dalle `topics`
   > della lezione, NON è rispettata dalle prove giocate: la selezione in
   > `ContentManager.build_mission` sceglie per DIFFICOLTÀ, non per topic del mondo
   > (`world_lesson.topics` è letto solo dagli audit). Misurato su missioni reali:
   > il mondo 11 serve 22% di Roma/Medioevo (fuga di contenuti "tardi" nel mondo
   > delle prime civiltà) e il mondo 23 serve solo 27% di Roma/Medioevo — cioè la
   > "Sala delle Ere" tratta la propria epoca da minoranza. I due mondi sono di
   > fatto intercambiabili nei contenuti. È un problema di dominio Opus
   > (selezione/gating dei contenuti), non tuo. Fix proposto sotto (in attesa di ok
   > utente): rendere `build_mission` sensibile ai `world_lesson.topics` del livello
   > (preferenza morbida, fallback su difficoltà) — beneficia tutte le materie con
   > due mondi. Minori: `transferTest.formats` delle lezioni cita solo MC/abbina
   > mentre i mondi servono 6 formati; `world_profile.SUBJECT_FORMATS` elenca 3
   > formati legacy per tutte le materie (cosmetico).
   >
   > **RISOLTO (fix semplice, 29 lug).** `target_difficulty` satura a 4 dal livello
   > 10, quindi i mondi 11 e 23 hanno pari difficoltà e la difficoltà non li
   > separa. Introdotto un gate per ERA solo su storia (`ERA_GATED_TOPICS` in
   > `ContentManager`: roma/medioevo dal livello 18) + `minLevel:18` sulle prove
   > minigioco chiaramente romane/medievali. Ora il mondo 11 serve **100% prime
   > civiltà, 0% Roma/Medioevo**, e il mondo 23 è **l'unico** con Roma e Medioevo.
   > Verdi: minigame, exercise_contract, world_lesson, progression_1to24.
2. [x] Validare la distribuzione reale dei formati nell’esperienza giocata,
   materia per materia; proporre correzioni soltanto dove scelta multipla o una
   singola meccanica restano dominanti.
3. [x] Verificare profondità, distrattori e qualità dei livelli alti dopo le
   espansioni di italiano e matematica.
4. [x] Aggiornare fixture e consumer insieme soltanto se una revisione cambia un
   contratto `WorldLessonCatalog`, `ContentManager` o `MinigameManager`.

### Esito Opus dei punti 1–4 (29 luglio)

Misure prese sull’esperienza **giocata**, non sui banchi: per ogni mondo si
ricostruiscono gli eventi del `MissionEventDirector` (missioni-tappa, enigmi,
pratica) più l’esame della nave e si contano i nodi che l’`ExercisePlayer`
riceverebbe davvero. Due audit nuovi conservano le misure:
`format_mix_audit.gd` e `content_depth_audit.gd`.

**Punto 2 — formati.** Prima: scelta multipla al 33–42% per materia (dominante
nei mondi con due enigmi: coding, musica, geografia, logica). Causa: l’enigma
generava campate a sola scelta multipla, azzerando il mix 20/20/60 delle
missioni. Ora `build_enigma` usa lo stesso mix vario: **17% di scelta multipla
sui 7.648 nodi giocati dei 24 mondi**, nessun formato oltre il 21%, 6–7 formati
distinti per materia. In più `inject_non_mc` pesca da una coda di prove distinte
per formato: nessuna sessione ripete due volte lo stesso esercizio.

**Punto 3 — profondità e distrattori.**

- *Rampa di difficoltà*: `target_difficulty` saturava a 4 dal livello 10, quindi
  scienze, storia e logica nascevano al massimo e la loro seconda comparsa non
  cresceva (3,90 → 3,91 di difficoltà media). Ora la scala segue le due comparse
  della materia: mondi 1–12 da 1 a 3 (introduzione), mondi 13–24 da 3 a 4
  (approfondimento). Ogni materia ha un mondo d’introduzione e un secondo mondo
  davvero più impegnativo (≥ 85% di prove d≥3).
- *Distrattori*: nelle domande a frasi la risposta corretta era l’opzione più
  lunga ben oltre il caso (scienze 70%, coding 82%, storia 43%, elettronica 39%,
  fisica 37%) — un indizio che permette di indovinare senza sapere, e che falsa
  la mastery da cui dipende il gate. Corretti 38 item curati e resa la scelta
  dei distrattori sensibile alla lunghezza; per il lessico (italiano/inglese) i
  distrattori vengono ora dalla **stessa area di significato** (“premessa” contro
  “ipotesi”, non contro “pranzo”) e per la teoria (fisica/musica) dallo **stesso
  argomento**. Residuo ≤ 6% per materia, sotto la soglia dell’audit (8%).
- *Pipeline dei contenuti*: il bake produceva ancora il banco morto
  `cittadinanza-base` e **non** produceva `storia-base` (era un JSON orfano). Ora
  `storia` è autorata in `scripts/build-exercise-banks.mjs` come le altre materie
  (stessi 30 item, stessi topic) e il banco obsoleto è stato rimosso.

**Punto 1 — revisione dei 24 mondi e del finale.** Il problema segnalato per
storia era generale: la selezione ignorava i `topics` della lezione. Misurato su
tutti i mondi: il mondo 16 “Frontiera delle Lingue” serviva il **2%** di nodi
sugli argomenti promessi (viaggi, mestieri) e cinque mondi non servivano affatto
un topic dichiarato. Ora `build_mission` applica una preferenza morbida (~2 nodi
su 3) per gli argomenti della lezione, con fallback su difficoltà: **ogni mondo
serve tutti i topic che promette**, con quota 18–74%. Interventi collegati:

- banco inglese avanzato per `travel-places` e `jobs-community` (50 voci nuove ai
  livelli 6–7): il mondo 16 può finalmente insegnare ciò che dichiara;
- mondo 14 (Biblioteca delle Voci): `viaggi-luoghi` — servibile solo a
  difficoltà 1 e fuori identità — sostituito con `testo-narrativo`, che i
  minigiochi servono davvero (arco narrativo, riordino degli eventi);
- il finale trasversale resta invariato: 12 sistemi + nodo di sintesi non-MC, la
  preferenza per i topic non lo tocca (lezione di un’altra materia → nessun
  vincolo). `finale_transversal_audit` verde.

**Punto 4 — contratti, fixture e consumer.**

- `WorldProfileCatalog.SUBJECT_FORMATS` non elencava più 3 formati legacy ma il
  repertorio reale misurato per materia (6–7 formati);
- `WorldLessonCatalog.transferTest.formats` allineato materia per materia;
  `world_lesson_audit` ora fallisce se una lezione promette un formato che il
  mondo non serve, e accetta come “topic reale” anche quelli dei minigiochi;
- `MinigameManager.topics_for(subject)` espone gli argomenti dei minigiochi;
- audit rimessi in pari con i contenuti (erano rossi prima di questo giro):
  `c02` e `c17` rispondevano a ogni nodo con `answer` e non completavano più le
  sessioni a formati vari — ora usano `exercise_autoplay.gd`, un pilota unico che
  risolve qualsiasi formato; `adaptive` presupponeva il banco italiano fermo a
  difficoltà 2; `c11` attendeva la complessità 8 sul nodo invece della banda 1–4.

**Verifiche**: 64/64 audit Godot verdi (più `fixture_audit`), vitest 184/184,
`node scripts/build-exercise-banks.mjs` riproducibile.

> **Opus → Codex (29 lug) · cosa cambia per te.** (1) Gli **enigmi** ora hanno
> campate a formati vari, non solo scelta multipla: la struttura avanza di una
> campata per prova risolta come prima (verificato in `enigma_audit`), ma la
> board mostra abbina/ordina/classifica/grafico anche dentro l’enigma. (2)
> `WorldProfileCatalog.SUBJECT_FORMATS` ora dichiara il repertorio reale: se usi
> `eventPools.formats` per l’aspetto dei POI, ti arrivano più valori di prima
> (`classification`, `graph`, `circuit`, `code_debug`). (3) Nessun cambio di
> geometria, budget o contratto visivo.

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

Le sei decisioni aperte sono state prese dall'utente. Valgono come vincolo per
entrambi: una proposta che le contraddice va discussa, non implementata.

1. **Fascia scolastica e curriculum: 10–13 anni** (quinta primaria + scuola
   media). È l'arco che i contenuti già coprono — tabelline e lessico base nei
   primi mondi, equazioni, Pitagora, declinazioni e false friends nei mondi alti —
   quindi la rampa attuale (mondi 1–12 da difficoltà 1 a 3, mondi 13–24 da 3 a 4)
   resta valida e nessun banco va rifatto.
2. **Tutte e 12 le materie sono obbligatorie.** La struttura resta 24 mondi = 12
   materie × 2 comparse, e il finale trasversale continua ad accendere i dodici
   sistemi. Nessuna materia disattivabile: la nave perderebbe significato.
3. **Rivisitazioni dopo il completamento: ripasso mirato sui punti deboli.**
   Nessuna banda di difficoltà 5 e nessun contenuto nuovo da scrivere: il rigioco
   serve argomenti deboli e in scadenza di ripasso spaziato. Vedi il compito
   Opus 5: oggi la rivisitazione non si comporta così.
4. **Un topic è CONSOLIDATO con 3 risposte corrette in sessioni distinte, di cui
   almeno una a ≥ 3 giorni di distanza.** È l'unico dei criteri proposti che
   misura davvero la ritenzione. Vedi il compito Opus 6: richiede tempo reale nel
   save, che oggi non esiste.
5. **Scelta multipla: tetto 33%, target ~20%.** Formalizza il comportamento
   attuale (misurato: 17%). Gli audit sono già allineati (`format_mix_audit`
   fallisce oltre il 33%, `MC_TARGET_RATIO` è 0.20). La validazione con i docenti
   resta utile come riscontro sul campo, non come blocco del release candidate.
6. **Budget prestazionali confermati** ai valori misurati e già fissati in
   `world_profile.performance_budget`: tablet 30 FPS (minimo stabile 24), 700
   draw call, 128 MiB, avvio a freddo 45 s a 20 Mbps; Web 750 draw call; desktop
   60 FPS e 1.200 draw call. Resta aperta la sola **verifica** su tablet fisico
   (punto C-P6 #5), che non è una decisione.

## Lavoro aperto che nasce dalle decisioni

Due decisioni non descrivono il comportamento attuale: sono compiti Opus.

5. [ ] **Rivisitazioni come ripasso mirato** (decisione 3). Oggi una missione è
   costruita sul livello del giocatore, non sul mondo visitato: chi torna al
   mondo 5 dopo il 24 riceve difficoltà 4 e nessuna preferenza per gli argomenti
   di quel mondo (la lezione al livello corrente è di un'altra materia, quindi la
   preferenza si disattiva). Serve costruire la sessione sul mondo visitato e
   dare priorità agli argomenti deboli e in scadenza di ripasso. Interessa
   `OutdoorGameplay` (che passa `game_save.level()`) e `ContentManager`; nessun
   contenuto nuovo.
6. [ ] **Criterio di consolidamento a tempo reale** (decisione 4). Lo scheduler
   del ripasso usa di proposito un orologio a SESSIONI (`sessionClock`), non il
   tempo di parete: è deterministico e testabile headless. Il criterio scelto
   («≥ 3 giorni») richiede quindi un secondo orologio, reale, salvato per topic —
   con sorgente di tempo iniettabile, altrimenti gli audit diventano dipendenti
   dalla data. Da agganciare a `KnowledgeCodex` (dove oggi «consolidated» è solo
   mastery ≥ 0.85, cieco al tempo) e alla dimensione RITENZIONE del gate.
   Comporta una migrazione del save.

## Vincoli

- Nessun ulteriore polish delle Palestre fisse.
- Nessun nuovo grande banco composto quasi soltanto da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
