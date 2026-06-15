# Game Design

## Concept

Eli Quest - Accademia delle Missioni e una piattaforma-gioco 2D a missione continua. La protagonista entra in una rete di laboratori segreti dove sistemi guasti, robot inattivi e terminali bloccati richiedono osservazione, ragionamento e correzione.

Il primo mondo e "Il Laboratorio Spento": un ambiente tecnico in cui energia, testo, codice, istruzioni e robotica sono parti dello stesso problema.

## Target

Il target e una bambina di 10-11 anni, curiosa e capace, nel passaggio tra quinta primaria e prima media. Il tono evita infantilizzazione, voti e compiti travestiti da gioco. La difficolta deve far sentire il problema interessante, non minaccioso.

## Ciclo Di Gioco

1. Esplora l'ambiente.
2. Leggi indizi brevi.
3. Formula un'ipotesi.
4. Interagisci con un sistema.
5. Osserva il feedback.
6. Correggi la strategia.
7. Sblocca un nuovo pezzo della missione.
8. Registra nel diario cosa hai scoperto.

## Progressione Dell'Accademia

La progressione non deve essere percepita come una scala di verifiche. Ora l'Accademia e organizzata in atti narrativi:

- **Atto I - Fondazioni:** capire sistemi spenti senza provare tutto.
- **Atto II - Sistemi Vivi:** leggere dati e conseguenze in una serra.
- **Atto III - Macchine Astratte:** progettare percorsi numerici con vincoli.
- **Atto IV - Prove e Linguaggio:** distinguere testo utile, rumore e fonti.

Il Hub mostra grado, missione attiva, obiettivo corrente, progresso e difficolta procedurale consigliata. Questo rende chiaro cosa si sta sbloccando e perche una sfida successiva richiede un ragionamento piu profondo.

## Esplorazione Del Laboratorio

Il laboratorio non deve funzionare come menu di livelli. La bambina controlla Eli in uno spazio unico e sceglie cosa osservare: messaggio instabile, banco degli attrezzi, pannello elettrico, terminale, robot, porta, nucleo NORA, finestra oscurata e tracce sul pavimento.

Ogni oggetto ha tre funzioni:

- raccontare qualcosa del mondo;
- suggerire una relazione tra sistemi;
- aprire un'azione solo quando la missione ha abbastanza contesto.

Gli hotspot non sono "pulsanti di esercizio": sono oggetti diegetici. Il pannello non porta a un quiz di elettronica, ma a un sistema guasto da stabilizzare. Il terminale non apre una scheda matematica, ma richiede un codice per tornare operativo.

## Missione 2: La Serra Biologica

La seconda missione sposta lo stesso principio dalla tecnologia ai sistemi viventi. Eli entra in una serra automatizzata dove tre piante stanno appassendo per motivi diversi: troppa acqua, poca luce, temperatura non adatta o combinazioni di questi fattori.

La bambina non riceve una lezione su biologia vegetale. Osserva foglie, sensori e dati. Ogni turno consente una sola regolazione su una pianta, poi la serra mostra conseguenze su vitalita, tabella e grafico.

Le tre piante hanno bisogni differenti:

- una felce preferisce umidita e luce morbida;
- un pomodoro vuole luce piena, acqua regolare e calore moderato;
- un cactus richiede poca acqua, luce intensa e temperatura piu alta.

Il sapere scientifico e nascosto nel confronto: la stessa scelta non funziona per tutti gli organismi.

## Missione 3: La Fabbrica Dei Numeri

La terza missione porta la matematica dentro una fabbrica industriale. La linea produce nuclei energetici, ma ogni nucleo deve attraversare macchine numeriche nel percorso corretto per raggiungere un numero-obiettivo.

Le macchine non sono esercizi scritti: sono dispositivi con effetti fisici leggibili:

- additori che iniettano energia;
- scarichi che sottraggono energia;
- duplicatori e triplicatori;
- separatori che dividono solo quando non c'e resto;
- cancelli che accettano solo pari o multipli di 3;
- bobine che trasformano il nucleo con una regola composta, come `2n + 1`.

La traccia della linea funziona come prima idea di espressione: ogni macchina avvolge il risultato precedente e rende visibile l'ordine dei passaggi. L'errore non viene punito: se una divisione non e possibile o un filtro blocca il nucleo, il blocco spiega quale proprieta matematica non e rispettata.

## Missione 4: Archivio Delle Parole

La quarta missione trasforma comprensione, grammatica, lessico, inglese operativo e scrittura breve in un'indagine d'archivio. I messaggi corrotti non sono frasi da correggere per voto: sono comandi danneggiati che aprono cassetti sbagliati, cancellano fonti o impediscono a NORA di ricostruire un evento.

La missione ha quattro passaggi diegetici:

- restauro di messaggi corrotti;
- scelta di indizi utili rispetto a dettagli veri ma irrilevanti;
- istruzione bilingue da eseguire senza distruggere una fonte;
- rapporto finale breve per chiudere il caso.

Il pensiero critico entra quando la bambina distingue informazione vera da informazione utile. La scrittura breve entra come consegna narrativa: NORA ha bisogno di un rapporto operativo, non di un tema.

## Missione Continua

La missione non e una serie di livelli scollegati. Il laboratorio resta lo spazio centrale e ogni puzzle modifica lo stato del mondo: il circuito accende il terminale, il codice abilita l'istruzione, l'istruzione sblocca il robot, il robot recupera la chiave.

La stanza ora usa una mappa del problema visibile nel pavimento: testo, energia, terminale, robot, porta. Questa traccia non spiega la soluzione, ma premia chi osserva e collega indizi.

## Missione Procedurale: Laboratorio Sempre Diverso

