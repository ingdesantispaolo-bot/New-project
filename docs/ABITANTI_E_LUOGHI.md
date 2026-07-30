# Eli Quest — Abitanti, dialoghi e luoghi

> Specifica del **mondo abitato**: chi vive nei 24 mondi, come parla, come
> assegna le missioni, come i personaggi si parlano tra loro e come gli edifici
> raccontano la storia.
> Trama e mistero in [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md), loop e gate in
> [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md), compagno in
> [PET_CUSTODE.md](PET_CUSTODE.md).
>
> **Vincolo architetturale non negoziabile**: gli abitanti **non creano una
> seconda progressione**. Non generano missioni nuove, non danno mastery, non
> muovono il gate. Danno un **volto e una ragione** agli eventi che
> `MissionEventDirector` pianifica già.

---

## 1. Perché servono gli abitanti

Oggi Eli è sola in un mondo bellissimo e disabitato, con una voce nell'orecchio.
Mancano tre cose che un bambino di 11 anni cerca in un gioco:

1. **Qualcuno per cui fare le cose.** Riempire una barra "missioni 3/5" è un
   compito. Aiutare Tobia a capire perché conta male è una storia.
2. **Qualcuno che si accorga di te.** Il riconoscimento sociale è la ricompensa
   più forte a quell'età, più dell'energia e più dei cosmetici.
3. **Un mondo che cambia perché ci sei passata.** Non solo la vegetazione che si
   illumina: le *persone* che smettono di fare un gesto vuoto e ricominciano a
   capirlo.

E ne serve una quarta, che è didattica: **spiegare a qualcun altro è il modo più
efficace di consolidare.** Con degli abitanti, "rispiegalo tu" diventa una
meccanica naturale invece che un esercizio travestito.

---

## 2. Architettura del cast: tre anelli

| Anello | Quanti | Dove | Funzione |
|---|---|---|---|
| **Residenti** | 2 per mondo (48) | Uno solo mondo, sempre lì | Incarnano la materia del mondo; hanno l'errore di comprensione da correggere |
| **Itineranti** | 6 in totale | Ovunque, a rotazione | Continuità affettiva: gli amici che ritrovi. Ricordano cosa hai fatto altrove |
| **Voci (i Maestri)** | 12 | Solo nella nave | Non camminano: sono le inflessioni di NORA (vedi TRAMA §3) |

Budget: **massimo 4 abitanti attivi contemporaneamente** in scena (2 residenti +
1 itinerante + 1 di passaggio). Rientra nel `performance_budget` esistente
usando lo stesso streaming dei POI: fuori dal `streamRadius` un abitante non è
istanziato.

### 2.1 Anatomia di un residente

Ogni residente si autora con cinque campi. Sono pochi di proposito: la varietà
nasce dalla combinazione, non dalla quantità di testo.

| Campo | Cos'è | Perché |
|---|---|---|
| `ruolo` | Cosa fa nel mondo | Lo lega all'identità del mondo |
| `tic` | Un intercalare, un modo di chiamare Eli, un gesto ricorrente | È il trucco di Animal Crossing: rende memorabile un personaggio con 10 battute |
| `convinzione` | **Un'idea sbagliata reale** sulla materia | È il gancio didattico: la stessa misconcezione che ha il giocatore |
| `bisogno` | Cosa chiede a Eli | Diventa il motivo della missione |
| `arco` | Come cambia in 3 stadi | Rende visibile che il mondo evolve |

La `convinzione` è il cuore del design. Non sono personaggi decorativi: ognuno
sbaglia **come sbagliano i bambini**, e vederlo cambiare idea è il modello di
ciò che sta succedendo al giocatore.

### 2.2 I tre stadi di relazione

Non si comprano, non si regalano oggetti. Avanzano su ciò che Eli **impara**.

