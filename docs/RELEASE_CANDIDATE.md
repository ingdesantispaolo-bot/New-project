# Eli Quest — Baseline release candidate

Rilevazione tecnica del 29 luglio 2026. Questo documento conserva le misure;
il lavoro ancora aperto resta in `insieme.md`.

## Ambiente

- Godot `4.7.1.stable`
- eseguibile locale:
  `%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`
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

La misura storica del primo avvio sulla rete simulata era 37,6 s: `index.wasm`
impiegava 29,0 s e `index.pck` 26,1 s, scaricati in parallelo. L'export corrente
ha un PCK più piccolo e, sui server Vite di sviluppo e anteprima, il WASM viene
trasferito in Brotli (circa 7,92 MiB invece di 37,68 MiB). Il dato temporale va
quindi rimisurato su tablet reale. Per i riavvii il service worker
`v9-web-loader` mantiene PCK/WASM/JS in cache; HTML e `build.json` restano
network-first.

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
| `index.pck` | 23,85 MiB |
| `index.wasm` | 37,68 MiB |
| export completo | 61,86 MiB |

Prima della compressione l’export misurava 132,17 MiB e il PCK 94,17 MiB.
La riduzione complessiva rispetto a quell'export è 70,31 MiB, circa il 53,2%.

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
& '%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' `
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

Il service worker usa la cache `v9-web-loader`: PCK/WASM/JS restano cache-first.
Il launcher confronta il build ID network-first, attende l'attivazione del nuovo
worker e soltanto dopo apre Godot, evitando il caricamento del PCK precedente.
`npm run audit:web` controlla l'allineamento tra build ID, cache, file esportati
e dimensioni dichiarate prima della build.

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

## Registro dei lavori (30 luglio – 3 agosto)

Spostati qui da `insieme.md` quando è arrivato a millecinquecento righe e
due terzi erano retrospettive di lavori chiusi. Stessa regola del registro
C-P6 qui sopra: verbatim, perché servono a ricostruire *come* si è arrivati
alle misure, non a essere riletti ogni giorno.

### Cosa posso verificare da qui (verificato il 30 luglio)

- **Godot gira in locale**:
  `%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`.
  Il progetto apre headless senza parse error.
- **Gli audit girano onesti**: `npm run audit:godot` usa
  `scripts/run-godot-audits.mjs`, che già gestisce i tre gotcha che hanno fatto
  perdere settimane — l'exit code bugiardo (un `assert` fallito non lo cambia),
  il save reale letto da `roundtrip_audit` (usa una APPDATA isolata) e il
  processo che resta appeso (timeout per audit).
- **L'export Web è possibile**: i template `4.7.1.stable` sono installati
  (`web_release.zip`, `web_nothreads_release.zip`). Quindi **puoi giocare quello
  che scrivo**, ed è il fatto che rende praticabile tutto questo piano.
  I template *Windows desktop* non sono installati: niente `.exe`, e non serve —
  il target è Web.
- **Il menu nativo esiste già**: `run/main_scene="res://scenes/boot_menu.tscn"`,
  e `boot_menu.gd` costruisce la UI a codice. La voce di menu della tappa 1 è
  davvero piccola.

## Difetto corretto dopo segnalazione (30 luglio) — argomento fuori registro

Segnalato giocando, con uno screenshot: nell'enigma di matematica del mondo 1,
esercizio 2/4, «Metti i numeri in ordine decrescente: **5, 6, 2**». Una radice
sola, quattro sintomi, tutti in `_numeric_ordering_node` — **l'unico generatore
della famiglia senza contenuto autorato**, perché matematica e logica erano le
sole due materie senza specifiche in `ORDERING`.

- **Sotto la fascia.** `count = 3 + level/6`, `span = 5 + level*2`: al livello 1
  tre interi sotto il 7, al livello 24 cinque interi sotto il 53. Per la fascia
  10–13 non è difficoltà 1: è un compito di prima elementare.
- **Fuori dalla lezione.** Dichiarava `topic: "sequenze"` per qualunque materia,
  ma i mondi di matematica dichiarano `tabelline/problemi` (1) e
  `proporzioni/frazioni/geometria` (13). Accumulava padronanza su un argomento
  che quei mondi non insegnano — e quella padronanza conta nella dimensione
  COPERTURA del gate e verso lo stato "consolidato". È il sintomo più grave.
- **Mal etichettato anche per logica**, dove `sequenze` è dichiarato (mondi 12 e
  24): il Codex la definisce «cerchi la regola che genera i termini successivi»,
  e ordinare interi estratti a caso non ha nessuna regola da trovare.
- **Invisibile agli audit.** `topics_for()` si costruisce dalle tabelle: un
  generatore procedurale non dichiarato non compare, quindi nessun controllo
  poteva vedere l'argomento emesso a runtime. `world_lesson_audit` verificava
  solo la direzione opposta (una lezione non promette argomenti inesistenti).

Correzioni:

- **matematica** resta procedurale — serve varietà infinita, i banchi piccoli sono
  già un rischio — ma gli elementi diventano **operazioni da calcolare**: ordinare
  `4 × 7`, `6 × 5`, `3 × 9` richiede davvero i prodotti. Argomento onesto:
  `tabelline` fino al 12, `frazioni` dal 13. Vincolo aggiunto: mai tutte le carte
  con lo stesso primo fattore, altrimenti si ordina guardando l'altro senza
  calcolare — la stessa famiglia di scorciatoie ripulita il 29 luglio;
- **logica** esce da `NUMERIC_ORDERING_SUBJECTS` e riceve **sei specifiche
  autorate** su `sequenze/deduzioni/analogie`, incluse una sequenza la cui regola
  alterna ×2 e −1 (i termini salgono e scendono, quindi **non si risolve
  ordinando per grandezza**) e una gerarchia di analogie;
- `NUMERIC_ORDERING_TOPICS` dichiara gli argomenti del generatore procedurale, che
  così rientra in `topics_for()` e sotto gli audit.

Guard-rail: **`minigame_topic_scope_audit.gd`**, il controllo che mancava. Per
tutte le 12 materie e tutti i 24 livelli verifica che ogni nodo dichiari un
argomento non vuoto e appartenente al registro della materia (banco + tabelle, più
i concetti del generatore per matematica), più una regressione mirata: gli
elementi dell'ordinamento di matematica non possono essere interi nudi e la
spiegazione deve mostrare il calcolo. Misura: nessun'altra materia emetteva
argomenti fuori registro — il difetto era isolato all'unico generatore non
dichiarato.

**Osservazione lasciata aperta** (decisione tua, non l'ho forzata): gli argomenti
dei minigiochi possono cadere fuori dalle `topics` della lezione del mondo anche
per le materie autorate — es. `ORDERING["scienze"]` serve `materia`, `ciclo-acqua`,
`catena`, `organizzazione`, mentre il mondo 10 dichiara `viventi/ecosistema/metodo`.
Per un evento di *pratica* è difendibile come ampliamento, ma diluisce il «ripasso
mirato» della decisione 3 del 29 luglio. Il nuovo audit **non** lo vieta.

## Difetto grave aperto (31 luglio) — le prove si ripetono

Segnalato giocando: «italiano e matematica sono sempre gli stessi, non solo la
tipologia ma anche **gli stessi numeri**: lo studente si trova due prove uguali».

### La misura che mancava

Nessun audit misurava la cosa che il bambino percepisce. `format_mix` misura la
varietà dei FORMATI, `content_depth` la profondità degli ARGOMENTI: un mondo può
essere verde su entrambi e servire cinque volte la stessa identica prova.
Ora c'è **`variety_audit.gd`**: simula 10 missioni consecutive per materia e conta
quante prove *distinte* capitano davvero.

Prima misura, ed è severa — la stessa prova ricapitava fino a **9 volte su 30**
(fisica L1 e scienze L1, formato `graph`; logica L1 `code_debug` ×8).

### Le tre cause, misurate

1. **Banchi magri.** Item per (argomento, difficoltà): **mediana 1** in otto
   materie su dodici. musica 29 item totali, storia 30, scienze e logica 38,
   coding 42. Quando il selettore sceglie quell'argomento a quella difficoltà,
   c'è **un solo item**: è quello, sempre.
2. **Specifiche dei minigiochi statiche e poche.** 16–33 per materia spalmate su
   sei formati, e sono **dati fissi**: stessa specifica = stessi numeri. Col gate
   `minLevel`, ai livelli bassi restano spesso **una o due** specifiche per
   formato specialista.
3. **Nessuna memoria anti-ripetizione** fra sessioni. Esisteva solo per la
   matematica generata (`_recent_math_signatures`, finestra 28); ai formati
   specialisti mancava del tutto.

### L'ironia che vale la pena registrare

**La correzione della varietà dei formati ha peggiorato la varietà dei contenuti.**
La decisione 5 del 29 luglio (scelta multipla al ~20%) ha instradato l'80% delle
campate sulle tabelle di specifiche piccole, che prima servivano una quota
marginale. Ogni volta che si sposta il traffico su una sorgente, va misurata la
profondità della sorgente.

### Cosa ho corretto ora (palliativi, non la cura)

- **Memoria anti-ripetizione** delle prove non-MC (finestra 24), l'equivalente di
  quella che la matematica aveva già;
- **rotazione a livello di formato**: se la prossima prova di un formato è già
  stata vista, si preferisce un altro formato — perché con una sola specifica
  disponibile l'unico modo di non ripetere è cambiare formato.

Effetto misurato: peggiore da **×9 a ×6**, problemi da 15 a 1. Non è la cura:
con un insieme di uno nessun algoritmo può ruotare.

Regressione presa dagli audit strada facendo: avevo allargato la chiave di
deduplica *dentro* la sessione, e `format_mix_audit` ha intercettato prove
ripetute nella stessa missione. Chiave riportata stretta.

### La cura: profondità estrema, in fasi

Piano completo in [docs/PROFONDITA_CONTENUTI.md](docs/PROFONDITA_CONTENUTI.md).
Obiettivo dell'utente: **cinquanta partite senza ripetersi, e voglia di farne
altre cento.**

Il conto che decide la strategia: ogni materia viene incontrata **~138 volte per
partita** (2 mondi da ospite + 22 da varietà). Cinquanta partite = **~7.000
esercizi distinti per materia**, ~84.000 in tutto. Oggi ce ne sono ~2.450 in
totale. **Autorare è fuori scala di due ordini di grandezza**: la profondità non
si scrive, si genera.

La leva: una specifica che pesca **4 elementi da un insieme di 32** produce 35.960
prove diverse — da sola supera il bisogno di cinquanta partite. Regola operativa:
**ogni insieme deve superare le 10.000 combinazioni**, cioè 24–32 elementi per
coppia (materia, formato). 12 materie × 6 formati = **72 insiemi, ~2.000 elementi
da autorare** invece di 84.000.

| Fase | Contenuto | Insiemi | Bersaglio `variety_audit` |
|---|---|---|---|
| **0** | Infrastruttura: specifiche a insieme + misura di profondità combinatoria | — | invariato (abilitatore) |
| **1** | Nucleo: italiano, matematica, inglese | 18 | ×5 · 0,32 |
| **2** | Banchi magri: musica, storia, scienze, coding, fisica, elettronica | 36 | ×3 · 0,25 |
| **3** | Restanti: latino, geografia, logica | 18 | ×3 · 0,20 |
| **4** | Ricchezza: più argomenti nei mondi alti, banda 4 popolata, trasferimento | — | — |
| **5** | Cricchetto al bersaglio + soglia combinatoria | — | difende il risultato |

I due numeri del cricchetto sono lo stato di fatto, **non** una promozione:
possono solo scendere, e sono l'unico rendiconto del progresso.

### Fase 0 — chiusa il 31 luglio (l'infrastruttura)

Nessun contenuto nuovo, come previsto. Tre pezzi, e una scoperta che ne ha
cambiato l'ordine di importanza.

**1. Il meccanismo a insieme** — `godot/scripts/game/exercise_pool.gd`. Una
specifica statica è semplicemente un insieme da cui si pesca tutto: **lo stesso
codice serve entrambe le forme**, quindi le fasi successive migrano una materia
alla volta senza rompere le altre. Estrazione deterministica per seed, vincoli di
non-ambiguità applicati *prima* di costruire il nodo invece che validati dopo, e
per lo smistamento un'estrazione che garantisce ogni contenitore non vuoto.
Ordinamento e smistamento hanno ora una forma a insieme che prima non esisteva;
l'abbinamento era già un'estrazione e ora passa dalla stessa strada.

**2. La misura di profondità** — `combinatorial_depth_audit`. Diceva il piano:
senza, non si sa quando una materia è finita. Il primo responso è netto:

| | prove distinte producibili (peggiore fra L1 e L13) |
|---|---|
| matematica | 132.110 |
| inglese | 80 |
| italiano | 39 |
| geografia | 33 |
| latino | 22 |
| scienze | 19 |
| logica | 15 |
| coding | 13 |
| fisica · musica · elettronica | 12 |
| storia | 6 |

**Una coppia (materia, formato) su 67 raggiunge le 10.000 combinazioni**, ed è
l'ordinamento generato di matematica — l'unica sorgente già combinatoria del
progetto. Undici materie su dodici stanno fra 6 e 124: con ~138 incontri per
partita, **la prima partita esaurisce già il materiale**. Il numero è congelato
come pavimento: da qui può solo salire.

**3. L'identità di contenuto** — `godot/scripts/game/exercise_signature.gd`. Non
era in programma, ed è il pezzo che contava di più.

Esistevano **tre** definizioni diverse di «stessa prova»: la deduplica dentro la
sessione usava `formato|testo`, la memoria delle prove recenti
`formato|testo|risposta`, l'audit di varietà i payload serializzati. Da quello
scarto nascevano due difetti veri:

- **la memoria anti-ripetizione era spenta sui formati specialisti.** Il confronto
  «l'ho già vista» metteva la chiave stretta contro una lista di chiavi larghe:
  combaciavano solo dove la risposta è vuota. Per grafico, circuito e caccia
  all'errore — cioè proprio i formati con le ripetizioni peggiori misurate — non
  poteva riuscire mai;
- **la misura contava le presentazioni, non le prove.** Righe rimescolate ed
  elementi in altro ordine risultavano prove nuove: **i numeri del 31 luglio
  descrivevano un gioco più vario di quello che esisteva.**

Ora la firma è una sola, guarda il contenuto e mai la presentazione, e la usano
tutti e tre. Effetto: fisica **×8 → ×4**, scienze **×7 → ×5**, inglese **×6 → ×2**
— non per contenuto nuovo, ma perché una macchina che c'era ha ricominciato a
funzionare. In compenso storia, logica e musica peggiorano sulla carta: erano già
così, non si vedeva.

**Il cricchetto è stato rialzato una volta sola, e non tornerà a succedere.**
0,38 → 0,67 perché è cambiata la *misura*, non il contenuto: i vecchi numeri non
sono comparabili con i nuovi. Questi sono i primi onesti.

Aggiunto anche un secondo cricchetto in `format_mix_audit`: **162 sessioni su
3.648 (4,4%)** chiedono lo stesso argomento nello stesso formato due volte. Non è
la stessa prova — quella ora è zero — ma è la stessa competenza a pochi minuti di
distanza: sintomo di insiemi poveri, che le Fasi 1–3 fanno scendere da sé.

Suite 79/79 verde. Esportato: `2026.07.31-web-loader-4` / `v18-web-loader`.

### Fase 1 — chiusa il 31 luglio (il nucleo)

~700 elementi autorati in italiano, matematica e inglese. Risultato misurato:

| | prima | dopo |
|---|---|---|
| italiano | 39 | **8.074.778** |
| inglese | 80 | **7.785.076** |
| matematica | 132.110 | **407.510** |
| ripetizioni del nucleo | fino a ×6 | **×1, 0–3%** |

Il nucleo è **oltre il bersaglio finale** (×3 · 20%): tre materie su tre a ×1.
Coppie (materia, formato) sopra le 10.000 combinazioni: da 1 a **9 su 67**.

Cosa ha funzionato, e cosa no:

- **abbinamento** — regge un insieme profondo solo dove ogni voce ha una risposta
  sua: contrari, sinonimi, definizioni, modi di dire, vocaboli, tabelline. I
  contenuti «a categoria» (classe grammaticale, tempo verbale) **non possono
  crescere lì**: con quattro risposte per venti voci l'abbinamento diventa
  ambiguo. Sono migrati allo smistamento, che è fatto apposta;
- **smistamento** — il formato che regge meglio: poche categorie leggibili, ma
  ventiquattro-trentadue tessere, e si pescano sei. È da solo il grosso degli otto
  milioni;
- **ordinamento** — parametrizzabile solo dove l'ordine è una proprietà
  *misurabile* (alfabeto, valore numerico). Il riordino di una frase resta a dato
  fisso: l'ordine giusto è quello di *quella* frase, non c'è insieme da cui pescare.

Due difetti presi e corretti mentre scrivevo i contenuti, entrambi della stessa
famiglia — **contenuto che regala la risposta**:

1. per evitare risultati duplicati avevo scritto etichette come `12 (144÷12)`: la
   carta della risposta conteneva l'operazione, quindi si abbinava senza calcolare.
   Corretto rendendo tutti i risultati **naturalmente distinti**;
2. la misura di varietà giocava **una** partita casuale e oscillava fra il 60% e il
   70%: un cricchetto su un numero che balla passa per fortuna o fallisce per
   sfortuna. Ora gioca cinque partite a semi fissi e riporta la peggiore.

I due cricchetti della varietà si sono mossi una seconda volta (0,60/×7 →
0,70/×8), sempre per un cambio di misura e non di contenuto. **Con questo la
strumentazione è chiusa**: da qui in poi ogni movimento è contenuto, e solo in
discesa. Restano alti perché li detta storia — sei prove distinte in tutto, ed è
la prima della Fase 2.

Suite 79/79 verde. Esportato: `2026.07.31-web-loader-5` / `v19-web-loader`.

### Fase 2 — chiusa il 31 luglio (i banchi magri)

Sei materie: musica, storia, scienze, coding, fisica, elettronica.

| | prima | dopo | peggiore ripetizione |
|---|---|---|---|
| coding | 13 | **7.666.565** | ×3 |
| fisica | 12 | **248.258** | ×2 |
| musica | 12 | **243.414** | ×3 |
| scienze | 19 | **221.329** | ×3 |
| elettronica | 12 | **213.551** | ×2 |
| storia | 6 | **133.313** | ×3 |

**Nove materie su dodici sono al bersaglio finale** (×1–×3). Restano latino,
geografia e logica: sono la Fase 3, e sono loro a tenere alti i due cricchetti
(0,50 · ×7). Coppie sopra le 10.000 combinazioni: da 9 a **17 su 67**.

La scoperta di questa fase: **in storia e in fisica l'ordinamento è il formato
migliore, non il peggiore.** Vale ovunque l'ordine sia una *grandezza* e non una
convenzione — l'anno di un evento, i km/h, i kg, i battiti al minuto di un tempo
musicale, i volt. Ventotto eventi storici con il loro anno danno 20.475 prove
diverse, e ogni estrazione è una domanda di storia sensata perché la linea del
tempo è una sola.

Con un limite che ho dovuto scrivere in codice: l'insieme cronologico grande
parte dal mondo 6. Pescandone tre a caso al mondo 1 poteva uscire «Hammurabi,
prima crociata, peste nera» — che non è una prova difficile, è una prova
impossibile a dieci anni. Sotto c'è un secondo insieme di eventi notissimi e
molto distanti, dove l'ordine si ricava dal senso storico e non dalla memoria
delle date.

**Due difetti presi dagli audit, entrambi causati dal successo della Fase 1:**

1. `format_mix_audit` ha visto le sessioni con lo stesso argomento nello stesso
   formato **salire** da 141 a 184. Contro-intuitivo ma logico: con gli insiemi
   profondi due estrazioni dello stesso insieme non sono più identiche, quindi
   non venivano più scartate. Per chi gioca però restano due volte la stessa
   consegna a un minuto di distanza. Corretto separando **due chiavi dichiarate**
   — dentro la sessione conta (formato, argomento), fra le sessioni conta
   l'identità di contenuto. Sceso a **74 su 3.648 (2%)**;
2. `content_depth_audit` ha visto sparire **«proporzioni»** dal mondo 13: la
   lezione lo prometteva, ma era servito solo dal banco a scelta multipla, e la
   tavolozza più ricca ne sostituisce di più. La cura non è iniettare meno
   minigiochi — è dare ai minigiochi l'argomento che il mondo promette.

Suite 79/79 verde. Esportato: `2026.07.31-web-loader-6` / `v20-web-loader`.

### Fase 3 — chiusa il 31 luglio (le ultime tre)

latino, geografia, logica.

| | prima | dopo | peggiore ripetizione |
|---|---|---|---|
| geografia | 33 | **7.791.351** | ×2 |
| latino | 22 | **297.163** | ×3 |
| logica | 15 | **133.892** | ×4 |

**Dodici materie su dodici sono a posto.** La più povera è ora elettronica con
213.551 prove distinte producibili — millecinquecento volte quello che serve per
una partita intera.

Ogni materia ha richiesto una strategia diversa, e questa è la lezione più utile
dell'intero piano:

- **geografia** è la materia più facile da rendere profonda: quasi ogni ordine è
  una grandezza (metri, chilometri, abitanti) e quasi ogni fatto è una coppia
  unica (Paese → capitale). Da 33 a 7,8 milioni senza inventare niente;
- **latino** è l'opposto: l'ordine dei casi è convenzione pura — si recitano così
  perché così li recita il libro, non perché uno sia «maggiore». Lì l'ordinamento
  resta a dato fisso, e tutta la profondità è dovuta venire da smistamento e
  abbinamento;
- **logica** è il caso più delicato. La profondità non può venire da **più
  elementi**: un insieme di trenta cani e trenta rose non rende il ragionamento
  più ricco, solo più lungo. Deve venire da **più regole** — quantificatori
  diversi, negazioni, affermazioni vere per ragioni diverse («alcuni numeri primi
  sono pari» è vera, e capire perché è tutto l'esercizio). E ogni insieme di
  analogie è **una relazione sola**, dichiarata: mescolarle renderebbe
  l'abbinamento indovinabile per associazione, che è il contrario di ciò che la
  materia allena.

**I cricchetti sono scesi a 0,17 · ×4** — la quota di ripetizioni è *sotto* il
bersaglio dichiarato (0,20), il ×4 lo supera di uno. Quel residuo è logica al
primo mondo e non è un problema di insiemi: viene dalla caccia all'errore, che è
un formato a dato fisso dove ogni specifica vale una prova sola. Portarlo a ×3
vuol dire più specifiche specialiste ai livelli bassi — cioè la Fase 4.

Attivata anche la **soglia di sufficienza** prevista dalla Fase 5: sotto le 1.380
prove distinte per materia l'audit è rosso. È dieci volte il fabbisogno di una
partita, e da oggi difende il risultato invece di limitarsi a misurarlo.

Suite 79/79 verde. Esportato: `2026.07.31-web-loader-7` / `v21-web-loader`.

### Fase 4 — chiusa il 31 luglio (la ricchezza)

Obiettivo diverso dalle prime tre: quelle toglievano la noia, questa serve a
guadagnare la voglia di continuare. Tre cose, e due errori miei corretti in corsa.

**1. Il gradiente di difficoltà dentro la sessione.** Fino a ieri *ogni* minigioco
di un mondo aveva la stessa identica difficoltà: al mondo 3 tutto a 1, al mondo 20
tutto a 4. Una sessione piatta non è solo monotona, è didatticamente peggiore — si
entra senza scaldarsi e si esce senza essere stati messi alla prova. Ora la prima
campata scende di un gradino e l'ultima sale: **riscaldamento, corpo, sfida**. La
media resta quella del livello, quindi la progressione della campagna non cambia.

Effetto misurato sulla copertura delle bande: le prove a difficoltà ≥3 nella
seconda comparsa di una materia passano dal 100% al 71–79% (torna a esistere il
riscaldamento), e nella prima comparsa dal 3–5% al 24–27% (comincia a esistere la
sfida). Le bande estreme non spariscono più di colpo.

**2. Le bande vuote dei banchi.** Era il pezzo di Fase 2 che avevo lasciato
indietro: musica e fisica avevano **tre** item a difficoltà 1, storia quattro e un
solo item a difficoltà 4, coding uno. Con tre item in una banda il banco ripropone
la stessa domanda quattro volte su trenta. **89 item nuovi** su sette materie.

**3. Musica al primo mondo** aveva otto abbinamenti possibili in tutto — due
specifiche da quattro coppie. Portata a 375 con durate in battiti, nomi
internazionali delle note e modo di produrre il suono.

**I due errori, che vale la pena aver registrati:**

- ho legato il numero di tessere alla difficoltà **assoluta**. Risultato misurato:
  la profondità del primo mondo è crollata da 200.000 a 15.000 e le ripetizioni
  sono risalite dal 17% al 23%, perché al mondo 1 *ogni* campata pescava meno, non
  solo il riscaldamento. Il gradiente deve variare **dentro** la sessione, non
  spostare la campagna verso il basso: rifatto legandolo al passo (−1 / +1);
- ho scritto gli 89 item nuovi con la risposta sempre in prima posizione — comodo
  da autorare, ma `giveaway_audit` l'ha preso subito: la posizione fissa è un
  indizio gratuito. Ridistribuita sulle quattro posizioni.

**Il risultato che non mi aspettavo.** Le sessioni con lo stesso argomento nello
stesso formato sono passate da 72 a **zero su 3.648**. Non per contenuto: avevo
attribuito il problema a insiemi poveri, e mi sbagliavo — era la **selezione**. Il
banco pescava senza guardare quali argomenti fossero già nella sessione. Ora
preferisce un argomento non ancora usato, e il cricchetto è assoluto: una sola
sessione che chiede due volte lo stesso argomento fa fallire l'audit.

Suite 79/79 verde. Esportato: `2026.07.31-web-loader-8` / `v22-web-loader`.

### Dove siamo, alla fine del piano

| | prima | dopo |
|---|---|---|
| prove distinte producibili | ~2.450 | **oltre 33 milioni** |
| coppie (materia, formato) sopra 10.000 | 1 su 67 | **23 su 67** |
| peggiore ripetizione | ×8 · 38% *(misura non onesta)* | **×4 · 17%** |
| sessioni con argomento ripetuto | 184 al picco | **0 su 3.648** |
| materia più povera | storia, 6 prove | elettronica, **213.551** |

Tre cricchetti difendono il risultato: le ripetizioni possono solo scendere, la
profondità solo salire, e le sessioni con argomento ripetuto devono restare zero.

### Lavoro: fatto e da fare

- [x] **Passo 1 — separare identità e gate.** `ApparatusConfig.world_subject()` e
      `apparatus_of()` distinguono «quale materia abita il mondo N» da «cosa apre
      il livello». Cambiamento a comportamento identico, fatto per ridurre il
      raggio d'azione del passo 2 — 19 consumatori di `level_gate`, di cui 10 audit.
- [x] **Passo 2 — il gate è il nucleo.** `GateReadiness.evaluate_subject()` (tre
      dimensioni) ed `evaluate_core()` (le tre materie). `level_gate()` non
      contiene più `subject` né `missionsRequired`.
- [x] **Passo 3 — apparato e livello scollegati.** `repair_apparatus(subject)` e
      `advance_level()` sono due atti distinti; `repair_and_advance()` resta come
      compatibilità e può riuscirne solo uno.
- [x] **Passo 4 — HUD**: da «Missioni 3/5» a «Nucleo · Ita 82% · Mat 91% · Ing 64%»,
      più il contatore delle stanze accese.
- [x] **Passo 5 — il Cuore richiede dodici stanze accese.** `can_open_heart()`
      gatta la prova trasversale e `advance_level()` non supera l'ultimo gradino
      con materie mai affrontate. Il conteggio «Cuore N/12 stanze» è nel contratto
      **dal livello 1** e compare nel prompt dell'apparato: l'obiettivo si scopre
      all'inizio, non al mondo 24. Se il Cuore è chiuso, NORA dice **quali**
      stanze mancano — una porta chiusa senza spiegazione è un difetto quanto la
      porta impossibile. Guard-rail: `heart_gate_audit.gd`.
- [ ] **Passo 6 — le quattro leve di copertura**: nave incompleta visibile, bonus
      crescente sulle materie trascurate, collezione del Custode, «esploratore
      completo».
- [x] **Salvataggi**: profili attuali dichiarati sacrificabili dall'utente. Nessuna
      migrazione scritta: un save vecchio conserva livello e conteggi, che ora
      significano un'altra cosa (i conteggi non gatano più).

### Cosa è servito davvero: quindici audit riscritti

La migrazione ha toccato 19 consumatori, ma il lavoro vero è stato negli audit:
**codificavano le regole vecchie**, quindi diventavano rossi *correttamente*.
Riscritti sulla nuova semantica: `c01`, `c02`, `c05`, `c06`, `loop`,
`progression_1to24`, `boot_navigation`, `guardrails`, `topic_evidence`,
`ship_activation`, `ship_reactivation_sequence`, `world_wave_e2`, `roundtrip`,
più due probe. Misura finale: **75/75 verdi**, livello 2 dopo 15 missioni
(cinque per materia del nucleo).

Due difetti del *runner* trovati strada facendo, entrambi corretti:

- **`EBUSY` in pulizia abortiva l'intera suite** al primo audit appeso, nascondendo
  tutti i risultati successivi: su Windows l'handle su `godot.log` resta aperto
  qualche istante dopo il kill. Ora la pulizia non può far fallire la suite, e da
  lì si è passati da «vedo due errori» a «li vedo tutti insieme».
- Ho lanciato **due suite in parallelo** e si sono pestate i piedi sulla stessa
  cartella temporanea. Vale come regola: una suite per volta.

### Difetto trovato strada facendo: un file senza audit

Ho rimosso una variabile ancora usata in `competency_matrix.gd` e **la suite è
rimasta verde**: quel file non è coperto da nessun audit. Corretto subito, ma il
buco resta — la matrice delle competenze è l'artefatto per i docenti, e oggi
nessuno verifica che si generi. Da coprire.

### Il costo, e perché non si è pagato

Da 10 a 18 POI per mondo. Prima misura: mondo 1 a **2916 nodi** e avvio a
769/500 ms — fuori budget.

Invece di rinunciare alla decisione ho guardato dove andava il tempo: a POI non
completato `WorldLearningReaction` costruiva **cinque gruppi di nodi e li
nascondeva subito** (`set_progress(0, …)` li rende tutti invisibili). Con un solo
POI contava poco; con diciotto era il costo di avvio più grosso del mondo 1. Ora
le parti si costruiscono **al primo progresso reale**, che è quando si vedono; il
landmark — uno solo per mondo — resta eager perché le sue fasi devono essere
ispezionabili dal caricamento.

Esito: **2441 nodi con 18 POI, meno dei 2668 che c'erano con 10**. Avvio del mondo
1 su sei misure: 349, 360, 365, 398, 434 e un 623 isolato sotto contesa. Più
veloce di prima, con quasi il doppio dei POI.

Sei audit di wave verificavano `active_parts.size() == 5` **al caricamento**:
un dettaglio implementativo travestito da contratto. Ora verificano il
comportamento — che la trasformazione progressiva esista e avanzi dopo il primo
progresso — che è un test più forte di quello che sostituisce.

**Resta aperto**: il bonus «esploratore completo» promesso da `DESIGN_COMPLETO.md`
§3 per chi tocca materie diverse nella stessa sessione. Non implementato.

## Difetto corretto dopo segnalazione (30 luglio) — caccia all'errore poco chiara

Segnalato giocando, **sull'esame finale di matematica**, esercizio 4/4: «Controlla
il calcolo passo per passo: quale riga sbaglia?» con righe `7 + 5` / `= 13` /
`# quanto fa davvero?`. Il difetto peggiore nel posto peggiore.