La generazione procedurale introduce rigiocabilità senza trasformare il gioco in una lista di quiz. Ogni run crea una stanza nuova da seed, con:

- un messaggio italiano corrotto;
- un circuito con guasti diagnosticabili;
- un terminale numerico narrativo;
- un'istruzione operativa inglese;
- un robot su griglia risolvibile;
- una porta finale che verifica la coerenza complessiva.

Il seed rende la missione riproducibile. La validazione impedisce contenuti non risolvibili o ambigui. I fallback garantiscono che il gioco non si blocchi se un generatore fallisce.

La missione procedurale e ora una stanza sistemica: testo, circuito, terminale, inglese, robot e porta non sono prove separate. Ogni sistema produce un effetto sul successivo, quindi la sfida diventa capire la catena causa-effetto prima di agire.

La difficoltà cresce aumentando vincoli e complessità, non solo numeri: meno indizi, griglie più grandi, più ostacoli, circuiti con più guasti e calcoli con più passaggi.

La missione procedurale ora usa difficolta 1-8 e archetipi diversi:

- calcolo diretto;
- ragionamento inverso;
- sequenze;
- vincoli di divisibilita;
- diagnosi di errore;
- circuiti con percorso aperto, polarita, corrente instabile o guasti combinati.

La regola di design e: una nuova difficolta deve cambiare il tipo di pensiero richiesto, non solo aumentare i numeri.

## Due Percorsi Complementari

Eli Quest separa due bisogni diversi senza cambiare identita al prodotto:

- **Missione narrativa:** e il gioco principale. Ha tempo, tre vite e continuita di storia. L'errore consuma una vita per dare tensione, ma il feedback spiega il motivo e la run riparte con lo stesso seed.
- **Allenamento focus:** e una sala specialistica per matematica, italiano, inglese, coding o elettronica. Non ha vite: registra tempo, precisione, indizi e voto formativo. Serve per specializzarsi senza interrompere la storia.

Entrambi i percorsi usano lo stesso principio: sfide procedurali validate, distrattori plausibili, almeno due passaggi cognitivi e indizi coerenti. Il prodotto deve restare semplice da usare ma profondo da padroneggiare.

Ogni console mostra un micro-metodo: cosa osservare, come decidere, come verificare. Questo rende visibile la strategia senza trasformare l'esercizio in una spiegazione scolastica lunga.

## Tono

Avventuroso, misterioso, intelligente, ironico con misura e rassicurante. L'assistente NORA non giudica: interpreta errori come segnali utili.

## Didattica Nascosta

La didattica emerge dal comportamento dei sistemi:

- Il LED spento suggerisce circuito aperto.
- Il codice numerico apre un terminale, non una scheda di matematica.
- La grammatica ripara un messaggio tecnico corrotto.
- L'inglese e un comando operativo.
- Il coding guida un robot con una sequenza visibile.
- La missione procedurale allena trasferimento: il contesto cambia, ma il metodo resta osservare, ipotizzare, provare e correggere.

## Indizi Progressivi

Gli indizi sono collegati agli oggetti, non a una schermata di aiuto generica. Il primo indizio invita a osservare, il secondo restringe il problema, il terzo chiarisce il principio senza consegnare direttamente la soluzione.

Esempio: il banco degli attrezzi suggerisce la forma ad anello del circuito; il pannello parla del percorso della corrente; il puzzle mostra il LED acceso o spento. La spiegazione nasce dalla sequenza osservazione-azione-feedback.

Nella serra, la stessa logica passa da oggetti tecnici a organismi: colore delle foglie, nota scientifica breve in inglese, tabella dei sensori e grafico della vitalita costruiscono un percorso di ragionamento senza trasformarsi in verifica.

Nella fabbrica, gli indizi sono industriali: una macchina bloccata, una traccia di trasformazione, un target energetico, un filtro che rifiuta un numero. Il calcolo mentale resta nascosto dentro la scelta del percorso.

Nell'archivio, gli indizi sono linguistici: accordi grammaticali, parole precise, negazioni inglesi e dettagli da scartare. La lingua resta uno strumento per far funzionare un sistema.

## Principi

- Nessun timer nella prima missione.
- Feedback descrittivo invece di "giusto/sbagliato".
- Scoperta prima della spiegazione.
- Indizi progressivi.
- Progressione narrativa e competenze separate dai voti.
- Ogni sistema deve avere almeno un indizio ambientale prima dell'interazione risolutiva.
- L'audio segnala esplorazione, scansione, errore lieve, successo e apertura senza diventare punitivo.

## Direzione Visiva Di Produzione

La qualità visiva deve sostenere la missione, non coprire la didattica. La direzione scelta è **accademia segreta pittorica, tecnica ma calda**:

- fondali dipinti con profondità e zone leggibili per gli hotspot;
- parallax leggero su piani lontani, architettura centrale e silhouette in primo piano;
- interfacce olografiche rifinite, non semplici rettangoli;
- particelle, flare e scanline usati come segnali di sistema;
- transizioni cinematiche brevi quando si entra in una scena o si completa un sistema;
- simboli corretti nei puzzle tecnici, soprattutto elettronica e robotica.

Gli esercizi devono cambiare aspetto in base all'interazione:

- successo: luce stabile, particelle ordinate, suono morbido;
- errore: vibrazione, luce rossa breve, feedback esplicativo;
- quasi corretto: colore caldo e indizio diagnostico;
- inattività o sistema non letto: interfaccia spenta o parzialmente oscurata.

La resa “premium” non significa aggiungere decorazione ovunque. Significa rendere chiara la funzione degli oggetti, far percepire causa-effetto e dare alla bambina la sensazione di manipolare sistemi reali.
