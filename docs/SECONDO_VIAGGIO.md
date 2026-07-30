# Eli Quest — Il Secondo Viaggio

> Il gioco che si sblocca **finendo il primo**. Non è un New Game+, non è un
> epilogo, non è una modalità di ripasso travestita: è un secondo gioco con un
> loop invertito e un salvataggio proprio.
> Trama in [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md) §8, abitanti in
> [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md), Custode in
> [PET_CUSTODE.md](PET_CUSTODE.md).

---

## 1. L'idea in una riga

> **Nel primo gioco impari. Nel secondo insegni.**

Le undici sorelle costruite da NORA prima di Eli sono vive, sparse fuori dal
circuito, sbiadite: sanno *fare* e non sanno più *perché*. Il tuo lavoro non è
più rispondere. È **capire che errore sta facendo qualcun altro** e scegliere
come spiegarglielo.

E l'opzione «dille la risposta» è sempre lì, funziona subito, e la peggiora.
La tesi di tutto il primo gioco, resa giocabile.

E oltre le undici, molto più in là, c'è **Meridiana**: la ragazzina che
quattrocento anni fa è andata a vedere cosa c'è al fondo del Silenzio, è rimasta
trattenuta là dentro, e ha lasciato acceso un messaggio di tre parole. Il
Secondo Viaggio è il viaggio per andarla a prendere — e per sentire cosa ha
visto, che potrebbe non coincidere con la risposta che il primo gioco ti ha
fatto trovare.

---

## 2. Perché è la scelta giusta per un seguito

| Ragione | |
|---|---|
| **È il livello di apprendimento più alto che esista** | Spiegare a qualcun altro batte qualunque forma di ripasso per ritenzione e trasferimento. Un gioco che lo mette al centro non è "contenuto extra": è la vetta del percorso didattico |
| **È il seguito naturale della trama** | La domanda «cosa è successo alle undici?» nasce al mondo 12 e resta aperta fino al beat finale. Il secondo gioco è la risposta, non un premio arbitrario |
| **Riusa quasi tutti i dati esistenti** | Ogni item ha già `explanation`; il Codex ha già `error` e `why`; i 48 residenti hanno già una `convinzione` sbagliata autorata. Il banco delle misconcezioni **esiste già** |
| **Non svaluta il primo gioco** | Non si può giocare prima, e serve davvero ciò che hai imparato: per correggere un errore devi sapere la cosa giusta |
| **È un obiettivo visibile da subito** | La voce di menu esiste dal primo avvio, bloccata. Sapere che c'è un altro gioco dietro l'ultimo mondo è la spinta più forte disponibile |

---

## 3. Lo sblocco

### 3.1 Come si presenta

Dal **primo avvio in assoluto**, il menu principale ha una voce in più, spenta:

```
        IL SECONDO VIAGGIO
        Rotta chiusa · 0/24
```

Il contatore avanza con la campagna. A 24/24 la voce si accende con
un'animazione dedicata, e da lì è un gioco a sé con **salvataggio separato**.

Mostrare il progresso invece di un lucchetto muto è deliberato: è un
goal-gradient, non uno sberleffo. Il bambino sa sempre quanto manca.

### 3.2 Regole

- Si sblocca **solo** a campagna completata (`ProgressionManager.is_complete()`),
  e non è aggirabile: verificato da `mystery_audit`.
- **Nessuna scorciatoia acquistabile.** Nessuna energia, nessun cosmetico,
  nessun modulo può anticiparlo.
- Il salvataggio della campagna **non viene toccato**: i 24 mondi restano
  rivisitabili come oggi.
- Il Custode, il nome che gli hai dato, la livrea e il legame **vengono con te**.
  È l'unica cosa che attraversa i due giochi, ed è voluto: è tuo.

---

## 4. Il loop: la Diagnosi

Sostituisce il ciclo "domanda → risposta → feedback" con un ciclo a tre tempi.

