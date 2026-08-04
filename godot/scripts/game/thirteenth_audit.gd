extends SceneTree

## I guard-rail narrativi di `docs/TRAMA_E_MISTERO.md` §10, resi vincolanti sul
## personaggio che rischia di violarli per primo.
##
## Un antagonista si scrive male in due modi, e sono tutti e due facili: gli si
## mette in bocca una minaccia perché «serve tensione», e gli si dà un'azione che
## toglie qualcosa al giocatore perché «altrimenti non fa paura». Il documento
## vieta entrambe le cose (§5.2, §10.3) e finora niente lo impediva.
##
## Non misura se fa paura: quello lo dirà chi gioca. Misura che, mentre la fa,
## non stia facendo del male a nessuno.

## Formule di minaccia. Sono scritte come le scriverebbe qualcuno in buona fede
## che vuole «alzare la posta»: è proprio quello il caso da fermare.
const MINACCE := [
	"ti distrugg", "ti farò", "ti faro", "pagherai", "ti pentirai",
	"ti fermerò", "ti fermero", "guai a te", "non uscirai", "ti prenderò",
	"ti prendero", "sarà peggio per te", "sara peggio per te", "ultimo avvertimento",
	"ti costringerò", "ti costringero", "non ti lascerò", "non ti lascero",
]

## §10.1: non muore nessuno, mai, nemmeno nel passato e nemmeno per allusione.
const MORTE := [
	"è morto", "e morto", "è morta", "e morta", "sono morti", "morire",
	"ucciso", "uccisa", "uccidere", "defunt", "perduto per sempre", "cadavere",
	"sepolt", "tomba di",
]

const MODI_AMMESSI := ["chiede", "avverte", "supplica"]
const MAX_SCHERMATE := 3

func _init() -> void:
	var failures: Array = []
	print("Il Tredicesimo — chiede, avverte, supplica. Mai minaccia.\n")

	failures.append_array(_check_azioni())
	failures.append_array(_check_presagi())
	failures.append_array(_check_battute())
	failures.append_array(_check_nome())
	failures.append_array(_check_scelta())

	if not failures.is_empty():
		printerr("IL TREDICESIMO NON RISPETTA I GUARD-RAIL — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nThirteenth audit OK — nessuna minaccia, nessuna perdita, nome verificato")
	quit(0)

## Le cinque azioni: reversibili, con un costo dichiarato e dentro la lista
## chiusa, e nessuna prima del mondo in cui il personaggio esiste.
func _check_azioni() -> Array:
	var out: Array = []
	if ThirteenthCatalog.AZIONI.size() != 5:
		out.append("le azioni sono %d, il documento ne prevede 5" % ThirteenthCatalog.AZIONI.size())
	var ids: Array = ThirteenthCatalog.AZIONI.keys()
	ids.sort()
	for action_id in ids:
		var action := ThirteenthCatalog.AZIONI[action_id] as Dictionary
		var costo := str(action.get("costo", ""))
		var world := int(action.get("dal_mondo", 0))
		if not ThirteenthCatalog.COSTI_AMMESSI.has(costo):
			out.append("azione «%s»: costo «%s» fuori dalla lista ammessa" % [action_id, costo])
		if not bool(action.get("reversibile", false)):
			out.append("azione «%s»: non reversibile — il documento non ne ammette" % action_id)
		if str(action.get("ripristino", "")).strip_edges() == "":
			out.append("azione «%s»: nessun ripristino dichiarato" % action_id)
		if world < ThirteenthCatalog.PRIMO_MONDO_AZIONE:
			out.append("azione «%s»: comincia al mondo %d, prima del %d" % [
				action_id, world, ThirteenthCatalog.PRIMO_MONDO_AZIONE])
		if action_id == "parla" and world < ThirteenthCatalog.PRIMO_MONDO_VOCE:
			out.append("la voce comincia al mondo %d, prima del %d" % [
				world, ThirteenthCatalog.PRIMO_MONDO_VOCE])
		print("%-13s dal mondo %d   costo: %-9s %s" % [
			action_id, world, costo,
			"reversibile" if bool(action.get("reversibile", false)) else "IRREVERSIBILE"])
	return out