| Stadio | Si sblocca quando | Cosa cambia |
|---|---|---|
| **0 · Gesto vuoto** | ingresso nel mondo | Ripete il rituale senza senso; dialoghi brevi, un po' persi |
| **1 · Dubbio** | superata la prima missione di sua proprietà | Comincia a fare domande; ti chiama per nome; il suo edificio si accende in parte |
| **2 · Capito** | gate del mondo pronto (missioni + mastery) | Ha cambiato idea; insegna a un altro abitante; l'edificio è pieno di vita |

Lo stadio 2 non richiede l'esame: si può ottenere prima di riparare l'apparato.
Così la ricompensa sociale arriva quando il giocatore ha fatto il lavoro, non
quando supera un test.

### 2.3 I sei itineranti

Sono il cast fisso, quello a cui ci si affeziona. Uno solo è presente in un mondo
alla volta (rotazione deterministica dal seed + livello), e ognuno ha una
**funzione di gioco**, non solo un carattere.

| Nome | Chi è | Tic | Funzione di gioco |
|---|---|---|---|
| **Nima** | Cartografa girovaga, allegra, baratta domande invece di merci | Ti chiama sempre «capitana» | **Orientamento**: dice dove sono le cose e cosa non hai ancora visto in questo mondo |
| **Vera** | Ragazzina della tua età, apprendista di niente, vuole imparare tutto | Finisce ogni battuta con una domanda | **Consolidamento**: ti chiede di rispiegarle ciò che hai appena imparato (§5.3) |
| **Orsolo** | Vecchio riparatore, brontolone, non crede alle "storie dei Primi" | «Mah.» | **Attrito**: mette in dubbio il mistero, obbliga a portare prove. Si converte lentamente |
| **Sesto** | Uno Sbiadito restituito a se stesso nel mondo 3. Dimentica le cose | Scambia le parole («passami il… coso che conta») | **Ripasso spaziato**: chiede aiuto proprio sugli argomenti che *tu* hai in scadenza di ripasso |
| **Cinabro** | Narratore mascherato, baratta storie in cambio di fatti | Parla in terza persona | **Mistero**: consegna il lore dei Primi come favole. Ambiguo: sembra sapere troppo |
| **Lucilla** | Alleva e cura i Custodi (i pet) | Parla ai pet, non a te | **Compagno**: dà il primo Custode, apre la schermata del pet, commenta il legame |

Note di regia:

- **Vera è il personaggio più importante del gioco dopo NORA.** È il pari: fa le
  domande che il giocatore ha paura di fare e riceve le spiegazioni che il
  giocatore deve consolidare. Cresce insieme a Eli, mondo dopo mondo.
- **Sesto** rende umano il ripasso spaziato: ripassare non è una punizione per
  aver sbagliato, è aiutare un amico che dimentica.
- **Orsolo** esiste perché un mistero senza nessuno che lo neghi non è un
  mistero: è un'informazione.
- Al **mondo 24** gli itineranti convergono tutti al Cuore, insieme ai residenti
  che hai portato allo stadio 2. Chi ti aspetta al finale dipende da chi hai
  fatto crescere.

---

## 3. Il cast dei 24 mondi

Formato: **Specialista** (ha la convinzione sbagliata) · **Testimone** (sa senza
sapere di sapere, e indica la Rovina). In corsivo la convinzione da smontare.

