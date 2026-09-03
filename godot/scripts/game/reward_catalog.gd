class_name RewardCatalog
extends RefCounted

## Catalogo cosmetici (C-14). Trascritto letteralmente da src/core/RewardCatalog.ts
## (stessi id/slot/nome/descrizione/costo/colore/glifo/minLevel — non inventato):
## qui `minLevel` è confrontato col LIVELLO Godot (apparati riparati 1→24), la
## spina dorsale unica del gioco, non l'euristica multi-sistema del prototipo
## Phaser (playerLevel() combinava run di training, missioni, gym, ecc.).
## Slot: bot, avatar, accessory, tool, pet, emblem, upgrade, decor.
## upgrade/decor non occupano uno slot equipaggiato: sono "posseduti" e basta
## (finiscono in cosmetics.inventory, non in cosmetics.equipped).

const CATALOG := [
	# --- Bit, il compagno ---------------------------------------------------
	{"id": "bot-lime", "mondo": 1, "slot": "bot", "name": "Bit Lime", "description": "Verde acido brillante per il tuo compagno.", "origine": "Vernice avanzata dai segnavia della radura: Tobia ne aveva un barattolo di troppo.", "cost": 120, "color": 0x7cf6a6},
	{"id": "bot-gold", "mondo": 1, "slot": "bot", "name": "Bit Oro", "description": "Un Bit dorato da campione.", "origine": "Foglia d’oro dalla bottega di Nonna Ersilia, tenuta per i giorni buoni.", "cost": 260, "color": 0xf6c85f},
	{"id": "bot-violet", "mondo": 7, "slot": "bot", "name": "Bit Viola", "description": "Look notturno viola-neon.", "origine": "Pigmento delle Rovine dei Glifi, l’unico colore che il tempo non ha sbiadito.", "cost": 260, "color": 0x9f8cff},
	{"id": "bot-rose", "mondo": 4, "slot": "bot", "name": "Bit Rosa", "description": "Rosa acceso, impossibile non notarlo.", "origine": "Colore del molo all’alba, quando le insegne si riempiono da sole.", "cost": 480, "color": 0xff7b9c},
	{"id": "bot-arctic", "mondo": 22, "slot": "bot", "name": "Bit Artico", "description": "Bianco-ciano, pulito e tecnico.", "origine": "Ghiaccio della Biosfera Profonda, che a toccarlo non è freddo.", "cost": 620, "color": 0xbffcff},
	{"id": "bot-solar", "mondo": 13, "slot": "bot", "name": "Bit Solare", "description": "Bagliore caldo per le serie perfette.", "origine": "Filamento del Deserto delle Orbite: brilla se lo guardi da fermo.", "cost": 860, "color": 0xffb85c},
	# --- Avatar della stanza ------------------------------------------------
	{"id": "avatar-gold", "slot": "avatar", "name": "Outfit Oro", "description": "Tuta oro per l'esploratore.", "origine": "Tuta da parata dei Dodici, mai usata: non c’è stata nessuna parata.", "cost": 220, "color": 0xf6c85f},
	{"id": "avatar-violet", "mondo": 2, "slot": "avatar", "name": "Outfit Viola", "description": "Tuta viola per l'esploratore.", "origine": "Tenuta notturna dell’Archivio delle Parole.", "cost": 220, "color": 0x9f8cff},
	{"id": "avatar-emerald", "mondo": 10, "slot": "avatar", "name": "Outfit Smeraldo", "description": "Verde smeraldo brillante.", "origine": "Verde della Serra delle Simbiosi, dove tutto cresce insieme a qualcos’altro.", "cost": 380, "color": 0x2ed889},
	{"id": "avatar-crimson", "mondo": 5, "slot": "avatar", "name": "Outfit Cremisi", "description": "Rosso deciso da veterano.", "origine": "Rosso delle Officine del Moto. Si sporca e non si vede: apposta.", "cost": 560, "color": 0xc94b55},
	{"id": "avatar-nebula", "mondo": 4, "slot": "avatar", "name": "Outfit Nebula", "description": "Blu profondo con riflessi viola.", "origine": "Tessuto ricavato dalle vele lunghe, quelle che leggono i segnali.", "cost": 760, "color": 0x5f7cff},
	{"id": "avatar-aurora", "slot": "avatar", "name": "Outfit Aurora", "description": "Toni verdi e ciano per esplorazioni lunghe.", "origine": "Per le esplorazioni lunghe. Le sorelle ne avevano una ciascuna.", "cost": 920, "color": 0x74f0c5},
	{"id": "avatar-pilot", "slot": "avatar", "name": "Tuta Pilota", "description": "Giacca chiara con spalliere aerodinamiche.", "origine": "Giacca di chi porta la nave. Sul colletto c’è ancora un nome, scucito.", "cost": 1150, "color": 0x9ff5e9, "minLevel": 4},
	{"id": "avatar-engineer", "mondo": 3, "slot": "avatar", "name": "Tuta Ingegnere", "description": "Cintura strumenti e pannelli tecnici arancio.", "origine": "Cintura di Ruggine, che ha smesso di credere che chiedere aiuto sia pigrizia.", "cost": 1450, "color": 0xffb85c, "minLevel": 5},
	{"id": "avatar-captain", "slot": "avatar", "name": "Mantello Capitano", "description": "Sash luminoso e mantello corto da leader.", "origine": "Mantello del posto che comanda. Il tredicesimo non l’ha mai indossato.", "cost": 2100, "color": 0x7ad7ff, "minLevel": 6},
	{"id": "avatar-shadow", "mondo": 16, "slot": "avatar", "name": "Tenuta Eclisse", "description": "Profilo scuro con linee neon da missioni difficili.", "origine": "Profilo scuro per il volume senza porta. Serviva a non farsi notare da sé stessi.", "cost": 3200, "color": 0x9f8cff, "minLevel": 8},
	{"id": "avatar-astral", "slot": "avatar", "name": "Veste Astrale", "description": "Abito leggendario con alone e stelle sul petto.", "origine": "Veste della cattedra vuota. Era apparecchiata anche lei, e ha aspettato.", "cost": 4400, "color": 0xffd75e, "minLevel": 9},
	# --- Accessori equipaggiabili --------------------------------------------
	{"id": "accessory-visor", "mondo": 15, "slot": "accessory", "name": "Visore tattico", "description": "Una lente luminosa sopra il casco dell'avatar.", "origine": "Lente da diagnosi, dalla Città Macchina.", "cost": 180, "glyph": "•", "color": 0x9ff5e9},
	{"id": "accessory-scarf", "mondo": 1, "requiresHazardWorld": 1, "slot": "accessory", "name": "Sciarpa fotonica", "description": "Un nastro caldo che segue il movimento e conserva il ritmo regolare delle pietre stabilizzate.", "origine": "Ersilia l'ha tessuta con i fili rimasti fra le pietre del Cerchio delle quantità. La consegna soltanto a chi le ha fatte tornare a contare insieme.", "cost": 100, "glyph": "=", "color": 0xf6c85f},
	{"id": "accessory-compass", "slot": "accessory", "name": "Bussola stellare", "description": "Piccolo segno da navigatore del Relitto.", "origine": "Bussola di Nima, che disegna mappe di posti da inventare.", "cost": 420, "glyph": "*", "color": 0x9f8cff},
	{"id": "accessory-pack", "slot": "accessory", "name": "Zaino dati", "description": "Modulo compatto per missioni lunghe.", "origine": "Zaino da missione lunga, con dentro ancora gli appunti di qualcuno.", "cost": 540, "glyph": "◊", "color": 0x7ad7ff},
	{"id": "accessory-crown", "slot": "accessory", "name": "Corona del metodo", "description": "Accessoria rara per chi ama spiegare ogni passo.", "origine": "Non incorona nessuno: segnala chi spiega ogni passaggio anche quando non serve.", "cost": 980, "glyph": "◊", "color": 0xffd75e},
	{"id": "accessory-antenna", "mondo": 4, "slot": "accessory", "name": "Antenne scanner", "description": "Due antenne sottili sopra il casco.", "origine": "Antenne dalla Baia dei Segnali. Rispondono anche ai messaggi non tuoi.", "cost": 720, "glyph": "~", "color": 0x9ff5e9, "minLevel": 4},
	{"id": "accessory-wings", "mondo": 9, "slot": "accessory", "name": "Ali stabilizzatrici", "description": "Pannelli laterali traslucidi per il movimento.", "origine": "Pannelli dell’Arcipelago, per stare in equilibrio sulle chiuse.", "cost": 1300, "glyph": "◊", "color": 0x74f0c5, "minLevel": 6},
	{"id": "accessory-jetpack", "mondo": 3, "slot": "accessory", "name": "Jetpack didattico", "description": "Doppio modulo dorsale con scie luminose.", "origine": "Prototipo del Cratere Logico. Funziona; nessuno sa ancora perché.", "cost": 1700, "glyph": "^", "color": 0xffb85c, "minLevel": 7},
	{"id": "accessory-halo", "mondo": 24, "slot": "accessory", "name": "Aureola prismatica", "description": "Anello raro sospeso sopra l'avatar.", "origine": "Anello prismatico del Cuore. Si accende quando dodici sistemi sono in linea.", "cost": 2600, "glyph": "o", "color": 0xffd75e, "minLevel": 8},
	# --- Ricordi dei Pericoli del Mondo ---------------------------------------
	# La Sciarpa fotonica qui sopra e' il Ricordo del mondo 1 e resta indossabile.
	# Gli altri ventitre sono oggetti da collezione permanenti: la bottega li
	# riunisce nella sezione RICORDI, ma non promettono un effetto che il mondo non
	# rende. Il costo coincide col premio del Pericolo del relativo tier: vincere
	# rende possibile scegliere subito il ricordo, senza consegnarlo d'ufficio.
	{"id": "memento-02-foglia-sintassi", "mondo": 2, "requiresHazardWorld": 2, "slot": "memento", "motif": "vine_book", "name": "Foglia di sintassi", "description": "Un segnalibro vivo: le nervature tengono separate le parti della frase.", "origine": "Si è staccata dalla Frase rampicante quando le parole hanno smesso di stringersi fra loro.", "cost": 100, "glyph": "V", "color": 0x9bd58b},
	{"id": "memento-03-gradino-ritorno", "mondo": 3, "requiresHazardWorld": 3, "slot": "memento", "motif": "step_stone", "name": "Gradino di ritorno", "description": "Una pietra a tre livelli che ritrova sempre la propria sequenza.", "origine": "Era sul bordo della Frana dei passi. Dopo la stabilizzazione ha smesso di cadere e si è incastrata così.", "cost": 100, "glyph": "3", "color": 0xff9f5a},
	{"id": "memento-04-boa-dei-tempi", "mondo": 4, "requiresHazardWorld": 4, "slot": "memento", "motif": "signal_buoy", "name": "Boa dei tempi", "description": "Una piccola boa con tre luci: prima, adesso e dopo.", "origine": "Galleggiava nella Nebbia dei verbi. Ora lampeggia in ordine e il faro riesce a leggerla.", "cost": 100, "glyph": "T", "color": 0x62d8ff},
	{"id": "memento-05-giunto-misura", "mondo": 5, "requiresHazardWorld": 5, "slot": "memento", "motif": "rail_caliper", "name": "Giunto di misura", "description": "Due ganasce di rotaia che conservano la distanza corretta.", "origine": "Gerbo lo ha tolto dal Binario delle misure dopo l'ultimo allineamento, e per la prima volta senza forzare: non scivola più di un millimetro.", "cost": 100, "glyph": "=", "color": 0xe8b45d},
	{"id": "memento-06-seme-risonante", "mondo": 6, "requiresHazardWorld": 6, "slot": "memento", "motif": "resonant_seed", "name": "Seme risonante", "description": "Un seme di cristallo che vibra soltanto quando il ritmo si chiude.", "origine": "È rimasto a terra dopo che l'Eco delle frasi ha pronunciato per la prima volta un periodo intero.", "cost": 120, "glyph": "~", "color": 0xe09cff},
	{"id": "memento-07-tessera-indivisa", "mondo": 7, "requiresHazardWorld": 7, "slot": "memento", "motif": "mosaic_tile", "name": "Tessera indivisa", "description": "Una losanga ricomposta: ogni parte porta ancora la propria linea.", "origine": "Proviene dal Mosaico delle frazioni. I bordi combaciano solo nella posizione trovata durante la prova.", "cost": 120, "glyph": "+", "color": 0xd9b36c},
	{"id": "memento-08-bobina-periodo", "mondo": 8, "requiresHazardWorld": 8, "slot": "memento", "motif": "circuit_coil", "name": "Bobina del periodo", "description": "Tre spire collegate come soggetto, verbo e completamento.", "origine": "Il Delta la espelleva a ogni scarica. Stabilizzato il circuito, la bobina ha tenuto il periodo senza spezzarlo.", "cost": 120, "glyph": "S", "color": 0x58e5d2},
	{"id": "memento-09-ago-cartografico", "mondo": 9, "requiresHazardWorld": 9, "slot": "memento", "motif": "map_needle", "name": "Ago cartografico", "description": "Una bussola a due assi che conserva scala e punto d'origine.", "origine": "Era l'unico ago rimasto fermo nella Rotta delle coordinate mentre la corrente cancellava i riferimenti.", "cost": 120, "glyph": "+", "color": 0x7fb8ff},
	{"id": "memento-10-ampolla-accento", "mondo": 10, "requiresHazardWorld": 10, "slot": "memento", "motif": "pollen_vial", "name": "Ampolla d'accento", "description": "Polline luminoso che si posa sempre sulla sillaba giusta.", "origine": "Raccolto nella Serra dopo che le Spore degli accenti hanno smesso di spostare il suono delle parole.", "cost": 120, "glyph": "'", "color": 0x8ee66f},
	{"id": "memento-11-sabbia-ordine", "mondo": 11, "requiresHazardWorld": 11, "slot": "memento", "motif": "order_hourglass", "name": "Sabbia d'ordine", "description": "Una clessidra in cui ogni granello aspetta il passaggio precedente.", "origine": "Gli strati della Soglia l'hanno lasciata emergere quando la Clessidra delle operazioni è tornata a scorrere in ordine.", "cost": 140, "glyph": "X", "color": 0xe7c27a},
	{"id": "memento-12-chiave-regola", "mondo": 12, "requiresHazardWorld": 12, "slot": "memento", "motif": "rule_key", "name": "Chiave della regola", "description": "Una chiave a denti mobili che conserva una sola configurazione coerente.", "origine": "Il Labirinto l'ha formata quando la Regola spezzata è diventata una frase completa e verificabile.", "cost": 140, "glyph": "K", "color": 0xa9b8ff},
	{"id": "memento-13-anello-rapporto", "mondo": 13, "requiresHazardWorld": 13, "slot": "memento", "motif": "orbit_ring", "name": "Anello di rapporto", "description": "Due orbite solidali: allargando una, l'altra mantiene la proporzione.", "origine": "Recuperato dalla duna centrale dopo che l'Orbita delle proporzioni ha smesso di deviare le traiettorie.", "cost": 140, "glyph": "o", "color": 0xffc65c},
	{"id": "memento-14-conchiglia-legami", "mondo": 14, "requiresHazardWorld": 14, "slot": "memento", "motif": "chorus_shell", "name": "Conchiglia dei legami", "description": "Una conchiglia d'archivio: avvicinandola si sentono voci diverse senza che si coprano.", "origine": "È comparsa nella Biblioteca quando il Coro dei connettivi ha ricominciato a collegare le voci invece di confonderle.", "cost": 140, "glyph": "C", "color": 0xf0a6d8},
	{"id": "memento-15-nodo-quieto", "mondo": 15, "requiresHazardWorld": 15, "slot": "memento", "motif": "network_node", "name": "Nodo quieto", "description": "Un nucleo a quattro porte che non riaccende più gli errori già risolti.", "origine": "La Città Macchina lo ha espulso dalla Rete dei calcoli alla prima esecuzione completata senza riavvii.", "cost": 140, "glyph": "+", "color": 0x63e6ff},
	{"id": "memento-16-placca-varco", "mondo": 16, "requiresHazardWorld": 16, "slot": "memento", "motif": "verb_gate", "name": "Placca del varco", "description": "Una targhetta girevole le cui tre finestre ora mostrano lo stesso tempo.", "origine": "Era fissata sopra il Varco dei verbi. I mercanti l'hanno smontata quando le insegne hanno smesso di cambiare da sole.", "cost": 160, "glyph": "V", "color": 0xffad72},
	{"id": "memento-17-ampolla-equilibrio", "mondo": 17, "requiresHazardWorld": 17, "slot": "memento", "motif": "pressure_ampoule", "name": "Ampolla d'equilibrio", "description": "Due camere d'acqua restano alla stessa pressione pur avendo forme diverse.", "origine": "Risalita dall'Oceano quando la Corrente delle frazioni ha riconosciuto parti equivalenti.", "cost": 160, "glyph": "=", "color": 0x69c8ff},
	{"id": "memento-18-diapason-riverbero", "mondo": 18, "requiresHazardWorld": 18, "slot": "memento", "motif": "echo_fork", "name": "Diapason del riverbero", "description": "Le due branche rispondono con una frase e la sua eco, nello stesso ordine.", "origine": "Una canna della Cattedrale lo ha lasciato cadere quando il Riverbero delle frasi ha smesso di rimandare parole fuori posto.", "cost": 160, "glyph": "Y", "color": 0xd8a6ff},
	{"id": "memento-19-medaglione-radici", "mondo": 19, "requiresHazardWorld": 19, "slot": "memento", "motif": "root_medallion", "name": "Medaglione delle radici", "description": "Un disco inciso da cui parole diverse tornano a una stessa radice.", "origine": "Le radici della Necropoli lo hanno liberato allentando il Sigillo dei rapporti attorno alle quantità confrontate.", "cost": 160, "glyph": "R", "color": 0xb9a06b},
	{"id": "memento-20-fibbia-concordanza", "mondo": 20, "requiresHazardWorld": 20, "slot": "memento", "motif": "storm_clasp", "name": "Fibbia di concordanza", "description": "Due metà di metallo temporalesco si chiudono soltanto quando forma e numero concordano.", "origine": "Si è saldata nel Campo delle concordanze durante l'ultima scarica della Tempesta.", "cost": 160, "glyph": "=", "color": 0x8de8ff},
	{"id": "memento-21-scheggia-scala", "mondo": 21, "requiresHazardWorld": 21, "slot": "memento", "motif": "scale_shard", "name": "Scheggia di scala", "description": "Un frammento di atlante con due misure diverse della stessa distanza.", "origine": "Proviene dalla Faglia delle scale. Le due incisioni coincidono soltanto dopo aver applicato la conversione corretta.", "cost": 180, "glyph": "/", "color": 0xe59c6c},
	{"id": "memento-22-capsula-periodo", "mondo": 22, "requiresHazardWorld": 22, "slot": "memento", "motif": "spore_capsule", "name": "Capsula del periodo", "description": "Una membrana bioluminescente custodisce una frase completa senza assorbirla.", "origine": "La Biosfera l'ha espulsa quando il Polline dei periodi non ha più trovato frasi interrotte di cui nutrirsi.", "cost": 180, "glyph": "O", "color": 0x76efb2},
	{"id": "memento-23-quadrante-ere", "mondo": 23, "requiresHazardWorld": 23, "slot": "memento", "motif": "era_dial", "name": "Quadrante delle ere", "description": "Quattro lancette segnano durate diverse senza sovrapporre gli avvenimenti.", "origine": "I copisti della Sala lo hanno fermato quando il Cronometro dei rapporti ha restituito a ogni evento il proprio tempo.", "cost": 180, "glyph": "T", "color": 0xf0c879},
	{"id": "memento-24-prisma-sintesi", "mondo": 24, "requiresHazardWorld": 24, "slot": "memento", "motif": "synthesis_prism", "name": "Prisma della sintesi", "description": "Ventiquattro facce raccolgono gesti diversi e restituiscono una sola luce leggibile.", "origine": "Il Cuore dei Primi lo ha lasciato nella camera quando l'Eco della sintesi ha separato di nuovo azioni e significati.", "cost": 180, "glyph": "*", "color": 0xffd75e},
	# --- Strumenti da esplorazione -------------------------------------------
	# Cambiano leggibilità/percorribilità di POI opzionali, senza alterare
	# mastery, gate o ricompense didattiche.
	# Il `cost` resta scritto e non lo paga nessuno: dal 14 agosto 2026 gli
	# strumenti non sono in vendita ([[FieldTools]]), e `can_unlock` li rifiuta
	# prima di guardare il prezzo. Toglierlo vorrebbe dire trattare la vetrina in
	# modo speciale per cinque voci su settanta; lasciarlo costa una riga morta.
	{"id": "tool-torch", "mondo": 1, "slot": "tool", "name": "Torcia da ricognizione", "description": "Illumina la notte profonda e rivela tesori schermati dall'oscurità.", "origine": "Torcia delle caverne. Serve davvero: senza, certe deviazioni restano chiuse.", "cost": 140, "glyph": "*", "color": 0xffc76b},
	{"id": "tool-scythe", "mondo": 2, "slot": "tool", "name": "Falce da campo", "description": "Taglia l'erba alta che protegge deviazioni e tesori opzionali.", "origine": "Falce da sterpaglia della Serra. Apre passaggi, non prove.", "cost": 180, "glyph": "~", "color": 0x91dc72, "minLevel": 2},
	{"id": "tool-lever", "mondo": 5, "slot": "tool", "name": "Leva dei Primi", "description": "Solleva le lastre sigillate che i Primi lasciavano sopra ciò che non voleva essere trovato.", "origine": "Barra di ferro nero delle Officine del Moto. Non era forza: era sapere dove spingere.", "cost": 260, "glyph": "~", "color": 0xc0c6d0, "minLevel": 5},
	{"id": "tool-lens", "mondo": 7, "slot": "tool", "name": "Lente dei Primi", "description": "Rende leggibili le iscrizioni sbiadite: le scritte ci sono ancora, è l'occhio che non arriva.", "origine": "Disco di vetro della Sala dei Glifi, con il bordo consumato dalle dita.", "cost": 300, "glyph": "o", "color": 0x9ad8ff, "minLevel": 7},
	{"id": "tool-bellows", "mondo": 11, "slot": "tool", "name": "Soffietto", "description": "Disperde i banchi di Silenzio denso. Il Silenzio si posa come la polvere, e come la polvere si soffia via.", "origine": "Soffietto da forgia della Soglia del Tempo, col cuoio rappezzato tre volte.", "cost": 360, "glyph": "~", "color": 0xd9c7a4, "minLevel": 11},
	# --- Le forme del Custode: obiettivi costosi di lungo periodo -------------
	#
	# Non sono creature in piu'. Il Custode e' UNO — quello consegnato dalla nave,
	# con il suo legame e i suoi regali — e queste voci decidono che aspetto abbia
	# (`outdoor_world._spawn_pet` legge lo slot `pet` per costruirlo). Le vecchie
	# descrizioni parlavano di compagni che "ti seguono", e un bambino che ne
	# comprava uno si aspettava un secondo animale: era una promessa che il gioco
	# non aveva mai fatto.
	{"id": "pet-dog", "mondo": 4, "slot": "pet", "name": "Cane Scout", "description": "Il Custode prende forma di cane scout: resta basso, vicino, e si pianta dove hai smesso di guardare.", "origine": "Randagio del molo. Si è imbarcato da solo e nessuno se l’è sentita di dirgli di no.", "cost": 1700, "glyph": "*", "color": 0xd9a15f, "minLevel": 4},
	{"id": "pet-cat", "mondo": 2, "slot": "pet", "name": "Gatto Prisma", "description": "Il Custode prende forma di gatto: gira largo e torna quando decide lui.", "origine": "Viveva nell’Archivio, sopra gli scaffali. Conosce i libri meglio dei copisti.", "cost": 2200, "glyph": "*", "color": 0xc7b8ff, "minLevel": 5},
	{"id": "pet-rabbit", "mondo": 10, "slot": "pet", "name": "Coniglio Luma", "description": "Il Custode prende forma di coniglio: sta fermo, poi copre in un salto la distanza che aveva tenuto.", "origine": "Dalla Serra delle Simbiosi, dove niente cresce da solo.", "cost": 2800, "glyph": "*", "color": 0xf2f7ff, "minLevel": 6},
	{"id": "pet-spark", "mondo": 20, "slot": "pet", "name": "Pet Scintilla", "description": "La forma piu' semplice del Custode: un nucleo di luce, senza corpo.", "origine": "Scintilla staccata da un quadro della Tempesta. Non si è più spenta.", "cost": 1500, "glyph": "*", "color": 0xf6c85f, "minLevel": 4},
	{"id": "pet-comet", "mondo": 13, "slot": "pet", "name": "Pet Cometa", "description": "Il Custode diventa una scia: lascia dietro di se' un tratto morbido di dove siete passati.", "origine": "Frammento di scia del Deserto delle Orbite, catturato a mano.", "cost": 1900, "glyph": "~", "color": 0xffb85c, "minLevel": 5},
	{"id": "pet-orbit", "slot": "pet", "name": "Pet Orbita", "description": "Il Custode diventa una sfera ciano e ti gira intorno con passo regolare.", "origine": "Gira e basta. Gli astronomi lo studiano da secoli senza concludere.", "cost": 2400, "glyph": "•", "color": 0x9ff5e9, "minLevel": 6},
	{"id": "pet-satellite", "slot": "pet", "name": "Pet Satellite", "description": "Il Custode si sdoppia in un modulo secondario che gli ruota accanto.", "origine": "Sonda di servizio dei Dodici. Ha ancora la rotta vecchia in memoria.", "cost": 3000, "glyph": "o", "color": 0x7ad7ff, "minLevel": 7},
	{"id": "pet-prisma", "slot": "pet", "name": "Pet Prisma", "description": "Il Custode diventa cristallo: dodici facce, e brilla di piu' dopo una serie precisa.", "origine": "Scheggia del nucleo prismatico: dodici colori, uno per sistema.", "cost": 3600, "glyph": "◊", "color": 0x9f8cff, "minLevel": 8},
	{"id": "pet-luma", "mondo": 22, "slot": "pet", "name": "Pet Luma", "description": "Il Custode diventa una stella viva che pulsa nei momenti in cui hai capito qualcosa.", "origine": "Luce delle caverne della Biosfera. Al buio conta le persone e si tranquillizza.", "cost": 4300, "glyph": "*", "color": 0xffd75e, "minLevel": 9},
	{"id": "pet-guardiano", "mondo": 1, "slot": "pet", "name": "Pet Guardiano", "description": "Il Custode assume il passo lento e dorato dei guardiani dei cristalli.", "origine": "Il guardiano dei cristalli, che Puccio saluta per nome. Tutti e quaranta.", "cost": 5200, "glyph": "◊", "color": 0xffd75e, "minLevel": 10},
	{"id": "pet-codex", "slot": "pet", "name": "Pet Codex", "description": "Il Custode diventa un libro in orbita: si apre da solo sugli argomenti che hai consolidato.", "origine": "Nato dal manuale di NORA quando un argomento diventa consolidato.", "cost": 6800, "glyph": "◊", "color": 0xc7b8ff, "minLevel": 12},
	# --- Emblemi (trofei da esporre) -----------------------------------------
	{"id": "emblem-star", "mondo": 1, "slot": "emblem", "name": "Emblema Stella", "description": "Un trofeo che dice: costanza.", "origine": "Insegna della prima rotta, quando il circuito era un giro di lezioni.", "cost": 400, "glyph": "*"},
	{"id": "emblem-bolt", "mondo": 20, "slot": "emblem", "name": "Emblema Fulmine", "description": "Per chi va veloce e preciso.", "origine": "Segno dei quadri della Tempesta, dove i lampi si contano invece di temerli.", "cost": 720, "glyph": "*"},
	{"id": "emblem-crown", "mondo": 8, "slot": "emblem", "name": "Emblema Corona", "description": "Il premio dei più costanti.", "origine": "Sigillo a tredici posti. Undici nomi, uno raschiato, uno mai inciso.", "cost": 1200, "glyph": "*"},
	{"id": "emblem-atom", "mondo": 10, "slot": "emblem", "name": "Emblema Atomo", "description": "Per esploratori curiosi e precisi.", "origine": "Marchio del banco di osservazione: osserva, ipotizza, cambia una cosa sola.", "cost": 900, "glyph": "*"},
	{"id": "emblem-scroll", "mondo": 23, "slot": "emblem", "name": "Emblema Scriptorium", "description": "Per chi conquista lingue e glifi.", "origine": "Bollo dei copisti della Sala delle Ere. Copiare non è capire, dicevano. Poi copiavano.", "cost": 900, "glyph": "◊"},
	# --- Strumenti NORA (vantaggi leggeri nelle run) -------------------------
	# --- Moduli di spedizione (14 agosto 2026) -------------------------------
	#
	# L'unica cosa che la bottega vende oltre alla bellezza. Ogni voce è appesa a
	# un numero che **esisteva già nel codice**: un oggetto che promette una
	# meccanica inesistente è stato il difetto del 6 agosto, e `endings_audit` lo
	# vieta.
	#
	# Agiscono **sulla mappa e mai su una prova**: è la decisione vincolante 15,
	# ed è ciò che rende lecito vendere potere in un gioco che si studia.
	#
	# **Erano due fino al 2 settembre 2026**, e su settanta voci di catalogo erano
	# le uniche due che cambiassero qualcosa: la bottega vendeva il 97% di colore.
	# Adesso sono sei e **se ne portano da due a quattro** ([[ExpeditionModules]]
	# — la bardatura): comprare non basta più, bisogna anche scegliere che cosa
	# portarsi dietro, ed è lì che sta la gestione delle risorse.
	#
	# Il radar dei forzieri e il cono della torcia — rinviati «a quando la resa
	# esisterà» — entrano adesso perché la resa **era già stata scritta e stava
	# spenta**: `ExpeditionModulePresentation` leggeva due numeri che nessuno
	# pubblicava.
	#
	# **Erano altri tre fino al 21 agosto 2026.** «Serbatoio ampliato» e «Bobina
	# larga» potenziavano l'impulso, che è stato tolto: `costo_delle_sacche_probe`
	# ha misurato che dal mondo 2 in poi nessuna sacca costa energia, quindi
	# quelle due voci vendevano un potenziamento a una meccanica senza lavoro.
	#
	# Chi tocca questo elenco deve rigenerare il foglio premi
	# (`npm run assets:reward`): senza, la bottega resta senza illustrazione e
	# `shop_presentation_audit` diventa rosso.
	{"id": "module-hush", "slot": "module", "name": "Andatura felpata", "description": "Le sacche di Silenzio ti notano solo da vicino.", "origine": "Suole di feltro dei turni di notte: i Dodici le mettevano per non svegliare chi dormiva, e hanno scoperto che non svegliavano nemmeno il Silenzio.", "cost": 340, "glyph": "o", "color": 0x8ff6d2, "minLevel": 3},
	{"id": "module-ballast", "slot": "module", "name": "Zavorra da campo", "description": "Uno spintone ti sposta molto meno.", "origine": "Piombo cucito nell'orlo della tuta, con il punto largo di chi lavorava al buio. Il trucco è antico quanto il vento: chi pesa di più resta dov'era.", "cost": 380, "glyph": "=", "color": 0x9fd8ff, "minLevel": 3},
	{"id": "module-stride", "slot": "module", "name": "Passo da spedizione", "description": "Cammini più svelta: un mondo che si attraversa in fretta è un mondo che si esplora di più.", "origine": "Fasce da polpaccio dei portalettere dei Dodici, che facevano il giro della nave due volte a turno e sostenevano che il segreto fosse nelle caviglie.", "cost": 520, "glyph": "^", "color": 0xffd08a, "minLevel": 4},
	{"id": "module-lantern", "slot": "module", "name": "Riflettore da ricognizione", "description": "Concentra la torcia in un cono davanti a te. Senza torcia non illumina niente: è un riflettore, non una lampada.", "origine": "Specchio parabolico smontato da un faro di prua. Nima lo usava per leggere di notte puntandolo al soffitto.", "cost": 620, "glyph": "*", "color": 0xffc76b, "minLevel": 5},
	{"id": "module-divining", "slot": "module", "name": "Rabdomante dei Primi", "description": "I forzieri ancora chiusi alzano un segnale quando ci passi vicino.", "origine": "Forcella di metallo dei Primi. Non trova l'oro: trova le cose che qualcuno ha deciso di lasciare indietro, che è un'altra faccenda.", "cost": 760, "glyph": "~", "color": 0x8ff6d2, "minLevel": 7},
	{"id": "module-ledger", "slot": "module", "name": "Taccuino del cambio", "description": "Quello che trovi nei forzieri rende di più. Non tocca il premio delle prove: quello non è merce.", "origine": "Registro dei baratti dei Dodici, con i prezzi di quattro secoli fa cancellati e riscritti sopra tre volte.", "cost": 900, "glyph": "◊", "color": 0xc7b8ff, "minLevel": 6},
	{"id": "nora-lens", "slot": "upgrade", "name": "Lente causale", "description": "La lente con cui NORA guardava i guasti quando aveva ancora gli occhi della nave.", "origine": "Ritrovata nel primo apparato riparato. Non serve a vedere meglio: serve a ricordarsi di guardare.", "cost": 360, "glyph": "◊"},
	{"id": "nora-reserve", "slot": "upgrade", "name": "Riserva di bordo", "description": "Una cella di scorta che si illumina piano nella sala macchine.", "origine": "I Dodici ne tenevano una per ciascuno. Undici sono ancora cariche.", "cost": 760, "glyph": "◊"},
	{"id": "nora-shield", "slot": "upgrade", "name": "Paratia rinforzata", "description": "La lastra che ha tenuto il ponte quando tutto il resto ha ceduto.", "origine": "Ha una crepa che nessuno ha mai riparato. NORA dice di lasciarla dov’è.", "cost": 980, "glyph": "◊"},
	{"id": "nora-prismatic-core", "slot": "upgrade", "name": "Nucleo prismatico", "description": "Il cuore della nave, che scompone la luce in dodici colori: uno per sistema.", "origine": "Si accende del colore delle materie che hai portato più avanti. È un ritratto, non una macchina.", "cost": 1600, "glyph": "*"},
	# --- Restauri d'area ------------------------------------------------------
	{"id": "decor-laboratorio", "slot": "decor", "name": "Luci laboratorio", "description": "Riaccende il nucleo visivo dell'area laboratorio.", "origine": "Banco della prima stanza riaccesa.", "cost": 300, "glyph": "*"},
	{"id": "decor-serra", "mondo": 10, "slot": "decor", "name": "Serra rigogliosa", "description": "Aggiunge bagliori verdi e vita alla serra-bio.", "origine": "Talee della Serra, del diario lungo quarant’anni di chi la custodisce.", "cost": 340, "glyph": "◊"},
	{"id": "decor-circuiti", "mondo": 15, "slot": "decor", "name": "Tracce circuiti", "description": "Rende più evidenti piste e nodi del cantiere-circuiti.", "origine": "Quadro di manutenzione della Città Macchina, con il registro dei guasti appeso.", "cost": 360, "glyph": "◊"},
	{"id": "decor-osservatorio", "mondo": 13, "slot": "decor", "name": "Cupola stellare", "description": "Accende una luce morbida nell'osservatorio.", "origine": "Carte del cielo del Deserto delle Orbite, aggiornate a quattro secoli fa.", "cost": 360, "glyph": "*"},
	{"id": "decor-musica", "mondo": 6, "slot": "decor", "name": "Sala accordata", "description": "Illumina il palco della sala-musica.", "origine": "Leggio del Giardino della Risonanza: il liutaio sordo legge con le mani.", "cost": 320, "glyph": "*"},
	{"id": "decor-archivio", "mondo": 2, "slot": "decor", "name": "Archivio vivo", "description": "Riscalda scaffali e postazioni della biblioteca.", "origine": "Scaffale dell’Archivio delle Parole, dove un bambino inventa nomi.", "cost": 320, "glyph": "◊"},
	{"id": "decor-biblioteca-classica", "mondo": 7, "slot": "decor", "name": "Scriptorium ambra", "description": "Riaccende lucerne e oro della biblioteca classica.", "origine": "Volumi delle Rovine. Metà sono commenti sbagliati fatti da qualcuno, con passione.", "cost": 380, "glyph": "◊"},
]

