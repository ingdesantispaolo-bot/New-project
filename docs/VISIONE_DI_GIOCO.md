# Eli Quest — Il Risveglio di NORA · Documento Bussola

> Questo è il **nord** del progetto. Ogni decisione di design, contenuto o codice
> dovrebbe poter rispondere alla domanda: *"avvicina o allontana dalla visione
> qui descritta?"*. In caso di dubbio, questo documento vince.
>
> Documenti collegati: [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md) ·
> [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md) ·
> [ABITANTI_E_LUOGHI.md](ABITANTI_E_LUOGHI.md) · [PET_CUSTODE.md](PET_CUSTODE.md) ·
> [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md) ·
> [ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md)

## Pitch in una frase

Il **Relitto dei Primi** era una nave-scuola; il **Silenzio** ha sciolto il
legame tra le cose e il loro significato, e i suoi Maestri si sono chiusi dentro
dodici apparati — uno per disciplina — per salvarlo. Eli risveglia **NORA**, la
loro prima allieva, riparandoli: e l'unico modo per riaccendere un apparato è che
qualcuno **capisca davvero** ciò che custodiva. **La comprensione non si copia,
si rifà**: per questo studiare è il potere che riapre la rotta.

## La fantasia (cosa prova lo studente)

Non "sto facendo esercizi": **sto esplorando un mondo, conquistando luoghi e
riportando in vita una nave viva**, con NORA che mi parla e cresce con me, un
compagno accanto, e ogni problema risolto che diventa energia con cui divento
più forte e apro nuove regioni.

Il verbo centrale non è *rispondere*, è **esplorare-conquistare-crescere**.

## Il loop in una riga

**Fuori** (mondo esterno) si svolgono **tutte le missioni**, tarate sul **livello
attuale**; **dentro** (la nave) si riparano gli **apparati** superando un
**esercizio finale** per ogni livello. Progressione lunga: **almeno 20 livelli**.
Riparare un apparato richiede padronanza della materia **e** un certo numero di
missioni di quella materia svolte all'esterno. Ogni livello completato riattiva
una parte della nave e sblocca un **nuovo mondo esterno**, con identità grafica,
tema, topologia, atmosfera e grammatica di missione proprie. Dettaglio in
[DESIGN_COMPLETO.md](DESIGN_COMPLETO.md).

## I 5 pilastri

1. **Fuori si allena, dentro si consacra.** Tutte le missioni sono nel mondo
   esterno (la palestra); la nave è il traguardo dove si riparano gli apparati
   (gli esami finali) e si vede la progressione prendere vita.
2. **Ogni sforzo ha un senso narrativo.** Riparare un apparato risveglia un pezzo
   di NORA e sblocca la storia; la nave si accende stanza dopo stanza. La
   progressione racconta.
3. **Difficoltà giusta, errore con posta in gioco.** Le missioni si tarano sul
   livello del giocatore e sulla materia più debole; sbagliare insegna sempre
   (spiegazione) ma ha una **conseguenza morbida** (perdi la combo / uno scudo,
   puoi fallire e ripetere la missione) — mai una penalità distruttiva.
4. **L'energia è potere reale.** Guadagnata solo svolgendo missioni, spesa per
   potenziare Eli (moduli, compagni) e per esprimersi (estetica).
5. **Un solo universo, molti mondi, un solo motore.** Ogni livello apre un
   mondo esterno diverso, ma l'esperienza resta continua e senza cuciture:
   **full Godot** (vedi decisione sotto).

## Decisioni vincolanti 2026-07-23

1. **Un mondo per livello.** I 24 livelli della campagna sbloccano 24 mondi
   esterni distinti e rivisitabili. Un mondo non può essere soltanto una palette
   diversa: deve cambiare almeno composizione, materiali/vegetazione o
   architettura, luce/meteo, landmark principale, soundscape e tipo di missioni.
2. **Minigiochi dentro le missioni.** Le attività oggi chiamate "Palestre"
   diventano eventi casuali trovati durante l'esplorazione o tappe di una
   missione. Non restano un menu o una stazione fissa da farmare.
3. **Ingresso nave deterministico.** Ogni mondo possiede un ingresso al Relitto
   in una posizione autorata, sicura, sempre raggiungibile e mai affidata alla
   generazione procedurale. È il riferimento visivo e navigazionale del livello.
4. **Manuale NORA.** I concetti importanti hanno spiegazioni brevi, esempi,
   errori tipici e dimostrazioni consultabili. NORA li introduce nel contesto e
   li archivia in un manuale accessibile dalla nave e dal mondo.
5. **Interazioni oltre la scelta multipla.** La scelta multipla resta utile per
   diagnosi e controlli rapidi, ma non è il formato dominante. Manipolazione,
   costruzione, ordinamento, abbinamento, mappe, grafici, circuiti, codice e
   simulazioni devono trasformare la conoscenza in azione.

## North-star metric

**Esercizi risolti con impegno per studente a settimana**, con guardrail di
qualità: *sessioni breve e frequenti* (ritorno quotidiano) e *padronanza reale*
(mastery che sale), non grinding. Se una feature aumenta i numeri ma peggiora
apprendimento o benessere, non entra.

## Decisione architetturale: FULL GODOT

Obiettivo confermato: **un unico motore Godot**, niente Phaser, niente bridge,
niente ricariche di pagina. Oggi Phaser è il cervello (esercizi, generatori,
save, storia) e Godot il corpo (mondo). Si arriva al full-Godot **per
migrazione incrementale e sempre spedibile**, non con un rewrite big-bang.
Piano e architettura in [ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md).

