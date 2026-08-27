# Eli Quest — Piano di lavoro

Aggiornato al 20 agosto 2026.

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

L'ordine residuo è per **resa su costo**. Le voci Codex del lotto di agosto e
quelle C-ART della lettura del 20 agosto sono uscite dal piano e stanno nel
registro.

**Il 26 agosto è arrivata una segnalazione che scavalca tutto il resto**: le
spiegazioni di NORA — il cuore della didattica, cioè la ragione per cui questo
gioco esiste. Le otto voci **G-N** e **C-N** della lettura di quel giorno stanno
più sotto e vengono prima di ogni altra cosa in questo file.

| | voce | impatto | costo | chi |
|---|---|---|---|---|
| **G-N1…N8 · C-N3, C-N5** | [Le spiegazioni di NORA](#le-spiegazioni-di-nora--la-lettura-del-26-agosto-2026) | il cuore | vario | Claude + Codex |
| **G-4** | Collegare i due moduli alla resa C-G4 | basso | basso | Claude |

---

## Le spiegazioni di NORA — la lettura del 26 agosto 2026

*Segnalazione dello studente: «le spiegazioni servono a poco, ci sono molte
scritte inutili e ripetute, poca sostanza e poca chiarezza, non è adatta a un
bambino di undici anni».*

Stessa lettura del 14 e del 20 agosto, applicata alla didattica: non che cosa il
gioco **contiene** in fatto di spiegazioni, ma che cosa un bambino **legge**
dopo aver risposto.

Il gioco ha molte spiegazioni: **3569 item, tutti con la loro `explanation`**,
zero vuote, più 249 voci di `NoraExplanations` che coprono tutti e 131 gli
argomenti dei banchi. Sulla carta è completo.

La misura, in una riga: **il gioco sa esattamente che errore ha fatto il
bambino, ha già scritto la frase che glielo spiega, e non gliela dice mai.** Al
suo posto gli dice la stessa riga generica che gli ha già detto due nodi fa.

Le sei misure che seguono sono state prese il 26 agosto sui banchi esportati e
sul percorso di gioco reale (`exercise_player._score_current` →
`NoraExplanations.riga`).

---

### 1. Il feedback più personale che il gioco possiede non arriva mai

**3082 item su 3569 (86%) portano `distractorWhy`**: per ogni alternativa
sbagliata, la frase che dice perché *quella* è sbagliata — calcolata al bake sui
dati veri dell'item, nella lingua della sua materia. È il pezzo di didattica più
costoso che abbiamo prodotto in due mesi.

In tutto Godot `distractorWhy` compare in **due** file: `knowledge_codex.gd` e
un audit. **Nel percorso della prova non entra.** `riga()` riceve materia,
argomento, spiegazione ed esito — non riceve *che cosa il bambino ha toccato*.

E nel manuale, dove pure entra, `_typical_error()` prende **il primo distrattore
diverso dalla risposta**, non quello scelto: mostra l'errore di qualcun altro.

Un bambino tocca «il salvavita scatta perché la corrente è troppa». La frase
«scatta quando la corrente torna indietro da un'altra strada, non quando è
troppa» è già scritta, già collaudata, già dentro il PCK che ha sul tablet. Lui
legge: *«Non ha ancora funzionato»* e una massima generale sull'elettricità.

### 2. Una riga per argomento, ripetuta per tutta la sessione

`NoraExplanations.VOCI` scrive il perché **una volta per argomento** — scelta
giusta quando è stata presa, venticinque volte meno lavoro degli item e nessuna
deriva fra copie. Ma un argomento ha in media 27 item, e `matematica:tabelline`
ne ha **284**.

Su una risposta giusta NORA aggiunge il `perche` dell'argomento in **3073 item
su 3569 (86%)** — cioè quasi sempre — e in tutti e 3073 i casi è **letteralmente
la stessa frase**. Chi fa tabelline legge *«Moltiplicare serve a non contare uno
per uno: è la scorciatoia per i gruppi uguali»* fino a 284 volte.

E non è diluita nel tempo: `LESSON_TOPIC_SHARE = 0.67` riserva **due nodi su
tre** agli argomenti promessi dalla lezione del mondo. La stessa riga torna
nella stessa sessione, a un minuto di distanza.

Sull'errore è peggio, ed è un bug vero: in `riga()` il controllo `ha_causa` è
applicato **solo nel ramo `corretto`**. Il `come` si attacca sempre, anche
quando la spiegazione dell'item ha già detto la stessa cosa.

> Una riga ripetuta non è neutra: **insegna a saltarla.** Dopo la terza volta il
> bambino ha imparato che sotto l'esito non c'è mai niente di nuovo, e da lì in
> poi non legge più nemmeno le spiegazioni buone.

### 3. Un terzo delle spiegazioni riapre con la risposta appena data

**1159 item su 3569 (32%)** — 833 di inglese e 326 di italiano — hanno tutti la
stessa forma:

```
Q:  Come si dice in inglese: "controllare"?
R:  check
S:  "check": controllare. Stesso gruppo: press = premere, open = aprire.
```

La prima metà **ripete la risposta che il bambino ha appena scritto**. La
seconda elenca due vicini di lista: non sono un campo semantico, sono le due
voci successive nell'array sorgente — *press* e *open* stanno lì perché stanno
lì, non perché abbiano a che fare con *check*.

Su mille item di inglese, ottocentotrentatré fanno così. È il blocco singolo più
grosso di tutto il gioco, ed è il più vicino allo zero didattico: costa una riga
di lettura e non lascia niente.

### 4. Le code generate

Frasi identiche a meno dei numeri, contate sulle 3569 spiegazioni:

| ripetizioni | frase |
|---|---|
| **254** | `cambiare l'ordine non cambia il prodotto.` |
| **108** | `Qui la tabellina si legge al contrario: …` |
| **91** | `cerchi quante volte il N sta dentro M.` |
| **57** | `Dividere è l'inverso del moltiplicare: …` |
| 14 | `Anche le altre sono avvertenze giuste, ma riguardano un altro argomento.` |

La proprietà commutativa è vera e vale la pena dirla. Detta **254 volte nella
stessa identica forma** non è didattica, è tappezzeria. La coda commutativa è
precedente; **le due code da 108 e 57 le ho aggiunte io** nel giro sulle
tabelline del 25 agosto, ed è debito mio.

### 5. Non è la leggibilità, e va scritto per non inseguirla

Indice **Gulpease** su tutte le 3569 spiegazioni (≥60 = leggibile alla scuola
media; sotto 40 = difficile anche per un diplomato):

```
mediana 90  ·  sotto 60: 91 item (3%)  ·  sotto 40: nessuno
```

Le frasi sono corte e le parole sono comuni. **Semplificare non è la cura** — e
chi partisse da qui riscriverebbe tremila righe già a posto senza spostare la
lamentela di una virgola.

Le peggiori dicono qual è il difetto vero, che è un altro:

> *«Nel periodo ipotetico della possibilità la condizione va al congiuntivo
> imperfetto e la conseguenza al condizionale presente.»* (Gulpease 43)

Non è difficile perché è lunga. È difficile perché è **la voce del libro di
grammatica**, copiata: nomina quattro categorie e non ne spiega nessuna. Un
undicenne che sapesse già che cosa sono «periodo ipotetico della possibilità» e
«congiuntivo imperfetto» non avrebbe sbagliato la domanda.

### 6. Non c'è nessuna grafica: è una `Label`

`exercise_player.gd:505`. Il pannello della spiegazione è una `Label` a testo
semplice. Niente grassetto, niente struttura, niente figura, un solo colore per
esito (verde o rosa).

Dentro ci finiscono attaccati con un a capo, **tutti con lo stesso peso
visivo**:

```
Funziona! +12 energia · serie ×3
Se non ricordi 7 × 8, per 8 raddoppi tre volte: 7 → 14 → 28 → 56. E 8 × 7 dà
lo stesso risultato: cambiare l'ordine non cambia il prodotto.
Moltiplicare serve a non contare uno per uno: è la scorciatoia per i gruppi
uguali.
```

Tre cose di natura diversa — la ricompensa, il caso particolare, la regola
generale — indistinguibili l'una dall'altra. E il pulsante `CONTINUA` compare
**nello stesso istante** in cui compare il testo: la strada più rapida
attraverso il gioco è non leggere.

Una moltiplicazione è una griglia. Una frazione è una torta tagliata. Un
circuito è un anello che si chiude. Una declinazione è una parola smontata in
due pezzi. **Il gioco ha 71 oggetti identitari illustrati e otto atlanti di
scenografia, e zero disegni che spieghino qualcosa.**

---

## Il contratto della spiegazione

Quattro regole. Valgono per ogni riga scritta da qui in avanti — per NORA, per i
banchi, per il manuale — e non si negoziano.

1. **Non ripetere quello che il bambino ha appena scritto.** La spiegazione
   comincia dove finisce la risposta. Se la si può leggere senza sapere che cosa
   è stato risposto e resta vera e utile uguale, è una spiegazione; se ripete la
   risposta, è un'eco.

2. **Parlare dell'errore fatto, non dell'errore in generale.** Quando il gioco
   sa quale alternativa è stata toccata, la prima riga è su quella. Il generico
   viene dopo, o non viene.

3. **Mai due volte la stessa frase nella stessa sessione.** Una riga detta è
   detta. La seconda volta si tace o si dice la cosa successiva — non si
   parafrasa: la parafrasi è la stessa tappezzeria con parole diverse.

4. **Concreto prima di astratto.** Prima la cosa che si può vedere o contare,
   poi il nome che ha. `docs/VOCE_11_ANNI.md` lo dice già per l'interfaccia: qui
   vale doppio. Nessuna spiegazione può nominare due categorie grammaticali che
   non ha mostrato.

Una quinta regola per chi scriverà la guardia, e viene da un errore già pagato:
**nessuna lista di parole può giudicare la qualità di una spiegazione.**
`ha_causa()` va bene per *scegliere* se aggiungere una riga, dove sbagliare
costa una riga in più; usata come giudice ha bocciato trenta voci fra le
migliori. La guardia misura ciò che è misurabile davvero — ripetizioni,
consegne, coperture — e lascia il giudizio a chi legge.

---

## Le voci

Ordinate per resa su costo. **G-** sono di Claude (contenuto, logica, guardie),
**C-** di Codex (resa, pannello, figure). Le due colonne non si bloccano a
vicenda: G-N1 e G-N2 valgono anche sulla `Label` di oggi, C-N3 vale anche sulle
spiegazioni di oggi.

> **Fatte il 26 agosto 2026, tutte e otto.** Codex non era disponibile, quindi le
> due voci **C-** le ha prese Claude. Sotto resta la descrizione originale di
> ognuna; qui il consuntivo, con le misure prima e dopo.
>
> | | voce | esito |
> |---|---|---|
> | **G-N1** | `distractorWhy` consegnato | **9244 frasi su 9244** arrivano a chi tocca quell'alternativa. Prima: zero |
> | **G-N2** | NORA non si ripete | memoria di dodici righe + voci a livelli. Venti prove di fila sullo stesso argomento: **zero ripetizioni** |
> | **C-N3** | Pannello a tre zone | `RichTextLabel`, correzione in grassetto, regola staccata e firmata, `CONTINUA` dopo mezzo secondo |
> | **G-N4** | Le 1159 glosse | riscritte: **dal 32% al 3,3%** le spiegazioni che riaprono con la risposta |
> | **C-N5** | Le figure | **dieci** famiglie, su 656 esercizi |
> | **G-N6** | Le code generate | la frase più ripetuta scende **da 254 a 91**, e le 91 hanno numeri diversi |
> | **G-N7** | Il riferimento | «SPIEGA CON NORA» ora c'è anche dopo una risposta giusta |
> | **G-N8** | La guardia | `nora_spiegazione_utile_audit`, cinque misure, tetto a cricchetto |
>
> **Completato il 27 agosto.** Le due code dichiarate il giorno prima sono
> chiuse.
>
> **Le figure sono dieci, su 656 esercizi**: griglia dei gruppi 290, linea del
> tempo 115, carta muta 58, parola smontata 50, retta dei numeri 43, due cerchi
> 34, torta tagliata 23, anello del circuito 22, i sei casi latini 12, contorno
> contro superficie 9.
>
> Una sostituzione nell'elenco, e va detta: **la bilancia dell'uguale non c'è, e
> al suo posto ci sono i sei casi latini.** Il piano la contava su «equazioni,
> uguaglianze, 60+ esercizi», ma quegli esercizi nel banco **non esistono**: la
> matematica ha `espressioni`, non `equazioni`, e nessun item contiene un'uguaglianza
> da bilanciare. Una figura che non si accende su niente è codice morto con una
> bella spiegazione sopra. I dodici item di `latino:casi` invece esistono, e la
> tabella dei sei casi è la cosa che ogni libro di latino ha in prima pagina e che
> il gioco non mostrava mai. Quando le equazioni entreranno nel banco, la bilancia
> è mezz'ora di lavoro.
>
> La carta muta non è disegnata a mano: viene da `MapGeometryCatalog`, la stessa
> geometria Natural Earth che il gioco usa già per le carte mute. Una sola fonte,
> così due parti del gioco non possono disegnare due Europe diverse.
>
> **Le glosse: l'etimologia c'è dove si può dedurre, e non oltre.** 109 item
> inglesi dicono adesso la parentela fra le due lingue — «le prime 5 lettere di
> *insert* e *inserire* sono le stesse: è la stessa parola arrivata per due
> strade», e le due regole vere (-tion → -zione, -ty → -tà) che valgono anche su
> parole mai viste. Mai sui falsi amici, dove la somiglianza *è* la trappola e le
> 29 voci portano già la loro nota scritta a mano.
>
> Resta fuori quello che si può solo scrivere a mano: «quando NON si usa» e la
> parola dentro un'altra che il bambino già conosce. Sono circa settecento voci di
> lessico, ed è lavoro di scrittura, non di codice.
>
> **Una cosa che l'audit ha ripreso al volo.** La frase sulla parentela, scritta
> come «*insert* e *inserire* sono la stessa parola», apriva con la risposta appena
> data: l'eco era risalita dal 3,3% al 4,8% — il difetto appena chiuso, rientrato
> da una porta laterale. Riscritta partendo dall'osservazione invece che dalla
> parola, è tornata al 3,3%.

| | voce | impatto | costo | chi |
|---|---|---|---|---|
| **G-N1** | Consegnare il `distractorWhy` che è già scritto | altissimo | basso | ✅ |
| **G-N2** | Non ripetersi dentro la sessione | alto | basso | ✅ |
| **C-N3** | Il pannello a tre zone | alto | medio | ✅ |
| **G-N4** | Le 1159 glosse di inglese e italiano | alto | medio | ✅ |
| **C-N5** | Le dieci figure che spiegano | alto | alto | ✅ 10, su 656 esercizi |
| **G-N6** | Le code generate | medio | basso | ✅ |
| **G-N7** | Il riferimento: dove ritrovare la cosa | medio | basso | ✅ |
| **G-N8** | La guardia | — | medio | ✅ |

---

### G-N1 · Consegnare il `distractorWhy` che è già scritto

Il lavoro è fatto: 3082 item ce l'hanno. Manca il filo.

- `riga()` prende un argomento in più: l'opzione toccata. Se
  `distractorWhy[scelta]` esiste, **quella è la prima riga dell'errore** — prima
  della spiegazione dell'item e al posto del `come` generico.
- `_score_current` e `_retryable_result` conoscono già la scelta e la passano.
- `_typical_error()` nel manuale smette di prendere il primo distrattore
  disponibile e prende quello sbagliato davvero, quando lo sa.
- Dove `distractorWhy` manca (487 item, il 14%) resta il comportamento di oggi.

Da misurare dopo: quanti errori nel gioco reale ricevono una frase specifica
invece di una generica. L'obiettivo è **oltre l'80%**, ed è già pagato.

### G-N2 · Non ripetersi dentro la sessione

- Un insieme di righe già dette, per sessione. Detta una volta, non torna.
- `ha_causa` applicato **anche al ramo dell'errore**: è un bug di due righe.
- La seconda volta che un argomento torna, NORA **non parafrasa**: tace. Il
  silenzio è informazione — vuol dire *questa la sai*.
- Le voci che coprono argomenti da cinquanta item in su hanno bisogno di più di
  un `perche`: non sinonimi dello stesso, ma **livelli** — il primo incontro, il
  caso che di solito frega, il collegamento con un altro argomento. Nove
  argomenti stanno sopra i cinquanta item e valgono da soli un migliaio di item.

### C-N3 · Il pannello a tre zone — *Codex*

Oggi: una `Label`, tre contenuti diversi appiattiti in un blocco solo,
`CONTINUA` acceso subito.

Serve una struttura che si legga **senza leggere**, cioè in cui si capisca a
colpo d'occhio dove guardare:

1. **L'esito** — riga breve, il colore che c'è già, l'energia. È l'unica parte
   che oggi funziona.
2. **La correzione** — *qui sta la cosa nuova.* Sull'errore: che cosa è stato
   toccato e perché non va (G-N1). Sul giusto: il caso svolto. Deve essere la
   zona **visivamente dominante** — peso maggiore, contrasto maggiore, spazio
   maggiore. Oggi ha lo stesso peso della ricompensa.
3. **La regola** — la riga di NORA, quando c'è. Secondaria, staccata,
   riconoscibile come «la voce di NORA» e non come altro testo.

Tre cose che servono e che oggi non ci sono:

- **`RichTextLabel` al posto di `Label`**, per dare grassetto al pezzo che conta
  e per ospitare la figura di C-N5 dentro il testo;
- **`CONTINUA` non compare nell'istante zero.** Non un timer punitivo: un
  ritardo breve, o meglio il pulsante che si accende quando la zona 2 ha finito
  di comparire. Chi ha già capito non deve aspettare, ma non deve nemmeno poter
  saltare la correzione prima che esista;
- **lo spazio deve reggere il testo lungo.** Con G-N1 e C-N5 la zona 2 cresce:
  va verificato su tablet, in verticale, con `reducedMotion` attivo.

Valgono i tre vincoli delle tavole: nessun testo dentro un'immagine, il conto
dei nodi si fa prima, il peso si dichiara in MB.

### G-N4 · Le 1159 glosse di inglese e italiano

833 di inglese e 326 di italiano, tutte nella forma `"parola": traduzione.
Stesso gruppo: …`. Sono un terzo delle spiegazioni del gioco.

La forma va rifatta nel generatore, non a mano. Quello che una glossa può dire e
oggi non dice:

- **da dove viene la parola** — *check* e *scacchi* sono la stessa parola, dallo
  scacco matto: il re è «controllato». Il latino ce l'ha già e funziona benissimo
  («da *aqua* vengono acquedotto e acquario»);
- **il falso amico o la trappola** — *library* non è la libreria, *sensible* non
  è sensibile. Sono le uniche cose che un bambino si ricorda di una glossa;
- **la parola dentro un'altra che già conosce** — *open* sta in *open day*,
  *free* in *wi-fi free*;
- **quando NON si usa** — *check* non traduce «controllare» nel senso di
  dominare.

Dove non c'è niente di vero da dire, **la spiegazione resta corta e onesta**:
meglio tre parole che una coda finta. Il «Stesso gruppo:» va tolto in ogni caso —
i vicini di array non sono un campo semantico, e dichiararlo è una piccola bugia
didattica.

Da fare a lotti, per campo semantico, come le materie: è il lotto più grosso ed
è quello con la resa più alta per riga scritta.

### C-N5 · Le dieci figure che spiegano — *Codex*

Non illustrazioni: **diagrammi**, cioè disegni in cui la posizione delle cose è
l'informazione. Dieci famiglie coprono la maggior parte del gioco, e ognuna
serve decine o centinaia di item:

| figura | serve a | item circa |
|---|---|---|
| la **griglia dei gruppi** (righe × colonne) | tabelline, divisioni, aree | 364+ |
| la **retta dei numeri** | ordine, negativi, frazioni, stime | 150+ |
| la **torta tagliata** | frazioni, percentuali | 120+ |
| la **bilancia** | equazioni, uguaglianze | 60+ |
| **contorno contro superficie** | perimetro e area | 80+ |
| l'**anello del circuito** aperto/chiuso, serie/parallelo | elettronica | 159 |
| la **linea del tempo** | storia | 167 |
| la **mappa muta** con un punto acceso | geografia | 199 |
| la **parola smontata** (radice + desinenza, prefisso) | latino, italiano | 200+ |
| i **due cerchi** che si incrociano o si contengono | logica, insiemi, quantificatori | 136 |

Come vanno fatte, e questo è il vincolo che le rende possibili:

- **disegnate in Godot, non esportate come immagini.** Una griglia 7×8 è
  `_draw()` con due cicli: pesa zero MB, si adatta ai numeri dell'item, e non ne
  serve una versione per ogni moltiplicazione. Vale per tutte e dieci tranne la
  mappa muta, che è una sagoma sola per continente;
- **il testo sta nei nodi, non nel disegno** — è la regola già in vigore per le
  tavole, e qui serve anche perché le etichette cambiano item per item e devono
  essere leggibili da un lettore di schermo;
- **una figura sola per spiegazione**, e solo dove aggiunge. Una figura che
  illustra ciò che il testo ha già detto è la stessa tappezzeria di prima,
  disegnata;
- **`reducedMotion` le congela**: nessuna figura che si costruisca con
  un'animazione obbligatoria da guardare.

Ordine suggerito, per resa: griglia dei gruppi, anello del circuito, retta dei
numeri. Le prime due da sole coprono cinquecento item e sono le due più facili
da disegnare.

### G-N6 · Le code generate

- La commutativa: detta **una volta per sessione** (ricade sotto G-N2), non 254.
- Le due code delle tabelline che ho aggiunto io — «si legge al contrario» e
  «dividere è l'inverso» — diventano la riga di NORA dell'argomento, che è il
  posto in cui una regola generale va detta, e spariscono dall'item.
- L'item torna a fare il suo mestiere: **il caso particolare, svolto**.

### G-N7 · Il riferimento: dove ritrovare la cosa

`SPIEGA CON NORA` esiste ma compare **solo dopo un errore**, ed è nascosto in
esame. Una spiegazione che non si può rileggere vale un solo istante.

- Il pulsante disponibile anche sulla risposta giusta: chi ha indovinato e vuole
  capire perché è esattamente il bambino da premiare.
- La voce del manuale raggiungibile **dopo** la prova, non solo durante.
- Il collegamento fra argomenti: le divisioni rimandano alle tabelline, le
  percentuali alle frazioni. `KnowledgeCodex` ha già la struttura per farlo.

### G-N8 · La guardia

`nora_spiegazione_utile_audit.gd`. Misura **solo cose misurabili**, mai la
qualità:

- nessuna riga di NORA ripetuta due volte in una sessione simulata;
- ogni item con `distractorWhy` consegna la frase giusta all'opzione giusta;
- nessuna spiegazione riapre con la risposta dell'item (la regola 1, che è
  meccanica e verificabile);