### Atto I — Chi accende

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **1 · Radura Accademia · matematica** | **Tobia**, conta i cristalli uno per uno. Tic: chiude le frasi con «…e uno». *«Contare in fretta è barare.»* | **Nonna Ersilia**, canta una filastrocca che è la tabellina del 7 e non lo sa | Bastone da conteggio dei Primi, tacche a gruppi di dieci: «contare in gruppi non è pigrizia, è vedere lontano» |
| **2 · Archivio delle Parole · italiano** | **Corinna**, ordina le parole per lunghezza. Tic: misura tutto con le dita. *«L'ordine giusto è quello che si vede.»* | **Bruno**, bambino che inventa parole e viene sgridato — ha ragione lui | Catalogo dei Primi ordinato per **funzione**, non per forma |
| **3 · Cratere Logico · coding** | **Ruggine**, riavvia la macchina a mano ogni giro. Tic: soffia sugli attrezzi. *«I cicli sono per i pigri.»* | **Sesto**, lo Sbiadito che qui torna se stesso e poi ti segue ovunque | Schema di telaio: «ripetere non è fatica, è un'istruzione» |
| **4 · Baia dei Segnali · inglese** | **Marea**, ripete i messaggi senza capirli per paura di sbagliare. Tic: sussurra prima di parlare. *«Capire è tradurre parola per parola.»* | **Vecchio Lino**, pescatore con venti parole d'inglese e zero timidezza | Quaderno bilingue dei Primi: la stessa lezione in due lingue affiancate |
| **5 · Officine del Moto · fisica** | **Gerbo**, sposta i massi a forza bruta. Tic: si sputa sulle mani. *«Le leve sono trucchi da deboli.»* | **Tilla**, ha capito il fulcro sull'altalena e nessuno le dà retta | **Prima spirale aperta**, incisa secoli dopo la caduta: «chi solleva con la testa non è meno forte» |
| **6 · Giardino della Risonanza · musica** | **Ambra**, accorda a orecchio benissimo, non sa nominare un intervallo. Tic: canticchia le risposte. *«Dare un nome alla musica la rovina.»* | **Oreste**, sordo, legge la musica con le mani sulle corde | Diapason dei Primi: «un suono con un nome si può regalare a qualcuno» |
| **7 · Rovine dei Glifi · latino** | **Livia**, la migliore copista: copia perfettamente senza leggere. Tic: soffia sull'inchiostro. *«Copiare bene è già capire.»* | **Zeno**, gioca a «trova la parola parente» e indovina i significati | Dizionario delle radici: una radice per pagina, i suoi discendenti sotto |
| **8 · Delta dei Circuiti · elettronica** | **Ciro**, collega i cavi a memoria; se lo schema cambia si blocca. Tic: conta i nodi a voce. *«Basta ricordare lo schema giusto.»* | **Doria**, guardiana delle chiuse: capisce la corrente per analogia con l'acqua | **Traccia decisiva 1** — sigillo d'equipaggio con **tredici** posti e dodici nomi |

### Atto II — Chi ha taciuto

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **9 · Arcipelago Cartografico · geografia** | **Alma**, disegna solo ciò che ha visto. Tic: bagna la matita. *«I numeri non sono posti.»* | **Remo**, traghettatore che sta perdendo la memoria delle rotte e vuole scriverle | Carta della rotta della nave: non una fuga, un **giro** che si ripete |
| **10 · Serra delle Simbiosi · scienze** | **Ortensia**, quando un esperimento fallisce cambia tre cose insieme. Tic: parla alle piante. *«Se cambio tutto, prima o poi funziona.»* | **Mirta**, quarant'anni di diario di osservazioni senza sapere che è scienza | Le provviste chiuse con ordine e gli appunti impilati: nessuno è stato sorpreso |
| **11 · Soglia del Tempo · storia** | **Danio**, data i reperti «a occhio» e crede alla prima storia che sente. Tic: scommette su tutto. *«Se lo dicono tutti, è vero.»* | **Vesta**, custodisce due cronache che si contraddicono e non sa quale bruciare | Due datazioni discordanti del Silenzio — nessuna delle due va bruciata |
| **12 · Labirinto delle Regole · logica** | **Quinto**, sa il percorso a memoria; se i muri si spostano è perduto. Tic: conta i passi. *«Ricordare la strada è saperla.»* | **Isa**, segna i bivi con un filo: ha inventato il metodo da sola | **La scheda d'iscrizione di NORA**, allieva n.1 dei Dodici |
| **13 · Deserto delle Orbite · matematica** | **Solano**, misura tutto e non stima mai; senza strumenti è paralizzato. Tic: pulisce le lenti. *«Stimare è tirare a indovinare.»* | **Duna**, indovina le distanze a occhio e crede sia un dono, non un metodo | Registro di Abaco: «abbiamo chiuso il sapere per salvarlo. Non tutti erano d'accordo» |
| **14 · Biblioteca delle Voci · italiano** | **Elmo**, riassume tutto in una frase e perde il punto di vista. Tic: taglia l'aria con la mano. *«Se so come finisce, ho capito.»* | **Ottavia**, racconta di mestiere la stessa storia da tre prospettive | **Traccia decisiva 2** — verbali con una tredicesima voce che dissente e perde |
| **15 · Città Macchina · coding** | **Gru**, riavvia invece di leggere l'errore. Tic: dà un colpetto alle macchine. *«L'errore è solo sfortuna.»* | **Pila**, bambina con un quaderno di tutti i guasti e le cause: ha inventato il log | La frase esatta: «una conoscenza chiusa è già silenzio» |
| **16 · Frontiera delle Lingue · inglese** | **Talia**, interprete che traduce alla lettera e crea equivoci. Tic: si scusa sempre. *«Ogni parola ha una sola traduzione.»* | **Marco dei Valichi**, commercia in sei lingue con cento parole ciascuna | I rituali degli abitanti riconosciuti come **lezioni consumate** della Tredicesima |

