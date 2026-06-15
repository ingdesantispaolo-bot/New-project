# Roadmap

## Missione 2: La Serra Biologica

Implementata come seconda missione giocabile. Focus su biologia di base, crescita delle piante, acqua, luce, temperatura, raccolta dati, lettura di grafici semplici, inglese scientifico base e problem solving. Sistemi: tre piante con bisogni diversi, sensori, tabella dati, grafico vitalita e turni di regolazione.

## Missione 3: La Fabbrica Dei Numeri

Implementata come terza missione giocabile. Focus su calcolo mentale, proprieta delle operazioni, multipli e divisori, sequenze, problemi a piu passaggi, prime idee di espressione e controllo dell'errore. Sistemi: nastri trasportatori, macchine additrici/sottrattrici/moltiplicatrici/divisorie, filtri pari/multipli di 3 e bobine di trasformazione.

## Missione 4: Archivio Delle Parole

Implementata come quarta missione giocabile. Focus su comprensione del testo, grammatica italiana, correzione di frasi, lessico, istruzioni in inglese, scrittura breve e pensiero critico. Sistemi: messaggi corrotti, filtro indizi, istruzione bilingue e rapporto finale.

## Missione 5: Atlante Perduto

Focus su geografia, mappe, coordinate, scale, orientamento e inglese operativo. Sistemi: tavolo olografico, bussole, coordinate, messaggi radio.

## Missione 6: Citta Intelligente

Focus su elettronica, dati, energia, logica condizionale e cittadinanza tecnologica. Sistemi: semafori, sensori, rete elettrica, priorita e conseguenze.

## Generazione Procedurale Controllata

Prima versione implementata con **Laboratorio Sempre Diverso**. Focus su rigiocabilità, seed deterministico, generatori modulari, validator, solver e fallback sicuri.

Componenti implementati:

- seed deterministico e salvabile;
- difficoltà 1-8 con progressione pedagogica;
- generatori matematica, robot, circuito, lingua italiana e inglese;
- validator e solver per garantire risolvibilità;
- `ChallengeQualityValidator` per scartare sfide troppo brevi, tentabili o con distrattori deboli;
- grafo di dipendenze tra testo, circuito, terminale, inglese, robot e porta;
- simulatori iniziali per Serra, Fabbrica e Archivio;
- AudioManager collegato a WAV locali generati da pipeline asset;
- archetipi matematici diversi: diretto, inverso, sequenza, vincolo, diagnosi errore;
- scenari circuito diversi: percorso aperto, corrente instabile, polarita, guasti combinati;
- `ProgressionSystem` per rendere chiari atti, grado, obiettivo corrente e difficolta consigliata;
- scena esplorativa procedurale con hotspot;
- diario con seed, puzzle risolti, indizi e competenze.

## Prossimi Step Tecnici

1. Sostituire l'atlas generato con export Aseprite/TexturePacker reale mantenendo i frame name stabili.
2. Rifinire le mappe LDtk/Tiled complete con layer artistici: parete, pavimento, oggetti, luci, collisioni, hotspot e foreground.
3. Sostituire l'avatar geometrico con sprite animato di Eli: idle, camminata, osservazione, interazione con terminale.
4. Portare anche i micro-flussi del terminale e del messaggio in dati configurabili, mantenendo scene Phaser dedicate solo quando serve visualizzazione complessa.
5. Aggiungere una modalità "ritmo lento" con diario consultabile come overlay, non solo come scena separata.

## Step Completati In Questa Iterazione

- Upgrade a Phaser 4.1.
- Code-splitting Vite per separare `phaser` e `howler` dal codice gioco.
- Lazy loading delle scene missione e dei puzzle tramite `SceneNavigator`.
- Pipeline asset iniziale con `assets:build`, WebP/AVIF e atlas TexturePacker-compatible.
- Mappe Tiled JSON generate e validate per schermata principale/Hub, Laboratorio, Serra, Fabbrica e Archivio.
- Tileset Tiled iniziale generato in `src/assets/tiles/eli-production-tileset.png`.
- Layer artistici generati nelle mappe: `floor`, `set_dressing`, `foreground_light`.
- Layout runtime compatti separati dalle mappe artistiche per proteggere il bundle.
- `MapLayoutSystem` collegato a hotspot, piante, macchine, pannelli e carte principali.
- `VisualKit` potenziato con parallax multilivello, grading leggero, flare/particelle da atlas, pannelli più rifiniti e transizioni cinematiche.
- Persistenza dello stato interno di Serra Biologica e Fabbrica dei Numeri.
- Hotspot del laboratorio estratti in dati in `src/data/laboratoryObjects.ts`.
- Laboratorio trasformato in spazio esplorativo con avatar, ispezione oggetti e azioni contestuali.
- Indizi progressivi legati agli oggetti ambientali.
- Audio esplorativo aggiunto: scansione, indizio, pannello e passo.
- Didattica mantenuta dentro sistemi della stanza invece che in schermate isolate.
- Missione 2 aggiunta con `GreenhouseScene`, dati in `src/data/greenhouse.ts`, progressione MissionEngine e diario finale.
- Missione 3 aggiunta con `NumberFactoryScene`, dati in `src/data/numberFactory.ts`, macchine numeriche, filtri e completamento MissionEngine.
- Missione 4 aggiunta con `WordArchiveScene`, dati in `src/data/wordArchive.ts`, restauro messaggi, filtro indizi, istruzione bilingue e rapporto finale.

## Prossimi 5 Step Di Sviluppo

1. Fare playtest pedagogico: misurare quando la bambina capisce il sistema e quando prova a caso.
2. Collegare i simulatori di Serra, Fabbrica e Archivio alle scene per generare casi nuovi con validazione automatica.
3. Aggiungere una schermata "percorso" nel Diario con atti, competenze, errori corretti e concetti scoperti.
4. Bilanciare difficolta 1-8 su soglie reali: tempi, tentativi, indizi usati, errori frequenti.
5. Aggiungere test automatici per 100 seed per difficolta e report sugli archetipi generati.

## Prossimi Step Procedurali

1. Aggiungere selettore UI per scegliere seed, difficoltà e focus competenze prima della generazione.
2. Salvare solo seed+difficoltà e rigenerare la missione quando il formato sarà stabile.
3. Estendere i generatori procedurali a Serra Biologica con simulatori turn-based validati.
4. Aggiungere playtest automatici per 100 seed per difficoltà.
5. Creare una schermata docente/genitore per copiare seed e leggere competenze allenate.
