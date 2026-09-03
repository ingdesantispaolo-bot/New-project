# Eli Quest — Stato dei contenuti e della narrativa

Ricognizione del **3 agosto 2026**. Tutti i numeri qui dentro sono misurati, non
ricordati: escono da `content_census_probe.gd`, `content_census2_probe.gd`,
`combinatorial_depth_audit.gd` e `content_depth_audit.gd`. Dove scrivo un
giudizio, il numero che lo sostiene è accanto.

---

## 1. Il censimento

### 1.1 Quanto materiale esiste, materia per materia

| materia | item nel banco | b1 | b2 | b3 | b4 | topic | specifiche minigioco |
|---|---:|---:|---:|---:|---:|---:|---:|
| inglese | **1109** | 708 | 286 | 76 | 39 | 18 | 31 |
| italiano | 336 | 268 | 22 | 18 | 28 | 21 | 35 |
| matematica | 284 | 16 | 81 | 110 | 77 | 1 | 37 |
| geografia | 110 | 18 | 30 | 34 | 28 | 8 | 30 |
| latino | 88 | 21 | 22 | 20 | 25 | 11 | 24 |
| musica | 63 | 13 | 12 | 15 | 23 | 8 | 34 |
| storia | 62 | 14 | 12 | 13 | 23 | 9 | 33 |
| logica | 60 | 13 | 12 | 12 | 23 | 7 | 38 |
| elettronica | 55 | 14 | 17 | 15 | 9 | 8 | 32 |
| coding | 54 | 11 | 19 | 11 | 13 | 13 | 41 |
| fisica | 52 | 13 | 10 | 21 | 8 | 8 | 35 |
| scienze | **48** | 13 | 12 | 11 | 12 | 8 | 42 |

**2321 item** in totale, **412 specifiche** di minigioco.

Il rapporto fra la materia più ricca e la più povera è **23 a 1**. Non è un
disastro come sembra — le specifiche di minigioco sono distribuite molto più
equamente (24–42 per materia) e generano combinatoria — ma dice dove il banco
regge da solo e dove no.

Nota su **matematica: 1 topic**. Il banco è solo `matematica-tabelline`; tutto
il resto della matematica lo produce `MathExerciseGenerator` a runtime, con i
propri topic. Non è un buco, è un'architettura diversa: va saputo, perché
mastery e ripasso spaziato del banco matematico coprono le sole tabelline.

### 1.2 Quali mondi tocca ogni materia

Ogni materia è ospite di **esattamente due mondi**, a dodici di distanza: la
prima volta si incontra, la seconda si approfondisce.

| materia | mondi | | materia | mondi |
|---|---|---|---|---|
| matematica | 1 · 13 | | latino | 7 · 19 |
| italiano | 2 · 14 | | elettronica | 8 · 20 |
| coding | 3 · 15 | | geografia | 9 · 21 |
| inglese | 4 · 16 | | scienze | 10 · 22 |
| fisica | 5 · 17 | | storia | 11 · 23 |
| musica | 6 · 18 | | logica | 12 · 24 |

### 1.3 Profondità combinatoria

`combinatorial_depth_audit` conta quante prove **distinte** ogni coppia
(materia, formato) sa produrre. Bersaglio: 10 000.

**26 coppie su 73 raggiungono il bersaglio. Le altre 47 no — e 43 di queste
stanno sotto le 100 prove anche al livello 24**, cioè a fine campagna, con tutte
le specifiche sbloccate.

> **Correzione del 3 agosto, sera.** In una prima stesura avevo letto la colonna
> dell'audit come «prove totali» e attribuito i numeri bassi ai `minLevel`. È
> falso: quella colonna è la profondità **al livello 1**, e misurando anche il
> livello 24 si vede che **una sola coppia su 73** è povera all'inizio e ricca
> alla fine. Le altre sono povere e basta. Il difetto è più grande di come
> l'avevo scritto, non più piccolo.

La ragione è strutturale, non un dimenticanza: **i formati a dato fisso
producono esattamente una prova per specifica.** Un grafico è quel grafico; un
circuito è quel circuito. Quindi la profondità di quella coppia *è* il numero di
specifiche scritte.

| materia | formato | prove distinte, per sempre |
|---|---|---:|
| musica · latino · inglese · storia · logica · geografia | circuito | **3** ciascuna |
| geografia | carta muta | **3** |
| musica · italiano · geografia · logica | grafico | **3** ciascuna |
| storia | reperti | **4** |
| scienze | ciclo | **4** |
| coding | ordina | **4** |
| elettronica | abbina | **5** |
| musica | notazione | **8** |

Cosa vuol dire giocando: una materia viene incontrata ~138 volte in una
campagna, distribuite su sei o sette formati. Se il formato «grafico» ha tre
specifiche, **lo stesso grafico ricompare cinque o sei volte per partita** — e
identico alla partita successiva.

Le coppie che invece esplodono sono poche e portano quasi tutto il totale:
«smista» arriva ai milioni, «abbina» e «ordina» alle decine di migliaia dove
sono combinatori. Il totale per materia (centinaia di migliaia) è vero, ma è
**concentrato in due o tre formati**: la varietà non è distribuita.

### 1.4 Come cambia la difficoltà fra prima e seconda visita

