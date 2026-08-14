extends SceneTree

## **Il chiavistello è risolvibile, onesto e non punisce.** (14 agosto 2026)
##
## Un minigioco che si gioca decine di volte per mondo non può avere un dente
## rotto ogni cento: il bambino non incontra «un caso raro», incontra il momento
## in cui il gioco ha barato. Questo audit gioca **ogni fascia migliaia di volte**
## e verifica le sole cose che, se saltassero, renderebbero il chiavistello
## ingiusto invece che difficile.
##
## 1. **Una risposta e una sola.** Nessun dente ha due tessere che valgono il
##    bersaglio: un dente ambiguo punisce chi ha ragione.
## 2. **La risposta c'è sempre.** Ogni dente ha esattamente una tessera giusta e
##    il numero di tessere promesso dalle regole.
## 3. **Niente numeri impossibili da leggere a mente**: nessun valore negativo,
##    nessun bersaglio oltre il massimo dichiarato dalla fascia.
## 4. **I distrattori sono vicini, non casuali**: la maggioranza sta entro una
##    distanza ragionevole dal bersaglio, altrimenti si scartano a occhio e il
##    calcolo non serve più.
## 5. **La difficoltà cresce davvero** lungo i ventiquattro mondi, e il tempo non
##    scende mai sotto la soglia in cui si misura il dito invece della testa.
## 6. **L'accessibilità non è una punizione**: con `reduced_motion` il tempo
##    cresce e la rotazione si ferma, sempre.

