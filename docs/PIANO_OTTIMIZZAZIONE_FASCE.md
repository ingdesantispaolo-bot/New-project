# Piano di ottimizzazione — otto fasce e tre priorità

Scritto il **9 settembre 2026**. Ogni numero qui dentro è stato misurato oggi
contro il repo, con tre sonde scritte apposta e citate per nome. Nessun numero è
riportato da un documento precedente.

Questo piano risponde a una domanda sola: **dopo il passaggio a otto fasce di
difficoltà e a tre fasce di priorità, dove il gioco è più debole, e qual è
l'ordine di lavoro che lo ripara con meno scrittura possibile.**

Documenti collegati: [insieme.md](../insieme.md) (voci G-C12, G-C13, R-17, R-18,
G-17) · [Registro dei lavori](RELEASE_CANDIDATE.md) ·
[Design](DESIGN_COMPLETO.md)

---

## Come sono stati presi i numeri

Tre sonde di sola lettura, tutte in `godot/scripts/game/`. Non sono audit: non
hanno `assert`, il runner non le raccoglie, e servono a *misurare* — le guardie
vere sono la Fase 5 di questo piano.

| sonda | che cosa misura |
|---|---|
| `censimento_fasce_probe.gd` | item di banco e ricette di minigioco per materia e per fascia, chiesti al motore e non ai file |
| `costo_banchi_probe.gd` | quanto costa leggere e interpretare i dodici banchi, separato dal resto dell'avvio |
| `avvio_mondo1_probe.gd` | lo stesso mondo istanziato quattro volte di seguito, per separare il costo che si paga una volta sola |

Più una misura strumentando `scripts/build-exercise-banks.mjs` in una copia, per
contare gli item che passano dal ponte 4→8.

---

## 1 · Che cosa dicono i dati

### 1.1 Il banco non è povero: è sbilanciato, e in un verso che nessuno ha deciso

4854 item, 198 argomenti, 12 materie. Il nucleo è il 65,7% del banco. Ma la forma
per fascia cambia segno da materia a materia:

| materia | tier | tot | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | forma |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| inglese | 1 | 1466 | 418 | 256 | 237 | 110 | 104 | 102 | 134 | 105 | **scende** |
| matematica | 1 | 944 | 51 | 52 | 108 | 94 | 127 | 131 | 210 | 171 | **sale** |
| italiano | 1 | 780 | 228 | 111 | 96 | 73 | 86 | 79 | 57 | 50 | **scende** |
| fisica | 2 | 229 | 25 | 24 | 24 | 22 | 37 | 46 | 29 | 22 | piatta |
| geografia | 2 | 199 | 14 | 13 | 30 | 30 | 35 | 35 | 21 | 21 | a campana |
| coding | 2 | 195 | 7 | 8 | 28 | 28 | 37 | 33 | 27 | 27 | a campana |
| latino | 3 | 289 | 11 | 10 | 46 | 45 | 58 | 58 | 31 | 30 | a campana |
| storia | 3 | 167 | 11 | 11 | 21 | 21 | 29 | 28 | 23 | 23 | a campana |
| elettronica | 3 | 159 | 12 | 10 | 24 | 23 | 24 | 23 | 22 | 21 | piatta |
| scienze | 3 | 154 | 16 | 15 | 21 | 20 | 26 | 25 | 16 | 15 | a campana |
| musica | 3 | 148 | 11 | 10 | 18 | 17 | 23 | 28 | 22 | 19 | a campana |
| logica | 3 | 124 | 9 | 8 | 15 | 14 | 16 | 16 | 23 | 23 | sale |

**Matematica sale, italiano e inglese scendono.** Il lessico è tanto e facile, la
sintassi è poca e difficile: in italiano un bambino al mondo 22 trova un terzo
del materiale che aveva al mondo 2, cioè meno varietà proprio dove le domande
sono più dure. Nessun documento ha mai dichiarato che debba essere così — è la
somma delle sorgenti, non una scelta.

### 1.2 Il numero che conta non è quanti item ci sono, ma quante sessioni distinte reggono

L'item vive in **una** fascia; la selezione ne ammette ±1. Il pozzo reale di una
fascia è quindi la somma di tre fasce, e va diviso per gli esercizi che la
sessione consuma — 6, 5 o 1 secondo la fascia di priorità.

| materia | esercizi/sessione | fascia peggiore | pozzo | **sessioni prima di ripetere** |
|---|---:|---|---:|---:|
| **coding** | 5 | **F1** | **15** | **3** |
| **geografia** | 5 | **F1** | **27** | **5** |
| fisica | 5 | F1 / F8 | 49 / 51 | 10 |
| matematica | 6 | F1 | 103 | 17 |
| italiano | 6 | F8 | 107 | 18 |
| inglese | 6 | F8 | 239 | 40 |
| logica | 1 | F1 | 17 | 17 |
| elettronica | 1 | F1 | 22 | 22 |
| storia | 1 | F1 | 22 | 22 |
| latino | 1 | F1 | 21 | 21 |
| musica | 1 | F1 | 21 | 21 |
| scienze | 1 | F1 | 31 | 31 |