- nessuna frase-scheletro compare più di N volte sull'insieme dei banchi, con N
  a cricchetto — **si abbassa e mai si alza**, come il tetto delle scorciatoie;
- ogni figura dichiarata da un argomento esiste ed è raggiungibile.

Il cricchetto è la parte che vale: è l'unica forma che ha funzionato sul debito
delle scorciatoie, e funziona perché non chiede a nessuno di giudicare.

---

> **Nota sull'ordine.** G-N1 è la prima perché è la sola voce di tutto il piano
> in cui il contenuto **esiste già** e manca solo la consegna: due giorni di
> lavoro sui banchi che oggi non arrivano al bambino. Se se ne facesse una sola,
> è quella.

---

## La rilettura delle 249 voci — 27 agosto 2026

Fin qui le spiegazioni sono state **misurate**: consegne, echi, ripetizioni,
figure. Nessuna di quelle misure dice se una spiegazione è *chiara*, e la
segnalazione dello studente diceva anche quello. L'unico modo di saperlo è
leggerle, quindi le ho lette tutte e 249, una per una.

**Il verdetto è che il corpus regge.** La grande maggioranza è concreta, corta e
dice un perché invece di un cosa: «L'uguale è una bilancia in equilibrio», «Roma
è durata tanto perché ha assorbito i popoli che conquistava invece di
cancellarli», «Si chiama preistoria perché mancano le scritture». Non c'era da
riscrivere in blocco, e riscrivere in blocco sarebbe stato il danno.