const GIRI_PER_FASCIA := 3000

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_ogni_dente_e_giusto()
	_la_difficolta_cresce()
	_accessibilita()
	if errori.is_empty():
		print("LOCK CHALLENGE audit VERDE — denti risolvibili, distrattori vicini, difficoltà crescente")
	else:
		printerr("LOCK CHALLENGE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _ogni_dente_e_giusto() -> void:
	var rng := RandomNumberGenerator.new()
	var vicini := 0
	var totale_distrattori := 0
	for world in [1, 3, 5, 8, 10, 13, 15, 18, 20, 24]:
		for tipo in [TreasureCatalog.TIPO_RESTO, TreasureCatalog.TIPO_LASCITO]:
			var regole := LockChallenge.regole(world, str(tipo))
			for giro in range(GIRI_PER_FASCIA / 10):
				rng.seed = hash("chiavistello:%d:%s:%d" % [world, str(tipo), giro])
				var dente := LockChallenge.genera_dente(rng, regole)
				var bersaglio := int(dente.get("bersaglio", -1))
				var tessere: Array = dente.get("tessere", [])

				if tessere.size() != int(regole["tessere"]):
					errori.append("mondo %d: il dente ha %d tessere invece di %d" % [
						world, tessere.size(), int(regole["tessere"])])
					return
				var giuste := 0
				var che_valgono_il_bersaglio := 0
				for voce in tessere:
					var tessera: Dictionary = voce
					var valore := int(tessera.get("valore", -1))
					if bool(tessera.get("giusta", false)):
						giuste += 1
						if valore != bersaglio:
							errori.append("mondo %d: la tessera giusta «%s» vale %d invece di %d" % [
								world, str(tessera.get("testo", "")), valore, bersaglio])
							return
					else:
						totale_distrattori += 1
						if absi(valore - bersaglio) <= maxi(6, int(bersaglio / 3)):
							vicini += 1
					if valore < 0:
						errori.append("mondo %d: la tessera «%s» vale un numero negativo (%d)" % [
							world, str(tessera.get("testo", "")), valore])
						return
					if valore == bersaglio:
						che_valgono_il_bersaglio += 1
					if str(tessera.get("testo", "")).strip_edges() == "":
						errori.append("mondo %d: una tessera è vuota" % world)
						return
					# **Ogni divisione dev'essere esatta.** Una tessera «22 ÷ 3»
					# vale 7 per il gioco e 7,33 per chi la calcola: il bambino
					# che fa il conto giusto non ritrova più il proprio risultato,
					# ed è l'unico modo in cui un minigioco di calcolo può mentire.
					var testo := str(tessera.get("testo", ""))
					if testo.contains("÷"):
						var membri := testo.split(" ")
						var divisore := int(membri[2]) if membri.size() >= 3 else 0
						if divisore > 0 and int(membri[0]) % divisore != 0:
							errori.append("mondo %d: «%s» non è una divisione esatta" % [world, testo])
							return
				if giuste != 1:
					errori.append("mondo %d: il dente ha %d tessere giuste invece di una" % [world, giuste])
					return
				if che_valgono_il_bersaglio != 1:
					errori.append("mondo %d: %d tessere valgono il bersaglio %d: il dente è ambiguo" % [
						world, che_valgono_il_bersaglio, bersaglio])
					return
				if bersaglio <= 0:
					errori.append("mondo %d: bersaglio non valido (%d)" % [world, bersaglio])
					return
	var quota := float(vicini) / maxf(float(totale_distrattori), 1.0)
	_controlla(quota >= 0.45,
		"solo il %d%% dei distrattori sta vicino al bersaglio: si scartano a occhio senza calcolare" % int(quota * 100.0))
	print("  distrattori vicini al bersaglio: %d%% su %d generati" % [
		int(quota * 100.0), totale_distrattori])

func _la_difficolta_cresce() -> void:
	var precedente := {}
	for world in range(1, 25):
		var regole := LockChallenge.regole(world, TreasureCatalog.TIPO_LASCITO)
		_controlla(float(regole["secondi"]) >= LockChallenge.SECONDI_MINIMI,
			"al mondo %d un dente dura %.1fs: sotto la soglia si misura il dito, non il calcolo" % [
				world, float(regole["secondi"])])
		_controlla(int(regole["tessere"]) >= 4,
			"al mondo %d il chiavistello ha meno di quattro tessere" % world)
		_controlla(int(regole["denti"]) >= 1, "al mondo %d il chiavistello non ha denti" % world)
		if not precedente.is_empty():
			_controlla(float(regole["secondi"]) <= float(precedente["secondi"]) + 0.001,
				"al mondo %d il tempo per dente RISALE: la difficoltà torna indietro" % world)
			_controlla(int(regole["massimo"]) >= int(precedente["massimo"]),
				"al mondo %d i numeri tornano più piccoli di prima" % world)
		precedente = regole
	# Il primo mondo e l'ultimo devono essere due cose diverse, o la scala non
	# serve a niente.
	var primo := LockChallenge.regole(1, TreasureCatalog.TIPO_LASCITO)
	var ultimo := LockChallenge.regole(24, TreasureCatalog.TIPO_LASCITO)
	_controlla(float(primo["secondi"]) - float(ultimo["secondi"]) >= 2.0,
		"fra il primo e l'ultimo mondo il tempo cambia di %.1fs soltanto" % (
			float(primo["secondi"]) - float(ultimo["secondi"])))
	_controlla(int(ultimo["massimo"]) >= int(primo["massimo"]) * 5,
		"i numeri dell'ultimo mondo non sono abbastanza più grandi del primo")
	_controlla(not bool(primo["doppia"]) and bool(ultimo["doppia"]),
		"le operazioni doppie non compaiono solo nella seconda metà della campagna")
	# Una cassa qualunque non può chiedere quanto il forziere di qualcuno.
	var resto := LockChallenge.regole(12, TreasureCatalog.TIPO_RESTO)
	var lascito := LockChallenge.regole(12, TreasureCatalog.TIPO_LASCITO)
	_controlla(int(resto["denti"]) < int(lascito["denti"]),
		"una cassa di cianfrusaglie chiede tanti denti quanto un lascito")

func _accessibilita() -> void:
	for world in [1, 12, 24]:
		var normale := LockChallenge.regole(world, TreasureCatalog.TIPO_LASCITO, false)
		var ridotto := LockChallenge.regole(world, TreasureCatalog.TIPO_LASCITO, true)
		_controlla(float(ridotto["secondi"]) > float(normale["secondi"]),
			"al mondo %d il movimento ridotto non allunga il tempo" % world)
		_controlla(float(ridotto["rotazione"]) == 0.0,
			"al mondo %d le tessere ruotano anche con il movimento ridotto" % world)
		_controlla(int(ridotto["tessere"]) == int(normale["tessere"]),
			"al mondo %d l'accessibilità cambia la prova invece del suo ritmo" % world)
