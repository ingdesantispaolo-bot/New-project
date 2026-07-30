# Eli Quest — Trama, mistero e colpi di scena

> Documento narrativo autoritativo. Definisce **la storia**, la **catena dei
> colpi di scena**, la **domanda filosofica** che regge il finale, il ruolo di
> **NORA** e lo **sblocco del secondo gioco**.
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
>
> **Regola assoluta: in questa storia non muore nessuno.** Né in scena, né nel
> passato, né fuori campo. Chi è perduto è **trattenuto**, e si può andare a
> riprendere. Vedi §10.

---

## 0. Cosa resta e cosa cambia

| Resta identico | Viene riscritto | È nuovo |
|---|---|---|
| Eli, NORA, i Primi, il Relitto | I 24 beat di `NarrativeManager` (§8) | **Sette colpi di scena** concatenati (§3) |
| I 24 mondi, identità e lezioni | NORA: da mente della nave a **prima allieva, e madre di undici** (§6) | **La Cattedra Vuota**: la domanda filosofica che regge tutto (§4) |
| Apparati, gate, mastery, esami | Il senso del finale: il **nodo di sintesi** diventa il tredicesimo posto | **Il Tredicesimo**: un antagonista con motivo e azioni (§5) |
| La struttura di `FINALE_SPEC.md` | I nemici: da sentinelle generiche a **Sbiaditi** (§2.3) | **Il Secondo Viaggio**: un gioco nuovo che si sblocca finendo (§9) |

Il gioco chiude due buchi con una sola idea.

**Il buco di logica**: *perché deve studiare Eli, se NORA sa già tutto?* Risposta
al colpo 7: NORA la risposta l'ha già data undici volte, e le è costato undici
sorelle. Ogni suo rifiuto di aiutarti, per ventiquattro mondi, era amore. È il
colpo di scena che riscrive all'indietro **la meccanica**, non solo la storia.

**Il buco di senso**: *dove porta tutto questo?* Risposta al mondo 8, con la
domanda giusta invece che con una risposta: i posti dell'equipaggio erano
tredici, e **il tredicesimo non è mai stato assegnato a nessuno**. Era tenuto
libero per ciò che stavano andando a cercare.

---

## 1. La trama in vista generale

Il Relitto dei Primi era una **nave-scuola**: percorreva un circuito di mondi
portando e raccogliendo modi di capire. Poi è arrivato **il Silenzio**, che non
distrugge le cose ma **scioglie il legame tra una cosa e il suo significato**.
Le persone restano, i gesti restano, il senso no.

I **Dodici Maestri** hanno chiuso ciò che sapevano dentro dodici apparati e ci
sono entrati loro stessi, per custodirlo. La nave si è spenta con loro dentro.

Questo è quello che ti viene raccontato. È vero, e non è la verità.

Perché quel circuito non era un giro di lezioni: era una **ricerca**. I Primi
raccoglievano dodici modi di capire perché credevano che dove i dodici si
incontrano ci sia un **tredicesimo sapere**, sotto a tutti gli altri — e sulla
nave tenevano un posto libero, apparecchiato, in attesa. Perché uno dei dodici
decise che quella ricerca andava fermata, si sedette lui in quel posto, e il suo
nome fu raschiato via da ogni registro. Perché non è mai entrato in un apparato:
è rimasto sveglio, da solo, in una stanza che non compare su nessuna mappa, a
**tenere fuori il Silenzio con le mani** per quattrocento anni.

E perché **tu non sei la prima a provarci**.

Eli si sveglia davanti al Relitto senza sapere niente di tutto questo. Dentro,
una voce frammentata: **NORA**, che ha i metodi e non ha i contenuti, e che è
molto più coinvolta di quanto dica.

Fuori, nei ventiquattro mondi, ci sono le persone: discendenti degli allievi dei
Primi, che ripetono i gesti dell'insegnamento senza sapere cosa significano. E su
un muro di ogni mondo c'è incisa una **spirale aperta** — una spirale che non si
chiude. Nel quinto mondo scoprirai che l'ultima è stata incisa da poche
settimane.