`content_depth_audit`, difficoltà media alla prima comparsa → alla seconda:

| materia | mondi | difficoltà | prove d≥3 |
|---|---|---|---|
| matematica | 1+13 | 1.21 → 3.20 | 0% → 80% |
| italiano | 2+14 | 1.24 → 3.01 | 0% → 75% |
| coding | 3+15 | 1.31 → 3.04 | 0% → 74% |
| inglese | 4+16 | 1.23 → 3.00 | 0% → 73% |
| fisica | 5+17 | 1.27 → 3.04 | 0% → 78% |
| musica | 6+18 | 2.02 → 3.04 | 29% → 74% |
| latino | 7+19 | 2.01 → 3.72 | 25% → 100% |
| elettronica | 8+20 | 2.04 → 3.72 | 27% → 100% |
| geografia | 9+21 | 2.00 → 3.70 | 27% → 100% |
| scienze | 10+22 | 2.04 → 3.76 | 29% → 100% |
| **storia** | 11+23 | **3.05** → 3.71 | **76%** → 100% |
| **logica** | 12+24 | **3.04** → 3.71 | **73%** → 100% |

---

## 2. I punti deboli, in ordine di quanto fanno male

### 2.1 ✔ RITIRATO — «la prima lezione di storia è a difficoltà 3»

> **Correzione del 3 agosto, sera. Avevo torto, e di parecchio.**
>
> Avevo letto la colonna «prima comparsa» di `content_depth_audit` come *primo
> incontro del bambino con la materia*. Non lo è: è la prima volta che quella
> materia fa da **ospite** di un mondo. Sono due cose diverse, e la differenza
> ribalta la conclusione.
>
> Misurato con `subject_presence_probe.gd`: **ogni mondo contiene tutte e dodici
> le materie**, dal primo. Diciotto eventi per mondo — sette della materia
> ospite, che contano per il gate, e **undici di pratica, uno per ciascuna delle
> altre materie**. Vengono da
> `MissionEventDirector.other_subjects()`, che restituisce l'intero ciclo.
>
> Quindi la storia si incontra al **mondo 1**, non al mondo 11, e a quel punto
> `target_difficulty(1)` vale **1**. La curva reale per la storia è: banda 1 ai
> mondi 1–5, banda 2 ai 6–10, banda 3 dall'11. È una progressione corretta.
>
> In più il correttivo di padronanza funziona: con mastery 0.3 il mondo 11 scende
> a banda 2 e il mondo 19 a banda 3.
>
> **Lascio la sezione con l'errore visibile invece di cancellarla**, perché il
> modo in cui l'ho preso è istruttivo: un audit misurava una cosa, io ho letto
> l'etichetta e ho creduto misurasse un'altra. La difesa non era rileggere il
> ragionamento — era misurare la cosa vera, che è quello che ho fatto dopo.

Quello che **resta** vero, e va guardato, sta in 2.1-bis.

### 2.1-bis ⚠ La pratica è dove sta l'apprendimento, e non conta per niente

Gli undici eventi di pratica hanno `countsForGate: false`. Non aprono l'apparato,
non fanno salire di livello, non sbloccano niente. Alimentano padronanza e
ripasso spaziato — che è la cosa giusta dal punto di vista didattico — ma dal
punto di vista di un bambino con un obiettivo, **si possono ignorare tutti**.

Chi li ignora arriva al mondo 11 senza aver mai fatto storia e trova la lezione
ospite a banda 3. Lo scenario che avevo descritto **esiste**: non è il caso
normale, è il caso di chi gioca puntando al traguardo. E il correttivo di
padronanza lo protegge di una banda sola.

Due rimedi possibili, non alternativi:

1. **Legare la difficoltà all'esperienza nella materia.** Il dato esiste già nel
   save: `missionsBySubject`, «subject → int cumulativo, mai azzerato». Il
   livello resta il tetto, l'esperienza diventa il pavimento:
   `min(target_per_livello, 1 + sessioni_materia / 4)`. Chi ha praticato arriva
   preparato; chi ha saltato riparte da dove è davvero.
2. **Dare alla pratica una ricompensa che non sia il gate.** Non energia — sarebbe
   una miniera. Il Codex di NORA e gli stadi di relazione degli abitanti sono già
   lì: una pratica fatta è un argomento che avanza nel Codex, ed è la moneta
   giusta perché è *sapere*, non valuta.

### 2.1-ter ✔ Il vincolo delle dodici materie, adesso è un contratto

`subject_presence_audit.gd` (nuovo) verifica per tutti e 24 i mondi: dodici
materie presenti, almeno undici raggiungibili entro il raggio, **esattamente un
evento di pratica per ognuna delle altre undici**, e nessun doppione sulla
materia ospite.

Serviva perché la proprietà era **emergente, non garantita**: bastava un filtro
ragionevolissimo — «solo le materie già sbloccate» — per farla sparire senza che
nessun test diventasse rosso.

Una cosa da sistemare, ed è di Codex: al **mondo 8** una materia su dodici cade
**oltre il raggio raggiungibile**, perché il direttore distribuisce le pratiche
fino a `reach + 350`. Presente ma non raggiungibile: 23 mondi su 24 sono a 12/12.

`ContentManager.target_difficulty(level)` guarda **solo il numero del mondo**:

```gdscript
if level <= 12:
    return clampi(1 + (level - 1) / 5, 1, 3)
```

Al mondo 11 il target è 3. Ma il mondo 11 è la **prima volta in assoluto** che
un bambino incontra la storia in questo gioco. Risultato misurato: il primo
contatto con la storia ha difficoltà media **3.05**, con il **76%** delle prove
a difficoltà ≥3 — mentre il primo contatto con la matematica sta a 1.21 e 0%.

Il correttivo di mastery non salva: al primo contatto la mastery è ignota
(`-1`), quindi `mastery_nudge` vale 0 e non abbassa niente.

Un bambino che arriva al mondo 11 ha imparato tanto — ma non ha imparato
*storia*. Gli si chiede di partire dal terzo gradino di una scala che non ha mai
salito. È esattamente il modo in cui si perde uno studente su una materia
intera, ed è didatticamente indifendibile.

**Rimedio proposto**: far dipendere il target dall'**esperienza nella materia**,
non dall'indice del mondo.

```
target = min( target_per_livello(level), 1 + sessioni_fatte_in_quella_materia / k )
```

Al primo contatto si parte sempre da 1–2, qualunque sia il mondo; chi arriva al
mondo 11 avendo già fatto storia nelle missioni di varietà ci arriva più in
alto. Il tetto per livello resta come massimo, non come minimo.

**Attenzione**: tocca `content_manager.gd` e cambia l'equilibrio di tutta la
campagna. Va misurato prima e dopo su entrambi gli estremi (mondo 1 e mondo 24) e
riverificato contro `gate_readiness` e gli audit di padronanza.

### 2.2 ⛔ Undici materie su dodici hanno banchi di sola scelta multipla

Misurato: **100% `multiple_choice`** in italiano, coding, inglese, fisica,
musica, latino, elettronica, geografia, scienze, storia, logica. Solo la
matematica ha un secondo formato (27% `numeric_input`).

La varietà di formato esiste — arriva dalle 412 specifiche di minigioco — ma
significa che **ogni singolo item di banco è una domanda a quattro opzioni**, e
che la parte non-indovinabile dell'esperienza poggia su ~30 specifiche per
materia.

La decisione vincolante dice «tetto 33%, target ~20%» ed è rispettata sul mix di
sessione. Ma il mix regge grazie ai minigiochi: se un giorno il direttore
pescasse più dal banco, la quota crollerebbe verso il 100% senza che nessuno
cambi una riga di contenuto.

**Rimedio proposto**: introdurre `numeric_input` e risposta breve nei banchi
delle materie dove è naturale — fisica (calcoli), elettronica (valori), musica
(intervalli e durate), geografia (coordinate e distanze), latino (forma
richiesta). Non serve convertire tutto: portare ogni banco al **20–30% di
non-scelta-multipla** toglie la dipendenza strutturale.

*Prerequisito*: il tastierino numerico introdotto il 3 agosto — senza, ogni
risposta libera è inaccessibile su tablet.

### 2.3 ⚠ La varietà è concentrata in due formati su dieci

**43 coppie (materia, formato) su 73 producono meno di 100 prove distinte**, e
quasi tutte ne producono meno di quindici — a fine campagna, con tutto sbloccato.

Il totale per materia è alto (centinaia di migliaia) ma arriva quasi tutto da
«smista» e da due o tre altri formati combinatori. Negli altri il giocatore vede
un piccolo insieme fisso che ricompare cinque o sei volte per partita, identico
alla partita dopo.

**Rimedio proposto**, in ordine di resa per sforzo:

1. **Rendere combinatori due formati oggi fissi.** È il rimedio con la resa più
   alta di tutti, perché non aggiunge contenuto: cambia come si usa quello che
   c'è. Un grafico con gli stessi dati ma **domanda variabile** («quale mese ha
   il massimo?» / «di quanto sale fra marzo e aprile?» / «quale colonna supera
   la linea?») moltiplica per quattro o cinque ogni specifica esistente. Vale
   per grafico, circuito, carta muta e reperti;
2. **Portare a 8–10 specifiche** le coppie che oggi ne hanno 3 o 4. Sono ~15
   coppie: 60–90 specifiche nuove in tutto, ed è lavoro di scrittura piano;
3. carta muta (3 bersagli) e atlante dei reperti (4): appennini, alpi, tirreno,
   adriatico, tevere, una carta d'Europa, un secondo foglio di reperti;
4. banda 4 di elettronica (9 item su 3 argomenti) e fisica (8 su 6): i mondi
   19–24 sono un quarto della campagna e pescano da lì.

Il punto 1 va discusso con Codex: cambia il contratto dei formati visuali, che
lui sta cablando adesso. **Prima si decide, meno costa.**

### 2.4 ⚠ Il divario 23 a 1 fra inglese e scienze

1109 item contro 48. L'inglese è sovrabbondante perché il vocabolario è
generabile a tappeto; scienze, fisica, coding ed elettronica hanno banchi da
cinquanta item.

Non è grave quanto sembra — le specifiche di minigioco sono equilibrate e
scienze ne ha 42, il massimo — ma vuol dire che **nelle materie STEM il banco non
regge da solo** e ogni sessione dipende dai minigiochi. Portare i quattro banchi
poveri a ~120 item li renderebbe autosufficienti.

