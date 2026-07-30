# Eli Quest — Il Custode (pet compagno)

> Specifica del compagno personalizzabile, del suo **volto sempre visibile** e
> della schermata dedicata.
> Trama in [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md), abitanti in
> [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md), economia in
> [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md) §7–8.

---

## 1. La decisione di design

Un pet è il richiamo più forte che esista per il pubblico di questo gioco. Vale
la pena costruirlo bene, e vale la pena essere severi su cosa **non** deve fare.

**Il Custode è tre cose insieme, in quest'ordine di importanza:**

1. **Uno specchio affettivo.** Il suo volto reagisce a ciò che succede nella
   sessione. È l'unico canale di feedback del gioco che non valuta mai: NORA dà
   il metodo, l'HUD dà i numeri, gli abitanti danno il contesto — il Custode dà
   solo compagnia.
2. **Una bussola morbida.** Reagisce alla presenza di significato: si illumina
   dove c'è qualcosa da capire, si fa attento vicino alle zone sbiadite. Guarda
   il suo muso e sai dove andare, senza una freccia sullo schermo.
3. **Un oggetto di storia.** I Custodi sono creature dei Primi che **sentono il
   significato**. Sono la ragione per cui il Silenzio non ha vinto ovunque:
   dove c'è un Custode, resta un filo. Ecco perché il suo volto è sempre in
   vista — è uno strumento, non un adesivo.

### 1.1 Cosa il Custode non fa, e perché

| Non fa | Perché |
|---|---|
| **Non ha fame, non si sporca, non si ammala** | Un ciclo di accudimento a decadimento produce senso di colpa quando il bambino non gioca. Un gioco che si studia non può punire chi torna dopo tre giorni |
| **Non è mai triste per un tuo errore** | È il vincolo più importante di tutti. Vedere il proprio compagno deluso dopo una risposta sbagliata è vergogna, e la vergogna spegne l'apprendimento. All'errore il Custode fa la faccia **incoraggiante**, sempre |
| **Non dà mastery, energia o aiuti in esame** | Vale il guard-rail del progetto: nessuna ricompensa scavalca una prova di competenza |
| **Non muore, non si perde, non va via** | Nessuna leva di ansia |
| **Non chiede acquisti per restare felice** | Il legame cresce giocando, non spendendo |

---

## 2. Il volto sempre visibile

### 2.1 Il widget

Un **ritratto circolare** di ~76 px, ancorato all'angolo, sempre in campo nel
mondo esterno, nella nave e durante gli esercizi. Contiene:

- il **muso** del Custode, disegnato in vettoriale come già fa
  `OutdoorVisualFactory.build_pet()` (nessuna nuova pipeline di asset);
- l'**espressione** corrente;
- un **anello di legame** sottile attorno, che si completa lentamente;
- il **nome** che gli hai dato, in piccolo, sotto.

Durante una sessione di esercizi resta visibile ma si sposta in un angolo
neutro, e **non copre mai** prompt, opzioni o pulsanti. È l'unico elemento
dell'HUD che sopravvive a tutte le schermate: è la costante affettiva del gioco.

### 2.2 Le espressioni

Otto stati, con precise regole di attivazione. Nessuno è negativo.

| Espressione | Quando | Come si legge |
|---|---|---|
| **Sereno** | riposo, niente di rilevante | Occhi morbidi, respiro lento. È il volto base, scelto nella personalizzazione |
| **Curioso** | vicino a un POI mai affrontato, a una Traccia non trovata, a un abitante con qualcosa di nuovo | Orecchie su, testa inclinata verso la direzione giusta |
| **Attento** | dentro o vicino a una zona sbiadita / uno Sbiadito | Immobile, pelo dritto, luce che si abbassa. Mai spaventato |
| **Concentrato** | è in corso un esercizio; ancora di più se l'argomento è in ripasso | Occhi socchiusi, fermo, guarda nella stessa direzione di Eli |
| **Incoraggiante** | **risposta sbagliata** | Si avvicina, sguardo caldo, piccolo colpetto. Nessuna tristezza, nessun sospiro |
| **Orgoglioso** | risposta corretta | Petto in fuori, coda alta |
| **Festa** | combo, missione superata, apparato riparato, argomento consolidato | Salta, scintille, l'unica animazione ampia |
| **Assonnato** | inattività prolungata, fase notte | Sbadiglia, si accuccia. Invito gentile a chiudere la sessione |