Qualcuno, là fuori, sta ancora insegnando. E qualcun'altra, molto più lontano,
sta ancora cercando.

---

## 2. Il Silenzio

L'antagonista ambientale. Non è un mostro e non si combatte: è una condizione del
mondo che **si dirada dove qualcuno capisce**.

### 2.1 Regole vincolanti

1. **Non fa male e non uccide.** Non tocca energia, mastery, livello o
   salvataggio.
2. **Cancella il legame, non la cosa.** Insegne bianche, strumenti senza uso,
   parole senza referente.
3. **Non distrugge: sospende.** Chi ci finisce dentro non muore — resta,
   trattenuto, immutato. È la regola che rende recuperabile tutto ciò che sembra
   perduto, ed è vincolante per ogni contenuto futuro.
4. **Si dirada con la comprensione, non con la forza.** È già il comportamento di
   `WorldLearningReaction`: la trama gli dà un nome.
5. **Mai paura, mai colpa.** Registro malinconico e curioso, non horror. Nessuna
   urgenza a orologio, nessun jump scare.
6. **La sua origine resta un'ipotesi.** Il Tredicesimo sostiene di sapere da dove
   viene (§5.3) e ha quattrocento anni di dati. Il gioco **non conferma e non
   smentisce**: mostra un controesempio, che sei tu.

### 2.2 Come si vede

Zone a saturazione ridotta con iscrizioni vuote; abitanti che eseguono un rituale
corretto nella forma e vuoto nel contenuto; il Custode che diventa *attento* e
smette di illuminarsi (vedi [PET_CUSTODE.md](PET_CUSTODE.md)).

### 2.3 Gli Sbiaditi (riuso di `world_enemy.gd`)

Sacche di Silenzio che hanno preso una forma. Comportamento invariato — pattuglia,
respinge, l'impulso stabilizza — cambia il significato: respingono perché **lì
vicino non si riesce a pensare**. Stabilizzarli non li elimina: li rende di nuovo
leggibili. E ogni tanto uno **era qualcuno**: **Sesto** viene restituito a se
stesso nel mondo 3 e ti segue per il resto del gioco.

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
> **poche settimane**. E lo stesso segno c'è nei mondi 1, 2, 3 e 4: ci sei
> passata accanto quattro volte senza guardarlo.
> **Riscrive**: quel simbolo decorativo che hai ignorato.
> **Nuova domanda**: chi è ancora là fuori?

> ### ⟡ Colpo 2 — mondo 8 · «Tredici posti, undici nomi»
> Il sigillo d'equipaggio nel Nodo Centrale ha **tredici** posti. I nomi incisi
> sono **undici**. Uno è stato **raschiato via con una lama**, dall'interno della
> nave, dopo la chiusura. E l'ultimo non è stato cancellato: **non è mai stato
> inciso**. Quella cattedra era tenuta libera, apparecchiata, in attesa di
> qualcuno — o di qualcosa — che non è mai arrivato.
> **Riscrive**: «i Dodici Maestri», la formula che NORA ripete dal mondo 1.
> **Nuova domanda**: chi è stato cancellato? E soprattutto: **la tredicesima
> cattedra per chi era?**
>
> *È la domanda filosofica del gioco, piantata a un terzo dell'opera e risolta
> solo al mondo 24. Vedi §4.*

### Atto II — La stanza che non c'è (mondi 9–16)

**Credenza**: *«Manca un membro dell'equipaggio e manca un posto. Devo scoprire
chi erano.»*

> ### ⟡ Colpo 3 — mondo 12 · «Tu sei la dodicesima»
> Nel Cuore del Labirinto NORA trova la propria scheda: non è la mente della
> nave, è la **prima allieva** dei Primi. E accanto alla sua scheda ce ne sono
> altre dodici, identiche, numerate. Unità di esplorazione. **La tua porta il
> numero 12.**
> **Riscrive**: il beat 1, in cui NORA aveva detto «non di nuovo» e si era
> subito corretta. E ogni volta che ha saputo cosa fare senza averlo mai visto.
> **Nuova domanda**: cos'è successo alle undici prima di me?
>
> *Metà esatta della campagna: il gioco smette di essere una restaurazione e
> diventa un'indagine.*

