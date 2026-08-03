extends SceneTree

## I sei itineranti sono i personaggi che si rivedono di più: uno per mondo,
## ventiquattro incontri. Un difetto che su un residente si nota una volta, su di
## loro si nota ventiquattro.
##
## Tre cose valgono la pena di essere vincolate:
##
## 1. **la rotazione** — mai due mondi di fila con la stessa faccia, e tutti e
##    sei devono comparire in una campagna. Un cast di sei che ne mostra tre fa
##    sembrare il gioco più piccolo di quello che è;
## 2. **i tic**, che qui sono la personalità intera: Vera che non chiude con una
##    domanda non è Vera, è una comparsa;
## 3. **il bersaglio comico**. §2.4 lo dice esplicitamente: si ride con Eli, mai
##    di lei, e mai di un errore. È l'unica regola di questo file che protegge
##    qualcuno che non è nel file.

const MIN_BATTUTE := 12
const MAX_SCHERMATE := 3
const MIN_TIC_SHARE := 0.34

## Formule che prendono in giro il giocatore. Sono innocue una alla volta e
## corrosive addosso a un bambino che sta sbagliando.
const DERISIONE := [
	"che figura", "ci sei cascata", "te l'avevo detto", "tanto non ci arrivi",
	"come al solito sbagli", "sei sempre la solita", "ma come fai a",
	"non hai capito niente", "ridicola", "che sbadata",
]

func _init() -> void:
	var failures: Array = []
	print("I sei itineranti — il cast che si rivede di più\n")

	failures.append_array(_check_cast())
	failures.append_array(_check_rotazione())

	if not failures.is_empty():
		printerr("ITINERANTI NON VALIDI — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nItinerant audit OK — sei registri, tic al loro posto, rotazione senza ripetizioni")
	quit(0)

func _check_cast() -> Array:
	var out: Array = []
	if ItinerantCatalog.ITINERANTI.size() != 6:
		out.append("gli itineranti sono %d, il documento ne prevede 6" % ItinerantCatalog.ITINERANTI.size())

	var registri: Dictionary = {}
	var funzioni: Dictionary = {}
	var ids: Array = ItinerantCatalog.ITINERANTI.keys()
	ids.sort()
	for itinerant_id in ids:
		var npc := ItinerantCatalog.ITINERANTI[itinerant_id] as Dictionary
		var lines := ItinerantCatalog.all_lines(str(itinerant_id))

		for field in ["nome", "registro", "chi", "tic", "ticMarker", "funzione"]:
			if str(npc.get(field, "")).strip_edges() == "":
				out.append("%s: campo «%s» mancante" % [itinerant_id, field])

		var registro := str(npc.get("registro", ""))
		if registri.has(registro):
			out.append("%s ha lo stesso registro di %s: sei toni diversi era il punto" % [
				itinerant_id, str(registri[registro])])
		registri[registro] = itinerant_id

		var funzione := str(npc.get("funzione", ""))
		if funzioni.has(funzione):
			out.append("%s ha la stessa funzione di %s" % [itinerant_id, str(funzioni[funzione])])
		funzioni[funzione] = itinerant_id

		if lines.size() < MIN_BATTUTE:
			out.append("%s: %d battute, minimo %d" % [itinerant_id, lines.size(), MIN_BATTUTE])

		var seen: Dictionary = {}
		var hits := 0
		var marker := str(npc.get("ticMarker", "")).to_lower()
		for line_data in lines:
			var screens: Array = line_data
			if screens.is_empty() or screens.size() > MAX_SCHERMATE:
				out.append("%s: battuta di %d schermate, ammesse 1-%d" % [
					itinerant_id, screens.size(), MAX_SCHERMATE])
			var joined := " ".join(PackedStringArray(screens))
			if joined.strip_edges() == "":
				out.append("%s: battuta vuota" % itinerant_id)
			if seen.has(joined):
				out.append("%s: battuta ripetuta due volte" % itinerant_id)
			seen[joined] = true
			if marker != "" and joined.to_lower().contains(marker):
				hits += 1
			for formula in DERISIONE:
				if joined.to_lower().contains(formula):
					out.append("%s: prende in giro il giocatore («%s») — vietato da §2.4" % [
						itinerant_id, formula])

		var share := float(hits) / maxf(1.0, float(lines.size()))
		if share < MIN_TIC_SHARE:
			out.append("%s: il tic «%s» compare in %d battute su %d (%.0f%%, minimo %.0f%%)" % [
				itinerant_id, marker, hits, lines.size(), share * 100.0, MIN_TIC_SHARE * 100.0])

		out.append_array(_check_speciali(str(itinerant_id), lines))

		print("%-14s %-12s %-22s %2d battute · tic %d/%d" % [
			str(npc.get("nome", "?")), str(npc.get("registro", "")),
			str(npc.get("funzione", "")), lines.size(), hits, lines.size()])
	return out

