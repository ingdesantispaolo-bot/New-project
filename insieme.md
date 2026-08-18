# Eli Quest — Piano di lavoro

Aggiornato al 14 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
[Custode avanzato](docs/CUSTODE_LIVELLO_AVANZATO.md) ·
[Minigiochi personaggi](docs/MINIGIOCHI_PERSONAGGI.md)

> **Snellito il 13 agosto 2026, ripulito il 14.** I lotti chiusi escono da qui e
> stanno nel registro del file di rilascio, con le loro misure e i loro audit.
> Qui resta solo ciò che non è fatto.

---

## Dove ci orientiamo — 14 agosto 2026

Le tre direzioni misurate il 5 agosto erano: la profondità degli esercizi (non era
il collo di bottiglia), le spiegazioni (lo era, ed è chiusa) e il divertimento
(non misurabile senza far giocare qualcuno).

La terza si è mossa, e non nel modo previsto. **Una parte del divertimento non
richiedeva un bambino per essere misurata**: bastava leggere che cosa fa il gioco
mentre si gioca, invece di che cosa contiene. Fatta quella lettura, il collo di
bottiglia si è spostato dai contenuti allo **strato di gioco**.

La misura, in una riga: il verbo del gioco oggi è *cammino fino a un'icona e si
apre un pannello*. Tutto il resto — 24 mondi autorati, dieci meccaniche di
minigioco, 46 residenti con un arco, sette colpi di scena — poggia su un ciclo
motorio che non chiede mai una decisione. Le cose che una decisione la chiedono
esistono e sono **tre**: l'enigma che si costruisce mentre rispondi, la
minimissione che cambia la mappa, il duello dei guardiani.

Le voci di questo piano sono lì per aggiungere la quarta, la quinta e la sesta.
Otto sono state chiuse fra il 13 e il 14 agosto — la serie, l'impulso che si
guadagna, la curva della potenza, la nave camminabile, la matematica del primo
livello, i moduli di spedizione, l'audio dei mondi e il Custode nella nave — e
**nessuna ha aggiunto un esercizio**: la
campagna resta a 21,1 ore misurate. È un vincolo del piano, non una speranza: il
collaudo l'ha già definita faticosa, e rispondere a «è noioso» con «è più lungo»
è l'errore che ha prodotto quel verdetto.

### L'ordine, e perché questo

L'ordine residuo è per **resa su costo**. Le voci Codex non bloccate da una
decisione o da un contratto di Claude sono uscite dal piano e stanno nel registro.

| | voce | impatto | costo | chi |
|---|---|---|---|---|
| **G-4** | Collegare i due moduli alla resa C-G4 | basso | basso | Claude |
| **G-10** | Camminare è una scelta | ? | medio | dopo il collaudo |

---

## G-4 · Collegare i due moduli — Claude

La resa C-G4 è pronta. Restano soltanto catalogo e semantica dei due moduli:

- aggiungere `module-radar` e `module-torch` a `RewardCatalog`, con slot `module`;
- calcolare gli effetti in `expedition_modules.gd` e pubblicare i numeri
  `treasureRadarRadius` e `torchRadius` in `runtime_state()`;
- estendere `expedition_module_audit` ai due nuovi effetti.

I consumer visivi restano dormienti a valore zero: il primo mostra un segnale
sulla cassa chiusa entro il raggio, il secondo scala il cono luminoso orientato
con Eli. Le cinque illustrazioni sono già riservate nel `reward-items-sheet` con
gli stessi identificativi.

---

## G-10 · Camminare non è una scelta

**Oggi.** `player_controller.gd` sono settantacinque righe: velocità, uno scatto
il cui moltiplicatore ora viene dai moduli (1,65× o 1,95×),
bob. L'unica cosa che il terreno fa è l'acqua che blocca. L'unica prova d'abilità
di tutto il gioco è il duello dei guardiani.