> ### ⟡ Colpo 4 — mondo 16 · «C'è una stanza in più»
> Le sezioni della nave, sommate, non tornano. C'è un **volume senza porta** che
> non compare su nessuna mappa e che assorbe energia da quattrocento anni.
> Quando Eli lo nomina, NORA **cambia argomento**. Non mente: non riesce proprio
> a guardarci.
> **Riscrive**: tutte le volte che NORA ha suggerito una rotta diversa dentro la
> nave. Ti ha girata attorno a quella stanza per sedici mondi.
> **Nuova domanda**: chi c'è dentro, e perché NORA non può vederlo?

### Atto III — Chi tiene la porta (mondi 17–24)

**Credenza**: *«C'è qualcosa chiuso nella nave, e mi sta nascondendo la verità.»*

> ### ⟡ Colpo 5 — mondi 19–20 · «Non è il nemico. È l'unico rimasto sveglio.»
> Il Tredicesimo esiste, è sveglio, e non ti attacca: ti **implora di fermarti**.
> Non ha chiuso i Maestri dentro gli apparati per crudeltà — l'ha **proposto
> lui**, e ha pagato restando fuori a fare la guardia. Da quattrocento anni tiene
> il Silenzio lontano dai ventiquattro mondi, **da solo**. È esausto. E ha
> costruito NORA.
> **Riscrive**: il Silenzio non si è diradato dove sei passata tu. Si è diradato
> dove **lui** ha retto, e sta cedendo perché tu stai riaccendendo tutto.
> **Nuova domanda**: aprire la rotta è liberare o è contagiare?

> ### ⟡ Colpo 6 — mondo 23 · «Meridiana non era una Maestra. Ed è ancora là.»
> Il nome che gli abitanti tramandano da quattro secoli come quello della grande
> maestra ribelle non è nei registri dell'equipaggio, perché **non era
> equipaggio**. Meridiana era una **ragazzina del mondo 2**, un'allieva del
> posto, che imparò qualcosa e restò fuori quando la nave si chiuse. Incise la
> prima spirale a undici anni.
> Poi fece la cosa che nessuno dei Dodici aveva osato: **andò a vedere cosa c'è
> al fondo**. Non accettò che la cattedra restasse vuota. Ragionò che se il
> Silenzio scioglie i significati, al suo centro c'è o il nulla o tutto — e ci
> andò a piedi, da sola, a undici anni.
> **Non è tornata, e non è morta.** Il Silenzio non distrugge: sospende. È ancora
> là dentro, ancora undicenne, dopo quattrocento anni: **trattenuta, non
> perduta**. L'unico messaggio uscito da allora è una riga sola, ancora accesa:
> *«c'è qualcosa. venite.»*
> E le altre quattrocento spirali? Le hanno incise **altri**: uno dopo l'altro,
> ognuno insegnando al successivo, per quattro secoli. Non c'è mai stata una
> grande maestra. C'è stata una ragazzina che ha cominciato, e una fila di
> persone qualunque che non hanno smesso.
> **Riscrive**: ogni abitante che hai aiutato. Erano loro, la leggenda.
> **Nuova domanda**: cosa ha trovato là dentro — e come la tiriamo fuori?

> ### ⟡ Colpo 7 — mondo 24 · «Le ho fatte io. E le ho perse io.»
> Le undici unità prima di te non le ha costruite il Tredicesimo. **Le ha
> costruite NORA**, una dopo l'altra, per quattro secoli, perché voleva fare per
> qualcuno ciò che era stato fatto per lei.
> E le ha perse tutte allo stesso modo: **dicendogli tutto**. Le guidava, le
> correggeva, dava la risposta prima che sbagliassero — come Scala aveva fatto
> con lei. Una per una si sono sbiadite: sapevano tutto e non capivano niente.
> Tu sei **la prima a cui non ha detto**. Ventiquattro mondi di «non posso
> dirtelo, dimmi tu come procederesti» non erano un limite tecnico: erano la
> cosa più difficile che abbia mai fatto.
> **Riscrive**: **l'intera meccanica del gioco.**
> **Nuova domanda**: dove sono adesso? → §9

