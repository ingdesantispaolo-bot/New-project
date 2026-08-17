# Forzieri e frammenti

*14 agosto 2026 — nasce da una segnalazione del committente: forzieri e frammenti
«sono solo una distrazione che non apporta nulla».*

Era vero, e misurandolo era vero in tre modi diversi. Questo documento tiene le
decisioni; il codice che le esegue è `godot/scripts/game/fragment_economy.gd`,
`godot/scripts/game/treasure_catalog.gd` e la regia in `outdoor_world.gd`.

## 1. Il difetto, misurato

| Cosa | Prima |
|---|---|
| Scarico della valuta | **nessuno**: `spend_fragments` non esisteva, la bottega chiamava `spend_energy` |
| Forzieri per mondo | **42** (1018 in campagna, `fragment_economy_probe`) |
| Etichette | tre stringhe a sorte, di cui una — «cassa energia» — prometteva un'energia che nessuno pagava (`rewardEnergy` generato e mai letto) |
| Contenuto | nessuno |

Un numero che sale per ventiquattro mondi e non compra niente, prodotto da
quarantadue oggetti identici per mondo.

## 2. Le due valute, separate

    ENERGIA     la fa lo studio, la spendono le prove. Non compra più niente.
    FRAMMENTI   li fa l'esplorazione, li spende la bottega.

Prima l'energia faceva due mestieri in conflitto: `economy_probe` misura che il
catalogo costa il 59–74% di **tutta** l'energia di una campagna, cioè comprarsi
un cappello competeva con l'allenarsi. Adesso chi esplora si compra la bellezza e
chi non esplora non perde niente di didattico — nessun cosmetico tocca una
domanda (decisione vincolante 15).

**Il Lascito continua a non pesare i frammenti** (`legacy_score.gd`): il finale
resta l'unica cosa che non si compra.

### Taratura

Le tariffe stanno tutte in `FragmentEconomy` e non sono a occhio:
`fragment_economy_probe` conta i forzieri dei 24 mondi con gli stessi vincoli del
gioco. Alle tariffe vecchie il catalogo costava **17,6 campagne**; alle nuove una
campagna intera al 100% ne compra il **59%** — dentro la fascia in cui stava
l'energia prima della separazione, e mai il catalogo intero: un catalogo
comprabile per intero è un catalogo senza scelte.

| Fonte | Prima | Adesso |
|---|---|---|
| Incontro risolto | 3 | 35 |
| Missione | 2 | 25 |
| Riparazione apparato | 4 | 50 |
| Camera del mondo | 12 | 150 |
| Varco (duello) | 4–11 | 45–125 |
| Forziere | 2–13 | 130–320 secondo il tipo |

## 3. Il forziere ha dentro qualcosa

**Regola di confine: il generatore fa la geometria, il catalogo fa il
significato.** `OutdoorGenerator` non è stato toccato — fixture di parità e
determinismo dei semi restano quelli che erano. `TreasureCatalog` legge l'id già
generato e decide che cosa quel forziere è, con lo stesso `posmod(hash(id), 100)`
che il progetto usa già per gli attrezzi richiesti.

**Un terzo dei forzieri resta** (34%): quarantadue per mondo diventano circa
dodici, uno ogni due chunk. Una cosa che si trova quaranta volte per mondo non è
un ritrovamento.

Tre tipi, e il rapporto fra loro è ciò che li fa funzionare — se ogni forziere si
fermasse a raccontare qualcosa, fermarsi smetterebbe di essere un avvenimento:

| Tipo | Quota | Cosa succede |
|---|---|---|
| **Lascito** | 26% | la roba di qualcuno che abita il mondo. Si apre un riquadro: l'oggetto, e una riga di Eli. Verbo `APRI`, e da fuori si legge «forziere chiuso con cura» |
| **Custode** | 14% | il Custode fruga e tiene per sé una cosa inutile, che finisce nella lista dei regali (`PetGifts`) — a fine campagna quella lista è il diario del viaggio, e adesso si riempie esplorando |
| **Resto** | 60% | cianfrusaglie: una riga di feedback e si cammina |