Difetto **sistemico**, non di una specifica: `_build_code_debug` creava un pulsante
numerato per **ogni** riga di `codeLines`, compresa quella che inizia con `#`. Ma
quella riga è la **consegna** (porta l'intento: «atteso: 1, 2, 3»), e il generatore
lo sa già — `_code_debug_node` la tiene in coda perché «è la consegna». Modello e
vista erano in disaccordo: chi la selezionava riceveva «Quella riga è valida: segui
i valori passo per passo», che per un commento non significa nulla. Su tre righe
mostrate, una non era nemmeno un candidato.

Aggravante nella specifica segnalata: togliendo la consegna restavano **due** righe
candidate (quasi testa o croce), e non erano passaggi — `7 + 5` e `= 13` sono i due
pezzi di **una sola uguaglianza**, quindi «quale riga sbaglia» era ambiguo: l'errore
stava nella relazione fra le due, non dentro una delle due.

Correzioni:

- **la consegna diventa una nota in grigio**, leggibile e non selezionabile, e la
  numerazione delle righe candidate resta contigua (`answerLine` non cambia
  significato). L'istruzione non dice più «Il numero di riga è parte dell'indizio»,
  che era opaca, ma «Tocca la riga sbagliata. Le righe numerate sono i passaggi;
  in grigio la consegna»;
- **sei specifiche riscritte** con almeno tre righe candidate e passaggi veri
  (censimento sotto): due di matematica, quattro di coding;
- **contratto rafforzato** in `ExerciseInteraction._validate_code_debug`:
  `answerLine` non può puntare a una consegna — prima un nodo poteva dichiarare
  come soluzione una riga che il giocatore non può nemmeno scegliere, prova
  impossibile che nessun audit vedeva.

Guard-rail: **`code_debug_clarity_audit.gd`**. Censimento su tutte le materie:
`answerLine` mai su una consegna, almeno 3 righe candidate, massimo una consegna e
sempre in ultima posizione, e — solo dove l'ordine è fisso — la posizione
dell'errore che varia.

Due cose imparate, che valgono oltre questo difetto:

- **il mio primo audit ha prodotto un falso positivo** e l'ho scoperto prima di
  riportarlo: segnalava «l'errore è sempre alla riga 3» per scienze, geografia,
  storia, musica e latino. Ma quelle specifiche hanno `shuffleLines: true`: il
  runtime rimescola il corpo e ricalcola `answerLine`, quindi la posizione autorata
  è irrilevante. La regola ora si applica solo alle specifiche a ordine fisso.
  Morale: un audit che non conosce le trasformazioni a runtime misura il dato
  sbagliato;
- **gli audit che falliscono con `assert` si appendono** e perdono lo stdout
  bufferizzato — cioè l'output proprio quando serve. `code_debug_clarity_audit`
  stampa l'elenco completo dei problemi e poi esce con `quit(1)`: il runner lo
  considera rosso comunque (controlla anche l'exit code), non spreca il timeout di
  240 s e si legge. Modello preferibile per i prossimi audit.

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

## Ottimizzazione asset tablet

- export Web ridotto da **68,79 MiB** a **61,86 MiB**: `index.pck` da 30,79 a
  23,85 MiB, −6,93 MiB complessivi (circa −10%);
- landmark 1254–1536 px importati con limite 512 px, adeguato alla resa massima
  di circa 260 px; sorgenti originali conservati;
- atlanti naturali importati a 1024 px con crop calcolato dalla dimensione
  effettiva, non da coordinate rigide;
- tavole identitarie, landmark, atlanti di bioma ed enigmi caricati soltanto per
  il mondo/tema corrente e riusati tramite cache condivise;
- cache PWA aggiornata a `v9-web-loader`; il launcher confronta il build ID,
  attende l'attivazione del nuovo service worker e poi apre Godot, così il
  tablet non riceve il vecchio PCK al primo accesso dopo una pubblicazione;
- compressione selettiva Brotli/Gzip per WASM e JavaScript nei server Vite
  sviluppo/anteprima: il WASM trasferito scende da 37,68 a circa 7,92 MiB con
  Brotli; il PCK resta non ricompresso perché il guadagno è marginale;
- `npm run audit:web` verifica build ID, versione cache e dimensioni PCK/WASM
  prima di ogni build;
- verifica: export Godot riuscito, 184/184 test TypeScript verdi, audit diretti
  dei mondi 21–23 e del mondo/finale 24 verdi. Lo smoke Chrome automatizzato è
  attualmente bloccato dal canale DevTools locale prima della navigazione e va
  ripetuto sul dispositivo fisico.


## Registro O-P7 / C-P8 — qualità dei contenuti (3 agosto)

Tre lavori chiusi il 3 agosto. In tutti e tre il difetto vero stava un livello
più a monte di dove sembrava, ed è la ragione per cui vale la pena averli scritti.

### Inglese: ottanta traduzioni false, e il modello dati che le produceva

Non erano quaranta. Il primo conteggio usava un filtro su quattro verbi e le
famiglie rotte erano otto; fuori dal filtro ce n'erano altre cinque senza barra
(`pay attention` → «pagare attenzione», `ask a question` → «chiedere una
domanda», `give a presentation` → «dare una presentazione», `put on a jacket`,
`do the dishes`).

La causa non era nei dati ma nella loro forma. Le famiglie di locuzioni erano
definite in `englishVocabularyBank.ts` come `verbMeaning + oggetto` — **un solo
significato del verbo per tutta la famiglia** — e il bake incollava i due pezzi.
Ne uscivano «fare / preparare un errore» per *make a mistake* e «guardare /
sembrare la parola sul dizionario» per *look up the word*, e metà degli item
chiedeva di tradurre IN inglese partendo da quell'italiano. L'ironia: erano
proprio i phrasal verb e le collocazioni, l'unica famiglia che per definizione
non è componibile.

Corretto il modello: ogni riga porta il significato italiano **intero** più una
`note` che dice qual è la trappola, e il bake preferisce la nota alla spiegazione
a modello. 160 locuzioni riscritte, 124 con nota didattica. Finché restava la
forma vecchia, la prossima famiglia aggiunta sarebbe rinata sbagliata.

I cinque prompt ambigui (`report` verbo contro sostantivo, `sotto` = below
contro under, `fresco` = cool contro fresh, `route`, `audience`) non sono stati
risolti cancellando un item: i due sensi esistono entrambi e sono contenuto
utile. Si chiede **quale** senso, e la distinzione diventa la lezione.

Misure: glosse rotte 0, prompt ambigui 0, spiegazioni tautologiche delle
locuzioni da 160 a 36 (le 36 restanti sono lessico trasparente, criterio 3).

### La trappola del bake: 89 item cancellati senza un errore

`godot/data/banks/*.json` non sono sorgenti, sono il prodotto di
`build-exercise-banks.mjs`. Gli 89 item della Fase 4 («bande vuote dei banchi»)
erano stati scritti direttamente nei JSON e il bake non li conosceva: alla prima
riesecuzione sono spariti tutti e ottantanove, in silenzio. Recuperati da git e
portati in sorgente (`CURATED_TAIL`), verificando item per item che il bake
riproduca i dodici banchi identici a prima.

### Domande su un titolo di capitolo, e il generatore che le rendeva ambigue

«Qual è la definizione corretta di *Calore e temperatura*?» non è una domanda di
fisica: è ricordare quale paragrafo portava quale intestazione. Ma il difetto
grosso era un altro — **il generatore sceglieva i distrattori fra gli argomenti
più vicini** (`nearestFirst`), che per una definizione è il modo più rapido di
costruire una domanda con due risposte giuste. «Ritmo e intervalli» aveva fra i
distrattori «Un intervallo è la distanza tra due note…», vero e proprio sugli
intervalli.

Due regole nuove, e la seconda l'ha scoperta la prima sbagliando:

- un distrattore non può appartenere a un argomento **sovrapposto** a quello
  chiesto. Non basta confrontare le parole: «Conta includendo la nota di
  partenza» non contiene *intervallo* ed è comunque la risposta giusta per
  «Ritmo e intervalli», perché viene da «Intervalli e scale». Si guarda quindi
  anche il titolo dell'argomento di provenienza;
- un distrattore non può essere una **parafrasi** della risposta. Allargando il
  pool è comparso «Una croma vale mezzo battito, non uno» contro «La croma vale
  mezzo battito, non uno». Guardia sulle radici, tarata su un falso positivo
  vero: «biglietto di andata e ritorno» contro «biglietto di sola andata» sono
  l'opposto l'uno dell'altro e sono anzi un'ottima coppia di distrattori.

Costo: due item in meno, ed erano i due ambigui — `fisica-moto-forze-energia`
(titolo-ombrello la cui «definizione» definiva la fisica in generale) e
`musica-ritmo-intervalli-attenzione` (nessun distrattore pulito disponibile).

### I tre buchi del primo mondo

| | prima | dopo | come |
|---|---|---|---|
| storia `matching` | 4 | 440 | due insiemi al posto di due specifiche fisse |
| latino `ordering` | 1 | 1.143 | i numeri romani, dove l'ordine è una grandezza |
| logica `code_debug` | 1 | 7 | autorato: qui non si pesca |

- **storia**: le specifiche fisse non erano solo povere, **regalavano metà della
  risposta** — «Romani → Roma» e «Greci → Grecia» si risolvono dal nome senza
  sapere niente di storia. Sostituite da due insiemi da dodici voci (civiltà →
  invenzione, civiltà → dove viveva), più un terzo da ventiquattro gatato al
  mondo 6 per i popoli che si studiano più tardi;
- **latino**: la Fase 3 aveva concluso che qui l'ordine è convenzione pura e non
  si parametrizza. Vero per i casi e per le parole di una frase, **non per i
  numeri romani**, dove l'ordine è una grandezza misurabile — il criterio del
  progetto. Le forme sottrattive (XL, XC, CD, CM) in un secondo insieme dal
  mondo 5;
- **logica**: nella caccia all'errore l'ordine delle righe **è** il ragionamento,
  quindi non si pesca. Sei casi autorati con l'errore distribuito su tutte e tre
  le righe — con l'errore sempre in fondo si impara a scegliere l'ultima riga
  invece di leggere — e ognuno rompe un anello diverso: premessa falsa, regola
  letta male, quantificatore allargato da «alcuni» a «tutti», conto sbagliato.

**Esito complessivo: il ×4 è sparito.** Peggiore ripetizione del gioco ×3, le tre
materie a ×2. Profondità: coppie (materia, formato) sopra le 10.000 da 23 a 25 su
69. Suite 82/82 Godot, 184/184 TypeScript.

## Minigiochi-personaggio — tre pilot e contratto completo (11–12 agosto)

Lavoro condiviso Opus/Codex a partire da `insieme.md`:

- **Tobia**: `Il mucchio che non finisce`, velocità e raggruppamento in decine;
  cristallo generativo trasparente, file leggibili 5+5, vassoi visivi e bersagli
  da 40 px;
- **Corinna**: `Lo scaffale che non si vede`, riflessione senza cronometro;
  carta-parola, scaffali da 92 px, feedback d'errore non punitivo e movimento
  disattivabile;
- **Ciro**: `Il circuito mutante`, tre reti riconfigurate e tre nodi per rete al
  mondo 8; corrente animata, incroci non connessi, errore locale senza reset e
  difficoltà crescente per schemi/passaggi anziché per tempo;
- glifo unico della convinzione, disegnato dal motore e predisposto nello stato
  intatto/spezzato;
- prima vittoria resa un momento narrativo unico: il gioco resta riprovabile
  dopo una sconfitta, ma non si riapre più a ogni saluto dopo il successo;
- matrice completa dei **46 residenti**, bilanciata 23 velocità / 23 riflessione,
  in `docs/MINIGIOCHI_PERSONAGGI.md`;
- layout verticale dei tre pilot ingrandito dopo il layout Godot: a 600×900 il
  circuito occupa quasi tutta la larghezza e conserva bersagli fisici di circa
  45 px. Catture riproducibili in `artifacts/character-minigames`.

Verifiche: `character_minigame_audit` verde,
`character_minigame_visual_audit` verde e `circuit_minigame_audit` verde; la
prova giocata attraversa un errore e tutte e tre le riconfigurazioni. Caricamento progetto e export Godot
senza errori di script. Export Web `2026.08.11-web-loader-6`, cache
`v96-web-loader`, PCK 25,39 MiB e core 63,07 MiB; `audit:web` e build Vite
verdi. Lo smoke Chrome non è partito in due tentativi perché DevTools non ha
risposto a `Page.enable` entro 30 secondi: errore precedente al caricamento del
gioco, da ripetere quando il canale browser è disponibile.

## C-ART-3/4 — confronto e conseguenze visibili (13 agosto)

- Il confronto Eli/NORA si svolge nella prova trasversale del mondo 24, dopo i
  dodici sistemi e prima del nodo di sintesi. Conserva indice, scudi e risposte,
  cambia intestazione a ogni blocco ed è saltabile senza scelta o stato di gate.
- I due luoghi vivi di ogni mondo 1–23 appartengono ora a residenti distinti:
  specialista nella casa del mestiere, testimone al Ritrovo. Finestre e facciata
  leggono lo stadio di quella persona; una vittoria con Tobia non modifica più
  il posto di Ersilia.
- Il pilot del mondo 1 aggiunge due conseguenze procedurali continue 0→1→2:
  mucchio → guide → gruppi di dieci per Tobia; cesto → ritmo riconosciuto →
  sette pagnotte sui battiti per Ersilia. Nessun testo, numero, segno di spunta,
  input o vantaggio meccanico; due nodi totali.
- Corretto un difetto emerso dal giro: il minigioco di Ersilia si apriva prima
  di persistere `ersiliaCountHeard`, quindi la conta tornava al rientro. L'audit
  dei mondi ora conta le tracce delle sorelle dalla stessa API usata dal runtime.

Misura isolata: mondo 1 a **2.789/3.500 nodi** e **311/500 ms**. Verdi
`building_audit`, `performance_budget_audit`, `world_l1_readiness_audit`,
`world_wave_e2_audit`, i cinque audit `exercise`, i due `finale`, `npc_arc`,
`mystery`, `world_life`, `c07`, `nora_arc`, `diary` e `thirteenth`.
QA visuale sul renderer reale: sei catture 1024×600 in
`artifacts/resident-consequences` confermano che i tre stadi restano distinguibili
senza dialogo; la sonda riproducibile è `resident_consequence_render_probe.gd`.

---

## G-1 · La serie (13 agosto)

Prima voce dello strato di gioco pianificato in `insieme.md`. La parola `combo`
non compariva in **nessuno** script del progetto, benché `DESIGN_COMPLETO` §6 e
§10 la dessero per esistente dal principio: una risposta giusta valeva dieci
punti, la prima come la ventesima, dal mondo 1 al mondo 24.

- **La regola** sta in `combo.gd`, modulo puro nello stile di `reflex_duel.gd`:
  il moltiplicatore parte da uno, sale di un quarto per ogni risposta giusta
  consecutiva dopo la prima e si ferma a **×2 alla quinta**, che è la lunghezza
  di un esame — il tetto esiste e si guadagna tutto. Sotto due giuste di fila non
  si mostra niente: un «×1» sempre a schermo non segnala nulla.
- **La serie si spezza in `_spend_shield()`**, che è l'unico passaggio obbligato
  di ogni errore in tutti i formati. Azzerarla in `_score_current` avrebbe
  lasciato viva la serie di chi sbaglia *dentro* un minigioco senza chiudere il
  nodo — cioè in metà del gioco.
- **Non attraversa le sessioni.** Una serie che si porta dietro il mondo diventa
  una cosa da proteggere invece che da giocare: si smetterebbe di toccare le
  materie deboli per non spezzarla, che è il contrario di ciò che il gate chiede.
- **Quando finisce non dice niente**: nessun suono, nessun rosso, nessun
  messaggio (decisione 13). Il bambino ha già ricevuto la spiegazione e ha già
  perso uno scudo; un terzo segnale sullo stesso errore è accanimento.
- L'esito di sessione porta ora `comboBest` e `comboEnergy`. Nessuna regola li
  legge: `energyGained` contiene già tutto, e la semantica a valle non è
  cambiata di una riga.

**Misura e guard-rail.** `combo_audit` verde, e verificato che morda: togliendo
l'azzeramento fra una prova e l'altra diventa rosso. Controlla l'aritmetica
(monotona, con tetto, raggiungibile in una sessione vera), il tetto di sessione
(nessuna prova perfetta, fino a venti nodi, supera il doppio della tariffa
piatta: il catalogo della bottega è tarato sul totale della campagna) e
soprattutto la **decisione vincolante 15**, con una prova comportamentale invece
che una lettura del codice — gli stessi esiti registrati due volte con energie
0 e 9999 devono lasciare la stessa padronanza e lo stesso conteggio di gate, e
l'energia deve davvero essere arrivata, altrimenti il confronto non proverebbe
niente.

Nessun esercizio aggiunto: la campagna resta a 21,1 ore. Suite completa
**167/167 verde in 232 s**. **C-G1 chiusa da Codex**: `ComboBadge` cresce con
un colpo neutro, cambia colore fino al tetto e si dissolve senza rosso, suono o
messaggio quando la serie si spezza. `combo_audit` verde sul consumer reale.

**Export fatto** il 13 agosto: `2026.08.13-web-loader-9`, cache `v112-web-loader`,
PCK 33,60 MiB, WASM 37,68 MiB. **`audit:web` è ROSSO**, e non per questo lotto:
`build_version.gd` stampa ancora `af66cec` mentre HEAD è `9005079`. Torna verde
solo dopo un commit, `npm run version:stamp`, riesportazione e risincronizzazione
— e al momento dell'export l'albero conteneva anche lavoro **non commesso di
Codex** (il ponte camminabile della nave e il layout verticale condiviso), che è
quindi finito dentro il PCK. Chi commette decide se separarli.

---

## Lotti visuali Codex — strato di gioco (13 agosto)

- **G-6, nave camminabile.** Il corpo centrale ospita Eli con lo stesso
  `player_controller.gd` del mondo esterno, dodici porte-materia e input
  touch/click. Le luci leggono `HubController.runtime_state()`; la scena non
  richiama più `ShipActivationModel`. La mappa dei mondi e il ritorno al mondo
  restano raggiungibili. `ship_scene_audit` verde: **249 nodi**, contro il tetto
  assoluto di 3500.
- **C-G7, reazione per nodo.** `notify_progress` inoltra anche le missioni
  ordinarie e ogni POI aggiorna il proprio `WorldLearningReaction`. Il visual
  sceglie la trasformazione già dichiarata per bioma e tipo; non calcola
  ricompense o completamenti. `event_progress_visual_audit` verde.
- **C-G2 e C-G3, consumer chiusi.** L'HUD mostra celle e conteggio cariche da
  `pulseCharges`/`pulseChargeMax` (`pulse_hud_audit` verde). Le quattro
  spritesheet 5×4 e le quattro orbite aggiuntive seguono ora il contratto
  Solstizio → Costellazione → Galassia → Prima Luce. `eli_evolution_audit`
  verifica nove tavole, l'associazione del loader, le sei orbite a grado 8 e la
  riduzione del movimento.
- **C-G9, presenza del Custode.** Il volto resta data-driven e ora la stessa
  decisione di `PetExpressionEngine` pilota una posa del corpo, con varianti per
  festa, orgoglio, curiosità, attenzione e incoraggiamento. Nessun segnale
  concede potere. `pet_pose_audit` verde su tutti i segnali dichiarati.
- **C-MG-4.** Quindici pannelli, inclusi radio e mercato, usano
  `MinigamePanelLayout.adapt_vertical`; nessuna copia locale di
  `_adatta_verticale`. `minigame_vertical_layout_audit` verde.
- **C-ART-2.** I 46 asset-residente già approvati vengono composti in tre pose
  mezzo busto guidate dallo stadio dell'arco; lo stadio arriva dal runtime e il
  ritratto non lo calcola. `resident_portrait_stage_audit` verde: **46 × 3**.
- **Comparsa minimissioni.** In un mondo nuovo il POI non è già visibile: la
  prima prova riuscita lo accende con una transizione, mentre nei mondi già
  giocati resta immediatamente disponibile. `minimission_reveal_audit` verde.

Gli spritesheet evolutivi sono stati generati con ImageGen built-in partendo da
Meridiana come riferimento vincolante, su chroma-key piatto; la normalizzazione
locale produce PNG 480×384 con alpha e angoli trasparenti validati. Nessun testo
è incorporato nelle immagini.

**Chiusura e release (14 agosto).** La suite completa ha coperto 174 audit: il
primo passaggio ne ha chiusi 173 e ha intercettato una sovrascrittura testuale
del silenzio al terzo errore; corretto il consumer di progresso, sono verdi sia
`pet_struggle_relief_audit` sia `event_progress_visual_audit`, quindi **174/174
verdi**. Export Web finale sincronizzato come `2026.08.14-web-loader-1`, cache
`v114-web-loader`: PCK 34,33 MiB, WASM 37,68 MiB, core 72,01 MiB;
`audit:web` verde. Questo record sostituisce il rosso transitorio annotato nel
lotto precedente; l'export include il worktree non commesso corrente.

---

## G-2 · L'impulso si guadagna (14 agosto)

Il difetto più grosso trovato nella lettura dello strato di gioco, e nessun
controllo lo aveva visto per una settimana perché ogni pezzo era coerente con se
stesso. Il 7 agosto le sacche di Silenzio erano diventate un pericolo con un costo
tarato sul grado di Eli — `world_enemy.gd` lo spiega per venti righe: *chi si
allena passa senza pagare* — e nello stesso mondo c'era un pulsante che le
stordiva **gratis**, con raggio 168 e ricarica in **1,25 secondi**. Il morso non
lo pagava nessuno, il grado di potenza non serviva a niente contro le sacche, e la
barra sullo schermo misurava una forza che non veniva mai messa alla prova.

- **La riparazione cambia specie alla risorsa, non la tara.** Un cooldown si
  rigenera da sé e quindi non è un costo, è un'attesa. Le cariche in
  `pulse_charge.gd` si **guadagnano** nell'unico modo che questo gioco riconosce:
  due prove superate una carica, tetto tre. Da qui la catena che il lotto del 7
  agosto voleva e non aveva: *studi → hai l'impulso → passi*.
- **A serbatoio pieno non si accumula.** Se il progresso continuasse a salire, chi
  gioca a lungo con tre cariche si ritroverebbe una riserva invisibile che si
  scarica tutta insieme: il tetto sarebbe una finzione e la scelta *passo o giro
  attorno* tornerebbe a non esistere.
- **Si parte da zero.** Regalare una carica all'avvio sembrerebbe gentile e
  insegnerebbe la cosa sbagliata: le celle vuote accanto alla barra di potenza
  dicono, senza una riga di testo, che quella cosa si riempie giocando. Non è un
  vicolo cieco perché il morso non ferma nessuno.
- **Il cronometro resta, ridotto a 350 ms**, e non è più l'economia: è un
  antirimbalzo, perché un tocco doppio involontario non deve bruciare una carica
  guadagnata con due prove.
- **L'economia sta nella semantica** (`OutdoorGameplay.usa_impulso`), non nella
  scena: la presentazione chiede e disegna. La resa C-G2 di Codex era già pronta e
  legge `pulseCharges`/`pulseChargeMax` dal contratto runtime — questo lotto ha
  collegato le due metà.

**Misura e guard-rail.** `pulse_economy_audit` verde, e verificato che morda: un
impulso che si accende sempre lo fa diventare rosso. Verifica l'aritmetica delle
cariche (tetto compreso, e che non si banchi una riserva), che l'impulso non sia
mai gratuito, che le cariche si guadagnino **solo** con le prove — energia,
frammenti e acquisti provati uno per uno — che accenderlo non tocchi nient'altro
nel salvataggio, e soprattutto che **le cariche non gattino niente**: due partite
identiche con zero e con tre cariche hanno uno stato di progressione che differisce
in `pulseCharges` e in nient'altro. È la forma verificabile di «niente sulla mappa
può fermare la progressione». Una prova **fallita** non ricarica.

**Una lezione, pagata falsificando.** Alla prima stesura l'audit conteneva un
`while PulseCharge.consuma(...)`. Provando a falsificarlo — cioè rimettendo
l'impulso gratuito — non è diventato rosso: si è **appeso**, quattro minuti, fino
al timeout. Un cricchetto che si blocca invece di rompersi fa perdere il giro a
tutta la suite e non dice niente a chi guarda. Ora il ciclo è limitato e fallisce
in un secondo.

**Due regressioni prese dalla suite**, entrambe vere e nessuna visibile
rileggendo: `eli_enemy_audit` misurava lo stordimento e `accessibility_release_audit`
la forma dell'onda con riduzione movimento, e da oggi senza una carica l'impulso
non si accende — quindi non c'era niente da misurare. Entrambi accreditano ora la
carica con lo stesso gesto che la darebbe al giocatore.

Suite completa **175/175 verde in 237 s**. Export finale fatto dal commit sorgente
`30bfe49`: `2026.08.14-web-loader-3`, cache `v116-web-loader`, PCK 34,33 MiB,
WASM 37,68 MiB, core 72,01 MiB. `audit:web` verde.

---

## La matematica del primo livello (14 agosto)

Segnalazione di una studentessa in collaudo: «gli esercizi di matematica del
primo livello sono troppo semplici». Misurata con una sonda nuova
(`first_level_probe.gd`, quaranta sessioni campionate per condizione), aveva
ragione, e le cause erano **tre e indipendenti**.

**Uno · il pavimento del generatore.** La complessità 1 ammette sei archetipi —
addizione, sottrazione, moltiplicazione, sequenza e due problemi a un passaggio —
con somme sotto il 35 e sottrazioni sotto il 28. Uscivano «Quanto fa 11 − 6?» e
«5 monete al mattino e 6 nel pomeriggio»: tre o quattro anni di scuola sotto la
fascia dichiarata (10–13). Il livello 1 vale ora nominalmente **complessità 2**;
la complessità 1 resta viva come gradino verso il basso per chi ha padronanza
sotto 0,5. Limite dichiarato nel codice: ai livelli 1–3 quel gradino non c'è,
perché il livello efficace non scende sotto 1 e lì il nominale *è* il pavimento.

**Due · le tabelline non coprivano le tabelline.** Con i vecchi limiti il fattore
massimo al livello 1 era **7**: quelle dell'8, del 9 e del 10 non uscivano mai, in
una materia il cui banco si chiama `matematica-tabelline`. Ora al nominale si
arriva a 10 e al gradino di chi fatica a 8.

**Tre · il banco aveva un argomento solo.** 284 voci, tutte `tabelline` — l'unica
materia su dodici così, le altre ne hanno da sette a ventuno. Aggiunti **80 item
scritti a mano** su cinque argomenti che NORA già sa spiegare: frazioni,
percentuali, geometria, espressioni, statistica. Il banco passa da 284 a **364
voci e da 1 a 6 argomenti**; la difficoltà 1 da 16 voci di un argomento a **41 di
sei**. Stanno in `build-exercise-banks.mjs` (il JSON è un prodotto del bake: chi
scrivesse lì perderebbe tutto al giro dopo, ed è già successo).

**Il difetto trovato scrivendoli, ed era il più grosso.** Per la matematica
`build_mission` costruiva i nodi con il generatore e **usciva prima di guardare il
banco** — sempre, anche nell'esame. Ottanta item scritti e nessuna strada per
arrivarci: la stessa specie di guasto dei `modules` nel salvataggio. Ora un nodo
su tre viene dal banco (`_innesta_banco_matematica`), le tabelline escluse
dall'estrazione perché il generatore ne produce già in abbondanza.

Tre regressioni prese dalla suite mentre lo si collegava, tutte vere:

- l'innesto poteva **cancellare il nodo di ripasso spaziato** — il sistema
  didattico decide che cosa deve tornare oggi, e un innesto che glielo sovrascrive
  rompe la sua promessa. Le posizioni di ripasso sono ora escluse
  (`c11_world_content_audit`);
- due item di banco potevano cadere **sullo stesso argomento nello stesso
  formato** nell'esame da cinque nodi: tre sessioni su 3648, e `format_mix_audit`
  ne ammette zero. Un argomento per sessione, e mai uno già presente;
- gli item di banco non portavano la `signature` che ogni nodo di matematica ha:
  un lettore a valle andava in errore invece che in rosso.

**Misurato dopo.** Al livello 1 la missione passa da 11 a **14 argomenti**, la
banda di difficoltà da 105/15 a **58/62** fra 1 e 2, e compaiono le domande che
prima non esistevano: «Come si trova rapidamente il 10% di un numero?», «Il
perimetro di una figura è…». Il banco resta al **29,9% di risposta libera**,
dentro la forbice 20–30% (la conversione è automatica nel bake).

Suite completa **175/175 verde in 246 s**. Export: `2026.08.14-web-loader-4`,
cache `v117-web-loader`, PCK 34,38 MiB. `audit:web` resta rosso per lo stamp di
versione fermo a `af66cec`, come nei due lotti precedenti.

---

## G-3 · La potenza non si ferma a metà campagna (14 agosto)

La scala della potenza si fermava a **140 prove, cinque gradi**, ed era stata
scritta quando i mondi non erano ancora ventiquattro. Le sacche di Silenzio
invece salgono fino al grado otto (`1 + floor((livello−1)/3)`).

**La misura, con una sonda nuova.** `power_curve_probe` simula il percorso vero —
missione della materia del mondo più pratica delle materie che il gate dichiara
mancanti, fino a superare il livello, più l'esame — e conta le prove superate
mondo per mondo. La campagna intera vale **590 prove**, e il grado massimo
arrivava all'**ottavo mondo**: per sedici mondi Eli non cresceva più mentre la
minaccia continuava a salire. Lo scarto misurato arrivava a **−4** ai mondi
22–24, cioè otto energie a ogni morso contro un giocatore che non poteva farci
niente.

Nessun audit se ne era accorto perché ognuno guardava metà del problema:
`world_light_audit` controllava che le soglie crescessero, `enemy_threat_audit`
che il grado massimo bastasse. Nessuno confrontava **quando** si arriva a un
grado con **quanto è forte la minaccia in quel momento**.

- **Nove gradi**, con le prime cinque soglie **intatte**: un salvataggio in corso
  non deve retrocedere di grado per una modifica alla scala. Le quattro nuove —
  Solstizio, Costellazione, Galassia, Prima Luce — a 215, 300, 395 e 500 prove,
  scelte perché lo scarto resti fra −1 e +1 in tutti e ventiquattro i mondi e
  nessun gradino duri più di tre. Misurato dopo: grado 0 al mondo 1 (giusto: le
  prime sacche devono mordere) e grado 8 al mondo 21.
- **C-G3 chiuso**: le nove spritesheet di Eli e le sei orbite erano già pronte;
  il contratto ora le nomina e `eli_evolution_audit` verifica l'associazione
  esatta dei nove gradi, Prima Luce nella scena e il comportamento a movimento
  ridotto.
- **Il varco ha un tetto** (`VARCO_MASSIMO`): a grado otto contro una sacca di
  grado uno copriva il 50,8% della pista, oltre il limite che `reflex_duel_audit`
  chiama «un regalo». Il tetto non tocca i gradi 0–4, che restano tarati com'erano.
- **Il grado consigliato delle minimissioni** seguiva una scala sua, tetto 4:
  dalla metà della campagna in poi qualunque giocatore lo superava senza
  accorgersene e il rischio dichiarato — entrare impreparati costa una volta e
  mezzo — smetteva di esistere per dodici mondi. Ora segue la scala della minaccia.
- `reflex_duel_audit` **leggeva il numero dei gradi da una costante scritta a
  mano** (5): i quattro nuovi sarebbero rimasti fuori da ogni controllo senza che
  diventasse rosso. Ora lo chiede alla scala.

**Il cricchetto spostato, non allentato.** `world_light_audit` pretendeva che
l'ultima soglia stesse sotto **400 prove**, con la motivazione giusta — «una
promessa che nessun bambino vedrà» — e un numero **inventato**: una stima della
campagna fatta prima di misurarla. Il controllo è passato a `power_curve_audit`,
che possiede la tabella misurata e verifica tre cose che lì non si potevano
vedere: che ogni grado arrivi dentro la campagna, che l'ultimo arrivi con almeno
quaranta prove di margine, e che il grado di Eli non resti mai più di due sotto
quello delle sacche di quel mondo. Verificato che morda: rimettendo la scala a
cinque gradi elenca da solo i mondi 19–24 con scarto 3 e 4.

Suite completa **176/176 verde in 245 s**. Export: `2026.08.14-web-loader-5`,
cache `v118-web-loader`, PCK 34,38 MiB. `audit:web` resta rosso per lo stamp di
versione fermo a `af66cec`.

---

## G-5 · L'economia misurata, e una voce di piano smentita (14 agosto)

G-5 diceva: «un esercizio del mondo 22 paga come una tabellina del mondo 1», e
proponeva di scalare la tariffa con la banda di difficoltà. **La misura l'ha
smentita**, ed è il motivo per cui questo lotto non contiene la modifica che
prometteva.

La frase è vera per esercizio ed è **falsa per minuto giocato**, che è l'unica
unità in cui la domanda ha senso: un mondo alto ha formati più lenti e più
sessioni, e il conto si chiude da solo. Misurato con `economy_probe` su tutti e
ventiquattro i mondi, simulando il percorso vero e calcolando l'energia con le
regole del gioco (tariffa dichiarata, serie di [[Combo]], premio di
completamento, meno l'ingresso): **da 40,6 a 45,4 energia al minuto, squilibrio
1,12x**.

Scalare le tariffe avrebbe **creato** lo squilibrio che voleva togliere.
Provato: con una tariffa che cresce di sei per banda, il mondo 20 paga 86,6
energia al minuto contro le 55,8 del mondo 4 — 1,55x — e tornare indietro a
ripassare, che il design chiama esplicitamente «ripasso mirato», sarebbe
diventato un modo per perdere tempo.

Quindi al posto della modifica c'è un **cricchetto che impedisce di introdurla**:
`economy_curve_audit` costruisce una sessione per ognuno dei ventiquattro mondi,
ne calcola l'energia al minuto e pretende che lo squilibrio resti sotto 1,45x;
in più riverifica il tetto della serie dal lato dell'economia — nessuna sessione
perfetta paga più del doppio della sua tariffa piatta — perché è il punto in cui
una modifica alle ricompense lo romperebbe senza toccare `combo.gd`. Verificato
che morda: con le tariffe scalate diventa rosso e nomina i due mondi.

**Il numero che serviva a G-4.** Il catalogo della bottega costa **72.600
energia** su 55 voci; la campagna ne produce **53.783** senza errori e **42.758**
sbagliandone una su cinque, cioè il **74%** e il **59%**. Il sink estetico è
tarato bene e non c'è energia in eccesso da drenare: i moduli di spedizione, se
entrano, devono essere **pochi e permanenti** (quattro o cinque a 150-600, circa
il 3% del catalogo) e mai consumabili, che sarebbero un rubinetto senza fondo su
un'economia già stretta.

Suite completa **177/177 verde in 247 s**.

---

## G-4 · I moduli di spedizione (14 agosto)

L'unica cosa che la bottega vende oltre alla bellezza, e nasce da una
contraddizione fra due documenti che avevano ragione tutti e due:
`DESIGN_COMPLETO` §8 prometteva sette moduli NORA (indizio, seconda chance, tempo
extra), il lotto del 6 agosto aveva deciso il contrario — *«un consumabile utile
diventa una scorciatoia per non sapere»*.

**La distinzione che li concilia è dove agisce il modulo.** Uno che tocca una
**prova** è una scorciatoia per non sapere; uno che tocca la **mappa** no — la
stessa distinzione che rende lecito mettere un duello di riflessi davanti a un
forziere di cosmetici. Da qui la decisione vincolante 15 applicata alla bottega.

- **Tre moduli, non sette**, perché tre sono quelli che **funzionano davvero**:
  Serbatoio ampliato (una carica d'impulso in più), Bobina larga (raggio
  dell'impulso da 168 a 230), Passo lungo (scatto da 1,65× a 1,95×). Radar dei
  forzieri e raggio della torcia restano nel piano finché non esiste la loro
  resa: un oggetto che promette una meccanica inesistente è già stato il difetto
  del 6 agosto, quattro upgrade da 1600 frammenti che non facevano nulla.
- **Permanenti, mai consumabili**, e il numero lo dice: il catalogo costa 72.600
  e una campagna produce fra 42.758 e 53.783 (G-5). Non c'è energia in eccesso da
  drenare. I tre costano insieme **950, l'1,3% del catalogo**: la scelta in
  bottega esiste e il sink estetico non se ne accorge. Un consumabile sarebbe un
  rubinetto senza fondo su un'economia già stretta.
- **Nessuna chiave nuova nel salvataggio.** `cosmetics.inventory` raccoglie già
  gli acquisti permanenti che non si equipaggiano e ha i suoi lettori: è bastato
  aggiungere `module` agli slot non equipaggiabili. La chiave `modules`,
  dichiarata e mai costruita (decisione 14), resta sepolta dov'è.
- **La semantica calcola, la scena legge un numero.** `runtime_state()` pubblica
  `pulseChargeMax`, `pulseRadius` e `sprintMultiplier`; l'impulso e il
  controller del giocatore non sanno niente di bottega né di acquisti.

**Il guard-rail, provato sul comportamento.** `expedition_module_audit` verifica
che ogni modulo esista e si compri davvero (compresa la sezione in bottega: un
oggetto che nessuna schermata elenca non esiste), che **cambi un numero**
misurabile fino al contratto runtime, che comprarlo non sposti padronanza,
conteggi del gate o prontezza al livello successivo, che nessuno sia necessario,
e che i moduli non superino il 6% del catalogo. Verificato che morda: rendendo
un modulo inerte lo dichiara rosso in due righe.

**Una regressione presa dalla suite**, e la riparazione vale oltre questo lotto:
`shop_presentation_audit` pretende un'illustrazione per **ogni** voce del
catalogo, e i tre moduli non ne hanno. La scelta era fra rimandare i moduli
finché non esiste l'arte o dargli una resa onesta subito. La bottega ora ha un
**ripiego generico** — un cerchio col glifo e il colore già dichiarati nella voce
— al posto del `return null` che valeva solo per i due strumenti disegnati a
mano: è la stessa regola che il progetto applica ai lotti di Codex, una cosa deve
essere usabile con forme piene e colori piatti prima che esista un disegno.

Suite completa **178/178 verde in 257 s**. Export: `2026.08.14-web-loader-6`,
cache `v119-web-loader`, PCK 34,38 MiB.

---

## G-9 · La presenza del Custode (14 agosto)

Il motore delle espressioni dichiarava **ventuno segnali** e la scena ne emetteva
quindici. Cinque erano **morti** — `session_start`, `mission_complete`,
`topic_consolidated`, `apparatus_repaired`, `idle` — ed è la decisione 14
applicata ai segnali invece che alle chiavi del salvataggio: non è un'analogia,
quella decisione nomina proprio `near_unexplored` e `near_faded` come il quarto
caso della stessa malattia.

**Il difetto senza sintomi.** Due chiamate passavano `_pet_react("festa")`, e
`festa` è una **faccia**, non un segnale: `face_for` non trovava la chiave e
ripiegava sul volto a riposo. Il Custode restava sereno nei due momenti che sono
la sua stessa presentazione — quando viene consegnato al bambino e quando riceve
un nome. Non dava nessun errore, e nessuna rilettura del codice l'avrebbe visto.

Collegati ora, tutti a cose **già a schermo** (la decisione 12 vieta che il
Custode anticipi o aiuti):

| segnale | quando | faccia |
|---|---|---|
| `pet_granted` (nuovo) | il Custode arriva e riceve un nome | festa |
| `power_grade_up` (nuovo) | Eli sale di grado di potenza | orgoglioso |
| `sister_found` (nuovo) | si apre la traccia di una sorella | attento |
| `session_start` | si apre una prova | concentrato |
| `mission_complete` | una tappa si chiude e sparisce dalla mappa | festa |
| `topic_consolidated` | un argomento diventa consolidato nel manuale | festa |
| `idle` | quarantacinque secondi senza che accada niente | offeso |

`topic_consolidated` ha richiesto un canale che non esisteva: `OutdoorGameplay`
emette ora un segnale omonimo quando un argomento raggiunge lo stato
consolidato — il traguardo più silenzioso del gioco, che non dà energia e non
apre niente, e che fuori dalla semantica non sapeva nessuno.

**Sull'`idle`, che era la scelta delicata.** Una faccia imbronciata dopo un
lungo silenzio non punisce: non toglie legame, non mostra messaggi, passa da
sola. La decisione 13 vieta di punire l'assenza, e qui non si perde niente — è
l'unica cosa che il Custode può fare per esistere quando il gioco non lo guarda.

**Il cricchetto.** `pet_presence_audit` pretende che ogni segnale dichiarato
abbia qualcuno che lo emette, che nessuno passi una faccia al posto di un
segnale, che ogni segnale abbia una faccia nota, e che **nessuna reazione nasca
da energia, frammenti, cosmetici o moduli** — la decisione 12 verificata a monte,
su ciò che fa reagire il Custode e non solo su ciò che fa. Verificato che morda:
rimettendo `_pet_react("festa")` lo dichiara rosso nominando il file.

**Un falso rosso, e la lezione.** Alla prima stesura l'audit dichiarava morti
tutti e cinque i `learning:*`, che nascono da `_pet_react("learning:%s" % nome)`:
la loro stringa intera non compare da nessuna parte. Un falso rosso è una bugia
esattamente come un falso verde, e insegna a non fidarsi del cricchetto: la
ricerca riconosce ora anche il modello interpolato.

**C-G9, il Custode nella nave (14 agosto).** La voce in lista d'attesa è chiusa:
`hub_scene.gd` mostra lo stesso `ShipPetFaceWidget` quando il Custode è stato
consegnato, apre `ShipPetScreen` con la pressione lunga e conserva il tetto di
legame per sessione anche sulla carezza. Un apparato riparato emette ora
`apparatus_repaired` prima della riattivazione, senza energia, frammenti o effetti
sui gate. `ship_pet_presence_audit` prova sul consumer reale volto, carezza,
schermata e reazione alla riparazione; `pet_presence_audit` non ha più segnali in
attesa. Il Custode resta accanto a Eli anche dentro la nave.

Suite completa **180/180 verde in 253 s**. Export: `2026.08.14-web-loader-7`,
cache `v120-web-loader`, PCK 34,45 MiB.

---

## C-G8 — paesaggio sonoro dei mondi (14 agosto 2026)

Il profilo reale contiene **24** combinazioni `terrainFamily`/`soundscape`, non le
22 stimate nel piano. Il generatore deterministico produce quindi 24 loop mono
da **60 secondi** a 22.050 Hz: un file distinto per mondo sonoro, organizzato in
nove famiglie di motivo. Nessun paesaggio ha più di quattro vicini con lo stesso
motivo; il mix già esistente conserva volume e altezza specifici del profilo.

`NativeAudioManager` risolve prima l'asset del `soundscape` e mantiene il vecchio
`ambience.day`/`ambience.night` come fallback esplicito per manifest incompleti.
Il manifest contiene 60 asset complessivi, inclusi i 24 loop lunghi, e l'audit del
generatore controlla durata, clipping, RMS, continuità del loop, unicità e
vicinanza timbrica. `audio_asset_audit` verifica anche il resolver usato dal
runtime e stampa: **C-G8 AUDIO ASSET audit OK — 24 soundscape da un minuto,
fallback intatto**.

**Chiusura release.** Suite Godot completa **181/181 verde in 283 s**. Il primo
passaggio aveva rivelato che gli audit delle ondate leggevano l'alpha dalla
texture già compressa per GPU; ora le sette ondate controllano il PNG sorgente e
restano valide anche con ETC2/S3TC. Export Web finale sincronizzato come
`2026.08.14-web-loader-9`, cache `v122-web-loader`: PCK **60,36 MiB**, WASM
**37,68 MiB**, core **98,04 MiB**; `audit:web` verde e manifest allineato.

---

## Registro dei lotti Opus (5–13 agosto 2026)

Trasferito qui il 13 agosto 2026 snellendo `insieme.md`, che per sua regola
contiene **solo lavoro da fare**. Un lotto per blocco: che cosa è cambiato, la
misura che lo dice e l'audit che lo tiene. I residui aperti di ciascuno non stanno
qui — stanno nel piano.

**Le spiegazioni (5 agosto).** 3392 item, 3172 spiegazioni distinte, media da 56 a
86 caratteri; i tre formati dominanti (abbinamento, ordinamento, classificazione)
hanno 207 spiegazioni proprie e l'inglese non ripete più la risposta appena data.
Tenuto da `minigame_explanation_audit` e `bank_explanation_audit`, che non guardano
la lunghezza ma la circolarità e il riuso: *la lunghezza era la metrica sbagliata* —
delle 242 spiegazioni «troppo corte» quasi tutte erano ottime, corte perché precise,
e le difettose erano le 31 circolari.

**La varietà delle prove (5 agosto).** Forme di sessione da **8 a 52**; l'apertura
`abbinamento → ordinamento → classificazione`, che copriva 288 sessioni su 288, ora
ne copre 24. Il formato `ciclo` è passato da una materia a otto. Tre formati nuovi
(retta numerica, bilancia, linea del tempo) e tre strutture nuove — compositore
vincolato (7 specifiche), tracciatore (6), indiziario (6) — tutti a disegno
procedurale. Lo scorrimento ha spostato un guard-rail: la fluency è una proprietà
dell'**argomento** e non della materia (`ContentManager.FLUENCY_TOPICS`), con
`guardrails_audit` a pretendere che nessuna missione sia mai cronometrata.

**Il gate a dodici materie (6 agosto).** Il livello si apre con tutte e dodici, la
copertura si conta **per livello** e non da sempre, l'esame sale a cinque nodi con
tre quarti per passare. Mondo 1 da 18 a **185** esercizi; campagna da 552 (~3 h) a
**2712 (~15 h)**; mondi che costano lavoro da 1 su 24 a **24 su 24**.

**Profili e copia in cloud (6 agosto).** Sei caselle per dispositivo e un codice di
ripristino di otto caratteri (nessun account, nessuna email); Worker in `cloud/`.
Tre regole: il locale è la verità, non si scarica mai da soli, un codice si occupa
solo se è libero. Un profilo non si cancella.

**Il registro dei giocatori (6 agosto).** Classifica d'apertura = **la settimana**
(si recupera da sé), più il viaggio/le cose sapute/i giorni e dodici classifiche di
materia; medaglie invece di «nessuna medaglia». Schede CASA (locale) e GRUPPO (solo
un riepilogo di numeri: mai il salvataggio, mai il codice). Nessuna misura scende
per un'assenza.

**La pratica ripeteva i quesiti (6 agosto).** Da **55% a 20%** di quesiti identici
su dieci giri, fondo per casella da 5–19 a **27–33**, almeno sette giri consecutivi
interamente nuovi. La palestra superata si chiude e la successiva nasce altrove
(`-r1`, `-r2`…). Sotto c'era un difetto strutturale: il ramo che chiude un incontro
era `mission or enigma`, quindi la pratica non veniva mai chiusa e il controllo a
monte leggeva una lista che nessuno riempiva. Tenuto da `practice_variety_audit`.

**Rigiocare da capo, e una misura sbagliata (6 agosto).** L'identità di un quesito
era il suo `prompt`, che nei formati interattivi è una **costante**: tutti gli
abbinamenti risultavano un esercizio solo. Contando il contenuto, il catalogo dà
354–826 nodi distinti a L1 (non 5–16) e gli inediti al secondo viaggio sono il
**91%**, con o senza il tetto che avevo introdotto — rimosso. Lezione: prima di
riparare su un numero, guardare da dove viene quel numero.

**Il catalogo delle ricette (6 agosto).** Ricette al mondo 1 portate a **dieci** per
ogni materia (undici l'italiano), scelte per azioni mentali mancanti: condizioni e
cicli in coding, forze in fisica, diagnosi e sicurezza in elettronica, il metodo in
scienze, le fonti in storia, l'etimologia in latino. Lezione pagata con un rosso: un
serbatoio nuovo si allinea a quelli della materia, altrimenti una ricetta in più
**peggiora** la varietà (musica L1 salita al 23% di ripetizioni).

**Il rango del nucleo (6 agosto).** Italiano, matematica e inglese hanno soglia
0,78 contro 0,70 e un argomento di copertura in più (`ApparatusConfig.CORE_MASTERY_BONUS`,
applicato dentro `GateReadiness.evaluate_subject`); ogni esame porta **due nodi** di
nucleo diversi dalla materia del mondo. Costo misurato: campagna da 20 a **21,1
ore**, +5% contro il +30-40% previsto a occhio.

**La voce di NORA (6 agosto).** Da 12 a **68** battute in tre atti allineati ai
ribaltamenti, carattere dichiarato (si interrompe e si corregge: il tic *è* la
trama) e i ricordi, assenti nel primo atto. Tenuto da `nora_voice_audit`: nessun
pozzo sotto le quattro battute, atti disgiunti, nessuna lode alla persona.

**Oggetti, epiloghi e la svolta severa (6 agosto).** Quattro «upgrade» promettevano
meccaniche del prototipo Phaser che qui non esistono: riscritti, e `endings_audit`
ora vieta a un oggetto di promettere una meccanica inesistente. Tutti i 55 oggetti
hanno una `origine`. `LegacyScore` pesa padronanza/ritenzione/mondo/rotta/indagine e
**non pesa** frammenti, cosmetici, ore né velocità — la prova più importante
dell'audit è che riempire un salvataggio di ricchezza non muova il Lascito di un
centesimo. Epiloghi da sei a **otto**, due severi (IL SILENZIO TIENE, IL CIRCUITO
INCOMPLETO). La padronanza **decade**, misurata in sessioni giocate e non in giorni
reali, con franchigia di dodici sessioni, pavimento a metà del proprio massimo e
nessun decadimento per una materia mai praticata: `decay_audit` misura che duecento
sessioni ignorando geografia richiudono il livello e dodici lo riaprono.

**Complementarità banchi/minigiochi (6 agosto).** I due insiemi di formati sono
perfettamente disgiunti — il banco misura il **sapere**, il catalogo il **fare**. Su
241 etichette di argomento: 45 solo banco, 92 comuni, **104 solo minigioco**.

**Dare senso al girovagare (6–7 agosto).** Gli edifici sono diventati luoghi
interagibili con una funzione per ruolo (casa del mestiere con ingresso a metà
prezzo, Ritrovo con bottega e conversazioni, prima rovina con un frammento di
circuito); la bottega ha il **lavoretto**, l'unica prova del gioco che paga invece
di costare; gli `hazard` sono passati da chiave di salvataggio senza produttore a
meccanica vera; i passaggi che si aprono sono saliti da uno a tre per mondo e, dove
non c'è acqua, la composizione mette uno sbarramento di terra con la stessa
struttura dati — **ogni mondo ha almeno un passaggio da aprire**, sei d'acqua e
diciotto di terra. Lo sbarramento è un segmento, mai un anello: aprirlo è una
scorciatoia, non un permesso. Tenuto da `world_mechanics_audit`.

**La camera sigillata e le ventiquattro pergamene (7 agosto).** L'unica zona
davvero chiusa del gioco, lecita perché dentro non c'è niente che serva a
progredire. Le pergamene sono la voce dei Dodici — testimoniano dove NORA deduce — e
ogni tanto si contraddicono fra loro, che è la stessa lezione di metodo che il gioco
insegna in storia. Tenuto da `parchment_audit`.

**Gli Sbiaditi: guardiani e varco (7 agosto).** Un forziere su tre è difeso, deciso
in modo stabile dall'identificativo, con un tetto di quattro guardiani vivi: la
prima versione ne metteva da otto a quindici in vista insieme, che non è un pericolo
ma un assedio. Il varco è un duello di riflessi le cui tre leve si muovono col grado
di Eli. Tenuto da `reflex_duel_audit`: nessuna combinazione produce un varco sotto
il 5% o sopra il 50% della pista, e perdere non costa mai più di un morso.

**Le minimissioni (7 agosto).** Ventiquattro incarichi che cambiano la mappa in
permanenza, e per direttiva esplicita del committente **sostituiscono** l'ultimo
slot-gate invece di aggiungersi: `time_cost_probe` prima 21,1 ore, dopo 21,1 ore.
Il timer previsto per la forma SPEGNERE non è stato fatto — un cronometro mentre si
legge una domanda misura la velocità di lettura — e il rischio è stato messo negli
errori di chi entra sotto il grado consigliato. Tenuto da `minimission_audit` e
`minimission_scene_audit`.

**Insegnare prima di chiedere (7 agosto).** La mini-lezione leggeva il topic del
**primo nodo** e si fermava lì: misurato su 1440 nodi, il **60,6%** delle domande
arrivava su un argomento mai spiegato in quella sessione, uniformemente su tutte e
dodici le materie. Ora la lezione copre ogni argomento nuovo e viaggia sul nodo:
**0,1%**.

**Elettronica hands-on (7 agosto).** Scelta multipla a zero fuori dall'esame, con
l'audit scritto sui formati e non sulla percentuale, così un `minLevel` spostato non
può far tornare le domande secche da sole.

**«E adesso che faccio?» (7 agosto).** IL PASSO nell'HUD: una frase, una cosa sola
da fare, con dove farla.

**I personaggi cambiano perché tu impari (8 agosto).** Stadio che avanza su ciò che
il bambino impara, osservazione che si legge camminando e una convinzione precisa
per ognuno dei 46 residenti.

**Dieci meccaniche per ventitré mondi (9–12 agosto).** La matrice prometteva 46
meccaniche, una per personaggio: sbagliata due volte — quarantasei a metà valgono
meno di dieci finite, e **le convinzioni non sono quarantasei** (tre personaggi
credono la stessa cosa in tre mestieri). Quindi dieci meccaniche, venticinque
giochi, ventitré mondi coperti; quello che non si ripete mai è il materiale. Tre
meccaniche nuove: la leva (la forza della mano non cresce mai, altrimenti spingere
resterebbe una strategia), la prova controllata, la stima. Quattro difetti trovati
dalle regole nuove, tutti della stessa specie — *la strategia vecchia funzionava*:
la lunghezza latina prediceva il caso, la popolarità prediceva la fonte, la stima si
vinceva a caso ai mondi bassi, il ciclo si vinceva a mano. Nessuno si vedeva
giocando una partita. Suite a **153 verdi**; il ciclo di Ruggine e la traccia di
Sesto sono stati rifatti dopo la valutazione del 12 agosto.

**Le spiegazioni di NORA (12 agosto).** Il difetto più grosso non era di scrittura:
`explanation` compariva **solo sbagliando**, e il gioco è tarato perché il bambino
risponda bene la maggior parte delle volte — 3412 spiegazioni scritte e l'unica
strada per arrivarci aperta solo sull'errore. `NoraExplanations` porta ora il
**perché** (sull'esito giusto) e il **come** (sull'errore) per 135 argomenti invece
che per 3412 item. Quanto NORA aggiunge a ciò che il bambino aveva già sotto gli
occhi: da **zero** a **100%** sulle risposte giuste. Lezione, la stessa dei digrammi:
**un'euristica può scegliere, non giudicare** — la lista di parole-spia è rimasta
dove sceglie ed è sparita da dove dava voti.

**Le undici sorelle e la voce di Eli (13 agosto).** Le sorelle esistevano al mondo
12 e al 24, e in mezzo undici mondi senza la cosa più importante della vita di Eli:
ora sono undici persone, una per mondo dal 13 al 23 (`sisters_thread.gd`), ognuna
bravissima in un solo modo di capire. La distingue il metodo, non il talento — se
fosse talento il gioco direbbe a chi lo gioca che o ce l'hai o non ce l'hai. Eli, che
non aveva **una riga** in tutta la campagna, parla in quattro semi e nel confronto
del mondo 24, dove chiede una regola nuova e NORA risponde «sì» senza attenuare.
Nessuna seconda pipeline di spawn: le tracce passano da quella dei semi.

**L'attrito, le posizioni, lo specchio e il prezzo (13 agosto).** Quattro difetti
dello stesso tipo — il gioco *diceva* una cosa e non la *faceva* succedere a
nessuno: Vera era un'alleata perfetta (cioè una funzione), il giocatore sceglieva
una volta sola in ventiquattro mondi, Meridiana arrivava come una notizia, il
Tredicesimo non costava niente. Aggiunto il caso profondo di `smemora`, una volta
sola in tutta la campagna e non prima del mondo 21: un abitante non dimentica il
nome di Eli, dimentica **il proprio mestiere**, e si ripristina facendo. Tenuto da
`stance_audit` (cinque scelte, nessuna punita, nessuna che prometta energia) e da
`thirteenth_audit` esteso.

## C-ART-5/6 — posizioni che tornano e «smemora» profondo (13 agosto)

- Le quattro posizioni mancanti sono scene, non più sole righe di catalogo:
  domanda ritirata del Tredicesimo al mondo 22; `prova_accettata` di Orsolo;
  fascicolo fisico di Squadra; segnale di Meridiana sui sensori lunghi. Tutte
  passano dal pannello comune, sono saltabili e non toccano gate o ricompense.
- Lo stato distingue incontro, risposta ed eco vista. Un salto chiude il
  momento senza inventare una risposta; una risposta torna una volta sola:
  Orsolo al Cuore, Squadra dopo il confronto NORA/Eli, Meridiana dopo
  l'assegnazione della Cattedra, il Tredicesimo subito prima del proprio nome.
- Nel solo `smemora` eleggibile del mondo 23, una volta per campagna, il
  direttore sceglie un residente non proprietario e mai un Bislacco. Il suo
  dialogo ordinario resta sostituito finché Eli supera una prova della sua
  materia; uscire dal mondo ripristina comunque tutto.
- Il caso profondo è visibile senza parlare: posa e gesto di lavoro restano
  quelli dell'attore, ma l'attrezzo si ripete lungo due archi contrapposti e il
  percorso si interrompe prima di un bersaglio integro. Al ritorno l'anello si
  chiude e collega gesto e oggetto per un istante; movimento ridotto conserva
  una versione statica senza lampeggi.

Verdi `stance_audit`, `c_art_5_6_runtime_audit`,
`c_art_world_staging_audit`, `stance_echo_finale_audit` e
`world_wave_e2_audit`. QA sul renderer reale nella cattura
`artifacts/deep-smemora-c-art-6.png`; sonda riproducibile
`deep_smemora_render_probe.gd`. Export Web completato e sincronizzato come
`2026.08.13-web-loader-8` / cache `v111-web-loader`: PCK 33,60 MiB, WASM
37,68 MiB, core 71,28 MiB; `audit:web` verde. La suite Godot completa è stata
fermata al limite documentato di 150 secondi: tutti gli audit emessi fino allo
stop erano verdi, inclusi i due regressivi `dialogue_audit` ed
`enigma_scene_audit`; il resto del pacchetto C-ART è stato eseguito in modo
mirato e verde.

## C-G4 — resa dei moduli di spedizione (14 agosto 2026)

- `expedition_module_presentation.gd` consuma esclusivamente due numeri del
  contratto runtime. `treasureRadarRadius` mostra un segnale direttamente sopra
  le casse chiuse entro il raggio, senza introdurre una lista HUD;
  `torchRadius` scala un vero cono `PointLight2D`, orientato secondo lo sguardo
  di Eli. Valori assenti o zero tengono entrambe le rese dormienti finché la
  semantica non pubblica i due effetti.
- Il generatore deterministico del `reward-items-sheet` contiene ora cinque
  illustrazioni dedicate: serbatoio, bobina, passo, radar e torcia. L'atlante
  sincronizzato Web/Godot passa a 58 regioni su 1024×1024; i tre moduli già in
  vendita non usano più il cerchio con glifo di ripiego.
- Verde `expedition_module_presentation_audit`: prova valori zero, distanza e
  stato raccolto del radar, equipaggiamento/scala/orientamento del cono, assenza
  di calcoli semantici nella resa e tutte le cinque regioni 128×128. Verdi anche
  le regressioni mirate `expedition_module_audit`, `shop_presentation_audit` e
  `outdoor_presentation_audit`.
