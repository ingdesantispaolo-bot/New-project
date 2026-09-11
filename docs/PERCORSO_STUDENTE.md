# Il percorso dello studente fra esercizi, allenamenti ed elementi del mondo

*Aperto il 10 settembre 2026. Corsia OPUS del piano [ASTRA × OPUS](../astra.md):
Astra lavora sulle missioni, qui si lavora su **come ci si arriva**.*

## La segnalazione

> «Lo studente quando si presenta in un mondo segue semplicemente il percorso
> indicatogli dalle istruzioni. Questo può andar bene ma toglie stimolo ad
> esplorazione del mondo. Il mondo va reso vivo ed interessante.»

## Che cosa era, misurato

Un mondo pianta **diciotto punti d'interesse**: sette della materia ospite —
missioni, un enigma, l'incarico dei Dodici — e undici palestre, una per ogni
altra materia (`MissionEventDirector.plan`, `HOST_EVENTS` più `GATE_SURPLUS`).
Tutti nascono alla costruzione del mondo, tutti restano sulla mappa finché non
si chiudono.

Quattro misure spiegano perché quel mondo si percorre come un elenco.

**1 · Ogni punto portava sopra la sua riga di registro.** La didascalia era
`PRATICA · MATEMATICA`, `MISSIONE · STORIA`, `ENIGMA · LOGICA`: la categoria del
direttore e il nome della materia. Diciotto per mondo, ventiquattro mondi:
**432 voci di un elenco**, nessuna delle quali nomina un posto. Non c'è niente da
scoprire in un cartello che dice a quale riga corrisponde quel puntino.

**2 · Il mondo sapeva già i nomi e non li diceva a nessuno.** Il direttore non
sparge coordinate: aggancia ogni evento a un **luogo dichiarato** della
composizione, con un ruolo (`region`, `instrument`, `landmark`, `crossing`,
`trail`) e una costellazione. Cercando `locationRole` e `locationCluster` in
tutto il progetto si trovano **solo scritture e audit: nessun lettore di gioco**.
È il difetto ricorrente del progetto — contenuto scritto e mai collegato — nella
sua forma più costosa, perché quel vocabolario è esattamente il vocabolario dei
luoghi.

Stessa storia per `discoveryCue` (`proximity` / `local_clue` / `distant_signal`):
calcolato per tutti e diciotto i punti di tutti e ventiquattro i mondi, letto
solo da `_make_world1_discovery_cue`, che è sotto due guardie — `world_level == 1`
**e** `countsForGate` — quindi vale per sette punti di un mondo su ventiquattro.

**3 · La decisione di dove andare non era del bambino.** Tre strumenti la
prendevano al posto suo, e sono nati tutti e tre da difetti veri:

| Strumento | Che cosa fa | Perché esiste |
|---|---|---|
| Quadro degli obiettivi | nomina **una** materia: «adesso tocca a latino» | nominarne dodici è illeggibile (7 agosto) |
| **PORTAMI** | punta la palestra di quella materia e imposta il passo | senza, la scelta si prendeva leggendo le etichette una per una (21 agosto) |
| «SEGUI LA MISSIONE» | punta la tappa successiva | stessa ragione |

Messi insieme bastano a giocare un mondo intero senza mai guardarsi attorno: si
apre il quadro, si preme un pulsante, si cammina in linea retta, si ripete. Il
mondo diventa il corridoio fra due schermate.

**4 · Fra un punto e l'altro il gioco tace.** Le tappe distano da trecento a
settecento unità. In quel tratto `_refresh_prompt` azzera la striscia di
feedback, e giustamente: non c'è niente da fare lì. Ma è **l'unico momento in cui
il bambino sta decidendo dove andare**, ed è l'unico in cui nessuno gli dice
niente. Così decide l'unica cosa che parla, cioè il quadro degli obiettivi.

## La regola che tiene insieme la correzione

**Non si toglie la guida: si dà da scegliere.**

Togliere il quadro o PORTAMI sarebbe rispondere a «non esploro» con «adesso ti
arrangi», e cancellerebbe due difetti misurati per riaprirne un terzo già
misurato. Il pavimento di accessibilità resta intatto, sempre. Quello che cambia
è che **non usarlo diventa la giocata migliore**.

