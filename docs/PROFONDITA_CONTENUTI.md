# Eli Quest — Profondità dei contenuti · tabella di marcia

> Obiettivo dichiarato dall'utente (31 luglio): **dopo cinquanta partite lo
> studente deve ancora incontrare esercizi vari, e avere voglia di farne altre
> cento.** Questo documento dice quanto è grande il problema, perché la strada
> ovvia non funziona, e in quali passi si costruisce quella che funziona.
>
> Misure di partenza in [insieme.md](../insieme.md) («le prove si ripetono»),
> strumento di misura in `godot/scripts/game/variety_audit.gd`.

---

## 1. Quanto serve davvero: il conto

Per mondo il direttore piazza **18 eventi**: 5 della materia ospite + 2 di
surplus + 11 di varietà. Una missione vale 3 campate, un enigma 4, un minigioco 4.

Su una campagna intera (24 mondi) ogni materia viene incontrata:

- come **ospite** di 2 mondi → ~50 campate;
- come **varietà** negli altri 22 → ~88 campate.

**≈ 138 campate per materia, per partita.** Per cinquanta partite senza ripetersi
servono **≈ 7.000 esercizi distinti per materia**, cioè **≈ 84.000 in tutto**.

### Perché autorare non è una strada

Oggi ci sono ~2.200 item nei banchi e ~250 specifiche di minigioco. Arrivare a
84.000 esercizi scritti a mano è fuori scala di due ordini di grandezza: non è una
questione di impegno, è una questione di aritmetica. E non servirebbe nemmeno a
una seconda partita, perché gli esercizi scritti restano gli stessi.

**La profondità non si autora: si genera.** Una specifica che *pesca* i suoi
elementi da un insieme produce combinazioni, non copie.

### Il conto che rende il problema risolvibile

Una prova di abbinamento che estrae **4 coppie da un insieme di 32** produce
C(32,4) = **35.960** prove diverse. Una sola specifica supera da sola il bisogno
di cinquanta partite.

| Estrazione | Insieme minimo | Combinazioni |
|---|---|---|
| 3 elementi | 40 | 9.880 |
| 4 elementi | 24 | 10.626 |
| 5 elementi | 18 | 8.568 |
| 6 elementi | 15 | 5.005 |

**Regola operativa: ogni insieme deve superare le 10.000 combinazioni.** In pratica
significa **24–32 elementi per ciascuna coppia (materia, formato)**.

### La dimensione reale del lavoro

12 materie × 6 formati = **72 insiemi** da ~28 elementi = **≈ 2.000 elementi da
autorare**.

Duemila invece di ottantaquattromila. È questo il motivo per cui la
parametrizzazione viene prima di qualunque aggiunta di contenuto: **fa la
differenza fra un lavoro possibile e uno impossibile.**

---

## 2. Stato di partenza, misurato

| Materia | Item banco | Secchi magri (<5) | Spec minigioco | Peggiore ripetizione |
|---|---|---|---|---|
| musica | 29 | 14/15 | 20 | ×3 |
| storia | 30 | 19/19 | 19 | ×3 |
| logica | 38 | 7/11 | 26 | ×6 |
| scienze | 38 | 28/28 | 24 | ×7 |
| coding | 42 | 30/30 | 22 | ×4 |
| fisica | 43 | 23/24 | 21 | ×8 |
| elettronica | 50 | 17/20 | 19 | ×4 |
| latino | 80 | 16/22 | 16 | ×4 |
| geografia | 102 | 22/29 | 20 | ×2 |
| matematica | 284 | 0/4 | 24 | ×4 |
| italiano | 326 | 0/19 | 33 | ×3 |
| inglese | 1101 | 3/40 | 25 | ×6 |

«Secchi magri» = coppie (argomento, difficoltà) con meno di 5 item: in otto
materie la **mediana è 1**. Quando il selettore sceglie quell'argomento a quella
difficoltà, esiste un solo esercizio.

Nota importante: **la colonna dei banchi conta meno di quanto sembri.** Dalla
decisione del 29 luglio la scelta multipla è ~10–20% delle campate: l'80% passa
dalle specifiche di minigioco. È lì che si vince o si perde.

---

## 3. Il meccanismo: specifiche parametriche

Oggi una specifica è un dato fisso:

```gdscript
{"topic": "classi-parole", "pairs": [["gatto","nome"], ["correre","verbo"], …]}
```

Diventa un insieme da cui pescare:

```gdscript
{"topic": "classi-parole", "kind": "pool", "draw": 4,
 "pool": [["gatto","nome"], ["correre","verbo"], … 32 voci …]}
```

Requisiti del meccanismo (contratto):

1. **Deterministico a parità di seed** — vincolo esistente del progetto.
2. **Estrazione senza collisioni**: mai due elementi con la stessa risposta nella
   stessa prova, mai una prova già presentata di recente (la memoria
   anti-ripetizione esiste già, finestra 24).