### 2.5 ⚠ Dall'esercizio non si esce

Nessun pulsante di abbandono, nessuna gestione di `ui_cancel` in
`exercise_player.gd`. Il 3 agosto questo ha trasformato un difetto di input (il
campo numerico non compilabile su tablet) in un **blocco totale**: unica via
d'uscita, chiudere il gioco.

Il tastierino risolve il caso di oggi, ma la fragilità resta e contraddice
«niente blocca il loop». Aggiungere un'uscita è però una scelta di design — un
bambino potrebbe usarla per saltare ogni esercizio — e va decisa, non subita.

### 2.6 ℹ La quota di «lezione» oscilla senza motivo

Misurata alla prima comparsa: fisica **70%**, latino 70%, elettronica 60%,
logica 60% — ma inglese **26%**, italiano 31%. Non c'è una ragione didattica per
cui la fisica debba spiegare tre volte più dell'inglese al primo incontro.
Sospetto un effetto collaterale della copertura dei topic, non una scelta.
Da guardare, non urgente.

> **Risolto, 16 agosto 2026.** La sospetta correlava con `NoraExplanations`:
> `entry_for()` predilige la voce di contesto («perché» generale) quando esiste,
> e cade sulla riformulazione stretta dell'item quando manca. Misurato lo stesso
> giorno: **111 argomenti su 246 (45%) non avevano voce di contesto**, quasi
> tutta fisica (14/22) ed elettronica/scienze a metà (13/21 ciascuna) — la
> materia con la copertura più bassa **è** quella che sembrava «spiegare
> meno», solo che il sintomo misurato qui era la conta delle sessioni di tipo
> lezione, non la profondità di quello che dicevano. Scritte le 111 voci
> mancanti (`godot/scripts/game/nora_explanations.gd`, stesso formato
> perché/come delle 135 esistenti), copertura ora 246/246, verificata da
> `nora_explanation_depth_audit.gd` (nuovo — impedisce la regressione). Non
> risolve la domanda originale di questa sezione (perché fisica *apra* più
> spesso con una lezione rispetto a inglese) ma toglie la spiegazione più
> probabile: ora ogni argomento, qualunque sia la sua frequenza di apertura,
> porta lo stesso contesto più ampio della singola domanda.

---

## 3. La storia: cosa funziona e cosa no

### 3.1 Com'è fatta

Sette colpi di scena ai mondi 5, 8, 12, 16, 19, 23, 24, ognuno con ≥3 semi nei
mondi precedenti (28 semi in totale, verificati da `mystery_audit`). Tre atti:
*I morti che non sono morti* → *La stanza che non c'è* → *Chi tiene la porta*.

La spina dorsale è solida e ha una qualità rara: **ogni colpo riscrive
all'indietro** invece di aggiungere. Il colpo 3 («la tua è la dodici») cambia il
significato del beat 1; il colpo 7 («le ho perse dicendogli tutto») cambia il
significato dell'intera meccanica di gioco. Un bambino che rigioca vede un altro
gioco, e questo è il pezzo di design migliore del progetto.

Il Tredicesimo non minaccia mai: chiede, avverte, supplica. Le sue cinque azioni
sono tutte reversibili e tre su cinque costano zero. È un antagonista che fa
paura senza fare male — cosa difficile da tenere, e per questo è vincolata da
audit.

### 3.2 Il punto forte: il tema regge il gioco, non lo decora

«Il sapere che passa di mano senza essere capito fabbrica Silenzio» non è un
pretesto: è la stessa cosa che il gioco fa fare al giocatore. NORA non dà mai la
risposta perché ha perso undici sorelle dandogliela. La meccanica **è** il tema.
Nella maggior parte dei giochi educativi la storia è una carta da parati; qui, se
togli la storia, la meccanica smette di avere una ragione.

### 3.3 Le debolezze narrative

**a) Il secondo atto è tutto rivelazione e poca azione.** Dal mondo 9 al 16 il
giocatore *scopre* cose — la rotta è un giro, ci sono dodici schede, c'è una
stanza in più — ma non gli viene chiesto di **fare** niente di diverso da prima.
Il primo atto ha lo stesso problema in misura minore. L'antagonista entra al 17:
per sedici mondi non c'è nessuno che ostacoli, solo cose da capire.
*Rimedio*: anticipare almeno una azione del Tredicesimo — la più innocua,
`scrive` — a un mondo dell'atto II, come evento isolato e senza spiegazione. Un
«FERMATI» su un'insegna al mondo 13 costa zero e cambia il ritmo di otto mondi.

> **✔ Fatto, 19 agosto 2026.** È il momento d'autore del mondo 12
> (`world_set_piece.gd`, forma `scritta`): una parola sola su un'insegna, senza
> spiegazione e senza minaccia. Vedi [DESIGN_COMPLETO §10.1](DESIGN_COMPLETO.md).

**b) Meridiana arriva tardi per quanto pesa.** È il colpo 6, al mondo 23, e
regge il Secondo Viaggio intero — ma i suoi semi sono solo quattro e tre stanno
oltre il mondo 20. Chi finisce il gioco la incontra come una notizia, non come
una persona.
*Rimedio*: due o tre semi in più nell'atto I, di quelli che non si capiscono al
primo giro. La spirale all'altezza di una bambina (mondo 2) è esattamente il tipo
giusto: ne servono altre.