### Atto III — Chi continua

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **17 · Oceano delle Forze · fisica** | **Nerea**, palombara, scende sempre più giù «a sentimento». Tic: trattiene il fiato mentre parla. *«Il corpo sa da solo quanto reggere.»* | **Coral**, ha smesso di scendere e sa dire esattamente perché: fa i conti | Il nome: **Meridiana**, uno strumento che non funziona al chiuso |
| **18 · Cattedrale del Suono · musica** | **Silo**, organista che suona solo forte. Tic: conta il riverbero. *«Il piano qui non si sente.»* | **Bea**, canta nei punti giusti della navata: ha mappato l'eco | Il progetto costruttivo di **Eli**, firmato con la spirale aperta |
| **19 · Necropoli delle Radici · latino** | **Numa**, epigrafista: considera le parole moderne «corrotte». Tic: lucida le lapidi. *«La lingua di prima era quella giusta.»* | **Fiorina**, chiama le piante con nomi antichi senza sapere che lo sono | Il perché: «il sapere che cammina sopravvive a quello che si nasconde» |
| **20 · Tempesta Elettromagnetica · elettronica** | **Sferza**, quando un sensore sbaglia alza la potenza. Tic: batte le nocche sui quadri. *«Se non legge, spingi di più.»* | **Quieto**, legge i lampi e prevede la scarica | Misure che dicono una cosa sola: il Silenzio si assottiglia dove sei passata |
| **21 · Atlante Fratturato · geografia** | **Terza**, studia un clima alla volta e non vede il sistema. Tic: allinea i fogli. *«Ogni posto fa storia a sé.»* | **Mino**, pastore con un calendario tramandato che è un modello climatico | Le zone tornate leggibili sovrapposte alla rotta antica: la stessa figura |
| **22 · Biosfera Profonda · scienze** | **Vesca**, cerca l'organismo «più forte». Tic: annusa tutto. *«Vince sempre il più forte.»* | **Fondo**, guida delle caverne: conosce ogni nicchia e chi ci vive | La domanda di NORA scritta da un Maestro: archivio o viaggiatore? |
| **23 · Sala delle Ere · storia** | **Cronia**, conserva solo la versione ufficiale. Tic: timbra tutto. *«Le fonti scomode confondono.»* | **Ovidio**, copista: le ha conservate di nascosto per quarant'anni | **Traccia decisiva 3** — nome, firma e scelta della Tredicesima, per intero |
| **24 · Cuore dei Primi · trasversale** | *Nessun nuovo residente*: al Cuore convergono i sei itineranti e i residenti portati allo stadio 2 (max 4 in scena a rotazione) | — | L'ultima nota di Meridiana, scritta a mano, indirizzata a Eli, datata **prima** della sua costruzione |

---

## 4. Gli edifici: tre ruoli, ventiquattro vestiti

Ogni mondo ha **tre edifici autorati**. Stessi tre ruoli ovunque — così il
giocatore impara a leggere il mondo a colpo d'occhio — vestiti con l'`artKit` del
mondo, così ognuno sembra un posto diverso.

