# Eli Quest — Piano di lavoro

Aggiornato al **9 settembre 2026**. I numeri della tabella qui sotto sono stati
rimisurati oggi contro il repo, uno per uno; dove una misura è di un altro giorno
la riga lo dice. **Il giro completo della suite non è stato eseguito oggi**: sono
stati eseguiti i tredici audit elencati in *Lo stato misurato*, tutti verdi.

**Qui c'è solo lavoro da fare.** I lotti chiusi stanno nel *Registro dei lavori*
di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md), che copre tutto fino a
oggi. Se in questo file compare la descrizione di una cosa già fatta, è un
difetto del file: il consuntivo va nel registro e la voce sparisce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
[**Piano fasce e priorità**](docs/PIANO_OTTIMIZZAZIONE_FASCE.md) ·
[Custode avanzato](docs/CUSTODE_LIVELLO_AVANZATO.md) ·
[Minigiochi personaggi](docs/MINIGIOCHI_PERSONAGGI.md) ·
[Voce a 11 anni](docs/VOCE_11_ANNI.md)

---

## Come si tiene questo file

Serve a due cose: non dimenticare i punti in sospeso, e coordinarsi con Codex.
Cinque regole, e sono tutte state pagate almeno una volta.

- **Le voci `G-` sono di Claude** (contenuto, logica, guardie), **le `C-` di
  Codex** (resa, pannello, figure). Le due colonne non si bloccano a vicenda: una
  cosa dev'essere giocabile con forme piene e colori piatti *prima* che esista un
  disegno, altrimenti l'arte diventa un prerequisito e il lotto si ferma ad
  aspettarla.
- **Una voce si chiude quando ha una guardia.** Niente entra senza un audit che
  lo tenga. Con un solo esecutore per parte la revisione incrociata non esiste, e
  questa regola la sostituisce.
- **Chi chiude una voce la toglie da qui** e scrive il consuntivo nel registro,
  con le misure prima e dopo. Una sezione «storica» lasciata qui dentro è come
  una voce aperta per chi legge dopo.
- **Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto:
  stai giudicando la build precedente.
- **Chi sta per lanciare `npm run audit:godot` lo dice qui prima**, e chi vede la
  suite andare oltre i ~150 secondi la ferma (vedi *Rischi noti*, 5).

> **Fatto il 9 settembre 2026: `npm run audit:godot`, 9 rossi su 265 in 2004
> secondi.** Primo giro completo dopo il passaggio alle otto fasce; l'elenco e
> l'attribuzione stanno nella Fase 0 di
> [docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).
> **Sei dei nove sono stati chiusi in giornata**: `variety` (147 item nuovi),
> `nora_explanation_depth` e `nora_spiegazione_utile` (cinque voci mancanti),
> `explanation_coverage` (il distributore delle spiegazioni, non il contenuto),
> `ricette_per_fascia` (pavimenti rimisurati) e `audio_controls`, che era un
> falso rosso da contesa ed e' verde in isolamento. Restano `gesto` (R-18),
> `performance_budget` (R-17) e `glifi`, che appartiene al lavoro che Codex sta
> scrivendo adesso. **Il giro va rifatto quando Codex ha finito.**
>
> E una regola che vale per sé quanto per l'altro: **la suite non si esegue
> mentre si scrive.** Il primo tentativo è stato lanciato mentre modificavo
> `minigame_manager.gd`, e metà degli audit ha letto il file vecchio: risultato
> buttato, mezz'ora di macchina persa.

> **Fatto l'11 settembre 2026 · Claude: `npm run audit:godot`, 280 verdi su 280
> in 1101 secondi**, e **export web eseguito** nello stesso stato dell'albero.
> Il giro era stato ripetuto quattro volte durante la giornata; i cinque rossi
> dei giri intermedi appartenevano tutti al lavoro che Codex stava scrivendo in
> quel momento (`subject_signature`, `minigame_topic_scope`, `minigame`,
> `pratica_perimetro`, `content_depth`) e si sono chiusi da soli quando ha finito.
>
> **Due lezioni sulla concorrenza, pagate oggi.** La prima: due processi Godot
> sullo stesso progetto bastano a produrre rossi falsi — un giro ha dato 2 su 278
> solo perché lanciavo singoli audit mentre girava, ed erano verdi entrambi
> rifatti da soli. Un rosso raccolto in concorrenza non vale finché non è stato
> rifatto in isolamento. La seconda: `build-exercise-banks.mjs` è l'unico file in
> cui le due corsie si toccano davvero, perché entrambe ci agganciano lotti nuovi.
> Chi lo modifica controlli che i sorgenti che importa esistano.
>
> **Lavoro chiuso nella giornata — la regola delle dispense**
> ([docs/REGOLA_DISPENSE.md](docs/REGOLA_DISPENSE.md)), su richiesta del
> committente: nessuna domanda senza un documento che la insegni. Cinque materie
> convertite su dodici — coding, storia, geografia, latino, scienze — con **97
> dispense** (media 3.196 caratteri contro i 290 con cui NORA spiegava, misurati
> su tutti e 300 gli argomenti del runtime) e **303 item nuovi** che dichiarano
> la dispensa che applicano. Restano elettronica, musica, logica, fisica,
> matematica, italiano e inglese: il registro del debito, con il tetto per
> materia che si abbassa e mai si alza, sta in `dispense_audit.gd`.

---

## Lo stato misurato — 9 settembre 2026

| | valore | dove si rimisura |
|---|---|---|
| audit Godot presenti | **261** file `*_audit.gd` (erano 251 il 6 settembre) | `find godot -name '*_audit.gd'` |
| **giro completo** | **2 non verdi su 277** (846 s): restano solo R-17 (metro) e `glifi` (Codex) | `npm run audit:godot` |
| item nei dodici banchi | **5242** (erano 5154) | `godot/data/banks/*.json` |
| di cui il nucleo | inglese **1466**, matematica **944**, italiano **780**, coding **306** = **3496**, il **66,7%** del banco | idem |
| formati nei banchi | **6**: scelta multipla 3855, risposta libera 1322, e da oggi **ordering 27, classification 19, matching 19** | `sessioni-lunghe-programma.mjs` |
| argomenti distinti nel banco | **198** — matematica **34** (erano 25), inglese **47**, italiano **30** | `topic_density_audit` |
| fasce di difficoltà | **8**, tre mondi ciascuna; i 24 livelli restano per formati e scaffolding | `difficulty_bands_audit` |
| fasce di priorità del curricolo | **50 / 35 / 15** su 4+4+4 materie, ±5 punti; sessione **6/4/2** esercizi | `subject_priority_audit` |
| voci di NORA | **294** (erano 261) — nucleo 135, cioè il 46% | `nora_explanations.gd` |
| export Web | **verde**, `2026.09.09-web-loader-1`: la build spedita è HEAD | `npm run audit:web` |
| PCK esportato | **80,27 MiB** (`index.pck`) + **14,60 MiB** differito (`content.pck`) + 37,68 di WASM | `public/godot/outdoor/` |
| pacchetto completo su disco | **133 MB** | idem |
| materie allenabili all'arrivo | **12/12 in tutti e 24 i mondi** | `materie_raggiungibili_audit` |
| mondo 1: nodi e avvio | **2553** nodi (era 2511) e **546–691 / 500 ms** — **ROSSO**, vedi R-17 | `performance_budget_audit` |
| «tocca una fra N» nell'esame | **70,0% «manipola» su tutte e dodici**; «sceglie» 20,7%–26,1%, media ≈23,7% (era 34,4%) | `gesto_audit` |
| «tocca una fra N» nel mondo | undici materie sotto il tetto, **italiano al 26,0% contro 22,3%** — **ROSSO**, vedi R-18 | idem |
| campagna | **21,3 ore** · mondo più corto 30,1 min, più lungo 69,4 min | `time_cost_probe` — **misura del 4 settembre, non rimisurata** |
| ricette `compose` | **18** su sei materie | `format_depth_audit` — misura del 4 settembre |
| item con la fascia scelta da un autore | **1695 su 4854**: il 65,1% l'ha presa dal ponte automatico 4→8 | vedi G-C12 |

> **I tredici audit eseguiti oggi, uno per uno.** Verdi: `difficulty_bands`,
> `subject_priority`, `italian_minigame_bands`, `world_difficulty_curve`,
> `topic_density`, `difficolta_per_materia`, `difficulty_calibration`,
> `adaptive`, `free_answer`, `c11_world_content`, `materie_raggiungibili`, più
> `audit:web`. **Rossi: `performance_budget` e `gesto`** — R-17 e R-18.
>
> Il giro completo (`npm run audit:godot`) **non** è stato lanciato: dieci audit
> nuovi sono entrati dal 6 settembre e nessuno ha ancora misurato la suite intera
> dopo il passaggio alle otto fasce. Finché non lo si fa, «251 verdi su 251» è un
> numero di cinque giorni fa su un albero diverso — e due rossi trovati
> assaggiando tredici audit su duecentosessantuno suggeriscono che il giro
> completo vada fatto prima di qualunque altra cosa.

> **Due lotti sono entrati senza consuntivo.** Le otto fasce (9 settembre) e le
> fasce di priorità 50/35/15 (8 settembre) hanno cambiato la Decisione 3 e la
> Decisione 16 — cioè due decisioni vincolanti — e **nel Registro dei lavori non
> c'è la loro riga**. Questo file le ha inseguite oggi, cinque giorni dopo, e nel
> frattempo ha continuato a descrivere quattro bande che non esistevano più.
> Chi ha chiuso i due lotti scriva il consuntivo con le misure prima e dopo: la
> regola non è burocrazia, è ciò che ha evitato che questa ricognizione durasse
> mezza giornata invece che un'ora.

> **Il numero da guardare è il PCK.** Ancora cresciuto, da 79,10 a **80,27 MiB**,
> e di nuovo senza che un lotto lo dichiarasse — mentre la regola dice che ogni
> atlante si dichiara in MB *prima* di essere generato. La domanda non è quanto
> pesa: è quanto pesa il primo caricamento su una rete di scuola.

---

## Rosso adesso — prima di ogni altra cosa

> **Stato al 9 settembre 2026: due rossi aperti, R-17 e R-18.** Le voci
> R-1…R-16 restano chiuse.
>
> Il 6 settembre la suite era verde su 251 audit, per la prima volta. **Quel
> verde non vale più per l'albero di oggi**: dal 6 settembre sono entrati dieci
> audit nuovi e — soprattutto — la scala di difficoltà è passata da quattro bande
> a otto fasce, che è il parametro su cui pesca ogni selezione di ogni materia.
> Riassaggiando tredici audit ne sono usciti due rossi: **il giro completo va
> fatto prima di qualunque altra cosa**, e costa dieci minuti di macchina ferma.
>
> **Il debito sospeso di R-2 si è chiuso da solo, ed è la cosa migliore
> successa questa settimana.** `storia / esame` era al 35,8% con la soglia
> allentata a 36,0 per decisione del committente: un debito non pagato, solo
> spostato. Rimisurato oggi sta al **24,7%**, e non perché la soglia sia stata
> toccata ancora — perché l'esame è stato ricostruito sulle fasce di priorità.
> Vedi R-18 per la tabella.
>
> Resta però il dettaglio del metro, e adesso conta di più di prima: con
> `TOLLERANZA_ESAME` a 3,0 punti e un rumore misurato di 0,6, la tolleranza è
> cinque volte più larga del necessario — e i tetti dell'esame hanno ora fino a
> quarantun punti d'aria sopra il valore reale. **Vanno riabbassati tutti**: un
> cricchetto che nessuno sfiora non trattiene niente.
>
> La suite è passata da 242/244 a **243/244**, e da 738 a **572 secondi**: i
> quattro minuti risparmiati sono l'audit che non resta più appeso a un `assert`
> fallito (vedi *Rischi noti*, 6).

### R-17 · L'avvio del mondo 1 ha sfondato il budget — aperta il 9 settembre 2026

`performance_budget_audit` è **rosso**. Misurato due volte in isolamento, a
macchina scarica, e i numeri stanno insieme:

| mondo | 4 settembre | oggi, 1ª misura | oggi, 2ª misura | nodi oggi |
|---|---:|---:|---:|---:|
| **1** | 392 ms | **691 ms** | **546 ms** | 2553 |
| 7 | — | 328 ms | 324 ms | 2013 |
| 13 | — | 325 ms | 331 ms | 2235 |
| 19 | — | 364 ms | 385 ms | 2277 |
| 24 | — | 420 ms | 420 ms | 2133 |

**Non è la macchina, ed è dimostrabile con questa stessa tabella.** Gli altri
quattro mondi ripetono se stessi entro venti millisecondi: se fosse carico,
ballerebbero anche loro. Balla solo il primo, e anche il suo minimo — 546 ms —
sta sopra il budget di 500.

E non sono i nodi: erano 2511, sono **2553**, quarantadue in più.

**Poi ho misurato invece di dedurre, e la diagnosi era sbagliata.**
`avvio_mondo1_probe.gd` istanzia lo stesso mondo 1 quattro volte di seguito:

    giro 0 · mondo  1 ·  759 ms · 2478 nodi
    giro 1 · mondo  1 ·  294 ms · 2478 nodi
    giro 2 · mondo  1 ·  298 ms · 2478 nodi
    giro 3 · mondo  1 ·  308 ms · 2478 nodi
    giro 0 · mondo 13 ·  427 ms      giro 1 · mondo 13 ·  291 ms

**Il mondo 1 a caldo costa 294 ms, cioè il 59% del budget, ed è più leggero del
mondo 13.** Non è pesante: è **primo**, e paga da solo la compilazione degli
script e il primo caricamento delle risorse. È esattamente ciò che era già stato
misurato l'8 settembre (3157 ms al primo giro, 412 al secondo) e che nessuno ha
poi applicato a questo rosso.

Anche il candidato che avevo indicato è escluso, misurato:
`costo_banchi_probe.gd` dice che leggere e interpretare tutti e dodici i banchi
costa **179,7 ms in lettura grezza e 91,8 ms** attraverso `ContentManager` — e la
crescita da 4061 a 4854 item ne spiega al massimo una quindicina. Non sono i
banchi.

**Che cosa fare, quindi.** Non togliere prop al mondo 1: sarebbe lavoro sprecato
che per giunta lo impoverisce, e il grafo di scena non è cambiato. Le due strade
vere:

- **cambiare il metro**: un'istanza di riscaldamento non cronometrata prima della
  misura, così `performance_budget_audit` misura il mondo e non l'avvio del
  motore. È una guardia, quindi la decisione è di Paolo — ma va detto che oggi
  quell'audit **non misura ciò che dichiara di misurare**;
- **tenere il metro e prendersi il numero sul serio**: 759 ms al primo mondo è
  anche ciò che vive il bambino la prima volta che apre il gioco. In quel caso il
  bersaglio non è la scena ma **quanto codice e quante risorse si compilano al
  primo mondo**, ed è lì che va cercato il mezzo secondo.

Le due strade non si escludono: la prima rende onesto l'audit, la seconda misura
una cosa vera che oggi nessuna guardia sorveglia.

### R-18 · Italiano crocetta troppo — **chiusa il 9 settembre 2026**

`gesto_audit` è **rosso**, e per la prima volta il rosso non è nell'esame:
**`italiano / mondo` al 26,0% di «sceglie» contro un tetto di 22,3%.** Le altre
undici materie del mondo stanno sotto.

> **CHIUSA.** Italiano e' passato da **26,6% a 20,5%** e `gesto_audit` e' verde
> per la prima volta. La causa non era nessuna delle due ipotesi tentate: era
> che il catalogo dell'italiano aveva **quattro sfide `compose` nelle fasce 1 e
> 5** — esattamente i mondi 2 e 14, gli unici in cui italiano e' materia del
> mondo — e `build_minigame` mette una campata calibrata in ogni sessione.
> Quindi ogni sessione conteneva una `compose` garantita, e `compose` conta fra
> i «sceglie». Misurato: era il 14,6% dei nodi al mondo 2 e il 17,0% al 14, piu'
> della scelta multipla stessa. Quattro opzioni manipolative aggiunte a quelle
> due fasce, e il numero e' sceso di sei punti.
>
> **La lezione: un numero aggregato non dice mai da dove viene.** Scomporlo per
> origine ha mostrato che la pratica e' il 70,5% dei nodi; scomporlo per
> **formato** ha mostrato il colpevole in una riga. Vedi
> [docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).

**Attenzione: la causa che segue è stata SMENTITA dalla misura.** Resta scritta
perché è un errore che costa poco rifare. Undici ricette nuove per italiano hanno
lasciato il numero a 26,0% e poi a 26,3%: dentro il rumore. La spiegazione e la
leva vera stanno nella Fase 1 di
[docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md) — in
due parole: **italiano è materia del mondo solo ai mondi 2 e 14**, e la pratica
sceglie il formato **per peso, non per numero di ricette**. Il prossimo tentativo
va fatto su `NONMC_FORMAT_WEIGHTS`, non sul contenuto.

L'ipotesi smentita era questa (censimento del 9 settembre,
`censimento_fasce_probe.gd`). Italiano è la materia di prima fascia con **meno
ricette di minigioco di tutte**, e serve **sei esercizi per sessione**: la
domanda in più va per forza a pescare nel banco, che è il posto dove la crocetta
vive.

| materia di prima fascia | ricette totali | ricette nuove da F5 a F8 | «sceglie» nel mondo |
|---|---:|---:|---:|
| inglese | **128** | 21 · 15 · 8 · 10 | 21,2% |
| matematica | **84** | 8 · 3 · 7 · 2 | 21,8% |
| **italiano** | **54** | **1 · 1 · 1 · 0** | **26,0%** ← rosso |

Italiano ha metà delle ricette dell'inglese e **smette di crescere a metà
campagna**: dalla fascia 5 in poi sblocca una ricetta per fascia, poi zero. Tre
punti non fanno una dimostrazione, ma vanno nella stessa direzione e la causa
meccanica è chiara: a parità di sessione, meno ricette significa più banco.

La riparazione quindi non è alzare il tetto: è **dare a italiano ricette di
minigioco nelle fasce alte**. `italian_minigame_catalog.gd` esiste dall'8
settembre, copre tutte e otto le fasce ma con **due sfide ciascuna, sedici in
tutto**, e `build_minigame` ne mette **una sola per sessione** — le altre cinque
domande vengono da altrove. È il posto giusto dove aggiungerne, ed è lo stesso
lavoro fatto per l'inglese (vedi G-C4).

**E la notizia buona, che va scritta perché ribalta G-C2 e R-2.** L'esame di fine
mondo, che era il problema dichiarato, oggi è sano su tutte e dodici le materie:

| | 4 settembre | 9 settembre |
|---|---:|---:|
| «manipola» nell'esame | non uniforme | **70,0% su tutte e dodici** |
| «sceglie» nell'esame, media | **34,4%** | **≈23,7%** |
| elettronica / esame | **63,0%** | **21,9%** (tetto 63,0) |
| storia / esame — il rosso di R-2 | **35,8%** (tetto 36,0) | **24,7%** (tetto 36,0) |

