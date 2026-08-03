extends SceneTree

## Le regole di `ABITANTI_E_LUOGHI.md` §2.2 e §5.1 sono vincolanti, ed è questo
## audit a renderle tali.
##
## Perché servono davvero: quarantotto residenti scritti senza vincolo di
## mescolanza suonano tutti uguali dopo il quinto mondo — e un cast che suona
## uguale è peggio di un cast piccolo. Il registro non cambia *cosa* si insegna,
## cambia *come*, ed è l'unica cosa che rende memorabile un personaggio che ha
## dodici battute in tutto.
##
## Non misura la bellezza: quella la giudica chi gioca. Misura che il materiale
## per essere belli ci sia.

const MIN_LINES_RESIDENT := 12   # 3 per stadio + 3 di reazione + 3 di riempimento
const MIN_LINES_BISLACCO := 4
const MAX_LINES_BISLACCO := 6
const MIN_PER_POOL := 3
const MAX_SCREENS := 3           # mai più di tre schermate per battuta
const REQUIRED_POOLS := ["stadio0", "stadio1", "stadio2", "reazione", "riempimento"]
## I due gruppi del flusso di missione (A2). Sono **facoltativi**: dove mancano,
## l'evento resta giocabile e muto, ed è il fallback previsto. Ma dove ci sono
## valgono le stesse regole di tutti gli altri — schermate, tic, nessuna battuta
## ripetuta. Prima di questo audit non li guardava nessuno: duecento battute
## scritte e zero verificate.
const OPTIONAL_POOLS := {"richiesta": 3, "consolazione": 2}
## Il tic deve comparire in almeno una battuta su tre: è il trucco che rende
## memorabile un personaggio, ma se sta in ogni riga diventa un tormentone.
const MIN_TIC_SHARE := 0.34

## Ogni battuta già vista, con chi la dice: serve al controllo fra personaggi.
var _lines_everywhere: Dictionary = {}

func _init() -> void:
	var failures: Array = []
	var worlds: Dictionary = {}

	print("Catalogo abitanti — regole di mescolanza e forma dei dialoghi\n")

	for npc_id in NpcCatalog.RESIDENTS.keys():
		var npc := NpcCatalog.RESIDENTS[npc_id] as Dictionary
		var world := int(npc.get("world", 0))
		var entry: Dictionary = worlds.get(world, {"residents": [], "funny": false})
		entry["residents"] = (entry["residents"] as Array) + [str(npc_id)]
		worlds[world] = entry
		failures.append_array(_check_fields(str(npc_id), npc))
		failures.append_array(_check_pools(str(npc_id), npc))

	for npc_id in NpcCatalog.BISLACCHI.keys():
		var npc := NpcCatalog.BISLACCHI[npc_id] as Dictionary
		var world := int(npc.get("world", 0))
		var entry: Dictionary = worlds.get(world, {"residents": [], "funny": false})
		entry["funny"] = true
		worlds[world] = entry
		var lines: Array = npc.get("battute", [])
		if lines.size() < MIN_LINES_BISLACCO or lines.size() > MAX_LINES_BISLACCO:
			failures.append("%s: %d battute, attese %d-%d" % [
				npc_id, lines.size(), MIN_LINES_BISLACCO, MAX_LINES_BISLACCO])
		failures.append_array(_check_screens(str(npc_id), lines))
		failures.append_array(_check_tic(str(npc_id), npc, lines))

	# --- regole di mescolanza, per mondo ---------------------------------------
	var levels: Array = worlds.keys()
	levels.sort()
	for world in levels:
		var entry := worlds[world] as Dictionary
		var residents: Array = entry["residents"]
		var registers: Array = []
		for npc_id in residents:
			var npc := NpcCatalog.RESIDENTS[npc_id] as Dictionary
			var registro := str(npc.get("registro", ""))
			registers.append(registro)
			if not NpcCatalog.REGISTRI.has(registro):
				failures.append("%s: registro sconosciuto «%s»" % [npc_id, registro])
			if str(npc.get("registro", "")) in ["buffo", "divertente"]:
				entry["funny"] = true
		if residents.size() != 2:
			failures.append("mondo %d: %d residenti, attesi 2" % [world, residents.size()])
		if registers.size() == 2 and registers[0] == registers[1]:
			failures.append("mondo %d: i due residenti hanno lo stesso registro «%s»" % [
				world, str(registers[0])])
		if registers.count("solenne") == 2:
			failures.append("mondo %d: entrambi i residenti «solenne»" % world)
		if not bool(entry["funny"]):
			failures.append("mondo %d: nessun personaggio che fa ridere" % world)
		print("mondo %-3d %-28s registri: %s%s" % [
			world, ", ".join(PackedStringArray(residents)),
			", ".join(PackedStringArray(registers)),
			"  + bislacco" if bool(entry["funny"]) else ""])

	# Regola 3: su tre mondi consecutivi non si ripete la stessa coppia di
	# registri. Senza questa, il cast «vario» diventa comunque monotono a blocchi:
	# tre mondi di fila burbero+caloroso suonano identici anche se i nomi cambiano.
	var pair_of: Dictionary = {}
	for world in levels:
		var registers: Array = []
		for npc_id in (worlds[world] as Dictionary)["residents"]:
			registers.append(str((NpcCatalog.RESIDENTS[npc_id] as Dictionary).get("registro", "")))
		registers.sort()
		pair_of[world] = "+".join(PackedStringArray(registers))
	for world in levels:
		for other in [world - 1, world - 2]:
			if pair_of.has(other) and str(pair_of[other]) == str(pair_of[world]):
				failures.append("mondi %d e %d hanno la stessa coppia di registri (%s): serve distanza di almeno tre" % [
					other, world, str(pair_of[world])])

	failures.append_array(_check_conta())

	print("\nresidenti: %d · bislacchi: %d · mondi coperti: %d su 24" % [
		NpcCatalog.RESIDENTS.size(), NpcCatalog.BISLACCHI.size(), levels.size()])
	# Diagnostico, non cricchetto: dove il flusso di missione è muto il gioco
	# funziona lo stesso, e questo numero dice quanto manca.
	var ready := NpcCatalog.a2_ready()
	print("flusso di missione completo (richiesta + consolazione): %d residenti su %d" % [
		ready.size(), NpcCatalog.RESIDENTS.size()])

	if not failures.is_empty():
		printerr("CATALOGO ABITANTI NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Npc catalog audit OK — registri mescolati, battute sufficienti, tic presenti")
	quit(0)