Gli **oggetti sono della materia del mondo** (cinque per materia, sessanta in
tutto) e i **proprietari sono del suo cast** (`NpcCatalog.for_world`). Nessun
testo dice mai chi era quella persona o come sta: dice che cosa ha lasciato e in
che stato. Un mazzo di stecche rilegato a gruppi di dieci racconta Tobia meglio
di una frase su Tobia — è la stessa regola delle Tracce (`mystery_catalog.gd`):
si leggono, non si recitano.

**Si incassa prima e si racconta dopo.** Chi chiude il riquadro senza leggere ha
già preso tutto: nessun testo di questo gioco può stare fra un bambino e una cosa
che ha guadagnato.

## 4. Guard-rail

- niente qui è obbligatorio: un forziere mancato non costa nulla, ed è la
  condizione perché possa valere qualcosa trovarlo;
- il contenuto guarda l'id e il mondo, **mai il giocatore**: livello, padronanza
  e cosmetici non cambiano cosa c'è dentro. Un forziere che paga di più a chi va
  meglio sarebbe una ricompensa nascosta al rendimento;
- un forziere saltato dalla densità resta saltato anche dopo un reload, e uno
  aperto non ricompare;
- comprare non muove nessuna delle cinque misure del Lascito.

Li verifica `treasure_audit.gd`, sul comportamento e non a parole.

## 5. La bottega attaccata al mondo

*Secondo lotto, stessa giornata: «bottega, valuta, gioco, missioni — come
possiamo collegare tutto in modo intelligente?».*

Misurando i legami esistenti, il gioco ne aveva già quattro chiusi e onesti:
studio → energia → prove; prove → luce del mondo e potenza di Eli; prove →
padronanza → **stadi degli NPC** (`npc_arc.gd`: Tobia cambia quando tu impari a
contare); prove → minimissioni → il mondo cambia. Mancavano quelli che
riguardavano la bottega, e ognuno mancava per una ragione diversa.

### 5.1 Le chiavi non si comprano

Torcia e falce sono le uniche due voci che **aprono il mondo** invece di
decorarlo. Con l'economia nuova costavano meno di un forziere: le due chiavi del
gioco erano diventate un acquisto automatico al primo baule.

Ribilanciare il prezzo sarebbe stato il rimedio ovvio e sbagliato — qualunque
cifra resta una riga di listino. Adesso **non sono in vendita**: le consegna chi
le usa, alla prima riparazione portata a termine in un mondo
(`field_tools.gd`, agganciato a `minimission_completed`). Le minimissioni
prendono il posto del primo evento-gate, quindi la consegna **non si può
mancare**: nessun bambino resta senza strumenti per non aver esplorato
abbastanza, che sarebbe il modo peggiore di legare l'esplorazione a sé stessa.

### 5.2 Il catalogo si scrive giocando

Tutte e 58 le voci avevano già un campo `origine` che le lega a un posto o a una
persona — *«Pigmento delle Rovine dei Glifi, l'unico colore che il tempo non ha
sbiadito»* — e nessuno lo faceva valere: si comprava il pigmento delle Rovine
senza aver mai visto le Rovine.

Ora **30 voci su 58** portano un campo `mondo`, e compaiono in vetrina quando
quella destinazione è aperta. Le altre 28 restano sempre disponibili e non è una
svista: sono la roba della nave e dei Dodici, quella degli itineranti che girano
tutti i mondi, e i moduli — che toccano il gameplay e non possono dipendere da
dove sei arrivata.

