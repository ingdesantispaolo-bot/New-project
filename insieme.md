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

## L'obiettivo: il collaudo

**Il gioco è costruito.** Contenuti, narrativa e cablaggio sono fatti e misurati:
2321 item nei banchi, 123 specifiche di minigioco, 24 mondi con cast, Tracce,
beat e conversazioni, sette colpi di scena con 35 semi, e **104 audit verdi**.

Quello che manca non si scrive: **si gioca.** Nessun bambino ha mai provato
niente di tutto questo, e nessuna delle misure qui dentro dice se è bello.

**Il prossimo passo è tuo**: esportare e giocare. Cosa guardare, in ordine di
quanto cambia il lavoro dopo, sta in «Coda tua» più sotto.

Le schede che seguono restano perché servono a due cose: verificare mondo per
mondo che quello che è cablato sia quello che era scritto, e riprendere in mano
un mondo quando il collaudo lo boccia.

---

## Le schede — L1, mondi 1–6

Tutto il contenuto delle colonne «cast», «Traccia» e «semi» è già scritto e
verde. Le schede servono a Codex per sapere **cosa va collocato dove**. I mondi
7–24 hanno la loro tabella più sotto, con lo stesso significato.

### Mondo 1 · Radura Accademia · matematica
- `artKit` **natura-rovine** · landmark **obelisco-dei-numeri**
- Cast: **Tobia** (specialista, burbero, «…e uno») · **Nonna Ersilia**
  (testimone, caloroso, «cuore») · Bislacco **Puccio**
- Traccia: **bastone da conteggio**, tacche a gruppi di dieci
- Semi da collocare: **1** — colpo 1, oggetto: la spirale piccola sul fianco del
  bastone, incisa dopo le tacche e con i bordi netti
- Da non sbagliare: la **conta di nonna Ersilia** va sentita nei primi cinque
  minuti. È la tabellina del 7 e contiene il nome del Tredicesimo. Se il
  giocatore la salta, al mondo 24 non ha la chiave in mano.

### Mondo 2 · Archivio delle Parole · italiano
- `artKit` **carta-e-foglie** · landmark **ponte-delle-frasi**
- Cast: **Corinna** (specialista, solenne, misura con le dita) · **Bruno**
  (testimone, curioso, «e questa come la chiami?») · Bislacco **Ditino**
- Traccia: **catalogo dei Primi**, ordinato per funzione e non per forma
- Semi da collocare: **3** — colpo 1 (dialogo di Bruno sul «ricciolo» che non si
  cancella) · colpo 2 (oggetto: il catalogo ha 13 sezioni e 11 intestazioni) ·
  colpo 6 (dettaglio: la spirale più vecchia è incisa **all'altezza di una
  bambina in piedi**)
- Il seme del colpo 6 è il più lontano di tutti: paga al mondo 23. Va messo dove
  si vede senza essere indicato.

### Mondo 3 · Cratere Logico · coding
- `artKit` **macchine-e-loop** · landmark **macchina-a-cicli**
- Cast: **Ruggine** (specialista, burbero, soffia sugli attrezzi) · **Sesto**
  (testimone, buffo, si ripresenta ogni volta) · Bislacco **Manetta**
- Traccia: **schema di telaio** — «ripetere non è fatica, è un'istruzione»
- Semi da collocare: **2** — colpo 1 (dettaglio: qualcuno ha soffiato via la
  polvere da una pietra) · colpo 2 (dialogo: Sesto si presenta come «il
  dodicesimo» e non sa spiegare perché)
- Sesto è anche **itinerante**: qui torna sé stesso e da qui in poi lo si
  incontra ovunque. È l'unico personaggio che sta nei due cataloghi
  (`w03-sesto` e `itin-sesto`).

### Mondo 4 · Baia dei Segnali · inglese
- `artKit` **segnali-e-onde** · landmark **faro-dei-messaggi**
- Cast: **Marea** (specialista, sognante, sussurra prima di parlare) ·
  **Vecchio Lino** (testimone, divertente, «captain») · Bislacco **Boa**
- Traccia: **quaderno bilingue**, la stessa lezione su due colonne che non si
  corrispondono riga per riga
- Semi da collocare: **1** — colpo 1, oggetto: sulla boa grande, sotto la
  ruggine, un ricciolo che il sale non ha ancora mangiato