| Ruolo | Cos'è | Funzione narrativa | Funzione di gioco |
|---|---|---|---|
| **Casa del mestiere** | Il posto dove la materia si pratica: casa del conto, scriptorium, officina dei giri, casa delle boe… | Allo stadio 0 ci si esegue il **gesto vuoto**; allo stadio 2 ci si insegna di nuovo | Casa dello Specialista. Le missioni di sua proprietà partono da qui |
| **Il Ritrovo** | Piazza, molo, fontana, chiostro, cortile, grotta | Il cuore sociale: qui gli abitanti **si parlano tra loro** | Punto di convergenza delle routine; qui si ascoltano le conversazioni (§6) |
| **La Rovina dei Primi** | Il landmark eroe già esistente (obelisco, faro, arco, osservatorio…) | Usata dai locali **per lo scopo sbagliato**: un anfiteatro come stalla, un osservatorio come granaio | Contiene la **Traccia** del mondo e il segno della spirale aperta |

Tre osservazioni di design:

1. **La Rovina è già nel gioco.** `heroLandmarks` esiste in ogni `WorldProfile` e
   `build_landmark()` ha già le 24 texture. Non serve arte nuova per il ruolo più
   importante: serve dargli un interno, un uso sbagliato e una Traccia.
2. **La Casa del mestiere si costruisce come `build_academy_pavilion()`**, che
   esiste già ed è esattamente questo: un edificio vettoriale caldo, leggibile a
   distanza, con finestre che si accendono di notte. Serve una variante per
   `artKit`, non un sistema nuovo.
3. **L'accensione delle finestre è la barra di progresso del mondo.** Stadio 0:
   buie. Stadio 1: metà. Stadio 2: tutte, più fumo dal camino e gente fuori. È
   diegetico, costa poco e si legge senza testo.

**Geometria** (stesse regole dei POI, per non rompere nulla): posizioni autorate
in coordinate mondo con origine sull'ingresso nave, **mai** dentro
`shipEntrance.safeRadius`, **mai** sopra la `safeRoute`, sempre adiacenti alla
rete di strade di `WorldCompositionData`. La Rovina coincide con la posizione del
landmark eroe già calcolata da `_hero_landmark_position()`.

---

## 5. Dialoghi

### 5.1 Forma (regole Animal Crossing)

- **1–3 righe per schermata**, mai di più. Una idea per schermata.
- **Avanzamento a tocco** su tutta la schermata; nessun dialogo a tempo, nessuna
  scelta obbligata per proseguire.
- **Ritratto + nome + testo**, in basso, con l'area di gioco ancora visibile:
  parlare non è entrare in un'altra scena.
- **Effetto macchina da scrivere** con completamento istantaneo al primo tocco, e
  **disattivato** quando è attiva la riduzione del movimento.
- **Mai muri di lore.** Le Tracce sono lette, non recitate.
- Ogni battuta ha un `tic` del personaggio in almeno una riga su tre.

### 5.2 Selezione delle battute

`DialogueDirector` è una funzione **pura e deterministica**: dato lo stato,
sceglie una battuta. Non scrive nel save tranne il marcatore "già vista".

Priorità di scelta (la prima che ha materiale vince):

1. **Reazione a caldo** — hai appena finito una missione sua, hai appena riparato
   l'apparato, hai appena portato Sesto a ripassare.
2. **Notizia** — un altro abitante ha qualcosa da riferire su di te (§6.2).
3. **Stadio** — la battuta della fase relazionale corrente.
4. **Contesto** — fase del giorno, meteo del mondo, POI vicino non ancora fatto,
   argomento in scadenza di ripasso.
5. **Riempimento** — pool di chiacchiere in carattere, con anti-ripetizione
   (mai la stessa battuta due volte di fila, mai una delle ultime 3).

Ogni personaggio ha un **minimo di 12 battute** per essere validato: 3 per
stadio, 3 di reazione, 3 di riempimento.