**c) Le undici sorelle non hanno un volto prima del colpo 7.** Il mondo 24 dice
«le ho perse tutte» e dovrebbe fare male, ma il giocatore non ha mai incontrato
nessuna di loro: sono un numero. Gli Sbiaditi esistono già come nemici del mondo.
*Rimedio*: rendere **uno** Sbiadito riconoscibile — che ripete una frase che NORA
ha detto al giocatore dieci mondi prima. Un solo caso, senza spiegazione. Al
colpo 7 quel ricordo torna e il numero diventa una persona.

> **✔ Fatto, 19 agosto 2026.** È il momento d'autore del mondo 16 (forma `eco`):
> una sacca si ferma e dice «Non te la do io la risposta. La rifai tu».

**d) La conta di nonna Ersilia è l'unica chiave e si sente una volta sola.** Se
un bambino salta quel dialogo nei primi cinque minuti, al mondo 24 non ha la
serratura. C'è un beat di ripiego per le tre Tracce decisive, ma **non per la
conta**.
*Rimedio*: farla riaffiorare almeno due volte — un Bislacco che la canticchia
storpiata, un'iscrizione con le stesse tre sillabe. Il ripiego narrativo esiste
già come pattern: qui manca.

**e) Il finale del giocatore che ha giocato poco è più povero, e non dovrebbe.**
Al Cuore convergono i residenti portati allo stadio 2. Chi ne ha portati zero
trova i sei itineranti — quindi non è mai vuoto, ed è verificato — ma la scena è
sensibilmente più breve. È coerente («chi ti aspetta dipende da chi hai fatto
crescere») e va bene così: lo segnalo perché è una scelta, e va confermata
sapendo cosa comporta.

**f) Il Custode non è mai nella storia.** Ha 18 segnali, espressioni, un'indole,
e Lucilla che gli parla — ma non compare in nessuno dei 24 beat né in nessun
colpo di scena. È il compagno costante del giocatore ed è narrativamente muto.
*Rimedio*: un solo beat in cui NORA lo nomina, e una reazione del Custode al
colpo 5. Poco, ma lo lega.

> **Parzialmente fatto, 19 agosto 2026.** Il Custode adesso **agisce**: le tane
> sono la prima interazione del gioco che non apre un pannello, e il buio del
> mondo 8 è il primo momento in cui la sua presenza cambia che cosa si vede
> ([PET_CUSTODE §3.5](PET_CUSTODE.md)). Resta da fare la parte narrativa vera:
> un beat in cui NORA lo nomina.
>
> **Ancora, 2 settembre 2026.** Il Custode **c'è quando la storia si ribalta**:
> nei mondi 5, 8, 12, 16, 19, 20, 23 e 24 — i sette colpi di scena — alza la
> testa mentre NORA parla (segnale `story_reveal`, faccia «attento»). Non dice
> niente, perché non parla; smette però di essere l'unica presenza che non si
> accorge della cosa più grossa della partita. E la sua collezione adesso sa
> dove siete stati (§5.3). **Resta ancora da fare** il beat in cui NORA lo
> nomina: quello tocca il testo autoritativo di TRAMA §8 e va deciso lì.

---

## 4. Cosa farei, in questo ordine

| # | Cosa | Perché prima | Chi |
|---|---|---|---|
| 1 | **Difficoltà legata all'esperienza nella materia**, non al numero del mondo | È l'unico difetto che può far perdere un bambino su una materia intera | Claude + misura |
| 2 | Uscita dall'esercizio (decisione di design) | Un blocco non deve poter esistere | tu decidi, Codex fa |
| 3 | Le 9 coppie (materia, formato) sotto 100 prove | Poche specifiche, resa immediata | Claude |
| 4 | `numeric_input` e risposta breve nei banchi non linguistici | Toglie la dipendenza strutturale dalla scelta multipla | Claude |
| 5 | Anticipare una azione del Tredicesimo nell'atto II | Otto mondi senza antagonista sono troppi | Claude |
| 6 | Semi di Meridiana nell'atto I, uno Sbiadito riconoscibile, la conta che riaffiora | Fanno male i tre colpi che devono fare più male | Claude |
| 7 | Banchi STEM da 50 a ~120 item | Rende i banchi autosufficienti | Claude |
| 8 | Carta d'Europa e secondo foglio di reperti | Sblocca due formati oggi quasi statici | Claude, dopo il cablaggio |

**Nessuno di questi è un blocco per cablare i mondi 1–6.** Il numero 1 conviene
farlo prima del collaudo, perché altrimenti si collauda una curva di difficoltà
che sappiamo già sbagliata dal mondo 9 in poi.

---

## 5. Il lotto del 2 settembre 2026 — contenuto scritto e mai collegato

*Richiesta: «analizza storia, missioni e mondi; aumentiamo l'integrazione fra
tutte le parti usando come guida la trama; aumentiamo profondità e accuratezza
della storia, degli oggetti di bottega, di NORA e del Pet».*

L'analisi ha trovato un difetto che si ripete in quattro punti diversi del
progetto, sempre nella stessa forma: **contenuto scritto per intero, verificato
da un audit, e mai letto dal gioco.** Non è mancanza di materiale — è
mancanza del filo che lo porta al giocatore.

