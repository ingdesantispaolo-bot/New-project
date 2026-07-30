# Eli Quest — Il Custode (pet compagno)

> Specifica del compagno personalizzabile: il suo **volto sempre visibile**, le
> **interazioni affettuose**, il suo **repertorio comico** e la schermata
> dedicata.
> Trama in [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md), abitanti in
> [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md), economia in
> [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md) §7–8.

---

## 1. La decisione di design

Un pet è il richiamo più forte che esista per il pubblico di questo gioco. Vale
la pena costruirlo bene, e vale la pena essere severi su cosa **non** deve fare.

**Il Custode è quattro cose, in quest'ordine:**

1. **Uno specchio affettivo.** Il suo volto reagisce a ciò che succede. È l'unico
   canale di feedback del gioco che non valuta mai: NORA dà il metodo, l'HUD dà i
   numeri, gli abitanti danno il contesto — il Custode dà solo compagnia.
2. **Un comico.** Fa cose stupide, se ne vanta, porta regali inutili, si mette
   nei guai da solo. In un gioco che chiede di studiare, il compagno è il posto
   dove **non** si deve capire niente: si ride e basta. Vedi §3.
3. **Una bussola morbida.** Si illumina dove c'è qualcosa da capire, si fa
   attento vicino alle zone sbiadite. Guardi il muso e sai dove andare.
4. **Un oggetto di storia.** I Custodi sono creature dei Primi che **sentono il
   significato**. Dove c'è un Custode, resta un filo. Il volto è sempre in vista
   perché è uno strumento, non un adesivo.

### 1.1 Cosa il Custode non fa, e perché

| Non fa | Perché |
|---|---|
| **Non ha fame, non si sporca, non si ammala** | Un ciclo di accudimento a decadimento produce senso di colpa quando il bambino non gioca. Un gioco che si studia non può punire chi torna dopo tre giorni |
| **Non è mai triste per un tuo errore** | Il vincolo più importante di tutti. Vedere il proprio compagno deluso dopo una risposta sbagliata è vergogna, e la vergogna spegne l'apprendimento. All'errore fa la faccia **incoraggiante**, sempre |
| **Non dà mastery, energia o aiuti in esame** | Nessuna ricompensa scavalca una prova di competenza |
| **Non muore, non si perde, non va via** | Nessuna leva di ansia |
| **Non chiede acquisti per essere felice** | Il legame cresce giocando, non spendendo |
| **Non fa mai una battuta su di te** | Il bersaglio comico è sempre lui, o un oggetto. Mai Eli, mai un errore |

---

## 2. Il volto sempre visibile

### 2.1 Il widget

Un **ritratto circolare** di ~76 px, ancorato all'angolo, sempre in campo nel
mondo esterno, nella nave e durante gli esercizi. Contiene il **muso** (disegnato
in vettoriale come già fa `OutdoorVisualFactory.build_pet()`), l'**espressione**
corrente, un **anello di legame** che si completa lentamente, e il **nome** che
gli hai dato.

Durante una sessione resta visibile ma si sposta in un angolo neutro e **non
copre mai** prompt, opzioni o pulsanti. È l'unico elemento dell'HUD che
sopravvive a tutte le schermate: è la costante affettiva del gioco.

**Si tocca.** Il widget non è decorativo: un tocco breve è una carezza (§3.1), un
tocco lungo apre la schermata. È la prima cosa che un bambino proverà a fare, e
deve funzionare.

### 2.2 Le dieci espressioni

Nessuna è negativa. Due sono esplicitamente comiche.

| Espressione | Quando | Come si legge |
|---|---|---|
| **Sereno** | riposo | Occhi morbidi, respiro lento. È il volto base, scelto da te |
| **Curioso** | vicino a un POI mai affrontato, una Traccia non trovata, un abitante con qualcosa di nuovo | Orecchie su, testa inclinata verso la direzione giusta |
| **Attento** | dentro o vicino a una zona sbiadita | Immobile, pelo dritto, luce che si abbassa. Mai spaventato |
| **Concentrato** | esercizio in corso, ancora di più se è ripasso | Occhi socchiusi, fermo, guarda dove guardi tu |
| **Incoraggiante** | **risposta sbagliata** | Si avvicina, sguardo caldo, colpetto. Nessuna tristezza, nessun sospiro |
| **Orgoglioso** | risposta corretta | Petto in fuori, coda alta, un po' esagerato |
| **Festa** | combo, missione superata, apparato riparato, argomento consolidato | Salta, scintille, l'unica animazione ampia |
| **Beato** | mentre lo accarezzi | Occhi chiusi, si appoggia al bordo del ritratto, verso soddisfatto |
| **Impicciato** | **ha appena fatto una figuraccia** (§3.2) | Sguardo in camera, orecchie basse, l'espressione di chi sa di aver combinato qualcosa |
| **Offeso (per finta)** | non lo accarezzi da un po' | Gira la testa e ti sbircia. **Si scioglie da solo in pochi secondi** con un sospiro comico: non è un rimprovero, è una gag |

