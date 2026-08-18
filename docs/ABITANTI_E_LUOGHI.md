# Eli Quest — Abitanti, dialoghi e luoghi

> Specifica del **mondo abitato**: chi vive nei 24 mondi, come parla, come
> assegna le missioni, come i personaggi si parlano tra loro e come gli edifici
> raccontano la storia.
> Trama e colpi di scena in [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md), loop e gate
> in [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md), compagno in
> [PET_CUSTODE.md](PET_CUSTODE.md), gioco sbloccato in
> [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md).
>
> Gli abitanti **portano i semi dei colpi di scena**: la filastrocca di nonna
> Ersilia nel mondo 1 contiene il nome cancellato del Tredicesimo, e le battute
> di Cinabro fanno da falsa pista per quattro atti. Chi scrive dialoghi deve
> tenere aperto [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md) §3.
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
| **Bislacchi** | 1 per mondo (24) | Uno solo mondo, di passaggio | **Comicità pura.** Nessun carico didattico, 4–6 battute, esistono per far ridere |
| **Itineranti** | 6 in totale | Ovunque, a rotazione | Continuità affettiva: gli amici che ritrovi. Ricordano cosa hai fatto altrove |
| **Voci (i Maestri)** | 12 | Solo nella nave | Non camminano: sono le inflessioni di NORA (vedi TRAMA §7) |

Budget: **massimo 4 abitanti attivi contemporaneamente** in scena (2 residenti +
1 itinerante + 1 bislacco). Rientra nel `performance_budget` esistente usando lo
stesso streaming dei POI: fuori dal `streamRadius` un abitante non è istanziato.

**Perché i Bislacchi sono un anello a sé.** Se ogni personaggio del mondo ha una
convinzione sbagliata e un arco di crescita, il gioco diventa monotono anche
essendo scritto bene: tutti parlano allo stesso modo, tutti *significano*
qualcosa. Il Bislacco non significa niente. Fa ridere e se ne va. Costa 4–6
battute e vale come il doppio dei residenti per la sensazione di mondo vivo.
Esempi: **Puccio** (mondo 1) è convinto che i cristalli siano suoi parenti e li
saluta per nome, tutti e quaranta; **Zufolo** (mondo 6) cerca da anni la nota che
gli ha rubato il cappello.

### 2.1 Anatomia di un residente

Ogni residente si autora con **sei campi**. Sono pochi di proposito: la varietà
nasce dalla combinazione, non dalla quantità di testo.

| Campo | Cos'è | Perché |
|---|---|---|
| `ruolo` | Cosa fa nel mondo | Lo lega all'identità del mondo |
| `registro` | **Il tono**: curioso, misterioso, buffo, divertente, caloroso, burbero, solenne, sognante | Impedisce che 48 personaggi suonino tutti uguali |
| `tic` | Un intercalare, un modo di chiamare Eli, un gesto ricorrente | È il trucco di Animal Crossing: rende memorabile un personaggio con 10 battute |
| `convinzione` | **Un'idea sbagliata reale** sulla materia | È il gancio didattico: la stessa misconcezione che ha il giocatore |
| `radice` | **La scena precisa o l'abitudine che ha generato la convinzione** — non «perché sì», ma un episodio concreto | Trasforma un errore in una storia. Senza radice, la correzione è un cambio di opinione; con la radice, è un personaggio che smette di proteggersi da qualcosa di specifico |
| `bisogno` | Cosa chiede a Eli | Diventa il motivo della missione |
| `arco` | Come cambia in 3 stadi | Rende visibile che il mondo evolve |

La `convinzione` è il cuore didattico: ognuno sbaglia **come sbagliano i
bambini**, e vederlo cambiare idea è il modello di ciò che sta succedendo al
giocatore. Il `registro` è il cuore *piacevole*: senza, il cast diventa una fila
di casi clinici. La `radice` è ciò che tiene lontana la banalità: una
convinzione senza origine è un'etichetta («Tobia conta lento perché è pignolo»);
una con origine è una persona («Tobia conta a uno a uno perché una volta ha
sbagliato un conto a occhio e ha pagato lui la differenza»). Non va mai detta
tutta in una battuta — si intuisce da una riga, non da un monologo — ma chi
scrive il personaggio deve saperla, anche se il giocatore non la sentirà mai per
intero.

**Vale anche per i Testimoni**, che non hanno una convinzione da correggere ma
custodiscono un sapere senza saperlo: la loro radice è **come** l'hanno
ricevuto (una canzone di famiglia, un mestiere tramandato, un'abitudine di
lavoro) — non una scena di errore, ma una scena di trasmissione. §3.2 mostra il
formato completo su un mondo pilota.

### 2.2 Gli otto registri, e la regola di mescolanza

| Registro | Come parla | Esempio dal cast |
|---|---|---|
| **Curioso** | Fa domande, si entusiasma, interrompe | Vera, Zeno (7), Pila (15) |
| **Misterioso** | Dice meno di quanto sa, risponde di sbieco | Cinabro, Doria (8), Fondo (22) |
| **Buffo** | Involontariamente comico. Non sa di esserlo | Sesto, tutti i Bislacchi, Puccio (1) |
| **Divertente** | Comico di proposito, prende in giro con affetto | Nima, Marco dei Valichi (16), Bea (18) |
| **Caloroso** | Accoglie, incoraggia, offre da mangiare | Nonna Ersilia (1), Lucilla, Mirta (10) |
| **Burbero** | Brontola, poi aiuta comunque | Orsolo, Numa (19), Coral (17) |
| **Solenne** | Parla come se ogni frase contasse | Livia (7), Cronia (23), Oreste (6) |
| **Sognante** | Distratto, poetico, altrove | Duna (13), Fiorina (19), Ambra (6) |

**Regola vincolante di mescolanza** (verificata da `npc_catalog_audit`):

1. I due residenti di un mondo hanno **registri diversi**, e mai entrambi
   «solenne».
2. Ogni mondo ha **almeno un personaggio che fa ridere** — il Bislacco basta.
3. Su tre mondi consecutivi non si ripete la stessa coppia di registri.
4. Ogni registro compare **almeno due volte** nell'arco dei 24 mondi: nessuno è
   decorativo.
5. Un registro cambia **come** dice le cose, mai **cosa** insegna. Un buffo e un
   solenne che spiegano lo stesso concetto lo spiegano ugualmente bene.

Il registro governa anche i parametri di resa: velocità del testo, ampiezza
dell'animazione di idle, suono della voce (bip in scala), pausa prima di
rispondere. Otto registri × un pool di battute danno otto personaggi percepiti
al costo di uno.

### 2.3 I tre stadi di relazione

Non si comprano, non si regalano oggetti. Avanzano su ciò che Eli **impara**.

