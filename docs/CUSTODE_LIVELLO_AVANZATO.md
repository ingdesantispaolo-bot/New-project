# Il Custode a livello avanzato — studio

4 agosto 2026. Documento di studio: dice cosa c'è, cosa manca, e che cosa
significa «avanzato» per un compagno che per contratto non deve servire a niente.

Riferimento del progetto: [PET_CUSTODE.md](PET_CUSTODE.md). Questo file non lo
sostituisce: ne misura lo scarto e propone dove andare.

---

## 1. Cosa c'è davvero, misurato sul codice

Il piano di lavoro in `PET_CUSTODE.md` §7 arriva a P7. Lo stato reale:

| Fase | Stato | Verificato su |
|---|---|---|
| **P1** stato, save, Custode da Lucilla | fatto | `pet_state.gd` |
| **P2** volto, 10 espressioni, carezza | fatto | `pet_face_widget.gd`, `pet_expression_engine.gd` |
| **P3** combinelle + *impicciato* | **4 su 16**, battute di NORA assenti | `pet_antics.gd` |
| **P4** schermata Custode | fatto | `pet_screen.gd` |
| **P5** legame, sblocchi, album, regali | **metà**: le facce si sbloccano, le combinelle no, i regali non esistono | `pet_state.gd` |
| **P6** lettura del mondo, opinioni sugli abitanti | **assente** | nessun emettitore |
| **P7** indole nel corpo del Custode | fatto | `pet_companion.gd` |

### 1.1 I cinque buchi, in ordine di gravità

**a) Lo starnuto non esiste.** `pet_antics.gd` ha un ramo dedicato: durante un
esercizio, un esame o un beat, l'unica combinella ammessa è `sneeze`. Ma
`sneeze` non è nel `CATALOG`. Il ramo è morto per costruzione: dentro un
esercizio il Custode non fa mai niente, e la gag progettata — starnutire nel
momento più solenne, con NORA che perde il filo — non può accadere.

**b) Il repertorio non cresce mai.** `BOND_UNLOCKS` contiene solo espressioni.
`PetState.antics()` restituisce sempre e solo le quattro di base. Un bambino a
legame pieno dopo venti mondi vede esattamente le stesse quattro combinelle del
primo giorno. La promessa «fino a sedici» non è mantenuta da nessuna riga.

**c) I regali non arrivano.** `gifts` è nel salvataggio, `pet_screen.gd` lo legge
e ne stampa il numero, ma **nessuno lo scrive**. La collezione «Cose che ti ha
portato» — che secondo il progetto a fine campagna è il diario del viaggio — è
vuota per sempre, e il contatore nella schermata dice zero a tutti.

**d) Il Custode non ha opinioni.** §3.4 elenca sette reazioni fisse agli
abitanti ricorrenti. Nel codice non ce n'è nessuna: il Custode attraversa Lucilla,
Orsolo e il Tredicesimo senza accorgersene.

**e) Il duetto con NORA non c'è.** §3.5 è la coppia comica del gioco e costa solo
righe di testo. Zero righe scritte.

In più, due segnali dichiarati e mai emessi: `near_unexplored` e `near_faded`.
Le espressioni *curioso* e *attento* si sbloccano col legame e poi non compaiono
mai, perché nulla le innesca.

---

## 2. Che cosa vuol dire «avanzato»

Il rischio di questa richiesta è ovvio: rendere il Custode avanzato aggiungendogli
**poteri**. Un aiuto in più, un indizio sulla risposta, energia, uno sconto sul
gate. Sarebbe un errore, e il progetto lo sa già — `pet_state.gd` lo dichiara in
testa: *il legame non sblocca vantaggi di gioco*.

La ragione è che nel momento in cui il Custode diventa utile, il bambino comincia
a **ottimizzarlo**: quante coccole servono, quando conviene, cosa sblocca cosa. Un
compagno ottimizzato non è più un compagno, è un'interfaccia. E la cosa che il
Custode fa davvero — stare lì mentre sbagli, senza valutarti — smette di
funzionare nel momento in cui vale punti.

Quindi: **tutto l'avanzamento va in carattere, niente in potere.** Tre assi.

### Asse A — Da reattivo a *memore*

