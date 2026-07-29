# Eli Quest — Baseline release candidate

Rilevazione tecnica del 29 luglio 2026. Questo documento conserva le misure;
il lavoro ancora aperto resta in `insieme.md`.

## Ambiente

- Godot `4.7.1.stable`
- eseguibile locale:
  `C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`
- preset: `Web`, release

## Verifiche automatiche

- 68 audit Godot su 68 verdi, eseguiti con save locali isolati (l'isolamento non
  è un dettaglio: `roundtrip_audit` legge il save reale e un salvataggio lasciato
  da una prova precedente può far fallire il gate);
- nota di metodo: un `assert` fallito in uno script Godot headless stampa
  `SCRIPT ERROR` ma **non** cambia l'exit code — un audit va considerato verde
  solo se l'output non contiene asserzioni fallite;
- round-trip missione → nave → esame → mondo successivo verde;
- touch essenziale, contrasto elevato e riduzione movimento coperti da audit;
- contrasto elevato e riduzione movimento sono selezionabili nel pannello
  **Personalizza l’esperienza**, applicati senza riavvio e persistenti nel save;
- streaming a raggio Web/tablet: massimo 9 chunk nei mondi campione;
- probe GPU desktop/tablet dopo la rimozione dei sentieri duplicati: massimo
  620 draw call; nel percorso Chrome Web il picco è 667, sotto il budget tablet
  definitivo di 700.

Campione headless con mondi 1, 7, 13, 19 e 24:

| Mondo | Avvio | Nodi | Chunk |
| --- | ---: | ---: | ---: |
| 1 | 207 ms | 2.665 | 9 |
| 7 | 156 ms | 1.812 | 9 |
| 13 | 181 ms | 1.908 | 9 |
| 19 | 185 ms | 1.709 | 9 |
| 24 | 146 ms | 1.527 | 9 |

## Profiling browser e budget definitivi

Il comando `npm run profile:web:godot` esegue lo stesso round-trip touch dello
smoke test applicando CPU throttling 4× e rete Wi-Fi simulata a 20 Mbps down,
5 Mbps up e 40 ms di latenza. La telemetria proviene da `Performance` di Godot;
Chrome DevTools misura separatamente heap JS, embedder e backing storage.

| Scenario | FPS stabilizzati | Draw call | Memoria browser misurabile |
| --- | ---: | ---: | ---: |
| Mondo | 30 | 667 picco | 58,4 MiB |
| Nave | 30 dopo transizione | 152 | 69,1 MiB |
| Esercizio grafico | 30 | 589 | 78,1 MiB |

Il primo avvio sulla rete simulata richiede 37,6 s: `index.wasm` impiega 29,0 s
e `index.pck` 26,1 s, scaricati in parallelo. Per i riavvii il service worker
`v7-touch-accessibility` mantiene PCK/WASM/JS in cache; HTML resta network-first
e il cambio di versione invalida la cache quando viene pubblicato un export.

Budget release fissati nei `WorldProfile`:

| Tier | Target | Minimo stabile | Draw call | Memoria | Avvio freddo 20 Mbps |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tablet/mobile | 30 FPS | 24 FPS | 700 | 128 MiB | 45 s |
| Web | 30 FPS | 24 FPS | 750 | 128 MiB | 45 s |
| Desktop | 60 FPS | 30 FPS | 1.200 | 192 MiB | 20 s su rete locale |

I minimi escludono i campioni prodotti durante un cambio scena. Il limite di
128 MiB lascia circa 50 MiB di margine sulla misura Chrome, ma la VRAM non è
esposta in modo affidabile dal browser.

Evidenza completa:
`artifacts/web-profile-current/web-smoke-report.json`.

Questa profilazione copre browser e hardware scolastico **simulato**. Il punto
C-P6 #5 resta aperto finché gli stessi budget non vengono confermati su almeno
un tablet fisico rappresentativo.

## Export Web

Le 44 grandi tavole pittoriche dei mondi usano import texture lossy a qualità
`0.85`; i sorgenti PNG restano invariati.

| File | Dimensione |
| --- | ---: |
| `index.pck` | 30,79 MiB |
| `index.wasm` | 37,68 MiB |
| export completo | 68,79 MiB |