3. **Distrattori onesti**: i distrattori vengono dall'insieme, quindi sono sempre
   plausibili — e restano validi i guard-rail del 29 luglio (nessun indizio di
   lunghezza, nessuna posizione privilegiata, nessun ordinamento già risolto).
4. **Coesistenza**: specifiche statiche e a insieme convivono, così la migrazione
   è incrementale e ogni passo è spedibile.
5. **Gate per livello invariato**: `minLevel` continua a valere sull'insieme.

---

## 4. Tabella di marcia

Ogni tappa è **spedibile e misurata**: si chiude quando `variety_audit` mostra il
miglioramento atteso, non quando il contenuto «sembra abbastanza».

### Fase 0 — L'infrastruttura ✅ chiusa il 31 luglio 2026

Il meccanismo delle specifiche a insieme (`ExercisePool`), la coesistenza con
quelle statiche, e la misura di **profondità combinatoria** per (materia, formato)
— non più solo le ripetizioni osservate. Senza questa misura non si sa quando una
materia è «finita».

Strada facendo è emerso un terzo pezzo, non previsto e più importante degli altri
due: **l'identità di contenuto** (`ExerciseSignature`). Esistevano tre definizioni
diverse di «stessa prova» e nessuna guardava il contenuto, quindi la memoria
anti-ripetizione era spenta sui formati specialisti e la misura contava le
presentazioni. Senza una firma sola, la profondità aggiunta nelle Fasi 1–3 sarebbe
stata invisibile sia al gioco sia agli audit — cioè inutile.

Primo responso della misura: **1 coppia (materia, formato) su 67** raggiunge le
10.000 combinazioni, ed è l'ordinamento generato di matematica. Undici materie su
dodici producono fra 6 e 124 prove distinte: la prima partita esaurisce già il
materiale. Il dettaglio per materia è in [insieme.md](../insieme.md).

> **Nota del 3 agosto 2026.** Questo documento descrive un piano *chiuso*, che
> aveva un obiettivo solo — non ripetersi. L'obiettivo corrente è più alto
> (massima qualità per ogni mondo, livello e materia) e il piano vivo è in
> [insieme.md](../insieme.md), sezione «Massima qualità dei contenuti». Le misure
> qui sotto restano vere ma sono campionate su **due livelli su ventiquattro**:
> è il motivo per cui non vedevano che il contenuto smette di crescere al mondo 6.

*Esito: nessun contenuto nuovo, come previsto. La varietà è comunque migliorata
dove la memoria anti-ripetizione era rotta (fisica ×8 → ×4, scienze ×7 → ×5,
inglese ×6 → ×2). Suite 79/79.*

### Fase 1 — Il nucleo: italiano, matematica, inglese ✅ chiusa il 31 luglio 2026

Sono le materie che gatano ogni livello, quindi le più incontrate in assoluto.
~700 elementi autorati su abbinamento, smistamento e ordinamento.

Esito: **italiano 39 → 8.074.778**, **inglese 80 → 7.785.076**, **matematica
132.110 → 407.510** prove distinte producibili. Ripetizione del nucleo **×1, 0–3%**
— oltre il bersaglio finale. Coppie sopra le 10.000 combinazioni: da 1 a 9 su 67.

Tre lezioni che cambiano come si scrivono le Fasi 2–3:

- **l'abbinamento regge la profondità solo con risposte uniche.** I contenuti «a
  categoria» (classe grammaticale, tempo verbale, parte del discorso) non possono
  crescere lì senza diventare ambigui: vanno nello smistamento;
- **lo smistamento è il formato più profondo del progetto.** Poche categorie
  leggibili, molte tessere, `draw` che ne pesca sei: da solo vale milioni;
- **l'ordinamento si parametrizza solo su una proprietà misurabile** (alfabeto,
  valore). Il riordino di una frase resta a dato fisso, e va bene così.

*Esito atteso raggiunto e superato: il nucleo è già al bersaglio della Fase 5.*

### Fase 2 — I banchi magri ✅ chiusa il 31 luglio 2026

musica, storia, scienze, coding, fisica, elettronica. ~1.100 elementi.

Esito: **coding 7.666.565**, **fisica 248.258**, **musica 243.414**, **scienze
221.329**, **elettronica 213.551**, **storia 133.313**. Tutte e sei fra ×2 e ×3,
cioè al bersaglio finale. Nove materie su dodici sono a posto; coppie sopra le
10.000 combinazioni da 9 a **17 su 67**.

La lezione di questa fase: **l'ordinamento è profondo ovunque l'ordine sia una
grandezza** — l'anno di un evento storico, i km/h, i kg, i BPM di un tempo
musicale, i volt. Non dove è una convenzione da ricordare (i casi latini, i passi
di un algoritmo): lì resta a dato fisso, ed è giusto così.

Con un vincolo di età che vale per ogni insieme futuro: **un insieme profondo può
produrre estrazioni impossibili.** Ventotto eventi storici pescati a tre possono
dare tre date che a dieci anni non si conoscono. La soluzione non è ridurre
l'insieme, ma affiancarne uno più facile ai primi mondi e gatare il grande con
`minLevel`.

