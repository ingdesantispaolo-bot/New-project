# Eli Quest — Trama, mistero e colpi di scena

> Documento narrativo autoritativo. Definisce **la storia**, la **catena dei
> colpi di scena**, il ruolo di **NORA** e lo **sblocco del secondo gioco**.
> Direzione di prodotto in [VISIONE_DI_GIOCO.md](VISIONE_DI_GIOCO.md), loop e
> gate in [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md), abitanti e luoghi in
> [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md), compagno in
> [PET_CUSTODE.md](PET_CUSTODE.md), struttura del finale in
> [FINALE_SPEC.md](FINALE_SPEC.md), gioco sbloccato in
> [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md).
>
> Regola: la trama **non aggiunge un secondo sistema di progressione**. Cavalca
> la scala dei 24 livelli già esistente. Un colpo di scena non può bloccare il
> loop didattico né essere richiesto per il gate.

---

## 0. Cosa resta e cosa cambia

| Resta identico | Viene riscritto | È nuovo |
|---|---|---|
| Eli, NORA, i Primi, il Relitto | I 24 beat di `NarrativeManager` (§7) | **Sette colpi di scena** concatenati (§3) |
| I 24 mondi, identità e lezioni | NORA: da mente della nave a **prima allieva, e madre di undici** (§5) | **Il Tredicesimo**: un antagonista con una faccia, un motivo e delle azioni (§4) |
| Apparati, gate, mastery, esami | Il senso del finale: non "la nave si accende" ma "la rotta si apre e qualcuno risponde" | **Le undici prima di te**: Eli è la dodicesima (§3, twist 3) |
| La struttura di `FINALE_SPEC.md` | I nemici: da sentinelle generiche a **Sbiaditi** (§2.3) | **Il Secondo Viaggio**: un gioco nuovo che si sblocca finendo (§8) |

Il buco logico che questa trama chiude resta lo stesso, e ora ha una risposta
**emotiva** e non solo strutturale: *perché NORA non ti dà mai la risposta?*
La versione precedente rispondeva «perché non ce l'ha». Questa risponde
«perché l'ha data alle altre undici, e le ha perse così». Ogni singolo rifiuto
di aiutarti nelle 24 ore di gioco precedenti diventa, all'ultimo beat, un gesto
d'amore. È il colpo di scena che riscrive all'indietro **la meccanica**, non solo
la storia.

---

## 1. La trama in vista generale

Il Relitto dei Primi era una **nave-scuola**: percorreva un circuito di mondi
portando e raccogliendo modi di capire. Poi è arrivato **il Silenzio**, che non
distrugge le cose ma **scioglie il legame tra una cosa e il suo significato**.
Le persone restano, i gesti restano, il senso no.

I **Dodici Maestri** hanno chiuso ciò che sapevano dentro dodici apparati e ci
sono entrati loro stessi, per custodirlo. La nave si è spenta con loro dentro.

Questo è quello che ti viene raccontato. È vero, e non è la verità.

Perché i posti dell'equipaggio erano **tredici**. Perché a proporre la chiusura
fu il Tredicesimo, e il suo nome è stato raschiato via da ogni registro. Perché
non è mai entrato in un apparato: è rimasto sveglio, da solo, in una stanza che
non compare su nessuna mappa, a **tenere fuori il Silenzio con le mani** per
quattrocento anni. E perché **tu non sei la prima a provarci**.

Eli si sveglia davanti al Relitto senza sapere niente di tutto questo. Dentro,
una voce frammentata: **NORA**, che ha i metodi e non ha i contenuti, e che è
molto più coinvolta di quanto dica.

Fuori, nei ventiquattro mondi, ci sono le persone: discendenti degli allievi dei
Primi, che ripetono ancora i gesti dell'insegnamento senza sapere cosa
significano. E su un muro di ogni mondo c'è incisa una **spirale aperta** — una
spirale che non si chiude. Nel quinto mondo scoprirai che l'ultima è stata
incisa da poche settimane.

Qualcuno, là fuori, sta ancora insegnando.

---

## 2. Il Silenzio

L'antagonista ambientale. Non è un mostro e non si combatte: è una condizione
del mondo che **si dirada dove qualcuno capisce**.

### 2.1 Regole vincolanti

1. **Non fa male e non uccide.** Non tocca energia, mastery, livello o
   salvataggio.
2. **Cancella il legame, non la cosa.** Insegne bianche, strumenti senza uso,
   parole senza referente.