Non è un gate didattico, ed è la condizione perché possa esistere qui: **non
chiede padronanza, non chiede di aver finito niente**, solo che la rotta sia
aperta (`shop_world_link_audit` lo verifica confrontando due partite identiche,
una che sa tutto e una che non sa niente). E il rifiuto non è un rifiuto: al
posto del prezzo la scheda mostra il nome del posto — *DA TROVARE · ROVINE DEI
GLIFI* —, che è un indirizzo, non una porta chiusa. Al mondo 1 restano comunque
20 voci comprabili.

### 5.3 Niente si scusa più

`upgrade` e `decor` — 11 voci, 6.080 frammenti — dichiaravano al bambino che il
loro effetto «non è ancora attivo in questa build». Non erano morte come
sembrava: i pezzi della nave disegnano già un anello di luce addosso a Eli, e il
restauro pesava nello shader del Relitto. Ma pesava **0,06 di luce**: comprato,
non si vedeva.

Adesso il restauro porta luce, colore e bordi meno cupi, e accende sette fuochi
stabili nel ponte restaurato — sempre gli stessi, perché un luogo che cambia
forma a ogni visita non è un luogo restaurato. E il **nucleo prismatico**
(1.600 frammenti, il pezzo più caro) fa finalmente quello che la sua descrizione
prometteva da sempre: dodici luci in cerchio, una per materia, ognuna accesa
quanto la padronanza di quella materia. Nessun numero, nessuna classifica — un
ritratto, non una pagella.

### 5.4 Il Custode è uno solo

Lo slot `pet` (11 voci, 35.400 frammenti) sembrava vendere un secondo compagno
accanto al Custode. Non era vero — `outdoor_world._spawn_pet` usa lo slot per
dare **al Custode** la sua forma — ma i testi dicevano il contrario («compagno
fedele: resta vicino»), e un bambino che paga 5.200 frammenti aspettandosi un
animale in più ha ragione a sentirsi imbrogliato. Le descrizioni ora dicono la
verità: sono forme che il Custode assume.

Con un difetto vero trovato per strada: il colore comprato **non si vedeva mai**,
perché la livrea di serie vinceva sempre. Ora l'ordine è quello del significato —
una livrea scelta a mano dal bambino batte tutto, ma sopra il default silenzioso
vince l'aspetto comprato.

## 6. Il chiavistello: come si apre un forziere

*Terzo lotto: «l'apertura dei forzieri deve avvenire con un minigioco di velocità
di matematica, con difficoltà che dipende dai mondi».*

Il posto dove metterlo era già dichiarato dal progetto: il forziere è **l'unica
cosa che una prova di abilità può lecitamente chiudere**, perché dentro c'è
bellezza e non progressione. Nessun forziere è obbligatorio, quindi nessun
bambino lento resta fermo.

### 6.1 La forma

Un quadrante. Al centro il **numero che apre**; attorno, tessere con
**operazioni**: si tocca quella che fa il numero. Ogni tessera giusta fa scattare
un dente; scattati tutti, il forziere si apre.

Le alternative scartate, e perché:

| Alternativa | Perché no |
|---|---|
| «quanto fa 7×8?» a risposta multipla | è un quiz, ed è già il formato di mezzo gioco: rifarlo a tempo lo rende solo più stressante |
| scrivere il risultato | la tastiera numerica su tablet è lenta: la velocità la deciderebbe il dito |
| centrare un bersaglio mobile | premia lo schermo grande e la mano ferma: in questo gioco non si mira mai |

Scegliere **l'operazione giusta fra tante** è invece calcolo mentale parallelo: il
bambino non risolve una domanda, ne scarta quattro — e impara a scartare per
ordine di grandezza, parità e ultima cifra, che è esattamente come si diventa
veloci davvero.

**I distrattori sono errori tipici, non numeri a caso**: la somma al posto del
prodotto, la sottrazione girata, il vicino di uno. Alla prima stesura `lock_challenge_audit`
ha misurato che solo il **42%** dei distrattori cadeva vicino al bersaglio — gli
altri si scartavano a occhio, e un dente dove tre tessere su quattro si buttano
senza calcolare non è calcolo veloce, è fortuna veloce. Ora il valore si sceglie
prima (un vicino del bersaglio) e l'espressione si costruisce per farlo: **82%**.

