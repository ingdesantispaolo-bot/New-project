# Minigiochi didattici — design e handoff grafico (playthrough #11)

Obiettivo: gli esercizi non devono essere un quiz a scelta multipla, ma
**minigiochi in cui la competenza è la meccanica** — si vince usando ciò che si è
imparato, non riconoscendo la risposta tra quattro. Questo documento è il ponte
tra i **contratti-contenuto di Opus** (dati) e la **resa di Codex** (grafica,
feedback, feel). Tutti i renderer di base esistono già nell'`ExercisePlayer`.

## Principi (cosa rende un esercizio un gioco)

Studiati su ciò che rende avvincenti i puzzle-game educativi migliori
(*Human Resource Machine*, *Baba Is You*, *DragonBox*, *Monument Valley*,
*Duolingo*, *Zoombinis*, *The Witness*):

1. **Manipolazione, non selezione.** Si trascina, collega, ordina, mira,
   costruisce — le mani fanno la cosa, non scelgono la sua etichetta.
2. **Feedback immediato e "succoso".** Ogni azione ha una reazione (snap, luce,
   suono, particella). L'errore è informativo e morbido, non punitivo.
3. **Un obiettivo visibile e un progresso.** Si costruisce/accende/completa
   qualcosa: la barra di avanzamento è l'oggetto stesso che prende forma.
4. **Escalation dentro la sessione.** I nodi salgono di complessità; la sfida
   cresce mentre la padronanza cresce (difficoltà per competenza, non per rango).
5. **Nessun timer sul ragionamento.** Il "flow" nasce da catene e combo, non
   dalla pressione del tempo. Solo la matematica (fluency) potrebbe un giorno
   essere cronometrata; il ragionamento mai (guardrail confermato).
6. **Ricompensa diegetica.** La vincita cambia il mondo (rotta accesa, ponte
   costruito, circuito che pulsa): la trasformazione ambientale È il premio.

## Catalogo dei formati come minigiochi

Per ciascuno: meccanica, competenza, materie, **contratto dati (Opus)** e
**resa & feel (Codex)**. I contratti sono in `ExerciseInteraction`.

### 1. Ordinamento / Costruzione — `ordering`
- **Gioco:** metti i pezzi nella sequenza giusta; ogni pezzo corretto si aggancia
  e la struttura cresce (ponte, macchina, frase, catena di passi).
- **Competenza:** sequenze e procedure — coding (algoritmo/loop), matematica
  (passi di un problema), italiano/latino (ordine delle parole), musica (ritmo).
- **Dati:** `items` (mescolati), `correctOrder`. *(implementato)*
- **Resa & feel (Codex):** slot numerati che si illuminano in sequenza; il pezzo
  giusto fa "snap" e connette una linea/tubo al successivo; il pezzo sbagliato
  rimbalza dolcemente. A completamento, la struttura si accende tutta.

### 2. Abbinamento / Collegamento — `matching`
- **Gioco:** collega ogni elemento al suo corrispondente tracciando una linea; le
  coppie giuste restano accese e "chiudono" un circuito/rotta/mappa.
- **Competenza:** relazioni e corrispondenze — inglese/latino (parola↔significato),
  geografia (paese↔capitale), scienze (organo↔funzione), elettronica (grandezza↔unità).
- **Dati:** `pairs: [{left, right}]` (i `right` mescolati). *(implementato)*
- **Resa & feel (Codex):** trascinare una linea da sinistra a destra; la linea
  giusta si fissa luminosa con un "click", quella sbagliata svanisce. Colonne come
  due sponde da unire; a coppie complete, un flusso attraversa i collegamenti.

### 3. Classificazione / Smistamento — `classification`
- **Gioco:** trascina ogni tessera nel contenitore giusto; ordinare "riempie" gli
  scaffali/habitat/quartieri. Riassegnabile prima di verificare.
- **Competenza:** categorie e criteri — italiano (classi di parole), scienze
  (viventi per dieta), coding (tipi di dato), storia (reperti per epoca),
  geografia (paese→continente), matematica (pari/dispari, proprietà).