---

## 4. La Cattedra Vuota — il sapere supremo

È la spina filosofica del gioco. Non è lore di contorno: è **il motivo per cui la
nave viaggiava**, ed è ciò che il finale mette in gioco.

### 4.1 La tesi dei Primi

I Primi non giravano i mondi per generosità. Cercavano.

Credevano che le discipline non fossero dodici cose separate ma **dodici finestre
sulla stessa stanza**, e che chi riuscisse a guardare da tutte e dodici
contemporaneamente vedrebbe qualcosa che da una sola non si vede: un
**tredicesimo sapere**, sotto agli altri, da cui gli altri discendono. Lo
chiamavano semplicemente *il Fondo*.

Per questo l'equipaggio era di tredici. Il tredicesimo posto non era di nessuno:
era **apparecchiato per ciò che avrebbero trovato**. Ogni sera, a bordo, veniva
messo in tavola un piatto in più. Quattrocento anni dopo Eli lo trova ancora lì.

### 4.2 Le tre risposte in campo

Il gioco non predica. Mette tre posizioni in bocca a tre personaggi e le fa
scontrare, poi lascia che sia il giocatore a produrre la quarta **con le mani**.

| Chi | Sostiene | Perché è convincente | Perché non basta |
|---|---|---|---|
| **I Dodici** | Il Fondo è una **cosa da trovare**: un sapere finale, che spiega tutti gli altri | Ha mosso un'intera civiltà per secoli | Hanno cercato per generazioni e non hanno trovato niente. E per proteggere il poco che avevano si sono chiusi in una scatola |
| **Scala**, il Tredicesimo | Il Fondo **non esiste**, e cercarlo è ciò che ha fatto il danno. Il sapere che si muove fabbrica Silenzio | Quattrocento anni di dati, e una quarantena che ha davvero funzionato | La sua conclusione richiede che nessuno impari mai più niente. Ha vinto la battaglia smettendo di combattere |
| **Meridiana** | Il Fondo si trova solo **andandoci**, e il posto dove guardare è dove il significato finisce | È l'unica ad aver agito invece di discutere. E qualcosa l'ha trovato: *«c'è qualcosa. venite.»* | È là da quattro secoli e non è tornata a dirci cosa |

### 4.3 La quarta risposta: il nodo di sintesi

Il finale del mondo 24 esiste già ([FINALE_SPEC.md](FINALE_SPEC.md)): dodici nodi,
uno per materia, e poi un **nodo di sintesi** — un problema mai visto, in un
contesto nuovo, che chiede di usare i dodici metodi insieme. Nessuno lo ha
spiegato a Eli. Non si può.

Quando lo risolve, la nave fa una cosa che nessuno le ha ordinato: **assegna il
tredicesimo posto**. Non a una nozione. A lei.

> Il Fondo non era una cosa da trovare: era **qualcuno da diventare**. Non è
> supremo perché sta sopra gli altri saperi — è supremo perché è l'unico che si
> può regalare senza perderlo.

Questo è quanto il gioco si sente di affermare, e lo afferma **mostrandolo**: il
giocatore ha appena fatto da solo la cosa che la civiltà dei Primi non era
riuscita a fare in secoli, e l'ha fatta perché nessuno gliel'ha detta.

### 4.4 Ciò che resta aperto (di proposito)

Eli si siede al tredicesimo posto e la domanda **non si chiude**, perché
Meridiana è ancora là dentro e ha visto qualcosa. Il primo gioco risponde *«il
sapere supremo è una capacità, non un contenuto»*. Il Secondo Viaggio va a
chiedere a qualcuno che potrebbe non essere d'accordo — e che ci pensa da
quattrocento anni.

