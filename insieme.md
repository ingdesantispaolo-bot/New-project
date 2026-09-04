# Eli Quest — Piano di lavoro

Aggiornato al **4 settembre 2026**. Ogni numero di questo file è stato rimisurato
oggi contro il repo: non è riportato dalla versione precedente.

**Qui c'è solo lavoro da fare.** I lotti chiusi stanno nel *Registro dei lavori*
di [docs/RELEASE_CANDIDATE.md](docs/RELEASE_CANDIDATE.md), che copre tutto fino a
oggi. Se in questo file compare la descrizione di una cosa già fatta, è un
difetto del file: il consuntivo va nel registro e la voce sparisce da qui.

Documenti autoritativi: [Visione](docs/VISIONE_DI_GIOCO.md) ·
[Design](docs/DESIGN_COMPLETO.md) · [Trama](docs/TRAMA_E_MISTERO.md) ·
[Abitanti](docs/ABITANTI_E_LUOGHI.md) · [Custode](docs/PET_CUSTODE.md) ·
[Secondo Viaggio](docs/SECONDO_VIAGGIO.md) ·
[Architettura](docs/ARCHITETTURA_FULL_GODOT.md) · [Finale](docs/FINALE_SPEC.md) ·
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

---

## Lo stato misurato — 4 settembre 2026

| | valore | dove si rimisura |
|---|---|---|
| audit Godot | **243 verdi su 244** in 572 s — rosso: `gesto_audit`, storia | `npm run audit:godot` |
| item nei dodici banchi | **3742** | `godot/data/banks/*.json` |
| voci di NORA | **256** | `nora_explanations.gd` |
| campagna | **21,3 ore** · mondo più corto 30,1 min, più lungo 69,4 min | `time_cost_probe` |
| mondo 1: nodi | **2511 / 3500** (era 2789: i nodi sono stati restituiti) | `performance_budget_audit` |
| mondo 1: avvio | **466 / 500 ms** — il 93% del budget, ed è il numero stretto | idem |
| PCK esportato | **79,10 MiB** (`index.pck`) + 14,60 MiB differito | `public/godot/outdoor/` |
| pacchetto completo su disco | **~132 MB** | idem |
| «tocca una fra N» nel mondo | 18,0%–32,0% per materia, tutte sotto il tetto | `gesto_audit` |
| «tocca una fra N» nell'esame | media **34,4%**, elettronica **63,0%**, storia fuori tetto | idem |
| ricette `compose` | **18** su sei materie (erano 7) | `format_depth_audit` |
| coppie (specialista, materia) sotto le tre ricette | **22**, a cricchetto | idem |

> **Due numeri da guardare.** L'avvio del mondo 1 è a 466 ms su un budget di 500:
> era 311 ms e nessuno ha scritto quando è salito. E il PCK è cresciuto da 63,51
> a 79,10 MiB (+24%) senza che nessun lotto lo dichiarasse — mentre la regola
> dice che ogni atlante si dichiara in MB *prima* di essere generato. La domanda
> non è quanto pesa: è quanto pesa il primo caricamento su una rete di scuola.

---

## Rosso adesso — prima di ogni altra cosa

> **Stato alla sera del 4 settembre 2026.** R-1 e R-3 sono chiuse; R-2 è chiusa
> per la parte del metro e resta aperta su **una materia sola**
> (`storia / esame`), confluita in **G-C2**. **R-4 è nuova ed è la più grave: un
> blocco vero, segnalato giocando.**
>
> La suite è passata da 242/244 a **243/244**, e da 738 a **572 secondi**: i
> quattro minuti risparmiati sono l'audit che non resta più appeso a un `assert`
> fallito (vedi *Rischi noti*, 6).

### R-4 · Cinque materie su dodici sono chiuse dalla falce, al mondo 2

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

