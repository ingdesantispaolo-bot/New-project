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