| Stadio | Si sblocca quando | Cosa cambia |
|---|---|---|
| **0 · Gesto vuoto** | ingresso nel mondo | Ripete il rituale senza senso; dialoghi brevi, un po' persi |
| **1 · Dubbio** | superata la prima missione di sua proprietà | Comincia a fare domande; ti chiama per nome; il suo edificio si accende in parte |
| **2 · Capito** | gate del mondo pronto (missioni + mastery) | Ha cambiato idea; insegna a un altro abitante; l'edificio è pieno di vita |

Lo stadio 2 non richiede l'esame: si può ottenere prima di riparare l'apparato.
Così la ricompensa sociale arriva quando il giocatore ha fatto il lavoro, non
quando supera un test.

### 2.4 I sei itineranti

Sono il cast fisso, quello a cui ci si affeziona. Uno solo è presente in un mondo
alla volta (rotazione deterministica dal seed + livello), e ognuno ha una
**funzione di gioco** e un **registro** distinto: sono deliberatamente sei toni
diversi, così qualunque mondo tu apra c'è una compagnia che cambia colore.

| Nome | Registro | Chi è | Tic | Funzione di gioco |
|---|---|---|---|---|
| **Nima** | Divertente | Cartografa girovaga: baratta domande invece di merci, e le sue mappe sono bellissime e leggermente sbagliate | Ti chiama «capitana», e non smette nemmeno quando le spieghi che non lo sei | **Orientamento**: dice dove sono le cose e cosa non hai ancora visto |
| **Vera** | Curioso | Coetanea, apprendista di niente, vuole imparare tutto e subito | Finisce ogni battuta con una domanda, comprese quelle in cui rispondeva | **Consolidamento**: ti chiede di rispiegarle ciò che hai imparato (§5.3) |
| **Orsolo** | Burbero | Vecchio riparatore. Non crede alle «storie dei Primi» e lo ripete anche quando gliele dimostri | «Mah.» — e quando è d'accordo, «Mah» detto più piano | **Attrito**: mette in dubbio il mistero, obbliga a portare prove. Si converte lentamente e non lo ammetterà mai |
| **Sesto** | Buffo | Uno Sbiadito restituito a se stesso nel mondo 3. Dimentica, e ci scherza sopra prima che lo faccia qualcun altro | Scambia le parole: «passami il… coso che conta. Il conta-coso» | **Ripasso spaziato**: chiede aiuto proprio sugli argomenti che *tu* hai in scadenza |
| **Cinabro** | Misterioso | Narratore mascherato, baratta storie in cambio di fatti | Parla di sé in terza persona, e sbaglia apposta il nome | **Mistero e falsa pista**: sa troppo, ed è sempre nel mondo dove la spirale è più fresca. Il giocatore deve sospettare che sia lui a inciderle. Al colpo 6 si scopre che **lo è** — insieme ad altre centinaia |
| **Lucilla** | Caloroso | Alleva e cura i Custodi. Ha un'opinione molto forte su ogni pet e nessuna sulle persone | Parla al tuo Custode, non a te, e riferisce a te ciò che il Custode «ha detto» | **Compagno**: dà il primo Custode, apre la schermata del pet, commenta il legame |

Due note di regia sulla comicità, che è la cosa più facile da sbagliare:

- **Nessuno fa battute sul giocatore.** Si ride *con* Eli, mai di lei, e mai di
  un errore. Il bersaglio comico è sempre il personaggio stesso, un oggetto, o
  Orsolo.
- **Sesto è comico perché ci scherza per primo.** Un personaggio che dimentica
  potrebbe essere triste: lo è solo se il gioco lo tratta come un problema. Sesto
  arriva sempre prima con la battuta, e così la sua smemoratezza diventa il suo
  numero comico invece che la sua ferita. Regola vincolante per chi lo scrive.

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

### 2.5 La leggenda dell'Ingegnere

Un ottavo strato, trasversale a tutto il cast, deciso il 16 agosto 2026. **Non è
un ottavo colpo di scena** — non tocca `mystery_audit`, non ha semi da piantare,
non si risolve mai — è una **leggenda di paese**, del tipo che ogni comunità ha
su chi ha stabilito le regole prima che ci fosse qualcuno a ricordarlo. Qualcuno,
da qualche parte, chiama questa figura **l'Ingegnere**, e a volte, quando la
storia si scalda, **Paolo**.

**Cosa dice la leggenda, e perché nessuno la conferma**: prima ancora dei Primi
— prima delle dodici discipline, prima degli apparati, prima che ci fosse un
Silenzio da cui guarire — qualcuno avrebbe deciso *come* le regole del mondo
tengono insieme: perché sette per sette fa sempre quarantanove, perché una leva
lunga solleva un peso che le braccia da sole non muovono, perché una storia
raccontata due volte a due persone diventa due storie vere. Non un dio, non un
Primo, non un fantasma: un **artigiano delle regole**, di cui nessuno ha mai
visto il volto e di cui tutti hanno un'opinione diversa — e il gioco non prende
mai posizione su quale sia quella giusta.

**Perché esiste, in termini di scrittura**: dà a *ogni* personaggio, dal
Bislacco più stupido al residente più solenne, un secondo terreno su cui parlare
oltre alla propria materia — un terreno che appartiene al **registro**, non al
`ruolo`, e quindi è già scalabile a tutti i 76 abitanti senza scrivere 76
leggende diverse: si scrive **una leggenda per registro** (otto voci), e ogni
personaggio la dice a modo suo, filtrata dal proprio `tic`. È anche, non
dichiarato in gioco, un piccolo saluto a chi il gioco l'ha davvero progettato —
ma resta esattamente questo: un dettaglio per chi lo nota, mai una spiegazione,
mai qualcosa che il gioco confermi.

**Le otto voci** (pool condiviso, priorità 5 «Riempimento» di §5.2, **mai** più
di una su dieci estrazioni — deve restare un tesoro trovato, non un tormentone):

| Registro | Come suona la leggenda in quella voce |
|---|---|
| **Curioso** | Fa la domanda che nessuno si è fatto. *«Ma chi ha deciso che sette per sette fa quarantanove? Qualcuno l'avrà pur deciso — non è mica caduto già scritto dal cielo.»* |
| **Misterioso** | Dice meno di quanto lascia intuire. *«Non tutte le regole hanno un nome sopra. Alcune ce l'hanno, e qualcuno l'ha tolto apposta.»* |
| **Buffo** | Prende la leggenda e la rovina per errore, senza accorgersene. *«L'Ingegnere ha inventato pure la fatica. Bel lavoro. Proprio quello che serviva.»* |
| **Divertente** | La usa per prendere in giro qualcosa, con affetto. *«Se un giorno incontri l'Ingegnere, chiedigli perché il ponte numero tre stona di un tono. Sa di cosa parlo. Spero.»* |
| **Caloroso** | La addolcisce fino a farla sembrare una nonna che racconta. *«Le regole buone sono come il pane: non si vedono le mani che le hanno impastate, ma si sente la pazienza.»* |
| **Burbero** | La respinge, poi lascia una crepa. *«Mah. Se uno ha progettato davvero tutto questo, poteva pensarci meglio alle scale del molo. — Anche se, quando una cosa funziona senza che nessuno l'abbia riparata... quello sì che fa pensare.»* |
| **Solenne** | La tratta come reliquia, senza mai nominarla per intero. *«Non tutte le mani che costruiscono restano nella storia. Alcune scelgono di restare nella struttura.»* |
| **Sognante** | La sogna, letteralmente, invece di raccontarla. *«Ho sognato una stanza di fili di luce, e qualcuno che ne annodava due dicendo "ecco, ora reggono insieme". Non ricordo il viso. Ricordo il nodo.»* |

