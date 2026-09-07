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
anche un gesto che nasce su Avanti e termina appena oltre il bordo completa
tutti e tre i nodi e riconsegna il controllo al mondo.

## Modifica

`ExercisePlayer` misura il rapporto tra viewport logica e altezza CSS del canvas.
I pulsanti della barra fissa conservano almeno 48 pixel CSS di altezza e testo
di almeno 16 pixel CSS. La misura si aggiorna al ridimensionamento, anche
passando a uno schermo con densità 3 e ruotando il telefono. Avanti completa
il gesto nato dentro il pulsante anche se il dito termina appena fuori; un
eventuale doppio evento touch/click non può saltare la domanda successiva.
L'area scorrevole continua a lasciare spazio alla barra.

### Minimissione «Recupera torcia»

La fixture numerica non copriva la coda specifica della minimissione:
trasformazione del POI, salvataggio e consegna della torcia. Il test Web ora
avvia la vera minimissione `riaccendere` del mondo 1, risolve i tre nodi e preme
i tre Avanti nel browser.

La chiusura dell'ultimo nodo non viene più rinviata con `call_deferred`: esito e
ritorno al mondo avvengono nello stesso giro di input. Inoltre il tween ciclico
del glifo guasto è legato al glifo stesso, così viene eliminato insieme al POI e
non produce più `Infinite loop detected` durante la trasformazione finale.

## Verifiche

- `node scripts/run-godot-audits.mjs exercise_`: 8/8 verdi.
- `npm run test:web:exercise-touch`: verde. Tocchi browser, risposta corretta,
  rilascio oltre il bordo di Avanti, tre avanzamenti, un solo esito, 73 energia,
  ritorno al mondo; poi vera minimissione della torcia, 3/3, pannello chiuso,
  riparazione registrata e torcia consegnata, senza errori runtime.
- Controllo visivo degli screenshot prima e dopo la modifica.

Il test Web usa Chrome con emulazione touch, **non Safari su un iPhone reale**.
Il difetto di dimensione è riprodotto e corretto; non è ancora dimostrato che
sia l'unica causa della segnalazione dello studente. Il link completo e la
versione usata nella foto non sono stati confermati. Nessun deploy effettuato.

Le fixture Web vivono in `scripts/fixtures/` e vengono copiate nel progetto
solo durante il test; il runner ripristina la scena iniziale e le rimuove prima
di avviare il browser. Non eseguire il test in parallelo con un export normale.