**Il collo di bottiglia è la seconda fascia, non la terza — che è il contrario di
quello che sembra guardando i totali.** Coding ai mondi 1–3 ha quindici item in
tutto e ne consuma cinque per sessione: **tre sessioni e il bambino ha visto
tutto il materiale del suo grado**. Le sei materie di terza fascia sembrano
povere ma pescano un esercizio alla volta, e a quel ritmo un pozzo da venti item
regge venti sessioni.

Questo cambia il bersaglio: **non serve arricchire dodici materie, ne servono
tre** — coding, geografia, fisica — e solo nelle fasce estreme.

> **Corretto dalla Fase 0, poche ore dopo.** Questo modello aveva ragione su
> coding e geografia e **torto sulle materie di terza fascia**: le dava per sane
> perché consumano un esercizio per sessione, e `variety_audit` le ha trovate
> rosse lo stesso — latino al 33% di prove ripetute, storia al 30%, scienze al
> 27%. Due ragioni, e nessuna era nel modello: la sonda della varietà pesca
> **trenta** nodi indipendentemente dalla fascia di priorità, e soprattutto il
> selettore sceglie **prima l'argomento e poi l'item**, quindi ciò che conta non
> è il pozzo della fascia ma la **casella più piccola fra argomento e fascia**.
> Storia era rossa alla fascia 5 con settantanove item nel pozzo, perché due
> argomenti ci stavano con uno solo.
>
> Lezione di metodo: un modello dedotto vale finché non c'è una misura, e poi si
> segue la misura. Il pavimento della sezione 2 resta utile come bersaglio, ma
> **la guardia vera era già in casa** e nessuno l'aveva collegata.

### 1.3 Le ricette di minigioco: tre buchi netti

Le ricette sono cumulative (gate `minLevel`): la colonna dice quante ne *vede*
quella fascia.

| materia | tier | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | tot | meccaniche in rotazione a F1 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| inglese | 1 | 27 | 51 | 72 | 74 | 95 | 110 | 118 | **128** | 128 | 4 |
| matematica | 1 | 25 | 42 | 57 | 64 | 72 | 75 | 82 | **84** | 84 | 7 |
| italiano | 1 | 22 | 30 | 37 | 51 | 52 | 53 | 54 | **54** | 54 | 5 |
| fisica | 2 | 20 | 30 | 38 | 38 | 53 | 53 | 55 | **58** | 58 | 6 |
| coding | 2 | 23 | 37 | 43 | 44 | 47 | 48 | 51 | **53** | 53 | 6 |
| logica | 3 | 18 | 31 | 42 | 45 | 45 | 46 | 49 | **50** | 50 | 4 |
| storia | 3 | 15 | 28 | 37 | 40 | 45 | 45 | 49 | **49** | 49 | 4 |
| geografia | 2 | 15 | 38 | 45 | 46 | 47 | 47 | 47 | **48** | 48 | 4 |
| scienze | 3 | 22 | 35 | 40 | 40 | 42 | 43 | 46 | **48** | 48 | 7 |
| musica | 3 | 14 | 33 | 40 | 41 | 43 | 46 | 46 | **47** | 47 | 4 |
| elettronica | 3 | 19 | 21 | 22 | 24 | 26 | 26 | 44 | **47** | 47 | 6 |
| **latino** | 3 | 11 | 23 | 29 | 30 | 30 | 31 | 31 | **31** | 31 | **3** |

Tre buchi, e ciascuno ha un effetto già osservabile:

1. **Italiano è la materia di prima fascia più povera di gesti** — 54 ricette
   contro le 128 dell'inglese — e serve sei esercizi per sessione. Dalla fascia 5
   in poi sblocca una ricetta per fascia, poi zero. **È la causa misurata di
   R-18** (italiano al 26,0% di «sceglie» contro un tetto di 22,3%): meno
   ricette, più banco, più crocette. L'ordine è pulito e va nella stessa
   direzione — inglese 128 → 21,2%, matematica 84 → 21,8%, italiano 54 → 26,0%.
2. **Elettronica sta ferma quindici mondi.** Dalla fascia 2 alla 6 sblocca
   +2, +1, +2, +2, +0, e poi +18 di colpo alla fascia 7. Dal mondo 4 al mondo 18
   il bambino gira sulle stesse ventisei ricette.
3. **Latino ha 31 ricette e tre meccaniche in rotazione al mondo 1** — l'unica
   materia sotto quattro — e dalla fascia 5 non ne sblocca più nessuna.

### 1.4 La fascia, per due terzi degli item, l'ha scelta un'euristica

`expandLegacyDifficultyBands()` in `scripts/build-exercise-banks.mjs` taglia in
due ogni vecchia banda ordinando gli item per un punteggio di *domanda
cognitiva*: lunghezza del prompt, formato libero, parole come «perché» o «se»,
righe della consegna. La metà più lunga passa alla fascia pari.

**3159 item su 4854, il 65,1%.** Al 100% per geografia, scienze, storia, logica e
latino; al 32,6% per inglese, che è la meglio autorata. Solo tabelline, lessico,
coding, elettronica e il catalogo teorico marcano `_difficulty8`.

La lunghezza del testo non è la difficoltà di un argomento. È lo stesso errore
già pagato sulle risposte («le domande *perché* regalano la lunghezza»), qui
applicato alla scala di difficoltà di tutto il gioco.

### 1.5 L'avvio del mondo 1 non è un problema di contenuto

