extends SceneTree

## **Il cielo di ogni mondo dice l'ora che promette.** (20 agosto 2026)
##
## Nasce da una misura, non da un'idea. I profili dichiarano ventiquattro ore
## d'autore, tutte diverse; il codice che le leggeva cercava quattro
## sottostringhe, e il risultato era che **diciotto mondi su ventiquattro
## rendevano a mezzogiorno identico**. Fra questi: Città Macchina
## («neon-notturno» — la parola «notte» non è dentro «notturno»), l'Oceano delle
## Forze («blu-profondo», un abisso), la Biosfera Profonda («bioluminescente»,
## caverne) e la Tempesta Elettromagnetica («lampi-intermittenti»).
##
## Nessun audit se ne era accorto perché il risultato era un mondo **perfettamente
## giocabile**: solo, con l'ora sbagliata. È il tipo di difetto che non si vede
## finché qualcuno non conta, ed è esattamente ciò che questo file adesso fa.
##
## Le proprietà tenute qui:
##
##   1. **nessun mondo cade nel ripiego**: ogni etichetta dei profili ha la sua
##      riga in tabella;
##   2. **chi promette buio resta buio a ogni ora del giro**;
##   3. **dove c'è un cielo il tempo si vede passare**, e dove non c'è non
##      cambia niente;
##   4. **la notte è più corta del giorno**: questo è un gioco che si studia;
##   5. **il pavimento di leggibilità regge**, e la scena lo applica davvero.

var _rossi: Array = []

func _init() -> void:
	_prova_tutte_le_etichette()
	_prova_chi_promette_buio()
	_prova_il_tempo_passa()
	_prova_la_notte_e_piu_corta()
	_prova_il_pavimento()
	_prova_la_scena_lo_usa()
	if _rossi.is_empty():
		print("WORLD SKY audit OK — ventiquattro ore d'autore, il tempo che passa dove c'e' un cielo")
		quit(0)
		return
	for riga in _rossi:
		printerr("WORLD SKY audit FALLITO — %s" % riga)
	quit(1)

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		_rossi.append(messaggio)

func _etichette() -> Array:
	var out: Array = []
	for livello in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		out.append({
			"livello": livello,
			"lighting": str(WorldProfileCatalog.profile(livello).get("lighting", "")).to_lower(),
		})
	return out

## Il campionamento di un giro intero: trentasei prese, una ogni dieci gradi.
func _giro(lighting: String) -> Array:
	var out: Array = []
	for passo in range(36):
		out.append(WorldSky.luce_del_cielo(lighting, float(passo) / 36.0))
	return out

func _prova_tutte_le_etichette() -> void:
	var viste: Dictionary = {}
	for voce_data in _etichette():
		var voce: Dictionary = voce_data
		var lighting := str(voce["lighting"])
		_controlla(lighting != "", "il mondo %d non dichiara nessuna ora" % int(voce["livello"]))
		_controlla(WorldSky.ORE.has(lighting),
			"il mondo %d («%s») non ha una riga in tabella e cadrebbe nel ripiego"
			% [int(voce["livello"]), lighting])
		viste[lighting] = true
	# E nessuna riga in tabella deve restare orfana: una scritta a mano per un
	# mondo che poi ha cambiato etichetta è una regola che non governa niente.
	for chiave in WorldSky.ORE.keys():
		_controlla(viste.has(str(chiave)),
			"la tabella descrive «%s», che nessun mondo usa piu'" % str(chiave))

func _prova_chi_promette_buio() -> void:
	# Le parole con cui un profilo promette il buio. Se un giorno se ne aggiunge
	# una nuova, va aggiunta qui: è il posto in cui la promessa diventa verifica.
	var promesse := ["notte", "notturno", "penombra", "profondo", "bioluminescente"]
	for voce_data in _etichette():
		var voce: Dictionary = voce_data
		var lighting := str(voce["lighting"])
		var promette := false
		for parola in promesse:
			if lighting.contains(str(parola)):
				promette = true
				break
		if not promette:
			continue
		var massima := 0.0
		for luce in _giro(lighting):
			massima = maxf(massima, float(luce))
		_controlla(WorldSky.fase(massima, 0.5) != "giorno",
			"il mondo %d si chiama «%s» e arriva a luce %.2f: e' pieno giorno"
			% [int(voce["livello"]), lighting, massima])

