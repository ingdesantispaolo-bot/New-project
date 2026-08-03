# Eli Quest — Piano di lavoro

Aggiornato al 3 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md)

---

## Obiettivo

Portare il percorso Godot alla qualità di consegna: apprendimento, missioni,
mondi abitati, NORA e riattivazione della nave come un unico ciclo leggibile,
accessibile, performante e pubblicabile su desktop, tablet e Web.

**Dove siamo**: la parte didattica è finita e misurata (88 audit verdi, 184 test,
33 milioni di prove distinte, 23 mondi su 24 abitati con 803 battute). La parte
narrativa è a metà. **Nessun bambino ha ancora giocato**, e questo resta il
rischio numero uno: nessun audit lo sostituisce.

---

## Chi fa cosa

| | Codex | Claude | Tu |
|---|---|---|---|
| Runtime Godot, scene, input, resa, integrazione visuale | ✅ | | |
| Strumentazione: audit, cricchetti, misure | ✅ | | |
| Contenuti STEM nelle tabelle di `minigame_manager.gd` | ✅ | | |
| Immagini generate e loro pipeline | ✅ | | |
| Export Web e `public/godot/outdoor` | ✅ | | |
| Contenuti di lingua e umanistiche, banchi, bake | | ✅ | |
| Catalogo abitanti, dialoghi, beat, Tracce | | ✅ | |
| Coerenza didattica, difficoltà, copertura competenze | | ✅ | |
| Revisione incrociata del lavoro dell'altro | ✅ | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | | ✅ |

### Proprietà dei file — vincolo, non suggerimento

| file | proprietario |
|---|---|
| `minigame_manager.gd` · voci STEM (matematica, fisica, elettronica, coding, scienze) | Codex |
| `minigame_manager.gd` · voci di lingua e umanistiche | Claude |
| `*_audit.gd`, `exercise_*.gd`, `*_catalog.gd` visuali, scene, UI | Codex |
| `npc_catalog.gd`, `npc_catalog_audit.gd`, narrativa | Claude |
| `scripts/build-exercise-banks.mjs`, `src/data/procedural/*` — tutte le materie | Claude |
| `godot/data/banks/*.json` — **prodotti del bake, non si scrivono a mano** | nessuno |
| `insieme.md`, `docs/PROFONDITA_CONTENUTI.md` | Claude |

Chi deve toccare il blocco dell'altro **lo chiede qui**.

---

## La regola che ci sblocca: contratto e fixture prima, volume dopo

Quasi tutte le dipendenze vanno in una direzione sola — **il contenuto precede il
runtime**. Se aspetto di aver scritto tutti e ventiquattro i mondi prima di
consegnare un contratto, Codex resta fermo per giorni; è appena successo con A2.

Quindi per ogni sistema io consegno **in tre tempi**:

1. **il contratto** — quali campi, quale regola, cosa decide chi. Poche righe;
2. **la fixture** — il mondo 1 completo, dati veri su cui costruire e provare;
3. **il volume** — gli altri ventitré mondi, che arrivano mentre lui costruisce.

E il runtime **degrada con grazia** dove il contenuto non c'è ancora: un evento
senza proprietario resta giocabile, un dialogo mancante non è un errore. È già
scritto nel documento abitanti e va tenuto per tutto.

### Stato delle dipendenze

| sistema Codex | cosa aspetta da me | stato |
|---|---|---|
| **A1 · Ossatura dialoghi** | forma della battuta (1–3 schermate), ritratto, nome | ✅ pronto |
| **A2 · Proprietà missioni** | regola `ownerNpc` + richiesta/consolazione | ✅ **completo: 46 residenti su 46** |
| **A3 · Edifici** | niente | ✅ pronto |
| **A5 · Vita di mondo** | conversazioni al Ritrovo del mondo 1 | ✅ **consegnate oggi** |
| **P1–P3 · Custode** | mappa segnale → espressione | ✅ pronto (già in `pet_expression_engine.gd`) |
| **A7a · Il Tredicesimo** | le 5 azioni e le sue battute | ⏳ dopo |
| **A7b · Sbiaditi** | niente | ✅ pronto |
| **Cablaggio formati visuali** | niente: i cataloghi sono scritti e validati | ✅ pronto |