### 5.1 I Dodici Maestri erano scritti e non li sentiva nessuno

`MaestriCatalog` contiene **96 battute** — 36 aperture, 36 rilanci, 24 chiusure,
una per ciascuno dei dodici Maestri — e fino al 2 settembre era citato **da un
solo file in tutto il progetto: il proprio audit**. `maestri_audit` verificava
che i dati fossero completi e coerenti, e lo erano; nessuno verificava che
qualcuno li leggesse. La sua stessa intestazione annunciava una regia («la regia
è di `nora_context_engine.gd`») che non era mai stata scritta.

Conseguenza: la regola vincolante di [TRAMA §6.1.4](TRAMA_E_MISTERO.md) — *«NORA
cambia voce mentre guarisce»* — era vera nei documenti e **falsa nel gioco**.
Dopo aver riparato dodici apparati NORA parlava esattamente come al primo minuto.

**Adesso l'apparato riparato cambia come NORA parla di quella materia.** Tre
punti di innesto, uno per momento:

| momento | prima | adesso, con l'apparato acceso |
|---|---|---|
| apertura sessione | formula unica per atto | l'apertura del Maestro + la frase di metodo |
| errore | 4 battute di consolazione per atto | il **rilancio** del Maestro: quello che dice al posto della risposta |
| prova risolta | battuta di NORA | ogni tre volte, la chiusura del Maestro |
| apparato riparato | battuta di NORA | **resta di NORA**: è il momento in cui un Maestro si sveglia |

Due cancelli, già scritti in `voices_for` e mai chiamati: **l'apparato riparato
libera la voce, la materia incontrata la chiama** (`data-core` tiene Stilo e
Faro; ripararlo al mondo 2 per l'italiano non deve svegliare l'inglese, che il
giocatore incontra al mondo 4). E la logica tace per ventitré mondi, perché il
suo Maestro è fuori: torna solo con il nome restituito.

Il rilancio non copre NORA — si alterna con le sue battute. Chi guarisce prende
un'inflessione, non diventa qualcun altro.

Lo tiene `maestri_voce_viva_audit`, che verifica il **comportamento** e non i
dati: che una partita nuova non abbia voci, che un apparato riparato si senta,
che la materia chiami, che la logica taccia, che NORA non sparisca — e che il
collegamento esista nel codice di gioco, perché è esattamente la riga che
mancava.

### 5.2 Le riparazioni dei Dodici non dicevano di chi erano