## Ambientazione in breve

- **Il Relitto dei Primi**: nave-**scuola** antica che percorreva un circuito di
  mondi portando e raccogliendo modi di capire. Ogni mondo è **abitato** dai
  discendenti dei suoi allievi, che ripetono ancora i gesti dell'insegnamento
  senza saperne più il senso. Stile grafico *Animal Crossing* (caldo, luminoso,
  leggibile, costruito attorno a punti focali). **Dentro** = la nave con gli
  **apparati** da riparare (gli esami finali); **fuori** = i **mondi-livello**
  dove si svolgono tutte le missioni e vivono le persone.
- **NORA**: non la mente della nave, ma la sua **prima allieva**. Il Silenzio le
  ha lasciato i metodi e le ha tolto i contenuti: impara *con* Eli, non prima di
  lei, e per questo non può mai dare la risposta. Recupera un Maestro — e una
  sfumatura di voce — a ogni apparato riparato.
- **Eli**: l'allieva-robot giocante. Cresce di livello (1 → 24), si potenzia, si
  personalizza — e **non è la prima**: undici l'hanno preceduta.
- **Il Custode**: il compagno sempre accanto a Eli, con un volto sempre in vista
  che reagisce a ciò che accade, che si accarezza e che ogni tanto fa una figura
  barbina mentre NORA prende appunti. È anche l'unico che sente dove il
  significato è svanito.
- **Gli abitanti**: 48 residenti + 24 comici di passaggio + 6 compagni
  ricorrenti, su **otto registri di tono** — curiosi, misteriosi, buffi,
  divertenti, calorosi, burberi, solenni, sognanti. Ogni mondo ne mescola almeno
  due e ha sempre qualcuno che fa ridere.
- **I Primi**: la civiltà scomparsa. Non morta: **chiusa per scelta**. E il loro
  viaggio non era un giro di lezioni: era una **ricerca**. I posti
  dell'equipaggio erano tredici, i nomi incisi sono undici, uno è stato raschiato
  via e **uno non è mai stato inciso** — la cattedra era apparecchiata per ciò
  che stavano cercando.
- **La Cattedra Vuota**: lo scopo filosofico del gioco. Esiste un sapere sotto
  tutti gli altri? Tre personaggi rispondono in tre modi opposti; la quarta
  risposta la produce il giocatore risolvendo il nodo di sintesi che nessuno gli
  ha spiegato — e la nave gli assegna il tredicesimo posto.
- **Il Tredicesimo**: propose la chiusura, si escluse, e da quattrocento anni
  tiene fuori il Silenzio da solo. Non è un mostro: è esausto, e ha ragioni.
- **Il Silenzio**: scioglie il legame tra una cosa e il suo significato. Si
  dirada dove qualcuno capisce. Da dove venga resta un'ipotesi.
- **Sette colpi di scena** (mondi 5, 8, 12, 16, 19–20, 23, 24). L'ultimo
  riscrive all'indietro **la meccanica del gioco**: dettaglio in
  [TRAMA_E_MISTERO.md](TRAMA_E_MISTERO.md) §3.
- **Il Secondo Viaggio**: finire la campagna sblocca un gioco nuovo in cui il
  loop si inverte — non impari, **insegni**. Voce di menu visibile e bloccata
  dal primo avvio, con il contatore dei mondi.
  Specifica in [SECONDO_VIAGGIO.md](SECONDO_VIAGGIO.md).
- **Apparati = materie**: ogni apparato (stanza) è legato a una materia —
  matematica/logica = Nucleo, coding = Cratere Logico, lingue = Data-core, latino
  = Sala dei Glifi, fisica/geografia = Ponte di Comando, musica = Motore a
  Risonanza, elettronica = Reattore. (Costruito sull'esistente.)

## Cosa NON è questo gioco

- Non è un quiz con una skin. Il mondo, la storia e la crescita sono il gioco;
  gli esercizi sono l'anima, non un test somministrato.
- Non è pay-to-win né grind-to-win: l'energia si guadagna solo **imparando**, e
  i potenziamenti aiutano ad apprendere meglio, non a saltare l'apprendimento.
- **L'errore ha una conseguenza, ma non è distruttivo.** Ogni errore è sempre
  istruttivo (spiegazione) e comporta una **penalità morbida**: azzera la combo
  e toglie uno "scudo" nella prova; se gli scudi finiscono la missione va
  ripetuta. Mai una penalità che cancella livello o energia già guadagnati.

## Pubblico e vincoli

- **Studenti di 10–13 anni**: fine della scuola primaria e secondaria di primo
  grado. Fascia di lancio decisa il 29 luglio 2026 ed è l'arco che i contenuti
  coprono davvero — tabelline e lessico di base nei primi mondi, equazioni,
  Pitagora, declinazioni latine e false friends nei mondi alti. La rampa di
  difficoltà è tarata su questo: mondi 1–12 come introduzione (difficoltà 1→3),
  mondi 13–24 come approfondimento (3→4). Nel save la fascia è
  `config.schoolBand = "primaria-secondaria-1"` (`LearningConfig.BAND_LAUNCH`).
- **Web-first**, distribuito su GitHub Pages; deve girare su hardware modesto e
  su schermi/aspect ratio diversi (mobile incluso).
- **Materie multiple** già presenti; l'architettura deve renderne facile
  l'aggiunta.