Va detto qui perché è la ragione per cui questo piano **non** ha una fase di
alleggerimento. `performance_budget_audit` è rosso a 546–691 ms su 500, ma:

    giro 0 · mondo 1 · 759 ms      giro 2 · mondo 1 · 298 ms
    giro 1 · mondo 1 · 294 ms      giro 3 · mondo 1 · 308 ms

A caldo il mondo 1 costa **294 ms**, ed è più leggero del mondo 13. È primo, non
pesante. E i banchi non c'entrano: leggerli tutti e dodici costa 179,7 ms grezzi
e **91,8 ms** attraverso `ContentManager`, e la loro crescita da 4061 a 4854 item
ne spiega una quindicina.

**Conseguenza per questo piano:** scrivere item nuovi è quasi gratis sull'avvio.
Il pavimento più severo qui proposto aggiunge 212 item, cioè il **+4,4%** del
banco: quattro millisecondi. Nessuna fase di questo piano va rinviata per il
budget d'avvio, e R-17 si ripara altrove (vedi la sua voce in `insieme.md`).

---

## 2 · Il pavimento proposto, e quanto costa

Serve una soglia dichiarata, perché oggi non ce n'è nessuna: `topic_density_audit`
conta gli item **per argomento sul totale del banco**, e `difficulty_bands_audit`
chiede solo che una fascia regga *una* sessione — che per una materia di terza
fascia è un esercizio, quindi passa con un item in tutta la fascia.

**Proposta: il pozzo di ogni fascia (fascia ±1) deve reggere almeno N sessioni
distinte senza ripetere un item.** È la formulazione giusta perché tiene conto
insieme di tre cose che oggi si guardano separate — quanti item ci sono, quanto
è larga la finestra ±1, e quanti esercizi consuma la sessione di quella fascia
di priorità.

Costo misurato di tre valori di N:

| N | item da scrivere | crescita del banco | dove |
|---:|---:|---:|---|
| **10** | **67** | +1,4% | coding 35 · geografia 31 · fisica 1 |
| **15** | **212** | +4,4% | coding 81 · geografia 81 · fisica 50 |
| 20 | 424 | +8,7% | coding 138 · geografia 136 · fisica 117 · matematica 17 · italiano 13 · logica 3 |

**Raccomandazione: N = 15.** Dieci sessioni è poco per una materia che un bambino
incontra in tre mondi consecutivi; venti costa il doppio degli item e comincia a
toccare materie che non hanno un problema reale. A quindici, il lavoro resta
concentrato su **tre materie e due fasce**, e il conto è di 212 item — meno di
quanto è stato scritto per la sola matematica il 6 settembre (319).

Dove vanno scritti, esattamente:

| materia | F2 | F8 | totale |
|---|---:|---:|---:|
| coding | 60 | 21 | **81** |
| geografia | 48 | 33 | **81** |
| fisica | 26 | 24 | **50** |

*(Un item scritto in fascia 2 alimenta i pozzi delle fasce 1, 2 e 3: è per questo
che il buco della fascia 1 si ripara scrivendo nella 2.)*

E per le ricette, un pavimento parallelo: **ogni fascia deve portare almeno tre
ricette nuove.** Oggi mancano **84 ricette**, così distribuite:

| materia | mancanti | dove si concentrano |
|---|---:|---|
| latino | 13 | F4→F8, che oggi portano 1 · 0 · 1 · 0 · 0 |
| geografia | 12 | F4→F8: 1 · 1 · 0 · 0 · 1 |
| italiano | 9 | F5→F8: 1 · 1 · 1 · 0 |
| elettronica | 8 | F2→F6: 2 · 1 · 2 · 2 · 0 |
| musica | 8 | F4→F8 |
| fisica · logica · scienze | 7 ciascuna | F4 e F6 a zero |
| storia | 6 | F6 e F8 a zero |
| coding | 5 | F4→F8 |
| inglese · matematica | 1 ciascuna | praticamente a posto |

---

## 3 · L'ordine di lavoro

Cinque fasi. L'ordine non è per dimensione ma per **quanto ciascuna cambia il
lavoro di quelle dopo**: si misura prima di scrivere, si scrive dove un rosso lo
richiede, e si mette la guardia solo quando il contenuto c'è — «prima il
contenuto, poi il cricchetto», che è già un invariante del progetto.

### Fase 0 · Il giro completo della suite — **fatta il 9 settembre 2026**

**Esito: 9 rossi su 265 audit, in 2004 secondi.** Il «251 verdi su 251» del 6
settembre non descriveva più niente.

| audit | di chi è | che cosa dice | esito |
|---|---|---|---|
| `variety_audit` | **del contenuto** | coding L1 al 27% di prove ripetute, latino 33%, storia 30%, scienze 27%, geografia 23% (tetto 17%) | **chiuso** dalla Fase 2 |
| `nora_explanation_depth` · `nora_spiegazione_utile` | del contenuto | cinque argomenti di italiano introdotti dal catalogo dell'8 settembre senza nessuna voce di NORA | **chiusi**: cinque voci scritte |
| `explanation_coverage_audit` | del contenuto **e del metodo** | in «griglia» una frase copriva il 26% dei nodi | **chiuso**, ma non come sembrava — vedi sotto |
| `ricette_per_fascia_audit` | mio, nuovo | pavimento tarato con il metodo sbagliato | **chiuso**: pavimenti rimisurati |
| `audio_controls_audit` | **nessuno** | timeout | **falso rosso**: verde in isolamento, era contesa |
| `gesto_audit` | del contenuto | italiano/mondo 26,0% (tetto 22,3%) | **aperto** — R-18, la leva sono i pesi |
| `performance_budget_audit` | del **metro** | misura il primo mondo del processo, non il mondo | **aperto** — R-17, decisione tua |
| `glifi_audit` | **di Codex, in corso** | 16 stringhe con caratteri che il font non ha, in `pet_field_methods.gd` e `outdoor_world.gd`, scritti oggi | **aperto**, non mio |