func _check_fields(npc_id: String, npc: Dictionary) -> Array:
	var out: Array = []
	for field in ["nome", "ruolo", "registro", "tic", "convinzione", "bisogno"]:
		if str(npc.get(field, "")).strip_edges() == "":
			out.append("%s: campo «%s» vuoto" % [npc_id, field])
	var arco: Array = npc.get("arco", [])
	if arco.size() != 3:
		out.append("%s: arco di %d stadi, attesi 3" % [npc_id, arco.size()])
	for stage in arco:
		if str(stage).strip_edges() == "":
			out.append("%s: uno stadio dell'arco è vuoto" % npc_id)
	return out

func _check_pools(npc_id: String, npc: Dictionary) -> Array:
	var out: Array = []
	var pools := npc.get("battute", {}) as Dictionary
	var all_lines: Array = []
	for pool in REQUIRED_POOLS:
		if not pools.has(pool):
			out.append("%s: manca il gruppo di battute «%s»" % [npc_id, pool])
			continue
		var lines: Array = pools[pool]
		if lines.size() < MIN_PER_POOL:
			out.append("%s: «%s» ha %d battute, minimo %d" % [
				npc_id, pool, lines.size(), MIN_PER_POOL])
		all_lines.append_array(lines)
	if all_lines.size() < MIN_LINES_RESIDENT:
		out.append("%s: %d battute in tutto, minimo %d" % [
			npc_id, all_lines.size(), MIN_LINES_RESIDENT])

	# I gruppi del flusso di missione: o ci sono tutti e due, o nessuno. Un
	# personaggio che chiede aiuto e poi non ha niente da dire quando la sessione
	# va male è peggio di uno muto: ti manda e ti abbandona.
	var has_any := false
	for pool in OPTIONAL_POOLS.keys():
		if pools.has(pool):
			has_any = true
	if has_any:
		for pool in OPTIONAL_POOLS.keys():
			if not pools.has(pool):
				out.append("%s: ha un gruppo del flusso di missione e non l'altro (manca «%s»)" % [
					npc_id, pool])
				continue
			var lines: Array = pools[pool]
			var minimum := int(OPTIONAL_POOLS[pool])
			if lines.size() < minimum:
				out.append("%s: «%s» ha %d battute, minimo %d" % [
					npc_id, pool, lines.size(), minimum])
			all_lines.append_array(lines)

	out.append_array(_check_screens(npc_id, all_lines))
	out.append_array(_check_tic(npc_id, npc, all_lines))
	# Nessuna battuta identica a un'altra dello stesso personaggio — e nemmeno a
	# quella di un altro abitante. La seconda metà della regola serve da quando le
	# consolazioni sono quarantasei: «non è andata, riproviamo» è la frase che
	# viene in mente a tutti, e quarantasei personaggi che la dicono uguale sono
	# un personaggio solo con quarantasei nomi.
	var seen: Dictionary = {}
	for line_data in all_lines:
		var key := "|".join(PackedStringArray(line_data as Array))
		if seen.has(key):
			out.append("%s: battuta ripetuta due volte" % npc_id)
		seen[key] = true
		if _lines_everywhere.has(key):
			out.append("%s: dice la stessa battuta di %s" % [npc_id, str(_lines_everywhere[key])])
		else:
			_lines_everywhere[key] = npc_id
	return out