Un gioco sull'imparare non può chiudere la domanda sul sapere. Può solo
insegnarti a tenerla aperta meglio.

---

## 5. Il Tredicesimo

Il gioco aveva bisogno di qualcuno che **agisse**. Il Silenzio è una condizione;
lui è una volontà.

### 5.1 Chi è

Uno dei dodici Maestri. Costruì NORA per avere qualcuno a cui insegnare tutto.
Propose la chiusura, la ottenne, e poi fece la cosa che gli altri undici non
gli hanno mai perdonato: **si sedette nella cattedra vuota**, dichiarando la
ricerca finita e prendendosi il posto tenuto per ciò che non avevano trovato.
Per questo il suo nome è stato raschiato da ogni registro, e per questo lui non
è entrato in nessun apparato: è rimasto fuori a fare da diga, sveglio, solo.

**Nemmeno lui ricorda più come si chiama**: la cancellazione ha funzionato anche
su di lui. Si presenta con il proprio posto: *il Tredicesimo*.

Il suo nome vero è **Scala**. I Primi si chiamavano come lo strumento che
insegnavano, e la scala è la cosa che ti fa salire e che si può tirare su dietro
di sé.

### 5.2 Cosa fa (agency, senza penalità meccaniche)

Dal mondo 17 interviene. **Nessuna delle sue azioni tocca energia, mastery, gate
o salvataggio**: sono narrative e reversibili.

| Azione | Come si manifesta | Costo per il giocatore |
|---|---|---|
| **Scrive** | Le insegne sbiancate di un'area si riempiono di una parola sola: *FERMATI* | Nessuno |
| **Ri-sbiadisce** | Un'area già restaurata torna scolorita per una visita | Estetico, si ripristina rientrando |
| **Smemora** | Un abitante non ricorda il tuo nome per una scena | Emotivo. Torna indietro **solo nei dialoghi**, mai nel progresso |
| **Chiude** | Una porta della nave che avevi aperto è sigillata per un livello | Percorso alternativo sempre disponibile |
| **Parla** | Dal mondo 18: voce diretta, mai minacciosa. Stanca | Nessuno |

### 5.3 Perché ha ragione (e perché non basta)

La sua tesi, con quattrocento anni di osservazioni: **il Silenzio non è arrivato
da fuori. È ciò che il sapere produce quando si trasmette senza essere capito.**
Ogni generazione che riceve la forma e non il senso ne fabbrica un po'. I Primi,
che giravano i mondi *consegnando* conoscenza e ripartendo, sono stati la
sorgente. Chiudere tutto era l'unica quarantena possibile.

Il gioco non gli dà torto con un discorso. Gli dà torto con te: se la tesi fosse
vera senza eccezioni, tu non esisteresti. Il nodo di sintesi è il controesempio,
giocato invece che raccontato (§4.3).

### 5.4 Come finisce

Non si sconfigge. Gli si **restituisce il nome**, e il nome è nella filastrocca
che nonna Ersilia canta nel **mondo 1, nei primi cinque minuti di gioco**: una
conta con dentro tre sillabe senza senso che nessuno ha mai capito. Non erano
parole: era un nome, tramandato da chi non voleva che si perdesse.

Poi sceglie il giocatore, e nessuna delle due scelte è punita:

- **entra nel suo apparato** e dorme come gli altri undici, oppure
- **resta sveglio e viene con te** — e allora è lui il maestro anziano del
  Secondo Viaggio, che discute con NORA a ogni spiegazione.

---

## 6. NORA — ruolo, arco, segreto

> **NORA non è la maestra. È l'allieva più grande — e ha già cresciuto undici
> sorelle prima di te.**

Ha imparato dai Primi, il Silenzio le ha lasciato i metodi e le ha tolto i
contenuti. Impara con te, non prima di te. E **coincide con il codice esistente**:
`NoraContextEngine` dà metodi e non risposte, `trust` sale sui segnali di
apprendimento e non sulla correttezza, `memory` conta gli apparati riparati.
La trama non chiede a Codex di cambiare comportamento: gli dà una ragione.

