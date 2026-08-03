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

**Dove siamo**: la parte didattica è finita e misurata (184 test, 33 milioni di
prove distinte). Da oggi anche **la parte narrativa è scritta per intero**: 23
mondi abitati, 46 residenti e 23 Bislacchi con oltre 1000 battute, 69
conversazioni al Ritrovo, 6 itineranti, 24 Tracce, 28 semi, 24 beat, il
Tredicesimo e le 12 voci dei Maestri. Manca **tutto il cablaggio**, e manca la
cosa che conta di più: **nessun bambino ha ancora giocato**. Nessun audit lo
sostituisce.

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
| **A4 · Itineranti** | i 6 personaggi, la rotazione, «rispiegamelo» | ✅ **consegnato** |
| **A5 · Vita di mondo** | conversazioni al Ritrovo | ✅ **69 scene, tutti i mondi abitati** |
| **P1–P3 · Custode** | mappa segnale → espressione | ✅ pronto (già in `pet_expression_engine.gd`) |
| **A7a · Il Tredicesimo** | le 5 azioni e le sue battute | ✅ **consegnato** |
| **A7b · Sbiaditi** | niente | ✅ pronto |
| **A7 · Mistero e finale** | 24 Tracce, semi dei 7 colpi, 24 beat | ✅ **consegnato** |
| **Voci dei Maestri in NORA** | le 12 inflessioni | ✅ **consegnato** |
| **Cablaggio formati visuali** | niente: i cataloghi sono scritti e validati | ✅ pronto |

**Nessun sistema di Codex aspetta più contenuto da me, e il volume è finito.**
Le 66 conversazioni al Ritrovo mancanti e i sei itineranti sono scritti: i passi
1–6 del giro dei mondi qui sotto sono completi per tutti i mondi abitati. Quello
che resta è tutto runtime.

*(Correzione del 3 agosto: avevo elencato la mappa segnale → espressione fra le
cose che Codex aspettava da me. È già scritta in `pet_expression_engine.gd`, con
il guardrail «nessuna faccia negativa» imposto da `pet_expression_audit`. Il
blocco non c'era: l'avevo messo io nel piano per errore.)*

---

## Il giro dei mondi — come si fa un mondo, passo passo

Ventiquattro mondi non si fanno «tutti insieme»: si fa **un mondo intero**, lo si
gioca, e poi si fa il successivo con quello che si è imparato. Il rischio da
evitare è quello che abbiamo già corso una volta: scrivere ottocento battute su
una formula che nessuno ha ancora provato.

**Undici passi, e chi li fa.** Un mondo è finito quando li ha fatti tutti:

| # | Passo | Chi | Fatto per quanti mondi |
|---|---|---|---|
| 1 | Cast: specialista + testimone + Bislacco, con registro, tic, convinzione, arco | Claude | **23 / 23** |
| 2 | Le 15 battute per residente (3 per stadio, 3 reazione, 3 riempimento) | Claude | **23 / 23** |
| 3 | Richiesta e consolazione (flusso missioni A2) | Claude | **23 / 23** |
| 4 | Traccia della Rovina + semi dei colpi che passano di lì | Claude | **24 / 24** |
| 5 | Le 3 conversazioni al Ritrovo (stadio 0, 1, 2) | Claude | **23 / 23** |
| 6 | Beat del mondo | Claude | **24 / 24** |
| 7 | Edifici vestiti per `artKit`, finestre per stadio, Rovina sul landmark eroe | Codex | 0 / 24 |
| 8 | Routine di vita a tre ancoraggi + regia delle conversazioni | Codex | 0 / 24 |
| 9 | Collocazione fisica di Traccia e semi: fuori da `safeRadius`, mai sulla `safeRoute`, mai in acqua | Codex | 0 / 24 |
| 10 | Immagini del mondo e loro pipeline | Codex | dipende dal kit |
| 11 | Verifica: audit verdi + un playthrough di quel mondo | entrambi | — |

I passi 1–6 sono **contenuto** e non dipendono da niente: li scrivo io e li
consegno a lotti. I passi 7–10 sono **runtime** e dipendono solo dal passo
corrispondente, non dall'intero lotto: Codex può vestire il mondo 2 mentre io
scrivo il Ritrovo del mondo 5.

### L'ordine dei lotti

Non in ordine di numero: **in ordine di quanto insegnano**.