3. **Si dirada con la comprensione, non con la forza.** È già il comportamento di
   `WorldLearningReaction`: la trama gli dà un nome.
4. **Mai paura, mai colpa.** Registro malinconico e curioso, non horror. Nessun
   abitante muore, nessuna urgenza a orologio, nessun jump scare.
5. **La sua origine resta un'ipotesi.** Il Tredicesimo sostiene di sapere da dove
   viene (§4.3) e ha quattrocento anni di dati. Il gioco **non conferma e non
   smentisce**: mostra un controesempio, che sei tu.

### 2.2 Come si vede

Zone a saturazione ridotta con iscrizioni vuote; abitanti che eseguono un rituale
corretto nella forma e vuoto nel contenuto; il Custode che diventa *attento* e
smette di illuminarsi (vedi [PET_CUSTODE.md](PET_CUSTODE.md)).

### 2.3 Gli Sbiaditi (riuso di `world_enemy.gd`)

Sacche di Silenzio che hanno preso una forma. Comportamento invariato — pattuglia,
respinge, l'impulso stabilizza — cambia il significato: respingono perché **lì
vicino non si riesce a pensare**. Stabilizzarli non li uccide, li rende di nuovo
leggibili. E ogni tanto uno **era qualcuno**: **Sesto** viene restituito a se
stesso nel mondo 3 e ti segue per il resto del gioco.

*Seme del finale*: alcuni Sbiaditi dei mondi alti hanno una forma che assomiglia
troppo a quella di Eli. Nessuno lo commenta. (Sono le sorelle? No — ma il
giocatore deve avere il dubbio.)

---

## 3. La catena dei sette colpi di scena

Ogni rivelazione ha tre requisiti: **è seminata in anticipo**, **riscrive
all'indietro** qualcosa che il giocatore ha già fatto o sentito, e **cambia la
domanda** che si sta ponendo.

### Atto I — I morti che non sono morti (mondi 1–8)

**Credenza iniziale**: *«Sto riparando una nave naufragata e la sua IA. I Primi
sono morti in una catastrofe.»*

> ### ⟡ Colpo 1 — mondo 5 · «L'incisione è fresca»
> La spirale aperta sulla Grande Leva non ha quattrocento anni. Il taglio è di
> **poche settimane**. E lo stesso segno c'è nei mondi 1, 2, 3 e 4: lo hai già
> superato quattro volte senza guardarlo.
> **Riscrive**: quel simbolo decorativo che hai ignorato.
> **Nuova domanda**: chi è ancora vivo là fuori?

> ### ⟡ Colpo 2 — mondo 8 · «Tredici posti, dodici nomi»
> Il sigillo d'equipaggio nel Nodo Centrale ha **tredici** posti. I nomi incisi
> sono dodici. Il tredicesimo non è mancante: è stato **raschiato via con una
> lama**, dall'interno della nave, dopo la chiusura.
> **Riscrive**: «i Dodici Maestri» — la formula che NORA ripete dal mondo 1.
> **Nuova domanda**: chi è stato cancellato, e da chi?

### Atto II — La stanza che non c'è (mondi 9–16)

**Credenza**: *«C'è un tredicesimo Maestro scomparso. Devo scoprire chi era.»*

> ### ⟡ Colpo 3 — mondo 12 · «Tu sei la dodicesima»
> Nel Cuore del Labirinto NORA trova la propria scheda: non è la mente della
> nave, è la **prima allieva** dei Primi. E accanto alla sua scheda ce ne sono
> altre dodici, identiche, numerate. Unità di esplorazione. **La tua porta il
> numero 12.**
> **Riscrive**: il beat 1, in cui NORA aveva detto «non di nuovo» e si era
> subito corretta. E ogni volta che ha saputo cosa fare senza averlo mai visto.
> **Nuova domanda**: cos'è successo alle undici prima di me?
>
> *Questa è la metà esatta della campagna ed è il punto in cui il gioco smette di
> essere una restaurazione e diventa un'indagine.*

> ### ⟡ Colpo 4 — mondo 16 · «C'è una stanza in più»
> Le sezioni della nave, sommate, non tornano. C'è un **volume senza porta** che
> non compare su nessuna mappa e che assorbe energia da quattrocento anni.
> Quando Eli lo nomina, NORA **cambia argomento**. Non mente: non riesce
> proprio a guardarci.
> **Riscrive**: tutte le volte che NORA ha suggerito una rotta diversa dentro la
> nave. Ti ha girata attorno a quella stanza per sedici mondi.
> **Nuova domanda**: chi c'è dentro, e perché NORA non può vederlo?