E tre regole di scrittura, valide per tutta la corsia:

- **mai la parola della categoria** — né PRATICA, né MISSIONE, né ENIGMA: sono
  parole del registro di chi ha costruito il gioco. Che cosa sia lo dice il
  disegno, che per i tre è diverso e riconoscibile da lontano;
- **mai puntare, mai portare** — un nome e una direzione. Camminarci resta il
  gioco;
- **il silenzio è un'informazione** — quando non c'è niente da dire non si dice
  niente. Una frase di riempimento insegna a non leggere le frasi.

## Lotto 1 — I nomi dei posti e lo sguardo intorno *(fatto, 10 settembre 2026)*

**`NomiDeiLuoghi`** trasforma il ruolo del luogo nel **sostantivo** del posto e la
materia nel suo **complemento**: «il banco delle misure», «la pietra delle date»,
«il varco dei fili», «il cippo delle rotte». Il ruolo era già lì e non lo leggeva
nessuno. Cinque forme per ruolo, così la materia ospite — che ha sette punti e
può appoggiarne più d'uno sullo stesso tipo di luogo — non ripete mai lo stesso
nome; l'unicità è verificata sui ventiquattro mondi, non promessa. Il caso
peggiore misurato ne chiede quattro (mondo 12, quattro prove di logica su
strumenti).

Il nome sostituisce la didascalia sulla targhetta, e da vicino la riga aggiunge
**che cosa chiede quel posto** con un verbo: «il banco delle misure · ti chiede
di contare e misurare · ancora 3 prove per il mondo successivo».

**`PercorsoStudente`** riempie il silenzio del cammino. Quando la striscia è
vuota e nessuno è a portata, dice **che cosa si vede da dove sei**: al massimo
due nomi, con distanza e direzione. Tre vincoli lo tengono onesto:

- entra nella frase solo ciò che sta entro la **portata dell'occhio** (720 unità,
  cioè una schermata) oppure ciò che è **già passato a portata d'occhio almeno
  una volta**. Camminare produce memoria, ed è la prima ricompensa
  dell'esplorazione che non sia un cosmetico;
- i due nomi sono di **generi diversi** — una prova, un allenamento, un elemento
  del paesaggio — perché due dello stesso genere sono una classifica, e una
  classifica è un ordine travestito;
- **riempie il silenzio, non lo interrompe**: la riga esce solo se la striscia è
  già vuota. NORA, il Custode, gli abitanti e i costi hanno la precedenza.

I forzieri restano fuori di proposito: trovarli è il mestiere del Custode, e
nominarli qui glielo toglierebbe.

La memoria dei posti visti vive **dentro la visita**, non nel salvataggio (vedi
«Che cosa resta aperto»).

Due guardie, e servono tutte e due.

`percorso_studente_audit` misura sui 24 mondi che i nomi siano unici e privi di
parole di registro, che lo sguardo sia deterministico, che non nomini mai il
posto su cui sei in piedi né uno mai visto fuori portata, e che da almeno il
**95%** dei punti d'interesse si veda qualcos'altro — misurato 97%.

`percorso_studente_scene_audit` costruisce il mondo vero e pretende quello che
un audit sui dati non può vedere: che la targhetta porti davvero il nome del
payload, che ci sia più di un genere da nominare, che lo sguardo **scriva** una
riga nell'HUD e che non scavalchi una riga già scritta. È la guardia contro il
difetto ricorrente — moduli verdi che in gioco non legge nessuno — e va scritta
per ogni lotto di questa corsia, non solo per il primo.

## Lotto 2 — La distanza di lettura del nome *(fatto, 10 settembre 2026)*

Il lotto 1 ha dato un nome ai posti. Restava che quel nome fosse **opaco
sempre**: appena un punto entrava nello schermo il suo nome era già leggibile,
cioè non esisteva il momento in cui hai visto qualcosa e non sai ancora che
cos'è — e quel momento è l'unico contenuto che l'esplorazione abbia da offrire.