`MinimissionCatalog` dichiara che «ogni riparazione è una cosa che uno dei Dodici
stava facendo quando è arrivato il Silenzio». Misurato: i mondi **1–12**
nominavano il proprietario con un **ordinale** («La Prima», «L'Ottavo») che non
compare in nessun altro punto del gioco, e i mondi **13–24 non nominavano
nessuno**. Metà del filo non esisteva; l'altra metà era anonima.

Adesso ogni incarico porta il nome del Maestro della sua materia — **lo stesso
alla prima e alla seconda visita**, perché è la stessa persona che ha lasciato
indietro due cose — e la frase che lo nomina dice anche *come lavorava*: Rame
seguiva il percorso fino in fondo, Seme cambiava una cosa per volta, Clessidra
accendeva una fonte solo quando qualcuno la interrogava. Chi ripara il mulino del
mondo 15 sta finendo il ciclo di Telaio, e Telaio è la voce che gli parla di
coding da quando ha riacceso il Cratere: le due metà di questo lotto si tengono.

Due eccezioni, e sono la trama: i mondi 12 e 24 sono della logica, il cui Maestro
è il Tredicesimo. Il mondo 12 adesso lo **dice** — è l'unica riparazione per cui
non c'è nessuno da chiamare, e il nome sui registri è stato raschiato con una
lama — trasformando un ordinale muto in un seme del colpo 2. Verificato da
`minimission_audit._ogni_riparazione_ha_un_padrone`, che pretende il nome ovunque
e lo **vieta** nei due mondi della logica.

### 5.3 Il diario del Custode non diceva dove sei stata

`PetGifts` aveva **16 regali, identici in tutti e ventiquattro i mondi**:
`pick()` non sapeva nemmeno dove si trovasse. Il file prometteva «dopo
ventiquattro mondi quella lista è il diario del viaggio», e il diario diceva *«Un
sasso — mondo 7»*: del mondo 7 c'era solo il numero, scritto dalla schermata e
non dal regalo. Il compagno che accompagna tutta la partita era l'unico sistema
affettivo che non sapeva niente dei luoghi che attraversa.

Adesso i regali sono **40**: i sedici di sempre — il sasso e il bottone sono la
battuta, e sono il motivo per cui un regalo non vale niente — più **uno per
mondo**, che si trova solo lì. Un regalo su due viene dal posto: una scaglia
dell'obelisco, un ingranaggio a cui manca il terzo dente, un grumo di sabbia fusa
da un fulmine. Il guard-rail non si muove di un millimetro: i ventiquattro sono
inutili quanto i sedici, e nessuno vale più di un altro.

### 5.4 La bottega sbagliava i posti

Il campo `origine` è l'unica superficie con cui la bottega tocca la storia, e dal
14 agosto il campo `mondo` lo rende una regola. Nessuno però confrontava il testo
con la regola. **Otto voci su ottantatré** non tornavano:

- il **Soffietto** si consegna alla Soglia del Tempo (mondo 11) e citava la Sala
  delle Ere, che è il mondo 23;
- il **Ricordo del mondo 5** lo faceva togliere dal binario a Ruggine, che vive
  nel mondo 3 e non si sposta mai;
- la **Zavorra**, un modulo comprabile ovunque, citava anche lei Ruggine;
- **sei restauri** nominavano il materiale di un mondo preciso senza chiedere di
  esserci mai stati.

Corretti i testi e aggiunte le sei ancore mancanti. `bottega_coerenza_audit` ora
verifica che nessuna voce nomini un luogo o una persona di un altro mondo, e
tiene un cricchetto sulla quota di voci ancorate che raccontano davvero il
proprio posto: **25 su 62**, e da qui si sale soltanto.

### 5.5 Il Custode non si accorgeva dei colpi di scena

Il punto (f) di §3 lo aveva già segnato: il compagno costante del giocatore non
compare in nessuno dei ventiquattro beat né in nessuno dei sette colpi. Il
rimedio prescritto era «una reazione del Custode al colpo 5».

Adesso c'è, e per tutti e sette: nei mondi **5, 8, 12, 16, 19, 20, 23 e 24** il
Custode alza la testa mentre NORA parla (`story_reveal`, faccia «attento»). Non
gli si fa dire una battuta — non parla, ed è giusto così — ma smette di essere
l'unica presenza in scena che non si accorge della cosa più grossa della partita.
La lista dei colpi vive in `NarrativeManager.COLPI`, dove l'intestazione del file
la dichiarava già a parole senza che nessuno potesse leggerla.

Resta aperto il beat in cui NORA lo nomina: quello tocca il testo autoritativo di
[TRAMA §8](TRAMA_E_MISTERO.md) e va deciso lì, non qui.

---

## 6. Il lotto del 2 settembre, seconda parte — Eli

*Richiesta: «cerchiamo una trama adatta a una ragazza di 11-15 anni».*

### 6.1 Quello che l'analisi ha sbagliato, e la correzione

La prima diagnosi diceva che **Eli non esiste**: nessun passato, nessun
desiderio, nessuna paura, nessuno che l'aspetta — una mano competente che ripara
cose. È vero **solo per la prima metà del gioco**. Dal mondo 12 in poi Eli esiste
eccome: `SistersThread` le dà una voce sopra ognuna delle undici sorelle, e al
mondo 24 una scena in cui è arrabbiata, non chiede scuse e chiede a NORA una
regola nuova. L'intestazione di quel file dice esattamente la cosa giusta sul
lettore — *«a dieci anni passa; a tredici no»*.

Il buco vero erano i **mondi 1–11**, e il taccuino: i pensieri che aveva già
duravano tre secondi l'uno.

### 6.2 La prima metà segue Squadra

Nei mondi 1–11 c'erano quattro semi che *provano* l'esistenza delle undici — un
bollo di collaudo, una targhetta, una frase di Mirta — e le prove non fanno
compagnia. Adesso la prima metà segue **l'undicesima**, quella immediatamente
prima di Eli, il cui fascicolo al mondo 23 ha «l'inchiostro di poche settimane
fa»: stessa strada, appena percorsa. Cinque segni nei mondi 1, 3, 4, 7 e 8, tutti
con la voce di Eli sopra, e tutti segni **di lavoro** — non spirali, che sono di
Meridiana. Dettagli in [TRAMA §3](TRAMA_E_MISTERO.md), colpo 3.

Misurato dopo il lotto: la prima metà porta 9 segni in 9 mondi, 7 con un pensiero
di Eli. Prima erano 4 segni e 2 pensieri.

### 6.3 Il taccuino, e il finale che legge da lì

Le 83 righe di Eli sparse nel gioco adesso si accumulano in un taccuino che si
apre dal diario e si rilegge dall'ultima pagina. Da lì il finale del mondo 24
nomina due cose vere che ha fatto — conteggi, mai voti, mai una mancanza — e chi
non si è fermato mai riceve una riga sua, calda. Nessun ramo: cambiano due
battute dentro la stessa scena.

### 6.4 Cosa resta aperto di questa richiesta

- **I momenti duri che si riparano.** La risposta era «Eli può chiudersi,
  rispondere male, non voler parlare per una scena, purché si ricuca». Oggi
  esiste in un punto solo — l'incrinatura con Vera — ed è dell'altra, non di Eli.
- **Le battute in scena.** Il taccuino è fatto; Eli che *risponde ad alta voce* a
  NORA fuori dal mondo 24 non ancora.
- **Meridiana al mondo 1.** Il suo primo seme è al mondo 2. È già «da subito» in
  pratica, ma non alla lettera.

---

## 7. Le pagine di soglia, e la storia detta in chiaro (2 settembre 2026)

*Richiesta: «pagine con una piccola lettura di introduzione e di uscita da ogni
mondo, per guidare e immergere lo studente»; e «i dialoghi e le parti che
spiegano la storia non devono essere criptiche o oscure, ma adatte a un ragazzo
di undici anni».*

### 7.1 Ho misurato prima di riscrivere, e la misura ha cambiato il lavoro

| testo | parole per frase | frasi oltre 20 parole | parole da scuola |
|---|---:|---:|---:|
| beat di NORA (24) | 7,9 | 1 su 87 | 0 |
| briefing d'ingresso (24) | 9,9 | 2 su 72 | 1 |
| debrief d'uscita (24) | 6,6 | 0 su 48 | 2 |
| minimissioni · apertura | 13,9 | 5 su 58 | 0 |
| semi del mistero | 13,7 | 12 su 62 | 0 |

**I testi non sono lunghi.** Se il problema fosse stato la lunghezza, la
correzione sarebbe stata accorciare — e non avrebbe aiutato nessuno. Il problema
è che la storia è raccontata **per allusioni**: *«Il sigillo ha tredici posti e
undici nomi. Uno raschiato con una lama, dall'interno.»* Sono nove parole, ed è
un enigma dentro un enigma.

La scelta è stata **non appiattire i beat** — l'allusione è ciò che rende la
storia bella — ma affiancargli una versione detta in chiaro, una volta per mondo,
quando il mondo si chiude.

### 7.2 La pagina di uscita

L'ingresso esisteva già (`WorldIntroPanel`). L'uscita no, e `WorldLessonCatalog`
dichiarava per iscritto che il suo `debrief` **restava senza lettore**: il difetto
ricorrente di questo progetto, per la quinta volta.

Adesso, appena l'apparato torna in linea, si apre una pagina con quattro parti —
le quattro domande che un ragazzino si fa uscendo da un posto, nell'ordine in cui
se le fa:

| parte | che cosa dice |
|---|---|
| QUI È CAMBIATO QUESTO | una cosa del mondo che era ferma e adesso funziona |
| ADESSO SAI FARE | la competenza con parole di azione, mai di scuola |
| **LA STORIA, IN CHIARO** | **quello che il beat ha detto per accenni, detto piano** |
| DOVE SI VA | il prossimo mondo, e perché ha senso andarci |

`world_readings_audit` tiene sei regole: ci sono tutte e ventiquattro con tutte e
quattro le parti; nessuna parola da pagella; **nessuna anticipa** un colpo di
scena successivo; nessuno muore; nessuna rimprovera chi ha appena finito il
mondo; e ogni lettura ha la sua tavola dipinta, che esiste come file.

Ogni pagina è illustrata con l'`underpaint` del proprio mondo — le ventitré
pitture che `ChunkGround` stende sotto il terreno e che finora si vedevano solo
di sbieco, sfocate sotto l'erba. Qui hanno una pagina intera, e non è servita
arte nuova.

### 7.2-bis Il tetto sulla lunghezza delle frasi era sbagliato, e l'ho tolto

La prima stesura dell'audit bocciava le frasi oltre le 18 parole. **Era un errore
che i miei stessi numeri smentivano**: la tabella qui sopra dimostra che i testi
non erano lunghi — 7,9 parole per frase nei beat — e che il difetto era
l'allusività. Ho messo un cricchetto proprio sulla cosa che avevo appena
scagionato, e per rispettarlo ho spezzato diciassette frasi, diverse delle quali
stavano meglio intere:

> *«Uno è stato raschiato via con una lama, da dentro la nave, dopo che si era
> chiusa: qualcuno voleva che quella persona sparisse.»*

Ventitré parole, ed è una frase buona; tagliata in due diventa scattosa. Un
ragazzo di undici anni legge romanzi con frasi il doppio più lunghe: quello che
non regge non è la frase lunga, è la frase oscura.

Le diciassette frasi sono state ricucite, e resta un solo controllo sulla misura
— **la guardia contro l'incidente**, a quaranta parole: non è una regola di
stile, prende il caso in cui due pensieri finiscono uniti per sbaglio. La media
si stampa come informazione e non fa fallire niente: dopo la ricucitura e
l'allungamento delle sei letture dei colpi di scena sta a **13,0**.

> Restano vere le altre tre correzioni della stessa giornata, che erano regole
> mie scritte male: «tredicesimo» vietato prima del mondo 19 bocciava il mondo 8,
> dove il *tredicesimo posto* è proprio la scoperta; «distanza» faceva scattare
> «istanza»; e «non è morta» — la frase con cui il documento stesso enuncia il
> guard-rail — veniva letta come una morte.

### 7.3 Le tre cose che restavano aperte

- **Meridiana al mondo 1**: fatto. Sotto la spirale fresca ce n'è un'altra quasi
  sparita, stessa forma, solco consumato. È il seme del colpo 6 e insieme la
  prima crepa nel colpo 1: la spirale fresca smette di poter essere di una
  persona sola.
- **Un momento duro di Eli che si ricuce**: fatto, al mondo 16, dove NORA ammette
  di averla girata attorno alla stanza senza porta per sedici mondi. Tre
  reazioni, nessuna giusta e nessuna punita: chiudersi, pretendere tutto, o
  perdonare e segnarselo. La ricucitura arriva al mondo 18 e **arriva comunque**,
  perché una reazione emotiva non può avere conseguenze (§10.6).
- **Le battute in scena di Eli fuori dal mondo 24**: parzialmente. Al mondo 16
  adesso parla, e nel taccuino si legge quello che pensa. Resta da darle voce nei
  dialoghi ordinari con gli abitanti.