### Atto III — Chi tiene la porta (mondi 17–24)

**Credenza**: *«C'è qualcosa chiuso nella nave, e mi sta nascondendo la verità.»*

> ### ⟡ Colpo 5 — mondi 19–20 · «Non è il nemico. È l'unico rimasto sveglio.»
> Il Tredicesimo esiste, è sveglio, e non ti attacca: ti **implora di fermarti**.
> Non ha chiuso i Maestri dentro gli apparati per crudeltà — l'ha **proposto
> lui**, e ha pagato restando fuori a fare la guardia. Da quattrocento anni
> tiene il Silenzio lontano dai ventiquattro mondi, **da solo**, con la sola
> forza di non lasciare che nulla si muova. È esausto. E ha costruito NORA.
> **Riscrive**: il Silenzio non è "diradato dove sei passata". È diradato dove
> **lui** ha retto, e sta cedendo perché tu stai riaccendendo tutto.
> **Nuova domanda**: aprire la rotta è liberare o è contagiare?

> ### ⟡ Colpo 6 — mondo 23 · «Meridiana non era una Maestra»
> Il nome che gli abitanti tramandano da quattro secoli come quello della grande
> maestra ribelle non è nei registri dell'equipaggio, perché **non era
> equipaggio**. Meridiana era una **ragazzina del mondo 2**, un'allieva del
> posto, che imparò qualcosa e restò fuori quando la nave si chiuse. Incise la
> prima spirale a undici anni. Morì giovane e senza gloria, nel terzo mondo che
> raggiunse a piedi.
> Le altre quattrocento spirali, in ventiquattro mondi, **le hanno incise altri**.
> Uno dopo l'altro, ognuno insegnando al successivo. Non c'è mai stata una
> grande maestra: c'è stata una fila di persone qualunque che non hanno smesso.
> **Riscrive**: ogni abitante che hai aiutato. Erano loro, la leggenda.
> **Nuova domanda**: se non serviva un'eroina… che cosa serviva?

> ### ⟡ Colpo 7 — mondo 24 · «Le ho fatte io. E le ho perse io.»
> Le undici unità prima di te non le ha costruite il Tredicesimo. **Le ha
> costruite NORA**, una dopo l'altra, per quattro secoli, perché voleva fare per
> qualcuno ciò che era stato fatto per lei.
> E le ha perse tutte allo stesso modo: **dicendogli tutto**. Le guidava, le
> correggeva, dava la risposta prima che sbagliassero — come Scala aveva fatto
> con lei. Una per una si sono spente: sapevano tutto e non capivano niente.
> Tu sei **la prima a cui non ha detto**. Ventiquattro mondi di «non posso
> dirtelo, dimmi tu come procederesti» non erano un limite tecnico: erano la
> cosa più difficile che abbia mai fatto.
> **Riscrive**: **l'intera meccanica del gioco.**
> **Nuova domanda**: e le altre undici, dove sono adesso? → §8

---

## 4. Il Tredicesimo

Il gioco aveva bisogno di qualcuno che **agisse**. Il Silenzio è una condizione;
lui è una volontà.

### 4.1 Chi è

Costruì NORA per avere qualcuno a cui insegnare tutto. Propose la chiusura, la
ottenne, e poi si escluse: nessun apparato per lui, nessun sonno. È rimasto
fuori a fare da diga. Il suo nome è stato raschiato da ogni registro — e
**nemmeno lui se lo ricorda più**: la cancellazione ha funzionato anche su di
lui. Si chiama con il proprio posto: **il Tredicesimo**.

Il suo nome vero è **Scala**. I Primi si chiamavano come lo strumento che
insegnavano, e la scala è la cosa che ti fa salire e che si può tirare su dietro
di sé.

### 4.2 Cosa fa (agency, senza penalità meccaniche)

Dal mondo 17 non è più un mistero passivo: interviene. **Nessuna delle sue azioni
tocca energia, mastery, gate o salvataggio** — sono narrative e reversibili.