**`ScopertaLuogo`** decide da quanto lontano un nome si legge, leggendo il
`discoveryCue` che il direttore calcolava per tutti i punti di tutti i mondi e
che fuori dagli audit non apriva nessuno:

| Grammatica | Dove sta | Il nome si legge da |
|---|---|---|
| `distant_signal` | regioni, landmark, varchi | 620 unità — quasi appena entra nello schermo |
| `local_clue` | strumenti | 380 — si vede che c'è qualcosa, per sapere cosa ci si avvicina |
| `proximity` | cippi lungo i sentieri | 220 — **non si annunciano**, si trovano camminandoci accanto |

I tre numeri stanno dentro la forbice fra il raggio d'interazione (88) e la mezza
diagonale dello schermo (734): dentro quella forbice ci sono tutti e tre i
momenti — vedo che c'è qualcosa, capisco che cos'è, ci arrivo.

**Il rombo del mondo 1 non si generalizza.** `_make_world1_discovery_cue` disegna
uno spillo fluttuante sopra il punto; accenderlo sui 24 mondi — che era la prima
idea, scritta in questo piano — vorrebbe dire **432 spilli**, cioè rispondere a
«sembra un elenco» aggiungendo icone all'elenco. Resta dov'è, sui sette punti di
gate della Radura. Si generalizza la *grammatica*, non il disegno.

**Come si compone col lotto 1.** Lo sguardo intorno nomina ciò che sta entro una
schermata, comprese le targhette che a quella distanza non sono ancora
leggibili: la voce dice «il campo dei viventi, poco più in là in alto», e il
nome sul posto lo conferma quando ci arrivi. L'informazione non sparisce —
smette di essere spalmata sulla mappa e torna a essere qualcosa che si raccoglie.

**Le due garanzie.** Niente diventa irraggiungibile: cambia solo l'opacità di
un'etichetta, mentre nodo, collisione, raggio d'interazione e PORTAMI restano
identici. E in **alto contrasto i nomi restano accesi**: la dissolvenza è
atmosfera, e l'atmosfera non costa la leggibilità a chi ne ha bisogno (in
movimento ridotto si accende di colpo invece di sfumare).

## Lotto 3 — Il quartiere ha un nome *(fatto, 10 settembre 2026)*

Un nome dice *che cosa* è un posto; non dice *dove*. Le undici palestre si
raccolgono in poche costellazioni — misurate **2,9 per mondo**, sei nel caso
peggiore — e quella costellazione è la cosa che un bambino può imparare a
memoria: «gli allenamenti stanno di là». Il campo `locationCluster` la descriveva
da mesi e non lo leggeva nessuno.

**Il quartiere prende il nome del suo posto più vistoso**, che è come nascono i
nomi dei quartieri veri; la prominenza non è un'opinione, è il ruolo del luogo —
landmark, varco, regione, strumento, sentiero, in quest'ordine. «il quartiere
della pietra delle date».

**Una costellazione con un posto solo non è un quartiere.** Chiamarla col nome
del suo unico posto darebbe «il banco delle misure, nel quartiere del banco delle
misure»: una tautologia detta a un bambino insegna che queste righe non vanno
lette. Dove il quartiere non c'è, non si dice niente.

Esce in due punti, e sono i due in cui la domanda «e dove?» viene fatta davvero:
la riga di ogni materia nel **quadro degli obiettivi**, e il messaggio di
**PORTAMI**, che adesso dice «Rotta verso il banco delle radici, nel quartiere
della pietra delle date» invece di «Rotta verso l'allenamento di latino». È la
differenza fra un pulsante che porta e un pulsante che insegna la strada: la
volta dopo ci si può andare da soli.

Misurato sui 24 mondi: **67 quartieri**, e il **90%** delle materie sa dire in
quale si allena. Le preposizioni articolate sono verificate: «il quartiere di il
campo» è il modo più rapido di far smettere di leggere queste righe.

## Lotto 4 — La tavola letta sul posto lascia un segno *(fatto, 10 settembre 2026)*