**Sei rossi su nove chiusi in giornata; tre restano, e uno solo è contenuto.**

**La griglia della logica meritava più attenzione di come sembrava.** Il rimedio
ovvio — aggiungere una sesta spiegazione per abbassare la quota di ciascuna —
ha peggiorato la situazione invece di sistemarla: la frase sopra il tetto è
cambiata ma la quota è rimasta al 26%. La causa stava nella funzione che sceglie
quale frase mostrare: mescolava con moltiplicatore **3**, che con cinque frasi
funziona (3 e 5 sono coprimi) e con sei diventa un divisore — `scenario * 3`
modulo 6 vale soltanto 0 o 3. **Il difetto non era nel contenuto ma nel
distributore**, e nessuna quantità di frasi in più lo avrebbe risolto. Con
moltiplicatori 7, 5 e 3 l'audit passa da 240 secondi appesi a **2 secondi
verde**.

**Il rosso più importante è `variety_audit`, e nessuno lo aveva collegato.** Dice
esattamente ciò che il §1.2 di questo piano ha misurato per un'altra via: coding,
latino, storia, geografia e scienze ripetono le prove alla **fascia 1**. Il
pavimento della Fase 2 non è quindi una proposta teorica — **è già un rosso
aperto**, e questo cambia la priorità della Fase 2, che sale davanti alla Fase 3.

**Nota di metodo, pagata.** Il primo giro è stato lanciato mentre modificavo
`minigame_manager.gd`: alcuni audit hanno letto il file vecchio e altri il nuovo,
e il risultato era inutilizzabile. Il giro valido è il secondo, con la macchina
ferma. **La suite non si esegue mentre si scrive** — vale per sé stessi quanto
per l'altro agente.

### Fase 1 · Le ricette di italiano — **fatta il 9 settembre 2026**

**Una correzione al piano, trovata scrivendolo.** Le nove ricette *non* andavano
in `italian_minigame_catalog.gd`: quel catalogo serve **un solo nodo calibrato
per sessione**, e non è ciò che `gesto_audit` conta. Le ricette che compongono il
mondo stanno nelle tabelle di `MinigameManager`, ed è lì che il buco stava.

**E il buco era più preciso di come il piano lo descriveva.** Incrociando gli
argomenti del banco con quelli delle ricette, tre argomenti di italiano hanno
**quindici item ciascuno, distribuiti su tutte e otto le fasce, e zero
minigiochi**:

| argomento | item | fasce coperte dal banco | ricette prima |
|---|---:|---|---:|
| `concordanza-tempi-verbali` | 15 | 1–8 | **0** |
| `imperativo-infinito-participio-gerundio` | 15 | 1–8 | **0** |
| `congiuntivo-condizionale` | 15 | 1–6, 8 | **0** |

Sono il cuore della morfologia verbale delle medie, e si potevano **soltanto
crocettare**. È lo stesso difetto trovato per l'inglese l'8 settembre — 27
argomenti del banco senza nessun minigioco — ripetuto su italiano e mai cercato.

Le nove ricette sono quindi scritte su questi tre argomenti, non su temi nuovi, e
cadono esattamente nel buco misurato: **fascia 5 +1, fascia 6 +3, fascia 7 +2,
fascia 8 +3**. Tutti i `minLevel` stanno all'**inizio** della fascia (13, 16, 19,
22): è la lezione dell'inglese, dove un gate a metà fascia era invisibile.

| formato | fascia | argomento | il gesto |
|---|---:|---|---|
| compose | 5 | concordanza-tempi-verbali | scegliere il futuro nel passato dopo «promise che» |
| classification | 6 | modi indefiniti | smistare per desinenza: -are / -ando / -ato |
| code_debug | 6 | concordanza-tempi-verbali | trovare la subordinata fuori tempo |
| code_debug | 6 | congiuntivo-condizionale | trovare l'indicativo dove serve il congiuntivo |
| compose | 7 | congiuntivo-condizionale | completare il periodo ipotetico della possibilità |
| compose | 7 | modi indefiniti | l'infinito dopo la preposizione, non il gerundio |
| classification | 8 | congiuntivo-condizionale | i tre gradi: certo / possibile / ormai impossibile |
| code_debug | 8 | modi indefiniti | il gerundio con il soggetto sbagliato |
| ordering | 8 | concordanza-tempi-verbali | ordinare frasi scollegate usando **solo** il tempo del verbo |

Due scelte di scrittura, contro le due scorciatoie che `scorciatoie_minigiochi_audit`
misura: nessuna tessera degli smistamenti contiene il nome del proprio
contenitore (le voci verbali si smistano dalla desinenza, i periodi ipotetici dai
modi), e le frasi dell'ordinamento sono **scollegate apposta**, così l'ordine non
si indovina dal senso e il tempo verbale resta l'unico indizio.

