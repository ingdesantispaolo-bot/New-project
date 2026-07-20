# Eli Quest — Il Risveglio di NORA · Documento Bussola

> Questo è il **nord** del progetto. Ogni decisione di design, contenuto o codice
> dovrebbe poter rispondere alla domanda: *"avvicina o allontana dalla visione
> qui descritta?"*. In caso di dubbio, questo documento vince.
>
> Documenti collegati: [DESIGN_COMPLETO.md](DESIGN_COMPLETO.md) ·
> [ARCHITETTURA_FULL_GODOT.md](ARCHITETTURA_FULL_GODOT.md)

## Pitch in una frase

Eli, giovane esploratrice-robot, risveglia **NORA** — la mente dormiente del
**Relitto dei Primi** — riparandone i sistemi; e ogni sistema è una disciplina.
**Studiare è il potere che riaccende la nave** e svela perché i Primi sono
scomparsi… e cosa sta tornando.

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
missioni di quella materia svolte all'esterno. Dettaglio in
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
5. **Un solo mondo, un solo motore.** Esperienza continua e senza cuciture:
   **full Godot** (vedi decisione sotto).

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

- **Il Relitto dei Primi**: nave-mondo antica incagliata su un pianeta di biomi,
  stile grafico *Animal Crossing* (caldo, luminoso, ricco, leggibile, costruito
  attorno a punti focali). **Dentro** = la nave con gli **apparati** da riparare
  (gli esami finali); **fuori** = il **pianeta procedurale** dove si svolgono
  **tutte le missioni**.
- **NORA**: la mente della nave, frammentata all'inizio, guida e narratrice che
  torna cosciente man mano che Eli ripara gli apparati.
- **Eli**: l'esploratrice-robot giocante; cresce di livello (1 → 20+), si
  potenzia, si personalizza.
- **I Primi**: la civiltà scomparsa; il mistero centrale della storia.
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

- **Studenti** (scuola primaria/secondaria di primo grado come fascia centrale).
- **Web-first**, distribuito su GitHub Pages; deve girare su hardware modesto e
  su schermi/aspect ratio diversi (mobile incluso).
- **Materie multiple** già presenti; l'architettura deve renderne facile
  l'aggiunta.