### Mondo 5 · Officine del Moto · fisica — ⟡ **colpo 1**
- `artKit` **leve-e-carrelli** · landmark **grande-leva**
- Cast: **Gerbo** (specialista, burbero, si sputa sulle mani) · **Tilla**
  (testimone, curioso, «te lo faccio vedere?») · Bislacco **Peso**
- Traccia: **la spirale aperta**, e il taglio è fresco di settimane
- Semi da collocare: nessuno. Qui si **incassa**.
- È il mondo che prova la cosa più delicata di tutte: che una Traccia letta in
  silenzio regga il peso di una rivelazione. Se il colpo 1 non funziona, non
  funzionerà nessuno dei sette, e conviene saperlo adesso.

### Mondo 6 · Giardino della Risonanza · musica
- `artKit` **cristalli-vibranti** · landmark **albero-risonante**
- Cast: **Ambra** (specialista, sognante, canticchia le risposte) · **Oreste**
  (testimone, solenne, sordo, legge con le mani sulle corde) · Bislacco
  **Zufolo**
- Traccia: **diapason dei Primi** — «un suono con un nome si può regalare»
- Semi da collocare: **3** — colpo 2 (oggetto: rastrelliera con 13 sedi, 11
  occupate, una vuota e pulita, una vuota e impolverata) · colpo 3 (dettaglio:
  NORA dice dove tenevano il diapason, in un mondo che dichiara di non aver mai
  visto) · colpo 7 (dettaglio: NORA ricorda **una lezione e non un dato**)
- **Oreste è sordo**: non reagisce ai suoni, reagisce alle vibrazioni e a chi
  gli entra nel campo visivo. Se la regia lo fa girare al richiamo vocale, il
  personaggio è smontato.

---

## Le schede — L2…L5, mondi 7–24

Stesse colonne. Il **tic** fra parentesi è la stringa che l'audit cerca: se una
battuta in scena non la contiene, il personaggio suona come un narratore.