**Codex ha sei cose pronte da fare subito**: il cablaggio dei formati visuali,
A1, A2, A3, A5, A7b e tutto il **Custode**. Lunica che ancora mi aspetta è A7a,
il Tredicesimo — ed è la prossima che scrivo.

*(Correzione del 3 agosto: avevo elencato la mappa segnale → espressione fra le
cose che Codex aspettava da me. È già scritta in `pet_expression_engine.gd`, con
il guardrail «nessuna faccia negativa» imposto da `pet_expression_audit`. Il
blocco non c'era: l'avevo messo io nel piano per errore.)*

---

## Coda di Codex

### C1 · Cablaggio dei formati visuali — *pronto, nessuna dipendenza*

I cataloghi `NOTATION` (8 specifiche, musica), `MAP_READING` (3, geografia) e
`HOTSPOT` (4, storia) sono scritti in `minigame_manager.gd` e validati contro i
tuoi validatori (`visual_content_probe.gd`, 15 nodi su 15). Manca il meccanismo:

1. `FORMATS` — aggiungere `"notation"`, `"map"`, `"hotspot"`;
2. `table_for()` — i tre casi;
3. rotazione degli specialisti in `build_minigame`, come per `CYCLE`;
4. costruttori `_notation_node`, `_map_node`, `_hotspot_node` — rimescolano
   l'ordine di presentazione come `_cycle_node` fa con le fasi. **Attenzione**:
   nella notazione la posizione orizzontale la deriva il renderer dall'ordine
   dell'array, quindi il primo simbolo non deve diventare sistematicamente la
   risposta;
5. `spec_depth()` — per questi tre vale 1, come grafico e circuito. Non gonfiarla.

Poi `visual_content_probe.gd` è pronto per diventare un audit: fa già `quit(1)`.

**Cosa manca ai cataloghi, e dipende da te**: la carta muta ha **tre** bersagli
(`po`, `sicily`, `sardinia`) e l'atlante dei reperti **quattro**. Con tre bersagli
le domande possibili sono tre. Servono appennini, alpi, tirreno, adriatico,
tevere — e poi una carta d'Europa; e un secondo foglio di reperti, greco o egizio.

### C2 · A1 · Ossatura dei dialoghi — *pronto*