## I presagi: pochi, silenziosi, e solo con le azioni che non costano niente.
func _check_presagi() -> Array:
	var out: Array = []
	var presagi: Array = ThirteenthCatalog.PRESAGI
	if presagi.size() > 2:
		out.append("i presagi sono %d: più di due e l'antagonista non è più un presagio, è già in scena" % presagi.size())
	for entry in presagi:
		var presagio := entry as Dictionary
		var world := int(presagio.get("world", 0))
		var azione := str(presagio.get("azione", ""))
		if not ThirteenthCatalog.AZIONI.has(azione):
			out.append("presagio al mondo %d: azione «%s» inesistente" % [world, azione])
			continue
		if world >= ThirteenthCatalog.PRIMO_MONDO_AZIONE:
			out.append("presagio al mondo %d: non è un presagio, è già dentro l'atto III" % world)
		if world < 9:
			out.append("presagio al mondo %d: troppo presto, il primo atto deve restare senza nessuno dall'altra parte" % world)
		# Solo azioni a costo nullo o estetico: un presagio che toglie qualcosa
		# prima che il giocatore sappia chi gliela toglie è una punizione anonima.
		var costo := str((ThirteenthCatalog.AZIONI[azione] as Dictionary).get("costo", ""))
		if not costo in ["nessuno", "estetico"]:
			out.append("presagio al mondo %d: l'azione «%s» costa «%s» — troppo, per qualcuno che non ha ancora un nome" % [
				world, azione, costo])
		if bool(presagio.get("commentato", true)):
			out.append("presagio al mondo %d: se qualcuno lo commenta diventa trama, e al mondo 17 NORA non può più stupirsi" % world)
		if str(presagio.get("dove", "")).strip_edges() == "":
			out.append("presagio al mondo %d: non dice dove accade" % world)
		# La voce resta all'atto III, sempre.
		if azione == "parla":
			out.append("presagio al mondo %d: la voce non si anticipa" % world)
		if ThirteenthCatalog.action_allowed_at(azione, world) == false:
			out.append("presagio al mondo %d: la regola non lo ammette" % world)
	var mondi: Array = presagi.map(func(p): return str(int((p as Dictionary)["world"])))
	print("presagi: %d (mondi %s) — nessuno commentato" % [
		presagi.size(), ", ".join(PackedStringArray(mondi))])
	# E la regola non deve aprire le porte a tutto il resto.
	if ThirteenthCatalog.action_allowed_at("chiude", 13):
		out.append("la regola dei presagi ammette «chiude» al mondo 13: era un'eccezione, non un cancello aperto")
	return out

func _check_battute() -> Array:
	var out: Array = []
	var modi_visti: Dictionary = {}
	var worlds: Array = ThirteenthCatalog.BATTUTE.keys()
	worlds.sort()
	var total := 0
	for world in worlds:
		if int(world) < ThirteenthCatalog.PRIMO_MONDO_VOCE:
			out.append("mondo %d: parla prima del %d" % [
				int(world), ThirteenthCatalog.PRIMO_MONDO_VOCE])
		for entry in ThirteenthCatalog.BATTUTE[world]:
			var line := entry as Dictionary
			var modo := str(line.get("modo", ""))
			var screens: Array = line.get("dice", [])
			total += 1
			modi_visti[modo] = true
			if not MODI_AMMESSI.has(modo):
				out.append("mondo %d: modo «%s» non ammesso" % [int(world), modo])
			if screens.is_empty() or screens.size() > MAX_SCHERMATE:
				out.append("mondo %d: battuta di %d schermate, ammesse 1-%d" % [
					int(world), screens.size(), MAX_SCHERMATE])
			out.append_array(_check_testo("mondo %d" % int(world), screens))
	for modo in MODI_AMMESSI:
		if not modi_visti.has(modo):
			out.append("nessuna battuta in modo «%s»: l'arco ne perde un terzo" % modo)
	print("\nbattute: %d su %d mondi (dal %d al 24) · modi usati: %s" % [
		total, worlds.size(), int(worlds[0]) if not worlds.is_empty() else 0,
		", ".join(PackedStringArray(modi_visti.keys()))])
	return out