**Regole vincolanti**, verificate da `dialogue_audit` (estensione, §7.4):

1. **Mai nei 24 beat, mai in un colpo di scena, mai in una Traccia.** Vive solo
   nel riempimento degli abitanti. `mystery_audit` non deve mai vederla.
2. **Non si risolve mai.** Nessun personaggio, per nessun motivo, conferma o
   smentisce che l'Ingegnere sia reale, sia uno dei Primi, sia il Tredicesimo o
   sia qualcun altro. È tenuta aperta con la stessa disciplina della Cattedra
   Vuota (TRAMA §4.4) — anzi, di più: quella almeno viene inquadrata da tre
   tesi; questa resta un pettegolezzo di paese, e deve restarlo.
3. **Il nome «Paolo» esce raramente e mai da un registro solenne o misterioso**:
   quei due lo chiamano sempre «l'Ingegnere». È buffo, divertente, caloroso o
   sognante a nominarlo per nome — perché un nome proprio, detto con affetto o
   con leggerezza, è un gesto informale, e i registri seri non lo permettono a
   se stessi.
4. **Ogni personaggio la dice al massimo una volta per partita nel proprio
   pool**, con il proprio tic dentro (Sesto scambia le parole anche qui, Nima
   chiama Eli «capitana» anche qui): non è un testo a parte, è dialogo del
   personaggio come tutto il resto.
5. **Zero effetto meccanico.** Nessuna missione, nessun oggetto, nessun indizio
   verificabile ne discende. Se un audit trovasse un collegamento a `mystery`,
   `gate` o `mastery`, sarebbe un bug di scope.

Esempi personalizzati (mostrano come una voce di registro diventa specifica sul
personaggio, non generica): §3.2 per il mondo 1 e per i sei itineranti.

**Implementazione (16 agosto 2026)**: i dati vivono in
`godot/scripts/game/engineer_legend_catalog.gd` (le otto voci, un pool per
registro), verificati da `engineer_legend_audit.gd` — entrambi scritti e
**verdi**: 8 registri, 24 righe, «Paolo» confinato a buffo/divertente/caloroso,
nessuna riga tocca i termini del mistero vero (Primi, NORA, Tredicesimo, Scala,
Meridiana, Silenzio).

**Agganciata ai sei itineranti, stessa data.** `outdoor_world.gd`, nel ramo che
compone le battute di un itinerante (dove oggi mescola `saluto` +
`funzione`/`dubbio` + `riempimento` + `congedo`), aggiunge in coda **una sola**
riga presa da `EngineerLegendCatalog.for_registro()`, scelta in modo
deterministico da `hash(npc_id)` — stesso personaggio, stessa riga, sempre.
Su un totale di dieci-quattordici battute per itinerante, un solo elemento
aggiunto mantiene la rarità prevista (§2.5, «massimo 1 estrazione su 10») senza
bisogno di un contatore a parte: la stessa rotazione a cursore che sceglie le
altre battute la sceglie di rado, per costruzione. Verificato da
`engineer_legend_wiring_audit.gd` (il contratto: ogni itinerante trova una voce
per il proprio registro, la riga è ben formata, e non coincide con una battuta
già autorata per quel personaggio).

**Non ancora agganciata ai 46 residenti né ai 23 Bislacchi.** Per i residenti
il punto naturale sarebbe lo stesso `riempimento` letto da
`_open_npc_dialogue` (circa riga 2950) — ma verificato che oggi quel ramo **non
si attiva mai**: `pools.get("stadio%d" % stage, pools.get("riempimento", []))`
trova sempre la chiave `stadioN` (0/1/2 esistono per ogni residente, garantito
da `npc_catalog_audit`), quindi il ramo di ripiego `riempimento` è
strutturalmente irraggiungibile. È un difetto preesistente e indipendente da
questo lavoro — il `riempimento` scritto per i residenti (es. i tre di Tobia
sui cristalli che crescono di notte) non viene mai mostrato in gioco — e va
riparato separatamente prima o assieme all'aggancio della leggenda lì.

---

## 3. Il cast dei 24 mondi

Formato: **Specialista** (ha la convinzione sbagliata) · **Testimone** (sa senza
sapere di sapere, e indica la Rovina). In corsivo la convinzione da smontare.

### Atto I — Chi accende

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **1 · Radura Accademia · matematica** | **Tobia**, conta i cristalli uno per uno. Tic: chiude le frasi con «…e uno». *«Contare in fretta è barare.»* | **Nonna Ersilia**, canta una filastrocca che è la tabellina del 7 e non lo sa. **Nella conta ci sono tre sillabe senza senso che nessuno ha mai capito** | Bastone da conteggio dei Primi, tacche a gruppi di dieci: «contare in gruppi non è pigrizia, è vedere lontano» |
| **2 · Archivio delle Parole · italiano** | **Corinna**, ordina le parole per lunghezza. Tic: misura tutto con le dita. *«L'ordine giusto è quello che si vede.»* | **Bruno**, bambino che inventa parole e viene sgridato — ha ragione lui | Catalogo dei Primi ordinato per **funzione**, non per forma |
| **3 · Cratere Logico · coding** | **Ruggine**, riavvia la macchina a mano ogni giro. Tic: soffia sugli attrezzi. *«I cicli sono per i pigri.»* | **Sesto**, lo Sbiadito che qui torna se stesso e poi ti segue ovunque | Schema di telaio: «ripetere non è fatica, è un'istruzione» |
| **4 · Baia dei Segnali · inglese** | **Marea**, ripete i messaggi senza capirli per paura di sbagliare. Tic: sussurra prima di parlare. *«Capire è tradurre parola per parola.»* | **Vecchio Lino**, pescatore con venti parole d'inglese e zero timidezza | Quaderno bilingue dei Primi: la stessa lezione in due lingue affiancate |
| **5 · Officine del Moto · fisica** | **Gerbo**, sposta i massi a forza bruta. Tic: si sputa sulle mani. *«Le leve sono trucchi da deboli.»* | **Tilla**, ha capito il fulcro sull'altalena e nessuno le dà retta | ⟡ **Colpo 1** — la spirale aperta, e il taglio è **fresco di settimane**: «chi solleva con la testa non è meno forte» |
| **6 · Giardino della Risonanza · musica** | **Ambra**, accorda a orecchio benissimo, non sa nominare un intervallo. Tic: canticchia le risposte. *«Dare un nome alla musica la rovina.»* | **Oreste**, sordo, legge la musica con le mani sulle corde | Diapason dei Primi: «un suono con un nome si può regalare a qualcuno» |
| **7 · Rovine dei Glifi · latino** | **Livia**, la migliore copista: copia perfettamente senza leggere. Tic: soffia sull'inchiostro. *«Copiare bene è già capire.»* | **Zeno**, gioca a «trova la parola parente» e indovina i significati | Dizionario delle radici: una radice per pagina, i suoi discendenti sotto |
| **8 · Delta dei Circuiti · elettronica** | **Ciro**, collega i cavi a memoria; se lo schema cambia si blocca. Tic: conta i nodi a voce. *«Basta ricordare lo schema giusto.»* | **Doria**, guardiana delle chiuse: capisce la corrente per analogia con l'acqua | ⟡ **Colpo 2** — sigillo d'equipaggio: **tredici** posti, **undici** nomi, uno raschiato con una lama dall'interno e uno **mai inciso** |