```
 1. ASCOLTA   la sorella risolve un esercizio ad alta voce, mostrando il
              ragionamento — e sbaglia. Il ragionamento è COERENTE:
              è costruito su una regola sbagliata, non su una distrazione.

 2. INDIVIDUA scegli QUALE PASSO è sbagliato. Non la risposta: il passo.
              (analisi dell'errore — la competenza che il primo gioco
               allenava di riflesso e qui diventa il gioco)

 3. SPIEGA    scegli come dirglielo. Tre o quattro opzioni, e ognuna ha
              una conseguenza visibile sulla prova successiva.
```

### 4.1 Le opzioni di spiegazione

| Opzione | Effetto immediato | Effetto sulla prova successiva |
|---|---|---|
| **Spiegazione mirata** — tocca esattamente la sua regola sbagliata | Ci mette qualche secondo, poi capisce | Applica il concetto **anche in un contesto nuovo**. La sbiadatura si ritira |
| **Spiegazione corretta ma fuori bersaglio** — vera, ma non parla del suo errore | Annuisce | **Rifà lo stesso errore**, identico. Nessun danno, ma nessun progresso |
| **«Dille la risposta»** | Giusto subito, sollievo immediato | Il ragionamento successivo è **più meccanico**: copia la forma. Un passo verso la sbiadatura. Reversibile |
| **«Chiedile perché»** — non sempre disponibile | Lei prova a giustificarsi e **si accorge da sola** | Effetto migliore di tutti. È l'opzione forte, ed è nascosta come tale |

Nota di design: «dille la risposta» **deve restare sempre disponibile e sempre
funzionante nell'immediato**. Se fosse bloccata o punita con una schermata di
errore sarebbe una lezione morale; lasciandola lì, con la sua conseguenza
visibile e reversibile, diventa una scoperta del giocatore. Il gioco non ti dice
che è sbagliato: te lo fa vedere.

Nessuna opzione fa perdere progressi, energia o mastery. La conseguenza è
**sulla sorella**, ed è recuperabile.

### 4.2 Da dove escono i ragionamenti sbagliati

Non si autorano da zero. Si compongono da dati esistenti:

| Ingrediente | Fonte esistente |
|---|---|
| L'esercizio | I banchi `godot/data/banks/*.json` |
| La regola sbagliata | `KnowledgeCodex` campo `error` + `why` |
| La spiegazione mirata | Campo `explanation` dell'item + `strategy` del Codex |
| Le misconcezioni caratterizzate | Campo `convinzione` dei 48 residenti ([ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md) §3) |
| Il distrattore "fuori bersaglio" | Una `explanation` di un topic vicino della stessa materia |

Serve un solo pezzo nuovo di contenuto: il **ragionamento a passi**, cioè la
catena di 3–4 passaggi con l'errore in uno di essi. È lo stesso lavoro già fatto
per la famiglia "caccia all'errore" — e vale la stessa regola guadagnata a caro
prezzo il 29 luglio: **la posizione del passo sbagliato deve ruotare**, mai
sempre il terzo.

---

## 5. Le undici sorelle

Undici capitoli, uno per sorella. Ognuna è un **luogo piccolo e autorato** — non
un mondo aperto in scala di campagna: un'area sola, intima. Il secondo gioco è
più raccolto del primo, di proposito.