Tredici righe però andavano toccate, e si dividono in tre classi.

### Un errore di contenuto

`fisica:temperatura` diceva: *«un ago rovente e una vasca tiepida possono avere
la stessa energia totale»*. La cosa da imparare è l'opposto ed è molto più
sorprendente: **la vasca tiepida ne contiene molta di più**, perché di particelle
ne ha molte di più. Detta come stava, la frase toglieva alla differenza fra
temperatura ed energia proprio il fatto che la rende memorabile.

### Voci che non parlavano della propria materia

`fisica:onde-luce` — venti esercizi, argomento vivo — ripeteva quasi parola per
parola `fisica:onde` e **non diceva una sola cosa sulla luce**, che è metà del suo
nome. Adesso ha due livelli, e il secondo è quello che serviva: *luce e suono sono
tutte e due onde, ma la luce non ha bisogno di niente in cui viaggiare — è per
questo che dal Sole ci arriva la luce e non il rumore*.

E tre voci vive di italiano — `verbo`, `modi-indefiniti`,
`imperativo-infinito-participio-gerundio` — insegnavano tutte lo stesso trucco,
«prova a metterci davanti io», con quasi le stesse parole. Sono argomenti
diversi, quindi impronte diverse, quindi **la memoria di NORA non le sopprimeva**:
il bambino le leggeva tutte e tre.

### Consigli che si contraddicono, o che usano strumenti inesistenti

- `inglese:data-science` e `inglese:nature-environment` dicevano «se somiglia
  all'italiano, **fidati**» — mentre `inglese:false-friends` insegna che i falsi
  amici si travestono da parole che sai già. Ora dicono *quando* fidarsi: nel
  lessico scientifico la somiglianza è affidabile perché le due lingue hanno
  preso le parole dallo stesso latino;