### 5.3 «Rispiegamelo» — la meccanica di Vera

Dopo che un argomento è passato allo stato `applied` nel Codex, Vera può
chiedere: *«Quella cosa dei gruppi uguali… me la rifai? Non ho capito la parte
del perché.»*

- Si aprono **3 spiegazioni**: una corretta, una plausibile-ma-superficiale, una
  con l'errore tipico di quell'argomento (lo stesso già presente nel Codex, campo
  `error`).
- Scegliere quella giusta è **elaborazione**, non ripetizione: è la forma di
  ripasso con il ritorno più alto sulla ritenzione.
- Ricompensa: **nessuna energia**, nessun avanzamento di gate. Vera capisce, e lo
  dice. La ricompensa è sociale — che è precisamente il punto.
- Effetto reale: l'argomento riceve una prova di ritenzione in
  `spaced_repetition` (una risposta corretta in sessione distinta, valida per il
  criterio di consolidamento).
- Frequenza massima: **una volta per sessione**, mai due volte lo stesso
  argomento nella stessa giornata. Non deve diventare un'interruzione.

### 5.4 Come gli abitanti assegnano le missioni

Nessuna missione nuova viene creata. Ogni evento pianificato da
`MissionEventDirector` riceve un **proprietario**:

```
evento (già esistente)  +  ownerNpc: "w01-tobia"
```

Il flusso:

1. **Richiesta** — parli con Tobia: «Il filare est non torna. Ho contato tre
   volte… e uno.» Il POI corrispondente viene evidenziato in bussola.
2. **Svolgimento** — invariato: si apre la stessa sessione di esercizi di oggi.
3. **Ritorno** — al rientro, o subito sul posto, battuta di esito. **Mai** una
   battuta di delusione se la sessione è fallita: «Allora non ero solo io a non
   capire. Riproviamo insieme?»
4. **Conseguenza** — allo stadio 1 e 2, la Casa del mestiere cambia e l'abitante
   dice cosa ha capito.

Regole di sicurezza:

- Un evento **senza** proprietario resta perfettamente giocabile (fallback:
  nessun dialogo). Se il catalogo abitanti è incompleto, il gioco non si rompe.
- L'abitante **non ripete** i requisiti del gate: quelli stanno nell'HUD. Parla
  del suo problema, non dei tuoi contatori.
- Gli **eventi di pratica** (che non contano per il gate) non hanno proprietario
  fisso: sono di chi passa di lì — spesso l'itinerante di turno.

---

## 6. La vita del mondo

È la parte che trasforma "personaggi collocati" in "mondo che evolve". Deve
restare **deterministica** (stesso seed + stesso stato = stessa vita) e a costo
quasi zero: nessuna simulazione, nessuna IA.

### 6.1 Routine

Ogni abitante ha **tre ancoraggi**: casa, lavoro, Ritrovo. La fase giorno/notte,
già presente, sceglie dove si trova. Si spostano con un cammino lento tra i punti
quando sono fuori inquadratura; in campo, si limitano a un'animazione di
occupazione (contare, martellare, scrivere).

### 6.2 Notizie

Quando succede qualcosa di rilevante — missione superata, apparato riparato,
abitante portato a uno stadio nuovo, Traccia trovata — viene emessa una
**notizia**: un piccolo token `{tipo, mondo, soggetto, livello}`.

Gli abitanti **consumano** le notizie e ne fanno battute:

> **Doria** — «Nima dice che al Cratere hai fatto ripartire una macchina che
> stava ferma da prima di mio nonno. Vero?»

Regole: massimo 8 notizie in coda, le più vecchie decadono, ogni notizia è usata
al massimo da 2 abitanti (altrimenti sembra un coro). Gli **itineranti hanno
priorità** sulle notizie di altri mondi: sono loro che viaggiano, ed è così che
il giocatore capisce che i mondi sono un unico posto.

### 6.3 Conversazioni al Ritrovo

**La feature più importante di questa sezione.** In certi momenti della giornata,
due o tre abitanti si trovano al Ritrovo e **parlano tra loro**. Eli può
avvicinarsi e ascoltare: non è un dialogo, è una scena che accade comunque.