| # | Come si è persa | Cosa la rende un personaggio |
|---|---|---|
| **Eli-11** | La più recente, quasi intera | È **arrabbiata con NORA**. Ha capito da sola cosa le è stato fatto. È la prima che incontri, ed è quella che ti dice in faccia che sei l'ennesimo tentativo |
| **Eli-07** | Crede di essere una maestra | Insegna cose sbagliate agli abitanti di un mondo, con totale sicurezza. Il capitolo più difficile: per aiutarla devi correggere **anche i suoi allievi** |
| **Eli-03** | Ripete le frasi di NORA | Dice le identiche battute che hai sentito per 24 mondi, a vuoto, fuori contesto. È lo specchio insopportabile di cosa sarebbe successo a te |
| **Eli-05** | Sa solo rispondere | Perfetta su tutto ciò che le è stato chiesto, muta davanti a qualunque domanda nuova. Il ritratto di chi ha studiato per il voto |
| **Eli-09** | Ha smesso di provare | Sa le cose ma non le dice più, per non sbagliare. Il capitolo sull'errore come permesso |
| **Eli-02, 04, 06, 08, 10** | Varianti su una o due materie sbiadite | Autorate sullo stesso schema, più brevi |
| **Eli-01 · «Una»** | La più antica, quasi muta | Ultima delle sorelle. Non parla per frasi: per singole parole. Il suo capitolo è ricostruire con lei una frase intera |

**Struttura di un capitolo**: 3 sessioni di Diagnosi (incontro · ricaduta ·
trasferimento), più una scena senza esercizi in cui la sorella ricorda il proprio
numero. Recuperata, sale a bordo: la nave torna ad avere un equipaggio.

### 5.1 Il dodicesimo capitolo: Meridiana

Recuperate tutte e undici, la rotta può puntare dove nessuno è mai tornato.

Meridiana **non è sbiadita**: è l'unica che il Silenzio non ha sciolto, e questo
è il primo mistero del secondo gioco. È lucida, ha ancora undici anni, e ha avuto
quattrocento anni per pensare a una cosa sola.

Il suo capitolo non è una Diagnosi: è **una conversazione**. Lei non ha bisogno
di essere corretta — ha bisogno di sapere cosa è successo fuori, e ti chiede
conto di ciò che hai deciso. Ha una sua risposta alla domanda della Cattedra
Vuota, maturata guardando il fondo, e **non è la stessa** che Eli ha dimostrato
al mondo 24.

Il gioco non stabilisce chi ha ragione. Le mette una accanto all'altra e lascia
che due ragazzine di undici anni, separate da quattro secoli, discutano di cosa
sia il sapere. È la scena per cui esiste tutto il resto.

Tirarla fuori richiede l'unica cosa che nessuno dei Primi aveva: **dodici modi di
capire in due teste che se li spiegano a vicenda.**

### 5.1 Il gate del secondo gioco

Non si diagnostica ciò che non si padroneggia. Una sorella è affrontabile solo
se hai **mastery sufficiente nelle materie in cui è sbiadita**.

Conseguenza elegante: le **rivisitazioni della campagna smettono di essere
ripasso fine a se stesso** e diventano preparazione. Torni nel mondo 6 perché ti
serve la musica per aiutare Eli-04. È lo scopo che alle rivisitazioni oggi manca.

---

## 6. NORA e il Tredicesimo, a bordo

Il secondo gioco ha due accompagnatori che **non sono d'accordo tra loro**, e
questo è il motore dei dialoghi.

- **NORA** ha dato troppo, e lo sa. La sua tentazione, ogni volta, è suggerirti
  la risposta da dare. Ogni tanto lo fa, si ferma a metà e si scusa.
- **Il Tredicesimo (Scala)**, se hai scelto di portarlo con te, ha dato niente, e
  crede ancora che sia la scelta giusta. Osserva ogni tua spiegazione con la
  diffidenza di chi si aspetta un disastro.

Entrambi hanno sbagliato in direzioni opposte. Entrambi imparano da te — che è la
chiusura tematica di tutto: l'allieva diventa maestra dei suoi maestri, senza mai
diventare arrogante, perché la cosa che ha imparato è **quanto è difficile
spiegare**.

Se hai lasciato Scala dormire nel suo apparato, il suo ruolo lo prende la voce
del Maestro pertinente alla materia. Il gioco resta completo.

---

## 7. Il finale del secondo gioco