**Guardia: `ricette_per_fascia_audit.gd`**, nuova. Conta le ricette **non
cumulative** — quante ne nasce ciascuna fascia — perché il conteggio cumulativo
nasconde proprio questo difetto: un numero alto può voler dire «ne ha tante»
oppure «le ha tutte dal mondo 1». Il pavimento è per materia e a cricchetto:
italiano a 3 perché è pagata, le altre al valore misurato oggi, bersaglio 3 per
tutte quando la Fase 3 sarà chiusa. Verifica anche che non più di una materia
stia sotto quattro meccaniche in rotazione alla fascia 1.

**Verifica: fallita, e la causa scritta nel piano era sbagliata.** Dopo le nove
ricette `gesto_audit` dà italiano/mondo al **26,0%** — identico a prima. Aggiunte
altre due ricette *manipolative* mirate al mondo giusto: **26,3%**, cioè dentro
il rumore di 1,0 punto. **Il numero di ricette non è la leva di R-18**, ed è una
misura, non un'impressione.

Due cose spiegano perché, e nessuna delle due era nel piano:

1. **Italiano è materia del mondo soltanto ai mondi 2 e 14**, ed è lì che
   `gesto_audit` lo misura (il campione parte da `learningFocus.subject`). Sette
   delle nove ricette hanno `minLevel` 16, 19 o 22: **non entrano mai in quella
   misura**. È la stessa lezione dell'inglese, che ha casa ai mondi 4 e 16 — il
   piano la citava, e l'ho ripetuta lo stesso.
2. **Sei delle nove ricette sono in formati che `gesto_audit` conta come
   «sceglie».** `compose`, `code_debug`, `cycle` e `clue` stanno nell'elenco
   `SCEGLIE`, non in `MANIPOLA`: hanno un disegno sopra, ma con le mani si tocca
   comunque una alternativa fra quelle offerte. Scrivere ricette senza guardare
   quell'elenco può peggiorare il numero invece di migliorarlo.

**Dove sta davvero la leva, misurato.** Scomponendo il mondo per origine dei
nodi:

| origine | quota dei nodi | «sceglie» al mondo 2 | «sceglie» al mondo 14 |
|---|---:|---:|---:|
| **pratica** (minigiochi) | **70,5%** | 20,0% | **33,5%** |
| missione | 15,4% | 29,4% | 26,3% |
| enigma | 10,3% | 30,1% | 27,3% |
| minimissione | 3,8% | 31,3% | 34,4% |

La pratica è sette nodi su dieci, e al mondo 14 è tredici punti peggiore che al
mondo 2. Ma la pratica **sceglie il formato per peso, non per numero di
ricette**: aggiungere specifiche a un formato aumenta la varietà dentro quel
formato, non la frequenza con cui quel formato viene estratto. È esattamente la
causa numero 1 che G-C2 aveva già scritto — `NONMC_FORMAT_WEIGHTS` favorisce
grafico, circuito e caccia all'errore (peso 25) su abbinamento, ordinamento e
smistamento (20, 15, 13) — e che io ho letto senza usarla.

**R-18 resta aperta, e il prossimo tentativo va fatto sui pesi**, misurando prima
il mondo 14 da solo. Non serve altro contenuto: ne è stato aggiunto e non ha
mosso niente.

### Fase 2 · Le fasce basse — **fatta il 9 settembre 2026**

**Il bersaglio è cambiato appena la Fase 0 ha parlato.** Il piano diceva «coding,
geografia, fisica», dedotto dal pavimento delle dieci sessioni. Il giro completo
ha invece dato un elenco misurato — `variety_audit`, otto problemi su cinque
materie — e quell'elenco comprende **latino, storia e scienze**, che il mio
modello dava per sani perché consumano un esercizio per sessione. Ho seguito il
rosso, non il modello: è il rosso ad avere giocato.

**147 item nuovi**, in cinque file separati per materia sul modello di
`matematica-programma.mjs`, tutti marcati `difficulty8` — sono i primi scritti
sapendo che le fasce sono otto, e non passano dal ponte di G-C12.

| materia | item | prima | dopo | sessioni peggiori |
|---|---:|---:|---:|---:|
| **coding** | **+81** | 195 | **276** | da **3** a **15** |
| **geografia** | **+89** | 199 | **288** | da **5** a **15** |
| **fisica** | **+51** | 229 | **280** | da **9** a **15** |
| storia | +31 | 167 | **198** | da 22 a **41** |
| latino | +24 | 289 | **313** | da 21 a **46** |
| scienze | +24 | 154 | **178** | 31 |

Il banco passa da 4854 a **5154 item**, e **nessuna materia sta piu' sotto il
pavimento delle quindici sessioni**: il minimo del gioco e' 15, era 3. **`variety_audit` è verde**, e con lui
`free_answer`, `bank_scorciatoie`, `risposta_unica`, `topic_density`,
`bank_explanation` e `difficulty_bands`.

**Che cosa si è imparato scrivendo, e non era nel piano.**