**Regola vincolante**: la mappa da segnale a espressione è dichiarata in una
tabella dati e verificata da audit. Nessun segnale di errore, fallimento o
mancanza produce un'espressione negativa, perché di espressioni negative **non ne
esistono**. *Offeso* è comico per costruzione e si risolve senza che tu faccia
nulla.

### 2.3 Le espressioni come guida

*Curioso* punta verso la cosa interessante più vicina non ancora affrontata, con
un raggio pari a metà dello `streamRadius`. *Attento* segnala che lì attorno
qualcosa ha perso il significato. Entrambe hanno priorità **inferiore** a quelle
di sessione: durante un esercizio il Custode è concentrato, non curioso.

### 2.4 Il legame

Un valore 0→1 che **sale e non scende mai**.

- Sale a fine sessione (superata o no: conta aver provato), quando aiuti un
  abitante, quando spieghi qualcosa a Vera, e con le coccole (poco, e con un
  tetto giornaliero, così non diventa un lavoro).
- Non sale comprando, non scende con l'inattività.
- **Sblocca espressioni e combinelle**: si parte con 5 espressioni e 4 combinelle,
  si arriva a 10 e 16. Le ultime arrivano tardi e sembrano un regalo.
- **Non sblocca vantaggi di gioco.** Mai.

---

## 3. Coccole, combinelle e figuracce

Questa è la sezione che rende il Custode un personaggio invece di un indicatore.

### 3.1 Le coccole

Tocco breve sul widget, o tasto dedicato quando sei nel mondo.

- Il Custode si struscia, chiude gli occhi (**Beato**), emette un verso.
- **Ogni indole reagisce diversamente**: il *Vivace* ti travolge e chiede il bis;
  il *Calmo* si appoggia piano e resta lì; il *Buffo* si rovescia a pancia in su
  senza preavviso; il *Serio* accetta con dignità, poi si riavvicina di un passo
  fingendo che sia un caso.
- Alla decima carezza di seguito si addormenta. Solo allora, e per gioco.
- Nessun contatore visibile, nessun obiettivo, nessuna ricompensa dichiarata.
  Le coccole non devono mai sembrare un compito.

### 3.2 Le combinelle

Ogni tanto, da solo, il Custode fa una cosa. Non serve a niente. È il punto.

**Repertorio iniziale** (sbloccato dal legame, fino a sedici):

| | |
|---|---|
| Insegue la propria coda e **si stupisce ogni volta** | Prova a imitare la posa di Eli e la sbaglia di un tanto |
| Si addormenta in piedi, si sveglia di soprassalto e finge di essere stato sveglio | Fa la guardia a un sasso per tre minuti buoni |
| Prova a sedersi su una superficie troppo piccola. Ci riprova | Starnutisce **esattamente** nel momento più solenne |
| Si nasconde dietro Eli quando passa Orsolo, poi finge di non averlo fatto | Cerca di bere dalla fontana e ci finisce dentro |
| Annusa uno Sbiadito, cambia idea, torna indietro con dignità | Corre avanti tutto entusiasta e poi non ricorda perché |

Dopo una combinella la faccia va su **Impicciato** per due secondi, con lo
sguardo in camera. È il tempo comico che fa funzionare la gag.

Frequenza: massimo una ogni ~90 secondi, **mai durante un esercizio**, mai
durante un beat di NORA tranne lo starnuto — che è progettato apposta per
rovinare un momento solenne, una volta ogni tanto, e che NORA commenta.

### 3.3 Il regalo inutile

Periodicamente il Custode **porta qualcosa**. È sempre orgogliosissimo.

- È un sasso. Una foglia. Una vite storta. Un bottone. Un altro sasso.
- Il gioco lo mette in una **collezione visibile** nella schermata del Custode:
  *«Cose che ti ha portato»*, con la data e il mondo. Alla fine della campagna
  quella lista è, senza volerlo, il diario del vostro viaggio.
- **Molto raramente** è davvero un frammento. Serve a farti guardare sempre.
- Nessun regalo è mai richiesto, nessuno scade, nessuno si può perdere.

### 3.4 Il Custode ha opinioni sugli abitanti

Reazione fissa e coerente per ogni personaggio ricorrente: è il modo più
economico di far sentire che il mondo è uno solo.