- **4–6 battute**, alternate, con i tic dei personaggi.
- Almeno una fa riferimento a qualcosa che **hai fatto tu** (via notizie), senza
  rivolgersi a te.
- Almeno una versione per stadio del mondo: allo stadio 0 discutono del gesto
  vuoto, allo stadio 2 uno insegna all'altro.
- Se ti avvicini si accorgono di te alla fine e ti salutano — non si
  interrompono subito: essere visti *dopo* è ciò che fa sembrare che vivessero
  anche senza di te.
- Almeno **una conversazione per mondo per stadio** (24 × 3 = 72 scenette da
  4–6 battute). È il grosso del lavoro di scrittura, ed è il denaro meglio speso.

Esempio (mondo 1, stadio 0 → stadio 2):

> **Stadio 0**
> Tobia — «Filari da sei. Sempre sei. Uno, due, tre… e uno.»
> Ersilia — «Canta invece di contare, che fai prima.»
> Tobia — «La tua canzone non è contare, nonna.»
> Ersilia — «No? *Sette, quattordici, ventuno…* Boh. Mia madre la faceva così.»

> **Stadio 2**
> Ersilia — «…ventotto, trentacinque. Ecco. E tu dicevi che non era contare.»
> Tobia — «È contare a gruppi. Me l'ha spiegato Eli. Salti di sette.»
> Ersilia — «E allora perché la mia canzone lo sapeva e io no?»
> Tobia — «Perché qualcuno te l'ha insegnata e poi ha smesso di dirti perché.»
> Ersilia — «…Mah. Cantiamo il nove, adesso?»

### 6.4 Gli stadi del mondo

| Stadio | Condizione (dati già esistenti) | Cosa si vede |
|---|---|---|
| 0 | ingresso nel mondo | Zone sbiadite, gesti vuoti, edifici spenti, abitanti dispersi |
| 1 | ≥ metà delle missioni richieste | Metà finestre accese, primi dialoghi di dubbio, il Ritrovo si popola |
| 2 | gate pronto (missioni + mastery) | Edifici accesi, abitanti allo stadio 2, conversazione nuova al Ritrovo |
| 3 | apparato riparato | Un abitante **insegna a un altro**; la Rovina è ripulita e usata bene; arriva un nuovo passante |

Nessuna condizione nuova: sono tutte già in `runtime_state()`.

---

## 7. Contratti tecnici

### 7.1 Nuovi moduli

| Modulo | Tipo | Responsabilità | Non fa |
|---|---|---|---|
| `npc_catalog.gd` | dati (`RefCounted`) | 48 residenti + 6 itineranti, con i 5 campi + pool di battute | Non calcola stati |
| `npc_director.gd` | logica | Chi è presente, dove, in che stadio; assegna `ownerNpc` agli eventi | Non tocca mastery, energia, gate |
| `dialogue_director.gd` | logica pura | Sceglie la battuta secondo la priorità §5.2 | Non scrive nel save (tranne "vista") |
| `world_life.gd` | logica | Routine, notizie, conversazioni al Ritrovo | Nessuna simulazione continua |
| `building_catalog.gd` | dati | 3 edifici × 24 mondi: ruolo, posizione, artKit, stato | Non decide progressione |
| `dialogue_box.gd` | UI | Ritratto, testo, avanzamento, accessibilità | Non decide cosa dire |
| `npc_actor.gd` | scena | Presenza, routine, animazione di occupazione, area d'interazione | Non contiene testo |

### 7.2 Estensione del save

```gdscript
"npc": {
    "relations": { "w01-tobia": 2, "w01-ersilia": 1 },   # stadio 0..2
    "seen": { "w01-tobia": ["l03","l07"] },              # anti-ripetizione
    "news": [ {"type":"mission","world":3,"level":3} ],  # coda max 8
    "explained": { "matematica:tabelline": 2 }            # "rispiegamelo" a Vera
},
"mystery": { "traces": [1,3,5] }
```

