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
	{"id": "bot-lime", "slot": "bot", "name": "Bit Lime", "description": "Verde acido brillante per il tuo compagno.", "origine": "Vernice avanzata dai segnavia della radura: Tobia ne aveva un barattolo di troppo.", "cost": 120, "color": 0x7cf6a6},
	{"id": "bot-gold", "slot": "bot", "name": "Bit Oro", "description": "Un Bit dorato da campione.", "origine": "Foglia d’oro dalla bottega di Nonna Ersilia, tenuta per i giorni buoni.", "cost": 260, "color": 0xf6c85f},
	{"id": "bot-violet", "slot": "bot", "name": "Bit Viola", "description": "Look notturno viola-neon.", "origine": "Pigmento delle Rovine dei Glifi, l’unico colore che il tempo non ha sbiadito.", "cost": 260, "color": 0x9f8cff},
	{"id": "bot-rose", "slot": "bot", "name": "Bit Rosa", "description": "Rosa acceso, impossibile non notarlo.", "origine": "Colore del molo all’alba, quando le insegne si riempiono da sole.", "cost": 480, "color": 0xff7b9c},
	{"id": "bot-arctic", "slot": "bot", "name": "Bit Artico", "description": "Bianco-ciano, pulito e tecnico.", "origine": "Ghiaccio della Biosfera Profonda, che a toccarlo non è freddo.", "cost": 620, "color": 0xbffcff},
	{"id": "bot-solar", "slot": "bot", "name": "Bit Solare", "description": "Bagliore caldo per le serie perfette.", "origine": "Filamento del Deserto delle Orbite: brilla se lo guardi da fermo.", "cost": 860, "color": 0xffb85c},
	# --- Avatar della stanza ------------------------------------------------
	{"id": "avatar-gold", "slot": "avatar", "name": "Outfit Oro", "description": "Tuta oro per l'esploratore.", "origine": "Tuta da parata dei Dodici, mai usata: non c’è stata nessuna parata.", "cost": 220, "color": 0xf6c85f},
	{"id": "avatar-violet", "slot": "avatar", "name": "Outfit Viola", "description": "Tuta viola per l'esploratore.", "origine": "Tenuta notturna dell’Archivio delle Parole.", "cost": 220, "color": 0x9f8cff},
	{"id": "avatar-emerald", "slot": "avatar", "name": "Outfit Smeraldo", "description": "Verde smeraldo brillante.", "origine": "Verde della Serra delle Simbiosi, dove tutto cresce insieme a qualcos’altro.", "cost": 380, "color": 0x2ed889},
	{"id": "avatar-crimson", "slot": "avatar", "name": "Outfit Cremisi", "description": "Rosso deciso da veterano.", "origine": "Rosso delle Officine del Moto. Si sporca e non si vede: apposta.", "cost": 560, "color": 0xc94b55},
	{"id": "avatar-nebula", "slot": "avatar", "name": "Outfit Nebula", "description": "Blu profondo con riflessi viola.", "origine": "Tessuto ricavato dalle vele lunghe, quelle che leggono i segnali.", "cost": 760, "color": 0x5f7cff},
	{"id": "avatar-aurora", "slot": "avatar", "name": "Outfit Aurora", "description": "Toni verdi e ciano per esplorazioni lunghe.", "origine": "Per le esplorazioni lunghe. Le sorelle ne avevano una ciascuna.", "cost": 920, "color": 0x74f0c5},
	{"id": "avatar-pilot", "slot": "avatar", "name": "Tuta Pilota", "description": "Giacca chiara con spalliere aerodinamiche.", "origine": "Giacca di chi porta la nave. Sul colletto c’è ancora un nome, scucito.", "cost": 1150, "color": 0x9ff5e9, "minLevel": 4},
	{"id": "avatar-engineer", "slot": "avatar", "name": "Tuta Ingegnere", "description": "Cintura strumenti e pannelli tecnici arancio.", "origine": "Cintura di Ruggine, che ha smesso di credere che chiedere aiuto sia pigrizia.", "cost": 1450, "color": 0xffb85c, "minLevel": 5},
	{"id": "avatar-captain", "slot": "avatar", "name": "Mantello Capitano", "description": "Sash luminoso e mantello corto da leader.", "origine": "Mantello del posto che comanda. Il tredicesimo non l’ha mai indossato.", "cost": 2100, "color": 0x7ad7ff, "minLevel": 6},
	{"id": "avatar-shadow", "slot": "avatar", "name": "Tenuta Eclisse", "description": "Profilo scuro con linee neon da missioni difficili.", "origine": "Profilo scuro per il volume senza porta. Serviva a non farsi notare da sé stessi.", "cost": 3200, "color": 0x9f8cff, "minLevel": 8},
	{"id": "avatar-astral", "slot": "avatar", "name": "Veste Astrale", "description": "Abito leggendario con alone e stelle sul petto.", "origine": "Veste della cattedra vuota. Era apparecchiata anche lei, e ha aspettato.", "cost": 4400, "color": 0xffd75e, "minLevel": 9},
	# --- Accessori equipaggiabili --------------------------------------------
	{"id": "accessory-visor", "slot": "accessory", "name": "Visore tattico", "description": "Una lente luminosa sopra il casco dell'avatar.", "origine": "Lente da diagnosi, dalla Città Macchina.", "cost": 180, "glyph": "◉", "color": 0x9ff5e9},
	{"id": "accessory-scarf", "slot": "accessory", "name": "Sciarpa fotonica", "description": "Un dettaglio caldo che segue il movimento.", "origine": "Sciarpa di Ersilia. La dà a chi finisce la conta senza sbagliare.", "cost": 280, "glyph": "▰", "color": 0xf6c85f},
	{"id": "accessory-compass", "slot": "accessory", "name": "Bussola stellare", "description": "Piccolo segno da navigatore del Relitto.", "origine": "Bussola di Nima, che disegna mappe di posti da inventare.", "cost": 420, "glyph": "✧", "color": 0x9f8cff},
	{"id": "accessory-pack", "slot": "accessory", "name": "Zaino dati", "description": "Modulo compatto per missioni lunghe.", "origine": "Zaino da missione lunga, con dentro ancora gli appunti di qualcuno.", "cost": 540, "glyph": "▣", "color": 0x7ad7ff},
	{"id": "accessory-crown", "slot": "accessory", "name": "Corona del metodo", "description": "Accessoria rara per chi ama spiegare ogni passo.", "origine": "Non incorona nessuno: segnala chi spiega ogni passaggio anche quando non serve.", "cost": 980, "glyph": "◇", "color": 0xffd75e},
	{"id": "accessory-antenna", "slot": "accessory", "name": "Antenne scanner", "description": "Due antenne sottili sopra il casco.", "origine": "Antenne dalla Baia dei Segnali. Rispondono anche ai messaggi non tuoi.", "cost": 720, "glyph": "⌁", "color": 0x9ff5e9, "minLevel": 4},
	{"id": "accessory-wings", "slot": "accessory", "name": "Ali stabilizzatrici", "description": "Pannelli laterali traslucidi per il movimento.", "origine": "Pannelli dell’Arcipelago, per stare in equilibrio sulle chiuse.", "cost": 1300, "glyph": "⟐", "color": 0x74f0c5, "minLevel": 6},
	{"id": "accessory-jetpack", "slot": "accessory", "name": "Jetpack didattico", "description": "Doppio modulo dorsale con scie luminose.", "origine": "Prototipo del Cratere Logico. Funziona; nessuno sa ancora perché.", "cost": 1700, "glyph": "⇡", "color": 0xffb85c, "minLevel": 7},
	{"id": "accessory-halo", "slot": "accessory", "name": "Aureola prismatica", "description": "Anello raro sospeso sopra l'avatar.", "origine": "Anello prismatico del Cuore. Si accende quando dodici sistemi sono in linea.", "cost": 2600, "glyph": "○", "color": 0xffd75e, "minLevel": 8},
	# --- Strumenti da esplorazione -------------------------------------------
	# Cambiano leggibilità/percorribilità di POI opzionali, senza alterare
	# mastery, gate o ricompense didattiche.
	{"id": "tool-torch", "slot": "tool", "name": "Torcia da ricognizione", "description": "Illumina la notte profonda e rivela tesori schermati dall'oscurità.", "origine": "Torcia delle caverne. Serve davvero: senza, certe deviazioni restano chiuse.", "cost": 140, "glyph": "✦", "color": 0xffc76b},
	{"id": "tool-scythe", "slot": "tool", "name": "Falce da campo", "description": "Taglia l'erba alta che protegge deviazioni e tesori opzionali.", "origine": "Falce da sterpaglia della Serra. Apre passaggi, non prove.", "cost": 180, "glyph": "⌁", "color": 0x91dc72, "minLevel": 2},
	# --- Pet-compagni: obiettivi costosi di lungo periodo --------------------
	{"id": "pet-dog", "slot": "pet", "name": "Cane Scout", "description": "Compagno fedele: resta vicino e reagisce forte ai tesori.", "origine": "Randagio del molo. Si è imbarcato da solo e nessuno se l’è sentita di dirgli di no.", "cost": 1700, "glyph": "🐶", "color": 0xd9a15f, "minLevel": 4},
	{"id": "pet-cat", "slot": "pet", "name": "Gatto Prisma", "description": "Agile e curioso: orbita con movimenti morbidi e precisi.", "origine": "Viveva nell’Archivio, sopra gli scaffali. Conosce i libri meglio dei copisti.", "cost": 2200, "glyph": "🐱", "color": 0xc7b8ff, "minLevel": 5},
	{"id": "pet-rabbit", "slot": "pet", "name": "Coniglio Luma", "description": "Saltella accanto all'avatar e scatta quando rispondi bene.", "origine": "Dalla Serra delle Simbiosi, dove niente cresce da solo.", "cost": 2800, "glyph": "🐰", "color": 0xf2f7ff, "minLevel": 6},
	{"id": "pet-spark", "slot": "pet", "name": "Pet Scintilla", "description": "Un nucleo luminoso che fluttua accanto all'avatar.", "origine": "Scintilla staccata da un quadro della Tempesta. Non si è più spenta.", "cost": 1500, "glyph": "✦", "color": 0xf6c85f, "minLevel": 4},
	{"id": "pet-comet", "slot": "pet", "name": "Pet Cometa", "description": "Una scia rapida che lascia una traccia morbida.", "origine": "Frammento di scia del Deserto delle Orbite, catturato a mano.", "cost": 1900, "glyph": "≋", "color": 0xffb85c, "minLevel": 5},
	{"id": "pet-orbit", "slot": "pet", "name": "Pet Orbita", "description": "Una sfera ciano che segue i passi nelle aree del Relitto.", "origine": "Gira e basta. Gli astronomi lo studiano da secoli senza concludere.", "cost": 2400, "glyph": "●", "color": 0x9ff5e9, "minLevel": 6},
	{"id": "pet-satellite", "slot": "pet", "name": "Pet Satellite", "description": "Orbita con piccolo modulo secondario.", "origine": "Sonda di servizio dei Dodici. Ha ancora la rotta vecchia in memoria.", "cost": 3000, "glyph": "◌", "color": 0x7ad7ff, "minLevel": 7},
	{"id": "pet-prisma", "slot": "pet", "name": "Pet Prisma", "description": "Cristallo vivo: brilla di più dopo serie precise.", "origine": "Scheggia del nucleo prismatico: dodici colori, uno per sistema.", "cost": 3600, "glyph": "◆", "color": 0x9f8cff, "minLevel": 8},
	{"id": "pet-luma", "slot": "pet", "name": "Pet Luma", "description": "Stella viva che pulsa nei momenti perfetti.", "origine": "Luce delle caverne della Biosfera. Al buio conta le persone e si tranquillizza.", "cost": 4300, "glyph": "✸", "color": 0xffd75e, "minLevel": 9},
	{"id": "pet-guardiano", "slot": "pet", "name": "Pet Guardiano", "description": "Compagno raro da veterani: presenza dorata e lenta.", "origine": "Il guardiano dei cristalli, che Puccio saluta per nome. Tutti e quaranta.", "cost": 5200, "glyph": "⬡", "color": 0xffd75e, "minLevel": 10},
	{"id": "pet-codex", "slot": "pet", "name": "Pet Codex", "description": "Libro orbitale leggendario che custodisce progressi.", "origine": "Nato dal manuale di NORA quando un argomento diventa consolidato.", "cost": 6800, "glyph": "▤", "color": 0xc7b8ff, "minLevel": 12},
	# --- Emblemi (trofei da esporre) -----------------------------------------
	{"id": "emblem-star", "slot": "emblem", "name": "Emblema Stella", "description": "Un trofeo che dice: costanza.", "origine": "Insegna della prima rotta, quando il circuito era un giro di lezioni.", "cost": 400, "glyph": "⭐"},
	{"id": "emblem-bolt", "slot": "emblem", "name": "Emblema Fulmine", "description": "Per chi va veloce e preciso.", "origine": "Segno dei quadri della Tempesta, dove i lampi si contano invece di temerli.", "cost": 720, "glyph": "⚡"},
	{"id": "emblem-crown", "slot": "emblem", "name": "Emblema Corona", "description": "Il premio dei più costanti.", "origine": "Sigillo a tredici posti. Undici nomi, uno raschiato, uno mai inciso.", "cost": 1200, "glyph": "👑"},
	{"id": "emblem-atom", "slot": "emblem", "name": "Emblema Atomo", "description": "Per esploratori curiosi e precisi.", "origine": "Marchio del banco di osservazione: osserva, ipotizza, cambia una cosa sola.", "cost": 900, "glyph": "✺"},
	{"id": "emblem-scroll", "slot": "emblem", "name": "Emblema Scriptorium", "description": "Per chi conquista lingue e glifi.", "origine": "Bollo dei copisti della Sala delle Ere. Copiare non è capire, dicevano. Poi copiavano.", "cost": 900, "glyph": "◈"},
	# --- Strumenti NORA (vantaggi leggeri nelle run) -------------------------
	{"id": "nora-lens", "slot": "upgrade", "name": "Lente causale", "description": "La lente con cui NORA guardava i guasti quando aveva ancora gli occhi della nave.", "origine": "Ritrovata nel primo apparato riparato. Non serve a vedere meglio: serve a ricordarsi di guardare.", "cost": 360, "glyph": "◇"},
	{"id": "nora-reserve", "slot": "upgrade", "name": "Riserva di bordo", "description": "Una cella di scorta che si illumina piano nella sala macchine.", "origine": "I Dodici ne tenevano una per ciascuno. Undici sono ancora cariche.", "cost": 760, "glyph": "⟡"},
	{"id": "nora-shield", "slot": "upgrade", "name": "Paratia rinforzata", "description": "La lastra che ha tenuto il ponte quando tutto il resto ha ceduto.", "origine": "Ha una crepa che nessuno ha mai riparato. NORA dice di lasciarla dov’è.", "cost": 980, "glyph": "⬡"},
	{"id": "nora-prismatic-core", "slot": "upgrade", "name": "Nucleo prismatico", "description": "Il cuore della nave, che scompone la luce in dodici colori: uno per sistema.", "origine": "Si accende del colore delle materie che hai portato più avanti. È un ritratto, non una macchina.", "cost": 1600, "glyph": "✺"},
	# --- Restauri d'area ------------------------------------------------------
	{"id": "decor-laboratorio", "slot": "decor", "name": "Luci laboratorio", "description": "Riaccende il nucleo visivo dell'area laboratorio.", "origine": "Banco della prima stanza riaccesa.", "cost": 300, "glyph": "✦"},
	{"id": "decor-serra", "slot": "decor", "name": "Serra rigogliosa", "description": "Aggiunge bagliori verdi e vita alla serra-bio.", "origine": "Talee della Serra, del diario lungo quarant’anni di chi la custodisce.", "cost": 340, "glyph": "◆"},
	{"id": "decor-circuiti", "slot": "decor", "name": "Tracce circuiti", "description": "Rende più evidenti piste e nodi del cantiere-circuiti.", "origine": "Quadro di manutenzione della Città Macchina, con il registro dei guasti appeso.", "cost": 360, "glyph": "⬡"},
	{"id": "decor-osservatorio", "slot": "decor", "name": "Cupola stellare", "description": "Accende una luce morbida nell'osservatorio.", "origine": "Carte del cielo del Deserto delle Orbite, aggiornate a quattro secoli fa.", "cost": 360, "glyph": "✧"},
	{"id": "decor-musica", "slot": "decor", "name": "Sala accordata", "description": "Illumina il palco della sala-musica.", "origine": "Leggio del Giardino della Risonanza: il liutaio sordo legge con le mani.", "cost": 320, "glyph": "♪"},
	{"id": "decor-archivio", "slot": "decor", "name": "Archivio vivo", "description": "Riscalda scaffali e postazioni della biblioteca.", "origine": "Scaffale dell’Archivio delle Parole, dove un bambino inventa nomi.", "cost": 320, "glyph": "▣"},
	{"id": "decor-biblioteca-classica", "slot": "decor", "name": "Scriptorium ambra", "description": "Riaccende lucerne e oro della biblioteca classica.", "origine": "Volumi delle Rovine. Metà sono commenti sbagliati fatti da qualcuno, con passione.", "cost": 380, "glyph": "◈"},
]

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