| Chi | Cosa fa il Custode |
|---|---|
| **Lucilla** | Impazzisce. Le corre incontro. È l'unica persona che preferisce a te, e lei lo sa |
| **Orsolo** | Si nasconde. Orsolo dice che i pet non gli piacciono. Al mondo 15 gli porta di nascosto un sasso |
| **Vera** | Vera lo adora e sbaglia il suo nome ogni singola volta, con variazioni sempre più creative |
| **Nima** | Cerca di mangiarle le mappe. Lei ha smesso di stupirsi |
| **Cinabro** | Gli si siede su un piede e non si muove. Cinabro non commenta mai la cosa |
| **Sesto** | Sono migliori amici perché **si dimenticano a vicenda** e si riconoscono ogni volta con enorme sorpresa |
| **Il Tredicesimo** | Non ha paura di lui. È l'unico. Ed è la prima crepa nella diffidenza di Scala |

### 3.5 NORA e il Custode: il duetto

NORA è asciutta, il Custode è un disastro. È la coppia comica del gioco, e costa
solo qualche riga.

> «Il tuo Custode fissa un sasso da quattro minuti. Non commento.»
>
> «Ha portato un altro sasso. È il quarantunesimo. Tengo il conto io perché
> qualcuno deve.»
>
> «Ha starnutito. Stavo per dire una cosa importante. Ora non la ricordo.
> Forse era meglio così.»
>
> «Confermo: si è di nuovo stupito della propria coda. Registro l'evento come
> nuovo, per rispetto.»

Regola: NORA non lo sgrida mai e non lo chiama stupido. È **affetto travestito da
rapporto tecnico**, e diventa più tenero man mano che lei si ricompone — allo
stadio *Che confessa* smette di fingere: «È ridicolo. Mi mancherebbe.»

---

## 4. La schermata del Custode

Si apre con un tocco lungo sul widget, o dalla Bottega.

| Sezione | Contenuto |
|---|---|
| **Ritratto grande** | Il Custode intero, animato, che reagisce mentre lo personalizzi (e ogni tanto fa una combinella lì dentro) |
| **Nome** | Max 12 caratteri, filtro parole vietate, modificabile sempre |
| **Specie** | I Custodi posseduti (catalogo esistente: Cane Scout, Gatto Prisma, Coniglio Luma, Scintilla, Cometa, Orbita, Satellite, Prisma, Luma, Guardiano, Codex) |
| **Livrea** | Colore principale + secondario, sbloccati dal legame |
| **Accessorio** | Collare, fiocco, sciarpina, campanello, ciuffo |
| **Indole** | *Vivace · Calmo · Buffo · Serio* — cambia **come** emote, non cosa fa |
| **Volto a riposo** | L'espressione che tiene quando non succede niente: la sua personalità a colpo d'occhio |
| **Album delle facce** | Le 10 espressioni, quelle bloccate in silhouette, con come si sbloccano |
| **Combinelle viste** | Le 16, come figurine. Collezionare gag invece di oggetti |
| **Cose che ti ha portato** | La collezione dei regali inutili, con data e mondo (§3.3) |
| **Legame** | Quando l'hai preso, quante sessioni insieme, quanti mondi visti |

### 4.1 Perché l'indole è la scelta più importante

Quattro indoli × dieci espressioni × sedici combinelle danno una quantità enorme
di comportamento percepito al prezzo di quattro curve di animazione. Due bambine
con lo stesso Custode dello stesso colore avranno due compagni che si muovono in
modo diverso.

| Indole | Ampiezza | Ritardo | Effetto percepito |
|---|---|---|---|
| Vivace | ×1.35 | 0.0 s | Reagisce subito e tanto |
| Calmo | ×0.75 | 0.4 s | Reagisce dopo, con misura |
| Buffo | ×1.20 | 0.2 s, con rimbalzo | Sopra le righe. Combinelle più frequenti |
| Serio | ×0.85 | 0.1 s, senza rimbalzo | Composto — il che rende le sue figuracce più divertenti |

---

## 5. Il primo Custode: cambio all'economia

Oggi il pet più economico costa **1500 energia** e richiede **livello 4**. Se il
volto è sempre in schermo, il giocatore non può guardare un buco per quattro
livelli.

**Decisione**: il primo Custode è **gratuito e arriva nel mondo 1**, da Lucilla,
subito dopo la prima missione superata. Non è una scelta a catalogo: è un
cucciolo che ti viene affidato — e la prima cosa che fai è **dargli un nome**.
Dare un nome nei primi cinque minuti è ciò che crea l'attaccamento.

Il catalogo esistente non cambia: gli altri Custodi restano obiettivi di lungo
periodo. Cambia solo che ne hai uno da subito.

Da gestire: `pet_companion.gd` deve accettare un Custode **non acquistato in
bottega**; gli slot `pet` restano, ma la schermata diventa il posto dove si
sceglie quale portare; nessun contenuto didattico dipende dal Custode.

