class_name RewardCatalog
extends RefCounted

## Catalogo cosmetici (C-14). Trascritto letteralmente da src/core/RewardCatalog.ts
## (stessi id/slot/nome/descrizione/costo/colore/glifo/minLevel — non inventato):
## qui `minLevel` è confrontato col LIVELLO Godot (apparati riparati 1→24), la
## spina dorsale unica del gioco, non l'euristica multi-sistema del prototipo
## Phaser (playerLevel() combinava run di training, missioni, gym, ecc.).
## Slot: bot, avatar, accessory, pet, emblem, upgrade, decor.
## upgrade/decor non occupano uno slot equipaggiato: sono "posseduti" e basta
## (finiscono in cosmetics.inventory, non in cosmetics.equipped).

const CATALOG := [
	# --- Bit, il compagno ---------------------------------------------------
	{"id": "bot-lime", "slot": "bot", "name": "Bit Lime", "description": "Verde acido brillante per il tuo compagno.", "cost": 120, "color": 0x7cf6a6},
	{"id": "bot-gold", "slot": "bot", "name": "Bit Oro", "description": "Un Bit dorato da campione.", "cost": 260, "color": 0xf6c85f},
	{"id": "bot-violet", "slot": "bot", "name": "Bit Viola", "description": "Look notturno viola-neon.", "cost": 260, "color": 0x9f8cff},
	{"id": "bot-rose", "slot": "bot", "name": "Bit Rosa", "description": "Rosa acceso, impossibile non notarlo.", "cost": 480, "color": 0xff7b9c},
	{"id": "bot-arctic", "slot": "bot", "name": "Bit Artico", "description": "Bianco-ciano, pulito e tecnico.", "cost": 620, "color": 0xbffcff},
	{"id": "bot-solar", "slot": "bot", "name": "Bit Solare", "description": "Bagliore caldo per le serie perfette.", "cost": 860, "color": 0xffb85c},
	# --- Avatar della stanza ------------------------------------------------
	{"id": "avatar-gold", "slot": "avatar", "name": "Outfit Oro", "description": "Tuta oro per l'esploratore.", "cost": 220, "color": 0xf6c85f},
	{"id": "avatar-violet", "slot": "avatar", "name": "Outfit Viola", "description": "Tuta viola per l'esploratore.", "cost": 220, "color": 0x9f8cff},
	{"id": "avatar-emerald", "slot": "avatar", "name": "Outfit Smeraldo", "description": "Verde smeraldo brillante.", "cost": 380, "color": 0x2ed889},
	{"id": "avatar-crimson", "slot": "avatar", "name": "Outfit Cremisi", "description": "Rosso deciso da veterano.", "cost": 560, "color": 0xc94b55},
	{"id": "avatar-nebula", "slot": "avatar", "name": "Outfit Nebula", "description": "Blu profondo con riflessi viola.", "cost": 760, "color": 0x5f7cff},
	{"id": "avatar-aurora", "slot": "avatar", "name": "Outfit Aurora", "description": "Toni verdi e ciano per esplorazioni lunghe.", "cost": 920, "color": 0x74f0c5},
	{"id": "avatar-pilot", "slot": "avatar", "name": "Tuta Pilota", "description": "Giacca chiara con spalliere aerodinamiche.", "cost": 1150, "color": 0x9ff5e9, "minLevel": 4},
	{"id": "avatar-engineer", "slot": "avatar", "name": "Tuta Ingegnere", "description": "Cintura strumenti e pannelli tecnici arancio.", "cost": 1450, "color": 0xffb85c, "minLevel": 5},
	{"id": "avatar-captain", "slot": "avatar", "name": "Mantello Capitano", "description": "Sash luminoso e mantello corto da leader.", "cost": 2100, "color": 0x7ad7ff, "minLevel": 6},
	{"id": "avatar-shadow", "slot": "avatar", "name": "Tenuta Eclisse", "description": "Profilo scuro con linee neon da missioni difficili.", "cost": 3200, "color": 0x9f8cff, "minLevel": 8},
	{"id": "avatar-astral", "slot": "avatar", "name": "Veste Astrale", "description": "Abito leggendario con alone e stelle sul petto.", "cost": 4400, "color": 0xffd75e, "minLevel": 9},
	# --- Accessori equipaggiabili --------------------------------------------
	{"id": "accessory-visor", "slot": "accessory", "name": "Visore tattico", "description": "Una lente luminosa sopra il casco dell'avatar.", "cost": 180, "glyph": "◉", "color": 0x9ff5e9},
	{"id": "accessory-scarf", "slot": "accessory", "name": "Sciarpa fotonica", "description": "Un dettaglio caldo che segue il movimento.", "cost": 280, "glyph": "▰", "color": 0xf6c85f},
	{"id": "accessory-compass", "slot": "accessory", "name": "Bussola stellare", "description": "Piccolo segno da navigatore del Relitto.", "cost": 420, "glyph": "✧", "color": 0x9f8cff},
	{"id": "accessory-pack", "slot": "accessory", "name": "Zaino dati", "description": "Modulo compatto per missioni lunghe.", "cost": 540, "glyph": "▣", "color": 0x7ad7ff},
	{"id": "accessory-crown", "slot": "accessory", "name": "Corona del metodo", "description": "Accessoria rara per chi ama spiegare ogni passo.", "cost": 980, "glyph": "◇", "color": 0xffd75e},
	{"id": "accessory-antenna", "slot": "accessory", "name": "Antenne scanner", "description": "Due antenne sottili sopra il casco.", "cost": 720, "glyph": "⌁", "color": 0x9ff5e9, "minLevel": 4},
	{"id": "accessory-wings", "slot": "accessory", "name": "Ali stabilizzatrici", "description": "Pannelli laterali traslucidi per il movimento.", "cost": 1300, "glyph": "⟐", "color": 0x74f0c5, "minLevel": 6},
	{"id": "accessory-jetpack", "slot": "accessory", "name": "Jetpack didattico", "description": "Doppio modulo dorsale con scie luminose.", "cost": 1700, "glyph": "⇡", "color": 0xffb85c, "minLevel": 7},
	{"id": "accessory-halo", "slot": "accessory", "name": "Aureola prismatica", "description": "Anello raro sospeso sopra l'avatar.", "cost": 2600, "glyph": "○", "color": 0xffd75e, "minLevel": 8},
	# --- Pet-compagni: obiettivi costosi di lungo periodo --------------------
	{"id": "pet-dog", "slot": "pet", "name": "Cane Scout", "description": "Compagno fedele: resta vicino e reagisce forte ai tesori.", "cost": 1700, "glyph": "🐶", "color": 0xd9a15f, "minLevel": 4},
	{"id": "pet-cat", "slot": "pet", "name": "Gatto Prisma", "description": "Agile e curioso: orbita con movimenti morbidi e precisi.", "cost": 2200, "glyph": "🐱", "color": 0xc7b8ff, "minLevel": 5},
	{"id": "pet-rabbit", "slot": "pet", "name": "Coniglio Luma", "description": "Saltella accanto all'avatar e scatta quando rispondi bene.", "cost": 2800, "glyph": "🐰", "color": 0xf2f7ff, "minLevel": 6},
	{"id": "pet-spark", "slot": "pet", "name": "Pet Scintilla", "description": "Un nucleo luminoso che fluttua accanto all'avatar.", "cost": 1500, "glyph": "✦", "color": 0xf6c85f, "minLevel": 4},
	{"id": "pet-comet", "slot": "pet", "name": "Pet Cometa", "description": "Una scia rapida che lascia una traccia morbida.", "cost": 1900, "glyph": "≋", "color": 0xffb85c, "minLevel": 5},
	{"id": "pet-orbit", "slot": "pet", "name": "Pet Orbita", "description": "Una sfera ciano che segue i passi nelle aree del Relitto.", "cost": 2400, "glyph": "●", "color": 0x9ff5e9, "minLevel": 6},
	{"id": "pet-satellite", "slot": "pet", "name": "Pet Satellite", "description": "Orbita con piccolo modulo secondario.", "cost": 3000, "glyph": "◌", "color": 0x7ad7ff, "minLevel": 7},
	{"id": "pet-prisma", "slot": "pet", "name": "Pet Prisma", "description": "Cristallo vivo: brilla di più dopo serie precise.", "cost": 3600, "glyph": "◆", "color": 0x9f8cff, "minLevel": 8},
	{"id": "pet-luma", "slot": "pet", "name": "Pet Luma", "description": "Stella viva che pulsa nei momenti perfetti.", "cost": 4300, "glyph": "✸", "color": 0xffd75e, "minLevel": 9},
	{"id": "pet-guardiano", "slot": "pet", "name": "Pet Guardiano", "description": "Compagno raro da veterani: presenza dorata e lenta.", "cost": 5200, "glyph": "⬡", "color": 0xffd75e, "minLevel": 10},
	{"id": "pet-codex", "slot": "pet", "name": "Pet Codex", "description": "Libro orbitale leggendario che custodisce progressi.", "cost": 6800, "glyph": "▤", "color": 0xc7b8ff, "minLevel": 12},
	# --- Emblemi (trofei da esporre) -----------------------------------------
	{"id": "emblem-star", "slot": "emblem", "name": "Emblema Stella", "description": "Un trofeo che dice: costanza.", "cost": 400, "glyph": "⭐"},
	{"id": "emblem-bolt", "slot": "emblem", "name": "Emblema Fulmine", "description": "Per chi va veloce e preciso.", "cost": 720, "glyph": "⚡"},
	{"id": "emblem-crown", "slot": "emblem", "name": "Emblema Corona", "description": "Il premio dei più costanti.", "cost": 1200, "glyph": "👑"},
	{"id": "emblem-atom", "slot": "emblem", "name": "Emblema Atomo", "description": "Per esploratori curiosi e precisi.", "cost": 900, "glyph": "✺"},
	{"id": "emblem-scroll", "slot": "emblem", "name": "Emblema Scriptorium", "description": "Per chi conquista lingue e glifi.", "cost": 900, "glyph": "◈"},
	# --- Strumenti NORA (vantaggi leggeri nelle run) -------------------------
	{"id": "nora-lens", "slot": "upgrade", "name": "Lente causale NORA", "description": "Il primo indizio di ogni run non consuma aiuti.", "cost": 360, "glyph": "◇"},
	{"id": "nora-reserve", "slot": "upgrade", "name": "Riserva rapida", "description": "Gli impulsi NORA si caricano dopo ogni sistema risolto.", "cost": 760, "glyph": "⟡"},
	{"id": "nora-shield", "slot": "upgrade", "name": "Scudo rinforzato", "description": "Una carica NORA può recuperare due vite invece di una.", "cost": 980, "glyph": "⬡"},
	{"id": "nora-prismatic-core", "slot": "upgrade", "name": "Nucleo prismatico", "description": "La stabilità stanza usa energia prismatica permanente.", "cost": 1600, "glyph": "✺"},
	# --- Restauri d'area ------------------------------------------------------
	{"id": "decor-laboratorio", "slot": "decor", "name": "Luci laboratorio", "description": "Riaccende il nucleo visivo dell'area laboratorio.", "cost": 300, "glyph": "✦"},
	{"id": "decor-serra", "slot": "decor", "name": "Serra rigogliosa", "description": "Aggiunge bagliori verdi e vita alla serra-bio.", "cost": 340, "glyph": "◆"},
	{"id": "decor-circuiti", "slot": "decor", "name": "Tracce circuiti", "description": "Rende più evidenti piste e nodi del cantiere-circuiti.", "cost": 360, "glyph": "⬡"},
	{"id": "decor-osservatorio", "slot": "decor", "name": "Cupola stellare", "description": "Accende una luce morbida nell'osservatorio.", "cost": 360, "glyph": "✧"},
	{"id": "decor-musica", "slot": "decor", "name": "Sala accordata", "description": "Illumina il palco della sala-musica.", "cost": 320, "glyph": "♪"},
	{"id": "decor-archivio", "slot": "decor", "name": "Archivio vivo", "description": "Riscalda scaffali e postazioni della biblioteca.", "cost": 320, "glyph": "▣"},
	{"id": "decor-biblioteca-classica", "slot": "decor", "name": "Scriptorium ambra", "description": "Riaccende lucerne e oro della biblioteca classica.", "cost": 380, "glyph": "◈"},
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