### Atto II — Chi ha taciuto

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **9 · Arcipelago Cartografico · geografia** | **Alma**, disegna solo ciò che ha visto. Tic: bagna la matita. *«I numeri non sono posti.»* | **Remo**, traghettatore che sta perdendo la memoria delle rotte e vuole scriverle | Carta della rotta della nave: non una fuga, un **giro** che si ripete |
| **10 · Serra delle Simbiosi · scienze** | **Ortensia**, quando un esperimento fallisce cambia tre cose insieme. Tic: parla alle piante. *«Se cambio tutto, prima o poi funziona.»* | **Mirta**, quarant'anni di diario di osservazioni senza sapere che è scienza | Le provviste chiuse con ordine e gli appunti impilati: nessuno è stato sorpreso |
| **11 · Soglia del Tempo · storia** | **Danio**, data i reperti «a occhio» e crede alla prima storia che sente. Tic: scommette su tutto. *«Se lo dicono tutti, è vero.»* | **Vesta**, custodisce due cronache che si contraddicono e non sa quale bruciare | Due datazioni discordanti del Silenzio — nessuna delle due va bruciata |
| **12 · Labirinto delle Regole · logica** | **Quinto**, sa il percorso a memoria; se i muri si spostano è perduto. Tic: conta i passi. *«Ricordare la strada è saperla.»* | **Isa**, segna i bivi con un filo: ha inventato il metodo da sola | ⟡ **Colpo 3** — la scheda di NORA (allieva n.1) e accanto **altre dodici schede numerate**. La tua è la dodici |
| **13 · Deserto delle Orbite · matematica** | **Solano**, misura tutto e non stima mai; senza strumenti è paralizzato. Tic: pulisce le lenti. *«Stimare è tirare a indovinare.»* | **Duna**, indovina le distanze a occhio e crede sia un dono, non un metodo | Un registro di manutenzione con **undici voci cancellate** e la dodicesima aperta oggi |
| **14 · Biblioteca delle Voci · italiano** | **Elmo**, riassume tutto in una frase e perde il punto di vista. Tic: taglia l'aria con la mano. *«Se so come finisce, ho capito.»* | **Ottavia**, racconta di mestiere la stessa storia da tre prospettive | I verbali della seduta: la tredicesima voce **propone** la chiusura e convince i dodici in un'ora |
| **15 · Città Macchina · coding** | **Gru**, riavvia invece di leggere l'errore. Tic: dà un colpetto alle macchine. *«L'errore è solo sfortuna.»* | **Pila**, bambina con un quaderno di tutti i guasti e le cause: ha inventato il log | Le sezioni della nave che non tornano: **un volume senza porta**, alimentato da quattro secoli |
| **16 · Frontiera delle Lingue · inglese** | **Talia**, interprete che traduce alla lettera e crea equivoci. Tic: si scusa sempre. *«Ogni parola ha una sola traduzione.»* | **Marco dei Valichi**, commercia in sei lingue con cento parole ciascuna | ⟡ **Colpo 4** — la mappa vera della nave, e sedici mondi di deviazioni di NORA attorno a una stanza sola |

### Atto III — Chi continua

| # · Mondo · Materia | Specialista | Testimone | Traccia (nella Rovina) |
|---|---|---|---|
| **17 · Oceano delle Forze · fisica** | **Nerea**, palombara, scende sempre più giù «a sentimento». Tic: trattiene il fiato mentre parla. *«Il corpo sa da solo quanto reggere.»* | **Coral**, ha smesso di scendere e sa dire esattamente perché: fa i conti | Le insegne sbiancate del molo riempite da sole con una parola sola: **FERMATI** |
| **18 · Cattedrale del Suono · musica** | **Silo**, organista che suona solo forte. Tic: conta il riverbero. *«Il piano qui non si sente.»* | **Bea**, canta nei punti giusti della navata: ha mappato l'eco | Il turno di guardia del Tredicesimo: quattrocento anni, **nessun cambio** |
| **19 · Necropoli delle Radici · latino** | **Numa**, epigrafista: considera le parole moderne «corrotte». Tic: lucida le lapidi. *«La lingua di prima era quella giusta.»* | **Fiorina**, chiama le piante con nomi antichi senza sapere che lo sono | ⟡ **Colpo 5a** — il progetto di NORA, firmato dal tredicesimo posto. **È lui che l'ha costruita** |
| **20 · Tempesta Elettromagnetica · elettronica** | **Sferza**, quando un sensore sbaglia alza la potenza. Tic: batte le nocche sui quadri. *«Se non legge, spingi di più.»* | **Quieto**, legge i lampi e prevede la scarica | ⟡ **Colpo 5b** — quattro secoli di misure della quarantena, e la curva che **sta cedendo adesso** |
| **21 · Atlante Fratturato · geografia** | **Terza**, studia un clima alla volta e non vede il sistema. Tic: allinea i fogli. *«Ogni posto fa storia a sé.»* | **Mino**, pastore con un calendario tramandato che è un modello climatico | La tesi di Scala per esteso: il Silenzio come **sottoprodotto** del sapere che passa di mano senza essere capito |
| **22 · Biosfera Profonda · scienze** | **Vesca**, cerca l'organismo «più forte». Tic: annusa tutto. *«Vince sempre il più forte.»* | **Fondo**, guida delle caverne: conosce ogni nicchia e chi ci vive | Archivio o viaggiatore: la domanda lasciata a NORA da un Maestro, mai risposta |
| **23 · Sala delle Ere · storia** | **Cronia**, conserva solo la versione ufficiale. Tic: timbra tutto. *«Le fonti scomode confondono.»* | **Ovidio**, copista: le ha conservate di nascosto per quarant'anni | ⟡ **Colpo 6** — il registro del mondo 2: **Meridiana, allieva locale, undici anni**, partita verso il centro del Silenzio e **mai tornata — né mai registrata come perduta**. E le quattrocento spirali dopo di lei, di mani tutte diverse |
| **24 · Cuore dei Primi · trasversale** | *Nessun nuovo residente*: al Cuore convergono i sei itineranti e i residenti portati allo stadio 2 (max 4 in scena a rotazione) | — | ⟡ **Colpo 7** — undici quaderni di NORA, uno per sorella, pieni di risposte date. Il dodicesimo è **vuoto** |