`dialogue_box.gd` (ritratto, nome, 1–3 righe, area di gioco visibile,
avanzamento a tocco su tutta la schermata, macchina da scrivere con completamento
al primo tocco e **disattivata con riduzione movimento**, nessun dialogo a tempo)
e `npc_actor.gd` (presenza, area d'interazione, animazione di occupazione).

Dati pronti: 46 residenti e 23 Bislacchi in `npc_catalog.gd`, con `registro`,
`tic`, `arco` a 3 stadi e i pool di battute già raggruppati come li chiede
`DialogueDirector` (§5.2 del documento abitanti).

### C3 · A2 · Proprietà delle missioni — *sbloccato*

`NpcCatalog.owner_for(world, kind)` risponde per tutti e 23 i mondi abitati:

- **missione** → lo specialista, perché il problema del mondo è il suo;
- **enigma** → il testimone, che «sa senza sapere di sapere e indica la Rovina»;
- **pratica** → nessuno: è di chi passa di lì, cioè dell'itinerante.

È una **regola**, non una lista: gli eventi li pianifichi con un seme diverso a
ogni partita, e una lista sarebbe falsa al secondo seme.

`NpcCatalog.mission_lines(id, "richiesta" | "consolazione")` dà le battute.
**Pronti tutti e 46 i residenti**: `a2_ready()` risponde 46 su 46, e l'audit lo
stampa a ogni giro. Il fallback muto resta nel codice — serve agli itineranti,
che non hanno ancora battute — ma per i residenti non scatta più.

**Vincolo di scrittura**: `consolazione` non contiene mai una battuta di
delusione. Sessione fallita = «riproviamo insieme», mai «peccato».

### C4 · A3 · Edifici — *pronto*

`building_catalog.gd`: i 3 ruoli (Casa del mestiere · Ritrovo · Rovina dei
Primi) vestiti per `artKit`, finestre che si accendono per stadio del mondo,
Rovina allineata al landmark eroe di `_hero_landmark_position()`. Riuso di
`build_academy_pavilion()`.

### C5 · A7b · Sbiaditi — *pronto*

Re-theme di `world_enemy.gd`: comportamento e resa degli Sbiaditi.

### C6 · A5 · Vita di mondo — *pronto*

Routine a tre ancoraggi guidate dalla fase giorno/notte, spostamenti fuori
inquadratura, regia delle conversazioni al Ritrovo.

`RitrovoCatalog.scene_for(world, stadio)` dà la scena;
`RitrovoCatalog.lines_of(id, con_notizia)` dà le battute nell'ordine, con quella
che cita il giocatore già sostituita al posto giusto quando c'è una notizia in
coda. Mondo 1 completo (stadi 0, 1, 2). Dove una scena manca, il Ritrovo resta un
luogo normale: nessun errore.

**Tre regole di regia che il catalogo dà per scontate e la scena deve rispettare:**

- **non si interrompono quando arrivi.** Il congedo è una battuta a parte, e va
  detto *alla fine*: essere visti dopo è ciò che fa sembrare che vivessero anche
  senza di te. Se ti salutano subito, stavano aspettando te;
- **non bloccano il movimento** e si può andare via a metà;
- la battuta di notizia **non si rivolge mai al giocatore** — parla di lui in
  terza persona. L'audit lo verifica cercando i «tu» diretti.

### C7 · P1–P7 · Custode — *pronto*

La mappa segnale → espressione è già in `pet_expression_engine.gd`: 18 segnali,
nessun buco, e `NEGATIVE_FACES` **vuota per costruzione** — ogni errore,
fallimento e scudo perso mappa su `incoraggiante`. È il guardrail più importante
del compagno: vedere il proprio Custode deluso dopo una risposta sbagliata è
vergogna, e la vergogna spegne l'apprendimento.


`pet_face_widget.gd` sempre visibile (carezza al tocco breve, schermata al tocco
lungo), `pet_expression_engine.gd`, `pet_antics.gd`, poi nome, livrea, indole,
volto a riposo, album, combinelle, regali.

**Le 10 espressioni devono essere distinguibili per forma, non solo per colore.**
Nessuna combinella durante sessione, esame o beat, con la sola eccezione dello
starnuto autorato.

### C8 · Contenuti STEM ancora aperti

- **banda 4 dei banchi STEM**: elettronica ha 9 item a difficoltà 4 su tre
  argomenti, fisica 8 su sei. I mondi 19–24 sono un quarto della campagna;
- **coding è al 17% di ripetizioni al primo mondo**, cioè esattamente sul
  cricchetto `MAX_REPEAT_SHARE`. Verde, ma senza un millimetro di margine: la
  prossima modifica a coding fa rosso l'audit anche senza peggiorare nulla;
- **`52 − 18`**, in `minigame_manager.gd`, caccia all'errore di matematica: il
  passaggio marcato sbagliato è `(50 − 10) + (2 − 8)`, che fa **34** ed è
  corretto. La prova chiede di trovare un errore che non c'è, e la spiegazione
  dice «non si può fare 2 − 8», che è falso. Proposta: `(50 − 10) + (8 − 2)`, che
  dà 46 ed è l'errore che i bambini fanno davvero;
- **ri-scaglionare i `minLevel` STEM** dove sono tarati male — ma *spostare in
  avanti contenuto esistente non è contenuto nuovo*: impoverisce i mondi bassi.
  Va misurato prima e dopo su entrambi gli estremi.

### C9 · Accessibilità dei formati visuali — *da decidere insieme*

Le etichette dei bersagli identificano senza descrivere («Segnaposto A», «Primo
reperto da sinistra»), come già fanno i grafici con «A, B, C»: è l'unica scelta
che non regala la risposta. Ma vuol dire che **chi usa un lettore di schermo non
può rispondere a una carta muta**. Vale già per grafici e circuiti; ora riguarda
tre formati in più. Va deciso, non subìto.

---

## Coda di Claude

Ordinata per **quanto sblocca**, non per dimensione.

### O1 · Il Tredicesimo — *sblocca A7a*

Le 5 azioni (scrive, cancella, aspetta, avverte, supplica) e le sue battute.
**Non minaccia mai Eli**: chiede, avverte, supplica. E il suo nome è nella conta
di nonna Ersilia, già scritta: «sca · la · re» sono «Scala, re-», cioè il nome
più l'inizio di «resta».

### O2 · I sei itineranti

Il cast fisso, quello a cui ci si affeziona: rotazione deterministica da seme +
livello, una funzione di gioco e un registro distinto ciascuno. **Da fare dopo
che avrai giocato il mondo 1**: sono i personaggi che si incontrano più spesso di
tutti, e se il ritmo dei dialoghi va corretto conviene correggerlo prima di
scriverne altri sei.

### O3 · I 24 beat + beat finale, le 24 Tracce, i semi dei sette colpi

I semi vanno collocati nei mondi *precedenti* al colpo. Tre per colpo, minimo.

### O4 · Le 12 inflessioni dei Maestri, «Rispiegamelo» di Vera, Secondo Viaggio

Terne di spiegazioni per topic (mirata / analogia / dal principio) e il contratto
dei ragionamenti a passi con posizione dell'errore variabile.

### O5 · Le 69 conversazioni al Ritrovo restanti

---

## Coda tua

1. **Giocare il mondo 1** appena Codex ha cablato A1+A2 ed esportato. È la cosa
   che sblocca più decisioni di qualunque altra: 803 battute sono scritte su una
   formula che nessuno ha ancora provato.
2. **Profilare su hardware scolastico/tablet reale** e confermare i budget.
3. **Provare su tablet reale**: touch, viewport landscape e portrait, contrasto
   elevato, riduzione movimento.
4. **Approvare il release candidate** quando 1–3 sono verdi.

---

## Invarianti di architettura

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta o beat è
  scritto dentro una scena: tutto viene dal catalogo.
- **I dati non decidono la resa** (niente posizioni sullo schermo nei cataloghi)
  **e la resa non decide i dati** (nessuna scena inventa registri o proprietari).
- **Nessuna immagine contiene testo**: non è traducibile, non è leggibile ad alto
  contrasto e non si corregge senza rigenerarla.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun abitante scrive mastery, energia, gate o ricompense.
- **Prima il contenuto, poi il cricchetto.** Stringere una soglia prima di aver
  scritto il contenuto obbliga a scrivere contenuto per far passare un test.
  All'inverso: **nessun cricchetto si allenta mai.**

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tre materie** (italiano, matematica, inglese), **si
   finisce il gioco con dodici**. Il gate è sulla padronanza, non sul conteggio
   delle missioni.
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha missioni di tutte le
   materie già incontrate.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%** (oggi 17%).
7. **Gli stadi di relazione avanzano su ciò che Eli impara**, mai su oggetti o
   valuta. Lo stadio 2 non richiede l'esame.
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario
   (≥2 specifiche per materia/formato/livello), nuovo a ogni livello, fedele al
   registro della materia. Cinque criteri su sette hanno un cricchetto; «vero» e
   «alla portata» li può verificare solo una rilettura umana.

---

## Vincoli

- Nessun nuovo banco composto quasi solo da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
- Nessuna ulteriore profondità combinatoria: 33 milioni bastano.
- Le spiegazioni del **lessico** (inglese, italiano) restano come sono: lì
  rivedere l'accoppiata *è* il ripasso.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. Si chiude solo
   con la prova sul campo.
2. **L'export invecchia più in fretta del codice.** `public/godot/outdoor/`
   contiene ancora la build di stamattina: nulla del 3 agosto è giocabile.
3. **Il mondo 1 è già stretto sui budget**: 2667/3500 nodi e 468/500 ms, ed è
   quello a cui stiamo per aggiungere abitanti ed edifici. Le tappe **contano** i
   nodi prima di aggiungerli.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: il 3 agosto la suite intera è passata da **105 a 1295 secondi**
   — dodici volte — con sei audit rossi, e un singolo audit che dura due secondi
   ne ha impiegati oltre quattrocento. Quattro processi Godot in esecuzione
   contemporanea, tre non miei.

   I rossi erano tutti in audit che caricano scene (`boot_navigation`,
   `enigma_scene`, `completed_event_visual`, `roundtrip`) e nessuno toccava le
   cose cambiate. Erano contesa, non regressioni.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma: sta misurando
   il carico della macchina, non il codice. Un audit singolo si può sempre
   eseguire — è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni tappa

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
stai giudicando la build precedente.