**La cautela che viene prima della proposta**, ed è del lotto del 6 agosto: *ogni
cosa che costa energia sulla mappa toglie prove fatte*, e la campagna è già lunga.
Quindi non pedaggi. Una **scelta**: lo scatto consuma una risorsa che si ricarica
stando fermi, e apre scorciatoie che non aprono mai niente di obbligatorio.

**Perché è ultimo, dichiarato.** È l'unica voce del piano che si può sbagliare
senza accorgersene, perché il suo unico giudice è il tatto — e il tatto arriva dal
tuo collaudo, non da una misura. Farla adesso significherebbe indovinare.

**Chi.** **Decisione tua dopo il collaudo**, poi Codex.

---

## I residui dei lotti chiusi

Nessuno di questi è un lotto: sono code dichiarate, tenute qui perché non si
perdano.

**Contenuti e didattica (Claude)**

- **N-1 · Le spiegazioni degli item.** Il livello per argomento copre il perché
  generale, ma «Roma è la capitale della Repubblica Italiana» resta una
  riformulazione. Vanno riscritte **per argomento**, partendo da quelli allo 0% di
  nesso: parole di casa, lessico inglese, declinazioni, geografia fisica.
- **Quindici ricette al mondo 1.** Oggi sono dieci per materia. Deciso, e da fare
  **dopo** il collaudo: sei materie del mondo 1 sono cambiate molto e conviene
  sapere se la differenza si sente prima di scriverne altre sessanta.
- **Il banco di matematica è ancora al 78% tabelline.** Il 14 agosto è passato da
  1 a 6 argomenti (284 → 364 voci), ma le 284 tabelline restano la maggioranza e
  gli argomenti nuovi hanno il minimo sindacale di sedici item ciascuno. Il
  prossimo giro li porta al livello delle altre materie — venti-trenta per
  argomento — e aggiunge i due che mancano per la fascia alta: proporzioni ed
  equazioni, che NORA sa già spiegare e il banco non chiede mai.
- **Il pavimento della matematica ai mondi 1–3.** Chi fatica non ha un gradino
  sotto il nominale, perché il livello efficace non scende sotto 1 e lì il
  nominale *è* il pavimento. Si ripara solo portando l'adattività della
  matematica dal canale «livello» a quello «complessità», che oggi sono due
  meccanismi sovrapposti (`effective_difficulty` per il banco,
  `math_effective_level` per il generatore). Vale la pena farlo se il collaudo
  segnala il difetto opposto — qualcuno che al mondo 1 fatica.
- **I vocabolari di banco e minigiochi non coincidono.** La copertura del gate
  conta gli argomenti toccati e il bersaglio si calcola sul **banco**, ma la
  pratica marca anche i 104 argomenti che vivono solo nel catalogo interattivo. In
  inglese, coding, scienze, fisica ed elettronica un bambino può soddisfare la
  copertura toccando argomenti che l'esame non verificherà mai. Delle due
  riparazioni, quella giusta è **allineare i vocabolari**: se un argomento vale per
  la copertura, deve poter comparire in un esame.
- **La scala dei formati per livello.** I singoli esercizi sono graduati
  (`minLevel`), i formati no. La scala proposta segue la difficoltà cognitiva:
  1–4 riconoscere e appaiare · 5–10 mettere in processo · 11–17 leggere una
  rappresentazione · 18–24 manipolare rispettando vincoli.
- **Elettronica alle altre undici.** La scelta multipla a zero fuori dall'esame
  regge in elettronica perché lì la tavolozza dei minigiochi è profonda (ventuno
  argomenti, sette formati). Dove è più magra lascerebbe buchi: si estende materia
  per materia, misurando la tavolozza prima.
- **I ventidue quesiti sui componenti elettronici** (relè, condensatore): il
  problema non è la forma della domanda ma il fatto che un decenne non ha mai visto
  l'oggetto. La risposta giusta è un minigioco che glielo faccia montare.
- **Le leve del nucleo studiate e non attivate**: due luoghi invece di uno per le
  tre materie quando non sono ospiti (tocca il direttore degli eventi e va
  rimisurato il tempo per mondo); ripasso più stretto sui loro argomenti; il
  registro che mostra il nucleo a parte.