---

### 3.1 I ventiquattro Bislacchi

Uno per mondo, 4–6 battute, zero carico didattico. Non hanno arco, non hanno
convinzioni da correggere, non danno missioni. Esistono perché un mondo in cui
tutti hanno una lezione da imparare è un mondo faticoso.

| Mondo | Bislacco |
|---|---|
| 1 | **Puccio** saluta i cristalli per nome. Tutti e quaranta. Se lo interrompi ricomincia |
| 2 | **Ditino** ha inventato una parola nuova e adesso non ricorda cosa voleva dire |
| 3 | **Manetta** dà istruzioni precise a una macchina spenta da secoli. La macchina, dice, è timida |
| 4 | **Boa** risponde a tutti i segnali radio, anche quelli non diretti a lui. Soprattutto quelli |
| 5 | **Peso** solleva cose che non vanno sollevate per allenarsi a sollevare cose |
| 6 | **Zufolo** cerca da anni la nota che gli ha rubato il cappello |
| 7 | **Postilla** corregge le iscrizioni antiche con annotazioni sue. Nessuna è pertinente |
| 8 | **Scintilla** si presenta come «il capo di questa palude». Non c'è nessuna palude |
| 9 | **Bora** disegna mappe di posti che deve ancora inventare |
| 10 | **Terriccio** ha dato un nome a ogni foglia e adesso ha un problema di memoria |
| 11 | **Anticaglia** vende reperti falsissimi con una passione commovente |
| 12 | **Svolta** entra nel labirinto ogni mattina per «tenerlo in esercizio» |
| 13 | **Miraggio** giura di aver visto qualcosa. Non ricorda cosa. Ma era enorme |
| 14 | **Prefazio** racconta solo l'inizio delle storie. Dice che il resto è ovvio |
| 15 | **Ronzino** è convinto di essere un automa e nessuno ha il coraggio di dirglielo |
| 16 | **Tuttolingue** parla una lingua che ha inventato lui e si stupisce che nessuno la sappia |
| 17 | **Scafandro** ha paura dell'acqua e fa il palombaro per orgoglio |
| 18 | **Controcanto** canta sempre mezzo tono sotto e ne è fierissimo |
| 19 | **Lapidario** legge le epigrafi ad alta voce come se fossero notizie del giorno |
| 20 | **Parafulmine** aspetta di essere colpito da un fulmine per «vedere l'effetto che fa» |
| 21 | **Meteora** prevede il tempo di ieri con precisione impressionante |
| 22 | **Muffa** ha allevato una colonia di funghi e li considera colleghi |
| 23 | **Errata** timbra documenti a caso «per portarsi avanti» |
| 24 | **Tutti quanti** — al Cuore i Bislacchi che hai incontrato arrivano insieme, e sono il momento più assurdo e più caldo del gioco |

### 3.2 Approfondimenti pilota: radici e leggenda su un mondo e sul cast fisso

Scrivere `radice` e leggenda dell'Ingegnere per 76 abitanti in un colpo solo
produce testo debole: la profondità si vede riscrivendo bene un caso, non
abbozzandone settanta. Questa sezione è l'**implementazione di riferimento** —
mondo 1 per intero, i sei itineranti per intero — da cui la Fase A6 (§8) estende
lo stesso livello di cura ai restanti 23 mondi, un mondo alla volta.

#### Mondo 1 · Radura Accademia

**Tobia** (Specialista, matematica) — registro **burbero** *(nuovo: mancava in
§2.2, colmato qui)*.

- `radice`: conta le casse di cristallo per il mercato di suo padre da quando
  ha otto anni. Una volta ha stimato «circa quaranta» a occhio invece di
  contare: erano trentasette, e la differenza l'ha pagata suo padre, in
  silenzio, senza rimproverarlo — il che è stato peggio di un rimprovero.
  Da allora conta a voce alta, uno per uno, davanti a chiunque, non per
  pignoleria ma perché **un numero detto ad alta voce non si può più
  cambiare in corsa**. Scambia la lentezza per l'unica forma di onestà che
  conosce.
- `bisogno`: essere creduto quando dice un numero.
- Stadio 0: *«Quaranta casse. Le riconto. Uno, due, tre… e uno. Non
  interrompere un conteggio serio: se parli, ricomincio.»*
- Stadio 1 (dopo la sua missione): *«Ho contato a gruppi di cinque, come hai
  fatto tu. Stesso numero. Meno fiato. Non mi fido ancora del tutto — ma non
  mi fido nemmeno di dire che avevi torto.»*
- Stadio 2: *«Contare in gruppi non è barare, è vedere più lontano — me l'hai
  fatto vedere tu. Ora tocca a me spiegarlo a mia nonna, che canta senza
  sapere di contare.»*
- Reazione (apparato riparato): *«Ho ricontato le casse del mercato in un
  terzo del tempo, stesso numero di sempre. Mio padre non ci credeva: l'ho
  fatto ricontare a lui, a uno a uno. Ha impiegato il triplo. Non gli ho detto
  "…e uno". Ma ci ho pensato forte.»*
- Riempimento: *«Sai qual è il numero più onesto che esista? Il resto di una
  divisione. Non mente mai, nemmeno quando la divisione bara.»*
- Leggenda dell'Ingegnere (burbero, personalizzata): *«L'Ingegnere. Mah. Se ha
  inventato lui i numeri, poteva fermarsi prima delle tabelline del sette.
  Quelle non entrano mai in testa bene, e uno.»*

**Nonna Ersilia** (Testimone) — registro **caloroso** (già in §2.2).

- `radice`: la conta gliel'ha insegnata sua nonna durante un inverno di
  raccolti magri, quando cantare insieme mentre si lavorava rendeva le ore più
  corte. Non gliel'ha mai spiegata: gliel'ha **fatta cantare** finché non è
  diventata automatica. Ersilia l'ha tramandata allo stesso modo, per lo
  stesso motivo, senza sapere che dentro c'è un metodo — e senza sapere cosa
  significhino tre sillabe, verso la fine, che canta comunque per rispetto.
