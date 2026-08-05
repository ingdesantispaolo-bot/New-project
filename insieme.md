# Eli Quest — Piano di lavoro

Aggiornato al 5 agosto 2026.

**Questo file contiene solo lavoro da fare.** Niente resoconti: quelli stanno nel
*Registro dei lavori* di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md).
Se una cosa è finita e verde, esce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
[Custode avanzato](docs/CUSTODE_LIVELLO_AVANZATO.md)

---

## Dove ci orientiamo — misurato il 5 agosto 2026

Tre direzioni possibili, e non si equivalgono. Le ho misurate invece di sceglierle
a intuito.

**Profondità degli esercizi — non è il collo di bottiglia.** Nell'esperienza
*giocata* (13 504 nodi su 24 mondi) la scelta multipla è all'**8%**, ogni materia
usa da 8 a 10 formati diversi, e le sessioni che ripropongono lo stesso argomento
nello stesso formato sono **0 su 3 648**. I banchi contano 3 472 item, almeno 15
per argomento, dal 20 al 30% a risposta libera. Qui il lavoro è fatto.

**Le spiegazioni — è qui il buco, ed è grosso.** I tre formati dominanti coprono
il **62% di tutto quello che un bambino gioca**, e nessuno dei tre spiega niente:

| formato | quota del giocato | cosa restituisce dopo la risposta |
|---|---:|---|
| abbinamento | 22% | «Collega ogni elemento a sinistra con quello giusto a destra» |
| ordinamento | 20% | «Ordine giusto: A, B, C» |
| classificazione | 20% | «Ogni tessera va nel gruppo giusto secondo la sua proprietà» |

Le prime e le terze sono **istruzioni**, identiche in ogni materia e in ogni
mondo. La seconda **ripete la risposta**. Nessuna dice un perché. In più, nei
banchi, **1 210 spiegazioni su 3 472 stanno sotto i 40 caratteri**, e 968 di
queste sono l'inglese, dove la spiegazione è tautologica: alla domanda «come si
dice *controllare*?» la spiegazione è «*check*: controllare».

Dove invece le spiegazioni sono state scritte a mano — grafici, circuiti,
notazione, carte — sono ottime: *«Il minimo si trova guardando chi sta più in
BASSO, non chi sta più a sinistra»*. È la prova che il problema non è la capacità
di scriverle: è che per tre formati su dieci non le ha mai scritte nessuno.

**Il divertimento — non si può ancora toccare.** Non esiste una misura, e
soprattutto **nessun bambino ha ancora giocato**. Qualunque modifica fatta adesso
sarebbe indovinare. È l'unica delle tre che richiede il collaudo *prima*, non
dopo.

### La scelta

**Prima le spiegazioni.** È il 62% del vissuto, è misurabile, è cricchettabile, ed
è il cuore della promessa didattica: un gioco che dice «giusto» e «sbagliato»
senza dire *perché* sta misurando, non insegnando. Il divertimento viene subito
dopo il tuo collaudo, con i dati veri in mano.

---

## Il piano — le spiegazioni

**Regola unica**: dopo la risposta il gioco dice *perché*, non *cosa fare*. Una
spiegazione che si potrebbe incollare identica su un altro esercizio non è una
spiegazione.

| Lotto | Cosa | Quanto | Stato |
|---|---|---:|---|
| **1** | I tre formati dominanti: ogni specifica dice perché quella è la risposta | **207** (79 abbinamento, 66 classificazione, 62 ordinamento) | **fatto** |
| **2** | Inglese: sostituire le spiegazioni tautologiche | 968 | **fatto** |
| **3** | Le spiegazioni circolari, misurate bene | 31 (non 242) | **fatto** |

Il lotto 1 è chiuso il 5 agosto 2026: **207 spiegazioni distinte**, nessuna sotto
i 40 caratteri, e `minigame_explanation_audit` verifica anche che arrivino ai
**nodi giocati** — una tabella perfetta che il costruttore ignora varrebbe quanto
una spiegazione assente. Tre specifiche avevano già una spiegazione propria,
migliore di quella che avevo scritto io: ho tenuto le loro.

Sul lotto 1 una cautela che mi porto dietro dal lavoro sui banchi: per il
vocabolario **non esiste un perché**. `dog`/`cane` è arbitrario, e inventare una
ragione sarebbe peggio del silenzio. Lì la spiegazione dice cosa hanno in comune
gli elementi di *quell'insieme* e cosa conviene notare — che è la cosa vera da
imparare quando la parola singola non ha logica.