### Fase 3 — Le restanti ✅ chiusa il 31 luglio 2026

latino, geografia, logica. ~600 elementi.

Esito: **geografia 7.791.351**, **latino 297.163**, **logica 133.892**. Dodici
materie su dodici entro il bersaglio; la più povera (storia, 133.313) ha circa
mille volte il fabbisogno di una partita.

Ogni materia ha richiesto una strategia diversa — è la lezione più utile del
piano intero:

- **geografia**: quasi ogni ordine è una grandezza e quasi ogni fatto è una
  coppia unica. La più facile da rendere profonda;
- **latino**: l'ordine è convenzione pura, quindi l'ordinamento resta fisso e
  tutta la profondità viene da smistamento e abbinamento;
- **logica**: la profondità non viene da più elementi ma da **più regole**. E
  ogni insieme di analogie deve essere **una relazione sola**, altrimenti
  l'abbinamento si indovina per associazione.

*Cricchetti finali: 0,17 · ×4 — la quota di ripetizioni è sotto il bersaglio
(0,20); il ×4 residuo è la caccia all'errore di logica ai primi mondi, che è
Fase 4.*

### Fase 4 — Profondità di secondo livello ✅ chiusa il 31 luglio 2026

Non più varietà, ma **ricchezza**. Tre interventi:

1. **gradiente di difficoltà dentro la sessione** — prima ogni minigioco di un
   mondo aveva la stessa identica difficoltà. Ora riscaldamento, corpo, sfida, con
   la media invariata. Le bande estreme smettono di sparire di colpo;
2. **bande vuote dei banchi** — musica e fisica avevano tre item a difficoltà 1,
   coding uno a difficoltà 4. 89 item nuovi su sette materie;
3. **musica al primo mondo** — da otto abbinamenti possibili a 375.

Due errori corretti in corsa, entrambi istruttivi: legare il numero di tessere
alla difficoltà *assoluta* invece che al passo del gradiente fa crollare la
profondità dei primi mondi (misurato: 200.000 → 15.000); e scrivere item nuovi con
la risposta sempre in prima posizione è un indizio gratuito che `giveaway_audit`
prende subito.

Il risultato inatteso: le sessioni con lo stesso argomento nello stesso formato
sono passate da 72 a **zero**. Non era un problema di insiemi poveri come avevo
scritto qui sopra — era la **selezione**, che pescava dal banco senza guardare
quali argomenti fossero già nella sessione.

### Fase 5 — Il cricchetto al bersaglio ✅ assorbita dalle fasi 3–4

I tre cricchetti sono attivi e difendono il risultato:

| | valore | direzione |
|---|---|---|
| `MAX_REPEAT_SHARE` | 0,17 | solo giù |
| `MAX_SAME_EXERCISE` | ×4 | solo giù |
| `MAX_SAME_TOPIC_SESSIONS` | 0 | assoluto |
| `DEPTH_FLOOR` per materia | 133.313 – 8.074.778 | solo su |
| `MIN_SUBJECT_DEPTH` | 1.380 | soglia di sufficienza |

Il bersaglio dichiarato all'inizio era ×3 · 0,20. La quota di ripetizioni è sotto
(0,17); il ×4 residuo è la caccia all'errore di logica ai primi mondi, che è un
formato a dato fisso: portarlo a ×3 vuol dire più specifiche specialiste ai
livelli bassi, non altro contenuto a insieme.

---

## 5. Come si misura il progresso

`variety_audit` è il giudice, e i suoi due numeri sono l'unico rendiconto che
conta. Vanno **solo in discesa**: chi li alza sta nascondendo una regressione.

| Tappa | MAX_SAME_EXERCISE | MAX_REPEAT_SHARE | Insiemi convertiti |
|---|---|---|---|
| prima della Fase 0 | 8 | 0,38 | 0/72 · *misura non onesta* |
| oggi (Fase 0) | 8 | 0,67 | 0/72 |
| Fase 1 | 5 | 0,32 | 18/72 |
| Fase 2 | 3 | 0,25 | 54/72 |
| Fase 3 | 3 | 0,20 | 72/72 |
| Fase 5 | 3 | 0,20 | + soglia combinatoria |

---

## 6. Vincoli che non si toccano

Valgono per ogni elemento aggiunto, in ogni fase:

- **Nessun esercizio ambiguo o senza spiegazione.** La spiegazione è contenuto,
  non decorazione: è ciò che rende l'errore istruttivo.
- **I guard-rail del 29 e 30 luglio restano**: nessun indizio di lunghezza nei
  distrattori, nessuna posizione privilegiata della risposta, nessun ordinamento
  presentato già risolto, nessun argomento fuori dal registro della materia.
- **Fascia 10–13**: ogni elemento nuovo va tarato sulla banda del suo livello.
- **Determinismo per seed**: due partite con lo stesso seed restano identiche.
- **Ogni fase è spedibile**: mai un passaggio che lascia il gioco a metà.