**La correzione non è di una riga, e per questo non l'ho fatta.**
`equipment_traversal_audit` pretende che al mondo 2 esista una palestra chiusa da
uno strumento (*«manca una deviazione opzionale legata all'equipaggiamento»*),
quindi togliere il varco dalle palestre lo fa arrossire. Le due proprietà stanno
insieme solo così: **una palestra può restare chiusa purché la sua materia abbia
un altro nodo aperto nel mondo.** In pratica una passata dopo la costruzione
degli eventi che toglie il varco alle palestre la cui materia resterebbe senza
niente, più la guardia che lo tiene: *con gli attrezzi dell'arrivo, tutte e
dodici le materie devono essere allenabili in ogni mondo.* Quella misura oggi
non esiste — la sonda che l'ha trovata era usa e getta.

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

**G-C1 · Il banco di matematica è al 75% tabelline.**
285 item su 380. Gli altri sei argomenti — statistica, percentuali, geometria,
frazioni, espressioni, radici — stanno tutti a 15 o 16, cioè al minimo che
`topic_density_audit` impone. Vanno portati al livello delle altre materie,
venti-trenta per argomento, e mancano ancora i due della fascia alta:
**proporzioni ed equazioni**. Il generatore già le propone e NORA sa spiegarle; è
il banco statico a non chiederle mai. Chiuderla sblocca anche la **bilancia
dell'uguale**: la figura non esiste perché non c'è un solo item con
un'uguaglianza da bilanciare, ed è mezz'ora di lavoro il giorno in cui ce ne sarà
uno.

**G-C2 · La scelta multipla dell'esame.** ← *la prima da riprendere: ha già un
rosso attaccato*

Nel mondo intero il quadro è sano e tutte e dodici le materie stanno sotto il
loro tetto. Nell'esame no: media **34,4%**, ed elettronica al **63,0%** —
coerente col suo progetto, perché lì la scelta multipla è stata tolta da tutto il
resto e vive solo qui, ma è comunque un esame che chiede la competenza con un
gesto diverso da quello con cui l'ha insegnata.

**E c'è un rosso vivo dentro questa voce: `storia / esame` al 35,8% contro un
tetto di 32,1** (vedi R-2). Geografia e scienze la seguono a +1,9 e +2,5, dentro
solo per la tolleranza. Le tre si muovono probabilmente per la stessa causa, che
è la prima delle due qui sotto.

Le due cause sono misurate e scritte in `gesto_audit`:

1. `NONMC_FORMAT_WEIGHTS` pesa grafico, circuito e caccia all'errore (25) più di
   abbinamento, ordinamento e smistamento (20, 15, 13) — cioè favorisce i formati
   che sono a loro volta «sceglie»;
2. `formati_da_sostituire` porta fuori solo la scelta multipla: i nodi da
   digitare restano, e in logica sono il 25% dell'esame.

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

**C-R1 · Il secondo foglio di reperti.**
Serve un'immagine nuova: gli atlanti dei reperti sono `.webp`
(`artifact_atlas_catalog.gd`), oggi ce n'è **uno solo** (`roman_artifacts`), e
senza un disegno il formato non si estende oltre la storia. Conviene deciderlo
insieme a G-C5, che è il suo primo cliente.

**C-R2 · I quindici minigiochi dei personaggi hanno un asset in tutto**
(`assets/minigames/tobia-crystal-v1.png`). Le tavole vettoriali sono leggibili e
funzionano. **Aspetta il collaudo**: finché non si misura quali meccaniche
restano nel giro, illustrarle tutte e quindici è lavoro su un'ipotesi.

> **Non sono voci aperte, e non vanno riaperte per distrazione.** Le figure di
> **fisica e scienze** sono escluse per scelta: nei loro testi non c'è niente che
> si estragga con certezza in un diagramma — le conversioni di unità in fisica
> sono tre esercizi su 157 — e disegnare comunque vorrebbe dire decorare. Il
> **cono di luce della torcia** rientra solo insieme al modulo G-4, che è
> ritirato: resa e regola tornano insieme o non tornano.

### Decisioni tue

**D-1 · G-14 · `mucchio` e `prova`: si stringono?**
`minigiochi_cieco_probe` gioca ogni pannello con tocchi casuali, sessanta partite
per archetipo. Il **mucchio** è il minigioco di Tobia, il primo che un bambino
incontra al mondo 1, e la sonda lo vince nel **100% dei casi**; la sua lezione
dichiarata è «raggruppare batte contare», e raggruppare non serve. È già stato
ritarato una volta — da sei tocchi a ventiquattro — e al ritmo umano di due
tocchi al secondo resta dentro il cronometro. La **prova** dice di sé «una causa
si isola, non si indovina», e si indovinava due volte su tre.
*Da fare comunque prima di decidere: rieseguire la sonda, perché la tabella in
giro è del 21 agosto e il mucchio è cambiato dopo.*

**D-2 · C-MG-3 · La lingua della radio.**
Marea sta al mondo 4, la cui materia è inglese, e i suoi nove messaggi sono in
italiano: la meccanica è giusta, il materiale no. Passarli all'inglese cambia la
difficoltà in modo serio — cinque secondi di segnale, un bambino al quarto mondo.

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
| 10 | qualità delle domande tarata per livello | chiuso | decisione 16, `world_difficulty_curve_audit` |
| 11 | esercizi come minigiochi, non solo scelta multipla | **in corso**: è G-C2 e G-C3 | `gesto_audit` — oggi **rosso** (R-2) |
| 12 | elementi sopra la mappa integrati col livello | fatto con le tavole di terreno e i landmark | `tavole_guard_audit` |
| 13 | gli esercizi indagano ma non insegnano | chiuso: NORA, il Manuale e le dieci figure | `nora_spiegazione_utile_audit`, `explanation_coverage_audit` — oggi **rosso** (R-3) |

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
   dodici.** Italiano, matematica e inglese restano il nucleo e hanno una soglia
   di padronanza più alta; non sono però l'unico gate. Il passaggio di livello si
   basa su padronanza, copertura e ritenzione, non sul conteggio delle missioni.
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
16. **Ogni mondo ha il proprio livello di difficoltà** (4 settembre 2026).
    `ContentManager.challenge_level` espone 24 gradini distinti; le bande seguono
    1–4, 5–10, 11–17 e 18–24; quota di riconoscimento e pesi dei formati cambiano
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
   è giocabile finché non si esporta — e in questo momento la build spedita porta
   la versione sbagliata (R-1).
3. **Il mondo 1 è stretto sul tempo, non più sui nodi.** 2511/3500 nodi ma
   **466/500 ms**: il 93% del budget d'avvio. Era 311 ms e nessun lotto ha scritto
   quando è salito. Prima di aggiungere qualcosa al mondo 1, misurare.
4. **`performance_budget_audit` è fragile al carico**: misura wall-clock con poco
   margine. Un rosso va sempre riverificato in isolamento — e con 466 ms su 500,
   oggi basta poco per farlo arrossire.

   Vale anche il rovescio, ed è la lezione del 4 settembre: **un cricchetto più
   stretto del proprio rumore di misura non è un cricchetto.** Prima di credere a
   un rosso su una soglia, rieseguire cambiando solo il seme: se il numero si
   muove più della tolleranza, il difetto è nel metro. `gesto_audit` ci ha messo
   tre giorni a mostrarlo.
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