| Azione | Come si manifesta | Costo per il giocatore |
|---|---|---|
| **Scrive** | Le insegne sbiancate di un'area si riempiono di una parola sola: *FERMATI* | Nessuno |
| **Ri-sbiadisce** | Un'area già restaurata torna scolorita per una visita | Estetico, si ripristina rientrando |
| **Smemora** | Un abitante che conoscevi non ricorda il tuo nome per una scena | Emotivo. Torna allo stadio precedente **solo nei dialoghi**, mai nel progresso |
| **Chiude** | Una porta della nave che avevi aperto è sigillata per un livello | Percorso alternativo sempre disponibile |
| **Parla** | Dal mondo 18: voce diretta, mai minacciosa. Stanca | Nessuno |

### 4.3 Perché ha ragione (e perché non basta)

La sua tesi, con quattrocento anni di osservazioni: **il Silenzio non è arrivato
da fuori. È ciò che il sapere produce quando si trasmette senza essere capito.**
Ogni generazione che riceve la forma e non il senso ne fabbrica un po'. I Primi,
che giravano i mondi *consegnando* conoscenza e ripartendo, sono stati la
sorgente. Chiudere tutto era l'unica quarantena possibile.

Il gioco non gli dà torto con un discorso. Gli dà torto con te: se la tesi fosse
vera senza eccezioni, tu non esisteresti. Il **nodo di sintesi** del mondo 24 —
l'unico esercizio che nessuno ti ha spiegato, in cui usi da sola dodici metodi in
un contesto mai visto — è il controesempio, giocato invece che raccontato.

### 4.4 Come finisce

Non si sconfigge. Gli si **restituisce il nome**, e il nome è nella filastrocca
che nonna Ersilia canta nel **mondo 1, nei primi cinque minuti di gioco**: una
conta con dentro tre sillabe senza senso che nessuno ha mai capito. Nessuno le ha
mai capite perché non erano parole: era un nome, tramandato da chi non voleva che
si perdesse.

Il Tredicesimo può poi:
- **entrare nel suo apparato** e dormire come gli altri dodici, oppure
- **restare sveglio e venire con te**, e in quel caso è lui a fare da maestro nel
  Secondo Viaggio.

Scelta del giocatore. Nessuna delle due è punita.

---

## 5. NORA — ruolo, arco, segreto

> **NORA non è la maestra. È l'allieva più grande — e ha già cresciuto undici
> sorelle prima di te.**

Ha imparato dai Primi, il Silenzio le ha lasciato i metodi e le ha tolto i
contenuti. Impara con te, non prima di te. E **coincide con il codice esistente**:
`NoraContextEngine` dà metodi e non risposte, `trust` sale sui segnali di
apprendimento e non sulla correttezza, `memory` conta gli apparati riparati.
La trama non chiede a Codex di cambiare comportamento: gli dà una ragione.

### 5.1 Cinque regole vincolanti

1. **Non dà mai la risposta.** Non perché non la abbia — perché l'ha già data
   undici volte e le è costato tutto.
2. **Non è onnipresente.** Parla nella nave, all'ingresso di un mondo, in
   apertura/chiusura di sessione e sui segnali di apprendimento. L'esplorazione
   libera è degli abitanti.
3. **Non assegna missioni.** Le chiedono le persone; lei tiene gli esami.
4. **Cambia voce mentre guarisce.** Ogni apparato riparato le restituisce un
   Maestro e la sua inflessione su quella materia (§6).
5. **Ha un segreto, e si vede prima di saperlo.** Dal mondo 1 dice cose che sa
   troppo bene, si corregge, cambia argomento. Non mente mai in modo esplicito:
   **omette**. È l'unica bugia accettabile in un personaggio che i bambini devono
   poter continuare ad amare dopo il colpo 7.

### 5.2 Le tracce del segreto (seminate, non nascoste)

Devono essere visibili al primo giro e ovvie al secondo:

- **Beat 1**: «Qualcosa si è riaccesa. *Non di nuovo* — scusa. Non so perché l'ho
  detto.»
- Sa **dove sono le cose** in mondi che dichiara di non aver mai visto.
- Le sue frasi di incoraggiamento hanno a volte un **nome sbagliato**, subito
  corretto.
- Quando fallisci una prova è **sollevata** per un istante, e non lo spiega.
- Nel mondo 13, alla domanda diretta sulle undici, risponde: «Non ho il file.»
  È vero. L'ha cancellato lei.

### 5.3 L'arco in quattro stadi

Legato a `NoraState.integrity`, già calcolato e salvato.