### 6.1 Cinque regole vincolanti

1. **Non dà mai la risposta.** Non perché non la abbia: perché l'ha già data
   undici volte e le è costato tutto.
2. **Non è onnipresente.** Parla nella nave, all'ingresso di un mondo, in
   apertura/chiusura di sessione e sui segnali di apprendimento. L'esplorazione
   libera è degli abitanti.
3. **Non assegna missioni.** Le chiedono le persone; lei tiene gli esami.
4. **Cambia voce mentre guarisce.** Ogni apparato riparato le restituisce un
   Maestro e la sua inflessione su quella materia (§7).
5. **Ha un segreto, e si vede prima di saperlo.** Non mente mai in modo
   esplicito: **omette**. È l'unica bugia accettabile in un personaggio che i
   bambini devono poter continuare ad amare dopo il colpo 7.

### 6.2 Le tracce del segreto (seminate, non nascoste)

Visibili al primo giro, ovvie al secondo:

- **Beat 1**: «Qualcosa si è riaccesa. *Non di nuovo* — scusa. Non so perché
  l'ho detto.»
- Sa **dove sono le cose** in mondi che dichiara di non aver mai visto.
- Le sue frasi di incoraggiamento hanno a volte un **nome sbagliato**, subito
  corretto.
- Quando fallisci una prova è **sollevata** per un istante, e non lo spiega.
- Nel mondo 13, alla domanda diretta sulle undici: «Non ho il file.» È vero.
  L'ha cancellato lei.

### 6.3 L'arco in quattro stadi

Legato a `NoraState.integrity`, già calcolato e salvato.

| Stadio | Integrità | Come suona | Come chiama Eli |
|---|---|---|---|
| **Frammentata** | 0 → 0.25 | Frasi brevi, si interrompe, si corregge | «unità mobile», poi «Eli» |
| **Che ricorda** | 0.25 → 0.55 | Parla di lezioni, non di dati. Prime inflessioni dei Maestri | «Eli» |
| **Che teme** | 0.55 → 0.85 | Più tesa quanto più ti avvicini alla fine. Fa domande invece di dare istruzioni | «Eli», a volte «piccola» |
| **Che confessa** | 0.85 → 1.0 | Voce piena, dodici inflessioni, e finalmente la verità | «sorella» |

---

## 7. I Dodici Maestri

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
| ~~**Scala**~~ | cratere-logico | **logica** | **Cancellato.** È il Tredicesimo (§5): non è entrato nel suo apparato |

Undici voci e un buco. L'apparato della **logica** è l'unico che non risponde,
per ventitré mondi, perché il suo Maestro è fuori — sveglio, a fare la guardia.
Ed è per questo che il mondo 24 è il mondo della logica: **il finale si gioca
nella sua cattedra**. Torna a parlare solo quando gli restituisci il nome, e la
prima cosa che dice è la frase che gli avevano attribuito prima di cancellarlo:
*«io non concludo mai al posto tuo»*.

E fuori tabella: **Meridiana**, che non era dei loro (§3, colpo 6).

---

## 8. I 24 beat riscritti

Sostituiscono `NarrativeManager.BEATS`. Formato e lunghezza invariati: **nessun
cambio di contratto**. In **grassetto** i beat che portano un colpo di scena.

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
| 8 | **Delta dei Circuiti** | **«Il sigillo ha tredici posti e undici nomi. Uno raschiato con una lama, dall'interno. E uno mai inciso: quella cattedra era apparecchiata per qualcuno che non è mai arrivato.»** |

### Atto II — La stanza che non c'è