**Regola vincolante**: la mappa da segnale a espressione è dichiarata in una
tabella dati e verificata da audit. Nessun segnale di errore, fallimento o
mancanza può produrre un'espressione negativa, perché di espressioni negative
**non ne esistono**.

### 2.3 Le espressioni come guida

Le due espressioni "di lettura del mondo" — *curioso* e *attento* — sono il modo
in cui il gioco orienta senza indicatori invadenti:

- **Curioso** punta verso la cosa interessante più vicina non ancora affrontata,
  con un raggio pari a metà dello `streamRadius`. È esattamente il compito che a
  Nima è affidato a parole: il Custode lo fa in silenzio, sempre.
- **Attento** segnala che lì attorno c'è qualcosa che ha perso il significato.
  È l'unico modo, oltre alla saturazione della scena, in cui il Silenzio si
  annuncia.

Entrambe hanno una priorità **inferiore** a quelle di sessione: durante un
esercizio il Custode è concentrato, non curioso.

### 2.4 Il legame

Un valore 0→1 che sale, non scende mai.

- **Sale** al termine di ogni sessione giocata con impegno (superata o no: conta
  aver provato), quando aiuti un abitante, quando spieghi qualcosa a Vera.
- **Non sale** comprando, e non scende con l'inattività.
- **Sblocca espressioni**: si parte con 4 (sereno, curioso, orgoglioso,
  incoraggiante) e si arriva a 8. Le ultime due, *festa* e *assonnato*, arrivano
  tardi e sono percepite come un regalo.
- **Non sblocca vantaggi di gioco.** Mai.

---

## 3. La schermata del Custode

Raggiungibile dal widget stesso (toccarlo la apre) e dalla Bottega.

### 3.1 Cosa contiene

| Sezione | Contenuto |
|---|---|
| **Ritratto grande** | Il Custode intero, animato, che reagisce mentre lo personalizzi |
| **Nome** | Campo di testo, max 12 caratteri, filtro di parole vietate, modificabile sempre |
| **Specie** | I Custodi posseduti (catalogo esistente: Cane Scout, Gatto Prisma, Coniglio Luma, Scintilla, Cometa, Orbita, Satellite, Prisma, Luma, Guardiano, Codex) |
| **Livrea** | Colore principale + secondario. Le combinazioni sbloccate crescono col legame, non col prezzo |
| **Accessorio** | Collare, fiocco, sciarpina, campanello, ciuffo. Cosmetici brevi, acquistabili con energia |
| **Indole** | *Vivace · Calmo · Buffo · Serio* — cambia **come** emote (ampiezza, velocità, tempo di ritardo), non cosa fa |
| **Volto a riposo** | Quale espressione tiene quando non succede niente. È la sua "personalità" a colpo d'occhio |
| **Album delle facce** | Le 8 espressioni, quelle bloccate in silhouette, con scritto come si sbloccano |
| **Legame** | Anello con la storia: quando l'hai preso, quante sessioni insieme, quanti mondi visti |

### 3.2 Perché l'**indole** è la scelta più importante

Quattro indoli × otto espressioni danno **32 comportamenti percepiti** al prezzo
di quattro curve di animazione. È il modo più economico esistente di far sentire
un pet come *proprio*: due bambine con lo stesso Custode dello stesso colore
avranno due compagni che si muovono in modo diverso.

| Indole | Ampiezza | Ritardo | Effetto percepito |
|---|---|---|---|
| Vivace | ×1.35 | 0.0 s | Reagisce subito e tanto |
| Calmo | ×0.75 | 0.4 s | Reagisce dopo, con misura |
| Buffo | ×1.20 | 0.2 s, con rimbalzo | Sopra le righe, comico |
| Serio | ×0.85 | 0.1 s, senza rimbalzo | Composto, quasi professionale |

---

## 4. Il primo Custode: cambio all'economia

Oggi il pet più economico costa **1500 energia** e richiede **livello 4**. Se il
volto del Custode è sempre in schermo, il giocatore non può passare quattro
livelli guardando un buco.

**Decisione**: il primo Custode è **gratuito e arriva nel mondo 1**, da Lucilla,
subito dopo la prima missione superata. Non è una scelta tra tutti: è un cucciolo
senza nome che ti viene affidato — e la prima cosa che fai è **dargli un nome**.
Dare un nome nei primi cinque minuti è ciò che crea l'attaccamento.

Il catalogo esistente **non cambia**: gli altri Custodi restano obiettivi di
lungo periodo da 1500 a 6800 energia. Cambia solo che ne possiedi uno da subito
e che cambiarli è una scelta, non un accesso.