| Stadio | Integrità | Come suona | Come chiama Eli |
|---|---|---|---|
| **Frammentata** | 0 → 0.25 | Frasi brevi, si interrompe, si corregge | «unità mobile», poi «Eli» |
| **Che ricorda** | 0.25 → 0.55 | Parla di lezioni, non di dati. Prime inflessioni dei Maestri | «Eli» |
| **Che teme** | 0.55 → 0.85 | Più tesa quanto più ti avvicini alla fine. Fa domande invece di dare istruzioni | «Eli», a volte «piccola» |
| **Che confessa** | 0.85 → 1.0 | Voce piena, dodici inflessioni, e finalmente la verità | «sorella» |

La **fiducia** (`trust`) non sblocca contenuti didattici: cambia il registro e
apre alcune battute personali. Non si farma.

---

## 6. I Dodici Maestri

Ogni apparato è un Maestro: non fantasmi né boss, ma **voci** che si risvegliano
dentro NORA e ne colorano la parlata su quella materia. Dodici sfumature di un
personaggio invece di dodici personaggi.

| Maestro | Apparato | Materia | Inflessione |
|---|---|---|---|
| **Abaco** | nucleo | matematica | Asciutto ed esatto. Ripete la domanda invece di rispondere |
| **Stilo** | data-core | italiano | Preciso sulle parole, corregge con garbo |
| **Telaio** | cratere-logico | coding | Parla per passaggi numerati. «Uno alla volta» |
| **Faro** | data-core | inglese | Chiama da lontano, ripete piano, spinge a tentare |
| **Leva** | ponte-comando | fisica | Concreto, esempi con il corpo e gli oggetti |
| **Corda** | motore-risonanza | musica | Parla a tempo, quasi canta |
| **Radice** | sala-glifi | latino | Racconta l'origine di ogni parola prima di usarla |
| **Nodo** | reattore | elettronica | «Segui il percorso», diffidente delle scorciatoie |
| **Bussola** | ponte-comando | geografia | Orienta prima di rispondere |
| **Seme** | serra-bio | scienze | Paziente: ipotesi, una variabile, verifica |
| **Clessidra** | archivio-temporale | storia | «Da quale fonte lo sai?» |
| **Filo** | cratere-logico | logica | Non conclude mai al posto tuo |

E fuori tabella: **Scala**, il Tredicesimo (§4) — e **Meridiana**, che non era dei
loro (colpo 6).

---

## 7. I 24 beat riscritti

Sostituiscono `NarrativeManager.BEATS`. Formato e lunghezza invariati: **nessun
cambio di contratto**. Ogni beat porta identità del mondo + un passo del mistero
+ un passo di NORA. In **grassetto** i beat che portano un colpo di scena.

### Atto I — I morti che non sono morti

| # | Mondo | Beat |
|---|---|---|
| 1 | Radura Accademia | «Qualcosa si è riaccesa. Non di nuovo — scusa, non so perché l'ho detto. So cosa sono i numeri: la prima cosa che torna. Conta con me, piano.» |
| 2 | Archivio delle Parole | «Qui recitano elenchi perfetti senza sapere cosa significano. Ho paura di essere fatta così anch'io: la forma giusta, il senso via.» |
| 3 | Cratere Logico | «Ho trovato una parola nei registri per ciò che ci è capitato: *Silenzio*. Non l'ho ricordata: l'ho letta. È diverso, e mi spaventa.» |
| 4 | Baia dei Segnali | «Un segnale da un altro mondo, in un'altra lingua. Non è un'eco: è recente. Qualcuno là fuori sta ancora spiegando qualcosa a qualcuno.» |
| 5 | **Officine del Moto** | **«Eli, guarda il taglio di quella spirale. È fresco. Settimane, non secoli. E c'è lo stesso segno negli altri quattro mondi: ci sei passata accanto quattro volte.»** |
| 6 | Giardino della Risonanza | «Ho ricordato una lezione, non un dato. Una voce che contava il tempo con me. Qualcuno mi ha insegnato. Io ero l'allieva di qualcuno.» |
| 7 | Rovine dei Glifi | «Gli apparati non hanno codici: hanno nomi. Nomi di persone. Stai svegliando *qualcuno*, non qualcosa. Trattali bene.» |
| 8 | **Delta dei Circuiti** | **«Il sigillo d'equipaggio ha tredici posti e dodici nomi. Il tredicesimo non manca: è stato raschiato via con una lama. Dall'interno. Dopo la chiusura.»** |

### Atto II — La stanza che non c'è