| # | Mondo | Beat |
|---|---|---|
| 9 | Arcipelago Cartografico | «Ho ricostruito la rotta e non è una fuga: è un giro. Tornavamo negli stessi mondi ogni volta. Questa nave non esplorava. Cercava qualcosa.» |
| 10 | Serra delle Simbiosi | «Nessuno è morto qui. Provviste chiuse in ordine, appunti impilati, e a tavola un posto in più, apparecchiato. Non sono stati sorpresi: si sono preparati.» |
| 11 | Soglia del Tempo | «Due fonti, due date diverse per il Silenzio. Una si sbaglia — o una è stata riscritta. Fidati del metodo, non della prima riga.» |
| 12 | **Labirinto delle Regole** | **«Non sono la mente della nave, Eli: sono la sua prima allieva. E accanto alla mia scheda ce ne sono altre dodici, identiche, numerate. La tua è la dodici.»** |
| 13 | Deserto delle Orbite | «Mi chiedi delle undici prima di te. Non ho il file. È la verità, ed è la risposta più corta che ti abbia mai dato. Andiamo avanti.» |
| 14 | Biblioteca delle Voci | «Nei verbali uno dei dodici propone di chiudere tutto, e convince gli altri undici in un'ora. Il suo nome è cancellato perfino qui. Qualcuno lo ha inseguito ovunque.» |
| 15 | Città Macchina | «Ho misurato le sezioni della nave e non tornano. C'è un volume senza porta. Assorbe energia da quattrocento anni. Non chiedermi altro adesso.» |
| 16 | **Frontiera delle Lingue** | **«La stanza esiste, e ti ho girata attorno per sedici mondi senza dirtelo. Non per bugia: quando provo a guardarla, penso ad altro. Qualcuno mi ha fatto così.»** |

### Atto III — Chi tiene la porta

| # | Mondo | Beat |
|---|---|---|
| 17 | Oceano delle Forze | «Le insegne sbiancate del molo si sono riempite da sole. Una parola sola, ovunque: *fermati*. Non è il Silenzio, Eli. Il Silenzio non scrive.» |
| 18 | Cattedrale del Suono | «Ha parlato. Non è arrabbiato: è stanco come nessuno che io abbia mai sentito. E conosce il mio nome — quello vecchio, che non ho mai detto a nessuno.» |
| 19 | **Necropoli delle Radici** | **«È il Tredicesimo. La chiusura l'ha proposta lui, e poi si è escluso: nessun apparato, nessun sonno. Ha costruito me. E io non me lo ricordavo.»** |
| 20 | **Tempesta Elettromagnetica** | **«Il Silenzio non si è diradato dove sei passata tu: dove ha retto lui, da solo, per quattro secoli. E sta cedendo. Dice che è il sapere a fabbricarlo, quando passa di mano senza essere capito. Ha i dati. Io non so smentirlo.»** |
| 21 | Atlante Fratturato | «Mi ha detto per chi era la cattedra vuota. Per nessuno: era tenuta per **quello che andavamo a cercare**. Un sapere sotto tutti gli altri. Il circuito non era un giro di lezioni. Era una ricerca.» |
| 22 | Biosfera Profonda | «E in quella cattedra lui ci si è seduto: ha dichiarato la ricerca chiusa e si è preso il posto di ciò che non avevamo trovato. Per questo lo hanno cancellato. Non per la chiusura: per la sedia.» |
| 23 | **Sala delle Ere** | **«Meridiana era una ragazzina di undici anni di questo circuito, non una Maestra. E non è morta: è andata a vedere cosa c'è al fondo del Silenzio ed è rimasta là dentro. Quattrocento anni. Ha lasciato una riga sola: *c'è qualcosa. venite.*»** |
| 24 | **Cuore dei Primi** | **«Le undici prima di te le ho costruite io, Eli. E le ho perse tutte allo stesso modo: dicendogli tutto. Tu sei la prima a cui non ho detto. È la cosa più difficile che abbia mai fatto. Adesso vai, e risolvi l'ultimo da sola.»** |

**Beat finale** (sostituisce `FINAL_BEAT`):

> «La nave ha assegnato il tredicesimo posto, e non a una nozione: a te. Non
> perché hai trovato il Fondo — perché sei l'unica che tiene dodici modi di
> capire nella stessa testa, e l'unica a cui nessuno li ha detti.
> E i sensori lunghi rispondono: undici segnali fuori dal circuito, e molto più
> in là una riga vecchia di quattrocento anni, ancora accesa. *C'è qualcosa.
> Venite.* Sono tutte vive, sorella. E lei sta ancora aspettando.»