## Le regole che valgono per un personaggio solo, e che sono la sua personalità.
func _check_speciali(itinerant_id: String, lines: Array) -> Array:
	var out: Array = []
	match itinerant_id:
		"itin-vera":
			# «Finisce ogni battuta con una domanda, comprese quelle in cui
			# rispondeva.» Se non è ogni battuta, non è un tic: è un'abitudine.
			for line_data in lines:
				var screens: Array = line_data
				var last := str(screens[screens.size() - 1]).strip_edges()
				if not last.ends_with("?"):
					out.append("itin-vera: una battuta non finisce con una domanda («%s»)" % last.substr(0, 40))
		"itin-cinabro":
			# Parla di sé in terza persona: il nome deve esserci, e almeno una
			# volta va sbagliato, altrimenti il tic è metà.
			var storpiature := 0
			for line_data in lines:
				var joined := " ".join(PackedStringArray(line_data as Array))
				if joined.contains("Cinabrio") or joined.contains("Cinaboro"):
					storpiature += 1
			if storpiature < 2:
				out.append("itin-cinabro: sbaglia il proprio nome %d volte: il tic non si nota" % storpiature)
		"itin-sesto":
			# È comico perché ci scherza per primo: la sua smemoratezza deve
			# comparire in battute che dice lui, non subirla.
			var scherzi := 0
			for line_data in lines:
				var joined := " ".join(PackedStringArray(line_data as Array)).to_lower()
				if joined.contains("dimentic") or joined.contains("piacere, sesto") or joined.contains("me lo ricordo"):
					scherzi += 1
			if scherzi < 3:
				out.append("itin-sesto: %d battute in cui scherza sul proprio dimenticare, minimo 3 — senza, è triste invece che buffo" % scherzi)
		"itin-orsolo":
			# Si converte lentamente e non lo ammette mai: il «mah» più piano
			# deve esistere come gruppo a parte.
			if ItinerantCatalog.lines_of("itin-orsolo", "prova_accettata").is_empty():
				out.append("itin-orsolo: nessuna battuta di resa: un attrito che non cede mai è un muro, non un personaggio")
	return out

## La rotazione, misurata su semi diversi invece che dichiarata.
func _check_rotazione() -> Array:
	var out: Array = []
	var count := ItinerantCatalog.ITINERANTI.size()
	for campaign_seed in [1, 7, 42, 1234, 99991]:
		var visti: Dictionary = {}
		var previous := ""
		for level in range(1, 25):
			var who := ItinerantCatalog.itinerant_for(campaign_seed, level)
			if who == previous:
				out.append("seme %d: %s compare ai mondi %d e %d di fila" % [
					campaign_seed, who, level - 1, level])
			previous = who
			visti[who] = int(visti.get(who, 0)) + 1
		if visti.size() != count:
			out.append("seme %d: in 24 mondi compaiono %d itineranti su %d" % [
				campaign_seed, visti.size(), count])
		var minimo := 99
		for who in visti.keys():
			minimo = mini(minimo, int(visti[who]))
		if minimo < 3:
			out.append("seme %d: qualcuno compare solo %d volte in 24 mondi" % [campaign_seed, minimo])
	print("\nrotazione: 5 semi × 24 mondi, tutti e sei presenti, mai due di fila")
	return out