1. **Il pozzo grande non basta: conta la casella più piccola.** Storia L13 era
   rosso con settantanove item nella fascia — un pozzo abbondante. Ma `civilta` e
   `metodo` avevano **un solo item** in quella fascia, ed è il selettore a
   scegliere prima l'argomento e poi l'item: pescato un argomento che ne ha uno,
   la ripetizione è certa. **La misura giusta non è item per fascia, è item per
   (argomento, fascia).** Nessuna guardia la fa oggi.
2. **Aggiungere item a crocetta rompe la Decisione 10.** Ogni lotto di scelta
   multipla abbassa la quota di risposta libera del banco, e sotto il 20%
   `free_answer_audit` diventa rosso. È successo tre volte, su storia e
   geografia. Regola: **ogni lotto porta con sé il proprio 20% di risposta
   libera**, scelto fra le domande che hanno una risposta breve e senza sinonimi.
3. **Le domande «perché» regalano la lunghezza, e in storia sono quasi tutte
   così.** Su ventuno item di storia, dodici avevano la risposta più lunga di
   ogni distrattore: `bank_scorciatoie_audit` è arrossito su latino e storia
   insieme. Riparato allungando i distrattori — mai accorciando la risposta,
   che è la regola già scritta.
4. **Il bake rifiuta due domande identiche con risposte diverse**, e ha trovato
   sette collisioni fra i miei prompt e quelli già in banco. È un controllo utile
   e va lasciato severo: obbliga a leggere che cosa la materia chiede già.

**Fisica, scritta per ultima e per una ragione diversa dalle altre.** Non era
mai stata rossa in `variety_audit` — l'unica delle sei materie povere a non
esserlo. Ma il suo pozzo peggiore era **9 sessioni**, il secondo più basso del
gioco, e soprattutto **quattro argomenti su dodici non esistevano affatto nelle
prime due fasce**: `onde-luce`, `energia`, `calore` e `metodo` erano a zero. Un
bambino che al mondo 1 incontrava fisica poteva vedere misure, forze, leve e
correnti, e mai la luce, il calore o l'energia — le tre cose di cui ha esperienza
diretta ogni giorno.

**Non essere rossi non vuol dire stare bene**: vuol dire stare sotto la soglia di
un cricchetto tarato sul peggiore. I 51 item nuovi portano fisica a **15
sessioni**, esattamente il pavimento proposto nella sezione 2, e **tutti e dodici
gli argomenti esistono ora alle fasce basse**. Le fasce 7 e 8 hanno preso i
conti — velocità, densità, pressione, equilibrio di una leva — perché lì il
fenomeno è già stato visto e la formula serve a prevederlo, non a sostituirlo.

**Guardia:** vedi Fase 5. `variety_audit` esisteva già ed è la guardia vera di
questa fase — nessuno l'aveva collegata al problema delle fasce.

### Fase 3 · Le ricette — **fatta il 9 settembre 2026**

**Bersaglio raggiunto: tutte e dodici le materie portano almeno tre ricette nuove
in ognuna delle otto fasce.** Prima ce n'erano trentaquattro sotto quella soglia,
e sei materie avevano fasce a zero.

**La prima metà del lavoro non è stata scritta: è stata spostata.** Elettronica
aveva **diciassette ricette tutte a `minLevel` 20** — il suo secondo mondo — e
niente fra la fascia 2 e la 6: quindici mondi sulle stesse ricette. Non mancava
contenuto, era gated tutto nello stesso punto. Dieci gate spostati sulle fasce
2, 4, 5, 6 e 8 e la materia passa da `0 · 3 · 1 · 1 · 0 · 19 · 2` a **tre o più
in ogni fascia, senza una riga nuova**. Stessa cosa per latino, che era l'unica
materia con tre sole meccaniche in rotazione al mondo 1: due cacce all'errore
stavano a `minLevel` 3 e al mondo 2 non erano idonee. Portate a 1.

**La seconda metà è contenuto: 47 ricette nuove.**

| materia | ricette | dove |
|---|---:|---|
| latino | 12 | 5 smistamenti, 4 ordinamenti, 3 abbinamenti — fasce 3-8 |
| geografia | 12 | 3 smistamenti, 4 abbinamenti, 3 ordinamenti, 2 cacce all'errore |
| musica | 10 | fasce 3-8, compresa la forma musicale alla 7 |
| logica | 9 | validità del ragionamento, negazioni, quantificatori |
| scienze · coding | 6 · 6 | trasformazioni e apparati; cicli, funzioni, mutabilità |
| fisica · storia | 5 · 5 | equilibrio e luce; invenzioni e metodo storico |
| matematica · inglese | 3 · 1 | insiemi numerici e formule; passato irregolare |

**Due cose imparate.**

1. **Guardare i gate prima di scrivere.** Metà del deficit di questa fase era
   contenuto già esistente e messo tutto allo stesso `minLevel`. La domanda da
   fare per prima non è «che cosa manca» ma «dove sta ciò che c'è».
2. **Un argomento nuovo va collegato a NORA nello stesso lotto.** Lo smistamento
   di matematica introduceva `insiemi-numerici`, argomento senza voce:
   `nora_explanation_depth_audit` l'ha trovato lo stesso giorno. È il difetto
   ricorrente del contenuto scritto e mai collegato, colto stavolta in un'ora
   invece che in una stagione.