**Il debito «sospeso» di R-2 non è più sospeso: è pagato**, e non da un
allentamento — dalla riscrittura dell'esame per fasce di priorità. Ma i tetti
sono rimasti dov'erano, e adesso sono larghissimi: elettronica ha 41 punti di
aria, storia 11. **Un tetto che nessuno sfiora non è un cricchetto**: vanno
riabbassati sui valori di oggi, con il margine del rumore misurato (0,6 punti) e
non con la vecchia `TOLLERANZA_ESAME` di 3,0, che era già cinque volte più larga
del necessario.

### R-16 · Il tasto per il menu principale c'era e non si trovava — chiusa il 6 settembre 2026

*Segnalazione: «non vedo il tasto per tornare al menu principale dove cambiare
personaggio o riavviare il livello».*

**Il tasto c'era, ed era PAUSA.** Misurato aprendo il mondo e stampando la
colonna in alto a destra: sette pulsanti, tutti visibili e a piena opacità, e
dietro PAUSA ci sono da tre settimane esattamente le tre cose cercate —
**RIPARTI DAL PORTALE · CAMBIA GIOCATORE · MENU PRINCIPALE** — più RIPRENDI,
VOLUME e SUONO.

Quindi non è un difetto di codice: è un difetto di **nome**. «PAUSA» racconta il
gesto — fermarsi — e non la destinazione. Chi cerca il menu principale cerca la
parola «menu», e quella parola non compariva da nessuna parte sullo schermo.

La cosa è più seria di come suona, per due motivi. Il primo: il 21 agosto il
pulsante della nave che diceva **MENU PRINCIPALE** è stato sostituito da PAUSA,
perché dietro sono state messe tre azioni invece di una — un miglioramento vero,
che però ha tolto proprio la parola che la gente cercava. Il secondo, e vale più
del primo: **se non l'ha trovato chi il gioco l'ha commissionato, un bambino non
lo trova di sicuro.**

Adesso, nel mondo e sulla nave, il pulsante dice **PAUSA · MENU**: il gesto e la
destinazione. `pause_menu_audit` non controlla più il testo esatto ma la
sostanza — il pulsante che porta al menu deve nominare il menu — in entrambe le
scene.

### R-15 · La consegna rinviata poteva perdersi — chiusa il 6 settembre 2026

*Quarta segnalazione sullo stesso gesto: «ho riprovato ancora ma ho ancora blocco
dopo aver premuto avanti dopo risposta corretta». La schermata questa volta non
lascia scampo.*

Nodo risolto, «Funziona! +15 energia · serie ×1,5», la spiegazione di NORA
scritta sotto, il tastierino e CONFERMA spariti **come devono** — le correzioni
di R-13 e R-14 hanno preso — e AVANTI in fondo alla barra. Premendolo non
succede niente.

Con quella schermata la strada si restringe a una sola: **la chiusura era già
stata chiesta e non è arrivata.** Nella build Web la chiusura è rinviata di un
fotogramma (`call_deferred`, per lasciare che il browser concluda il gesto prima
di salvataggio e segnali), e fino a oggi `_advance()` tornava indietro in
silenzio quando una chiusura era in coda:

```gdscript
if _completion_queued or _session_closed:
    return
```

Se quel fotogramma non arriva, **ogni pressione successiva di AVANTI è un
no-op**, e per di più il pulsante veniva spento subito: nessun secondo tocco era
nemmeno possibile. In headless non si riproduce — lì la chiusura è immediata — ed
è esattamente per questo che tre giri di verifica non l'hanno vista.

**Tre correzioni, ognuna sufficiente da sola.**

1. **Il secondo tocco non vale meno del primo.** Se la chiusura è in coda e non è
   ancora arrivata, AVANTI la esegue **subito, sul posto**. `_finish()` si protegge
   da sé: si esegue una volta sola comunque.
2. **AVANTI non si spegne più** dopo la richiesta: restava spento in attesa di una
   consegna che poteva non arrivare, cioè morto.
3. **Una rete di sicurezza a mezzo secondo**: se la consegna rinviata non è
   arrivata, la chiusura si fa comunque. Quando tutto va bene trova la sessione
   già chiusa e non fa niente.

**E niente sta più fra il tocco e la chiusura.** In `_finish()` il segnale di
fine veniva emesso **dopo** il nodo audio nativo e una `JavaScriptBridge.eval`:
due cose che possono fallire fuori dal nostro controllo, e che se si fossero
fermate avrebbero lasciato `_session_closed` acceso e la prova aperta per sempre.
Ora si consegna prima; suono e pulizia del DOM sono conseguenze e vengono dopo.

**La guardia** simula il caso esatto — chiusura in coda, sessione ancora aperta —
e pretende che il secondo AVANTI chiuda. Provata togliendo la correzione:
*«chiusura in coda e mai arrivata, il secondo AVANTI non chiude la prova»*;
rimessa: verde.

### R-14 · PROVA restava acceso, e la scheda regalava la risposta — chiusa il 6 settembre 2026

*Segnalazione con tre schermate: «rispondendo correttamente alla terza tappa per
recuperare la torcia, premendo invio si blocca».*

Le schermate mostrano tre difetti diversi, e il primo è il blocco.

**1 · ANNULLA e PROVA restavano accesi dopo la risposta.** È il gemello esatto di
R-13, con un altro pulsante. Su un minigioco — grafico, ordinamento, smistamento
— i due comandi vivono nella **barra**, non dentro `_options`, quindi
`_disable_buttons(_options)` non li toccava. Nella terza schermata si vede tutto:
nodo risolto, «Funziona! +13 energia · serie ×1,25» scritto sotto, e **PROVA
ancora verde e grande sopra un AVANTI scuro e discreto**. Il dito va sul pulsante
che sembra il principale; quello rientra in `_score_current`, che esce subito
perché il nodo è già chiuso, e non succede niente.

Adesso, chiuso il nodo, la riga ANNULLA/PROVA se ne va con il tastierino e con
CONFERMA. Restano SPIEGA CON NORA e AVANTI. In più il campo di testo rilascia il
fuoco: se il browser aveva aperto la tastiera di sistema, quella copriva proprio
la zona di AVANTI.

**2 · Mille pixel di nero fra la domanda e i comandi.** Nella seconda schermata —
telefono in verticale — il riquadro andava dal 4% al 96% dello schermo mentre il
contenuto ne occupava un quarto: fra l'ultima riga e i pulsanti c'era il vuoto, e
AVANTI finiva a un palmo di distanza da dove il bambino stava guardando. Le
risposte libere ora usano la forma **compatta**, come la scelta multipla: il
riquadro si ferma al 74%.

**3 · La scheda di NORA regalava la risposta.** Davanti a *«Quale numero completa
6 × ? = 36?»* si apriva la scheda con scritto, sotto **FATTI NUOVI IN QUESTA
PROVA**, «• 6». La risposta, un secondo prima della domanda, e niente da
imparare.

L'intenzione era già scritta dentro `recall_fact` — *«restituisce {} quando la
domanda chiede di ragionare invece che di ricordare: quella risposta non va
anticipata»* — ma l'unico controllo era il numero di parole, e **un numero è
sempre una parola sola**: passava sempre. La regola che distingue davvero le due
cose è un'altra: un nome da ricordare ha delle **lettere** (Oslo, accusativo,
conduttore), il risultato di un conto no (6, 42, 0,25, 3/4). I nomi veri
continuano ad arrivare prima della domanda — è il regalo del 31 agosto, e la
guardia verifica anche quello.

**Tre guardie nuove**, tutte provate togliendo la correzione e vedendole
diventare rosse: `exercise_reachability_audit` ora gioca il nodo e pretende che
ANNULLA/PROVA e CONFERMA spariscano quando è chiuso;
`fact_level_teaching_audit` pretende che sei risposte da calcolare non vengano
anticipate e che quattro nomi veri lo restino.

### R-13 · CONFERMA era visibile e morto — chiusa il 6 settembre 2026

*Segnalazione, con schermata: «ho risposto 5, premuto conferma e avanti, e il
programma si blocca». Nella schermata: Tappa 3/3, il 5 scritto nel campo, il
tastierino ancora acceso, CONFERMA grigio.*

**Non era il riquadro, non era la scheda di NORA, e non era il ritentativo di
R-12.** `_lock_interactions()` spegne CONFERMA quando un nodo si chiude — giusto
— e `_show_current()` lo rimetteva visibile **senza riaccenderlo**. Dalla
**seconda risposta libera in avanti** il pulsante c'era, si vedeva, e non faceva
niente. L'unica consegna rimasta era l'OK del tastierino: è lo stesso gesto, ma
nessuno lo ha mai detto al bambino.

Una riga sola, `_input_submit.disabled = false`, mancante da sempre.

**E la schermata mostrava anche perché sembrava un blocco e non un pulsante
rotto.** Dopo aver risposto:

- il tastierino restava acceso, con il numero ancora scritto;
- CONFERMA restava lì, solo un po' più grigio;
- **l'esito di NORA nasceva sotto il tastierino e sotto INDIZIO**, cioè fuori
  dallo schermo finché non si scorreva.

Il bambino non aveva **nessun segno visibile** che la sua risposta fosse
arrivata: il dito tornava dov'era un attimo prima, su CONFERMA, e non succedeva
niente. Adesso, chiuso il nodo, tastierino, CONFERMA e INDIZIO **spariscono**
invece di restare spenti, e la colonna si porta da sola sull'esito.

**La guardia c'era e guardava la schermata iniziale.**
`exercise_reachability_audit` verificava che CONFERMA fosse nella barra fissa,
non che funzionasse al secondo nodo: guardava la prova, non la giocava. Ora
gioca il primo nodo per davvero e controlla il secondo. Provata togliendo la
riga: *«al secondo nodo CONFERMA è visibile=true e spento=true — si scrive la
risposta e non si consegna»*; rimessa: verde.

### R-12 · «Rispondo e si blocca, vedo ancora la domanda, 3/3» — chiusa il 6 settembre 2026

*Segnalazione: «sia per la torcia in una partita nuova sia per la falce nella
partita vecchia, dopo aver risposto alle domande il programma si blocca, si vede
ancora domanda, vedo 3/3».*

**Quarta segnalazione della stessa famiglia, e la prima con questa causa.** Le
tre precedenti riguardavano il riquadro e la scheda di NORA — il contenuto che
non scorreva (8 agosto), i comandi che scorrevano via (15 agosto), la scheda che
si mangiava i tocchi (5 settembre). Nessuna delle tre era questa, ed è il motivo
per cui il difetto è sopravvissuto a tutte e tre.

**La causa, riprodotta giocando davvero le minimissioni della torcia e della
falce su sette schermi.** Basta **una risposta sbagliata** su uno dei nove
formati che si possono ritentare — ordinamento, smistamento, grafico, percorso
della macchina, ciclo, griglia, porte, decodifica, debug — e il nodo resta
aperto:

- AVANTI non compare, perché il nodo non è chiuso;
- l'unica uscita è **azzeccarlo**, o sbagliarlo tante volte quanti sono gli
  scudi rimasti.

Per chi gioca è indistinguibile da un blocco: la domanda è ancora lì, il
contatore dice ancora 3/3, nessun comando porta avanti. La riga «puoi spostarle e
riprovare» c'era, ma è testo in mezzo a una schermata piena.

**E contraddiceva un guard-rail scritto**: *niente blocca il ciclo*. Uno stato la
cui unica uscita è la risposta giusta è esattamente ciò che quel guard-rail
vieta, e colpisce più duramente proprio il bambino che non sa rispondere — cioè
quello per cui il guard-rail esiste.

**La cura non toglie il ritentativo**, che è la parte didattica buona: aggiunge
la seconda porta e la rende visibile. Dopo un errore compare **«NON CI RIESCO»**
accanto ad ANNULLA e VERIFICA: chiude il nodo come sbagliato, NORA spiega, la
prova continua. Costa quanto sbagliare — lo scudo è già stato speso — quindi non
è una scorciatoia: dice ad alta voce quello che stava succedendo comunque.

**La guardia esisteva e non guardava.** `nodo_senza_uscita_audit`, scritto il 5
settembre proprio per questa famiglia, **rispondeva sempre correttamente**: il
modo più facile di non vedere un difetto che si manifesta solo sbagliando. Ora
alterna giusto e sbagliato e pretende che dopo ogni tentativo esista una via
d'uscita visibile che chiuda davvero il nodo. Provata togliendo la correzione:
rossa; rimessa: verde.

### R-4 · Cinque materie su dodici chiuse dalla falce, al mondo 2 — chiusa

> **Chiusa il 4 settembre 2026.** Le palestre non portano più varchi. La misura
> che l'ha trovata è diventata una guardia, `materie_raggiungibili_audit`, e su
> **tutti e ventiquattro i mondi** dà adesso 12/12 — nessun blocco simile altrove.
>
> | mondo | prima | dopo |
> |---:|---:|---:|
> | 2 | 7/12 | **12/12** |
> | 5 | 7/12 | **12/12** |
> | 7 | 9/12 | **12/12** |
> | 11 | 11/12 | **12/12** |
> | gli altri venti | 12/12 | 12/12 |
>
> **La misura che ha deciso la forma della correzione.** Contando i nodi per
> materia: in ogni mondo la materia in focus ne ha **sette** (missioni, enigmi,
> minimissione) e **le altre undici ne hanno uno solo, la loro palestra**. Non
> esiste quindi una palestra che si possa chiudere senza chiudere la sua materia,
> né con una chiave futura né con quella del mondo corrente. La prima versione
> della correzione — «chiudi solo le palestre la cui materia ha un altro nodo» —
> non chiudeva più niente, ed è stata la prova che la regola giusta è più
> semplice: **niente varchi sulle palestre.** Le porte restano sui forzieri, che
> è dove il progetto ha sempre detto che stanno.
>
> **Una guardia che presumeva il difetto.** `equipment_traversal_audit`
> *pretendeva* che al mondo 2 esistesse una palestra chiusa da uno strumento — la
> meccanica giusta provata sul nodo sbagliato. Ora gira su un forziere, e ha una
> riga in più che prima mancava: nessun varco su una palestra.
>
> Provata prima di fidarsene: eseguita sul codice di ieri,
> `materie_raggiungibili_audit` è **rossa sui quattro mondi giusti**, con i nomi
> esatti delle materie murate.

<details>
<summary>La diagnosi</summary>

*Segnalazione di gioco: «al livello 2 non riesco a recuperare la falcetta per
completare il livello».* **Ha ragione, ed è un blocco vero.**

Misurato aprendo il mondo con gli attrezzi che uno studente ha davvero
all'arrivo — la sola torcia:

| mondo | chiave | materie allenabili prima della chiave | materie chiuse dalla chiave |
|---:|---|---:|---|
| **2** | Falce | **7/12** | coding, elettronica, matematica, musica, storia |
| **5** | Leva | **7/12** | coding, geografia, italiano, scienze, storia |
| 7 | Lente | 9/12 | fisica, inglese, logica |
| 11 | Soffietto | 11/12 | inglese |

Il gate chiede **tutte e dodici** le materie. Quindi finché la falce non arriva,
il mondo 2 non si chiude — non è una deviazione, è il livello.

**La buona notizia:** non è un vicolo cieco. L'incarico che consegna la chiave è
presente e **raggiungibile senza la chiave** in tutti e quattro i mondi, la
bussola ci porta e il cartello del varco dice già dove si prende. Chi fa la
riparazione per prima cosa non si accorge di niente. Chi gira il mondo prima
trova cinque materie murate e un quadro obiettivi che ne chiede dodici.