- `elettronica:legge-ohm` diceva «copri con un dito la grandezza che cerchi **nel
  triangolo V-I-R**», e quel triangolo il gioco non lo disegna da nessuna parte.
  Un metodo che usa uno strumento che non esiste non è un metodo;
- `inglese:comparatives` dava la regola senza il caso «-y», che è quello che
  produce «more happy»; `inglese:past-tense` diceva «una sola forma per ogni
  persona» senza nominare *was/were*, cioè il primo verbo che si impara.

Più tre righe riscritte perché erano in italiano da adulto: «quanto è plausibile
un evento fra tutti quelli possibili», «una relazione fra grandezze reali, non
un'equazione a sé stante», e una che diceva tre volte «si muovono» in una riga.

> **Una nota su che cosa è vivo.** Le voci sono 249 ma gli argomenti che i banchi
> propongono davvero sono **131**: 118 voci aspettano contenuti che non esistono
> ancora. Cinque delle tredici righe toccate stanno su argomenti vivi; le altre
> otto erano errori che dormivano. Li ho corretti lo stesso — un errore di fisica
> che aspetta di essere pubblicato è comunque un errore di fisica.

### E le correzioni: un cricchetto che proteggeva il rumore

Rileggendo anche le correzioni generate il giorno prima è saltata fuori una cosa
che la misura non poteva vedere, perché la misura le contava tutte uguali.

A «qual è il nominativo plurale di *rosa*?» era attaccato il perché di **«2»** —
vero, perché «2» è la risposta a *«quanti numeri distingue la declinazione
latina?»* — e assurdo: nessun bambino scrive «2» a una domanda su una parola. La
passata sulle domande vicine accostava numeri a parole ogni volta che capitavano
nello stesso argomento.

Adesso una correzione si attacca solo fra risposte **dello stesso tipo**: numeri
con numeri, parole con parole. Sono uscite **523 correzioni-rumore**, e quindici
esercizi sono rimasti scoperti — tutti numerici il cui argomento non ha nessun
altro numerico, quindi senza niente di vero da dire.

Quei quindici li ho scritti a mano, ed è il pezzo di questa giornata che vale di
più, perché nessun generatore ci sarebbe arrivato. Puntano alla confusione
classica dell'argomento:

> *«In una catena erba → cavalletta → rana → serpente, quanti passaggi?»* — chi
> scrive **4** legge: «quattro sono gli esseri viventi; i passaggi sono le frecce
> fra loro, e le frecce sono tre».
>
> *«Quanti casi ha una declinazione?»* — chi scrive **5** legge: «cinque sono le
> declinazioni, non i casi: sono due conti diversi che si scambiano facilmente».
>
> *«Il tuono arriva dopo 3 secondi, quanti chilometri?»* — chi scrive **340**
> legge: «sono i metri che il suono percorre in UN secondo».

> **Il cricchetto è stato ritarato, e va detto perché.** Le frasi di correzione
> erano 15015 e sono scese a **14537 migliorando**. Un pavimento su un numero che
> conta anche il rumore **protegge il rumore**: quando si scopre che lo faceva, il
> numero si ritara e si scrive la ragione accanto. È l'unica eccezione onesta alla
> regola del «mai in giù», e si usa solo con la misura in mano.

### La guardia che ne è nata

`nora_spiegazione_utile_audit` ha una misura in più: **due argomenti vivi non
possono dire quasi la stessa cosa con le stesse parole**. Confronta l'ossatura
delle righe (via le parole corte) e si arrossa sopra il 60% di parole condivise.

Non giudica la qualità — non potrebbe, ed è la regola che vale da sempre qui — fa
la domanda che si farebbe un lettore: *questa non l'ho già letta?*

**Provata prima di fidarsene**: eseguita sul file com'era prima della rilettura è
**rossa** sulle voci gemelle di italiano, e verde dopo. Una guardia verde alla
nascita non prova niente.

---

## Le spiegazioni, il secondo giro — 27 agosto 2026

Il punto della situazione dopo il lotto del 26 dice che la struttura tiene —
9244 correzioni consegnate su 9244, eco dal 32% al 3,3%, 656 esercizi con un
disegno — e lascia scoperti quattro buchi misurati. Questo lotto li chiude.

L'ordine è per resa su costo, come sempre.

| | voce | che cosa copre | esito |
|---|---|---|---|
| **N-9** | I livelli per gli argomenti affollati | 1325 esercizi su 18 argomenti | ✅ 18 su 18 |
| **N-10** | Le 487 correzioni mancanti | 161 numeriche + 326 a risposta aperta | ✅ **zero scoperti** |
| **N-11** | Le figure per le materie scoperte | musica, coding, italiano, inglese | ✅ 4 materie su 5 |
| **N-12** | La guardia si alza | tre misure nuove a cricchetto | ✅ |

> **Chiuse tutte e quattro il 27 agosto.** I numeri, prima e dopo:
>
> | | prima | dopo |
> |---|---|---|
> | esercizi che consegnano una correzione | 3082 su 3569 | **3569 su 3569** |
> | frasi di correzione scritte | 9244 | **15015** |
> | argomenti affollati con più di una riga di NORA | 1 su 18 | **18 su 18** |
> | esercizi con una figura | 656 | **810** |
> | materie con almeno una figura | 6 su 12 | **10 su 12** |
>
> **Quello che non è stato fatto, e perché.** Fisica e scienze restano senza
> figure: nei loro testi non c'è niente che si estragga con certezza in un
> diagramma — le conversioni di unità in fisica sono **tre esercizi su 157** — e
> disegnare comunque vorrebbe dire decorare. È la stessa ragione per cui non
> esiste la bilancia dell'uguale, e vale la pena ripeterla: *una figura che si
> accende su tre prove è codice morto con una bella spiegazione sopra*.
>
> Restano anche le glosse scritte a mano — «quando NON si usa», la parola dentro
> un'altra già nota — su circa settecento voci di lessico. Nessuna regola
> meccanica le produce.
>
> **Due difetti che gli audit hanno preso mentre li scrivevo**, e sono i due che
> valgono più della correzione stessa:
>
> - `risposta_unica_audit` ha trovato **trentotto esercizi in cui NORA stava per
>   dire «sbagliato» a una risposta che il gioco accetta come giusta**:
>   «Imperfetto» e «imperfetto» sono due voci diverse del banco e la stessa
>   risposta. Il confronto va fatto con lo stesso metro del runtime — minuscole,
>   virgola come punto — e guardando la lista `accept`;
> - una **lista Python** `[10, 20, 30]` veniva disegnata come **retta dei
>   numeri**, perché a un'espressione regolare somiglia a una serie. Per un
>   bambino una figura sbagliata pesa più di una frase sbagliata: a quello che
>   vede si crede.

### N-9 · I livelli per gli argomenti affollati

Il meccanismo dei livelli esiste dal 26 agosto e **lo usa un argomento solo su
249**: `matematica:tabelline`. Ma diciotto argomenti hanno quaranta o più
esercizi e insieme ne coprono **1325**, ognuno servito da una riga sola:
`inglese:everyday-phrases` ne ha 160, `travel-places` 87, `home-family` 78.

La memoria di dodici impronte impedisce che la riga torni *subito*; su una
sessione lunga rientra. Due livelli in più per ciascuno — trentasei righe di
`perche` e diciotto di `come` — e il problema sparisce per un terzo del gioco.

**Livelli, non sinonimi.** Il primo è la ragione di fondo, il secondo il caso che
di solito frega, il terzo il collegamento con un altro argomento. Se le tre righe
si possono scambiare di posto senza che cambi niente, sono sinonimi e vanno
riscritte.

### N-10 · Le 487 correzioni mancanti

Sono tutte risposte aperte. Si dividono in due classi che si trattano in modo
diverso, e questa è la ragione per cui vanno separate:

**161 numeriche.** Qui l'errore tipico si *calcola*: chi sbaglia `3 × 2` scrive
quasi sempre 5 (ha sommato) o 8 (ha raddoppiato due volte). Il generatore delle
tabelline queste alternative le costruisce già, con il loro perché — le usa per
la scelta multipla e le **butta via** quando l'item è numerico. Vanno tenute: la
risposta aperta le sa già riconoscere, perché il confronto è sulla stringa
digitata ed è stato verificato che funziona.

**326 a risposta aperta con una parola.** Qui l'errore non si calcola, ma per gli
argomenti a insieme chiuso — le capitali, i componenti elettronici, le parti del
discorso — la parola sbagliata plausibile è un'altra voce dello stesso insieme, e
il suo perché si scrive una volta per insieme. Dove l'insieme non è chiuso non si
inventa niente e la voce resta scoperta: **è meglio dichiararle che riempirle**.