**Guardia: `ricette_per_fascia_audit`**, con i pavimenti ora **a 3 per tutte e
dodici**. Il dizionario per materia resta solo perché una materia futura potrebbe
entrare povera; nessuna riga scende.

### Fase 4 · Il ponte 4→8 — **fatta il 9 settembre 2026**

**Il ponte e' passato dal 65,1% al 41,9% degli item, e sei materie ne sono
uscite del tutto.**

| materia | dal ponte prima | dopo |
|---|---:|---:|
| logica | **100%** | **0%** |
| latino · scienze · storia | 100% | **0%** |
| elettronica | 92,5% | **0%** |
| musica | 89,9% | **0%** |
| coding · fisica · geografia | 89,7 · 88,6 · 100% | 63,4 · 72,5 · 73,6% |
| matematica · italiano · inglese | 67,4 · 58,2 · 32,6% | invariati |

**Come, e perche' non e' un'altra euristica.** Riscrivere tremila item non era
la strada. Al loro posto c'e' una **scala dichiarata per argomento**: una
tabella che dice, materia per materia e argomento per argomento, in quali
quattro fasce cadono i suoi gradi. Non guarda il testo — guarda **l'ordine in
cui la materia si insegna**, ed e' scritta, motivata e rileggibile in una
pagina. Sei tabelle: `SCALA_LOGICA`, `SCALA_LATINO`, `SCALA_ELETTRONICA`,
`SCALA_MUSICA`, `SCALA_SCIENZE`, `SCALA_STORIA`.

Un esempio, perche' si veda la differenza: in logica `deduzioni` va `2 3 5 7`
perche' il sillogismo diretto e' facile e il modus tollens — «non ha l'ombrello,
quindi non piove» — e' il passo che a undici anni costa di piu'; `verita` va
`3 5 7 8` perche' giudicare se un'affermazione sia vera, falsa o indecidibile
chiede di ragionare sul ragionamento. Questi sono giudizi didattici: si possono
discutere, correggere, sbagliare. La lunghezza del prompt no.

**Tre cose imparate, tutte pagate.**

1. **Applicare la scala dove i banchi si costruiscono non basta.**
   `CURATED_TAIL` e le rifiniture della macro-banda 4 aggiungono item *dopo*,
   e quelli finivano dritti nel ponte: otto in latino, diciotto in logica,
   trentacinque in musica. Le scale si applicano ora **in fondo al bake**, dove
   nessuna aggiunta puo' piu' sfuggire.
2. **Una scala va giudicata anche su quanti ARGOMENTI tocca ogni fascia.** La
   prima stesura di storia metteva nella fascia 1 due soli argomenti, e
   `variety_audit` e' tornato rosso: il pozzo era abbondante (49 item) ma il
   selettore sceglie prima l'argomento. Stessa lezione della Fase 2, ripetuta
   da me poche ore dopo averla scritta.
3. **La cella grande e' il limite del metodo.** Ogni cella (argomento, grado)
   finisce tutta nella stessa fascia, e `declinazione-3m` ne ha dodici in un
   grado solo: `format_mix_audit` ha trovato una sessione al mondo 19 che
   chiedeva due volte quell'argomento nello stesso formato. Riparato spostando
   la cella; se un giorno ne nascesse una piu' grande, la soluzione non e'
   spostarla ma **sdoppiarla nella sorgente**.

**Guardia: `fascia_autorata_audit.gd`**, nuova. Il bake **non cancella piu'** il
flag `_difficulty8`: resta nel JSON, perche' e' l'unica cosa che distingue una
fascia decisa da una persona da una dedotta dalla lunghezza del testo, e
cancellarlo rendeva la distinzione invisibile a valle. L'audit conta la quota
per materia con un pavimento a cricchetto — sei materie a 100, le altre al
valore misurato — piu' un pavimento complessivo al 57%. **Il ponte non puo' piu'
ricrescere in silenzio.**

**Resta da riautorare** matematica (67,4% dal ponte), fisica (72,5%), geografia
(73,6%), coding (63,4%) e italiano (58,2%). Il metodo e' quello: si scrive la
scala, si applica in fondo, si guarda `variety_audit` e `format_mix_audit`, si
alza il pavimento.

### Fase 5 · Le guardie — **fatta il 9 settembre 2026**

Tre guardie nuove e i tetti di `gesto_audit` riportati sul misurato.

| guardia | che cosa pretende | stato |
|---|---|---|
| `pozzo_per_fascia_audit` | ogni fascia regge ≥ 15 sessioni distinte, **e** il suo pozzo tocca abbastanza argomenti | nuova, verde |
| `fascia_autorata_audit` | la quota di item con la fascia decisa da una persona sale e mai scende | nuova, verde |
| `ricette_per_fascia_audit` | ogni fascia porta ≥ 3 ricette nuove, per tutte e dodici | nuova, verde |
| tetti di `gesto_audit` | mondo ed esame riportati a misurato + 1,0 punto | 20 tetti su 24 scendono |

**La misura che mancava e che ha corretto due volte chi scriveva** e' la seconda
di `pozzo_per_fascia`: **quanti argomenti tocca il pozzo di una fascia**. Il
selettore sceglie prima l'argomento e poi l'item, quindi un pozzo abbondante con
due soli argomenti ripete lo stesso. Contare gli item non lo vede.