## **Il catalogo si scrive giocando.** (14 agosto 2026)
##
## Ogni voce del catalogo aveva già, dal primo giorno, un campo `origine` che la
## lega a un posto o a una persona precisa — «Pigmento delle Rovine dei Glifi,
## l'unico colore che il tempo non ha sbiadito». Nessuno lo faceva valere: si
## poteva comprare il pigmento delle Rovine senza aver mai visto le Rovine, e la
## bottega restava un menu con una bella prosa attaccata.
##
## `mondo` rende quel legame una regola: la voce entra in vetrina quando quel
## mondo è raggiungibile. Non è un gate didattico — non chiede padronanza, non
## chiede di aver finito niente, basta che la rotta sia aperta — ed è per questo
## che può esistere in un gioco dove niente di opzionale può bloccare niente.
##
## Le voci di provenienza ordinaria entrano arrivando nel mondo; i 24 Ricordi
## dei Pericoli si vedono in anteprima ma chiedono anche la stabilizzazione del
## luogo. Le altre restano sempre disponibili, e non è
## una svista: sono la roba della nave e dei Dodici (le tute di parata, il
## mantello di chi comanda, la sonda di servizio), quella degli itineranti che
## girano tutti i mondi, e i moduli — che toccano il gameplay e non possono
## dipendere da dove sei arrivata. Gli strumenti di campo compaiono invece come
## schede informative: si vedono in bottega, ma non si comprano ([[FieldTools]]).
##
## Ritorna 0 per «nessun mondo richiesto».
static func mondo_di(id: String) -> int:
	return int(find(id).get("mondo", 0))