### N-11 · Le figure per le materie scoperte

Cinque materie su dodici non hanno nessun disegno, e fra queste ci sono i due
banchi più grossi. Cinque figure nuove, scelte dove il disegno dice qualcosa che
il testo non dice:

| figura | materia | prove |
|---|---|---|
| **la battuta divisa** — le caselle di una misura, col primo movimento acceso | musica | 11 |
| **la scala delle sette note** — i gradini che salgono, e il do che ricomincia | musica | 17 |
| **la lista con gli indici** — le caselle numerate **da zero** | coding | 17 |
| **la frase col pezzo acceso** — dove guardare dentro la frase | italiano | 22 |
| **le parole imparentate** — le lettere in comune accese | inglese | 147 (col latino) |

Due scelte di disegno vanno spiegate, perché in tutte e due il caso ho preferito
mostrare **meno** di quello che il piano prometteva.

**La frase non si smonta in soggetto e complemento.** Il piano diceva «soggetto,
verbo, complemento», ma etichettarli vorrebbe dire rispondere al posto del
bambino: è esattamente ciò che l'esercizio gli sta chiedendo. La figura accende
solo il pezzo di cui la domanda parla — «in *Luca legge un libro*, che cos'è *un
libro*?» — perché nell'analisi logica metà della fatica è capire di quale pezzo si
sta parlando, e quella metà si può dare senza regalare l'altra.

**Il coding non traccia la variabile.** Per farlo davvero bisognerebbe eseguire il
codice, e un'esecuzione sbagliata insegnerebbe una cosa falsa. La lista con gli
indici invece si legge dal testo senza interpretare niente, e colpisce l'errore
più comune di chi comincia: credere che il primo elemento sia il numero uno.

Restano senza **fisica e scienze**: nei loro testi non c'è niente che si estragga
con certezza in un diagramma — le conversioni di unità in fisica sono tre
esercizi su 157 — e disegnare comunque vorrebbe dire decorare.

### N-12 · La guardia si alza

Tre misure nuove in `nora_spiegazione_utile_audit`, tutte a cricchetto:

- ogni argomento con quaranta o più esercizi ha **almeno due livelli**;
- la quota di esercizi che consegnano una correzione **non scende mai**;
- **nessuna materia resta a zero figure**, e il numero di materie coperte non
  cala.

---

## Due audit che si contraddicevano — 27 agosto 2026

`glifi_audit` era rosso su `tool-torch` dal 21 agosto, cioè da quando il modulo
torcia è stato ritirato e le sue illustrazioni tolte da `build-reward-assets.mjs`.
Sembrava un'illustrazione mancante. Non lo era.

**I due audit chiedevano l'opposto.** `shop_presentation_audit` asserisce che
torcia e falce **non devono** stare nell'atlante della bottega — «gli strumenti
consegnati dal mondo non devono occupare l'atlante» — perché non si comprano: li
consegna il mondo. `glifi_audit` scandiva `RewardCatalog.CATALOG` per intero e
pretendeva un'insegna per ogni riga, quei due compresi.

Nessuno dei due sbagliava sul contenuto: **sbagliava questo sulla premessa.** La
regola vera è «ogni articolo *esposto in bottega* ha la sua insegna», non «ogni
riga del catalogo». Ora `glifi_audit` filtra sugli stessi otto slot di vetrina, e
si accorge da solo se quella lista si svuotasse per un refuso.

Vale la pena tenerlo a mente: **due guardie che misurano la stessa cosa con due
premesse diverse non si annullano, si alternano** — vince quella che gira per
ultima, e il rosso sembra un difetto del contenuto invece che del metro.

---

## Il cancello del mondo 2 — 26 agosto 2026

*Segnalazione di gioco: «ho completato tutto il mondo 1 e non riesco ad accedere
al mondo 2».* È la seconda volta: il 24 agosto era la copertura, resa visibile
sui cartelli delle palestre. Questa volta è un'altra cosa, e nessuna sonda
poteva vederla.

**`compiti_bastano_probe` e `progression_1to24_audit` giocano sempre rispondendo
giusto.** Un bambino che risponde giusto sempre non esiste, e il gate era tarato
su di lui. Misurato con il nuovo `gate_mondo1_audit`, mediana su sette semi:

| accuratezza | prima | dopo |
|---|---|---|
| 100% | 16 sessioni | 16 |
| 85% | 29 (fino a 36) | **20** (peggiore 25) |
| 70% | tre semi su sette **non aprivano mai il gate** | **35** (peggiore 46) |

Il mondo 1 di prove ne offre diciassette. Quattro cause distinte, tutte corrette;
**nessuna era l'ampiezza del gate**, che resta a dodici materie come deciso il 5
agosto.

1. **La padronanza si misurava su tre nodi.** Era una media mobile fra sessioni,
   e una sessione sono tre nodi: un campione così piccolo è quasi tutto rumore.
   Ogni materia riceve una sessione ogni dodici, quindi la stima si muoveva di un
   passo per giro e una sessione sfortunata al primo incontro costava cinque giri
   per essere riassorbita. Adesso si stima sulle risposte accumulate, con oblio
   0,85 — l'unico dei tre valori provati che non lascia nessun blocco.
2. **Il ripasso chiedeva la coda vuota.** La dimensione RITENZIONE pretendeva
   zero ripassi in calendario *nell'istante del controllo*; ma ogni sessione ne
   genera di nuovi e una voce esce dal calendario solo dopo quattro ripassi
   riusciti di fila. Il conto saliva a sei e non scendeva più. Adesso conta ciò
   che è stato sbagliato e **non ancora ripreso** — che è quello che la
   dimensione dichiara di misurare — e l'errore appena fatto ha una sessione di
   tempo prima di contare.
3. **Un argomento di matematica poteva non tornare mai.** La matematica non nasce
   dal banco come le altre undici: nasce dal generatore, e gli argomenti scritti a
   mano entrano da `_innesta_banco_matematica`, dove il calendario dei ripassi non
   arrivava. `matematica:statistica` sbagliata una volta restava sbagliata per
   sempre — sulla materia che **abita il mondo 1**, quindi addosso a chiunque.
4. **La soglia del nucleo rendeva il mondo 1 impossibile, non difficile.** La
   padronanza stimata di un bambino al 70% si assesta intorno a 0,767: sopra la
   soglia base (0,70) e sotto quella del nucleo (0,78). Non lento — *impossibile*,
   a qualunque quantità di lavoro.

> **Questa quarta è una decisione di prodotto, ed è l'unica che ho preso io.**
> Il rango del nucleo è una scelta del committente del 6 agosto e non si tocca;
> quello che ho cambiato è che il bonus **cresce con la scala** invece di essere
> pieno dal primo mondo. La ragione sta nel design stesso: dichiara una valvola
> contro il blocco — «la difficoltà adattiva abbassa gli item finché
> l'accuratezza risale» — e al mondo 1 **quella valvola non esiste**, perché
> `target_difficulty(1)` vale 1, che è già il fondo del banco. Se un giorno
> esistesse contenuto sotto la difficoltà 1, la rampa può tornare piatta.
> Si cambia in una riga: `ApparatusConfig.core_bonus`.

E una cosa che l'audit ha trovato di sé stesso: **non era deterministico.**
`build_mission(..., null, ...)` si costruisce un generatore e lo `randomize()`,
quindi ogni esecuzione misurava una partita diversa. Un tetto misurato su una
partita diversa ogni volta non è un tetto. Trovato facendo girare due volte di
fila la stessa identica revisione e leggendo due numeri.

---

## G-4 · Radar e torcia — ritirata il 21 agosto 2026

*Decisione del committente.*

I due moduli restavano in attesa del loro contratto semantico, con le
illustrazioni gia' riservate nel foglio premi. Sono usciti per la stessa
ragione per cui e' uscito l'impulso: **chiedono una resa che non esiste** — un
segnale sulla cassa entro il raggio, un cono luminoso orientato con Eli — e
venderli prima sarebbe stato il difetto del 6 agosto ripetuto, quattro
potenziamenti che costavano fino a 1600 frammenti e non facevano nulla.

La sezione spedizione non ne ha bisogno: ha gia' tre moduli che si vedono
(Passo lungo, Andatura felpata, Zavorra da campo), tutti e tre su numeri che il
grado di Eli non azzera.

Tolte anche le due illustrazioni riservate da `build-reward-assets.mjs`: il
foglio premi si genera dal solo catalogo, che e' la sola fonte di verita'. Se un
giorno la resa esistera', il modulo entra allora — con la sua resa, non prima.

---

## Arte generativa — la lettura del 20 agosto 2026

Stessa lettura fatta il 14 agosto sullo strato di gioco, applicata ai disegni:
non che cosa il gioco **contiene** in fatto d'arte, ma che cosa un bambino
**guarda** mentre gioca.