- **Gli epiloghi non nominano le minimissioni**: oggi le contano soltanto.

**Minigiochi dei personaggi**

- **C-MG-3 · La lingua della radio.** Marea sta al mondo 4, la cui materia è
  inglese, e i suoi nove messaggi sono in italiano: la meccanica è giusta, il
  materiale no. Passarli all'inglese cambia la difficoltà in modo serio, con cinque
  secondi di segnale e un bambino al quarto mondo. **Decisione tua.**

## Le cose da guardare giocando

Sono i punti in cui una resa sbagliata non rompe niente e toglie tutto il
significato.

- **La durata dei minigiochi dei personaggi.** Misurare su tablet almeno un gioco
  per ciascuna delle quindici meccaniche, insieme agli errori prima della scoperta
  e alla capacità di spiegare la strategia. Solo quei numeri possono decidere se
  un gioco debba aggiungersi al giro o sostituire una tappa di missione, senza
  allungare alla cieca la campagna da 21,1 ore.

- **1 · la conta di nonna Ersilia** va sentita nei primi cinque minuti. È la
  tabellina del 7 e contiene il nome del Tredicesimo. Se il giocatore la salta,
  al mondo 24 non ha la chiave in mano.
- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Se la resa non mostra la direzione dei graffi, il colpo 2 perde metà
  del suo significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Provviste sigillate, appunti impilati, un posto in più
  apparecchiato. Non è una scena di abbandono: è una scena di preparazione.
- **11 · le due datazioni**: nessuna delle due va bruciata, e la resa non deve
  suggerire quale sia «quella giusta».
- **12, 16, 19 · Tracce decisive**: hanno un `ripiego` in `MysteryCatalog`, ed è
  **obbligatorio cablarlo**. Senza, entrare nella Rovina diventa necessario per
  capire il finale, e questo viola il guard-rail «niente blocca il loop».
- **14 · i verbali**: dove dovrebbe esserci il nome della tredicesima voce c'è un
  **buco nella carta**, non una cancellatura. Va reso come un'assenza fisica.
- **17 · le insegne**: è la **prima azione del Tredicesimo** in tutto il gioco
  (`scrive`, poi `risbiadisce`). Una parola sola, ripetuta su ogni insegna
  dell'area, e sparisce uscendo. Nessun effetto sul gioco: costo zero.
- **18 · la voce**: prima volta che il Tredicesimo **parla**. Nessun ritratto,
  nessun corpo. Stanca, mai minacciosa.
- **19 · `chiude`**: la terza azione entra qui. Una porta della nave sigillata per
  un livello, e **deve esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.

### Il mondo 24 · Cuore dei Primi

Non ha residenti suoi: al Cuore convergono **i sei itineranti** e i residenti che
il giocatore ha portato allo stadio 2, **massimo quattro in scena per volta**.

`FinaleCatalog.cast_for(residenti_stadio2, ondata)` risponde con chi è in scena e
`waves_needed()` con quante ondate servono. Contenuto pronto: **una battuta per
ognuno dei 46 residenti** — e ognuna dice cosa quel personaggio ha smesso di
credere, non un saluto — più le sei degli itineranti.

Due vincoli, verificati da `finale_content_audit`:

- **il Cuore non è mai vuoto.** Con zero residenti allo stadio 2 ci sono comunque
  i sei itineranti. Un finale che premia con la solitudine chi ha giocato in un
  altro modo è una punizione travestita da conseguenza;
- **nessuna battuta nomina chi non è venuto.** Gli assenti non si nominano.

`FinaleCatalog.CATTEDRA` ha l'assegnazione del tredicesimo posto. Si innesca
**dopo il nodo di sintesi**, non all'arrivo: il posto va a chi l'ha risolto, non
a chi è arrivato.

---

## Chi fa cosa