Ogni mondo ha una tavola incisa sul grande landmark (`LandmarkTavolaCatalog`):
si trova esplorando, si legge una volta, e il salvataggio se la ricorda in
`landmarkTavoleSeen`. Fin qui c'era tutto — poi, misurato: **quel ricordo non lo
apriva nessuno**, se non per non rimostrare il pannello. Chi si era fermato a
leggere e chi era passato dritto giocavano il resto del mondo in modo identico,
cioè l'esplorazione era letteralmente senza conseguenze.

Le conseguenze adesso sono due, e stanno tutte e due nel mondo:

- **prima** — il landmark dichiara di avere qualcosa da leggere finché non l'hai
  letto: una riga sulla sua targa, che è l'unica cosa che ogni mondo mostra da
  lontano, e quindi l'unico posto in cui il richiamo arriva a chi non è già lì.
  Da vicino la riga diventa «c'è qualcosa inciso, e si può guardare da vicino».
  Letta la tavola, il richiamo si spegne **subito** e non al rientro nel mondo:
  un richiamo che resta acceso dopo essere stato raccolto insegna a non fidarsi
  dei richiami;
- **dopo** — davanti alla prima prova della materia del mondo, NORA richiama la
  riga di scoperta della tavola, una volta per visita. Non è un aiuto e non
  risponde a niente: è il momento in cui quello che hai visto camminando torna
  utile, che è l'unica ricompensa didattica onesta che l'esplorazione possa
  avere in un gioco che vieta le scorciatoie per non sapere.

La metà che manca — la tavola consultabile **dentro** la prova — vive in
`exercise_player.gd`, che è della corsia di Codex: non si tocca, e non è in
programma.

## Che cosa resta aperto

Non altri lotti, ma tre cose da tenere d'occhio.

**La memoria dei posti visti muore uscendo dal mondo.** Renderla persistente
vuol dire una chiave nuova nel salvataggio, che è di Codex. Vale la pena solo se
il rientro in un mondo già battuto diventa un caso frequente: allora si chiede.

**Il rombo del mondo 1 resta un'eccezione.** `_make_world1_discovery_cue` è
l'unico spillo fluttuante rimasto, sui sette punti di gate della Radura. O lo si
toglie — e la Radura legge come gli altri ventitré mondi — o si accetta che la
fetta verticale abbia un vocabolario in più. È una decisione di progetto, non un
difetto.

**Le undici palestre restano una per materia.** Il percorso adesso si sceglie,
ma fra diciotto punti la cui composizione è identica in tutti e ventiquattro i
mondi. Quella è la ricetta del direttore, e cambiarla è un lotto di gameplay, non
di percorso.

## Il confine con la corsia di Codex

Codex lavora sulle **missioni** — `exercise_player.gd`, `outdoor_gameplay.gd`,
`progression_manager.gd`, `save_manager.gd`, `local_progress_report.gd`,
`linked_missions_*.gd`, `obelisk_mission*.gd`. Questa corsia **non li apre**,
nemmeno per una riga, nemmeno quando sarebbe comodo: un lotto che ha bisogno di
uno di quei file si riscrive per farne a meno, oppure aspetta.

Ne segue una regola pratica: **quello che questa corsia non può salvare, non lo
salva**. La memoria dei posti visti vive dentro la visita e non nel salvataggio;
il giorno in cui servisse persistente, si chiede — non si aggiunge una chiave a
`save_manager.gd`.

`git status` prima di ogni lotto, e i file presi si scrivono qui sotto.

## Assegnazione dei file (protocollo `astra.md`)

Presi da questa corsia il 10 settembre 2026:

- `godot/scripts/game/nomi_dei_luoghi.gd` *(nuovo)*
- `godot/scripts/game/scoperta_luogo.gd` *(nuovo)*
- `godot/scripts/game/percorso_studente.gd` *(nuovo)*
- `godot/scripts/game/percorso_studente_audit.gd` *(nuovo)*
- `godot/scripts/game/percorso_studente_scene_audit.gd` *(nuovo)*
- `godot/scripts/ui/objective_panel.gd` *(condiviso — non aperto da Codex)*
- `godot/scripts/outdoor_world.gd` *(condiviso — verificato con `git status`:
  non aperto da Codex né il 10 settembre né nei lotti successivi)*