Un secondo difetto è emerso solo **guardando** il minigioco (`lock_render_probe`
salva quattro viste reali in `artifacts/lock/`): fra le tessere compariva
«22 ÷ 3». Il gioco la calcolava 7 per troncamento, un bambino che la svolge per
bene trova 7,33 e non ritrova più il proprio risultato — l'unico modo in cui un
minigioco di calcolo può davvero mentire. I distrattori per divisione ora
spostano il **dividendo** di un divisore («22 ÷ 2» → «24 ÷ 2»): restano esatti,
restano vicini, restano errori plausibili. `lock_challenge_audit` da allora
verifica ogni divisione generata.

### 6.2 La difficoltà, mondo per mondo

Cresce in quest'ordine: prima i **numeri**, poi le **operazioni**, poi il **tempo**
che si accorcia, e per ultima la rotazione delle tessere — leggere mentre una cosa
si muove costa attenzione, e a dieci anni quella è la risorsa scarsa.

| Mondi | Numeri fino a | Operazioni | Tessere | Tempo per dente |
|---|---|---|---|---|
| 1–4 | 20 | + − | 4 | 6,5 s |
| 5–9 | 50 | + − × | 4 | 5,5 s |
| 10–14 | 100 | + − × ÷ | 5 | 4,8 s |
| 15–19 | 144 | doppie (a×b+c) | 5 | 4,2 s |
| 20–24 | 200 | doppie | 6 | 3,8 s |

Sotto i **3 secondi** non si scende mai: più giù non si misura il calcolo, si
misura il tempo di reazione del dito — che è un'altra cosa e non si insegna.

I denti seguono il valore del forziere: 2 per una cassa qualunque, 3 per il
forziere di qualcuno. Una cassa di cianfrusaglie non può chiedere quanto un
lascito, o il bambino impara che aprire non vale la pena.

### 6.3 Cosa succede quando si sbaglia

Niente. È il punto su cui poggia tutto il resto: la tessera sbagliata **si spegne
e resta lì**, il quadrante trema un istante, e il costo è il tempo già speso a
calcolarla. Nessun rosso lampeggiante: il rosso addosso a un bambino che sta
contando in fretta è una punizione, e qui non c'è niente da punire.

Tempo scaduto o uscita volontaria: il forziere **resta chiuso dov'è**, non risulta
raccolto, non costa frammenti né energia, e si riprova subito — con numeri nuovi,
perché il seme cambia a ogni tentativo e un chiavistello fallito non deve poter
essere rifatto a memoria.

Vincere senza sbagliare non paga di più: il contenuto di un forziere non dipende
da come si gioca (§4). Paga una riga diversa — «chiavistello pulito» — e una
reazione del Custode. È l'unico premio che non sposta l'economia.

### 6.4 Accessibilità

Con `reduced_motion` le tessere **non ruotano** e il tempo cresce del 45%: chi ha
bisogno di meno movimento non perde per questo il forziere. Con `high_contrast` i
bordi diventano pieni e gli aloni spariscono. Si gioca col dito, col mouse e con
i tasti 1-6 — su desktop cercare il mouse mentre si conta è un secondo lavoro, e
il chiavistello misura il primo.

Lo verificano `lock_challenge_audit` (i numeri: nessun dente ambiguo su 22.800
generati, difficoltà monotòna sui 24 mondi) e `lock_panel_audit` (la scena: apre,
paga, e perdere non costa niente).

## 7. Il duello: come si scioglie un guardiano

*Quarto lotto, 16 agosto 2026: «miglioriamo il combattimento contro i guardiani
con un minigioco di calcolo, con difficoltà che dipende dal livello del mondo.
Non deve essere come quello per aprire i bauli. Deve insegnare a padroneggiare i
calcoli veloci, e deve essere un combattimento».*