Undici sorelle recuperate, più Meridiana. Con Eli sono tredici — e il tredicesimo
posto, quello apparecchiato da sempre, alla fine lo occupano **in tredici a
turno**. Che è la cosa più vicina a una risposta che questa storia si permette:
il sapere supremo non è una sedia per uno.

La nave non è più un relitto: è una scuola con dei maestri giovani.

Ultima scena: il circuito riaperto porta il primo passeggero. Non è un Maestro,
non è un Primo, non è una sorella. È **una ragazzina di un mondo qualunque, di
undici anni**, che ha visto una spirale su un muro e ha voluto sapere cosa
significa.

Ed è a te che lo chiede.

---

## 8. Contratti tecnici

### 8.1 Moduli

| Modulo | Responsabilità | Non fa |
|---|---|---|
| `second_journey_unlock.gd` | Stato di sblocco, contatore in menu, save separato | Non modifica il save campagna |
| `sister_catalog.gd` | Le 11 sorelle: materie sbiadite, personalità, capitoli | Non calcola mastery |
| `reasoning_builder.gd` | Compone il ragionamento a passi da item + `error`/`why` | Non inventa contenuti |
| `diagnosis_player.gd` | Il ciclo ascolta → individua → spiega, e le conseguenze | Non tocca il gate della campagna |
| `sister_state.gd` | Sbiadatura per materia, ricadute, recupero | Non concede energia |

### 8.2 Save

Slot separato, con un solo ponte in ingresso dalla campagna:

```gdscript
"secondJourney": {
    "unlockedAt": 24,
    "sisters": { "eli-11": {"stage": 2, "faded": ["italiano"]} },
    "mentor": "scala",          # o "" se l'hai lasciato dormire
    "petCarriedOver": "pet-first"
}
```

La campagna resta autoritativa e **read-only** per il secondo gioco: mastery e
Codex si leggono, non si scrivono. Nessun modo di far progredire la campagna
giocando il seguito, e viceversa.

### 8.3 Vincoli

1. Nessun contenuto del secondo gioco è raggiungibile prima del 24/24.
2. Nessuna azione del secondo gioco modifica mastery, energia o gate del primo.
3. La sorella **non è mai in pericolo** e non peggiora in modo irreversibile:
   ogni ricaduta è recuperabile nella sessione successiva.
4. Nessun timer. Nessuna sessione a tempo. La Diagnosi è ragionamento
   (`reasoning`), come già stabilito per tutte le materie non-fluency.
5. Accessibilità e budget: stessi vincoli della campagna.

### 8.4 Audit

`second_journey_audit.gd`: sblocco non aggirabile; ogni sorella ha 3 sessioni e
materie coerenti con il catalogo; ogni ragionamento a passi ha l'errore in
posizione **ruotata**; ogni opzione «fuori bersaglio» è davvero corretta ma non
pertinente; «dille la risposta» è sempre presente e sempre reversibile; nessuna
scrittura sul save campagna; determinismo a parità di seed.

---

## 9. Piano di lavoro

Non parte adesso. Parte **dopo** che la campagna abitata (A1–A7) è giocabile.

| Fase | Contenuto |
|---|---|
| **S0** | Voce di menu bloccata con contatore 0/24 — **si può fare subito**, costa poco e comincia a motivare da oggi |
| **S1** | `reasoning_builder`: un ragionamento a passi da un item reale, verificato |
| **S2** | `diagnosis_player`: il ciclo a tre tempi su **una sola sorella** (Eli-11) |
| **S3** | Conseguenze delle quattro opzioni e ricadute |
| **S4** | Le altre dieci sorelle, capitoli e luoghi |
| **S5** | NORA e Scala accompagnatori, finale |

**S0 è la raccomandazione operativa**: mettere in menu una voce bloccata con il
contatore costa mezza giornata e trasforma i 24 mondi in un percorso verso
qualcosa, molto prima che il secondo gioco esista.