## Il titolo leggibile del mondo da cui viene una voce: è quello che la vetrina
## mostra al posto del prezzo finché non ci sei arrivata. Dire «Rovine dei Glifi»
## trasforma un articolo non disponibile in un posto dove andare.
static func luogo_di(id: String) -> String:
	var world := mondo_di(id)
	if world <= 0:
		return ""
	return str(WorldProfileCatalog.profile(world).get("title", ""))

static func find(id: String) -> Dictionary:
	for cosmetic in CATALOG:
		if str(cosmetic.get("id", "")) == id:
			return cosmetic
	return {}

static func by_slot(slot: String) -> Array:
	var items: Array = []
	for cosmetic in CATALOG:
		if str(cosmetic.get("slot", "")) == slot:
			items.append(cosmetic)
	return items

## La collezione trasversale dei Pericoli: comprende anche la Sciarpa fotonica,
## che resta un accessorio equipaggiabile, senza duplicare la voce nel catalogo.
static func conquest_items() -> Array:
	var items: Array = []
	for cosmetic in CATALOG:
		if int(cosmetic.get("requiresHazardWorld", 0)) > 0:
			items.append(cosmetic)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("requiresHazardWorld", 0)) < int(b.get("requiresHazardWorld", 0)))
	return items

static func conquest_for_world(world: int) -> Dictionary:
	for cosmetic in CATALOG:
		if int(cosmetic.get("requiresHazardWorld", 0)) == world:
			return cosmetic
	return {}