func _check_screens(npc_id: String, lines: Array) -> Array:
	var out: Array = []
	for line_data in lines:
		var screens: Array = line_data
		if screens.is_empty():
			out.append("%s: battuta senza schermate" % npc_id)
		elif screens.size() > MAX_SCREENS:
			out.append("%s: battuta di %d schermate, massimo %d" % [
				npc_id, screens.size(), MAX_SCREENS])
		for screen in screens:
			if str(screen).strip_edges() == "":
				out.append("%s: schermata vuota" % npc_id)
	return out

func _check_tic(npc_id: String, npc: Dictionary, lines: Array) -> Array:
	var marker := str(npc.get("ticMarker", ""))
	if marker == "":
		return ["%s: manca «ticMarker», il tic non è verificabile" % npc_id]
	if lines.is_empty():
		return []
	var hits := 0
	for line_data in lines:
		for screen in Array(line_data):
			if str(screen).to_lower().contains(marker.to_lower()):
				hits += 1
				break
	var share := float(hits) / float(lines.size())
	if share < MIN_TIC_SHARE:
		return ["%s: il tic «%s» compare in %d battute su %d (%.0f%%, minimo %.0f%%)" % [
			npc_id, marker, hits, lines.size(), share * 100.0, MIN_TIC_SHARE * 100.0]]
	return []

## La conta di nonna Ersilia deve essere davvero la tabellina del sette — è tutto
## il senso della scena — e deve contenere le tre sillabe del nome cancellato.
func _check_conta() -> Array:
	var out: Array = []
	var conta := NpcCatalog.CONTA_ERSILIA
	var multipli: Array = conta.get("multipli", [])
	for index in multipli.size():
		var expected := 7 * (index + 1)
		if int(multipli[index]) != expected:
			out.append("conta di Ersilia: il %d° numero è %d, atteso %d" % [
				index + 1, int(multipli[index]), expected])
	if multipli.size() != 10:
		out.append("conta di Ersilia: %d multipli, attesi 10" % multipli.size())
	var testo := " ".join(PackedStringArray(conta.get("versi", []))).to_lower()
	for syllable in Array(conta.get("sillabe", [])):
		if not testo.contains("— %s —" % str(syllable).to_lower()):
			out.append("conta di Ersilia: la sillaba «%s» non compare isolata nei versi" % syllable)
	for number in multipli:
		var word := _in_lettere(int(number))
		if word != "" and not testo.contains(word):
			out.append("conta di Ersilia: manca il numero %d («%s»)" % [int(number), word])
	return out

func _in_lettere(value: int) -> String:
	match value:
		7: return "sette"
		14: return "quattordici"
		21: return "ventuno"
		28: return "ventotto"
		35: return "trentacinque"
		42: return "quarantadue"
		49: return "quarantanove"
		56: return "cinquantasei"
		63: return "sessantatré"
		70: return "settanta"
	return ""