Il gioco ha molta arte, e la parte grande è coperta: 23 tavole di terreno (una
per mondo), 22 landmark illustrati, 69 residenti più cinque itineranti, 24
guardiani, 11 Custodi, 9 tavole di Eli, 5 presenze di NORA, 60 riquadri di
ricompensa.

La misura, in una riga: **è illustrato ciò che sta sullo sfondo o si guarda da
lontano, ed è un poligono piatto quasi tutto ciò che si tocca.** Il terreno della
Necropoli delle Radici è dipinto; le tre pietre della sua Rovina dei Primi sono
le stesse tre pietre grigie degli altri ventitré mondi.

Le voci **C-** che seguono sono di Codex — sono resa, mai regola — e sono
ordinate per resa su costo: il numero segue la priorità. L'unica **G-** del
blocco, G-11, è la guardia che le tiene, ed è di Claude. Nessuna aggiunge un
esercizio, un nodo di regola o un minuto alla campagna, e nessuna è un
prerequisito: ogni cosa che nominano **è già giocabile oggi** con forme piene e
colori piatti. Si sostituisce un segnaposto, non si sblocca un lotto.

Tre vincoli valgono per tutte, e non si negoziano:

- **nessuna immagine contiene testo.** Le iscrizioni descritte nei cataloghi —
  «contare in gruppi non è pigrizia» sul bastone del mondo 1 — restano righe di
  catalogo, lette dal pannello e dal lettore di schermo;
- **il conto dei nodi si fa prima.** Il mondo 1 sta a 2.789/3.500 nodi e 311/500
  ms. Una tavola che sostituisce trenta poligoni **restituisce** nodi; un
  effetto che ne aggiunge va misurato con `performance_budget_audit` in
  isolamento, perché quell'audit è fragile al carico;
- **il peso arriva su un tablet scolastico.** Il PCK esportato è passato da
  34,33 a **52,27 MiB** in una giornata di tavole, e il pacchetto completo sta a
  89,96 MiB. Ogni atlante nuovo si dichiara in MB prima di essere generato, e da
  qui in avanti la domanda non è più «quanto pesa questo» ma «quanto pesa il
  primo caricamento su una rete di scuola».

> **Stato alla sera del 20 agosto.** Otto voci aperte la mattina, **sei chiuse**
> e nel registro: C-ART-7, 8, 10, 11, 14 e la guardia G-11. Restano due code
> misurate (C-ART-10 e la trasparenza di C-ART-9) e due voci a metà per scelta,
> C-ART-12 e C-ART-13, che avanzano a lotti.
>
> Un fatto va scritto perché è tornato tre volte su tre: **i tre audit scritti
> insieme alle tavole erano verdi, e nessuno dei tre difetti li ha fatti
> arrossire.** Verificavano la dichiarazione — che la tavola sia dichiarata, che
> il nodo esista, che il tipo sia quello giusto — non il disegno. È la stessa
> forma della decisione 14.
>
> Da lì è nata **G-11**, `tavole_guard_audit`, che misura il disegno: i ritagli,
> il contrasto del testo sulla superficie che ha sotto, i nodi contati
> sull'oggetto che il mondo costruisce. È nata rossa su dieci punti e li ha
> chiusi tutti; copre anche le tavole arrivate dopo — 72 edifici e sei atlanti
> naturali — che passano senza correzioni.
>
> **Un quarto difetto l'ha preso un audit che c'era già.** La sagoma di ruolo di
> C-ART-8 copriva il guardiano illustrato, e `generated_character_art_audit`
> vieta da prima di questo lotto che qualcosa gli si disegni sopra. Ora la sagoma
> sta dietro e sporge — corona sopra la testa, lame di lato — ma **la resa è
> geometria, non un occhio**: è la prima cosa da guardare giocando.
>
> **Il peso è la cosa da tenere d'occhio.** Il PCK esportato è passato da
> **34,33 a 52,27 MiB** (+52%), il pacchetto completo a 89,96 MiB. Ogni tavola
> di oggi è dentro quel numero, e quel numero arriva su un tablet scolastico.
>
> E una correzione mia, perché il numero era in questo file: gli oggetti
> identitari non sono 46 ma **71**. Contavo i `match` a un nome per riga e ce ne
> sono a tre.

---

### C-ART-10 · La coda (chiusa nel registro, non nel gioco)

Il lotto sta nel registro e le tavole sono buone: 71 kind su otto atlanti 4×3,
mappatura verificata a campione — la libreria è una libreria, il leggio è un
leggio, la caravana è una caravana. Restano quattro cose piccole.

- **La misura non è stata scritta, e intanto si è mossa.**
  `performance_budget_audit` è verde, ma il numero non è più quello:
  mondo 1 a **2.918/3.500 nodi e 403/500 ms**, contro i 2.789 e 311 dell'ultima
  misura scritta — l'81% del budget d'avvio. Non è tutto di questo lotto, in
  mezzo sono passati il cielo e i fuochi; ma la voce prometteva di
  **restituire** nodi, e nella misura non si vede. Va preso prima e dopo sullo
  stesso commit, e scritto nel registro accanto al «verde».
- **In scena ogni prop porta cinque nodi, non tre.** `IdentityPropArt.build()`
  ne restituisce due — radice e tavola — e `build_identity_prop` aggiunge ombra,
  bagliore e l'animazione del bagliore: cinque, uno dei quali gira in `_process`
  a ogni fotogramma. L'audit misura il primo oggetto e non il secondo:
  `get_child_count() <= 3` passa su una cosa che nel gioco non esiste.
- **Un alone che pulsa su tutto.** Prima ce l'avevano alcuni prop, e per un
  motivo; adesso ce l'hanno tutti e settantuno, un colore per famiglia. Un alone
  che pulsa è il segno con cui questo gioco dice «qui c'è qualcosa»: metterlo
  sulla scenografia insegna a non fidarsene. Va tenuto dove significa e tolto
  dove decora.
- **Venticinque celle vuote, otto atlanti sempre in memoria, 850 righe morte.**
  Le famiglie simbiosi (2 kind) e sintesi (3) hanno fogli da dodici celle: dieci
  e nove disegni fatti e mai raggiungibili, circa 2 MB su 8,1. I `preload`
  tengono tutti e otto gli atlanti in memoria per l'intera sessione, mentre
  landmark e atlanti naturali si caricano pigri e si liberano con
  `release_world_texture_caches()` — qui quella cura non c'è. E poiché nessun
  kind resta fuori dalle famiglie, i poligoni di `build_identity_prop` non sono
  più raggiungibili: o tornano a essere un ripiego vero quando una tavola manca,
  o vanno via.

---

### C-ART-12 · Cinque shader per tutto il gioco

**Oggi.** Due file — `painterly_ground` e `painterly_water` — e tre stringhe
inline: la stanza della nave, l'atmosfera, la vignetta. Tutto il resto
dell'atmosfera è CPU: `OutdoorAtmosphere` è un `ColorRect` più due
`CPUParticles2D`, e ogni chioma che ondeggia porta un nodo `OutdoorAmbientAnim`
che gira in `_process` a ogni fotogramma — 91 punti di aggancio nel codice.

**Progresso (20 agosto).** La foschia del mondo è uscita dalla stringa inline:
`world_atmosphere.gdshader` è una risorsa condivisa, con tinta per bioma e
movimento congelato da `reducedMotion`. Restano il vento vertex sugli atlanti,
la migrazione delle altre due stringhe e il cono della torcia.

**Perché adesso.** Il tempo ha ricominciato a passare il 20 agosto. La luce
cambia e **non cambia nient'altro**: niente vento che cala la sera, niente
foschia che si alza, nessuna ombra che si allunga. Un ciclo giorno/notte che
muove solo un `CanvasModulate` si legge come un filtro, non come un'ora.

**Cosa, in ordine di resa.**

- **Il vento sull'atlante naturale**, in vertex shader: zero nodi, e restituisce
  quelli di `OutdoorAmbientAnim` insieme al loro `_process`.
- **La foschia per bioma**, oggi un velo di colore uniforme sull'intera
  schermata.
- **Il cono di luce della torcia.** G-4 lo dichiara già come consumer dormiente
  a valore zero — «scala il cono luminoso orientato con Eli» — e le
  illustrazioni sono riservate nel `reward-items-sheet`. È la metà Codex di una
  voce già aperta, non una voce nuova.

**Il vincolo.** Movimento ridotto spegne il vento e la foschia mobile; il
pavimento di leggibilità di `WorldSky` (0,20) non si tocca da nessuna direzione.
Giudici: `world_light_audit`, `world_sky_audit`, `accessibility_release_audit` e
una misura isolata di `performance_budget_audit`.

---

### C-ART-13 · Le conseguenze dei residenti sono due su quarantasei

