# Avanti su telefono — verifica del 7 settembre 2026

La foto mostra la terza risposta accettata e il pulsante Avanti visibile.
Questo stato, da solo, non dimostra che una chiamata differita sia andata persa.

## Risultato riprodotto

La sequenza numerica della foto (3 × ? = 18, risposta 6) completa tre nodi
sia in Godot nativo sia nell'export Web con tocchi esattamente al centro.
In una viewport browser da 390 × 684 pixel CSS, però, i 48 pixel **logici**
del pulsante Avanti diventano circa **14,6 pixel CSS**. Spostare il dito di
9 pixel tra pressione e rilascio porta il rilascio fuori dal pulsante:
la risposta rimane accettata e la prova non avanza.

La prova precedente è fallita con `Touch did not advance`; dopo la modifica,
lo stesso gesto completa tutti e tre i nodi e riconsegna il controllo al mondo.

## Modifica

`ExercisePlayer` misura il rapporto tra viewport logica e altezza CSS del canvas.
I pulsanti della barra fissa conservano almeno 48 pixel CSS di altezza e testo
di almeno 16 pixel CSS. La misura si aggiorna al ridimensionamento, anche
passando a uno schermo con densità 3 e ruotando il telefono. L'area scorrevole
continua a lasciare spazio alla barra. La logica di punteggio e chiusura resta
quella esistente.

## Verifiche

- `node scripts/run-godot-audits.mjs exercise_`: 8/8 verdi.
- `npm run test:web:exercise-touch`: verde. Tocchi browser, risposta corretta,
  movimento di 9 pixel su Avanti, tre avanzamenti, un solo esito, 73 energia,
  ritorno al mondo; viewport verticale, densità 3 e rotazione orizzontale.
- Controllo visivo degli screenshot prima e dopo la modifica.

Il test Web usa Chrome con emulazione touch, **non Safari su un iPhone reale**.
Il difetto di dimensione è riprodotto e corretto; non è ancora dimostrato che
sia l'unica causa della segnalazione dello studente. Il link completo e la
versione usata nella foto non sono stati confermati. Nessun deploy effettuato.

Le fixture Web vivono in `scripts/fixtures/` e vengono copiate nel progetto
solo durante il test; il runner ripristina la scena iniziale e le rimuove prima
di avviare il browser. Non eseguire il test in parallelo con un export normale.