- **Dati:** `items`, `categories`, `assignments: {item→categoria}`. *(implementato)*
- **Resa & feel (Codex):** tessere trascinabili in "bidoni" tematizzati per materia
  (scaffali per italiano, habitat per scienze, teche per epoca per storia); una
  tessera nel bidone giusto si posa con luce verde, in quello sbagliato torna
  indietro con un pulse ambra. A board completa, i contenitori si animano.

### 4. Mira / Hotspot — `hotspot`
- **Gioco:** tocca il punto giusto su un'immagine/mappa/diagramma. Precisione,
  non lista.
- **Competenza:** localizzazione e lettura visiva — geografia (dove sulla carta),
  scienze (parte del corpo/cellula), musica (nota sul pentagramma), latino
  (elemento dell'iscrizione).
- **Dati:** `hotspots: [{id, x, y, label?}]`, `answer` (id corretto), immagine di
  sfondo. *(implementato per storia con l'atlante illustrato dei reperti romani)*
- **Resa & feel (Codex):** immagine diegetica del livello; il tocco lascia un
  bersaglio; hotspot giusto → cerchio luminoso ed etichetta; sbagliato → ping
  breve. Serve un set di immagini per materia (mappa, corpo, pentagramma…).

### 5. Grafico — `graph`
- **Gioco:** leggi assi e andamento, poi seleziona il punto richiesto (massimo,
  intersezione, valore a x).
- **Competenza:** lettura di dati — matematica (coordinate, funzioni), fisica
  (moto/pressione nel tempo), scienze (crescita), geografia (quote/clima).
- **Dati:** `points: [{id, x, y}]`, assi, `answer`. *(renderer pronto)*
- **Resa & feel (Codex):** assi e griglia leggibili; punti come nodi selezionabili;
  il punto giusto pulsa, una guida tratteggiata scende sugli assi a mostrare la
  lettura.

### 6. Circuito — `circuit`
- **Gioco:** osserva i collegamenti e scegli/collega il componente giusto per far
  scorrere la corrente e accendere il carico.
- **Competenza:** elettronica (serie/parallelo, componenti, guasti), logica (flusso).
- **Dati:** `components: [{id, kind}]`, collegamenti, `answer`. *(renderer pronto)*
- **Resa & feel (Codex):** schema pulito; scelta corretta → la corrente scorre
  animata fino al LED che si accende; scelta sbagliata → il percorso resta spento.

### 7. Trace / Debug del codice — `code_debug`
- **Gioco:** segui l'esecuzione riga per riga e trova/correggi il passo rotto.
- **Competenza:** coding (debug, trace), logica.
- **Dati:** righe di codice, stato atteso, `answer` (riga/correzione). *(renderer pronto)*
- **Resa & feel (Codex):** evidenziatore che avanza sulle righe con lo stato delle
  variabili a lato; la riga-bug lampeggia; la correzione riavvia l'automa/output.

### 8. Inserimento — `numeric_input`
- **Gioco:** digita il risultato; per la matematica (fluency) l'unico formato dove
  la rapidità ha senso didattico, ma oggi resta senza tempo.
- **Dati:** `answer`. *(implementato; `answers_equivalent` accetta 12 ≡ 12.0 ≡ 12,0)*

### 9. Scelta multipla — `multiple_choice`
- **Uso residuo, ≤ 1/3 dei nodi.** Resta per vero/falso motivato o quando la
  discriminazione tra alternative È la competenza. Mai dominante.

### 10. Ponte delle trasformazioni — `machine_path`
- **Gioco:** monta in ordine macchine matematiche, avvia una sfera e osserva
  come cambia a ogni passaggio fino al traguardo.
- **Competenza:** calcolo a più passaggi, ordine delle operazioni, previsione e
  correzione di una strategia.
- **Dati:** `start`, `target`, `slotCount`, `machines`, `solution`.
  *(implementato e attivo nelle missioni di matematica)*
- **Resa & feel:** trascinamento o tocco, percorso numerico sempre visibile,
  animazione sequenziale all'avvio e ponte che si apre quando il valore arriva
  al traguardo. Sono accettati anche percorsi corretti diversi da quello creato
  dal generatore.

### 11. Il campione senza nome — `mystery_sample`
- **Gioco:** scegli gli strumenti del laboratorio, produci osservazioni e scopri
  quale materiale è nascosto nella capsula.
- **Competenza:** metodo sperimentale, proprietà dei materiali e deduzione da
  più prove — calamita, conducibilità elettrica, luce e galleggiamento.
- **Dati:** `samples`, `tests`, `results`, `answer`, `minTests`.
  *(implementato e attivo nelle missioni di scienze e fisica)*
- **Resa & feel:** ogni strumento fa reagire il campione e aggiunge una riga al
  quaderno di BIT. Un'ipotesi sbagliata indica quale esperimento la contraddice,
  senza rivelare il materiale. Campione, strumenti e ipotesi cambiano ordine a
  ogni caso.

### 12. Il messaggio fuori tempo — `verb_decoder`
- **Gioco:** una frase arrivata dal Relitto ha perso il verbo. Si regolano tre
  ghiere — quando accade, come viene presentata, forma corretta — e si avvia il
  decodificatore per recuperare una piccola scoperta narrativa.
- **Competenza:** tempi dell'indicativo, differenza fra fatto/dubbio/possibilità/
  ordine, congiuntivo e condizionale, concordanza dei tempi e modi indefiniti.
- **Dati:** `segments`, `clues`, `timeChoices`, `moodChoices`, `forms`,
  `solution`, `hints`, `discovery`.
  *(implementato e attivo nelle missioni di italiano)*
- **Resa & feel:** la frase cambia mentre si inserisce la forma; il controllo
  finale anima la barra del decodificatore. Un errore indica quale ragionamento
  non coincide — tempo, modo o forma — senza consegnare tutta la soluzione.

## Materia → formati consigliati

| Materia | Formati minigioco prioritari |
|---|---|
| matematica | machine_path · numeric_input · graph · ordering (passi) · classification (proprietà) |
| italiano | verb_decoder (tempi e modi) · classification (classi di parole) · ordering (frase) · matching (sinonimi/contrari) |
| coding | code_debug · ordering (algoritmo) · classification (tipi) · matching (operatori) |
| inglese | matching (lessico) · classification (categorie) · ordering (frase) |
| fisica | mystery_sample · graph (moto/pressione) · numeric_input · matching (grandezza↔unità) |
| musica | hotspot (nota sul pentagramma) · ordering (ritmo) · matching (strumenti) |
| latino | matching (caso↔funzione, lessico) · ordering (frase) · classification (declinazioni) |
| elettronica | circuit · matching (grandezza↔unità) · classification (serie/parallelo) |
| geografia | hotspot (mappa) · matching (capitali) · classification (continenti) |
| scienze | mystery_sample · classification (viventi/ecosistemi) · hotspot (corpo/cellula) · graph (crescita) |
| storia | ordering (linea del tempo, fasi di Roma) · classification (reperti per epoca) · matching (personaggi e fonti) |
| logica | ordering (sequenze) · classification (esclusioni) · code_debug (deduzione) |

## Cosa serve a Codex per completare #11

I renderer esistono. Per portare i minigiochi "avvincenti" nel percorso live:

1. **Feel & juice** su ogni renderer (snap, luce, suono, particelle, board che si
   anima a completamento), tematizzati per materia come sopra.
2. **Asset immagine:** il primo `hotspot` illustrato è attivo per storia; grafici,
   circuiti, mappe e pentagrammi sono resi proceduralmente perché coordinate,
   note e collegamenti cambiano a ogni esercizio. Nuovi atlanti servono soltanto
   quando entra un nuovo contratto hotspot con coordinate fisse.
3. ~~**Attivare `build_varied_mission`** come default del percorso live~~ — fatto:
   missioni **ed enigmi** usano il mix vario. Misura sull'esperienza giocata dei
   24 mondi (`format_mix_audit`): scelta multipla al 17%, nessun formato oltre il
   21%, 6–7 formati distinti per materia.

## Cosa fornisce Opus (contenuti)

- `classification` reale e giocabile per più materie (in `MinigameManager`, senza
  asset): smistamento come primo minigioco non-MC diffuso.
- I contratti dati di tutti i formati (`ExerciseInteraction.validate`).
- Per i formati visivi: i DATI (punti, hotspot, componenti, righe) si consegnano
  quando Codex fissa il set di immagini/coordinate di riferimento (contratto
  congiunto, stesso gate).