**Oggi.** `ResidentConsequenceVisual.supports()` risponde vero per `w01-tobia` e
`w01-ersilia`, e basta. Il commento lo dichiara: pilot del mondo 1, gli altri
«solo dopo aver misurato nodi e tempo di avvio». Nel frattempo
`resident_portrait_stage_audit` verifica 46 × 3 pose **nel ritratto**: la persona
cambia quando ci parli, il posto in cui vive no.

**Progresso (20 agosto).** Il primo lotto ha portato la copertura a **6/46**:
Corinna, Bruno, Ruggine e Sesto hanno tre conseguenze leggibili nei loro luoghi
dei mondi 2–3, sempre come un solo nodo procedurale. `resident_consequence_batch_audit`
verifica il montaggio nel `BuildingActor`, i tre stadi e il budget di nodi.
Restano quaranta residenti, da estendere a lotti misurati.

**Perché.** È l'unica cosa in tutto il gioco che dice, senza una parola e senza
un numero, che quello che il bambino ha imparato è arrivato a qualcuno. Due
mucchi di cristalli nel mondo 1 su quarantasei persone è un pilot rimasto pilot.

**Cosa.** Un lotto per volta, non tutti insieme: i sei residenti dei mondi 2–3,
misurati nodi e millisecondi prima e dopo, e si prosegue solo se il conto regge.
La misura che quel commento aspettava adesso esiste — 2.789/3.500 e 311/500 ms —
quindi il cancello si può aprire, un mondo alla volta.

**L'audit.** `resident_consequence_render_probe.gd` esiste già e produce catture
riproducibili: la regola resta quella del lotto del 13 agosto — i tre stadi
devono restare distinguibili **senza dialogo**.

---

### Le due che aspettano

Non sono voci: sono cose viste in questa lettura che non conviene aprire adesso.

- **Il formato che mostra l'oggetto vero vive in una materia sola.** `HOTSPOT`
  esiste per `storia`, con un atlante (`roman_artifacts`) e quattro bersagli;
  `ArtifactAtlasCatalog` ha una voce sola. È l'unico formato in cui un bambino
  riconosce una cosa vera invece di leggerne il nome, e delle dodici materie ne
  serve una. Non sostituisce il minigioco di montaggio già in piano per i
  ventidue quesiti sui componenti elettronici: semmai gli prepara il materiale.
  Aspetta perché il **secondo foglio di reperti** è già una voce aperta, e i due
  fogli conviene deciderli insieme.
- **I quindici minigiochi dei personaggi hanno un asset in tutto**
  (`assets/minigames/tobia-crystal-v1.png`). Le tavole vettoriali sono leggibili
  e funzionano. Aspetta il collaudo per la ragione già scritta nel piano: finché
  non si misura quali meccaniche restano nel giro, illustrarle tutte e quindici
  è lavoro su un'ipotesi.

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

## Il pacchetto differito — che cosa contiene, adesso

**Decisione del 21 agosto: l'arte parte con il gioco, sempre.** I 74 ritratti,
le 24 tavole dei guardiani, gli 11 Custodi e i 5 itineranti sono nel pacchetto
d'avvio. Nel differito resta **solo l'audio**, che degrada in silenzio e non ha
una faccia.

Prima quelle tavole viaggiavano col pacchetto chiesto in sottofondo, e chi
entrava nel mondo nei primi venti secondi vedeva i gusci vettoriali. Il
rimontaggio all'arrivo aveva chiuso il difetto, ma la finestra restava: una
finestra in cui il gioco si mostra peggio di com'è non è un compromesso che
questo progetto fa.

Il prezzo, dichiarato: **PCK da 52,27 a 63,51 MiB**, pacchetto completo a 101,19
MiB; il differito scende da 25,8 a 14,6 MiB. Il primo caricamento è più pesante
di undici mega e il primo mondo è quello giusto da subito.

Misura sulla build esportata, entrando nel mondo appena parte:
**`montato-e-riapplicato:0`** — nessun nodo in attesa, nessun ripiego mostrato.
Prima erano dodici.

Due guardie, e servono tutt'e due perché il difetto è vissuto un mese senza che
nessuno lo vedesse: `boot_art_audit` non lascia rimettere l'arte nel differito —
è una riga di un `.cfg` che nessun test esegue e rimetterla costa un secondo — e
`content_pack_refresh_audit` tiene in piedi il rimontaggio, che resta come rete
di sicurezza per l'audio e per qualunque cosa venga differita domani.

**Il disegno vettoriale resta nel codice, e non è una contraddizione.** Nel
guscio delle sacche di Silenzio quelle forme non sono un ripiego: sono il corpo,
e l'illustrazione ci sta sopra per costruzione. Toglierle cambierebbe la resa
voluta, non semplificherebbe niente. Quello che è stato eliminato è la
*condizione* in cui il ripiego si vede.

---

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

## Gli allenamenti: dove si fanno, e con che faccia — 21 agosto 2026

*Segnalazione di gioco: «dobbiamo gestire meglio come e dove fare allenamenti.
Ora gli ingressi sono in icone sparse a caso anche brutte con 2605 come logo».*

Tre difetti distinti dietro una frase sola. Il primo è chiuso, gli altri due sono
qui sotto divisi fra chi li deve fare.

### Che cos'era «2605» — chiuso

Non era un logo: è il **codice esadecimale di ★**, U+2605. Il progetto non
imbarca nessun font e usa `Open Sans SemiBold`, che quel glifo non ce l'ha. Su
Windows Godot ripiega sui font di sistema e la stella si vede; **nel Web e su
tablet quel ripiego non esiste** e resta il rettangolo col codice dentro. È il
motivo per cui nessuna cattura di sviluppo aveva mai mostrato il difetto: è
invisibile esattamente sulla macchina di chi scrive il codice.

Misurato da `glifi_probe`: **58 simboli su 63** usati nel codice non hanno glifo
nel font imbarcato, e nella bottega **0 articoli su 44** si disegnano interi.

Chiuso oggi: l'insegna delle palestre è **disegnata** — nessun glifo, nessun
ripiego possibile — e porta il **colore della materia** da `SubjectPalette`, che
da oggi è una tabella sola per il mondo, la nave e le palestre (prima erano due
copie divergenti). Resta aperta la bottega, qui sotto.

### C-G-12 · Le insegne della bottega — chiusa il 21 agosto 2026

Ogni articolo del catalogo aveva un campo `glyph` con un carattere Unicode, e
**nessuno dei quarantaquattro si disegnava** fuori da Windows: chi giocava nel
browser comprava rettangoli con dentro `25C9`, `1F436`, `2726`.

Chiusa per una strada migliore di quella che avevo proposto. Non sono servite
quarantaquattro forme nuove: **l'atlante illustrato esisteva gia'**
(`reward-items-sheet`), e alla bottega mancava solo di usarlo sempre. Tolto il
ripiego `_tool_fallback_texture` da `outdoor_shop_panel`, rigenerato il foglio
premi dal catalogo — 63 icone, e i tre strumenti che stavano fuori dall'atlante
(`tool-lever`, `tool-lens`, `tool-bellows`) adesso ci sono davvero.

`glifi_audit` tiene le due condizioni: **ogni articolo del catalogo ha una
regione nell'atlante**, e la bottega **non puo' tornare al glifo di sistema**.
`glifi_probe` resta come censimento del repertorio Unicode nel codice, che e' il
posto da cui il difetto e' arrivato.

Nota per chi tocca il catalogo: aggiungere o togliere una voce **richiede
`npm run assets:reward`**. Il 21 agosto due moduli nuovi hanno fatto diventare
rosso `shop_presentation_audit` proprio per questo, e le illustrazioni riservate
ai moduli ritirati vanno tolte anche da `build-reward-assets.mjs`.

### G-12 · Il quartiere degli allenamenti — chiusa il 21 agosto 2026

**Il difetto.** Le undici palestre nascevano nella banda esterna, una per
materia, e c'era una riga che le allontanava **di proposito**:

    score -= float(cluster_usage.get(cluster_id, 0)) * 18.0

con il commento «formano costellazioni, non un unico mucchio». Giusta per gli
eventi del gate — che devono offrire una scelta di rotta — e sbagliata per gli
allenamenti, che non sono un percorso: sono un **servizio**, e un servizio
sparso su duemila unità di mappa non si usa.

**La forma.** Per le palestre quella riga si rovescia: il quartiere ripetuto
diventa un pregio, e la vicinanza alla stazione precedente pesa più di ogni
altra cosa (`ancora` in `_semantic_placement`). L'ordine lungo il filo è quello
del ciclo delle materie, quindi è **stabile fra i mondi**: chi ha imparato che il
latino viene dopo l'inglese lo ritrova al mondo dopo.