| | Claude | Codex | Tu |
|---|---|---|---|
| Codice, contenuti, regole di gioco e audit | ✅ | | |
| **Arte generativa, scena e resa visiva** (voci **C-**) | | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | | ✅ |
| Decisioni di prodotto (G-4, G-8, G-10, C-MG-3) | | | ✅ |

Le voci **G-** sono di Claude tranne dove è nominata una **C-G**: quella riga è di
Codex, ed è sempre la parte che si vede — mai la regola.

Le richieste a Codex passano da questo file e vanno tenute **separate dalla
meccanica**: una cosa deve essere giocabile con forme piene e colori piatti prima
che esista un disegno, altrimenti l'arte diventa un prerequisito e il lotto si
ferma ad aspettarla.

Con un solo esecutore per parte la revisione incrociata sparisce, e la sostituisce
una regola sola: **niente entra senza un audit che lo tenga.** Vale soprattutto per
il runtime, dove un errore non si vede rileggendo — il 3 agosto una sostituzione in
blocco ha invaso due costruttori che non c'entravano, e non me ne sono accorto
rileggendo il diff: me l'ha detto `minigame_audit`.

---

## Le altre voci aperte

Nessuna si scrive: vogliono un **asset** o una **tua decisione**.

- **Secondo foglio di reperti** — serve un'immagine nuova: gli atlanti dei
  reperti sono `.webp` (`artifact_atlas_catalog.gd`), e senza un disegno il
  formato non si estende.
- **Carta d'Europa** — **non serve un disegno.** La carta d'Italia è geometria
  vettoriale derivata da Natural Earth, dominio pubblico
  (`map_geometry_catalog.gd`), non un'immagine. Per l'Europa servono le coordinate
  dei poligoni dallo stesso dataset — un lavoro di dati, non d'arte, e quindi
  qualcosa che posso fare io se mi dai il via.
- **Accessibilità dei formati visuali** — le etichette identificano senza
  descrivere («Segnaposto A»), che è l'unica scelta che non regala la risposta.
  Ma chi usa un lettore di schermo **non può rispondere a una carta muta**. Vale
  già per grafici e circuiti. Va deciso, non subìto.

---

## Coda tua — il collaudo

I mondi sono cablati, verdi ed esportati: **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

È anche l'unico modo per giudicare le voci di questo piano che una misura non
raggiunge — G-10 per prima, e il ritmo di tutte le altre.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto (semi troppo espliciti)
   o non capisci cosa sia successo (troppo nascosti)? La taratura vale per tutti
   e sette i colpi: se sbaglia qui, sbaglia sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o sembra che ti
   aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta**: la senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

---

## Invarianti di architettura

- **La presentazione non calcola.** Nessuna scena o UI calcola mastery,
  ricompense, gate o completamenti: li legge da `runtime_state()`.
- **Il runtime non contiene testi.** Nessun dialogo, nome, battuta o beat è
  scritto dentro una scena: tutto viene dal catalogo.
- **I dati non decidono la resa** (niente posizioni sullo schermo nei cataloghi)
  **e la resa non decide i dati** (nessuna scena inventa registri o proprietari).
- **Nessuna immagine contiene testo**: non è traducibile, non è leggibile ad alto
  contrasto e non si corregge senza rigenerarla.
- Un cambio di contratto aggiorna fixture e consumer **nello stesso commit**.
- Nessun abitante scrive mastery, energia, gate o ricompense.
- **Prima il contenuto, poi il cricchetto.** Stringere una soglia prima di aver
  scritto il contenuto obbliga a scrivere contenuto per far passare un test.
  All'inverso: **nessun cricchetto si allenta mai.**

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tre materie** (italiano, matematica, inglese), **si
   finisce il gioco con dodici**. Il gate è sulla padronanza, non sul conteggio
   delle missioni.
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha missioni di tutte le
   materie già incontrate.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%** (oggi 17%).
7. **Gli stadi di relazione avanzano su ciò che Eli impara**, mai su oggetti o
   valuta. Lo stadio 2 non richiede l'esame.