| # · mondo · materia | `artKit` · landmark | cast (specialista / testimone / bislacco) | Traccia | semi |
|---|---|---|---|---|
| **7 · Rovine dei Glifi · latino** | `pietra-e-iscrizioni` · arco-dei-glifi | Livia (inchiostro) / Zeno (parente) / Postilla | Dizionario delle radici | 1 · colpo 2, dettaglio |
| **8 · Delta dei Circuiti · elettronica** ⟡ | `generatori-e-cavi` · nodo-centrale | Ciro (nodi) / Doria (acqua) / Scintilla | **Sigillo d'equipaggio** | — |
| **9 · Arcipelago · geografia** | `mappe-e-quote` · torre-cartografica | Alma (matita) / Remo (rotta) / Bora | Carta della rotta | 3 · colpi 3, 4, 6 |
| **10 · Serra delle Simbiosi · scienze** | `flora-e-fauna` · cupola-vivente | Ortensia (piante) / Mirta (tisana) / Terriccio | La dispensa in ordine | 2 · colpi 3, 7 |
| **11 · Soglia del Tempo · storia** | `reperti-e-prime-civiltà` · portale-delle-epoche | Danio (scommett) / Vesta (cronac) / Anticaglia | Due datazioni discordanti | 2 · colpi 3, 5 |
| **12 · Labirinto delle Regole · logica** ⟡ | `muri-mobili` · cuore-del-labirinto | Quinto (passi) / Isa (e se invece) / Svolta | **Le schede delle unità** — *decisiva* | — |
| **13 · Deserto delle Orbite · matematica** | `strumenti-astrali` · osservatorio | Solano (lenti) / Duna (mano tesa) / Miraggio | Registro di manutenzione | 2 · colpi 4, 7 |
| **14 · Biblioteca delle Voci · italiano** | `libri-e-eco` · sala-delle-voci | Elmo (taglia l'aria) / Ottavia ((cambia voce)) / Prefazio | I verbali della seduta | 2 · colpi 4, 5 |
| **15 · Città Macchina · coding** | `automi-e-cavi` · torre-di-controllo | Gru (colpetto) / Pila (quando è successo) / Ronzino | Le sezioni della nave | 1 · colpo 4 |
| **16 · Frontiera delle Lingue · inglese** ⟡ | `insegne-multilingua` · porta-delle-lingue | Talia (scus) / Marco dei Valichi (lingue) / Tuttolingue | **La mappa vera** — *decisiva* | — |
| **17 · Oceano delle Forze · fisica** | `pressione-e-flussi` · cattedrale-sottomarina | Nerea (fiato) / Coral (numer) / Scafandro | Le insegne del molo | 1 · colpo 5 |
| **18 · Cattedrale del Suono · musica** | `canne-e-archi` · grande-organo | Silo (riverbero) / Bea (navata) / Controcanto | Il turno di guardia | 1 · colpo 5 |
| **19 · Necropoli delle Radici · latino** ⟡ | `epigrafi-e-radici` · albero-delle-radici | Numa (lapid) / Fiorina (chiamo) / Lapidario | **Il progetto di NORA** — *decisiva* | — |
| **20 · Tempesta EM · elettronica** ⟡ | `sensori-e-scariche` · torre-di-campo | Sferza (nocche) / Quieto (second) / Parafulmine | Le misure della quarantena | — |
| **21 · Atlante Fratturato · geografia** | `strati-e-climi` · pilastro-tettonico | Terza (fogli) / Mino (formaggio) / Meteora | La tesi per esteso | 1 · colpo 6 |
| **22 · Biosfera Profonda · scienze** | `cellule-e-energia` · nucleo-vivente | Vesca (annus) / Fondo (guarda) / Muffa | La domanda mai risposta | 2 · colpi 6, 7 |
| **23 · Sala delle Ere · storia** ⟡ | `mosaici-manoscritti-e-fonti` · archivio-delle-ere | Cronia (timbr) / Ovidio (carte) / Errata | **Il registro del mondo 2** | — |
| **24 · Cuore dei Primi · trasversale** ⟡ | `sintesi-di-tutti` · cuore-dei-primi | *nessun residente* — vedi «Il mondo 24» | Gli undici quaderni | — |

⟡ = il mondo porta un colpo di scena.

### Le trappole, mondo per mondo

Solo dove ce n'è una. Sono le cose che si sbagliano cablando, non scrivendo.

- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Se la resa non mostra la direzione dei graffi, il colpo 2 perde metà
  del suo significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Provviste sigillate, appunti impilati, un posto in più
  apparecchiato. Non è una scena di abbandono: è una scena di preparazione.
- **11 · le due datazioni**: nessuna delle due va bruciata, e la resa non deve
  suggerire quale sia «quella giusta».
- **12, 16, 19 · Tracce decisive**: hanno un `ripiego` in `MysteryCatalog`, ed è
  **obbligatorio cablarlo**. Senza, entrare nella Rovina diventa necessario per
  capire il finale, e questo viola il guard-rail «niente blocca il loop».
- **14 · i verbali**: dove dovrebbe esserci il nome della tredicesima voce c'è un
  **buco nella carta**, non una cancellatura. Va reso come un'assenza fisica.
- **17 · le insegne**: è la **prima azione del Tredicesimo** in tutto il gioco
  (`scrive`, poi `risbiadisce`). Una parola sola, ripetuta su ogni insegna
  dell'area, e sparisce uscendo. Nessun effetto sul gioco: costo zero.
- **18 · la voce**: prima volta che il Tredicesimo **parla**. Nessun ritratto,
  nessun corpo. Stanca, mai minacciosa.
- **19 · `chiude`**: la terza azione entra qui. Una porta della nave sigillata per
  un livello, e **deve esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.

### Il mondo 24 · Cuore dei Primi

Non ha residenti suoi: al Cuore convergono **i sei itineranti** e i residenti che
il giocatore ha portato allo stadio 2, **massimo quattro in scena per volta**.

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` risponde con chi è in scena e
`waves_needed()` con quante ondate servono. Contenuto pronto: **una battuta per
ognuno dei 46 residenti** — e ognuna dice cosa quel personaggio ha smesso di
credere, non un saluto — più le sei degli itineranti.

Due vincoli, verificati da `finale_content_audit`:

- **il Cuore non è mai vuoto.** Con zero residenti allo stadio 2 ci sono comunque
  i sei itineranti. Un finale che premia con la solitudine chi ha giocato in un
  altro modo è una punizione travestita da conseguenza;
- **nessuna battuta nomina chi non è venuto.** Gli assenti non si nominano.

`FinaleCatalog.CATTEDRA` ha l'assegnazione del tredicesimo posto. Si innesca
**dopo il nodo di sintesi**, non all'arrivo: il posto va a chi l'ha risolto, non
a chi è arrivato.

---

## Chi fa cosa

| | Claude | Tu |
|---|---|---|
| Tutto il codice, i contenuti e gli audit | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | ✅ |

Con un solo esecutore la revisione incrociata sparisce, e la sostituisce una
regola sola: **niente entra senza un audit che lo tenga.** Vale soprattutto per
il runtime, dove un errore non si vede rileggendo — il 3 agosto una sostituzione
in blocco ha invaso due costruttori che non c'entravano, e non me ne sono
accorto rileggendo il diff: me l'ha detto `minigame_audit`.

---

## Il giro dei mondi — quando un mondo è finito

Undici passi. I primi sei sono contenuto e **sono fatti per tutti e 24 i mondi**;
gli altri sono runtime e si fanno un mondo alla volta.

| # | Passo | Chi | Stato |
|---|---|---|---|
| 1 | Cast: specialista, testimone, Bislacco | Claude | ✅ 23/23 abitati |
| 2 | Le 15 battute per residente | Claude | ✅ 23/23 |
| 3 | Richiesta e consolazione (A2) | Claude | ✅ 46 residenti su 46 |
| 4 | Traccia + semi | Claude | ✅ 24/24 · 28 semi |
| 5 | Le 3 conversazioni al Ritrovo | Claude | ✅ 69 scene |
| 6 | Beat del mondo | Claude | ✅ 24 + beat finale |
| 6b | Convergenza al Cuore (solo mondo 24) | Claude | ✅ 52 battute |
| 7 | Edifici vestiti per `artKit`, finestre per stadio, Rovina sul landmark | Codex | 2 e 3 in corso |
| 8 | Routine di vita + regia delle conversazioni | Codex | — |
| 9 | Collocazione fisica di Traccia e semi | Codex | — |
| 10 | Immagini del mondo | Codex | dipende dal kit |
| 11 | Audit verdi + un playthrough di quel mondo | entrambi | — |

**Un mondo è finito** quando gli undici passi sono fatti e queste cinque cose
sono vere:

1. i due residenti hanno stadio 0, 1 e 2 **distinti**, e allo stadio 2 uno dei
   due insegna qualcosa all'altro;
2. c'è **almeno un personaggio che fa ridere**, e nessuna battuta comica ha come
   bersaglio il giocatore;
3. la Traccia si legge in ≤3 schermate e **non è raccontata da nessuno**;
4. il Ritrovo ha le tre conversazioni, e in nessuna qualcuno parla due volte di
   fila o saluta Eli prima della fine;
5. il mondo è giocabile **saltando ogni dialogo**.

---

## La coda — cosa manca davvero

**Il cablaggio è fatto.** Verificato il 3 agosto file per file: tutti e otto i
cataloghi sono usati dal runtime, e ognuno ha un audit che gira nella suite.

| sistema | dove vive | audit |
|---|---|---|
| Dialoghi (A1) | `dialogue_box.gd`, `npc_actor.gd`, cablati in `outdoor_world` | `dialogue_audit` |
| Edifici (A3) | `building_catalog.gd`, `building_actor.gd` | `building_audit` |
| Proprietà missioni (A2) | `mission_ownership_flow.gd` | `mission_ownership_audit` |
| Vita di mondo e Ritrovo (A5) | `world_life.gd` → `ritrovo_catalog.gd` | `world_life_audit` |
| Itineranti (A4) | `outdoor_world.gd` → `itinerant_catalog.gd` | `itinerant_audit` |
| Tracce e semi (A7) | `outdoor_world.gd` → `mystery_catalog.gd` | `mystery_runtime_audit` |
| Il Tredicesimo (A7a) | `thirteenth.gd` | `thirteenth_runtime_audit` |
| Voci dei Maestri | `outdoor_world.gd` → `maestri_catalog.gd` | `maestri_audit` |
| Finale e Cuore | `hub_scene.gd` → `finale_catalog.gd` | `finale_content_audit` |
| Custode (P1–P7) | `pet_*.gd` | `pet_expression_audit` |
| Formati visuali | `FORMATS` include notation, map, hotspot | `visual_content_audit` |

**Suite: 104 audit, tutti verdi, 119 secondi.**

*(Nota su come l'ho verificato, perché è il modo in cui mi ero sbagliato: avevo
cercato i `class_name` e concluso che cinque cataloghi non li usasse nessuno. È
falso — il progetto li carica con `preload`, e il riferimento è la costante, non
il nome di classe. La misura giusta è cercare **il percorso del file**.)*

### Quello che resta, ed è poco

1. **Carta d'Europa e secondo foglio di reperti**: servono asset nuovi, non testo.
2. **Accessibilità dei formati visuali** — da decidere, vedi sotto.
3. **Uscita dall'esercizio**: decisione di design, non ancora presa.

*(Fatti il 3 agosto: banda 4 di elettronica e fisica — tutti e otto gli
argomenti coperti in entrambe — e le domande variabili su **tutte e 123 le
specifiche a dato fisso**, 234 domande aggiunte.)*

### L11 · Accessibilità dei formati visuali — *da decidere*

Le etichette dei bersagli identificano senza descrivere («Segnaposto A»), che è
l'unica scelta che non regala la risposta. Ma vuol dire che **chi usa un lettore
di schermo non può rispondere a una carta muta**. Vale già per grafici e
circuiti. Va deciso, non subìto.

---

## Le dodici materie in ogni mondo — vincolo, e come si regge

Vincolo didattico dichiarato il 3 agosto: **tutte le materie presenti in ogni
mondo**. Misurato: **è già così**, e da oggi è un contratto invece che una
fortuna.

Diciotto eventi per mondo: **sette della materia ospite** (missioni ed enigmi,
contano per il gate) e **undici di pratica, uno per ciascuna delle altre**. Li
produce `MissionEventDirector.other_subjects()`, che restituisce l'intero ciclo.

`subject_presence_audit.gd` (nuovo, verde) verifica per tutti e 24 i mondi:
dodici materie presenti, ≥ undici raggiungibili, **esattamente un evento di
pratica per ognuna delle altre undici**, nessun doppione sull'ospite. Serviva
perché la proprietà era emergente: bastava aggiungere un filtro sensato — «solo
le materie già sbloccate» — per perderla senza che nulla diventasse rosso.

**Da sistemare, ed è tuo, Codex**: al **mondo 8** una materia su dodici cade
oltre il raggio raggiungibile. Il direttore distribuisce le pratiche fino a
`reach + 350`, quindi qualcuna può finire fuori. Presente ma non raggiungibile è
come assente, per un bambino. 23 mondi su 24 sono a 12/12.

**Correzione, e me la scrivo qui perché l'avevo messa nel piano al contrario**:
avevo segnalato come difetto grave che «la prima lezione di storia è a difficoltà
3». Falso. Avevo letto la colonna «prima comparsa» di `content_depth_audit` come
*primo incontro del bambino con la materia*, mentre è la prima volta che quella
materia fa da **ospite**. La storia si incontra al mondo 1, a banda 1.

---

## Cosa resta lato contenuti

**Niente che si scriva.** Le due voci rimaste hanno bisogno di **asset** (carta
d'Europa, secondo foglio di reperti) o di una **decisione** (accessibilità,
uscita dall'esercizio).

Dopo che avrai giocato resta la voce senza dimensione nota: **riscrivere quello
che il collaudo boccia.** È l'unica che può valere mille battute.

---

## Coda tua — il collaudo

Quando i mondi sono cablati ed esportati, **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto (semi troppo espliciti)
   o non capisci cosa sia successo (troppo nascosti)? La taratura vale per tutti
   e sette i colpi: se sbaglia qui, sbaglia sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o sembra che ti
   aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta**: la senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

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
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario,
   nuovo a ogni livello, fedele al registro della materia. Cinque criteri su
   sette hanno un cricchetto; «vero» e «alla portata» li può verificare solo una
   rilettura umana.

### Guard-rail narrativi (i tre che si rompono per primi)

- **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato. Chi
  non c'è è *trattenuto dal Silenzio*: sospeso e recuperabile.
- **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
  il gate. Le tre Tracce decisive (mondi 12, 16, 19) hanno un beat di ripiego.
- **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.

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
   che l'esperienza è corretta, varia e onesta, non che è bella. È il motivo per
   cui si cabla a lotti invece che tutto insieme.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2667/3500 nodi e 468/500 ms, ed è
   quello a cui stiamo per aggiungere abitanti ed edifici. **Contare i nodi prima
   di aggiungerli**, non dopo.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: la suite intera è passata da **105 a 1295 secondi** — dodici
   volte — con sei audit rossi, e un singolo audit da due secondi ne ha impiegati
   oltre quattrocento. Quattro processi Godot in contemporanea, tre non miei. I
   rossi erano tutti in audit che caricano scene, e nessuno toccava le cose
   cambiate: era contesa, non regressione.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma. Un audit
   singolo (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire —
   è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni lotto

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