| Lotto | Mondi | Perché questi, e in questo momento |
|---|---|---|
| **L0** | 1 | Già completo lato contenuto. **Va giocato prima di tutto il resto**: è la fixture su cui è tarato tutto |
| **L1** | 2, 3, 4 | I primi tre dopo la fixture. Se il ritmo dei dialoghi è sbagliato, si scopre qui e si corregge su quattro mondi, non su ventiquattro |
| **L2** | 5, 8 | I due mondi con un colpo di scena in Atto I. Provano la parte più delicata: che una Traccia regga il peso di una rivelazione |
| **L3** | 6, 7, 9, 10, 11 | Il resto dell'Atto I e l'inizio del II, a regime |
| **L4** | 12, 16 | I due colpi dell'Atto II, incluso quello di metà campagna |
| **L5** | 13, 14, 15 | Il resto dell'Atto II |
| **L6** | 17, 18, 19, 20 | Entra in scena il Tredicesimo: prima volta che un'azione narrativa tocca un mondo già restaurato |
| **L7** | 21, 22, 23 | La discesa verso il colpo 6 |
| **L8** | 24 | Il Cuore: convergenza, nodo di sintesi, finale. Si fa per ultimo perché usa tutto |

**Regola del lotto**: non si apre il lotto successivo finché quello in corso non
ha i suoi audit verdi *e* qualcuno non l'ha giocato. Un lotto è piccolo apposta —
tre o quattro mondi si giocano in una sera.

### Definizione di «mondo finito»

Undici passi fatti, e queste cinque cose vere:

1. i due residenti hanno stadio 0, 1 e 2 **distinti**, e allo stadio 2 uno dei
   due insegna qualcosa all'altro;
2. c'è **almeno un personaggio che fa ridere** (il Bislacco basta), e nessuna
   battuta comica ha come bersaglio il giocatore;
3. la Traccia si legge in ≤3 schermate e **non è raccontata da nessuno**;
4. il Ritrovo ha le tre conversazioni, e in nessuna qualcuno parla due volte di
   fila o saluta Eli prima della fine;
5. il mondo è giocabile **anche saltando ogni dialogo**.

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

**69 scene: tutti e 23 i mondi abitati hanno i tre stadi.** Il mondo 24 non ne ha
di suo — al Cuore convergono gli itineranti e i residenti portati allo stadio 2,
ed è una scena di finale, non di Ritrovo.

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

### C8 · A7a · Il Tredicesimo — *sbloccato*

`thirteenth_catalog.gd`: le **5 azioni** con il costo dichiarato e il ripristino
(`scrive`, `risbiadisce`, `smemora`, `chiude`, `parla`), **17 battute** dal mondo
18 al 24, la scena della restituzione del nome e le **due uscite**, nessuna delle
quali è punita. `thirteenth_audit.gd` è verde e verifica ciò che serve davvero:
nessuna minaccia al giocatore, nessuna azione irreversibile, nessuna formula di
morte, e che il nome esca **davvero** dalla conta del mondo 1 — il controllo
confronta `ThirteenthCatalog.SILLABE` con `NpcCatalog.CONTA_ERSILIA`, così il
finale non poggia su una coincidenza scritta in due file che nessuno confronta.

Quello che manca è tuo: `thirteenth.gd`, cioè **quando** le azioni scattano e
come si vedono. Due vincoli che il catalogo dà per scontati:

- `smemora` non tocca mai il proprietario di una missione in corso, e mai due
  volte lo stesso abitante;
- `chiude` non può mai essere l'unica strada: il percorso alternativo esiste
  sempre, e la porta si riapre al livello dopo.

### C9 · A7 · Mistero, Tracce e beat — *sbloccato*

`mystery_catalog.gd`: i **7 colpi**, **28 semi** (quattro per colpo, tutti in
mondi precedenti e mai tutti dello stesso tipo) e le **24 Tracce**, una per
Rovina. `narrative_manager.gd` ha i 24 beat nuovi e il beat finale — **contratto
invariato**, `beat_for_level` non si accorge di niente.

`mystery_audit.gd` è verde e verifica i semi, l'ordine dei colpi, il limite delle
schermate e che **nessun testo dica che qualcuno è morto** (§10.1) — con le
negazioni gestite, perché «nessuno è morto qui» è una frase che il gioco *deve*
poter dire.

Tuo: la **collocazione fisica** delle Tracce e dei semi (passo 9 del giro dei
mondi). L'audit del testo non può controllarla — serve `world_life_audit`, che ha
le posizioni.