Effetti collaterali da gestire:

- `pet_companion.gd` deve accettare un Custode **non equipaggiato dalla bottega**
  (il regalo iniziale non è un cosmetico acquistato);
- gli slot `pet` della bottega restano, ma la schermata del Custode diventa il
  posto dove si sceglie quale portare;
- nessun contenuto didattico dipende dal Custode: chi lo rifiuta gioca uguale.

---

## 5. Contratti tecnici

### 5.1 Moduli

| Modulo | Tipo | Responsabilità | Non fa |
|---|---|---|---|
| `pet_state.gd` | dati/logica | Specie, nome, livrea, accessorio, indole, volto a riposo, legame, espressioni sbloccate | Non tocca mastery, energia, gate |
| `pet_expression_engine.gd` | logica pura | Segnale di gioco → espressione, con priorità e isteresi | Non emette segnali propri |
| `pet_face_widget.gd` | UI | Ritratto sempre visibile, anello di legame, apertura schermata | Non decide l'espressione |
| `pet_screen.gd` | UI | Personalizzazione, album, storia del legame | Non concede ricompense |
| `pet_companion.gd` | scena (esiste) | Il corpo che segue Eli nel mondo | Estendere con indole ed espressione |

### 5.2 Priorità delle espressioni

Dalla più alta: `festa` → `orgoglioso` / `incoraggiante` (2.2 s) →
`concentrato` (durante sessione) → `attento` → `curioso` → `assonnato` →
`sereno`. **Isteresi minima 1.2 s** fra due cambi, per evitare il muso che
sfarfalla.

### 5.3 Save

```gdscript
"pet": {
    "active": "pet-first",
    "name": "Briciola",
    "livery": [0xf6c85f, 0xffe3a8],
    "accessory": "collar-red",
    "temperament": "vivace",
    "restingFace": "sereno",
    "bond": 0.42,
    "faces": ["sereno","curioso","orgoglioso","incoraggiante"],
    "sessionsTogether": 37,
    "adoptedAtLevel": 1
}
```

Migrazione non distruttiva: un save senza `pet` riceve il Custode iniziale alla
prima missione superata, come un giocatore nuovo.

### 5.4 Vincoli

1. Il widget non copre mai elementi interattivi, a nessuna viewport.
2. Con **riduzione del movimento** attiva: espressioni sì, animazioni ampie no
   (*festa* diventa un lampo statico).
3. Con **contrasto elevato**: il ritratto guadagna un bordo pieno; le espressioni
   restano distinguibili per **forma**, non per colore.
4. Budget: il widget è UI, non aggiunge draw call di mondo. Il corpo nel mondo
   resta uno solo, come oggi.
5. Il Custode **non parla**. Nessun testo, nessun consiglio scritto: solo facce.
   È ciò che lo tiene distinto da NORA e dagli abitanti.

### 5.5 Audit

`pet_expression_audit.gd` deve verificare:

- ogni segnale di gioco è mappato a un'espressione, senza buchi;
- **nessun segnale di errore, fallimento, scudo perso o missione fallita mappa a
  un'espressione negativa** (e non ne esiste nessuna nel catalogo);
- le priorità e l'isteresi impediscono più di N cambi al secondo;
- il legame non decresce mai, in nessuna sequenza di eventi;
- le espressioni bloccate non sono mai selezionabili né mostrate come attive;
- determinismo: stessa sequenza di segnali → stessa sequenza di espressioni.

---

## 6. Piano di lavoro

| Fase | Contenuto | Verificabile con |
|---|---|---|
| **P1** | `pet_state.gd`, save, Custode iniziale gratuito da Lucilla nel mondo 1 | Si possiede un Custode dopo la prima missione |
| **P2** | `pet_face_widget.gd` con 4 espressioni e `pet_expression_engine.gd` | `pet_expression_audit`, screenshot desktop/tablet |
| **P3** | `pet_screen.gd`: nome, livrea, indole, volto a riposo | Personalizzazione persistente al riavvio |
| **P4** | Legame, sblocco delle 8 espressioni, album | Legame monotono crescente |
| **P5** | *Curioso* e *attento* agganciati a POI e zone sbiadite | Il muso indica davvero il POI più vicino |
| **P6** | Indole applicata anche al corpo nel mondo (`pet_companion.gd`) | Playthrough, riduzione movimento |

P1+P2 da sole cambiano già la sensazione del gioco: un compagno con un nome e una
faccia che reagisce. Il resto è approfondimento.