func _prova_il_tempo_passa() -> void:
	var con_cielo := 0
	for voce_data in _etichette():
		var voce: Dictionary = voce_data
		var lighting := str(voce["lighting"])
		var valori := _giro(lighting)
		var minimo := 1.0
		var massimo := 0.0
		for luce in valori:
			minimo = minf(minimo, float(luce))
			massimo = maxf(massimo, float(luce))
		if WorldSky.cammina(lighting):
			con_cielo += 1
			# «Si vede passare» ha un numero: un quarto di escursione. Sotto,
			# l'orologio gira e nessuno se ne accorge — che è il difetto di
			# partenza con un'altra faccia.
			_controlla(massimo - minimo >= 0.25,
				"il mondo %d («%s») cammina ma l'escursione e' %.2f: il tempo non si vede passare"
				% [int(voce["livello"]), lighting, massimo - minimo])
		else:
			_controlla(is_equal_approx(minimo, massimo),
				"il mondo %d («%s») non ha un cielo eppure la sua luce cambia"
				% [int(voce["livello"]), lighting])
	# Un ciclo che vale per tre mondi non è «rimettere il giorno e la notte».
	_controlla(con_cielo >= 12,
		"solo %d mondi su %d hanno un tempo che passa" % [con_cielo, WorldProfileCatalog.MAX_LEVEL])

func _prova_la_notte_e_piu_corta() -> void:
	# Su un mondo a banda piena: la notte deve occupare meno di un terzo del
	# giro. Non è realismo, è che un bambino non può passare metà della sessione
	# a leggere enigmi al buio.
	var notti := 0
	var campioni := 0
	for luce in _giro("giorno-limpido"):
		campioni += 1
		if WorldSky.fase(float(luce), 0.5) == "notte":
			notti += 1
	_controlla(float(notti) / float(campioni) < 0.34,
		"la notte occupa il %d%% del giro" % roundi(100.0 * float(notti) / float(campioni)))
	_controlla(WorldSky.CURVA < 1.0,
		"la curva non accorcia piu' la notte (%.2f)" % WorldSky.CURVA)
	# Il giro dura abbastanza da non lampeggiare e poco da vedersi in una
	# sessione di studio.
	_controlla(WorldSky.DURATA >= 300.0 and WorldSky.DURATA <= 1800.0,
		"un giro dura %.0f s: fuori dal respiro di una sessione" % WorldSky.DURATA)
	# Alba e tramonto sono la stessa luce e non la stessa cosa.
	_controlla(WorldSky.fase(0.5, 0.2) == "alba" and WorldSky.fase(0.5, 0.8) == "tramonto",
		"alba e tramonto non si distinguono")
	_controlla(WorldSky.fase_di_sistema("tramonto") == "alba",
		"il tramonto arriva all'audio e a WorldLife come una parola che non conoscono")

func _prova_il_pavimento() -> void:
	# **La forbice.** (20 agosto 2026) Il pavimento ha due modi di sbagliare, e
	# sono opposti: troppo alto e la notte non e' piu' notte — a 0.34 la Radura
	# calava in una sera perenne — troppo basso e su un pannello scolastico a
	# contrasto ridotto il bambino non trova piu' Eli. Le due sponde stanno qui
	# perche' chi un giorno vorra' spostare il numero legga prima perche' non e'
	# libero.
	_controlla(WorldSky.PAVIMENTO <= 0.28,
		"pavimento a %.2f: la notte non arriva mai a essere notte" % WorldSky.PAVIMENTO)
	_controlla(WorldSky.PAVIMENTO >= 0.12,
		"pavimento a %.2f: al buio pieno non si gioca piu'" % WorldSky.PAVIMENTO)

	for campione in [Color(0.02, 0.03, 0.05), Color("0b1a2e"), Color("120c04"), Color.BLACK]:
		var alzato := WorldSky.sopra_il_pavimento(campione)
		_controlla(WorldSky.luminanza_di(alzato) >= WorldSky.PAVIMENTO - 0.001,
			"il pavimento non regge su %s: luminanza %.2f"
			% [campione.to_html(false), WorldSky.luminanza_di(alzato)])
	# E non tocca ciò che è già leggibile: un pavimento che schiarisce il
	# mezzogiorno avrebbe cancellato la notte insieme al buio.
	var chiaro := Color("d9e2f1")
	_controlla(WorldSky.sopra_il_pavimento(chiaro).is_equal_approx(chiaro),
		"il pavimento schiarisce anche quello che era gia' leggibile")

func _prova_la_scena_lo_usa() -> void:
	var file := FileAccess.open("res://scripts/outdoor_world.gd", FileAccess.READ)
	if file == null:
		_rossi.append("scena mondo assente")
		return
	var sorgente := file.get_as_text()
	_controlla(sorgente.contains("WorldSky.sopra_il_pavimento"),
		"la scena non applica il pavimento di leggibilita': il numero esiste e non governa niente")
	_controlla(sorgente.contains("_il_cielo_cammina"),
		"la scena non distingue i mondi in cui il tempo passa")
	_controlla(sorgente.contains("FieldTools.TORCIA"),
		"lo scurimento della notte non guarda piu' la torcia posseduta")