Fino a quel giorno il guardiano si scioglieva con **il varco**: una barra, un
cursore, il momento giusto. Funzionava, ed è stato tolto lo stesso per una
ragione sola: era l'unico momento del gioco in cui *la bravura non c'entrava con
quello che il gioco insegna*. Un bambino che si allena a contare non diventava
più bravo a centrare un cursore, e un bambino con riflessi buoni prendeva i
premi senza avere imparato niente. La potenza di Eli allargava il varco, ma la
competenza vera restava fuori dalla porta.

### 7.1 La forma, e perché non è il chiavistello

Il guardiano porta un **sigillo**: un numero. Eli ha un **impulso**: un altro
numero, che parte piccolo. In mano ha delle **rune** — `+7`, `×4`, `−5`, `÷3` —
e ognuna è un colpo che cambia l'impulso. Quando l'impulso vale **esattamente**
il sigillo, il sigillo si spezza. I colpi sono contati, le rune si consumano.

La differenza col chiavistello non è cosmetica ed è tutto il punto:

| | chiavistello | duello |
|---|---|---|
| gesto mentale | **riconoscere** (quale operazione fa 42) | **costruire** (sono a 12, come arrivo a 36) |
| direzione | in avanti | all'indietro |
| durata | una domanda, una risposta | una strada da pianificare in due o tre colpi |
| forma | un quadrante che gira | un campo di battaglia con una scala |

Il pensiero inverso è ciò che separa chi sa le tabelline da chi sa *usarle*, ed è
la sola scorciatoia vera verso il calcolo mentale rapido. Due minigiochi di
calcolo nello stesso gioco si giustificano solo se chiedono due gesti diversi.

### 7.2 Perché è un combattimento

Tre cose, tutte e tre assenti dal varco:

1. **Il guardiano si carica.** La barra sotto di lui è il tempo, raccontato dalla
   parte di chi ti sta davanti: quando è piena colpisce, e Eli perde un punto di
   **tenuta**. Non è un cronometro sopra una domanda, è un avversario.
2. **Ha da due a quattro sigilli**, secondo il suo grado: il duello è fatto di
   scambi, e ogni sigillo spezzato lo fa arretrare. La ripresa esiste.
3. **Accelera**: ogni sigillo spezzato accorcia del 10% la carica del successivo.
   Un combattimento che finisce più teso di come è cominciato.

### 7.3 La corda di risonanza (il pezzo che insegna)

Sotto il guardiano c'è una scala: una tacca d'oro segna il sigillo, un ago segna
l'impulso, e la zona **oltre** la tacca è disegnata e barrata.

Un numero da raggiungere, scritto e basta, dice solo *quanto*. Una scala dice
**quanto manca**, a colpo d'occhio: un bambino che vede l'ago fermo a un terzo
della corda sa che gli serve un `×3` prima di averlo calcolato. Quell'ordine di
grandezza è la prima cosa che fa un calcolatore veloce, ed è la sola parte del
calcolo mentale che un'interfaccia può davvero insegnare.

Sotto la corda resta scritta la **catena**: `4 → ×6 → 24 → +9 → 33`. È il
quaderno del duello — l'unico posto del gioco in cui il ragionamento resta
visibile dopo essere stato fatto.

### 7.4 La difficoltà, mondo per mondo

Cresce in quest'ordine: prima i **numeri**, poi le **operazioni**, poi i **passi**
della catena, e per ultimo il **tempo**. Il salto da due a tre passi, a metà
campagna, è il salto vero: con due colpi si può ancora andare a tentativi, con
tre no.