**Il lotto 3 era mal misurato, e l'ho corretto scrivendolo.** Il piano contava
242 spiegazioni «sotto i 40 caratteri», ma la lunghezza era la metrica sbagliata:
la maggioranza di quelle corte era ottima — «Pro-nome: al posto del nome»,
«*Riso* è un cereale e anche una risata», «Sorge sulla Senna». Corte perché
precise. Allungarle le avrebbe peggiorate. Il difetto vero è **circolare**, non
corto: la spiegazione che ripete la domanda e la risposta senza aggiungere
niente. Misurate così erano **31**, ed è quelle che ho riscritto.

Due cricchetti, entrambi dopo il contenuto: `minigame_explanation_audit` per le
specifiche giocate, `bank_explanation_audit` per i banchi. Nessuno dei due misura
la lunghezza, per la ragione sopra: controllano che la spiegazione esista, che
non sia circolare e soprattutto che **nessuna singola frase copra più di venti
item** — una spiegazione buona per mezzo banco descrive il formato, non quel
banco.

---|---:|---:|---|---:|---:|
| inglese | 1109 | 30% | geografia | 199 | 20% |
| italiano | 587 | 22% | storia | 167 | 20% |
| matematica | 284 | 30% | elettronica | 159 | 20% |
| latino | 212 | 21% | fisica | 157 | 23% |
| coding | 195 | 30% | scienze | 155 | 21% |
| musica | 132 | 21% | logica | 116 | 29% |

**3472 item in totale**, nessun argomento sotto quindici, nessun banco fuori
forbice.

Quello che manca adesso non si scrive: **si gioca.** Nessun bambino ha mai
provato niente di tutto questo, e nessuna delle misure qui dentro dice se è
bello.

Le schede che seguono servono a due cose: verificare mondo per mondo che quello
che è cablato sia quello che era scritto, e riprendere in mano un mondo quando il
collaudo lo boccia.

---

## Le cose da guardare giocando

Le schede di cablaggio (artKit, landmark, cast, tic) sono uscite da qui il
5 agosto 2026: quel lavoro è fatto, è verde e lo tengono gli audit. Riscriverlo
in un piano di lavoro significava rileggere ogni volta istruzioni per qualcosa
di già costruito.

Resta quello che **solo giocando** si può giudicare. Sono i punti in cui una resa
sbagliata non rompe niente e toglie tutto il significato.

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

| | Claude | Tu |
|---|---|---|
| Tutto il codice, i contenuti e gli audit | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | ✅ |

Con un solo esecutore la revisione incrociata sparisce, e la sostituisce una
regola sola: **niente entra senza un audit che lo tenga.** Vale soprattutto per
il runtime, dove un errore non si vede rileggendo — il 3 agosto una sostituzione
in blocco ha invaso due costruttori che non c'entravano, e non me ne sono
accorto rileggendo il diff: me l'ha detto `minigame_audit`.

---

## Le altre voci aperte

Nessuna si scrive: vogliono un **asset** o una **tua decisione**.

- **Carta d'Europa e secondo foglio di reperti** — servono immagini nuove.
- **Accessibilità dei formati visuali** — le etichette identificano senza
  descrivere («Segnaposto A»), che è l'unica scelta che non regala la risposta.
  Ma chi usa un lettore di schermo **non può rispondere a una carta muta**. Vale
  già per grafici e circuiti. Va deciso, non subìto.

---

## Coda tua — il collaudo

I mondi sono cablati, verdi ed esportati: **gioca dall'inizio senza saltare
niente**. Non serve arrivare in fondo al primo giro: quello che cambia il lavoro
si vede nei primi sei mondi, e le ultime due domande si possono rimandare.

È anche l'unico modo per aprire la terza direzione: **il divertimento non si
misura da qui**, e finché non hai giocato qualunque modifica su quel fronte
sarebbe indovinare.

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

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. La build è
   esportata e giocabile: da qui in poi questo rischio si chiude solo giocando,
   e ogni giorno che passa senza collaudo è lavoro fatto su un'ipotesi.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta.
3. **Il mondo 1 è già stretto sui budget**: 2667/3500 nodi e 468/500 ms, ed è
   quello a cui stiamo per aggiungere abitanti ed edifici. **Contare i nodi prima
   di aggiungerli**, non dopo.
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