- `bisogno`: qualcuno che ascolti la canzone fino in fondo, non solo il
  ritornello.
- Stadio 0: *«Vieni, tesoro, siediti. Sette, quattordici, ventuno… La canto da
  quando ero bambina io. Non so nemmeno più cosa voglia dire.»*
- Stadio 1: *«Tobia dice che la mia canzone è un modo di contare. Io la canto
  e basta, da sempre. Chissà, magari mia nonna sapeva cose che io ho solo
  imparato a memoria.»*
- Stadio 2: *«…ventotto, trentacinque. Lo sapevo fare, tesoro, e non sapevo di
  saperlo. C'è una parte strana, verso la fine — tre sillabe che non vogliono
  dire niente. Le ho sempre cantate lo stesso, per rispetto a chi me le ha
  insegnate.»*
- Leggenda dell'Ingegnere (caloroso, personalizzata): *«Mia nonna diceva che
  il mondo l'ha impastato qualcuno con santa pazienza, tesoro, come il pane.
  Chiamalo Ingegnere, chiamalo nonno di nessuno: io gli sono grata lo stesso,
  chiunque sia stato.»*

**Puccio** (Bislacco) — un assaggio di come la leggenda rende comico anche chi
non ha nessun arco:

- *«Ehi, Cristallo numero ventisette, lo sapevi? Dicono che ci ha fatti tutti
  l'Ingegnere. Tutti e quaranta, uno per uno. Bella fatica, eh? — No, non
  rispondermi, lo so che non parli. Però annuisci sempre uguale, e mi va bene
  lo stesso.»*

#### Il cast fisso: i sei itineranti

Sono il cast a cui il gioco chiede più affetto — «Vera è il personaggio più
importante dopo NORA» (§2.4) — quindi sono anche il primo posto dove la
`radice` deve reggere un bambino che li rivede in tutti e ventiquattro i mondi.

**Vera** — non è curiosità gratuita: è la più piccola di una famiglia di
apprendisti, sempre arrivata dopo che gli altri avevano già imparato, sempre in
rincorsa. Chiedere tutto e subito non è impazienza: è la paura di restare
indietro un'altra volta. Sotto le sue domande a raffica c'è questo, e non va
mai detto — va solo intuito da una battuta come questa:
- *«Ma l'Ingegnere — quello vero, se esiste — ha mai sbagliato qualcosa? Perché
  se non ha mai sbagliato niente, io non mi fido. Chi non sbaglia mai non ha
  ancora provato abbastanza cose.»*

**Orsolo** — non nega le storie dei Primi per ottusità: da apprendista credette
a una leggenda simile su un riparatore leggendario capace di aggiustare
qualunque cosa senza pezzi di ricambio, ci costruì sopra mesi di lavoro sbagliato,
e imparò a proprie spese che una bella storia e un fatto vero si assomigliano
troppo per fidarsi a orecchio. Il suo scetticismo è una cicatrice, non un
carattere.
- *«L'Ingegnere che ha progettato tutto quanto. Certo. E io sono il fratello
  segreto di un Primo. Mah. — Anche se, quando una cosa funziona bene senza
  che nessuno l'abbia riparata da anni... quello sì che mi fa dubitare.»*

**Sesto** — la sua smemoratezza da Sbiadito non cancella i fatti: cancella **chi
gliel'ha insegnati**. Ricorda la tabellina, non il viso di chi gliela disse.
È il tipo di dimenticanza più gentile e più triste che il gioco possa dare a un
personaggio comico, ed è per questo che deve arrivare sempre con la battuta
prima che qualcun altro se ne accorga (regola vincolante, §2.4):
- *«L'Ingegnere ha progettato tutto il... il conta-coso. No, aspetta: il
  coso-conta. Comunque, bel lavoro, chiunque sia stato. Peccato non ricordi se
  l'ho già ringraziato o no.»*

**Cinabro** — parla di sé in terza persona perché è più facile mentire a un
nome che a se stessi. La sua leggenda dell'Ingegnere è l'unica che sfiora
davvero il tema del gioco, senza mai confermarlo:
- *«L'Ingegnere non è un nome, dice chi lo racconta. È un posto vuoto che
  qualcuno continua a riempire, uno dopo l'altro. Cinabro lo sa. Cinabro non lo
  dice a Cinabro, nemmeno di notte.»*

**Lucilla** — ha un'opinione su ogni Custode e nessuna sulle persone perché da
bambina, in una casa sempre piena, gli animali erano l'unica compagnia che non
giudicava e non se ne andava mai delusa. Non è freddezza verso la gente: è che
con gli animali ha imparato per prima a fidarsi, e non ha più avuto bisogno di
disimparare.
- *«Il tuo Custode dice che l'Ingegnere gli piacerebbe, se esistesse. Dice che
  chi progetta bene le cose, ama anche chi ci vive dentro. Non parla mai a
  caso, il tuo Custode.»*

**Nima** — le sue mappe sono «bellissime e leggermente sbagliate» non per
pigrizia: una volta disegnò una carta perfetta al centimetro e nessuno la
guardò due volte. Da allora sacrifica un po' di esattezza per la sensazione del
posto — il fiume non è mai esattamente lì, ma *sembra* di sentirlo scorrere.
È l'unica del cast fisso a scegliere consapevolmente il fascino sopra la
precisione, ed è un bel contrappunto silenzioso a un gioco che insegna il
contrario.
- *«Capitana, si dice che l'Ingegnere abbia disegnato la prima mappa di tutte,
  perfetta al millimetro. La mia la faccio a occhio. È più simpatica. Anche se
  il fiume, quello, non è proprio lì.»*

### 3.3 Regola d'estensione ai restanti residenti già scritti

I 44 residenti oltre a Tobia ed Ersilia **esistono già** in
`godot/scripts/game/npc_catalog.gd`, spesso con un commento sopra
`convinzione` che è già, di fatto, una `radice` abbozzata (es. Tobia, riga
38–39 del file). Il lavoro che resta non è inventare 44 personaggi: è **rendere
esplicita e verificabile** la radice che molti hanno già in nuce, portandola al
livello di dettaglio di §3.2, e — dove il registro lo rende naturale —
aggiungere un accenno alla leggenda dell'Ingegnere dentro un `riempimento`
esistente, pescando dal registro giusto in `engineer_legend_catalog.gd` e
riscrivendolo con il tic del personaggio, non copiato parola per parola. La
leggenda **non** richiede scrittura nuova per personaggio oltre a questo: resta
scalabile per costruzione. I Testimoni e gli itineranti di §3.2 sono il metro
di paragone per il tono: mai una spiegazione intera, sempre un dettaglio che
lascia intuire il resto.

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