| Mondi | Numeri fino a | Operazioni | Fattori | Passi | Rune in mano | Carica |
|---|---|---|---|---|---|---|
| 1–4 | 30 | + × | ×2–×3 | 2 | 4 | 12,0 s |
| 5–9 | 60 | + − × | ×2–×5 | 2 | 5 | 11,0 s |
| 10–14 | 100 | + − × ÷ | ×2–×9 | 3 | 5 | 11,0 s |
| 15–19 | 150 | + − × ÷ | ×2–×12 | 3 | 6 | 10,0 s |
| 20–24 | 240 | + − × ÷ | ×2–×12 | 3 | 6 | 9,0 s |

Sopra a questa tabella agiscono le due leve che c'erano già: **il grado di Eli**
allunga la carica (+0,55 s per grado, fino a +3,5) e alza la tenuta (da 2 a 6);
**il grado del guardiano** accorcia la carica (−0,5 s per grado) e aggiunge
sigilli. Sotto i **6,5 secondi** non si scende mai: poco più di due secondi a
colpo, e sotto non si misura il calcolo ma la velocità del dito.

I colpi concessi sono i passi **più uno**. Quel colpo di riserva è ciò che rende
sensate la sottrazione e la divisione: senza, chi supera il sigillo avrebbe già
perso e le rune che tornano indietro non servirebbero mai. Con la riserva, chi
sfonda ha una via di rientro — e trovarla è esattamente il calcolo da insegnare.

### 7.5 Le rune spente, e le esche

Una runa che **qui non entra** è disegnata spenta e barrata: `÷4` su 30 non si
può fare. Non è un divieto arbitrario ed è l'unico posto del gioco in cui «non si
può» significa «guarda perché» — la divisibilità si impara vedendola.

Le esche non sono rune a caso, per la stessa ragione per cui non lo sono i
distrattori del chiavistello: l'**esca d'ampiezza** (il moltiplicatore grosso che
dalla partenza sfonda il sigillo), la **vicina** (una runa della strada giusta col
numero spostato di uno), e la **runa che serve dopo** — una divisione spenta
all'inizio che si accende a metà strada, e che insegna a guardare la mano *prima*
di cominciare.

### 7.6 Cosa succede quando si sbaglia, e accessibilità

Perdere il duello costa **quanto un morso** e non un grammo di più: se costasse
di più, la scelta razionale sarebbe girare alla larga e il minigioco non lo
giocherebbe nessuno. Il guardiano resta dov'è, il forziere pure, si torna quando
si vuole con numeri nuovi. Andarsene non costa niente. E se con le rune rimaste
il sigillo non si fa più, lo scambio si chiude subito invece di lasciar scorrere
la carica su una partita già persa.

Incassare un colpo **non suona come una risposta sbagliata** e non è mai rosso:
il guardiano para in ambra e avanza di un passo. È un colpo preso in un duello,
non un errore su una domanda, e il gioco non deve mai lasciar credere il
contrario. Con `reduced_motion` niente tremori né ondeggio e la carica cresce del
40%; con `high_contrast` bordi pieni e niente aloni; si gioca col dito, col mouse
e coi tasti 1-6.

Lo tengono `guardian_duel_audit` (la taratura e la generazione: su migliaia di
scambi nessuno è irrisolvibile, nessuno si spezza con un colpo solo, nessuno si
apre con meno di due rune giocabili) e `guardian_scene_audit`, che il duello lo
**gioca davvero** dentro un mondo vero. `guardian_duel_render_probe` salva sei
viste reali in `artifacts/duello/`: la prima stesura ci si è rivelata con il
numero dell'impulso appoggiato sopra l'ago e la carica del guardiano che ci
passava attraverso — difetti che nessuna asserzione avrebbe visto.

## 8. Il duello delle voci: la seconda materia

*Quinto lotto, 17 agosto 2026: «un altro tipo di minigioco, questa volta di
italiano. I guardiani possono sfidarti casualmente in italiano o matematica.
Deve insegnare a padroneggiare modi e tempi verbali veloci, deve essere un
combattimento, con difficoltà dipendente dal livello del mondo».*

### 8.1 La forma