Prima della compressione l’export misurava 132,17 MiB e il PCK 94,17 MiB.
La riduzione del download totale è 64,41 MiB, circa il 48,7%.

## Controllo visuale

- le tavole compresse dei mondi campione non mostrano banding, aloni o perdita
  percettibile su landmark e testo;
- Eli usa il nuovo foglio pittorico femminile a 20 frame
  `eli-adventure-girl-sheet-v2.png`, coerente con l’identità narrativa;
- i quattro tier di anomalie hanno silhouette, frammenti e intensità distinte;
- header nave, oscurità del mondo 13 e board degli esercizi non-MC sono stati
  corretti dopo le capture desktop/tablet;
- i sentieri non vengono più disegnati sia globalmente sia dentro ogni chunk:
  nei mondi 19–24 usano materiali coerenti con necropoli, tempesta, atlante,
  biosfera, archivio e Cuore; nella nave completa la rail non parla più di
  “relitto” ma di **Sistemi della nave**;
- evidenze riproducibili: `artifacts/eli-enemies`,
  `artifacts/exercise-renderers` e le capture C-P6.

Comando di export:

```powershell
$env:APPDATA='D:\AppElis\New-project\.tmp\godot-appdata'
$env:LOCALAPPDATA='D:\AppElis\New-project\.tmp\godot-localappdata'
& 'C:\Users\39351\Godot\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' `
  --headless --path godot --export-release Web '..\.tmp\web-cp6\index.html'
```

L’export, lo smoke e il profiling browser sono riproducibili; la conferma su
tablet reale resta criterio aperto in `insieme.md`.

## Smoke browser di rilascio

`npm run smoke:web:godot` usa Chrome reale e input touch per attraversare:

`boot → mondo 1 → nave → esame → mondo 2 → missione matching`.

La prova conferma inoltre musica e ambiente in riproduzione, SFX dopo il primo
gesto, contrasto elevato, riduzione movimento, viewport 1024×600 e 600×900 e
persistenza del save dopo un reload completo. Il formato dell’esercizio viene
ora rimosso dal DOM alla chiusura, evitando falsi positivi fra esame e missione.
Report e catture sono in `artifacts/web-smoke-current/`; gli errori console
rilevati sono zero.

Il service worker usa la cache `v7-touch-accessibility`: PCK/WASM/JS restano
cache-first, ma il cambio versione forza i dispositivi già usati ad acquisire
l’export corrente.

## Registro dei lavori C-P6 (29 luglio)

Resoconti dei lavori chiusi, spostati qui da `insieme.md` — che torna a essere
soltanto la lavagna del lavoro aperto. Sono riportati verbatim: servono a
ricostruire *come* si è arrivati alle misure di questo documento.

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

Esito Codex dei punti 6–8 (29 luglio):

- il pannello **COMANDI TOUCH** è diventato **PERSONALIZZA L’ESPERIENZA**:
  oltre a lato, dimensione e visibilità offre ora **CONTRASTO ELEVATO** e
  **RIDUZIONE MOVIMENTO**, applicati in tempo reale e persistenti nel save;
- verificati i layout GPU a 900×600 e 600×900, senza sovrapposizioni fra HUD,
  pannello opzioni, azione, impulso e feedback NORA; cattura portrait
  `artifacts/c-p6-playthrough/03c-comandi-touch-portrait.png`;
- lo smoke Chrome reale percorre tramite touch boot → mondo 1 → nave → esame →
  mondo 2 → missione `matching`, controlla musica/ambiente/SFX, ruota la
  viewport landscape/portrait e ricarica l’intera pagina verificando il save;
- corretto lo stato Web dell’esercizio, che dopo la chiusura restava nel DOM e
  poteva produrre un falso positivo diagnostico; lo smoke usa ora il POI reale
  trasformato nelle coordinate del canvas;
- report verde in `artifacts/web-smoke-current/web-smoke-report.json`, zero
  errori console; cache aggiornata a `v7-touch-accessibility` per rendere
  visibile il nuovo PCK anche sui dispositivi che avevano già aperto il gioco;
- il punto 7 è completato. I punti 5, 6 e quindi l’approvazione finale del punto
  8 restano aperti soltanto per il passaggio su tablet scolastico fisico.

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