### 5.5 Regole anti-banalità

Il rischio più concreto con 76 abitanti non è che siano pochi: è che finiscano
per suonare **intercambiabili**, o peggio, che dicano cose vuote riempite di
punti esclamativi. Checklist vincolante per chi scrive o revisiona una battuta,
verificata a campione in `dialogue_audit`:

1. **Ogni battuta dice un fatto o mostra un carattere — mai le due cose a
   vuoto.** Se togliendola nulla cambia (né si impara qualcosa sul personaggio
   né sulla materia né sulla storia), va tagliata.
2. **Vietate le domande retoriche che restano senza eco.** «Non è
   meraviglioso?» non è una battuta, è un riempitivo. Se un personaggio fa una
   domanda, o la risposta arriva nella riga dopo, o il non-rispondere è
   caratterizzante (Cinabro, Orsolo) — mai le due cose a caso.
3. **L'umorismo viene dalla specificità, non dall'entusiasmo.** «Trentasette
   invece di quaranta» fa ridere/commuove; «un errore terribile!» no. Un
   numero, un oggetto, un dettaglio concreto valgono più di un aggettivo.
4. **Il mistero viene dall'omissione calcolata, non dalla vaghezza.** Un
   personaggio misterioso *sa una cosa precisa e non la dice tutta*; non
   parla semplicemente in modo confuso. Se una battuta «misteriosa» sparisse
   in un frullatore di sinonimi vaghi, va riscritta con un dettaglio vero
   dentro.
5. **Lista nera di frasi da bigliettino**, bandite senza eccezioni: «il sapere
   è la vera ricchezza», «insieme si può fare tutto», «ogni errore è
   un'opportunità» dette così, nude, senza un fatto sotto. Il gioco può
   *mostrare* queste idee (è il tema di NORA, è il tema del Codex), ma nessun
   personaggio le **pronuncia** come slogan.
6. **Il `tic` caratterizza, non riempie.** Va usato in almeno una riga su tre
   (§5.1) ma mai a fine riga come intercalare automatico senza motivo dentro
   quella riga specifica.
7. **Ogni personaggio con una `radice` (§2.1, §3.2) deve avere almeno una
   battuta che vi accenna senza spiegarla per intero.** Se la radice non
   traspare mai in nessuna battuta, esiste solo nella documentazione ed è
   sprecata.

---

## 6. La vita del mondo

È la parte che trasforma "personaggi collocati" in "mondo che evolve". Deve
restare **deterministica** (stesso seed + stesso stato = stessa vita) e a costo
quasi zero: nessuna simulazione, nessuna IA.

### 6.0 Dove stanno (16 agosto 2026)

**Il posto di un abitante viene da chi è**, non da un indice. Fino al 16 agosto
2026 il cast veniva distribuito su quattro ancoraggi fissi in un anello di
quattrocento pixel attorno allo sbarco: chiunque fossero, i quattro si trovavano
tutti nei primi dieci passi, e i loro luoghi — che il gioco già assegna per nome
in `BuildingCatalog._resident_owner` — restavano vuoti.

| chi | dove sta | perché |
| --- | --- | --- |
| specialista | Casa del mestiere | è il suo laboratorio: trovarcelo dentro spiega l'edificio senza una riga di testo |
| testimone | Ritrovo | è il luogo che presidia |
| Bislacco | fuori mano, 1180 px dallo sbarco, in un arco fra 28° e 66° deciso dal seme del mondo | incontrarlo dev'essere una piccola scoperta, non un saluto obbligatorio all'arrivo |
| itinerante | sulla strada, a metà della risalita verso la nave, dal lato opposto al Bislacco | è di passaggio: lo si incontra camminando |

Distanza minima fra due abitanti: **420 px** (era 150). Sotto quella soglia due
presenze si leggono ancora come un gruppo. `world_life_audit` verifica sia la
corrispondenza persona↔luogo sia la dispersione (nessuna coppia sotto 380 px,
almeno 900 px fra i due più lontani).

### 6.1 Routine

Ogni abitante ha **tre ancoraggi**: casa, lavoro, Ritrovo. La fase giorno/notte,
già presente, sceglie dove si trova. Si spostano con un cammino lento tra i punti
quando sono fuori inquadratura; in campo, si limitano a un'animazione di
occupazione (contare, martellare, scrivere).

Due precisazioni nate dal collaudo del 16 agosto 2026:

- **l'ancoraggio di lavoro è il proprio**, non la Casa del mestiere per tutti.
  Con un ancoraggio comune il capannello si riformava da solo anche dopo aver
  sparso il cast: lo specialista lavora alla Casa, il testimone al Ritrovo, il
  Bislacco gira attorno alla Rovina, l'itinerante resta sulla strada. Il Ritrovo
  è il solo momento in cui si radunano davvero, ed è giusto che sia l'unico:
  è la scena in cui si parlano fra loro;
- **il turno della gente ha un orologio suo**. La fase giorno/notte è ferma da
  quando il mondo nasce coperto e si illumina col lavoro fatto, quindi non poteva
  più muovere nessuno. `outdoor_world._turno_del_villaggio` scandisce lavoro
  (110 s) → Ritrovo (40 s) → riposo (34 s) senza toccare la luce.

### 6.1.5 Battute di passaggio

**Chi ti vede passare ti dice qualcosa.** Il difetto che questa parte ripara non
era il testo — registro, tic, convinzione e arco esistono per quarantasei
persone — era che quel testo usciva **solo aprendo un dialogo**: attraversando il
mondo un abitante era un birillo con un nome sopra, muto anche se gli passavi a
due passi dopo avergli rimesso in moto l'apparato.

Quando Eli arriva a 300 px, l'abitante dice **una riga sola**, presa dal suo
stesso catalogo: la prima schermata di una battuta, quindi con la sua voce e il
suo tic. Le regole servono a tenerla simpatica invece che molesta:

- parla **all'arrivo**, non finché resti lì (isteresi 300/470 px);
- un solo fumetto per volta nel mondo, con 4,5 s di pausa fra uno e l'altro;
- 26 s di riposo per persona, e il cursore avanza: la seconda battuta non è mai
  la prima;
- alterna riempimento e battute dello **stadio d'arco corrente** — passandogli
  davanti due volte si sente prima il colore, poi dove sta col suo cambiamento;
- **la notizia ha la precedenza sul colore**: se hai appena superato una prova,
  chi incontri commenta quello (pool `reazione`, una volta per persona per
  notizia). È il pezzo che li rende partecipi della storia invece che
  decorativi;
- tacciono mentre un pannello copre il mondo.

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

> **Aggiornato al 5 agosto 2026.** Questa tabella descriveva moduli previsti
> (`npc_director.gd`, `dialogue_director.gd`) che non sono mai stati scritti:
> la funzionalità è stata realizzata, ma distribuita diversamente. Qui sotto c'è
> dove vive **davvero**, non dove era stato progettato che vivesse.