Il guardiano porta un **sigillo**: una casella del sistema verbale — modo, tempo,
persona. Eli ha un **impulso**: il suo verbo, fermo su un'altra casella e scritto
per esteso («canto»). In mano ha delle **rune**, e ognuna sposta *un asse solo*:

| | |
|---|---|
| `modo → congiuntivo` | sposta il modo |
| `tempo → imperfetto` | sposta il tempo |
| `persona → voi` | sposta la persona |

Quando l'impulso si ferma sulla casella del sigillo, il sigillo si spezza. E
mentre lo si fa, **il verbo si trasforma sotto gli occhi**:
`canto → cantavo → cantavate → cantaste`.

Le alternative scartate, e perché:

| Alternativa | Perché no |
|---|---|
| «che tempo è *cantavate*?» a risposta multipla | è un quiz: misura se lo sai già, non te lo insegna |
| scegliere la voce giusta fra quattro | è il chiavistello con le parole al posto dei numeri |
| scrivere la voce | la tastiera su tablet è lenta, e si misurerebbe l'ortografia |
| trascinare le voci nella casella giusta | è un puzzle da tavolo: niente in esso somiglia a un combattimento |

### 8.2 Le due cose che insegnano, e sono gratis

**Le rune spente.** `tempo → passato remoto` è spenta quando sei nel congiuntivo,
perché il congiuntivo il passato remoto **non ce l'ha**; `modo → condizionale` è
spenta quando sei sul futuro, perché il condizionale il futuro non ce l'ha. Il
bambino impara la forma del sistema sbattendoci contro, che è l'unico modo in cui
quella forma si impara.

**L'ordine conta.** Per arrivare al condizionale passato partendo dall'indicativo
futuro non puoi cambiare modo per primo: quella casella non esiste. Devi passare
da un tempo che i due modi hanno in comune. È pianificazione vera, e nasce dalla
grammatica invece che da una regola inventata dal gioco.

### 8.3 I tre binari (il pezzo che si vede)

Il primo disegno era la tabella dei verbi, modi in riga e tempi in colonna, come
sul libro. **Non ci sta**: a nove tempi e tre modi le intestazioni scendevano a
corpo dieci, che su un tablet in mano a un bambino non è una tabella, è una
macchia. E soprattutto non serviva — da una tabella si legge *dov'è tutto*, mentre
qui bisogna leggere **dove sono e dove devo arrivare**, che sono tre informazioni,
una per asse.

Quindi tre binari, uno sopra l'altro, con la casella attuale accesa e quella del
sigillo cerchiata d'oro. Fanno una cosa che una tabella stampata non può fare:
**i tempi si spengono e si riaccendono mentre cambi modo**. Passi al condizionale
e vedi sparire l'imperfetto e il futuro; torni all'indicativo e tornano.

### 8.4 La difficoltà, mondo per mondo

| Mondi | Modi | Tempi | Verbi | Assi da cambiare | Rune | Carica | Sigillo scritto come |
|---|---|---|---|---|---|---|---|
| 1–4 | indicativo | 3 | regolari in *-are* | 2 | 4 | 13,0 s | etichetta |
| 5–9 | indicativo | 5 | regolari, i tre gruppi | 2 | 5 | 12,0 s | etichetta |
| 10–14 | + congiuntivo | 5 | tutti, irregolari compresi | 3 | 5 | 12,0 s | voce da riconoscere |
| 15–19 | + condizionale | 7 | tutti | 3 | 6 | 11,0 s | voce da riconoscere |
| 20–24 | tutti e tre | 9 | tutti | 3 | 6 | 10,0 s | voce da riconoscere |

Il passaggio più importante è l'ultima colonna. Fino al mondo 9 il sigillo dice a
parole dove andare («INDICATIVO PRESENTE · io»): si impara la **mappa**, cioè
quali caselle esistono. Dal mondo 10 il sigillo mostra una **voce vera di un
altro verbo** («aveste temuto», *da temere*) e tocca a te capire che casella sia:
si impara il **riconoscimento**, che è la competenza vera e che senza la mappa
non si può nemmeno cominciare. Chiedere di riconoscere una casella a chi non sa
ancora quali caselle esistono è il modo più rapido per far smettere di giocare.