Le **tre Tracce decisive** (mondi 12, 16, 19) hanno un beat di ripiego: chi non
entra in nessuna Rovina capisce il finale lo stesso. Va cablato, altrimenti la
Rovina diventa obbligatoria e viola §10.2.

### C10 · Le dodici voci di NORA — *sbloccato*

`maestri_catalog.gd`: 12 Maestri, una materia ciascuno, e per ognuno le battute
di **apertura**, **rilancio** e **chiusura** — 12 × 8. Il rilancio è il gruppo
che conta: è cosa dice NORA *al posto* della risposta, ed è diverso per materia
perché non si rilancia in matematica come si rilancia in storia.

`MaestriCatalog.voices_for(apparati_riparati, nome_restituito)` risponde **11
prima** della restituzione del nome e **12 dopo**: il buco della logica è nel
codice, non solo nel documento.

`teaching_catalog.gd` porta i due contratti dello spiegare: «Rispiegamelo» di
Vera (3 opzioni, 1 giusta, **ricompensa sociale e zero energia**) e la Diagnosi
del Secondo Viaggio (4 opzioni, nessuna punita, «dille la risposta» sempre
disponibile). E `TeachingCatalog.error_step()`, che colloca il passo sbagliato:
misurato dall'audit, esce **33/33/33** su tre passi e **25/25/25/25** su quattro,
e non si ripete mai fra due tentativi consecutivi sullo stesso argomento.

### C10b · A4 · Itineranti — *sbloccato*

`itinerant_catalog.gd`: i sei personaggi ricorrenti, sei registri diversi e sei
funzioni di gioco, **82 battute**, e la rotazione in
`ItinerantCatalog.itinerant_for(seme, livello)`.

La rotazione è un **mescolamento a blocchi di sei**, non una progressione:
l'audit misura 5 semi × 24 mondi e verifica che compaiano tutti e sei, che
nessuno esca meno di tre volte e che **non se ne ripeta uno due mondi di fila**.
Ci ero arrivato prima con un passo moltiplicativo ed era sbagliato — con sei
elementi un passo di 3 percorre due sole facce su ventiquattro mondi. L'ha visto
l'audit, che misura invece di credere.

Vera è quella che ti serve per prima: la sua meccanica «rispiegamelo» ha il
contratto in `teaching_catalog.gd` e le battute (richiesta, capito, non capito)
nel catalogo. **Il non-capito non contiene mai una delusione**, come le
consolazioni dei residenti.

### C11 · Contenuti STEM ancora aperti

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

### C12 · Accessibilità dei formati visuali — *da decidere insieme*

Le etichette dei bersagli identificano senza descrivere («Segnaposto A», «Primo
reperto da sinistra»), come già fanno i grafici con «A, B, C»: è l'unica scelta
che non regala la risposta. Ma vuol dire che **chi usa un lettore di schermo non
può rispondere a una carta muta**. Vale già per grafici e circuiti; ora riguarda
tre formati in più. Va deciso, non subìto.

---

## Coda di Claude

**È vuota, e questo è il punto.** Non c'è più niente che Codex debba aspettare da
me: tutti i cataloghi di contenuto sono scritti, hanno un'API e un audit verde
che li tiene. Da qui in poi il mio lavoro è **reagire** — al playtest, alle
revisioni, ai buchi che si vedranno cablando.

### O1 · Reagire al playtest del mondo 1 — *aspetta te*

È l'unica voce che conta finché qualcuno non gioca. Ottocento battute e settanta
conversazioni sono scritte su una formula che nessun bambino ha ancora provato:
se il ritmo è sbagliato, si corregge **prima** che qualcosa venga vestito, non
dopo. Quando avrai giocato, la lista di cosa riscrivere la faccio in un'ora.

### O2 · Contenuti dei formati visuali — *aspetta una decisione, non me*

La carta muta ha tre bersagli e l'atlante dei reperti quattro: sono i due
cataloghi più poveri che esistano nel gioco. Servono appennini, alpi, tirreno,
adriatico, tevere, una carta d'Europa e un secondo foglio di reperti. **Li scrivo
appena C1 è cablato**: prima sarebbe contenuto che nessuno può vedere.

### O3 · Revisione incrociata del lavoro di Codex

Quando A1–A7 sono cablati, rileggo i dialoghi *in scena* invece che in tabella.
Un catalogo verde e una conversazione che funziona non sono la stessa cosa, e la
differenza si vede solo a schermo.

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