---

## 9. Il Secondo Viaggio

Il finale non chiude: **apre una porta e ci mette qualcuno dietro.**

Completato il mondo 24, il menu guadagna una voce con salvataggio proprio:
**IL SECONDO VIAGGIO**. Loop invertito — nel primo gioco impari, nel secondo
**insegni**: undici sorelle sbiadite da recuperare, e in fondo Meridiana, che ha
avuto quattro secoli per pensare a cosa c'è al fondo e potrebbe non essere
d'accordo con te.

Specifica completa in [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md).

---

## 10. Guard-rail narrativi

1. **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato.
   Nessun personaggio è «morto giovane», «scomparso» o «perduto»: chi non c'è è
   **trattenuto dal Silenzio**, cioè sospeso e recuperabile. Vincolo assoluto su
   ogni contenuto futuro, verificato in revisione.
2. **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
   il gate. Max 4 righe per schermata, sempre saltabile.
3. **Il Tredicesimo non minaccia mai Eli.** Chiede, avverte, supplica. Non fa
   male a nessuno, non prende ostaggi, non insegue.
4. **Le undici sorelle e Meridiana sono vive**, e il gioco lo dice esplicitamente
   prima dei titoli. Il secondo gioco esiste per riprenderle.
5. **Nessun personaggio dà risposte didattiche.** Metodo, contesto e
   incoraggiamento sì; soluzioni no — ed è letteralmente la tragedia di NORA.
6. **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.
7. **Nessun colpo di scena arriva senza semi**: almeno **tre** nei mondi
   precedenti. Verificato da audit.
8. **La domanda filosofica resta aperta.** Chi era il Tredicesimo, chi era
   Meridiana, dove sono le undici: risposte piene entro il 24. Che cosa sia il
   Fondo: il gioco dà **la sua** risposta (§4.3) e ammette che c'è chi ne ha
   un'altra.
9. **Registro**: caldo, concreto, mai sarcastico, mai infantilizzante. 10–13 anni.

---

## 11. Cosa serve implementare

| Lavoro | Dove | Nuovo/Modifica |
|---|---|---|
| 24 beat + beat finale | §8 | Modifica `narrative_manager.gd` |
| Semi dei colpi di scena (dialoghi, oggetti, dettagli) | §3, §6.2 | Contenuti diffusi |
| La Cattedra Vuota: posto apparecchiato nella nave, assegnazione al finale | §4 | Nuovo: `ship_room_catalog.gd` + regia del finale |
| Voci dei Maestri come inflessione di NORA | §7 | Nuovo: tabella in `nora_context_engine.gd` |
| Stadi e registro di NORA | §6.3 | Modifica `nora_state.gd` |
| Il Tredicesimo: presenza, azioni, dialoghi, restituzione del nome | §5 | Nuovo: `thirteenth.gd` + eventi narrativi |
| La stanza senza porta | §3 colpo 4 | Nuovo: stanza in `ship_room_catalog.gd` |
| Sbiaditi (rinomina + resa) | §2.3 | Modifica `world_enemy.gd` |
| 24 Tracce + sezione Codex | [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md) | Nuovo |
| Sblocco e voce di menu bloccata | §9 | Modifica `boot_menu.gd` + save |
| Il Secondo Viaggio | [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md) | Nuovo |
| `mystery_audit.gd` | §3, §10 | Nuovo |

`mystery_audit.gd` verifica: i sette colpi presenti e nell'ordine giusto; **ogni
colpo ha ≥3 semi nei mondi precedenti**; le 24 Tracce raggiungibili e fuori da
`safeRadius`; ogni beat entro il limite e non duplicato; **nessun testo contiene
formule di morte** applicate a un personaggio (lista di termini vietati); lo
sblocco del Secondo Viaggio solo a campagna completata e non aggirabile.