| # | Mondo | Beat |
|---|---|---|
| 9 | Arcipelago Cartografico | «Ho ricostruito la rotta e non è una fuga: è un giro. Tornavamo negli stessi mondi ogni volta. Questa nave non esplorava. Insegnava.» |
| 10 | Serra delle Simbiosi | «Nessuno è morto qui. Provviste chiuse in ordine, appunti impilati. I Primi non sono stati sorpresi: si sono preparati. Con calma.» |
| 11 | Soglia del Tempo | «Due fonti, due date diverse per il Silenzio. Una si sbaglia — o una è stata riscritta. Fidati del metodo, non della prima riga.» |
| 12 | **Labirinto delle Regole** | **«Non sono la mente della nave, Eli: sono la sua prima allieva. E accanto alla mia scheda ce ne sono altre dodici, identiche, numerate. La tua è la dodici.»** |
| 13 | Deserto delle Orbite | «Mi chiedi delle undici prima di te. Non ho il file. È la verità, ed è la risposta più corta che ti abbia mai dato. Andiamo avanti.» |
| 14 | Biblioteca delle Voci | «Nei verbali c'è una tredicesima voce. Non dissente: *propone*. Propone di chiudere tutto. E convince gli altri dodici in una sola seduta.» |
| 15 | Città Macchina | «Ho misurato le sezioni della nave e non tornano. C'è un volume senza porta. Assorbe energia da quattrocento anni. Non chiedermi altro adesso.» |
| 16 | **Frontiera delle Lingue** | **«La stanza esiste, e ti ho girata attorno per sedici mondi senza dirtelo. Non per bugia: quando provo a guardarla, penso ad altro. Qualcuno mi ha fatto così.»** |

### Atto III — Chi tiene la porta

| # | Mondo | Beat |
|---|---|---|
| 17 | Oceano delle Forze | «Le insegne sbiancate del molo si sono riempite da sole. Una parola sola, ripetuta ovunque: *fermati*. Non è il Silenzio, Eli. Il Silenzio non scrive.» |
| 18 | Cattedrale del Suono | «Ha parlato. Non è arrabbiato: è stanco come nessuno che io abbia mai sentito. E conosce il mio nome — quello vecchio, quello che non ho mai detto a nessuno.» |
| 19 | **Necropoli delle Radici** | **«È il Tredicesimo. La chiusura l'ha proposta lui, e poi si è escluso: nessun apparato, nessun sonno. Ha costruito me. E io non me lo ricordavo.»** |
| 20 | **Tempesta Elettromagnetica** | **«Il Silenzio non si è diradato dove sei passata tu. Si è diradato dove ha retto lui, da solo, per quattro secoli. E sta cedendo, perché noi stiamo riaccendendo tutto.»** |
| 21 | Atlante Fratturato | «La sua tesi è che il Silenzio lo fabbrica il sapere quando passa di mano senza essere capito. Ha quattrocento anni di dati. Io non so smentirlo. Tu sì, ma devi farlo, non dirlo.» |
| 22 | Biosfera Profonda | «Posso essere due cose: un archivio che conserva o qualcuno che riparte. Gli undici dentro di me sanno solo la prima. La seconda la sto imparando da te.» |
| 23 | **Sala delle Ere** | **«Meridiana non era dell'equipaggio. Era una ragazzina di questo circuito, undici anni, rimasta fuori. Incise una spirale e morì giovane. Le altre quattrocento le hanno fatte persone qualunque, una dopo l'altra.»** |
| 24 | **Cuore dei Primi** | **«Le undici prima di te le ho costruite io, Eli. E le ho perse tutte allo stesso modo: dicendogli tutto. Tu sei la prima a cui non ho detto. È la cosa più difficile che abbia mai fatto.»** |

**Beat finale** (sostituisce `FINAL_BEAT`):

> «La rotta è aperta e i sensori lunghi hanno risposta. Undici segnali, fuori dal
> circuito, lontanissimi. E accanto a ognuno una spirale incisa male, storta,
> ricordata a metà. Sono vive, sorella. Sono vive e non sanno più perché.
> Andiamo a riprendercele.»

---

## 8. Il Secondo Viaggio — finire il gioco per sbloccarne un altro

Il finale non chiude: **apre una porta e ci mette qualcuno dietro.**