**Che cosa ho creduto e che cosa dice la misura.** Avevo scritto «una catena
leggibile». Non si ottiene, e alzare il premio di vicinanza non la produce: il
collo di bottiglia è la **capienza dei luoghi**, non il punteggio — undici
palestre più otto eventi di gate non entrano nei socket di un quartiere solo.
Misurato: col premio a 340 il passo fra due stazioni consecutive resta anche di
2400 unità, e alzarlo ancora peggiora.

Quello che l'ancora ottiene davvero, e che è ciò che serviva:

| | prima | dopo |
|---|---|---|
| quartieri per mondo (media) | 4,2 | **2,9** |
| quartieri nel mondo peggiore | 11 | **5** |
| raggio del gruppo (media) | 1452 | **1319** |

Non è una collana: è un **quartiere degli allenamenti**, che è la cosa che si
impara a memoria e si torna a cercare. `semantic_placement_audit` tiene i due
tetti — sei quartieri, raggio 2300 — misurati sul caso peggiore. Si abbassano,
non si alzano.

**E il «come», non solo il «dove».** Il quadro degli obiettivi elencava già le
dodici materie con quanto manca a ciascuna, e poi lasciava il bambino a cercarle
camminando. Adesso ogni materia aperta ha il suo **PORTAMI**: chiude il quadro e
punta la bussola alla sua stazione. Il filo risolve il *dove*, il pulsante il
*come ci arrivo*.

Trovato per strada: quel quadro usava `✔` (U+2714) per le materie chiuse — un
altro «2605», stesso font, stesso rettangolo col codice su Web e tablet.

### Perché il filo è coerente con la storia, e la spirale no

Quando il filo esiste, una stazione non è più un disco con una stella: è un
**ripetitore dei Primi**, e le undici insieme sono il circuito che il nucleo
prismatico della nave rimette in fila. Serve la resa: la pietra, il filo che
collega una stazione alla successiva quando le hai visitate tutte e due, e la
luce che si accende del colore della materia quando la stazione è stata usata in
questo mondo.

Il colore lo dà già `SubjectPalette` ed è lo stesso della notte di quel mondo e
della scheda sul ponte: non va reinventato, va letto.

I Primi hanno lasciato un **circuito**, e `BuildingCatalog` lo dice già: la
*first_ruin* di ogni mondo «è un pezzo del circuito, e messe in fila raccontano
che qualcuno è passato di qui prima, dodici volte». Il nucleo prismatico che si
compra in bottega è descritto come «il cuore della nave, che scompone la luce in
dodici colori: uno per sistema — è un ritratto, non una macchina».

Undici pietre in fila, ognuna del colore del suo sistema, che partono dalla
piazza degli abitanti e si allontanano nel mondo, **sono** quel circuito visto da
terra invece che dal ponte. Undici dischi identici sparsi a caso non sono niente:
sono interfaccia travestita da mondo, ed è esattamente quello che la segnalazione
ha visto.

C'è anche una conseguenza narrativa che il filo si porta dietro gratis: gli
abitanti allenano **quello che sanno fare**, e il ritrovo è dove si parlano. Una
stazione accanto alla piazza è un posto in cui qualcuno può stare; una stazione a
duemila unità nel nulla no. Il gancio con `TeachingCatalog` e con i maestri
esiste già e non è mai stato usato per la pratica.

---

## G-13 · La risposta più lunga — pagata su scienze e storia, 21 agosto 2026

*Domanda del committente: «possono esserci casi simili in altre materie?». Sì.*

Nel duello dei verbi la scorciatoia era «la domanda e la risposta usano le stesse
parole». In una banca a scelta multipla è un'altra e non richiede nemmeno di
saper leggere: **si tocca l'opzione più lunga**.

### La prima misura era troppo severa, e l'ho corretta

Contavo «la risposta è la più lunga» e basta — quindi anche «Mercurio (8) contro
Saturno (7)», che nessun bambino può sfruttare: un carattere non si vede. Quel
numero descriveva la prosa italiana, non una scorciatoia giocabile.

Adesso la scorciatoia è **simulata come la userebbe qualcuno**: tocco la più
lunga se il divario supera i cinque caratteri — circa una parola — altrimenti
tiro a caso. Il confronto è col caso, che con quattro opzioni è il 25%.

### Pagato

Sessantotto distrattori allungati a mano, trentacinque in scienze e trentatré in
storia. **Mai accorciando la risposta giusta**: la sua precisione è contenuto
didattico, la lunghezza di un distrattore no. Ogni sostituzione tiene il
distrattore sbagliato e plausibile — una precisazione che un bambino potrebbe
credere, mai una parola di riempimento.

| materia | prima | dopo | |
|---|---|---|---|
| **scienze** | 45,4% | **22,1%** | sotto il caso: la scorciatoia fa perdere |
| **storia** | 42,5% | **22,2%** | sotto il caso |
| fisica | 39,3% | — | debito |
| elettronica · musica | 38% | — | debito |
| geografia | 35,2% | — | debito |
| italiano · coding | 33% | — | debito |
| latino | 31,5% | — | debito |
| inglese · matematica · logica | 25-26% | — | in banda |

### Il debito che resta, e il guardiano

`bank_scorciatoie_audit` misura le tre scorciatoie — lunghezza, posizione, eco —
e ogni materia ha il **tetto che aveva il 21 agosto**. Serve a due cose, e la
seconda vale più della prima: non si può peggiorare, e il debito è visibile e si
accorcia. Un debito che non sta scritto da nessuna parte non viene mai pagato.

Le nove materie sopra il caso si pagano nello stesso modo: si guardano i quesiti
in cui la giusta supera la seconda di cinque caratteri e si allunga un
distrattore. Sono fra i venti e i quaranta per materia.

**Due cose invece sane, e vale la pena saperlo:** la posizione della risposta
giusta è uniforme, e l'eco della domanda non aiuta — la risposta giusta ripete le
parole del quesito **meno** del caso. I distrattori sono scritti bene: sono loro a
somigliare alla domanda, ed è giusto così.

---

### G-14 · Quali minigiochi si vincono a caso — misurato il 21 agosto 2026

Quindici archetipi, quarantasei personaggi, tutti con un pannello e tutti con un
audit. Ma nessuno di quegli audit chiedeva la cosa che conta: **si vincono senza
capirli?** `minigiochi_cieco_probe` gioca ogni pannello con tocchi casuali,
sessanta partite per archetipo, e conta.

| archetipo | vinti a caso | tocchi medi | |
|---|---|---|---|
| **mucchio** | **100,0%** | 6 | *il primo che un bambino incontra, mondo 1* |
| **prova** | **68,3%** | 5 | *«una causa si isola, non si indovina»* |
| scaffale | 43,3% | 8 | |
| vibrazione | 36,7% | 62 | |
| leva | 35,0% | 77 | |
| mercato | 25,0% | 5 | |
| glifi | 21,7% | 7 | |
| parentela | 20,0% | 78 | |
| stima | 8,3% | 87 | |
| altalena | 3,3% | 54 | |
| traccia | 1,7% | 14 | |
| ciclo · radio · circuito · ritmo | **0,0%** | | *sani* |

**I due da guardare.**

Il **mucchio** è il minigioco di Tobia, mondo 1: il primo che un bambino
incontra, e si vince **sempre** toccando a caso in sei tocchi. Un fallimento
c'è — il cronometro — ma non stringe mai. La lezione dichiarata è «raggruppare
batte contare», e raggruppare non serve: si tocca tutto.

La **prova** dice di sé «una causa si isola, non si indovina», e si indovina due
volte su tre.

Gli altri tredici stanno sotto il 45%, e quattro sono a zero. La colonna dei
tocchi medi separa due famiglie: chi si chiude in cinque-otto tocchi (mucchio,
prova, scaffale, mercato, glifi) e chi ne chiede decine. Nei primi il caso ha
poche occasioni di sbagliare, ed è lì che il numero sale.

**Che cosa NON è questo numero.** Non è un verdetto: alcuni archetipi sono giochi
di velocità, dove sbagliare costa tempo e non la partita, e un CIECO paziente li
finisce comunque. È il numero da guardare **prima** di dire che un minigioco
funziona — e prima di aggiungere il sedicesimo archetipo.

**Da decidere insieme:** se e come stringere mucchio e prova. La sonda resta e
misura di nuovo dopo ogni taratura.

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
   2026). È la regola che tiene insieme G-1, G-2 e G-4: serie e moduli
   moltiplicano o aiutano sulla **mappa**, e non toccano mai mastery,
   copertura, ritenzione, gate o esami.
   *(Le cariche d'impulso stavano in questo elenco fino al 21 agosto 2026:
   l'impulso è stato tolto perché non aveva lavoro — vedi
   [FORZIERI_E_FRAMMENTI §9.2.1](docs/FORZIERI_E_FRAMMENTI.md). La regola non
   cambia, cambia l'elenco di chi la deve rispettare.)* Nel momento in cui una di queste tre
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