8. **Qualità dei contenuti**: vero, non ambiguo, istruttivo, alla portata, vario,
   nuovo a ogni livello, fedele al registro della materia. Cinque criteri su
   sette hanno un cricchetto; «vero» e «alla portata» li può verificare solo una
   rilettura umana.
9. **Almeno 15 item per argomento** (3 agosto 2026). Sotto quella soglia il
   ripasso spaziato dichiara consolidato ciò che è solo memoria di una schermata.
   Tenuto da `topic_density_audit`.
10. **Ogni banco al 20–30% di risposta non a scelta multipla** (4 agosto 2026).
   Una domanda a quattro opzioni si risolve per esclusione senza sapere niente;
   scrivere «rifrazione» in un campo vuoto no. Due formati liberi: `numeric_input`
   per i numeri, `short_answer` per le parole — quest'ultimo accetta le varianti
   dichiarate in `accept`, perché segnare sbagliata una risposta giusta è il modo
   più veloce per far smettere di provare. Il tetto del 30% dice l'altra metà:
   oltre, il banco diventa un dettato, e le domande di ragionamento — dove la
   risposta è una frase — restano giustamente a scelta multipla.
   Tenuto da `free_answer_audit`.

11. **Da una prova si esce sempre, e uscire costa** (4 agosto 2026). Un difetto
   di input non deve poter diventare un blocco totale: su tablet è già successo.
   La porta chiede conferma a due tocchi e costa 3 energie — quanto l'ingresso —
   e l'energia della prova non consegnata non arriva: senza prezzo, uscire e
   rientrare sarebbe il modo più veloce di ripescare domande finché non capitano
   le facili. Con zero energia si esce lo stesso. Gli argomenti visti restano nel
   Codex: il gioco non toglie a nessuno quello che ha imparato.
   Tenuto da `exercise_exit_audit`.

12. **Il Custode avanza in carattere, mai in potere** (4 agosto 2026). Nessun
   aiuto, nessun indizio, nessuna energia, nessuno sconto sul gate. Nel momento
   in cui il compagno diventa utile il bambino comincia a ottimizzarlo, e un
   compagno ottimizzato non è più un compagno. Tenuto da `pet_advanced_audit`.
   Include il terzo errore: al terzo errore sullo stesso argomento nella
   sessione corrente il Custode starnutisce — non aiuta, e NORA non lo commenta,
   perché lei non commenta mai un errore. Tenuto da `pet_struggle_relief_audit`,
   che ha già preso un doppio difetto: `sneeze` mancava dal catalogo, e
   `set_blocked()` interrompeva qualunque combinella a ogni fotogramma in cui un
   pannello restava aperto, non solo alla transizione — quindi anche uno
   starnuto avviato durante una prova sarebbe morto un fotogramma dopo.
   Include la lettura del mondo: *curioso* su un incontro non esplorato,
   *attento* vicino a uno Sbiadito — atmosfera, non informazione: entrambi già
   visibili a schermo. `near_unexplored`/`near_faded` erano dichiarati dal
   primo giorno e mai emessi finché non sono stati agganciati. Tenuto da
   `pet_world_awareness_audit`.

13. **Il diario racconta, non giudica** (5 agosto 2026). Mostra giorni giocati,
   prove superate e cosa sai adesso; non mostra percentuali di errore, non mette
   le materie in classifica e non dà obiettivi. **I giorni giocati sono
   cumulativi e non scendono mai**, come il legame del Custode: una serie che si
   azzera è una minaccia sul domani, non un resoconto di ieri, e questo progetto
   ha già deciso che non punisce chi torna dopo tre giorni. `streak` resta nello
   schema e non si mostra. Tenuto da `diary_audit` e `diary_panel_audit`.