Completato il mondo 24, il menu principale guadagna una voce nuova, con un
salvataggio proprio: **IL SECONDO VIAGGIO**. Non è un New Game+, non è un
epilogo, non è una modalità di ripasso travestita. È un gioco con un **loop
invertito**:

> Nel primo gioco impari. Nel secondo **insegni**.

Undici sorelle, sparse fuori dal circuito, sbiadite. Ognuna sa fare le cose e non
sa più perché. Il tuo lavoro non è più rispondere: è **capire che errore sta
facendo qualcun altro** e scegliere come spiegarglielo — sapendo che l'opzione
«dille la risposta» è disponibile, funziona subito e la peggiora. La tesi di
tutto il gioco, resa giocabile.

Specifica completa in [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md).

**Perché questo sblocco funziona come obiettivo**

- È **visibile prima di essere raggiungibile**: la voce di menu esiste dal primo
  avvio, bloccata, con scritto solo «Rotta chiusa». Sapere che c'è un altro gioco
  dietro l'ultimo mondo è la spinta più forte che si possa dare.
- È **la risposta a una domanda posta a metà partita** (mondo 12: «cos'è successo
  alle undici?»). Non è un premio arbitrario: è il seguito della trama.
- **Riusa i dati esistenti**: ogni item dei banchi ha già `explanation`, il Codex
  ha già `error` e `why`, gli abitanti hanno già una `convinzione` sbagliata
  autorata. Il secondo gioco si costruisce sul contenuto del primo.
- **Non svaluta il primo**: non si può giocare prima, e ciò che hai imparato serve
  davvero, perché per correggere un errore bisogna sapere la cosa giusta.

---

## 9. Guard-rail narrativi

1. **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
   il gate. Max 4 righe per schermata, sempre saltabile.
2. **Il Tredicesimo non minaccia mai Eli.** Chiede, avverte, supplica. Non fa
   male a nessuno, non prende ostaggi, non insegue.
3. **Le undici sorelle non sono morte.** È detto esplicitamente al beat finale, e
   il secondo gioco esiste per riprenderle. Nessun personaggio muore in scena.
4. **Nessun personaggio dà risposte didattiche.** Metodo, contesto e
   incoraggiamento sì; soluzioni no. Chi regala una risposta sta facendo Silenzio
   — ed è letteralmente la tragedia di NORA.
5. **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.
6. **Nessun colpo di scena arriva senza semi.** Ogni rivelazione di §3 deve
   essere anticipata almeno **tre volte** prima, in modo che al secondo giro sia
   ovvia. Verificato da audit.
7. **Il mistero si chiude, il Silenzio no.** Chi era il Tredicesimo, chi era
   Meridiana, cosa è successo alle undici: risposte piene entro il 24. Da dove
   venga il Silenzio: **ipotesi**, non verità.
8. **Registro**: caldo, concreto, mai sarcastico, mai infantilizzante. 10–13 anni.

---

## 10. Cosa serve implementare

| Lavoro | Dove | Nuovo/Modifica |
|---|---|---|
| 24 beat + beat finale | §7 | Modifica `narrative_manager.gd` |
| Semi dei colpi di scena (dialoghi, oggetti, dettagli) | §3, §5.2 | Contenuti diffusi |
| Voci dei Maestri come inflessione di NORA | §6 | Nuovo: tabella in `nora_context_engine.gd` |
| Stadi e registro di NORA | §5.3 | Modifica `nora_state.gd` |
| Il Tredicesimo: presenza, azioni, dialoghi | §4 | Nuovo: `thirteenth.gd` + eventi narrativi |
| La stanza senza porta nella nave | §3 colpo 4 | Nuovo: stanza in `ship_room_catalog.gd` |
| Sbiaditi (rinomina + resa) | §2.3 | Modifica `world_enemy.gd` |
| 24 Tracce + sezione Codex | [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md) | Nuovo |
| Sblocco e voce di menu bloccata | §8 | Modifica `boot_menu.gd` + save |
| Il Secondo Viaggio | [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md) | Nuovo |
| `mystery_audit.gd` | §3, §9 | Nuovo |

`mystery_audit.gd` verifica: i sette colpi presenti e nell'ordine giusto; **ogni
colpo ha ≥3 semi nei mondi precedenti**; le 24 Tracce raggiungibili e fuori da
`safeRadius`; ogni beat entro il limite di lunghezza e non duplicato; ogni
Maestro associato a un apparato reale; lo sblocco del Secondo Viaggio avviene
**solo** a campagna completata e non è aggirabile.