## Il controllo che conta: né minacce né morte, in nessun testo del file.
func _check_testo(where: String, screens: Array) -> Array:
	var out: Array = []
	for screen in screens:
		var text := str(screen)
		if text.strip_edges() == "":
			out.append("%s: schermata vuota" % where)
		var lower := text.to_lower()
		for threat in MINACCE:
			if lower.contains(threat):
				out.append("%s: minaccia il giocatore («%s») — vietato da §10.3" % [where, threat])
		for death in MORTE:
			if lower.contains(death):
				out.append("%s: formula di morte («%s») — vietata da §10.1" % [where, death])
	return out

## Il nome deve uscire dalla conta del mondo 1, e la conta deve contenerlo
## davvero. Senza questo controllo il finale poggia su una coincidenza scritta in
## due file che nessuno confronta.
func _check_nome() -> Array:
	var out: Array = []
	var sillabe: Array = ThirteenthCatalog.SILLABE
	if sillabe.size() != 3:
		out.append("le sillabe sono %d, la conta ne isola 3" % sillabe.size())
		return out
	var nome := ThirteenthCatalog.NOME_VERO.to_lower()
	if nome != str(sillabe[0]) + str(sillabe[1]):
		out.append("«%s» + «%s» non fa «%s»" % [sillabe[0], sillabe[1], nome])
	if not "resta".begins_with(str(sillabe[2])):
		out.append("«%s» non è l'inizio di «resta»: la seconda metà dell'indovinello non torna" % sillabe[2])

	# E le tre sillabe devono stare davvero nella conta di nonna Ersilia.
	var versi := " ".join(PackedStringArray(
		(NpcCatalog.CONTA_ERSILIA as Dictionary).get("versi", []))).to_lower()
	for sillaba in sillabe:
		if not versi.contains("— %s —" % str(sillaba)):
			out.append("la sillaba «%s» non è isolata nella conta del mondo 1" % str(sillaba))
	if str((NpcCatalog.CONTA_ERSILIA as Dictionary).get("seedOf", "")) != "il-tredicesimo":
		out.append("la conta non è dichiarata seme del Tredicesimo")

	# La restituzione deve contenere il nome e la frase del Maestro.
	var scena: Array = (ThirteenthCatalog.RESTITUZIONE as Dictionary).get("scena", [])
	var joined := ""
	for entry in scena:
		joined += " ".join(PackedStringArray((entry as Dictionary).get("dice", []))) + " "
		out.append_array(_check_testo("restituzione", (entry as Dictionary).get("dice", [])))
	if not joined.contains(ThirteenthCatalog.NOME_VERO):
		out.append("la scena della restituzione non pronuncia il nome")
	if not joined.contains(ThirteenthCatalog.FRASE_DEL_MAESTRO):
		out.append("la scena della restituzione non contiene la frase del Maestro")
	print("\nnome: «%s» da «%s»+«%s», e «%s» apre «resta» — conta del mondo 1 verificata" % [
		ThirteenthCatalog.NOME_VERO, sillabe[0], sillabe[1], sillabe[2]])
	return out

## Due uscite, nessuna punita. È la differenza fra una scelta e un esame.
func _check_scelta() -> Array:
	var out: Array = []
	var opzioni: Array = (ThirteenthCatalog.SCELTA as Dictionary).get("opzioni", [])
	if opzioni.size() != 2:
		out.append("le uscite sono %d, il documento ne prevede 2" % opzioni.size())
	for entry in opzioni:
		var option := entry as Dictionary
		if bool(option.get("punita", true)):
			out.append("l'uscita «%s» è punita: il documento non lo ammette" % str(option.get("id", "?")))
		if str(option.get("conseguenza", "")).strip_edges() == "":
			out.append("l'uscita «%s» non dichiara una conseguenza" % str(option.get("id", "?")))
		out.append_array(_check_testo("scelta/%s" % str(option.get("id", "?")), option.get("dice", [])))
	print("uscite: %d, nessuna punita" % opzioni.size())
	return out