14. **Una chiave del salvataggio senza lettori è un errore** (5 agosto 2026).
   Lo stesso difetto si è ripetuto quattro volte: `gifts`, `daily`, `modules` e
   (fuori dal salvataggio) i segnali `near_unexplored`/`near_faded` erano
   dichiarati insieme al progetto e costruiti solo a metà. Sembravano vivi
   perché stavano nello schema, e tutto ciò che li nominava era coerente con se
   stesso. Ora `save_schema_audit` pretende che ogni chiave compaia in almeno un
   file di produzione fuori dalla dichiarazione: le fixture degli audit non
   contano — `modules` stava in sette audit e in zero righe di gioco.

15. **La potenza vale contro il Silenzio, mai contro una domanda** (13 agosto
   2026). È la regola che tiene insieme G-1, G-2 e G-4: serie, cariche d'impulso
   e moduli moltiplicano o aiutano sulla **mappa**, e non toccano mai mastery,
   copertura, ritenzione, gate o esami. Nel momento in cui una di queste tre
   sfiorasse una prova, il gioco comincerebbe a vendere l'apprendimento.
   Per la serie la tiene già `combo_audit`, e non con una rilettura del codice:
   registra due volte gli stessi esiti con energie diversissime e pretende la
   **stessa** padronanza e lo **stesso** conteggio di gate. Chi domani leggesse
   l'energia dentro il calcolo della padronanza lo troverebbe rosso lo stesso
   giorno.

### Guard-rail narrativi (i tre che si rompono per primi)

- **Non muore nessuno. Mai.** Né in scena, né fuori campo, né nel passato. Chi
  non c'è è *trattenuto dal Silenzio*: sospeso e recuperabile.
- **Niente blocca il loop.** Nessuna Traccia, dialogo o beat è obbligatorio per
  il gate. Le tre Tracce decisive (mondi 12, 16, 19) hanno un beat di ripiego.
- **L'errore non ha conseguenze narrative.** Nessuno è mai deluso da Eli.

---

## Vincoli

- Nessun nuovo banco composto quasi solo da scelta multipla.
- Nessuna scena `WorldScene` duplicata per livello.
- Nessun effetto della nave scollegato dalla progressione didattica.
- Nessuna valuta o ricompensa che permetta di saltare prove di competenza.
- Nessuna ulteriore profondità combinatoria: 33 milioni bastano.
- Le spiegazioni del **lessico** (inglese, italiano) restano come sono: lì
  rivedere l'accoppiata *è* il ripasso.
- **Nessuna voce di questo piano allunga la campagna.** 21,1 ore misurate: chi
  aggiunge qualcosa che costa tempo lo misura con `time_cost_probe` prima e dopo.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. La build è
   esportata e giocabile: da qui in poi questo rischio si chiude solo giocando,
   e ogni giorno che passa senza collaudo è lavoro fatto su un'ipotesi.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2789/3500 nodi e 311/500 ms. **Contare
   i nodi prima di aggiungerli**, non dopo. Vale in modo particolare per G-6: un
   ponte camminabile è una scena nuova, non un pannello.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con il 6%
   di margine. Un rosso va sempre riverificato in isolamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione,
   è una misura: la suite intera è passata da **105 a 1295 secondi** — dodici
   volte — con sei audit rossi, e un singolo audit da due secondi ne ha impiegati
   oltre quattrocento. Quattro processi Godot in contemporanea, tre non miei. I
   rossi erano tutti in audit che caricano scene, e nessuno toccava le cose
   cambiate: era contesa, non regressione.

   **Regola operativa**: chi sta per lanciare `npm run audit:godot` lo dice qui
   prima. Chi vede la suite andare oltre i ~150 secondi la ferma. Un audit
   singolo (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire —
   è il giro completo che va serializzato.
6. **C-16 passo 3 (rimozione di Phaser) resta sospeso.** Va fatto quando
   nient'altro è in volo, altrimenti una regressione somiglierà a un bug del
   mondo abitato.

---

## Rituale di export — cancello di ogni lotto

```powershell
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync     # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web    # verifica che i quattro valori combacino
npm run audit:godot
```

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
stai giudicando la build precedente.