**Dove nasce.** [outdoor_world.gd:1914](godot/scripts/outdoor_world.gd#L1914):
dal mondo 2 in poi **ogni** palestra riceve un `requiredTool`, pescato per hash
fra le chiavi già consegnabili nel mondo. Al mondo 2 quelle chiavi sono torcia e
falce, quindi circa metà delle palestre nasce chiusa. Il commento lì accanto
dichiara l'intenzione opposta — *«Solo deviazioni opzionali: nessuno strumento
può bloccare il gate»* — e più sotto spiega di aver escluso le chiavi **future**
per non togliere «l'unico posto in cui allena quella materia in questo mondo».
È il ragionamento giusto applicato a metà: le palestre sono una per materia,
quindi anche la chiave **di questo mondo** toglie quell'unico posto, finché non
arriva.

**Perché nessuna guardia l'ha preso.** `tool_verticality_audit` controlla due
cose diverse: che nessun evento con `countsForGate` sia dietro una chiave, e che
nessuna palestra sia dietro una chiave **futura**. La copertura delle dodici
materie non passa da `countsForGate` — si calcola sulle materie allenate — e la
falce al mondo 2 non è una chiave futura. Il buco ha esattamente la forma della
segnalazione.

**Il vincolo che rendeva la correzione non ovvia.**
`equipment_traversal_audit` pretendeva che al mondo 2 esistesse una palestra
chiusa da uno strumento (*«manca una deviazione opzionale legata
all'equipaggiamento»*), quindi togliere il varco dalle palestre lo faceva
arrossire — una guardia che presumeva il difetto. Risolto spostando quella prova
sui forzieri, che è dove le porte stanno per progetto.

</details>

### R-11 · L'esplorazione non insegnava niente — chiusa il 5 settembre 2026

*Richiesta: dare più valore alla mappa, «la tavola trovata in una rovina, il
paradigma latino in un archivio», su tutti e 24 i mondi.*

**Non serviva costruire niente di nuovo — esisteva già, in due pezzi tenuti
separati.** Ogni mondo ha già un grande landmark illustrato, sempre visibile,
con un'interazione già cablata (`HeroLandmarkInteraction`). E il gioco sa già
disegnare quattordici famiglie di tavole a costo zero — `NoraFigura`, righe di
`_draw()`, zero megabyte — finora usate solo dentro le prove. Bastava smettere
di tenerle separate: la stessa tavola che spiega un esercizio la si trova prima,
esplorando.

**Rispettata la regola già scritta il 27 agosto**: dove non c'è niente da
estrarre con certezza non si disegna. Fisica e scienze restano senza figura ai
loro quattro landmark (mondi 5, 10, 17, 22) — non una dimenticanza, la stessa
scelta già presa per le prove.

Ventiquattro voci, una per mondo, ciascuna con: che cosa si vede avvicinandosi
(due frasi, concrete, come i lasciti dei forzieri) e una riga sola che fa notare
un dettaglio, mai una spiegazione. Qualche esempio:

> *Mondo 1, l'Obelisco dei Numeri* — «La pietra è incisa a tacche. Le prime file
> sono fitte, una tacca alla volta; poi qualcuno ha ricominciato, raggruppandole
> a dieci a dieci.» → **la griglia dei gruppi**, la stessa che accompagna ogni
> tabellina da lì in avanti.
>
> *Mondo 19, l'Albero delle Radici* — «"Verbum" e "verbo" condividono le prime
> quattro lettere: la radice non si è mai mossa in duemila anni.» → **la parola
> smontata**, radice ed etimologia.
>
> *Mondo 24, il Cuore dei Primi* — «Il cuore proietta dodici cerchi di luce, uno
> per sistema, e ognuno tocca gli altri due vicini.» → **i due cerchi**, qui
> piegati a dire la convergenza finale invece di un ragionamento logico.

**Una volta sola, e mancarla non costa nulla** — la stessa regola dei forzieri e
delle Tracce. `landmarkTavoleSeen` nel salvataggio tiene il conto; un pannello
dedicato (`LandmarkTavolaPanel`) mostra la tavola senza ripetere gli errori già
pagati oggi altrove: `Panel` ancorato, non `PanelContainer` che cresce col
contenuto, pulsante fisso fuori dallo scorrimento.

**Due guardie.** `landmark_tavola_audit` chiama `mostra()` per davvero su tutte e
24 le figure — non basta che le chiavi ci siano, il disegno deve riuscire — e
pretende una descrizione per chi non vede, nessuna riga ripetuta, nessuna
scoperta lunga più di una frase. Provata rompendo apposta una chiave: rossa sul
mondo esatto, poi verde di nuovo. `pannelli_modali_audit`, già scritto oggi per
un altro difetto, copre gratis anche questo pannello: non si apre sopra
un'altra schermata, e il passo di Eli lo segue.

### R-10 · La bottega diceva sempre la stessa frase — chiusa il 5 settembre 2026

*Richiesta: rendere bottega, oggetti e mondi un'esperienza più interessante e
interattiva, con parole curate per un bambino di dieci anni.*

**Non un mercante nuovo.** Un personaggio che tratta i prezzi è un'aggiunta
vera — nuova UI, nuovo contratto, una decisione di prodotto che spetta al
committente. Quello che si poteva fare subito, senza inventare niente, era far
parlare **chi già parla ovunque nel gioco**: NORA guarda quello che è già scritto
nel salvataggio — forzieri aperti, pattuglie sciolte, mondi visitati — e lo dice
aprendo la bottega. Zero dati nuovi, zero rischio.

Prima, sempre la stessa riga: *«Trasforma i frammenti raccolti nei mondi in
identità, alleati e nuovi spazi da vivere»*. Adesso otto soglie, dalla più
esigente alla più permissiva:

> *«Ho segnato una sacca che non c'è più. Quello che custodiva adesso è tuo, e
> resta tuo.»* — dopo la prima pattuglia sciolta
>
> *«Cinque cose trovate, cinque persone di cui adesso sai un pezzetto senza
> averle mai incontrate. Continua a guardare per terra.»* — dopo cinque forzieri

`nora_bottega_voce_audit` tiene due proprietà: nessuna riga vuota o troppo lunga
per un sottotitolo, e **chi ha esplorato di più non torna mai a sentire la frase
di chi non ha fatto niente** — attraversare le soglie va in una direzione sola.

### R-9 · La notte era un filtro, non un'ora — chiusa il 5 settembre 2026

*Richiesta: dare valore alla mappa e aggiungere tensione.*

Il ciclo giorno/notte esisteva e muoveva **un solo `CanvasModulate`**: oltre al
colore non cambiava niente, e il piano lo chiamava già «un filtro, non un'ora».

**Il buio non poteva essere la leva, e va detto perché.** `WorldSky.PAVIMENTO`
garantisce una luminanza minima di 0,20 su tutto ciò che finisce sullo schermo:
è una promessa di accessibilità, e non si tocca da nessuna direzione — nemmeno
per fare atmosfera. Quindi la notte doveva cambiare **che cosa succede**, non
**quanto si vede**.

Succede che **le sacche notano Eli da più lontano**: ×1,34 a mezzanotte piena,
con la curva che sale senza salti dal tramonto in poi. E le sacche adesso
**seguono l'ora** invece di tenere la vista che avevano alla nascita — chi entrava
di giorno e restava fino a notte fonda girava con la vista del mattino.

**Costa zero nodi e zero millisecondi.** È un moltiplicatore, non una luce: con
il mondo 1 a 457 ms su 500 non era un dettaglio da poco, ed è la ragione per cui
questa leva è stata scelta fra le tre possibili.

| | vista delle sacche |
|---|---:|
| giorno | 1,00 |
| notte | **1,34** |
| notte, con Andatura felpata | **0,96** |

**Ed è qui che l'Andatura felpata guadagna i suoi 340 frammenti.** Prima era uno
sconto su un pericolo che non stringeva mai; adesso è la risposta a una domanda
che il mondo pone — e la notte torna percorribile come il giorno per chi l'ha
comprata. È il primo modulo della bottega che ha un momento in cui *serve*.

`notte_audit` tiene quattro proprietà: la notte stringe davvero; non stringe
tanto da chiudere una strada (il guard-rail «niente blocca il loop» vale anche
per l'ora del giorno); l'Andatura felpata la riporta al giorno **senza
cancellarla**; e dove il tempo non passa — archivi, abissi — non cambia niente,
perché lì mezzanotte non esiste.

### R-8 · Vincere un duello non contava niente — chiusa il 5 settembre 2026

*Segnalazione: «vincere un combattimento deve dare vantaggi adeguati, altrimenti
lo studente li evita».* Aveva ragione, e la causa era più profonda del premio.

**Prima ho provato la strada sbagliata, e va scritto.** L'idea era far pagare il
duello in `indagine`, la dimensione narrativa del Lascito. Ma `indagine` conta i
**beat di livello** — uno per mondo, rivelato quando ci arrivi: non è una cosa
che si trova, è una cosa che ti succede. Il secondo aggancio, `mondo`, era anche
peggio.

**La misura che ha cambiato tutto:**

```
ogni mondo pianifica 18 eventi · la campagna ne produce 432
META_INCONTRI era 90
→ «mondo» si riempiva al MONDO 5, e da lì valeva 0,20 pieni qualunque cosa facessi
```

Con `rotta` (mondi aperti) e `indagine` (beat per livello) automatiche per
costruzione, **il 45% del Lascito era deciso dal solo fatto di giocare**. Non
esisteva un posto in cui mettere il premio di un duello — ed è la ragione
strutturale per cui saltarlo era la mossa razionale.

**La correzione.** `META_INCONTRI` da 90 a **560**, ricavata dai totali veri:
432 eventi + 72 (le 24 riparazioni, che valgono tre) + 60 pattuglie = 564 se si
fa tutto. E `mondo` adesso conta anche **le pattuglie sciolte** — una guardiana
battuta non rinasce, quindi lascia un posto diverso, che è esattamente il
criterio dichiarato di quella dimensione.

Misurato su tre modi di giocare, a parità di didattica:

| | mondo | totale | finale a padronanza 0,62 |
|---|---:|---:|---|
| solo ciò che il gate chiede | 0,64 | 0,815 | **registro** |
| tutti gli eventi, pattuglie evitate | 0,90 | 0,866 | **fondo** |
| tutto, pattuglie comprese | 1,00 | 0,886 | **fondo** |

Sette punti di punteggio finale fra il primo e l'ultimo, **e una fascia di
differenza**. Prima erano tutti e tre a 1,00.

Nessuna regola violata: la decisione 15 resta intatta perché qui non si compra
niente — si conta ciò che si è fatto. E `endings_audit` ora costruisce il profilo
pieno con quello che il gioco offre davvero (18 eventi, la riparazione e le
pattuglie di quel mondo) invece di dividere la meta per ventiquattro, che con 560
avrebbe chiesto 24 eventi in mondi che ne hanno diciotto: **un profilo perfetto
impossibile non prova che il finale pieno sia raggiungibile, prova il contrario.**

### R-7 · La difficoltà di minigiochi e duelli — chiusa il 5 settembre 2026

*Richiesta: «controlla che anche i minigiochi siano a difficoltà crescente su 24
livelli, e lo stesso nei combattimenti».*

**La prima misura poneva la domanda sbagliata, e va detto.** Contando i gradini
distinti fra il mondo 1 e il 24, la media era 12,5 su 24 con cinque archetipi
fermi a tre. Ma **un bambino non incontra un archetipo ventiquattro volte**: il
mucchio lo incontra una volta sola, la prova quattro. Ventiquattro gradini per
una prova giocata una volta sono un numero che non tocca nessuno.

La domanda giusta — *nei mondi in cui quell'archetipo compare davvero, la
richiesta cresce?* — è la stessa che `guardian_duel_audit` applica alle fasce del
duello. Con quel metro, tre archetipi erano piatti fra un incontro e l'altro:

| archetipo | mondi | difetto | correzione |
|---|---|---|---|
| **mercato** | 4, 11, 14, 16 | `richieste` fermo a quattro: i banchi ne hanno quattro, chiederne di più non produce niente | gli errori concessi scendono da 3 a 2 |
| **prova** | 10, 15, 20, 21 | cadenza da otto: il 10 e il 15 chiedevano gli stessi fattori a cinque mondi di distanza | cadenza da sei |
| **vibrazione** | 6, 18 | **diventava più facile salendo**: gli errori erano `prove − 1`, quindi quattro al mondo 18 contro due al 6 | budget fisso a due |

La vibrazione era il caso peggiore ed è colpa di ieri: legare gli errori ai turni
sembrava prudente e faceva l'opposto. Indovinare costa già due errori per turno,
quindi **un budget fermo si stringe da solo** man mano che i turni crescono.

**E la sonda cieca ha ripreso al volo una ritaratura sbagliata.** La prima
versione degli errori del mercato partiva da quattro invece che da tre — un
gradino più generoso di prima — e il gioco risaliva dal 25,0% al 36,7%. *Una
curva che sale deve partire da dove stava.* Rimessa a tre: **23,3%**, il valore
più basso mai misurato per quell'archetipo.

**I duelli erano messi peggio.** Cinque fasce su 24 mondi, e fra il mondo 15 e il
24 cambiavano **soltanto** `massimo` (150 → 240) e `secondi` (10 → 9): bersagli
più grandi e meno tempo, cioè le due cose che il gioco rifiuta come difficoltà in
ogni altro minigioco. Per dieci mondi il duello era la stessa prova scritta più
grande.

La quinta fascia adesso allunga **la catena**: quattro colpi invece di tre, mano
da sette rune, e i secondi **risalgono** a dodici — un anello in più è più cosa da
pensare, non meno tempo per pensarla. Il salto da due a tre colpi era già
dichiarato come *il* salto del duello; il quarto è il gradino successivo.

**Due guardie nuove.** `minigiochi_scala_audit` misura, per ogni archetipo, che la
richiesta non cali mai fra un incontro e il successivo e sia più alta all'ultimo
che al primo — ignorando gli archetipi che si incontrano una volta sola, che una
curva non ce l'hanno. E `guardian_duel_audit` ha una riga in più: **fra due fasce
deve cambiare qualcosa oltre la taglia** — la lunghezza della strada, le rune da
scartare, le operazioni o l'intervallo dei fattori.

> **Una cosa che NON era un difetto, e che avevo scambiato per tale.** Le prime
> tre righe di misura dicevano che scaffale, mercato e prova «rigiocano una prova
> identica». Falso: il materiale è del **personaggio**, non dell'archetipo, quindi
> Corinna e Coral propongono parole diverse anche a parità di parametri. Quello
> che era piatto era *quanto il gioco chiede*, non *che cosa mostra*.
>
> Su quella diagnosi sbagliata avevo scritto una rotazione della finestra di
> selezione, per far uscire anche la coda delle liste. **Tolta**: ogni
> personaggio compare una volta sola, quindi non toglieva nessuna ripetizione, e
> ha fatto arrossire `market_minigame_audit`, che è legato al contenuto dei primi
> turni. Una correzione che non corregge niente e rompe una guardia è solo
> rischio.

### R-6 · «Preme AVANTI e non succede niente» — chiusa il 5 settembre 2026

*Segnalazione di gioco: «lo studente risponde, preme avanti, e si blocca. La
domanda è ancora visibile, AVANTI è visibile, ma non sembra succedere niente».*

**È la terza volta su questo punto**, e le prime due sono citate dentro
`exercise_player.gd`: *«rispondendo correttamente la prova si blocca»* (8 agosto,
il contenuto non scorreva) e *«VERIFICA tagliato dal bordo»* (15 agosto, i
comandi scorrevano via col contenuto). Le due correzioni hanno riparato **il
riquadro della domanda**. Nessuna ha toccato **la scheda di NORA**, quella che si
apre sopra la prova quando un nodo porta un concetto nuovo — ed è lì che il
difetto è rimasto.

Quella scheda è un `Control` a tutto schermo con `MOUSE_FILTER_STOP`: finché non
si chiude **si mangia ogni tocco**. Chi gioca preme AVANTI, che sta sotto, e non
succede niente. Due difetti la tenevano aperta:

1. **Il pulsante che la chiude finiva sotto il bordo.** Era l'ultimo elemento di
   una colonna scorrevole dentro un `PanelContainer`, che si adatta al contenuto
   e quindi **cresceva oltre i propri ancoraggi**. Misurato: «HO CAPITO» a
   **y 854 su uno schermo alto 720** — centotrenta pixel fuori. Ora il riquadro è
   un `Panel` ancorato, il testo scorre dentro, e il pulsante è fissato in fondo
   fuori dallo scorrimento: la stessa forma della correzione del 15 agosto.
2. **Due schede si aprivano una sull'altra.** Niente controllava se ce ne fosse
   già una: chiuderne una lasciava l'altra a fermare i tocchi, e il pulsante
   sembrava rispondere una volta e poi smettere. Ora la scheda nuova sostituisce
   la vecchia.

**La guardia: `nodo_senza_uscita_audit`.** Gioca sessioni vere prese dal mondo —
missioni, enigmi e riparazioni dei mondi 1, 2, 5 e 9 — su tre schermi, e a ogni
scheda chiede due cose: il pulsante che la chiude sta dentro lo schermo senza
scorrere, e non ce n'è più di una aperta. **279 nodi, 136 schede.** Sul codice di
ieri è rossa su entrambi i difetti, con le coordinate esatte.

> **Una nota di metodo che vale più della correzione.** La prima stesura di
> questa guardia costruiva le sessioni a mano con `ContentManager`: apriva
> **zero** schede su 168 nodi e sarebbe stata verde su un difetto vivo. La scheda
> la attacca il percorso di gioco, non il costruttore della sessione. Una guardia
> che non vede mai la cosa che deve sorvegliare è peggio di nessuna guardia.

### R-5 · Due schermate una sull'altra dopo la prima prova — chiusa il 5 settembre 2026

*Segnalazione di gioco: «clicca il tasto per procurarsi la falcetta, procede alla
prova, e dopo alcune domande corrette il programma si blocca».*

**La riparazione non era rotta.** Giocata dall'inizio alla fine — tre campate,
tutte corrette — finisce, consegna la falce e restituisce il passo. Rotto era il
**contorno**, e il momento coincide perché il Custode si concede alla *prima
sessione conclusa*: la richiesta del suo nome si apriva esattamente lì.

Due difetti distinti, tutti e due misurati:

1. **Il campo del nome prendeva il fuoco della tastiera.** `grab_focus()` su una
   `LineEdit`: su tablet e su Web apre la tastiera di sistema, che copre la scena
   e si prende i tasti. Il gioco **sembra fermo mentre non lo è** — ed è la
   descrizione esatta della segnalazione. Ora il nome si scrive toccando il
   campo, come un bambino farebbe comunque.
2. **Si camminava sotto un pannello aperto.** `_on_dialogue_closed` restituiva il
   passo in cima, *prima* di decidere se aprire il minigioco del personaggio; se
   un pannello era già aperto, `_apri_minigioco_personaggio` usciva subito e il
   giocatore restava libero **sotto una schermata modale**. Da fuori è
   indistinguibile da un blocco: si tocca la scena e risponde qualcos'altro.

E la sovrapposizione vera e propria: la richiesta del nome e il minigioco di
Corinna stavano aperti **insieme**. Ora la richiesta del nome non si apre sopra
un'altra schermata e si ritira quando ne arriva una; `needs_name` resta vero e
la domanda torna alla sessione successiva, perché per contratto è rimandabile.

**Nessuno giocava questa strada.** `minimission_audit` guarda solo i dati e non
entra in scena; `roundtrip_audit` scavalca chiamando `_on_exercise_finished`. Il
ciclo domanda-per-domanda di una riparazione — e soprattutto quello che succede
**dopo** — non lo percorreva nessun audit. Adesso lo fa
`pannelli_modali_audit`, che tiene un'invariante in due righe: **mai due
schermate insieme, e il passo di Eli è spento se e solo se ce n'è una aperta.**
Le due metà sbagliate di quella riga sono i due modi in cui un bambino dice «si
è bloccato». Provata prima di fidarsene: disattivando la correzione è rossa su
entrambi i casi, con i nomi dei pannelli.

### R-1 · La build spedita porta la versione sbagliata — chiusa

`npm run audit:web` **esce 1**:

```
la versione mostrata (461516e) non e' quella del codice: da allora sono cambiati
10 file, fra cui godot/scripts/game/adaptive_audit.gd
```

> **Chiusa il 4 settembre 2026.** Il rituale a due commit ha funzionato al primo
> colpo: `1e94cfd` porta il codice, `7c06252` porta la build, e `audit:web` è
> verde — *«2026.09.04-web-loader-2, PCK 79.10 MiB, WASM 37.68 MiB»*, cache a
> `v189-web-loader`. La diagnosi resta qui sotto perché spiega perché l'ordine
> dei due commit non è una formalità.

`BuildVersion.COMMIT` diceva `461516e`, ma HEAD era `3096ace`, e fra i dieci file
cambiati dopo lo stamp ci sono `content_manager.gd`, `world_lesson.gd` e
`world_difficulty_curve_audit.gd` — cioè proprio la decisione 16.

**Il gioco non è rotto: è l'etichetta a essere indietro di un commit.** La
cronologia lo dice: `461516e` alle 11:23:39, lo stamp alle 11:23, il PCK alle
11:29, `3096ace` alle 11:30:24. L'export ha preso il codice nuovo dall'albero di
lavoro; lo stamp aveva già scritto il commit precedente, perché il commit che
porta la build non esisteva ancora. `web:sync:check` è allineato, quindi non è la
cache.

**Non è però solo contabilità, ed è per questo che l'audit esiste.** Il suo
commento lo dice: se fra il commit marchiato e HEAD non è cambiato nessun
sorgente è contabilità; se è cambiato, **la build online mente su cosa sta
eseguendo**, ed è esattamente il numero che serve quando arriva una segnalazione
di gioco. Qui sono cambiati dieci file, fra cui il cuore della difficoltà.

**Il rituale, com'era scritto, non poteva finire verde.** Se si esporta prima di
committare, lo stamp è sempre di un commit indietro e l'audit si arrossa ogni
volta che il lotto ha toccato il codice — cioè sempre. L'ordine giusto è:
**committare il codice, poi stampare, esportare, sincronizzare, e fare un secondo
commit che contenga solo la build e `build_version.gd`.** Il rituale in fondo a
questo file è stato corretto di conseguenza.

### R-2 · `gesto_audit` — chiusa il metro, resta storia

> **Chiusa il 4 settembre 2026, tranne una materia.** `REPEATS` è passato da 8 a
> 32: il campione del mondo va da ~1200 a ~4600–6100 nodi per materia, e le due
> basi di seme che prima discordavano di **2,3 punti** ora concordano entro
> **0,5**. I dodici tetti del mondo sono stati ritarati sul peggiore delle due
> basi e **il mondo è verde**.
>
> L'esame è passato per lo stesso allargamento (1200 → 4800 nodi, accordo entro
> 0,6). Otto tetti su dodici **scendono**, e la regola applicata è scritta
> nell'audit: dove la nuova misura è più bassa il tetto scende; dove è più alta
> ma entro l'incertezza dichiarata del vecchio strumento (±1,8) si adegua; dove
> è più alta oltre quell'incertezza **non si muove**, perché lì è cambiato il
> contenuto e alzare il tetto laverebbe una regressione.
>
> **Resta un rosso solo, ed è vero: `storia / esame` al 35,8% contro 32,1.**
> +3,7 punti, il doppio dell'incertezza del vecchio strumento. La tavolozza di
> storia non è sottile — sei linee del tempo, tre indiziari, due cicli — quindi
> la causa probabile è il lavoro sui pesi dei formati del 4 settembre.
> **Provato e scartato:** aggiungere specialisti non serve, perché `cycle` e
> `clue` contano a loro volta come «sceglie» e hanno alzato il numero di quattro
> decimi invece di abbassarlo. Serve un formato **manipolativo** in più
> nell'esame di storia, o un peso diverso in `NONMC_FORMAT_WEIGHTS` — che è la
> radice già identificata in G-C2. Geografia (+1,9) e scienze (+2,5) stanno
> dentro solo per la tolleranza: sono le due da guardare subito dopo.

<details>
<summary>La misura che ha portato a questa conclusione</summary>

### La diagnosi del 4 settembre

I tetti sono stati misurati il 1 settembre e **possono solo scendere**. Quattro
li superano, con una tolleranza di 1,0 punto:

| materia | oggi | tetto | oltre la tolleranza di |
|---|---:|---:|---:|
| coding | 31,8% | 30,1 | 0,7 |
| inglese | 27,3% | 25,8 | 0,5 |
| fisica | 24,7% | 23,1 | 0,6 |
| elettronica | 26,6% | 25,6 | 0,0 |

**Prima di inseguire il contenuto, va detto che cosa misura davvero questo
rosso.** Rieseguito cambiando **solo il seme** — `7100` → `7777`, nessuna riga di
contenuto toccata — i dodici numeri si spostano così:

| | seme 7100 | seme 7777 | Δ |
|---|---:|---:|---:|
| storia | 29,2 | 26,9 | **−2,3** |
| geografia | 27,9 | 29,5 | **+1,6** |
| inglese | 27,3 | 25,7 | **−1,6** |
| latino | 23,6 | 22,5 | −1,1 |
| le altre otto | | | entro ±0,8 |

Col secondo seme **inglese passa** (25,7 sotto il tetto di 25,8) e fisica cade
esattamente sulla tolleranza. La conclusione è netta: **l'oscillazione da seme
(fino a 2,3 punti) è più grande della tolleranza che il cricchetto concede (1,0
punto)**, quindi in questa fascia l'audit misura il seme quanto il contenuto. È
lo stesso difetto già trovato e corretto il 1 settembre **per l'esame** — dove
`CAMPIONI_ESAME` è stato portato a 1200 nodi per materia proprio perché «un
cricchetto su ottanta nodi misura il seme» — e **mai corretto per il mondo**.

Quindi la voce si divide in due, e sono due lavori diversi:

- **R-2a · Il metro.** Allargare il campione del mondo come è stato fatto per
  l'esame, e rimisurare i dodici tetti su due basi di seme indipendenti,
  scrivendo di quanto concordano. Finché la tolleranza è più stretta del rumore,
  ogni rosso costa un'indagine a mano e insegna a ignorare l'audit.
- **R-2b · Il contenuto.** La preoccupazione di fondo resta vera e documentata: il
  2 settembre elettronica è crollata da ~244.000 a 2.293 di profondità perché il
  perimetro era stato stretto senza rifornirlo. Coding resta sopra il tetto con
  entrambi i semi, ed è il caso da guardare per primo.

**Nessuna delle quattro materie viola la decisione 6**, che fissa il tetto di
progetto al 33%: stanno fra il 24,7% e il 31,8%. Quello che si è rotto è il
cricchetto che abbiamo messo noi sopra la regola, non la regola.

</details>

### R-3 · `explanation_coverage_audit` — chiusa

> **Chiusa il 4 settembre 2026.** `compose` è passato da **sette ricette a
> diciotto**: ogni materia che offre il formato ne ha adesso almeno tre. La
> frase di latino è scesa sotto il quarto dei nodi e l'audit è verde — *«25
> formati, nessuna spiegazione mancante, nessuna formula sopra il 25%»*.
>
> Undici ricette nuove, tutte su argomenti che NORA già copre, così nessuna apre
> il costo di un topic nuovo: punteggiatura (italiano), declinazione-2m e
> verbo-sum (latino), third-person e irregular-past (inglese), condizioni e liste
> (coding), note e ritmo (musica), frazioni e geometria (matematica).
>
> **Un buco chiuso per strada:** l'unica ricetta `compose` di musica era a
> `minLevel` 12, mentre il mondo di musica è il 6 — quindi al primo incontro con
> la materia il compositore **non usciva mai**. Le due nuove stanno a livello 6.
>
> E un effetto collaterale nel verso giusto: musica scende da 27,3% a 24,3% di
> «sceglie», latino da 24,9 a 24,4, inglese di sette decimi. Nessuno ha tolto
> una crocetta — è la scelta dello specialista che si è ridistribuita.

**La guardia, e qui c'è la parte che vale più della correzione.**
`format_depth_audit` è nato dalla segnalazione «al mondo 1 la prova di scienze
riguarda sempre la farfalla», e la sua regola è «un formato con meno di tre
ricette si ripete». Ma misurava **soltanto le tre generiche** — abbinamento,
ordinamento, smistamento. I formati **specialisti**, dove le ricette sono più
rade, non li guardava nessuno: è la stessa cecità che quell'audit fu scritto per
chiudere, spostata di un piano.

Adesso conta anche loro, per coppia **(formato, materia)**, e il numero misurato
oggi è **22 coppie sotto le tre ricette** — con `compose` non più fra queste.
Non è un minimo secco, perché *prima il contenuto, poi il cricchetto*: alcune
sono sottili per natura, e imporre tre a tutti obbligherebbe a scrivere contenuto
per far passare un test. È un tetto che **può solo scendere**, e rende visibile
un debito che finora non aveva un numero. Le più esposte sono le tredici a
ricetta singola: lì il bambino rivede la stessa identica prova ogni volta che il
formato esce.

<details>
<summary>La diagnosi che ha portato a questa conclusione</summary>

```
in «compose» una sola frase copre il 30% dei nodi: è un'istruzione, non una
spiegazione — «L'accusativo singolare della prima declinazione esce in -am.
"-ae" è g…»
```

La soglia è `QUOTA_GENERICA = 0,25`: nessuna frase può coprire più di un quarto
dei nodi di un formato. La regola è giusta — *una riga ripetuta insegna a
saltarla* — e il bambino qui legge davvero la stessa frase sul latino un `compose`
su tre.

**Ma riscrivere quella frase non la risolve, e va detto perché.** Il formato
`compose` ha **sette ricette in tutto, distribuite su sei materie**: italiano 2,
e una ciascuna per latino, inglese, coding, musica e matematica. Tredici
spiegazioni in totale. Anche distribuendo alla perfezione, la ricetta unica di
una materia vale già circa un sesto dei nodi del formato; basta che due materie
abbiano il `minLevel` alto perché le rimanenti si concentrino e una singola frase
arrivi al 30%. **La soglia del 25% non è raggiungibile scrivendo meglio: è
raggiungibile solo scrivendo di più.**

E c'è una cosa che vale più della correzione. `format_depth_audit` esiste
esattamente per questo — è nato dalla segnalazione «al mondo 1 la prova di
scienze riguarda sempre la farfalla» — e la sua regola è «un formato con meno di
tre ricette si ripete». Ma **conta per formato, globalmente**: `compose` ha sette
ricette, quindi passa. Il difetto vive un livello più sotto, in
**(formato, materia)**, dove `compose` ha una ricetta sola quasi ovunque. È la
stessa cecità che quell'audit fu scritto per chiudere, spostata di un gradino.

> Nella suite completa questo audit compariva anche come `[TIMEOUT]`, e la
> ragione ora si sa: **un `assert` fallito interrompe `_init` e il `quit(0)` non
> viene mai chiamato**, quindi il processo resta appeso fino al timeout del
> runner. Un audit che si arrossa costa quattro minuti invece di venti secondi, e
> il rosso vero si legge solo scorrendo l'output. Vale per ogni audit di questo
> progetto.

</details>

---

## La coda aperta

### Contenuti e didattica — Claude

**G-C1 · Il banco di matematica — chiusa il 6 settembre 2026.**
*Richiesta: «occupati di matematica per tutti i mondi, in modo da esplorare tutti
gli argomenti del programma medie e biennio liceo scientifico, spiegati con
attenzione e dettaglio, usando mini giochi quando possibile».*

Il banco aveva **379 item e sette argomenti**, di cui 284 tabelline: il 75%. Gli
altri sei stavano tutti a 15 o 16, cioè al minimo che `topic_density_audit`
impone — esistevano per non far arrossire una guardia. Adesso sono **698 item e
venticinque argomenti**, e le tabelline sono il **40,7%**.

**Trecentodiciannove item nuovi**, in `scripts/banks/matematica-programma.mjs` —
un file suo, perché è materiale che si continuerà ad ampliare e in mezzo al bake
sarebbe una vena di millecinquecento righe. Diciotto argomenti nuovi, ognuno
almeno a quindici item, distribuiti sulle bande in cui la scuola li introduce:

| banda (mondi) | argomenti nuovi |
|---|---|
| 1 (1-4) | numeri, operazioni, multipli, primi |
| 2 (5-10) | potenze, interi, proporzioni, probabilità |
| 3 (11-17) | coordinate, solidi, sequenze, funzioni, problemi |
| 4 (18-24) | calcolo letterale, sistemi, disequazioni, similitudine, equazioni |

Il biennio del liceo entra per intero nella banda 4: insiemi numerici (N ⊂ Z ⊂ Q
⊂ R e il primo irrazionale), monomi e polinomi, i due prodotti notevoli,
raccoglimento e scomposizione, sistemi lineari con i tre casi letti sul grafico,
disequazioni con la trappola del verso che si rovescia, radicali, Talete e il
primo teorema di Euclide.

**Cinque voci di NORA nuove** (`solidi`, `calcolo-letterale`, `sistemi`,
`disequazioni`, `similitudine`) e **tredici schede scritte a mano nel Manuale**:
per gli argomenti nuovi il Manuale avrebbe costruito la lezione da solo pescando
un item a caso, e una scheda automatica non sa dire qual è l'errore tipico né
perché si fa — che sono le due righe che valgono di più.

**Sei minigiochi nuovi**, per i sei argomenti che restavano senza gesto:
abbinamento per `radici` (√ → numero) e `similitudine` (i nomi del triangolo
rettangolo); smistamento per `solidi` (**cm, cm², cm³**: chi non distingue le tre
unità non può accorgersi che un risultato è assurdo), `calcolo-letterale`
(monomio/binomio/trinomio), `sistemi` (un punto, nessun punto, tutta la retta) e
`disequazioni` (il numero risolve o no, con il confine incluso o escluso).
Nessun nome di contenitore compare dentro le sue tessere: è la scorciatoia del
«bidone», e `scorciatoie_minigiochi_audit` resta verde.

**Le regole di scrittura, dichiarate nel file.** La risposta giusta non è mai più
lunga di quattro caratteri del distrattore più lungo (il tetto di matematica in
`bank_scorciatoie_audit` scende, non sale); nessun punto delle migliaia in una
risposta, perché `2.500` e `2500` per il correttore di Godot sono due numeri
diversi e l'item diventerebbe incorreggibile una volta convertito a risposta
libera; tutti scritti a scelta multipla di proposito, perché la conversione al
30% di risposta libera è automatica e scriverli già liberi butterebbe via i
`distractorWhy`. Un controllo a parte verifica tutte e sei le regole su tutti e
319 gli item prima del bake.

Resta aperta la **bilancia dell'uguale**: la figura non esiste ancora, ma adesso
c'è di che disegnarla — `uguaglianze` ha il suo smistamento e `equazioni`
diciotto item.

> **Fase 4 chiusa a meta' il 9 settembre 2026, e G-C12 e' passata dal 65,1% al
> 41,9%.** Sei materie sono uscite del tutto dal ponte — logica, latino,
> scienze, storia, elettronica, musica — non riscrivendo gli item ma dandogli una
> **scala dichiarata per argomento**: una tabella che dice in quali quattro
> fasce cadono i gradi di ogni argomento, scritta guardando l'ordine in cui la
> materia si insegna e non la lunghezza del testo.
>
> **Guardia: `fascia_autorata_audit`.** Il bake non cancella piu' il flag
> `_difficulty8`, quindi la quota di fasce decise da una persona e' misurabile e
> a cricchetto. Restano da riautorare matematica, fisica, geografia, coding e
> italiano; il metodo e le tre trappole gia' pagate stanno in
> [docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).

**G-C12 · Due terzi delle fasce le ha scelte un'euristica, non un autore.**
← *aperta il 9 settembre 2026; è il debito della scala a otto, e va prima di
G-C11*

Il passaggio da quattro bande a otto fasce è stato fatto giusto sul piano della
struttura — mappatura, sessioni, esami e guardia sono a posto e verdi. Ma il
**contenuto** non è stato riautorato: `expandLegacyDifficultyBands()` in
`scripts/build-exercise-banks.mjs` **taglia in due ogni vecchia banda** ordinando
gli item per un punteggio di *domanda cognitiva* — lunghezza del testo, formato
libero, presenza di parole come «perché» o «se», righe della consegna — e manda
la metà più alta nella fascia pari.

Misurato oggi strumentando il bake: **3159 item su 4854, il 65,1%, hanno preso la
loro fascia da quel punteggio.**

| materia | dal ponte | | materia | dal ponte |
|---|---:|---|---|---:|
| geografia | **100%** | | fisica | 88,6% |
| scienze | **100%** | | matematica | 67,4% |
| storia | **100%** | | italiano | 58,2% |
| logica | **100%** | | inglese | **32,6%** |
| latino | **100%** | | | |
| elettronica | 92,5% | | musica | 89,9% |
| coding | 89,7% | | | |

Solo tabelline, lessico, coding, elettronica e il catalogo teorico portano una
fascia scritta a mano (`_difficulty8`); tutto il resto è ordinato per lunghezza.
E **la lunghezza del testo non è la difficoltà di un argomento**: è la stessa
confusione che `perche-regala-la-lunghezza` ha già fatto pagare una volta sulle
risposte. Una domanda corta su un argomento avanzato finisce in fascia dispari,
una domanda lunga su un argomento elementare in fascia pari.

La firma si vede a occhio nella distribuzione: per otto materie su dodici le
coppie (2k−1, 2k) sono quasi esattamente metà e metà — 30/30, 21/21, 16/16 — che
è ciò che produce un taglio a metà, non un curricolo.

**Che cosa va fatto, e in quale ordine.** Non riscrivere 3159 item: riautorare
per materia, cominciando dalle cinque al 100% che sono anche le più povere
(geografia, scienze, storia, logica, latino), e dichiarare `_difficulty8`
sull'item man mano che la fascia diventa una scelta. Il ponte resta finché serve,
ma **va misurato**: serve un audit che dica quanti item di ciascuna materia hanno
una fascia autorata, e che quel numero salga e mai scenda. Senza quella guardia,
la scala a otto resta una rinumerazione con un nome nuovo.

> **Fase 2 chiusa il 9 settembre 2026.** 300 item nuovi su sei materie
> (geografia +89, coding +81, fisica +51, storia +31, latino +24, scienze +24),
> in sei file `scripts/banks/*-programma.mjs`, tutti con la fascia scritta a mano.
> Il banco passa da 4854 a **5154 item**; **nessuna materia sta piu' sotto il
> pavimento delle quindici sessioni** (il minimo del gioco era 3), e
> **`variety_audit` e' verde** dopo essere stato rosso su cinque materie. In fisica quattro argomenti su dodici non esistevano affatto
> nelle prime due fasce: luce, calore, energia e metodo erano a zero. Consuntivo e lezioni in
> [docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).
>
> **La misura che manca ancora, ed e' la piu' importante:** non item per fascia,
> ma item per **(argomento, fascia)**. Storia era rossa con settantanove item nel
> pozzo perche' due argomenti ci stavano con uno solo, e il selettore sceglie
> prima l'argomento. Nessuna guardia lo vede.

**G-C13 · Il censimento per fascia, e i due buchi che mostra.**
← *aperta il 9 settembre 2026; misurata con* `censimento_fasce_probe.gd`

Questa voce porta i numeri veri, perché finora il piano non li aveva mai scritti.
Il probe chiede al motore stesso — non ai file — quanti item e quante ricette
vede ogni materia in ogni fascia.

**Il banco, item per fascia.** L'item sta in *una* fascia sola; la selezione ne
ammette ±1, quindi il pozzo reale di una fascia è la somma di tre.

| materia | tier | tot | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| inglese | 1 | 1466 | 418 | 256 | 237 | 110 | 104 | 102 | 134 | 105 |
| matematica | 1 | 944 | 51 | 52 | 108 | 94 | 127 | 131 | 210 | 171 |
| italiano | 1 | 780 | 228 | 111 | 96 | 73 | 86 | 79 | 57 | 50 |
| fisica | 2 | 229 | 25 | 24 | 24 | 22 | 37 | 46 | 29 | 22 |
| geografia | 2 | 199 | 14 | 13 | 30 | 30 | 35 | 35 | 21 | 21 |
| coding | 2 | 195 | 7 | 8 | 28 | 28 | 37 | 33 | 27 | 27 |
| latino | 3 | 289 | 11 | 10 | 46 | 45 | 58 | 58 | 31 | 30 |
| storia | 3 | 167 | 11 | 11 | 21 | 21 | 29 | 28 | 23 | 23 |
| elettronica | 3 | 159 | 12 | 10 | 24 | 23 | 24 | 23 | 22 | 21 |
| scienze | 3 | 154 | 16 | 15 | 21 | 20 | 26 | 25 | 16 | 15 |
| musica | 3 | 148 | 11 | 10 | 18 | 17 | 23 | 28 | 22 | 19 |
| logica | 3 | 124 | 9 | 8 | 15 | 14 | 16 | 16 | 23 | 23 |

**Due forme opposte, e nessuna delle due è stata decisa.** Matematica sale
(51 → 210): il materiale sta dove sta il programma. Italiano e inglese
*scendono* (228 → 50, 418 → 105): il lessico è tanto e facile, la sintassi è
poca e difficile. Un bambino al mondo 22 trova in italiano un terzo del materiale
che aveva al mondo 2 — cioè meno varietà proprio dove le domande sono più dure.

**Il numero che conta davvero: quante sessioni distinte prima di rivedere un
item.** È il pozzo (fascia ±1) diviso per gli esercizi della sessione.

| materia | tier | esercizi/sessione | fascia peggiore | sessioni prima di ripetere |
|---|---:|---:|---|---:|
| **coding** | 2 | 5 | **F1** (15 item) | **3** |
| geografia | 2 | 5 | F1 (27 item) | 5 |
| fisica | 2 | 5 | F1 (49) e F8 (51) | 10 |
| italiano | 1 | 6 | F8 (107 item) | 18 |
| matematica | 1 | 6 | F1 (103 item) | 17 |
| inglese | 1 | 6 | F8 (239 item) | 40 |
| le sei di terza fascia | 3 | 1 | logica F1 (17 item) | 17 |

**La seconda fascia è il collo di bottiglia, non la terza.** Cinque esercizi per
sessione su banchi da ~200 item: coding al mondo 1–3 ha **quindici item in tutto**
e ne serve cinque per sessione — tre sessioni e il bambino ha visto tutto. Le sei
materie di terza fascia sembrano povere ma pescano un esercizio alla volta, e a
quel ritmo un pozzo da venti item regge venti sessioni.

**Le ricette di minigioco.** Sono cumulative (`minLevel`), quindi la colonna dice
quante ne *vede* quella fascia, non quante ne nascono.

| materia | tier | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | in rotazione a F1 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| inglese | 1 | 27 | 51 | 72 | 74 | 95 | 110 | 118 | **128** | 4 meccaniche |
| matematica | 1 | 25 | 42 | 57 | 64 | 72 | 75 | 82 | **84** | 7 |
| italiano | 1 | 22 | 30 | 37 | 51 | 52 | 53 | 54 | **54** | 5 |
| fisica | 2 | 20 | 30 | 38 | 38 | 53 | 53 | 55 | **58** | 6 |
| coding | 2 | 23 | 37 | 43 | 44 | 47 | 48 | 51 | **53** | 6 |
| logica | 3 | 18 | 31 | 42 | 45 | 45 | 46 | 49 | **50** | 4 |
| storia | 3 | 15 | 28 | 37 | 40 | 45 | 45 | 49 | **49** | 4 |
| geografia | 2 | 15 | 38 | 45 | 46 | 47 | 47 | 47 | **48** | 4 |
| scienze | 3 | 22 | 35 | 40 | 40 | 42 | 43 | 46 | **48** | 7 |
| musica | 3 | 14 | 33 | 40 | 41 | 43 | 46 | 46 | **47** | 4 |
| elettronica | 3 | 19 | 21 | 22 | 24 | 26 | 26 | 44 | **47** | 6 |
| **latino** | 3 | 11 | 23 | 29 | 30 | 30 | 31 | 31 | **31** | **3** |

Tre cose che questa tabella dice e che non erano scritte da nessuna parte:

1. **Italiano è la materia di prima fascia più povera di gesti** — 54 ricette
   contro 128 dell'inglese — e serve sei esercizi per sessione. È la causa
   misurata di R-18;
2. **Elettronica sta ferma dalla fascia 2 alla fascia 6**: +2, +1, +2, +2, +0, e
   poi +18 di colpo alla fascia 7. Dal mondo 4 al mondo 18 il bambino gira sulle
   stesse ventisei ricette — quindici mondi;
3. **Latino ha 31 ricette e tre meccaniche in rotazione al mondo 1**, ed è
   l'unica materia che al mondo 1 sta sotto quattro. Dalla fascia 5 in poi non ne
   sblocca più nessuna.

**E il buco delle fasce basse resta**, ora con il suo numero: nelle prime due
fasce — i mondi 1–6, dove tutto si incontra per la prima volta — coding ha 15
item, logica 17, latino 21, musica 21, elettronica 22, storia 22.
`topic_density_audit` non se ne accorge perché conta gli item **per argomento sul
totale del banco**, non dentro la fascia: i quindici item della Decisione 9 non
sono mai stati misurati per fascia, e con quattro bande larghe non serviva.
`difficulty_bands_audit` chiede solo che ogni fascia regga *una sessione* — che
per una materia di terza fascia è un esercizio, quindi passa con un item in tutta
la fascia.

**Le riparazioni, con il conto fatto**, stanno in
[docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md): un
pavimento dichiarato («il pozzo di ogni fascia regge almeno quindici sessioni
distinte»), **212 item** su tre sole materie — coding 81, geografia 81, fisica 50,
tutti nelle fasce 2 e 8 — e **84 ricette**, di cui nove per italiano che chiudono
R-18. Il ponte 4→8 è l'ultima fase, non la prima: un item in fascia sbagliata
resta un item corretto.

> **Fase 3 chiusa il 9 settembre 2026: le ricette di minigioco.** Tutte e dodici
> le materie portano ora almeno **tre ricette nuove in ognuna delle otto fasce**;
> prima trentaquattro caselle stavano sotto quella soglia e sei materie avevano
> fasce a zero. **Meta' del lavoro non e' stata scritta ma spostata**: elettronica
> aveva diciassette ricette tutte a `minLevel` 20 — quindici mondi sulle stesse —
> e latino ne aveva due gated un mondo troppo tardi. Le altre 47 sono contenuto
> nuovo. Guardia: `ricette_per_fascia_audit`, pavimenti a 3 per tutte.
>
> **La domanda da fare per prima non e' «che cosa manca» ma «dove sta cio' che
> c'e'».** Vedi [docs/PIANO_OTTIMIZZAZIONE_FASCE.md](docs/PIANO_OTTIMIZZAZIONE_FASCE.md).

> **Fase 5 chiusa il 9 settembre 2026: le guardie.** Tre audit nuovi —
> `pozzo_per_fascia`, `fascia_autorata`, `ricette_per_fascia` — e **venti tetti
> su ventiquattro abbassati** in `gesto_audit`, che ne aveva fino a quarantuno
> punti d'aria. `TOLLERANZA_ESAME` da 3,0 a 1,0.
>
> La misura che mancava, e che ha corretto due volte chi scriveva, e' la seconda
> di `pozzo_per_fascia`: **quanti ARGOMENTI tocca il pozzo di una fascia**. Il
> selettore sceglie prima l'argomento; contare gli item non lo vede.

**G-C2 · La scelta multipla — riscritta il 9 settembre 2026.**

**La voce si è capovolta, e conviene dirlo per intero perché per tre settimane il
lavoro è stato puntato dalla parte sbagliata.** Il problema dichiarato era
l'esame: media 34,4%, elettronica al 63,0%, storia rossa a 35,8%. Rimisurato oggi,
l'esame è **sano su tutte e dodici le materie** — «manipola» al 70,0% ovunque,
«sceglie» fra il 20,7% e il 26,1%, media ≈23,7% — e non perché qualcuno abbia
lavorato sui formati: perché l'esame è stato **ricostruito sulle fasce di
priorità** (50/35/15, pescando da tutte le materie con quote fisse). Un lotto che
non si proponeva di sistemare il gesto lo ha sistemato di rimbalzo.

Restano due cose, e nessuna delle due è quella scritta prima:

1. **Il rosso si è spostato nel mondo, su italiano** (26,0% contro 22,3%): è
   R-18, e la causa candidata sono i sei esercizi per sessione della prima
   fascia;
2. **I tetti sono da riabbassare.** Elettronica ha un tetto di 63,0 su un valore
   reale di 21,9. Un cricchetto con quarantun punti d'aria non trattiene niente,
   e la regola dice che i cricchetti scendono.

Le due cause vecchie restano scritte in `gesto_audit` e vanno riverificate prima
di crederci ancora, perché sono state misurate su un esame che non esiste più:
`NONMC_FORMAT_WEIGHTS` che favorisce i formati a loro volta «sceglie», e
`formati_da_sostituire` che porta fuori solo la scelta multipla lasciando dentro
i nodi da digitare.

**G-C3 · La scelta multipla a zero fuori dall'esame, alle altre dieci materie.**
`MC_TARGET_PER_MATERIA` contiene ancora due sole voci, elettronica e logica. Si
estende **una materia alla volta, misurando prima la tavolozza** — e R-2 è la
dimostrazione di che cosa succede a non farlo.

**G-C4 · I vocabolari di banco e minigiochi non coincidono.**
La copertura del gate conta gli argomenti toccati, ma il bersaglio si calcola sul
banco: circa cento argomenti vivono solo nel catalogo interattivo. In inglese,
coding, scienze, fisica ed elettronica un bambino può soddisfare la copertura
toccando argomenti che l'esame non verificherà mai. Delle due riparazioni quella
giusta è **allineare i vocabolari**: se un argomento vale per la copertura, deve
poter comparire in un esame.

> **L'inglese è allineato per otto argomenti** (8 settembre 2026). Con il
> programma di grammatica di `scripts/banks/inglese-programma.mjs` hanno
> finalmente un banco — e quindi un esame — `articles`, `third-person`,
> `do-does`, `past-tense`, `irregular-past`, `comparatives`, `question` e
> `word-family`: prima erano ricette di `MinigameManager` e basta. Restano
> scoperti gli argomenti che nascono dalla forma del minigioco e non dal
> programma (`sentence`, `negative`, `wh-question`, `spelling`, `opposites`,
> `conversation`, `categorie`, `parts-of-speech`, `verbs`, `nouns`,
> `irregular-plural`, `vocabolario`, `word-family` nel senso dei suffissi):
> lì la riparazione giusta non è scrivere item apposta, è decidere se quegli
> argomenti debbano contare per la copertura.

> **E il verso opposto è chiuso** (9 settembre 2026). Il disallineamento aveva
> due direzioni, e la seconda era la più grave: **27 argomenti del banco
> d'inglese su 47 non avevano nessun minigioco**, fra cui `to-be`, `have-got`,
> `pronouns`, `plurals` e `there-is` — tutto ciò con cui la lingua comincia si
> poteva soltanto crocettare. La causa non era la pigrizia del catalogo ma una
> cosa strutturale: con dodici materie su ventiquattro mondi **l'inglese ha casa
> solo ai mondi 4 e 16**, che stanno al *primo* dei tre livelli della loro
> fascia, e ogni ricetta di grammatica aveva `minLevel` a metà fascia — un mondo
> troppo tardi. Il mondo 4 vedeva 15 ricette su 61, tutte di lessico.
>
> Ora gli argomenti scoperti sono **zero**, i gate stanno all'inizio della
> fascia, il decodificatore dei verbi (le tre ghiere: tempo, forma della frase,
> voce) è passato dall'italiano all'inglese con otto casi di fascia, e la linea
> del tempo serve i tre passati. La grammatica toccata con le mani è salita dal
> 24,8% al 45,3% al mondo 4 e dal 59,1% al 60,1% al mondo 16, con gli argomenti
> distinti da 2 a 12 e da 20 a 28. Guardia: `inglese_minigiochi_audit`.
>
> Il pezzo che nessun audit vedeva era però la **lezione del mondo**: finché
> `world_lesson.gd` prometteva solo lessico, `LESSON_TOPIC_SHARE` (0,67) tirava
> due nodi su tre lontano dalla grammatica e il programma nuovo arrivava al
> bambino come **due nodi su millesettecento**. Regola generale: un argomento
> non è servito da un mondo finché quel mondo non lo *nomina*.

**G-C5 · I ventidue quesiti sui componenti elettronici.**
Relè, condensatore: il problema non è la forma della domanda, è che un decenne
non ha mai visto l'oggetto. Le domande dirette sono già fuori dalla pratica e
restano nell'esame; **manca il minigioco che faccia montare i componenti** prima
di verificarne il nome. Il formato `HOTSPOT` — l'unico in cui si riconosce una
cosa vera invece di leggerne il nome — esiste per la sola `storia`, con un
atlante e quattro bersagli: non sostituisce il montaggio, ma gli prepara il
materiale.

**G-C6 · Le spiegazioni degli item che restano riformulazioni.**
Il livello per argomento copre il perché generale, ma «Roma è la capitale della
Repubblica Italiana» resta un'eco. Vanno riscritte **per argomento**, partendo da
quelli allo 0% di nesso: parole di casa, lessico inglese, declinazioni, geografia
fisica.

**G-C7 · Le settecento glosse di lessico che si scrivono solo a mano.**
«Quando NON si usa» e la parola dentro un'altra che il bambino già conosce.
Nessuna regola meccanica le produce: è lavoro di scrittura, a lotti per campo
semantico. Vale il vincolo di sempre — dove non c'è niente di vero da dire, la
spiegazione resta corta e onesta.

**G-C14 · Quattro firme per materia — aperta il 10 settembre 2026.**
*Richiesta: «gli esercizi che dobbiamo scrivere devono essere interattivi, non
più domande e risposte ma interazioni complesse con tipologie diverse a seconda
della materia; partiamo da quelle dove ne abbiamo di meno».*

Dichiarazione di rotta: **da qui in avanti il contenuto nuovo è interazione.**
Non «meno crocette» — quello è già un cricchetto — ma esercizi in cui il gesto
è la competenza, con **almeno quattro firme per materia**, ognuna una famiglia da
cui si generano molte varianti. I cinque renderer del primo lotto sono ora nel
runtime; il consuntivo misurato è in `docs/RELEASE_CANDIDATE.md`.

Tre cose sono nostre e vengono prima.

1. **Il banco porta tre formati manipolativi su dieci.** Linea del tempo,
   scorrimento, percorso di macchine, campione misterioso, decodificatore,
   griglia e porte hanno un renderer che funziona ma arrivano **solo** dalle
   ricette procedurali: `authoredMcItems` non li costruisce. Finché è così un
   esercizio complesso non si può *scrivere*, si può solo *generare* — le griglie
   di logica, oggi, le costruisce un algoritmo su sei scenari. Sono tre righe per
   formato, le stesse del 10 settembre per abbina/ordina/smista.
2. **Le firme che già esistono non hanno contenuto autorato.** Logica ha griglia
   e porte, scienze e fisica hanno il campione misterioso, italiano e inglese il
   decodificatore: tutto generato. Le prime griglie scritte a mano, con indizi
   pensati invece che potati, sono contenuto nuovo a costo zero di motore.
3. **L'ordine è quello del censimento**, dalla materia con meno item: logica 140,
   musica 155, elettronica 171, scienze 178, storia 225 — incrociato con chi una
   firma ce l'ha già.

**Si parte da coding**, che è la più povera in ventuno mondi su ventiquattro ed è
appena entrata nel nucleo con sei esercizi per sessione. Le sue quattro firme,
scelte per coprire quattro concetti diversi e non quattro vestiti dello stesso:

| firma | che cosa insegna | stato |
|---|---|---|
| **il robot nella griglia** | sequenza, cicli, condizioni | `robot_grid` nel runtime |
| **la catena di montaggio** | funzioni in fila, composizione, ordine delle operazioni | `machine_path` esiste: basta renderlo idoneo a coding |
| **il centralino** | condizioni e **ordine di valutazione** — la catena di `elif` in cui il primo vero vince | renderer nuovo, secondo giro |
| **il passo a passo** | stato: che cosa vale ogni variabile dopo ogni riga | renderer nuovo, secondo giro |

**Fatto l'11 settembre — tre lotti, 50 item, zero renderer nuovi.**

| materia | item | che cosa ha guadagnato |
|---|---:|---|
| coding | 23 | la catena di montaggio (`machine_path`), che esisteva per la sola matematica |
| logica | 12 | le prime **griglie e porte scritte a mano**: prima erano tutte generate |
| elettronica | 15 | da **zero** item manipolativi a dodici, e una firma trovata per strada |
| musica | 13 | le durate come catena di dimezzamenti, il metronomo come scala |
| scienze | 15 | le prime **indagini di laboratorio scritte a mano** |
| storia | 14 | tre linee del tempo, e il centro della scala che non aveva niente da toccare |
| latino | 14 | il decodificatore, sui verbi: tempo, modo e forma su tre ghiere separate |

Centocinque item, **undici formati diversi**, zero renderer nuovi.

**Le porte sono elettronica prima che logica, e nessuno se n'era accorto.** Il
formato era registrato come firma della sola logica, ma due interruttori in
serie *sono* la porta AND e due in parallelo *sono* la OR — non una metafora, la
stessa cosa vista da due discipline. Elettronica ha quindi una firma condivisa
e ora anche il banco di prova `breadboard`, che si monta davvero.

**Una guardia nuova: `node scripts/verifica-griglie.mjs`.** La griglia rilegge
gli indizi dal loro TESTO e capisce due forme sole («X non ha Y», «Chi ha Y è X
oppure Z»); poi conta per forza bruta che resti una soluzione sola. Lo script
rifà lo stesso conto sulla sorgente prima del bake: al primo giro ha trovato
**due griglie su tre ancora aperte**, e scoprirlo da Godot sarebbe costato un
giro di audit invece di mezzo secondo. Le due trappole che il validatore non sa
spiegare le controlla anche lui: un nome sottostringa di un altro, e un indizio
che nomina più di un attributo.

**Musica, due gesti trovati senza chiedere niente.** Il ritmo è aritmetica
esatta: contando in **sedicesimi** l'albero delle durate diventa una catena di
dimezzamenti interi (semibreve 16, minima 8, croma 2) e quindi è `machine_path`;
il punto di valore è un ×3 seguito da un ÷2, cioè «una volta e mezza», e montarlo
è capirlo. Il metronomo è una scala da 40 a 200, quindi è `timeline`: adagio,
andante, allegro e presto non sono quattro parole in fila ma zone di una linea.

**La regola che sta emergendo, e che vale per i prossimi lotti**: delle sei
firme mancanti, **tre erano già disponibili sotto il nome di un'altra materia**.
Prima di aprire una richiesta a Codex, guardare l'elenco dei dieci manipolativi e
chiedersi che cosa misura davvero quel gesto — `porte` non è «logica», è una
tavola di verità, e una tavola di verità la riempie anche chi studia gli
interruttori.

**Scienze: la guardia nuova ha trovato il difetto che dichiarava di cercare.**
`node scripts/verifica-firme.mjs` controlla i quattro formati-firma sulla
sorgente prima del bake, e oltre ai contratti verifica **tre cose che
`ExerciseInteraction` non sa controllare**:

- nella griglia, un nome che è sottostringa di un altro e un indizio che nomina
  più di un attributo;
- nel campione misterioso, **che nessuna prova SOLA basti a chiudere il caso** —
  se la prima mossa identifica già il campione, l'indagine finisce subito e la
  lezione «servono più prove indipendenti» non viene mai imparata;
- nella catena di macchine, che il percorso dichiarato arrivi al traguardo senza
  incepparsi su una divisione.

Al primo giro ha bocciato **tutte e due** le indagini di scienze: in una l'acqua
isolava subito il campione, nell'altra la prova della corrente. Riscritte, e il
campione nascosto è diventato quello che **nessuna prova nomina da sola** — il
sale, a cui non succede mai niente di speciale, e che si trova solo per
esclusione. È un caso migliore di quello che avevo scritto all'inizio.

**Storia: ventuno prove da toccare, tutte alle fasce 2 e 8.** Il centro della
scala — dalla 3 alla 7, cioè i mondi dal 7 al 21 — non ne aveva **nessuna**: un
bambino attraversava metà campagna senza toccare niente in storia. Il lotto sta
tutto lì in mezzo.

**E la linea del tempo risolve il vincolo invece di aggirarlo.** La regola della
materia dice *nessuna domanda di nome o di data senza una tavola su cui
impararla*; qui **la linea del tempo È la tavola**, perché ogni evento porta
l'anno scritto accanto e collocarlo è il modo in cui quell'anno si impara.

**Due cose imparate dalle guardie, e valgono per chi scriverà le prossime.**

1. **La separazione minima del 2%.** Due eventi più vicini di così sulla scala si
   sovrappongono sotto un dito. La prima linea di Roma metteva Cesare (44 a.C.) e
   l'inizio dell'impero (27 a.C.) a tredici millesimi: due eventi diversi per la
   storia, lo stesso punto per uno schermo. Cesare è uscito, e non è una perdita
   — su milletrecento anni quei diciassette non si vedono, ed è proprio quello
   che la scala deve insegnare.
2. **L'`answer` di una linea del tempo è una chiave, non una parola.**
   `KnowledgeCodex.recall_fact` tratta come «nome da ricordare» qualunque
   risposta fatta di lettere: con gli id a parole (`carlomagno`) la linea veniva
   scambiata per una domanda di nome e `tavole_riferimento_audit` chiedeva che
   NORA avesse insegnato quella stringa. Gli id sono diventati **gli anni**
   (`800`, `476`, `-509`): non hanno due lettere di fila, quindi la prova torna a
   essere quello che è — una posizione su una scala. La guardia resta accesa e
   misura di nuovo la cosa giusta.

**Latino, e una correzione allo studio del 10 settembre.** Lo studio diceva «le
manopole del caso: renderer già pronto, costo zero», cioè riusare il
decodificatore per far regolare caso, numero e genere di un **nome**. È sbagliato,
e si vede aprendo il renderer: i titoli delle ghiere sono scritti nel codice e
parlano di tempo e di modo.

Ma quelle tre ghiere sono **esatte per i verbi**, che è dove il latino è più
difficile: tempo, modo e forma sono proprio le tre informazioni che una desinenza
porta insieme, e separarle è tutto il punto — chi indovina «scribebat» perché
«suona da passato» non ha capito, chi sceglie *imperfetto* e *indicativo* e poi
trova la forma sì. I tre item vanno dal presente di scribo all'imperfetto di sum
fino al perfetto di Cesare che attraversa il Rubicone, dove la differenza fra
«transibat» e «transiit» non è stile: è che cosa è successo.

Per la declinazione il decodificatore ora legge tre `axisTitles` opzionali dai
dati: caso, numero e forma non ereditano più i titoli pensati per i verbi.

**Prossimo**: geografia, l'ultima delle sei senza firma.

**G-C8 · I maestri nella pratica.**
`TeachingCatalog` ha un solo consumatore fuori dagli audit
([outdoor_world.gd:3904](godot/scripts/outdoor_world.gd#L3904)), ed è il
«rispiegamelo». Le stazioni di pratica non lo usano: il residente dovrebbe
allenare ciò che sa fare, nel luogo in cui vive o si ritrova. Il gancio esiste
dal quartiere degli allenamenti e non è mai stato tirato.

**G-C9 · Le leve del nucleo, studiate e non attivate.**
Due luoghi invece di uno per le tre materie quando non sono ospiti — tocca il
direttore degli eventi e va rimisurato il tempo per mondo; ripasso più stretto
sui loro argomenti; il registro che mostra il nucleo a parte.

**G-C10 · Gli epiloghi non nominano le minimissioni.** Oggi le contano soltanto.

**G-C11 · Quindici ricette al mondo 1** (oggi dieci per materia). Deciso, e da
fare **dopo il collaudo**: sei materie del mondo 1 sono cambiate molto e conviene
sapere se la differenza si sente prima di scriverne altre sessanta.

### Resa e scena — Codex

**C-R5 · La dispensa è tre schermate di testo senza una figura.** Aperta l'11
settembre 2026 insieme alla regola delle dispense
([docs/REGOLA_DISPENSE.md](docs/REGOLA_DISPENSE.md)). Misurato adesso, con le
cinque materie convertite:

| | |
|---|---|
| dispense scritte | **97** |
| testo totale | **310.056 caratteri** |
| media per dispensa | **3.196 caratteri** |
| la più lunga (`coding-operatori-base`) | 4.102 caratteri |
| la più lunga sulla scheda | **1.719 px in una finestra da 566 px = 3,0 schermate** |
| blocchi disegnati in quella scheda | 24, **tutti di testo** |

Il contenuto c'è ed è verificato — `dispense_audit` è verde, e giocando davvero
il documento arriva davanti al 100% dei primi incontri. Il problema è che
`ExercisePlayer._show_teaching_overlay` sa disegnare una cosa sola: paragrafi in
`Label`. Tre schermate di prosa continua davanti a un bambino di undici anni si
saltano, e una dispensa saltata è peggio di una scheda breve, perché insegna che
le spiegazioni si chiudono senza leggerle.

Due cose, e la prima vale più della seconda:

1. **Una figura per dispensa, dove la figura è il contenuto.** La scheda deve
   poter portare un disegno accanto a una sezione, non solo testo. I casi in cui
   il disegno *è* la spiegazione sono già scritti e si trovano per nome: i tre
   stati della materia (`scienze-materia-base`), la piramide ecologica
   (`scienze-ecosistema-alta`), la fascia dei deserti a trenta gradi
   (`geografia-geografia-fisica-alta`), le due placche che spingono
   (`geografia-geografia-italia-alta`), il rientro che decide a chi appartiene
   una riga (`coding-condizioni-base`).
2. **Come si sta dentro tre schermate.** Oggi non c'è nessun segno di quanto
   manchi né modo di tornare a una sezione: la colonna scorre e basta. Serve
   almeno un indicatore di avanzamento, e possibilmente le sezioni come passi
   con un avanti/indietro invece di uno scorrimento unico.

**Guardia da lasciare chiusa insieme al lavoro:** un audit che pretende che
nessuna dispensa superi N schermate senza portare almeno una figura, con N
misurato e scritto. Oggi il numero è 3,0 e non c'è nessuna figura: qualunque
soglia dichiarata è un miglioramento su nessuna.

**C-R6 · Il paradigma latino è una tabella raccontata a parole.** Aperta l'11
settembre 2026. Le sette dispense `latino-declinazione-*` descrivono in prosa
corrente una tabella di undici caselle — «al singolare: nominativo *rosa*,
genitivo *rosae*, dativo *rosae*…» — e lo fanno perché la scheda non sa
disegnare una tabella, non perché sia il modo giusto di presentarla. Ogni libro
di latino stampa quel paradigma in griglia nella prima pagina, e c'è un motivo:
in griglia si vede a colpo d'occhio quali caselle coincidono, che è esattamente
la cosa che gli item chiedono di sapere.

Il materiale è già strutturato e non va riscritto: ogni dispensa dichiara le sue
`regole`, e `TAVOLE_LATINO` ha già le tavole `paradigma` con una voce per casella.
Manca il renderer: una griglia casi × numero, con le caselle che coincidono
marcate.

**Guardia da lasciare chiusa insieme al lavoro:** un audit che verifichi che per
ogni dispensa di declinazione la griglia disegnata abbia tante celle quante ne
dichiara la tavola corrispondente — ancorato agli id, mai a un totale (è la
lezione di `treasure_audit`).

**C-R7 · Scienze e fisica restano le due materie senza nessuna figura.**
`nora_spiegazione_utile_audit`, controllo 5, oggi stampa: «1047 prove hanno un
disegno · 10 materie su 12 (senza: fisica, scienze)». Era vero prima e resta vero
adesso, ma da oggi pesa di più: scienze ha sedici dispense che nominano cose che
si capiscono guardandole e non leggendole — le particelle nei tre stati, la
piramide dell'energia, la catena che si chiude sui decompositori, l'inclinazione
dell'asse che produce le stagioni.

**Guardia:** quella che esiste già. La riga «10 materie su 12» diventa «12 su 12»
da sola quando il lavoro è fatto, e non serve scrivere un audit nuovo.

**C-R2 · I quindici minigiochi dei personaggi hanno un asset in tutto**
(`assets/minigames/tobia-crystal-v1.png`). Le tavole vettoriali sono leggibili e
funzionano. **Aspetta il collaudo**: finché non si misura quali meccaniche
restano nel giro, illustrarle tutte e quindici è lavoro su un'ipotesi.

**C-R3 · Gli ultimi quattro mondi non hanno scenografia.** ✅ **Chiusa l'8 settembre 2026.**
Misurati i `Node2D` effettivamente disegnati nei chunk caricati, alla stessa
distanza di streaming:

| mondo | tema | nodi per chunk |
|---|---|---|
| 1 | `academy` | **143** |
| 6 | — | 86 |
| 12 | — | 58 |
| 18 | `sound_cathedral` | 59 |
| 21 | `fractured_atlas` | *(stesso gruppo, non misurato a parte)* |
| 22 | `deep_biosphere` | **19** |
| 23 | `hall_of_eras` | **12** |
| 24 | `first_heart` | **18** |

Scomposto sul mondo 18: `BiomeAssemblies` **670** nodi, `HabitatDetails` **85**,
prop identitari 5. Sul mondo 23: **niente** oltre al terreno e a due prop
identitari. Il climax della campagna si gioca su un'isola da 2900×2800 px con
nove oggetti in tutto.

Non è la tabella delle percentuali di `chunk_manager` — quella l'ho seguita e
non è lei. Sono due `return` dichiarati per nome:
`chunk_visual._build_global_assemblies` (riga 177) e `_build_global_details`
(riga 223) escludono `fractured_atlas`, `deep_biosphere`, `hall_of_eras` e
`first_heart`, cioè **i mondi 21, 22, 23 e 24**.

**L'esclusione è giusta e non va tolta.** Quei temi non hanno alberi e sassi:
prestargli il vocabolario generico li sporcherebbe, ed è esattamente perché
qualcuno l'ha scritta che non l'ho toccata. Quello che manca è **il vocabolario
loro**: per ciascuno dei quattro temi servono i `kind` di assembly (principale,
figli, accento — i tre `_assembly_*_kind` di `chunk_visual`) e i dettagli
d'habitat che gli appartengono. Frammenti di carta stellare per l'Atlante,
crescite bioluminescenti per la Biosfera, stele e cornici per la Sala delle Ere,
schegge di nucleo per il Cuore.

Alzare la percentuale degli ostacoli **non** risolve: gli ostacoli procedurali
sono al massimo 16 per mondo dove ce ne sono, e non spiegano i 900 nodi di
differenza. E sono decorazione senza collisione, quindi nemmeno cambiano il
cammino.

**Guardia da lasciare chiusa insieme al lavoro:** un audit che pretende un
pavimento di nodi disegnati per chunk in **tutti** i ventiquattro mondi — il
numero si taratura sul mondo 18 (59), non sul mondo 1. Senza, la prossima
esclusione per tema torna a passare inosservata per una stagione.

> **Fatto.** L'esclusione dai due generatori naturali e' rimasta esattamente al
> suo posto. `chunk_visual` apre ora due strati separati, `ThemeAssemblies` e
> `ThemeHabitatDetails`, che usano il nuovo vocabolario vettoriale
> `ThemeSceneryArt`: carta strappata, rotte e frammenti di bussola nell'Atlante;
> steli, spore e radici luminose nella Biosfera; stele, cornici e registri
> materici nella Sala delle Ere; schegge, vene e tracce di impulso nel Cuore.
> Ogni tema ha `kind` distinti per principale, figli, accento e micro-dettagli;
> nessuna forma ha testo o collisione.
>
> La prima misura onesta della guardia ha trovato anche sette temi precedenti
> sotto il pavimento: non sono stati nascosti dal test. La densita' delle loro
> assemblies e' stata calibrata per tema, senza alzare gli ostacoli. Con raggio
> di streaming 1, `world_scenography_density_audit` misura ora **tutti e 24 i
> mondi >= 59 nodi/chunk**; il minimo e' il mondo 21 a **59,1**. I mondi 21–24
> stanno rispettivamente a **59,1 · 74,3 · 61,6 · 71,2**, e la guardia verifica
> anche che entrambi gli strati tematici esistano e contengano forme del tema.
> Le istanze ripetute dell'Atlante sono un `MultiMesh`: la guardia conta le forme
> disegnate, mentre la GPU le invia insieme.
>
> Anche le catture GPU sono state rifatte: mondo 21 **566 / 595 / 699** draw call
> (desktop / HUD compatto / landmark, budget mobile 700), mondo 23
> **505 / 539 / 677**, mondo 24 **565 / 596 / 628**. Il mondo 22 resta verde
> nelle viste giocate (**521 / 551**) ma rosso sulla sola tavola landmark
> (**748**): una misura causale con tutta la nuova scenografia esclusa lascia
> comunque **730** draw call. Il sovraccosto appartiene quindi alla scena
> preesistente del `living_core`, non a C-R3; non e' stato nascosto alzando il
> budget ne' svuotando la Biosfera.

*Nota di misura, perché non venga confuso con questo:* il **deserto** — quanta
terra sta a più di 600 px da qualunque contenuto — è sceso da 40,8% a 23,9%
distribuendo i forzieri, ed è un asse diverso. C-R3 è quanto è **arredato** un
posto, non quanto c'è **da fare**. Un mondo può essere pieno di cose da fare e
sembrare comunque un prato.

**C-R4 · Il cuore del duello è un carattere, non un disegno.** ✅ **Chiusa l'8
settembre 2026.**
[`duel_stage.gd:371`](godot/scripts/ui/duel_stage.gd#L371) disegna la tenuta con
`"♥".repeat(...)`, e il font imbarcato non ha quel glifo: su Web e su tablet il
bambino vede un rettangolo vuoto col codice esadecimale dentro, cioè il difetto
**invisibile esattamente sulla macchina di chi scrive il codice**. È il rosso di
`glifi_audit`, ed è l'unico rosso della suite che appartiene alla resa. Serve un
cuore disegnato — o una forma piena, che basta — al posto del carattere.

> **Fatto.** `DuelEnduranceShapes` disegna ogni punto di tenuta con due lobi e
> una punta piena, più un contorno; in alto contrasto la forma diventa bianca e
> conserva la sagoma. Il testo contiene soltanto il numero di mosse e lo stato
> del colpo, mentre tooltip e metadato espongono «Tenuta di Eli: N». Il
> cricchetto e' doppio: `glifi_audit` vieta il ritorno al carattere e
> `guardian_scene_audit` verifica il nodo disegnato nei due tipi di duello.

> **Non sono voci aperte, e non vanno riaperte per distrazione.** Le figure di
> **fisica e scienze** sono escluse per scelta: nei loro testi non c'è niente che
> si estragga con certezza in un diagramma — le conversioni di unità in fisica
> sono tre esercizi su 157 — e disegnare comunque vorrebbe dire decorare. Il
> **cono di luce della torcia** rientra solo insieme al modulo G-4, che è
> ritirato: resa e regola tornano insieme o non tornano.

### Decisioni tue

**G-16 · Al mondo 24 la tolleranza verso il basso ha ancora senso? — aperta il 6
settembre 2026**

La selezione degli item accetta da sempre una tolleranza di **±1 attorno alla
banda del mondo** (`content_manager.gd`): dà varietà senza uscire dal grado, e
vale per tutte e dodici le materie. Al mondo 24, quindi, un item di banda 3 è
ammesso **per costruzione**.

Nessuno se n'era accorto perché `c11_world_content_audit` chiedeva banda 4 su
ogni nodo, con **un seme solo e venticinque nodi**, e con un banco di matematica
per tre quarti di tabelline il caso non pescava mai un banda 3. Il banco ricco lo
pesca: misurato su quaranta semi, al mondo 24 si gioca **86,9% in banda 4** e la
missione peggiore ne ha il 76,0%. La misura è stata allargata e resa onesta —
niente sotto la banda 3, e due pavimenti a cricchetto — ma la domanda di progetto
resta tua:

- **così com'è**: al grado più alto un esercizio su otto è del grado precedente,
  e serve da respiro fra i vincoli;
- **solo banda 4 al mondo 24**: più coerente con la Decisione 16 («si padroneggia
  il livello del mondo»), ma tocca tutte e dodici le materie e obbliga a
  rimisurare `world_difficulty_curve_audit`.

Non l'ho cambiata di sfuggita dentro un lotto di contenuti: è la curva, ed è la
tua.

> **Aggiornamento del 9 settembre: la domanda si è ammorbidita da sola.** Con
> otto fasce invece di quattro bande, il ±1 del mondo 24 ammette la fascia 7, non
> più un intero quarto di campagna: la stessa tolleranza vale ora **un terzo** di
> quanto valeva. Prima di decidere, conviene rimisurare quanto pesa davvero —
> l'86,9% era misurato sulla scala vecchia e non si trasferisce.

**G-17 · Sei materie su dodici avevano un esercizio per sessione — chiusa il 10
settembre 2026**

> **Fasce 4+4+4, sessioni 6/4/2.** Nessuna materia si chiude più in una domanda
> sola, e le quote 50/35/15 restano quelle dichiarate: 24/16/8 esercizi fanno
> 50,0% / 33,3% / 16,7%. Il giro completo passa da 39 a 48 esercizi.

La gerarchia 50/35/15 dell'8 settembre non aveva toccato solo la soglia: aveva
cambiato **quanto si esercita**. `EXERCISE_NODES_BY_TIER` valeva 6 / 5 / 1, e la
terza fascia erano sei materie — musica, latino, elettronica, scienze, storia,
logica. Un giro da 39 esercizi rispettava le quote, ma **6 contro 1 è un rapporto
di sei a uno fra una sessione di matematica e una di storia**, e la differenza non
era di soglia ma di esistenza: in una sessione da un esercizio non c'è modo di
sbagliare e riprovare, non c'è un secondo esercizio che chiuda il ragionamento del
primo, e NORA ha una sola occasione di dire qualcosa.

**Perché la risposta non era «mettere 2».** La quota di sforzo è `esercizi ×
materie`, non `esercizi`. Con sei materie in terza fascia, portarle a due dava
28,6% contro un 15% ±5: sfondava di quattordici punti, e trascinava fuori
tolleranza anche le altre due fasce (42,9% e 28,6%). Le uniche lunghezze che
salvavano il 15% su sei materie — 10/6/2, 9/7/2 — chiedevano un giro da almeno 60
esercizi, +54% di campagna contro il vincolo dichiarato che nessuna voce del piano
la allunga.

**La leva era la composizione, non il numero.** Con lunghezze 6/4/2 le quote
50/35/15 ammettono **una sola** divisione: 4+4+4. Ma *quali* materie occupano i
posti non l'ha deciso la didattica: l'ha deciso il banco. `pozzo_per_fascia_audit`
chiede quindici sessioni distinte per fascia, cioè `pozzo / esercizi`, e misurando
i dodici banchi gli esercizi che ciascuno regge oggi sono inglese 15, italiano 7,
matematica 6, fisica/geografia/coding 5, latino 3, storia 3, scienze 2, e
**musica, elettronica e logica 1**.

**La scelta piu' difendibile era la piu' cara.** `logica` al nucleo — ragionare
accanto a leggere e calcolare — chiedeva **217 item nuovi**, perché logica ha il
banco più sottile dei dodici (124 item) e ciò significava metterlo nella sessione
più lunga. Con `coding` al nucleo e `logica` in terza fascia il conto scende a
**80**. Il vincolo è il contenuto, non il giudizio: se il banco di logica
raddoppia, la promozione torna sul tavolo.

**Due conseguenze da tenere d'occhio.**

- `coding`, `latino` e `storia` ereditano il resto del rango, non solo la
  lunghezza: bonus di soglia (+0,08 al nucleo, +0,04 in seconda al mondo 24) e un
  argomento distinto in più di copertura per il gate. Sono le tre materie da
  guardare per prime se un gate diventa lento.
- **L'esame non è cambiato**: resta 10/7/3 nodi su 20 (`PRIORITY_EXAM_COUNTS`),
  perché è tarato sui pesi e non sulla lunghezza delle sessioni. Cambia *chi*
  riempie quelle caselle, non quante sono.

**L-1 · Il lotto delle sessioni lunghe — 88 item, 10 settembre 2026**

> **Sei materie sotto il pavimento, e nessuna più.** `pozzo_per_fascia_audit`
> verde su tutte e dodici, `free_answer_audit` verde su tutte e dodici. I dodici
> banchi passano da 5154 a **5242 item**.

Sessioni più lunghe consumano il banco più in fretta: `pozzo / esercizi` deve
restare sopra le quindici sessioni distinte per ogni fascia di difficoltà, e con
6/4/2 sei materie ci finivano sotto. I buchi stavano **agli estremi** — fascia 2
e fascia 8 — che è dove il ponte euristico 4→8 aveva lasciato meno materiale:

| materia | scritti | dove |
|---|---:|---|
| coding | 30 | 15 alla fascia 2, 15 alla fascia 8 |
| storia | 27 | 10 alla fascia 2, 17 alla fascia 8 |
| elettronica | 12 | fasce 5-8, tutte su `elettricita-base` |
| logica | 8 | fascia 2 |
| musica | 7 | fascia 2 |
| latino | 4 | 1 alla fascia 2, 3 alla fascia 8 |

**Sessantacinque su ottantotto non sono a crocetta, e non erano possibili
prima.** Fino a oggi i dodici banchi contenevano tre formati soli — scelta
multipla, numero, parola — e i gesti veri (trascina, abbina, smista) arrivavano
solo dalle ricette dei minigiochi, cioè da un sistema che il pozzo non conta.
Non era una scelta di design: `authoredMcItems` sapeva costruire quei tre
formati e nessuno aveva avuto bisogno del quarto, mentre l'`ExercisePlayer` ne
disegna venticinque da mesi. Da questo lotto il banco porta anche **ordering,
matching e classification**, con i contratti che `ExerciseInteraction` già
validava.

**Due difetti trovati mentre si scriveva.**

1. **`difficulty8` era letto solo per la scelta multipla.** Trentatré item
   autorati dichiaravano la propria fascia accanto a una risposta libera, e
   `authoredMcItems` non copiava il flag: quegli item finivano lo stesso sotto la
   scala per argomento o nel ponte 4→8. È la solita forma del difetto — scritto
   e mai letto — e stavolta il lettore mancava di tre righe.
2. **Un audit con un'asserzione fallita non finisce da solo.** Il `quit(0)` sta
   dopo gli assert: quando uno cede, lo script si ferma e il `SceneTree` resta a
   girare a vuoto. Il verdetto restava onesto (`FAILURE_MARKERS` intercetta la
   riga e stampa il messaggio), ma costava i 240 secondi interi del timeout —
   `pozzo_per_fascia_audit` ha girato venti minuti dopo aver già detto tutto.
   Ora `run-godot-audits.mjs` chiude il processo appena vede l'asserzione.

**Due rossi che la nuova composizione ha acceso, e tutti e due erano latenti.**

1. **L'esame del mondo 17 conteneva una prova di fascia 1.** La causa non era la
   progressione ma un cancello: prima del mondo 20 l'elettronica può pescare
   **solo** dagli id che il mondo 8 prepara (`ELECTRONICS_BEGINNER_EXAM_IDS`),
   e quelle prove stanno tutte nelle fasce basse. Al mondo 17, che è fascia 6,
   non restava niente nella finestra e la selezione ripiegava sul primo item
   disponibile. Il cancello adesso lascia passare anche l'approfondimento di
   `elettricita-base` scritto per le fasce 5-8: stesso argomento già insegnato,
   difficoltà che cresce col mondo. Il difetto c'era da prima — elettronica
   entrava in meno esami, e i semi dell'audit non l'avevano mai campionato.
2. **`subject_priority_audit` misurava la gerarchia su tre nomi scritti a mano**
   — matematica, fisica, storia. Il giorno in cui storia è salita in seconda
   fascia, l'assert ha cominciato a confrontare due materie della stessa fascia:
   rosso giusto, motivo sbagliato. Adesso i tre campioni si pescano da
   `tier_subjects(1|2|3)`, e la guardia segue la composizione invece di
   ricordarsela.

**L-2 · Cinque rossi che il lotto ha acceso, e cinque difetti veri — 10 settembre 2026**

La suite intera dopo il lotto: **7 non verdi su 277**. Due erano già noti e non
nostri (`performance_budget` = R-17 il metro, `glifi` = corsia di Codex). Gli
altri cinque erano tutti difetti **latenti**, che la nuova composizione ha solo
messo sotto il campione:

1. **`c04_audit` pretendeva un `answer` da ogni nodo.** Vero finché il banco
   portava solo crocette e risposte libere; un ordinamento non ha un `answer`.
   Adesso valida con `ExerciseInteraction.validate`, che è il posto dove il
   contratto di ogni formato è già scritto.
2. **`heart_gate_audit` contava le stanze spente come `materie − nucleo`.**
   Tornava per un caso: nessuna materia del nucleo divideva l'apparato con una
   di fuori. Coding e logica stanno tutte e due nel cratere logico, quindi
   riparare coding accende anche la stanza di logica — sette spente, non otto.
   Adesso il conto lo fa la mappa `materia → apparato`.
3. **`tavole_riferimento_audit`: due nomi chiesti senza una tavola che li
   insegni**, «feudo» e «veto». La regola era già scritta e l'ho violata
   scrivendo il lotto. Riparato dal lato giusto: «feudo» entra fra le risposte
   della voce che già lo spiega nella nota, e la tavola romana — che aveva
   consoli e senato ma non chi poteva fermarli — guadagna **i tribuni della
   plebe**.
4. **`music_beginner_audit`: la stessa prova due volte nella stessa missione.**
   La causa era in `_drain_into`, che lavorava su `pool.duplicate()`: il pozzo
   del chiamante restava pieno, e le due pescate su `lesson_near_pool` — prima
   con la quota del mondo, poi con il conto pieno — potevano ridare lo stesso
   identico item. Cinque missioni su cento a musica, mondo 6. **Adesso pescare
   svuota**, e l'id in chiaro fa da seconda rete. Vale per ogni missione del
   gioco, non solo per musica.
5. **`format_mix_audit`: una sessione su 3648 chiedeva due volte lo stesso
   argomento nello stesso gesto.** Erano due `matching|medioevo` scritti da me
   nello stesso lotto. Ridistribuiti sugli argomenti giusti — le fonti di una
   rivolta sono `fonti`, le novità che cambiano le città sono `civilta` — e la
   misura è tornata a **0 su 3648**.

**Poi la suite ne ha accesi altri due, e sono i due più istruttivi.**

6. **Il bake contava gli ordinamenti come «risposta libera».** Le due passate che
   convertono automaticamente le crocette in risposte aperte misuravano quanto
   libero c'era già con `format !== "multiple_choice"` — lo stesso insieme,
   finché i banchi avevano tre formati. Con i gesti dentro il banco non lo è
   più: trascinare non è scrivere, e la conversione si fermava troppo presto.
   Dieci item numerici in meno su logica, e `free_answer_audit` rosso al 19%.
   Adesso il bake usa il metro dell'audit, `numeric_input` e `short_answer`.
7. **`variety_audit`: la memoria delle prove recenti esisteva solo per i
   minigiochi.** Un item del banco poteva tornare in ogni missione di fila senza
   che niente se ne accorgesse. Il difetto era invisibile finché i formati da
   toccare arrivavano tutti dalle ricette — erano loro a occupare i posti buoni,
   e loro ruotavano. Con gli ordinamenti dentro il banco è uscito subito: logica
   al mondo 1, la stessa prova cinque volte su trenta. Adesso `_drain_into`
   ricorda quello che serve e preferisce quello che il bambino non ha visto di
   recente; storia è passata dal 23% al 7% di ripetizioni.

   Non è bastato: **logica alla fascia 1 aveva due argomenti soli**, `sequenze`
   ed `esclusioni`. Otto item nuovi di fascia 1 aprono `deduzioni`, `insiemi`,
   `verita` e `quantificatori` fin dal primo mondo. Il lotto sale a **96 item**.

8. **`_sciogli_doppioni` non poteva sciogliere un doppione non a crocetta.**
   Contava i doppioni e chiedeva altrettante sostituzioni, ma `inject_non_mc`
   tocca solo i formati che la materia dichiara sostituibili — di norma la sola
   scelta multipla. Due `short_answer` sullo stesso argomento restavano dov'erano.
   Adesso il formato del doppione entra fra i sostituibili, ed è zero su 3648.

9. **L'esempio svolto del manuale prendeva «l'item più facile dell'argomento».**
   Da oggi il più facile può essere un abbinamento, la cui risposta è un gesto e
   non una parola: `KnowledgeCodex` costruiva quindi una lezione con
   «domanda → (vuoto)». Adesso `_sample_item` sceglie il più facile **fra quelli
   con una risposta scritta**: un ordinamento resta un ottimo esercizio,
   semplicemente non è un esempio da mostrare.

**Il filo che li lega**: quattro su cinque erano guardie o selezioni che
funzionavano per una **coincidenza della composizione precedente**, non per una
regola. Una guardia che nomina tre materie a mano, un conto che sottrae invece
di leggere la mappa, un pozzo che si duplica invece di svuotarsi: tutte cose
verdi finché nessuno sposta niente.

**G-14 · Gli archetipi che si vincevano senza capirli — chiusa il 4 settembre 2026**

> **Nessun archetipo supera più il 25%**, che è il caso su quattro opzioni. Prima
> ce n'era uno al 100% e tre sopra il 40%.
>
> | archetipo | 21 ago | prima | **dopo** | che cosa è cambiato |
> |---|---:|---:|---:|---|
> | **mucchio** · Tobia, mondo 1 | 100,0% | 100,0% | **0,0%** | regola del tocco + cronometro |
> | **scaffale** · Corinna, mondo 2 | 43,3% | 43,3% | **8,3%** | tre scaffali invece di due |
> | **vibrazione** · Oreste | 36,7% | 36,7% | **11,7%** | errori sotto il costo di indovinare |
> | **prova** · Ortensia | 68,3% | 46,7% | **23,3%** | si nomina solo ciò che si è isolato |
> | mercato · Lino | 25,0% | 25,0% | 25,0% | — |
> | glifi · Bruno | 21,7% | 21,7% | 21,7% | — |
> | parentela · Zeno | 20,0% | 20,0% | 20,0% | — |
> | leva, stima | 35,0%, 8,3% | 0,0% | 0,0% | erano già sani: lo diceva il cronometro |
> | altalena, traccia | 3,3%, 1,7% | idem | idem | — |
> | ciclo · radio · circuito · ritmo | 0,0% | 0,0% | **0,0%** | *sani da sempre* |
>
> **La lettura era sbagliata prima ancora dei numeri.** Il CIECO tocca sessanta
> volte al secondo: dove c'è un cronometro il tempo non gli finisce mai, e la sua
> percentuale è un tetto che nessun bambino raggiunge. La sonda lo correggeva in
> una colonna e non nel titolo. Ora la prima colonna è già a ritmo umano — ed è
> per questo che leva e stima risultano a zero: **lo erano sempre state.**
>
> **Il mucchio non era una taratura.** Con la vecchia regola un tocco su una fila
> intera ne prendeva dieci *ovunque cadesse*: non esisteva una mossa sbagliata,
> quindi chi toccava a caso faceva gli stessi tocchi di chi aveva capito —
> misurati, quindici contro quindici. Nessun cronometro poteva separarli. Adesso
> si prende **da dove si tocca fino in fondo alla fila**: chi prende una fila
> dalla testa la porta via in un tocco, chi la punge a metà ne prende la coda.
> Svuotarla a caso costa in media H(10) = 2,93 tocchi contro uno.
>
> **E la guardia contava un mucchio che non esisteva.** `character_minigame_audit`
> calcolava `floor(pezzi/gruppo) + pezzi%gruppo` = sei tocchi, mentre `_disponi()`
> ne costruiva quindici. Adesso la disposizione la calcola **una funzione sola**
> che usano pannello e audit, e c'è la misura che mancava del tutto: *chi tocca a
> caso deve perdere*.
>
> Le altre tre correzioni seguono lo stesso principio — **rendere impossibile il
> gesto cieco invece di punirlo**: nella prova un nome si può dire solo se quella
> manopola si è mossa da sola fra due esperimenti (il pulsante resta spento, e lo
> dice senza scriverlo); nello scaffale la terza categoria fa cadere il testa o
> croce; nella vibrazione gli errori concessi scendono sotto il costo medio di
> indovinare.

**D-1 · I quattro rimasti fra il 20% e il 25%: si stringono ancora?**

`mercato` (25,0%), `prova` (23,3%), `glifi` (21,7%) e `parentela` (20,0%). Sono
tutti attorno al caso di una scelta fra quattro, che è il riferimento dichiarato
di questa misura, e nessuno di loro ha una scorciatoia strutturale come quelle
appena chiuse. Scendere ancora vuol dire togliere tentativi, e da qui in poi il
confine fra «esigente» e «punitivo» **lo vedi tu giocando, non lo vede la sonda.**

**D-2 · C-MG-3 · La lingua della radio.** ✅ **Chiusa l'8 settembre 2026.**
Marea sta al mondo 4, la cui materia è inglese, e i suoi nove messaggi erano in
italiano: la meccanica era giusta, il materiale no — e la convinzione da far
cadere, *capire è tradurre parola per parola*, su un testo italiano non si poteva
nemmeno formulare.

I nove messaggi sono adesso in inglese, con due protezioni sulla difficoltà che
era il rischio dichiarato: **ogni parola sta nel banco d'inglese a difficoltà 1**
(waves, boat, water, rocks, fog, wind, rain, engine, help, bell, safe, place), e
la finestra passa da 5,4 a 9,0 secondi tramite `secondiFattore`, che vale per
questa scheda soltanto — alzare il cronometro dell'archetipo avrebbe regalato
secondi anche a chi legge nella propria lingua. Le luci restano in italiano: al
mondo 4 si chiede di capire l'inglese, non di produrlo.

**D-3 · Accessibilità dei formati visuali.**
Le etichette identificano senza descrivere («Segnaposto A»), che è l'unica scelta
che non regala la risposta. Ma **chi usa un lettore di schermo non può rispondere
a una carta muta**, e vale già per grafici e circuiti. Va deciso, non subìto.

---

## Coda tua — il collaudo

I mondi sono cablati ed esportati: **gioca dall'inizio senza saltare niente**.
Non serve arrivare in fondo al primo giro — quello che cambia il lavoro si vede
nei primi sei mondi. È anche l'unico modo per giudicare ciò che nessuna misura
raggiunge.

In ordine di quanto cambiano il lavoro dopo:

1. **Il ritmo dei dialoghi.** Tre schermate sono troppe? I tic diventano
   tormentoni al terzo incontro? Gli itineranti fanno piacere o stancano? È la
   risposta che decide se riscrivo mille battute o nessuna.
2. **Il colpo 1 al mondo 5.** Ci arrivi sapendo già tutto o non capisci cosa sia
   successo? La taratura vale per tutti e sette i colpi: se sbaglia qui, sbaglia
   sei volte ancora.
3. **Il Ritrovo.** Sembra che vivano anche senza di te, o che ti aspettassero?
4. **Le missioni.** Chiedere aiuto a un personaggio è meglio che leggere un
   cartello, o è solo più lento?
5. **Nonna Ersilia e la conta.** La senti nei primi cinque minuti? Ti resta in
   testa? È la chiave del finale: se non resta in testa, il mondo 24 non ha una
   serratura.
6. **Il Tredicesimo, dal mondo 17.** Fa paura senza farti male? Ti viene voglia
   di dargli retta almeno una volta? Se sembra solo un fastidio, il colpo 5 non
   funzionerà.
7. **La durata dei minigiochi dei personaggi.** Almeno uno per ciascuna delle
   quindici meccaniche, su tablet, con gli errori prima della scoperta e la
   capacità di spiegare la strategia. Solo quei numeri decidono se un gioco debba
   aggiungersi al giro o **sostituire** una tappa di missione: la campagna sta a
   21,3 ore e nessuna voce di questo piano la allunga.

E le due prove che solo tu puoi fare: **hardware scolastico e tablet reale**
(touch, landscape e portrait, contrasto elevato, riduzione movimento).

### Le cose da guardare giocando

Sono i punti in cui una resa sbagliata non rompe niente e toglie tutto il
significato.

- **1 · la conta di nonna Ersilia** va sentita nei primi cinque minuti. È la
  tabellina del 7 e contiene il nome del Tredicesimo. Se il giocatore la salta,
  al mondo 24 non ha la chiave in mano.
- **8 · il sigillo**: tredici alloggiamenti, undici nomi. Il dodicesimo è
  raschiato e **i graffi vanno verso l'interno** — l'ha fatto qualcuno seduto al
  tavolo. Senza la direzione dei graffi il colpo 2 perde metà del significato.
- **10 · la dispensa**: è il primo posto in cui il gioco dice esplicitamente che
  **non è morto nessuno**. Non è una scena di abbandono: è di preparazione.
- **11 · le due datazioni**: nessuna va bruciata, e la resa non deve suggerire
  quale sia «quella giusta».
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
- **19 · `chiude`**: una porta della nave sigillata per un livello, e **deve
  esistere sempre una strada alternativa**.
- **20 · la curva**: le misure della quarantena stanno piatte per trecentonovanta
  anni e si alzano **poco prima** che Eli arrivi, non da quando è arrivata. È la
  differenza fra «è colpa tua» e «stava già cedendo», e il gioco dice la seconda.
- **21 · la tesi**: in fondo al foglio ci sono **due mani diverse**. «Allora
  bisogna smettere» e, di traverso, «oppure imparare meglio».
- **23 · il registro**: nella colonna delle perdite non c'è niente. Meridiana non
  è mai stata registrata come perduta, e questo è il punto.
- **Il mondo 24 · Cuore dei Primi.** Non ha residenti suoi: convergono i sei
  itineranti e i residenti portati allo stadio 2, massimo quattro in scena per
  volta. Due vincoli tenuti da `finale_content_audit`: **il Cuore non è mai
  vuoto** — con zero residenti allo stadio 2 ci sono comunque i sei itineranti,
  perché un finale che premia con la solitudine è una punizione travestita da
  conseguenza — e **nessuna battuta nomina chi non è venuto**. Il tredicesimo
  posto (`FinaleCatalog.CATTEDRA`) si assegna **dopo il nodo di sintesi**: va a
  chi l'ha risolto, non a chi è arrivato.

---

## La lista del 24 luglio

`elementi da correggere.txt` è l'unica lista scritta da te, e finora questo piano
non l'ha mai riconciliata. Ecco dove sta ogni punto, così non resta sospeso per
omissione. **La colonna «tenuto da» distingue ciò che una guardia protegge da ciò
che è stato fatto e può tornare indietro senza che nessuno se ne accorga.**

| | punto | stato | tenuto da |
|---|---|---|---|
| 1 | elementi grafici fuori contesto nei mondi | fatto con gli atlanti identitari e i 72 edifici | `tavole_guard_audit` — ma «fuori contesto» è un giudizio: **da confermare giocando** |
| 2 | fiumi con sorgente e foce, ponti da costruire | chiuso il 28 agosto | registro |
| 3 | la sfera completata sparisce anche graficamente | fatto: un incontro in `completedEncounterIds` non viene più disegnato sulla mappa | nessuna guardia dedicata |
| 4 | la risposta giusta non sempre la prima | chiuso | `bank_scorciatoie_audit`, che misura posizione, lunghezza ed eco |
| 5 | elementi grafici che sembrano importanti e non servono | chiuso con C-ART-10: l'alone pulsante è stato tolto dalla scenografia, perché è il segno con cui il gioco dice «qui c'è qualcosa» | registro, `tavole_guard_audit` |
| 6 | equipaggiamento indispensabile (torcia, falce) | **ritirato** con G-4, tua decisione del 21 agosto: chiedono una resa che non esiste, e venderli prima sarebbe il difetto del 6 agosto ripetuto | — |
| 7 | personaggi nemici per livello | chiuso: Sbiaditi e pattuglie | `eli_enemy_audit` |
| 8 | sprite del personaggio di qualità AAA | fatto per l'arte statica (9 tavole di Eli); **il movimento non è stato né rifatto né misurato** | — · **resta da giudicare giocando** |
| 9 | niente ricompense sugli errori, energia per entrare | chiuso | decisione 11, `exercise_exit_audit` |
| 10 | qualità delle domande tarata per livello | chiuso, e dall'8 settembre su **otto fasce** invece di quattro bande | decisione 16, `world_difficulty_curve_audit`, `difficulty_bands_audit` — ma la fascia di due terzi degli item la sceglie un'euristica: **G-C12** |
| 11 | esercizi come minigiochi, non solo scelta multipla | **quasi chiuso nell'esame** (70% «manipola» su dodici materie su dodici); resta il mondo | `gesto_audit` — oggi **rosso su italiano/mondo** (R-18) |
| 12 | elementi sopra la mappa integrati col livello | fatto con le tavole di terreno e i landmark | `tavole_guard_audit` |
| 13 | gli esercizi indagano ma non insegnano | chiuso: NORA (294 voci), il Manuale e le dieci figure | `nora_spiegazione_utile_audit`, `explanation_coverage_audit` — R-3 chiusa il 4 settembre |

---

## Il contratto della spiegazione

Quattro regole. Valgono per ogni riga scritta da qui in avanti — per NORA, per i
banchi, per il manuale — e non si negoziano.

1. **Non ripetere quello che il bambino ha appena scritto.** La spiegazione
   comincia dove finisce la risposta. Se la si può leggere senza sapere che cosa
   è stato risposto e resta vera e utile uguale, è una spiegazione; se ripete la
   risposta, è un'eco.
2. **Parlare dell'errore fatto, non dell'errore in generale.** Quando il gioco sa
   quale alternativa è stata toccata, la prima riga è su quella.
3. **Mai due volte la stessa frase nella stessa sessione.** Una riga detta è
   detta. La seconda volta si tace o si dice la cosa successiva — non si
   parafrasa: la parafrasi è la stessa tappezzeria con parole diverse.
4. **Concreto prima di astratto.** Prima la cosa che si può vedere o contare, poi
   il nome che ha. Nessuna spiegazione può nominare due categorie grammaticali
   che non ha mostrato.

E una quinta per chi scrive le guardie, che viene da un errore già pagato:
**nessuna lista di parole può giudicare la qualità di una spiegazione.**
`ha_causa()` va bene per *scegliere* se aggiungere una riga; usata come giudice
ha bocciato trenta voci fra le migliori. La guardia misura ciò che è misurabile
davvero — ripetizioni, consegne, coperture — e lascia il giudizio a chi legge.

---

## Chi fa cosa

| | Claude | Codex | Tu |
|---|---|---|---|
| Codice, contenuti, regole di gioco e audit | ✅ | | |
| **Arte generativa, scena e resa visiva** (voci `C-`) | | ✅ | |
| **Giudizio su bellezza, ritmo, divertimento** | | | ✅ |
| **Prova su tablet reale e hardware scolastico** | | | ✅ |
| Decisioni di prodotto aperte (D-1, D-2, D-3) | | | ✅ |

Difficoltà e progressione sono file di Codex. Con due agenti sullo stesso albero:
**mai `git add -A`** — si committa per nome e si legge il diff.

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
- **Due guardie che misurano la stessa cosa con due premesse diverse non si
  annullano, si alternano**: vince quella che gira per ultima, e il rosso sembra
  un difetto del contenuto invece che del metro.

---

## Decisioni vincolanti

Una proposta che le contraddice va discussa, non implementata.

1. **Fascia 10–13 anni.**
2. **Dodici materie obbligatorie**: 24 mondi = 12 materie × 2.
3. **Si sale di livello con tutte e dodici le materie, e si finisce il gioco con
   dodici.** Il passaggio di livello si basa su padronanza, copertura e
   ritenzione, non sul conteggio delle missioni. **Aggiornata l'8 settembre
   2026**: il nucleo non è più «tre materie con la soglia più alta» ma una
   gerarchia a **tre fasce di priorità**, dichiarata in `apparatus_config.gd` e
   tenuta da `subject_priority_audit`.

   | fascia | materie | quota di sforzo e di voto | esercizi per sessione | bonus di soglia al mondo 24 |
   |---|---|---:|---:|---:|
   | 1 | matematica, inglese, italiano, **coding** | **50%** | 6 | +0,08 |
   | 2 | fisica, geografia, **latino**, **storia** | **35%** | 4 | +0,04 |
   | 3 | musica, elettronica, **scienze**, **logica** | **15%** | 2 | — |

   **Aggiornata il 10 settembre 2026**: le fasce erano 3+3+6 con sessioni 6/5/1,
   e sei materie si liquidavano in **un** esercizio. Con dodici materie divise
   **4+4+4** la lunghezza 6/4/2 dà 24/16/8 = 50,0% / 33,3% / 16,7%, cioè le
   stesse quote senza nessuna sessione da una domanda. **Chi occupa i posti l'ha
   deciso la capienza dei banchi**, non la didattica: il quarto posto del nucleo
   vuole sei esercizi per sessione, e solo coding, fisica e geografia ci
   arrivavano con poche decine di item. Il giro completo passa da 39 a **48**
   esercizi. Vedi **G-17**, chiusa.

   Le quote valgono ±5 punti, sono verificate sugli esami *costruiti davvero* —
   non solo sulle costanti — e il voto è pesato: nove risposte su tredici passano
   se valgono, non passano se sono tutte di terza fascia. **Tutte e dodici
   restano nel gate**: l'audit lo verifica esplicitamente, perché una fascia al
   15% assomiglia molto a una materia facoltativa e non deve diventarlo.

   I bonus di soglia crescono lungo la scala e sono **nulli al mondo 1**: al
   primo mondo il nucleo chiede quanto le altre, altrimenti si ripete il difetto
   del 26 agosto (mondo 1 impossibile, non difficile, per chi risponde giusto
   sette volte su dieci).
4. **Un mondo è un LIVELLO, non una materia**: ogni mondo ha una materia in focus
   e missioni di tutte e dodici le materie.
5. **Rivisitazioni = ripasso mirato.** Consolidato = 3 corrette in sessioni
   distinte, con ≥ 3 giorni fra la prima e l'ultima.
6. **Scelta multipla: tetto 33%, target ~20%.** Misurato oggi: il mondo intero
   sta fra il 18,4% e il 31,8% per materia; **l'esame no** — vedi G-C2.
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
    Due formati liberi: `numeric_input` per i numeri, `short_answer` per le
    parole — quest'ultimo accetta le varianti dichiarate in `accept`, perché
    segnare sbagliata una risposta giusta è il modo più veloce per far smettere
    di provare. Il tetto del 30% dice l'altra metà: oltre, il banco diventa un
    dettato. Tenuto da `free_answer_audit`.
11. **Da una prova si esce sempre, e uscire costa** (4 agosto 2026). La porta
    chiede conferma a due tocchi e costa 3 energie — quanto l'ingresso — e
    l'energia della prova non consegnata non arriva: senza prezzo, uscire e
    rientrare sarebbe il modo più veloce di ripescare domande finché non capitano
    le facili. Con zero energia si esce lo stesso, e gli argomenti visti restano
    nel Codex. Tenuto da `exercise_exit_audit`.
12. **Il Custode avanza in carattere, mai in potere** (4 agosto 2026). Nessun
    aiuto, nessun indizio, nessuna energia, nessuno sconto sul gate: nel momento
    in cui il compagno diventa utile il bambino comincia a ottimizzarlo, e un
    compagno ottimizzato non è più un compagno. Include lo starnuto al terzo
    errore sullo stesso argomento — non aiuta, e NORA non lo commenta — e la
    lettura del mondo (*curioso* su un incontro non esplorato, *attento* vicino a
    uno Sbiadito): atmosfera, non informazione. Tenuto da `pet_advanced_audit`,
    `pet_struggle_relief_audit` e `pet_world_awareness_audit`.
13. **Il diario racconta, non giudica** (5 agosto 2026). Mostra giorni giocati,
    prove superate e cosa sai adesso; non mostra percentuali di errore, non mette
    le materie in classifica e non dà obiettivi. **I giorni giocati sono
    cumulativi e non scendono mai**: una serie che si azzera è una minaccia sul
    domani, non un resoconto di ieri. `streak` resta nello schema e non si
    mostra. Tenuto da `diary_audit` e `diary_panel_audit`.
14. **Una chiave del salvataggio senza lettori è un errore** (5 agosto 2026). Lo
    stesso difetto si è ripetuto quattro volte: `gifts`, `daily`, `modules` e i
    segnali `near_unexplored`/`near_faded` erano dichiarati insieme al progetto e
    costruiti solo a metà. `save_schema_audit` pretende che ogni chiave compaia in
    almeno un file di produzione fuori dalla dichiarazione: le fixture non
    contano — `modules` stava in sette audit e in zero righe di gioco.
15. **La potenza vale contro il Silenzio, mai contro una domanda** (13 agosto
    2026). Serie e moduli moltiplicano o aiutano sulla **mappa**, e non toccano
    mai mastery, copertura, ritenzione, gate o esami. Nel momento in cui una di
    queste sfiorasse una prova, il gioco comincerebbe a vendere l'apprendimento.
    `combo_audit` non la verifica rileggendo il codice: registra due volte gli
    stessi esiti con energie diversissime e pretende la **stessa** padronanza e lo
    **stesso** conteggio di gate.
16. **Ogni mondo ha il proprio livello di difficoltà** (4 settembre 2026,
    **riscritta il 9 settembre 2026**). Due assi distinti, e confonderli è il
    modo più veloce di rompere la curva:

    - la **fascia di contenuto** vale 1..8 e dice quanto è avanzato l'argomento.
      `ContentManager.DIFFICULTY_BANDS = 8`, `target_difficulty(livello) =
      1 + (livello−1)/3`: **otto fasce da tre mondi ciascuna**. Erano quattro
      bande disuguali (1–4, 5–10, 11–17, 18–24) fino all'8 settembre;
    - il **gradino di sfida** resta 1..24 (`challenge_level`) e guida valori,
      numero di passaggi, scaffolding e maturazione dei formati.

    La selezione ammette ±1 fascia attorno a quella del mondo, per riscaldamento,
    finale e ripasso: sulla scala a otto quella tolleranza vale ora un terzo di
    quanto valeva sulla scala a quattro. Guardia: `difficulty_bands_audit`, che
    verifica la mappatura mondo→fascia, che ogni materia abbia in ogni fascia
    almeno gli item per una sessione, e che missioni ed esami *costruiti davvero*
    restino nella finestra.

    Quota di riconoscimento e pesi dei formati cambiano
    a ogni mondo. È ammesso un piccolo scostamento fra mondi vicini, dovuto alla
    materia, al formato o al ripasso mirato; non sono ammesse inversioni marcate.
    `world_difficulty_curve_audit` campiona gli esercizi realmente serviti e
    tollera una sola inversione locale fino a 0,35 punti. **Mastery ed esperienza
    non adattano la difficoltà**: lo studente deve padroneggiare il livello del
    mondo per accedere al successivo.

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
- **Nessuna voce di questo piano allunga la campagna.** 21,3 ore misurate: chi
  aggiunge qualcosa che costa tempo lo misura con `time_cost_probe` prima e dopo.
- **Ogni atlante nuovo si dichiara in MB prima di essere generato**, e il conto
  dei nodi si fa prima, non dopo.

---

## Rischi noti

1. **Nessun bambino ha mai giocato.** Tutte le misure sono strutturali: dicono
   che l'esperienza è corretta, varia e onesta, non che è bella. La build è
   esportata e giocabile: da qui in poi questo rischio si chiude solo giocando, e
   ogni giorno che passa senza collaudo è lavoro fatto su un'ipotesi.
2. **L'export invecchia più in fretta del codice.** Nulla di quanto scritto oggi
   è giocabile finché non si esporta. Al 9 settembre `audit:web` è **verde**
   (`2026.09.09-web-loader-1`): la build spedita è HEAD, e R-1 resta chiusa.
3. **Il mondo 1 ha sfondato il budget del tempo, non quello dei nodi.** 2553/3500
   nodi — praticamente fermi — ma **546–691 ms su 500**. Era 392 ms il 4
   settembre e 311 prima ancora, e nessun lotto ha mai scritto quando saliva. È
   R-17. Prima di aggiungere qualcosa al mondo 1, misurare; e prima di togliere,
   verificare che il costo sia nella scena e non nella lettura dei banchi.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con poco
   margine. Un rosso va sempre riverificato in isolamento — cosa che per R-17 è
   stata fatta, due volte, con la macchina ferma.

   Vale anche il rovescio, ed è la lezione del 4 settembre: **un cricchetto più
   stretto del proprio rumore di misura non è un cricchetto.** Prima di credere a
   un rosso su una soglia, rieseguire cambiando solo il seme: se il numero si
   muove più della tolleranza, il difetto è nel metro. `gesto_audit` ci ha messo
   tre giorni a mostrarlo.

   Misurato lo stesso giorno: lo stesso mondo 1, stesso commit, **457 ms a
   macchina scarica e 512 ms con altri Godot in giro**. Cinquantacinque
   millisecondi di differenza su un budget da 500 — cioè l'11% — che non hanno
   niente a che vedere col gioco. Il conto dei nodi invece non si muove di uno:
   **quando il tempo si arrossa e i nodi sono identici, è la macchina.**

   **Corretto il 9 settembre: né quella regola né la sua prima correzione
   bastano.** In R-17 i nodi erano identici, non era la macchina — e non era
   nemmeno una regressione del mondo. Era il **primo** mondo del processo, che
   paga la compilazione degli script e il primo caricamento delle risorse: lo
   stesso mondo 1, istanziato una seconda volta, costa 294 ms invece di 759.

   **La verifica che decide, e costa un minuto:** istanziare lo stesso mondo due
   volte di seguito (`avvio_mondo1_probe.gd`). Se il secondo giro crolla, il rosso
   appartiene all'avvio del motore e togliere roba a quel mondo non serve a
   niente. Guardare solo gli altri mondi non basta: anche loro pagano il proprio
   primo caricamento.
5. **La suite non si esegue mentre l'altro lavora.** Non è una raccomandazione, è
   una misura: con quattro processi Godot in contemporanea la suite è passata da
   105 a 1295 secondi e sei audit sono arrossiti per contesa, nessuno dei quali
   toccava le cose cambiate. Un giro pulito oggi sta a **738 secondi**.
   **Regola operativa:** chi sta per lanciare `npm run audit:godot` lo dice qui
   prima; chi vede la suite andare molto oltre la ferma. Un audit singolo
   (`node scripts/run-godot-audits.mjs <nome>`) si può sempre eseguire — è il giro
   completo che va serializzato.

6. **Un `assert` fallito costa quattro minuti, non venti secondi.** In un audit
   headless l'asserzione stampa `SCRIPT ERROR` e **interrompe `_init`**: il
   `quit(0)` in fondo non viene mai chiamato, il `SceneTree` resta vivo e il
   processo va avanti fino al timeout del runner. Quindi un audit rosso appare
   come `[TIMEOUT]` e il motivo vero sta più su nell'output. Chi indaga un
   timeout cerchi prima `Assertion failed`, e chi scrive un audit metta le
   stampe **prima** dell'assert, non dopo — altrimenti la misura che serve a
   capire il rosso non viene mai emessa.
6. **Il peso arriva su un tablet scolastico.** PCK a 79,10 MiB, pacchetto a ~132
   MB: +24% da quando il numero è stato scritto l'ultima volta, senza che nessun
   lotto lo dichiarasse.

---

## Rituale di export — cancello di ogni lotto

```powershell
git commit ...          # PRIMA il codice, da solo
npm run version:stamp   # marchia il commit appena fatto
& "%USERPROFILE%\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" `
  --headless --path godot --export-release Web ../public/godot/outdoor/index.html
npm run web:sync        # allinea build.json + sw.js e BUMPA la versione di cache
npm run audit:web       # verifica che i quattro valori combacino
npm run audit:godot
git commit ...          # secondo commit: solo build, build_version.gd, build.json, sw.js
```

**L'ordine conta, ed è il motivo di R-1.** `version:stamp` scrive il commit
corrente, quindi il commit che *porta* la build non può mai essere quello
marchiato. `audit:web` lo sa e non lo pretende: pretende che **fra il commit
marchiato e HEAD non sia cambiato nessun sorgente del gioco**. Se si esporta con
il codice ancora da committare, quella condizione è violata per costruzione e
l'audit si arrossa a ogni lotto. Due commit separati la rendono vera senza
sforzo.

Il bump di `cacheVersion` non è cosmetico: è ciò che fa scadere la cache PWA.
Senza, un tablet che ha già aperto il gioco continua a servire il PCK vecchio.

**Chi esporta lo dice esplicitamente.** Se nessuno lo dice, non è stato fatto.