Migrazione **non distruttiva e idempotente**, come già fa `save_manager.gd`: un
salvataggio senza queste chiavi parte da vuoto e gioca normalmente.

### 7.3 Vincoli di integrazione

1. **Nessun abitante scrive mastery, energia, gate o ricompense.** Solo
   `OutdoorGameplay` lo fa, come oggi.
2. **Nessun abitante è obbligatorio.** Il percorso 1→24 resta completabile senza
   parlare con nessuno. Un catalogo vuoto degrada a gioco attuale.
3. **Budget**: max 4 abitanti istanziati, streaming come i POI, nessun `_process`
   per abitante fuori dallo `streamRadius`. Restano validi i tetti di
   `performance_budget` (14 POI attivi web, 10 mobile).
4. **Geometria**: mai dentro `safeRadius`, mai sulla `safeRoute`, mai in acqua,
   mai a bloccare un POI del gate.
5. **Accessibilità**: dialoghi leggibili al contrasto elevato, nessun
   avanzamento a tempo, macchina da scrivere disattivata con riduzione del
   movimento, tutto raggiungibile a tocco senza tastiera.
6. **Lingua**: fascia 10–13, frasi brevi, lessico concreto. Nessun abitante usa
   termini tecnici che il Codex non abbia già introdotto.

### 7.4 Audit da scrivere

| Audit | Verifica |
|---|---|
| `npc_catalog_audit.gd` | 2 residenti per mondo; ogni residente ha ruolo/tic/convinzione/bisogno/3 stadi; ≥12 battute; id unici; nessun tic duplicato nello stesso mondo |
| `dialogue_audit.gd` | Nessuna battuta oltre il limite di caratteri; nessun duplicato in un pool; anti-ripetizione efficace su 200 estrazioni; determinismo a parità di seed |
| `world_life_audit.gd` | Ogni mondo ha ≥1 conversazione per stadio; abitanti mai in acqua/`safeRadius`/`safeRoute`; ≤4 attivi; le notizie decadono |
| `building_audit.gd` | 3 edifici per mondo con ruoli distinti; Rovina allineata al landmark eroe; nessuna collisione con POI del gate |
| `mystery_audit.gd` | 24 Tracce raggiungibili; le 3 decisive hanno il beat di fallback; arco completo |
| `giveaway_audit.gd` (estensione) | Nessuna battuta contiene la risposta di un esercizio |

---

## 8. Piano di lavoro

Ordine pensato perché **ogni fase sia spedibile da sola** e il gioco resti
giocabile in ogni momento.

| Fase | Contenuto | Verificabile con |
|---|---|---|
| **A1 · Ossatura** | `dialogue_box.gd`, `npc_actor.gd`, `npc_catalog.gd` con il **solo mondo 1**, 2 residenti, 12 battute a testa | Si parla con Tobia ed Ersilia; il resto del gioco invariato |
| **A2 · Proprietà delle missioni** | `ownerNpc` sugli eventi, flusso richiesta → svolgimento → ritorno | `npc_catalog_audit`, gate 1→2 invariato |
| **A3 · Edifici** | `building_catalog.gd`, 3 ruoli, mondo 1 + finestre per stadio | `building_audit`, screenshot |
| **A4 · Itineranti** | I 6 personaggi ricorrenti, rotazione, Vera e «rispiegamelo» | Ritenzione registrata in `spaced_repetition` |
| **A5 · Vita di mondo** | Routine, notizie, conversazioni al Ritrovo (mondo 1, 3 stadi) | `world_life_audit` |
| **A6 · Estensione ai 24 mondi** | Cast, edifici, conversazioni, Tracce | Tutti gli audit + playthrough |
| **A7 · Mistero e finale** | Tracce nel Codex, beat riscritti, convergenza al Cuore | `mystery_audit`, `world_wave_e2_audit` |

Fase A1 è deliberatamente piccola: serve a vedere **subito** se parlare con
qualcuno cambia davvero la sensazione del gioco, prima di scrivere 54 personaggi.