Oggi il Custode risponde a un segnale e torna sereno. Non ricorda niente.

Avanzato è un compagno che tira fuori **cose vostre**: il quarantunesimo sasso,
il mondo in cui l'ha raccolto, la volta che si è addormentato durante l'esame.
I regali datati e localizzati sono già progettati per questo, e sono il pezzo
più economico con l'effetto più lungo: a fine campagna quella lista è un diario
che nessuno ha dovuto scrivere.

### Asse B — Da reattivo a *iniziativa*

Oggi ogni espressione arriva dopo qualcosa che ha fatto il bambino. Avanzato è
il Custode che si muove **per primo**: guarda verso un punto d'interesse che non
avete visitato, si irrigidisce vicino a una zona sbiadita, e — questo è il pezzo
delicato — reagisce a *come sta andando la prova*, non a com'è andata.

Il caso che conta: **tre errori sullo stesso argomento**. Oggi non succede niente,
o meglio: il Custode fa *incoraggiante* ogni volta, che alla terza è rumore.
Avanzato è che alla terza **sdrammatizza**: si mette davanti allo schermo, o
starnutisce. Non aiuta — non deve — ma rompe la spirale. È l'unico momento in cui
un compagno serve davvero a qualcosa, ed è emotivo, non meccanico.

### Asse C — Da personaggio singolo a *relazione a tre*

NORA asciutta, il Custode disastro, Eli in mezzo. È il moltiplicatore più
economico del gioco: righe di testo, nessun sistema nuovo, e cambia la
percezione di entrambi i personaggi. Il Custode diventa più buffo perché
qualcuno lo commenta; NORA diventa più tenera perché qualcosa la disarma.

E ha un arco: allo stadio *Che confessa*, NORA smette di fingere.

---

## 3. Piano proposto, in ordine di resa

| # | Intervento | Costo | Resa | Stato |
|---|---|---|---|---|
| 1 | **Le 16 combinelle + lo starnuto**, sbloccate dal legame | dati | alta — ripara un ramo morto e mantiene una promessa | **fatto** |
| 2 | **I regali inutili**: raccolta, data, mondo, album | piccolo sistema | alta e crescente nel tempo | **fatto** |
| 3 | **Il duetto con NORA** su combinella e regalo | testo | alta | **fatto** |
| 4 | **Le opinioni sugli abitanti** all'apertura del dialogo | testo | media-alta | **fatto** |
| 5 | **Sdrammatizza al terzo errore** sullo stesso argomento | piccolo | alta ma delicata | da fare |
| 6 | **Lettura del mondo**: *curioso* e *attento* su POI e sbiadito | medio | media | da fare |

I primi quattro sono in `pet_antics.gd`, `pet_gifts.gd`, `pet_state.gd` e
`outdoor_world.gd`, e li tiene `pet_advanced_audit`: sedici combinelle tutte
raggiungibili, sedici regali, sette opinioni, legame monotono, e dentro una
prova solo lo starnuto. L'audit è stato provato togliendo `sneeze` dal catalogo:
diventa rosso su quattro righe.

Il 5 e il 6 restano aperti di proposito. Il 5 tocca il ciclo dell'esercizio nel
punto più delicato — un bambino bloccato — e la differenza fra «mi ha fatto
ridere quando ero fermo» e «mi ha distratto mentre pensavo» la dice il collaudo,
non un audit.

---

## 4. I guard-rail che questo lavoro non può rompere

Sono già nel codice e restano:

1. **Nessuna espressione negativa.** `NEGATIVE_FACES` è vuota per costruzione.
   Nemmeno la nuova reazione al terzo errore può essere delusione: *impicciato* e
   *incoraggiante* sono comiche o affettuose, mai valutative.
2. **Il legame sale e non scende mai.** Niente fame, niente decadimento, niente
   senso di colpa per chi torna dopo tre giorni.
3. **Nessun vantaggio di gioco.** Né mastery, né energia, né aiuti, né sconti sul
   gate. Solo espressioni, combinelle, regali e battute.
4. **Mai durante una prova, tranne lo starnuto.** E lo starnuto è raro apposta:
   una gag che capita spesso non è più una gag, è un'interruzione.
5. **Nessun contatore visibile sulle coccole.** Non devono mai sembrare un
   compito.