---

## 6. Contratti tecnici

### 6.1 Moduli

| Modulo | Responsabilità | Non fa |
|---|---|---|
| `pet_state.gd` | Specie, nome, livrea, accessorio, indole, volto a riposo, legame, espressioni e combinelle sbloccate, regali raccolti | Non tocca mastery, energia, gate |
| `pet_expression_engine.gd` | Segnale → espressione, con priorità e isteresi | Non emette segnali propri |
| `pet_antics.gd` | Combinelle, regali, opinioni sugli abitanti, battute di NORA | Non interrompe mai una sessione |
| `pet_face_widget.gd` | Ritratto sempre visibile, carezza al tocco breve, schermata al tocco lungo | Non decide l'espressione |
| `pet_screen.gd` | Personalizzazione, album, combinelle, regali, storia del legame | Non concede ricompense |
| `pet_companion.gd` | Il corpo che segue Eli (esiste) | Estendere con indole e combinelle |

### 6.2 Priorità delle espressioni

Dalla più alta: `festa` → `beato` (carezza in corso) → `orgoglioso` /
`incoraggiante` (2.2 s) → `impicciato` (2.0 s dopo una combinella) →
`concentrato` (sessione) → `attento` → `curioso` → `offeso` → `assonnato` →
`sereno`. **Isteresi minima 1.2 s** fra due cambi.

### 6.3 Save

```gdscript
"pet": {
    "active": "pet-first",
    "name": "Briciola",
    "livery": [0xf6c85f, 0xffe3a8],
    "accessory": "collar-red",
    "temperament": "vivace",
    "restingFace": "sereno",
    "bond": 0.42,
    "faces": ["sereno","curioso","orgoglioso","incoraggiante","beato"],
    "antics": ["tail","pose","guard","sneeze"],
    "gifts": [ {"item":"sasso","world":3,"day":12} ],
    "sessionsTogether": 37,
    "adoptedAtLevel": 1
}
```

Migrazione non distruttiva: un save senza `pet` riceve il Custode iniziale alla
prima missione superata.

### 6.4 Vincoli

1. Il widget non copre mai elementi interattivi, a nessuna viewport.
2. Con **riduzione del movimento**: espressioni sì, animazioni ampie no (*festa*
   diventa un lampo statico; le combinelle diventano una posa fissa + il volto
   *impicciato*, che è dove sta la battuta).
3. Con **contrasto elevato**: bordo pieno; le espressioni restano distinguibili
   per **forma**, non per colore.
4. Budget: il widget è UI, non aggiunge draw call di mondo. Il corpo nel mondo
   resta uno solo.
5. **Il Custode non parla.** Nessun testo, nessun consiglio scritto: facce, versi
   e azioni. È ciò che lo tiene distinto da NORA e dagli abitanti — e ciò che
   rende funzionanti le battute di NORA su di lui.
6. Nessuna combinella durante un esercizio, un esame o un colpo di scena — con
   l'unica eccezione autorata dello starnuto.

### 6.5 Audit

`pet_expression_audit.gd`:

- ogni segnale di gioco è mappato a un'espressione, senza buchi;
- **nessun segnale di errore, fallimento, scudo perso o missione fallita mappa a
  un'espressione negativa** — e nel catalogo non ne esiste nessuna;
- `offeso` si risolve da solo entro N secondi **senza input del giocatore**;
- priorità e isteresi impediscono più di N cambi al secondo;
- il legame non decresce mai, in nessuna sequenza di eventi;
- nessuna combinella si attiva durante sessione, esame o beat narrativo (salvo
  lo starnuto autorato);
- determinismo: stessa sequenza di segnali → stessa sequenza di espressioni.

---

## 7. Piano di lavoro

| Fase | Contenuto |
|---|---|
| **P1** | `pet_state.gd`, save, Custode iniziale gratuito da Lucilla nel mondo 1, con il nome dato dal giocatore |
| **P2** | `pet_face_widget.gd` con 5 espressioni, carezza al tocco, `pet_expression_engine.gd` |
| **P3** | `pet_antics.gd`: le prime 4 combinelle + volto *impicciato* + le battute di NORA |
| **P4** | `pet_screen.gd`: nome, livrea, indole, volto a riposo |
| **P5** | Legame, sblocco di espressioni e combinelle, album, regali inutili |
| **P6** | *Curioso* e *attento* agganciati a POI e zone sbiadite; opinioni sugli abitanti |
| **P7** | Indole applicata anche al corpo nel mondo (`pet_companion.gd`) |

P1+P2+P3 insieme cambiano già la sensazione del gioco: un compagno con un nome,
una faccia che reagisce, che si può accarezzare e che ogni tanto fa una figura
barbina mentre NORA prende appunti.