**Il bersaglio non può mentire.** La voce mostrata deve individuare **una casella
sola** in tutto il paradigma del verbo campione: «cantaste» è passato remoto *e*
congiuntivo imperfetto, «canti» è tre cose diverse. Mostrarne una e poi dire «no,
intendevo l'altra» sarebbe la bugia peggiore che un gioco di grammatica possa
raccontare a un bambino che ha ragione. `verb_duel_audit` lo verifica su ogni
sigillo generato.

### 8.5 Il coniugatore

Le voci vengono da un motore (`verb_conjugator.gd`): desinenze regolari dei tre
gruppi, incoativi in `-isc-`, tempi composti costruiti dall'ausiliare giusto,
accordo del participio con «essere», e **ogni irregolarità scritta per esteso**,
mai «quasi regolare». Trentasette verbi, 13 caselle × 6 persone ciascuno.

`verb_conjugation_audit` confronta il motore con **126 voci scritte a mano**, non
con un'altra funzione del motore — che sarebbe come farsi correggere il compito
da chi l'ha copiato. È l'unico audit del progetto in cui l'errore non è un difetto
di gioco ma un **danno didattico**: un bambino si fida di quello che legge qui e
se lo porta al compito in classe.

Fuori copertura, dichiarato: imperativo (le sue persone non sono sei), modi
indefiniti (non hanno persona), trapassato remoto (vive solo dentro una
subordinata). Nessuna delle tre toglie qualcosa al calcolo veloce di modi e tempi.

### 8.6 Quale guardiano chiede cosa

La materia la decide l'**identificativo del guardiano** e non il caso del momento:
lo stesso guardiano chiede sempre la stessa cosa, in questa partita e nella
prossima. Un guardiano che cambiasse materia fra un tentativo e l'altro
toglierebbe senso al tornare — chi ha perso su una voce difficile deve poter
tornare a **quella**, altrimenti allenarsi non paga e il duello è una slot machine.

E la materia **sta scritta sul cartiglio** che si legge da lontano
(`GUARDIANO VOCI · T4`): avvicinarsi è una scelta informata, non una lotteria.

Non segue la materia del mondo, di proposito: le due devono comparire in tutti e
ventiquattro i mondi, o un bambino che gioca il mondo di scienze non vedrebbe mai
un verbo.

**Nessuna delle due può essere la strada conveniente.** Sigilli, tenuta, colpi di
riserva, prezzo della sconfitta e premio stanno in `duel_rules.gd` e sono
identici: se una materia fosse più generosa, si imparerebbe a cercare i guardiani
di quella invece di quelli che si ha voglia di affrontare. `verb_duel_audit`
confronta le due tabelle mondo per mondo.

## 9. Cosa non è stato fatto (e resta sul tavolo)

- **Tenere o restituire.** Un lascito è la roba di una persona viva: la scelta
  naturale è restituirla. L'impianto esiste già (`stance_choices.gd`, cinque
  momenti di cui uno solo cablato) e il meccanismo sarebbe quello dichiarato lì —
  nessuna opzione punita, cambia solo che qualcuno se ne ricorda. **Attenzione**:
  se restituire valesse per il Lascito e tenere no, la scelta avrebbe una
  risposta giusta e il gioco starebbe punendo di nascosto (§10.6). La
  restituzione non deve dare punteggio, solo memoria — la stessa logica dei
  regali del Custode, che non valgono niente apposta.
- **Mecenatismo**: spendere frammenti per riparare pezzi visibili di un mondo
  invece che per comprare cosmetici. Tematicamente è la cosa più forte in un
  gioco che parla di riparare; costa contenuto e arte per mondo.