| Modulo | Tipo | Responsabilità | Non fa |
|---|---|---|---|
| `npc_catalog.gd` | dati + logica di scelta | 46 residenti (i 2 del mondo 24 stanno in `finale_catalog.gd`) + 6 itineranti, con i 5 campi e i pool di battute; `owner_for()` assegna `ownerNpc` agli eventi, `mission_lines()` sceglie la battuta | Non tocca mastery, energia, gate |
| `mission_ownership_flow.gd` | logica pura | Stadio della relazione, richiesta accettata, esito, ritorno | Non scrive ricompense |
| `outdoor_world.gd` | scena | Chi è presente e dove: `_create_npc_actors()`, streaming, apertura dei dialoghi | — |
| `world_life.gd` | logica | Routine, notizie, conversazioni al Ritrovo | Nessuna simulazione continua |
| `building_catalog.gd` | dati | 3 edifici × 24 mondi: ruolo, posizione, artKit, stato | Non decide progressione |
| `dialogue_box.gd` | UI | Ritratto, testo, avanzamento, accessibilità | Non decide cosa dire |
| `npc_actor.gd` | scena | Presenza, routine, animazione di occupazione, area d'interazione | Non contiene testo |
| `engineer_legend_catalog.gd` | dati | Le otto voci della leggenda dell'Ingegnere (§2.5), una per registro | Non sceglie quando parlare — quello, quando sarà agganciata, è di chi seleziona il riempimento |

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
| `npc_catalog_audit.gd` | 2 residenti + 1 bislacco per mondo; ogni residente ha ruolo/registro/tic/convinzione/**radice**/bisogno/3 stadi; ≥12 battute (≥4 per un bislacco); id unici; nessun tic duplicato nello stesso mondo; **nessun residente con `convinzione` valorizzata e `radice` vuota** |
| ~~`register_mix_audit.gd`~~ → **dentro `npc_catalog_audit.gd`** | Le 5 regole di mescolanza di §2.2, tutte coperte dal 5 agosto 2026: registri diversi tra i due residenti; almeno un comico per mondo; nessuna coppia ripetuta su tre mondi consecutivi; ogni registro usato ≥2 volte; nessun registro che predice quanto materiale ha un personaggio (proxy misurabile della regola 5 — la qualità vera la giudica chi gioca) |
| `dialogue_audit.gd` | Nessuna battuta oltre il limite di caratteri; nessun duplicato in un pool; anti-ripetizione efficace su 200 estrazioni; determinismo a parità di seed; **pool «leggenda dell'Ingegnere» (§2.5): mai fuori dal riempimento, mai più di 1 estrazione su 10, «Paolo» per nome mai in bocca a un registro solenne o misterioso**; **lista nera di §5.5 assente da ogni pool** |
| `world_life_audit.gd` | Ogni mondo ha ≥1 conversazione per stadio; abitanti mai in acqua/`safeRadius`/`safeRoute`; ≤4 attivi; le notizie decadono |
| `building_audit.gd` | 3 edifici per mondo con ruoli distinti; Rovina allineata al landmark eroe; nessuna collisione con POI del gate |
| `mystery_audit.gd` | 24 Tracce raggiungibili; le 3 decisive hanno il beat di fallback; arco completo |
| `giveaway_audit.gd` (estensione) | Nessuna battuta contiene la risposta di un esercizio |
| `engineer_legend_audit.gd` | Il pool §2.5: 8 registri, «Paolo» confinato ai registri autorizzati, nessun termine del mistero vero |
| `engineer_legend_wiring_audit.gd` | L'aggancio ai sei itineranti: ogni registro trova una voce, la riga è ben formata, mai identica a una battuta già autorata |

---

## 8. Piano di lavoro

Ordine pensato perché **ogni fase sia spedibile da sola** e il gioco resti
giocabile in ogni momento.

| Fase | Contenuto | Verificabile con |
|---|---|---|
| **A1 · Ossatura** | `dialogue_box.gd`, `npc_actor.gd`, `npc_catalog.gd` con il **solo mondo 1**, 2 residenti, 12 battute a testa, **`radice` e leggenda dell'Ingegnere già incluse (§3.2)** | Si parla con Tobia ed Ersilia; il resto del gioco invariato |
| **A2 · Proprietà delle missioni** | `ownerNpc` sugli eventi, flusso richiesta → svolgimento → ritorno | `npc_catalog_audit`, gate 1→2 invariato |
| **A3 · Edifici** | `building_catalog.gd`, 3 ruoli, mondo 1 + finestre per stadio | `building_audit`, screenshot |
| **A4 · Itineranti** | I 6 personaggi ricorrenti, rotazione, Vera e «rispiegamelo», **`radice` e leggenda dell'Ingegnere già incluse (§3.2)** | Ritenzione registrata in `spaced_repetition` |
| **A5 · Vita di mondo** | Routine, notizie, conversazioni al Ritrovo (mondo 1, 3 stadi) | `world_life_audit` |
| **A6 · Estensione ai 24 mondi** | Cast, edifici, conversazioni, Tracce, **`radice` per ogni residente e assegnazione del pool di registro (§2.5) per ogni abitante, mondo dopo mondo con la cura di §3.2 come metro** | Tutti gli audit + playthrough |
| **A7 · Mistero e finale** | Tracce nel Codex, beat riscritti, convergenza al Cuore | `mystery_audit`, `world_wave_e2_audit` |

Fase A1 è deliberatamente piccola: serve a vedere **subito** se parlare con
qualcuno cambia davvero la sensazione del gioco, prima di scrivere 54 personaggi.

**Nota sulla profondità (16 agosto 2026)**: `radice` e leggenda dell'Ingegnere
non sono una fase a parte — sono uno standard di scrittura e un piccolo modulo
dati (`engineer_legend_catalog.gd`) che si applicano dentro le fasi esistenti.

**Correzione allo stato di A6, stessa data**: verificato con `npc_catalog_audit`
che **46 residenti e 23 Bislacchi sono già scritti**, uno per ciascuno dei
mondi 1–23 — la nota precedente di questo documento e il commento di
`npc_catalog.gd` dicevano «solo il mondo 1», ed era falso: descriveva la
*fixture* di `dialogue_audit.gd`, non il catalogo. Quello che manca ad A6 non
è il cast: è la `radice` esplicita (oggi solo un commento sopra `convinzione`,
non ancora un campo verificato) e, dove sensato, un accenno alla leggenda
dell'Ingegnere dentro il `riempimento` già scritto. Chi riprende questo lavoro
deve rileggere §3.2 prima di toccare i 46 residenti esistenti: è lì il livello
di cura atteso, non nella tabella compatta di §3.