**I tetti avevano fino a quarantun punti d'aria.** Elettronica stava a 63,0 su un
valore reale di 22,8; inglese a 26,6 su 20,3. Un tetto che nessuno sfiora non
trattiene niente. Ora tetto = misurato + 1,0, contro un rumore dello strumento di
0,6 punti, e `TOLLERANZA_ESAME` scende da 3,0 a 1,0 — era cinque volte piu' larga
del necessario e rendeva il tetto vero tre punti piu' in alto di quello scritto.

---

## R-18 chiusa: la causa non era nessuna delle due ipotesi

Italiano era al **26,6%** di «sceglie» nel mondo contro un tetto di 22,3, e ci
sono voluti tre tentativi.

1. **Piu' ricette di minigioco** (Fase 1): undici scritte, il numero non si e'
   mosso. Meta' erano in formati che `gesto_audit` conta come «sceglie», e sette
   su nove stavano fuori dai due mondi in cui italiano viene misurato.
2. **I pesi dei formati** (Fase 5): `NONMC_FORMAT_WEIGHTS` dava 25 a grafico,
   circuito e caccia all'errore — tutti «sceglie» — e 13 allo smistamento.
   Riequilibrati a 14 e 20. Ha migliorato **tutte le altre materie** (inglese da
   21,2 a 20,3, logica da 18,4 a 17,1, elettronica da 23,7 a 22,5) e italiano
   quasi niente: 26,6 → 26,2.
3. **La causa vera**, trovata scomponendo italiano per formato: **`compose` era
   il 14,6% dei nodi al mondo 2 e il 17,0% al mondo 14 — piu' della scelta
   multipla stessa.** Il catalogo dell'italiano aveva due sfide per fascia, e
   nelle fasce 1 e 5 erano **tutte e quattro `compose`**. Quelle due fasce sono
   esattamente i mondi 2 e 14, gli unici in cui italiano e' materia del mondo, e
   `build_minigame` mette una campata calibrata in **ogni** sessione: ogni
   sessione di italiano conteneva una `compose` garantita.

Quattro opzioni manipolative aggiunte a quelle due fasce, e italiano passa da
**26,6% a 20,5%**. `gesto_audit` e' **verde per la prima volta**.

**La lezione, che vale oltre questo caso:** un numero aggregato non dice mai da
dove viene. Scomporlo per origine (missione, enigma, pratica, esame) ha mostrato
che la pratica e' il 70,5% dei nodi; scomporlo per **formato** ha mostrato il
colpevole in una riga. Le prime due riparazioni erano ragionevoli e sbagliate:
la terza e' costata quattro sfide.


## 4 · Il conto complessivo

| fase | scrittura | chiude |
|---|---|---|
| 0 · giro completo | — | **fatta**: 9 rossi su 265 in 2004 s |
| 1 · ricette italiano | 11 ricette | tre argomenti verbali senza gesto — **non** R-18 |
| 2 · item fasce basse | **fatta**: 300 item su 6 materie | **`variety_audit` verde**; pavimento di 15 sessioni raggiunto da tutte e dodici |
| 3 · ricette per materia | **fatta**: 47 ricette + 12 gate spostati | tutte e dodici a ≥ 3 per fascia |
| 4 · ponte 4→8 | **fatta**: 6 scale dichiarate | dal 65,1% al **41,9%**; guardia a cricchetto |
| 5 · guardie | **fatta**: 3 audit nuovi + 20 tetti abbassati | **`gesto_audit` verde**: R-18 chiusa |

**212 item e 84 ricette.** Per confronto: il solo lotto di matematica del 6
settembre ne ha scritti 319. Questo piano è più piccolo di quello, ed è distribuito
su tre materie invece che una.

**Nessuna fase allunga la campagna.** Nessuna aggiunge tappe: sostituisce
materiale ripetuto con materiale nuovo dentro sessioni che già esistono. Le 21,3
ore restano, e `time_cost_probe` va comunque rieseguito alla fine della Fase 2.

---

## 5 · Le decisioni che restano tue

Questo piano ne assume tre. Se una risposta è diversa, la fase corrispondente
cambia.

1. **N = 15 sessioni è il pavimento giusto?** Dieci costa 67 item, venti ne costa
   424. La domanda vera non è di misura ma di esperienza: quante volte un bambino
   entra nella stessa materia dentro tre mondi consecutivi. È il tipo di numero
   che si vede giocando.
2. **La forma discendente di italiano e inglese va corretta o accettata?** Questo
   piano la *accetta* — nessuna delle 212 righe è per loro, perché nessuna delle
   due sfonda il pavimento. Ma resta il fatto che al mondo 22 l'italiano ha un
   terzo del materiale del mondo 2, e questo è un giudizio didattico, non una
   soglia.
3. **`performance_budget_audit` deve misurare il mondo o l'avvio?** Oggi dichiara
   il primo e misura il secondo. Il metro va deciso prima di inseguire R-17, e la
   scelta cambia se quel rosso sia un difetto o un'informazione. Vedi la voce R-17
   in `insieme.md`.

E una che è già scritta in `insieme.md` come **G-17** e pesa su tutto questo: sei
materie su dodici hanno **un esercizio per sessione**, ed è aritmetica più che
taratura — con sei materie e la quota 15% ±5, portarle a due obbliga a un giro da
almeno 60 esercizi contro gli attuali 39.
