extends SceneTree

## Le dodici voci di NORA e i due contratti dello spiegare, resi vincolanti.
##
## Tre cose si rompono in silenzio, qui:
##
## 1. **NORA che dà la risposta.** È la regola §6.1.1 ed è letteralmente la
##    tragedia del personaggio: ha perso undici sorelle dicendogli tutto. Ogni
##    Maestro deve avere battute di *rilancio* — cosa dire al posto della
##    risposta — perché una regola senza battute diventa silenzio imbarazzato, e
##    il silenzio imbarazzato lo riempie chi scrive con una soluzione.
## 2. **Le dodici voci che suonano uguali.** Se le inflessioni non si distinguono
##    non sono dodici sfumature: è una sola voce con dodici etichette, e il
##    progresso narrativo non si sente.
## 3. **L'errore sempre nello stesso passo.** Regola guadagnata il 29 luglio: un
##    errore fisso al terzo passaggio allena a contare fino a tre.

const POOL_RICHIESTI := ["apertura", "rilancio", "chiusura"]
const MIN_APERTURA := 3
const MIN_RILANCIO := 3
const MIN_CHIUSURA := 2

## Formule con cui una battuta smette di essere un rilancio e diventa una
## risposta. «La risposta è», «basta fare», «il risultato è»: sono le scorciatoie
## che vengono in mente quando si scrive di fretta.
const RISPOSTE = [
	"la risposta è", "la risposta e", "il risultato è", "il risultato e",
	"basta fare", "devi solo fare", "si fa così:", "si fa cosi:",
	"la soluzione è", "la soluzione e",
]
## «viene» regala la risposta solo quando è seguito da un numero — «viene 12».
## Da solo prende «il resto viene da sé» e «sistemarla viene dopo», che sono
## rilanci perfettamente legittimi: una lista di sottostringhe qui non basta.
const RISPOSTA_NUMERICA := "\\bviene\\s+-?\\d"

func _init() -> void:
	var failures: Array = []
	print("I Dodici Maestri — dodici voci, e nessuna che dà la risposta\n")

	failures.append_array(_check_maestri())
	failures.append_array(_check_rispiegamelo())
	failures.append_array(_check_diagnosi())
	failures.append_array(_check_rotazione())

	if not failures.is_empty():
		printerr("VOCI E CONTRATTI NON VALIDI — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nMaestri audit OK — dodici voci distinte, nessuna risposta regalata, errore che ruota")
	quit(0)

func _check_maestri() -> Array:
	var out: Array = []
	if MaestriCatalog.MAESTRI.size() != 12:
		out.append("i Maestri sono %d, il documento ne prevede 12" % MaestriCatalog.MAESTRI.size())

	var materie_viste: Dictionary = {}
	var inflessioni: Dictionary = {}
	var silenti: Array = []
	var ids: Array = MaestriCatalog.MAESTRI.keys()
	ids.sort()
	for maestro_id in ids:
		var maestro := MaestriCatalog.MAESTRI[maestro_id] as Dictionary
		var materia := str(maestro.get("materia", ""))
		if not MaestriCatalog.MATERIE.has(materia):
			out.append("%s: materia «%s» fuori dalle dodici" % [maestro_id, materia])
		if materie_viste.has(materia):
			out.append("due Maestri per la materia «%s»: le voci non sarebbero dodici" % materia)
		materie_viste[materia] = true

		var inflessione := str(maestro.get("inflessione", ""))
		if inflessione.strip_edges() == "":
			out.append("%s: nessuna inflessione dichiarata" % maestro_id)
		if inflessioni.has(inflessione):
			out.append("%s ha la stessa inflessione di %s" % [maestro_id, str(inflessioni[inflessione])])
		inflessioni[inflessione] = maestro_id

		if bool(maestro.get("silente", false)):
			silenti.append(str(maestro_id))
			if str(maestro.get("silenzio", "")).strip_edges() == "":
				out.append("%s è silente e non dichiara cosa succede al posto della voce" % maestro_id)

		# I tre gruppi, con i minimi. Il rilancio è quello che conta.
		var minimi := {"apertura": MIN_APERTURA, "rilancio": MIN_RILANCIO, "chiusura": MIN_CHIUSURA}
		for pool in POOL_RICHIESTI:
			var lines: Array = maestro.get(pool, [])
			if lines.size() < int(minimi[pool]):
				out.append("%s: «%s» ha %d battute, minimo %d" % [
					maestro_id, pool, lines.size(), int(minimi[pool])])
			for line in lines:
				if str(line).strip_edges() == "":
					out.append("%s: battuta vuota in «%s»" % [maestro_id, pool])

		# Nessun rilancio può contenere la risposta: è il punto di tutto.
		var numerica := RegEx.create_from_string(RISPOSTA_NUMERICA)
		for line in maestro.get("rilancio", []):
			var lower := str(line).to_lower()
			for formula in RISPOSTE:
				if lower.contains(formula):
					out.append("%s: il rilancio «%s…» dà la risposta invece di rilanciare" % [
						maestro_id, str(line).substr(0, 40)])
			if numerica.search(lower) != null:
				out.append("%s: il rilancio «%s…» dice il risultato" % [
					maestro_id, str(line).substr(0, 40)])

		print("%-10s %-12s %s" % [
			str(maestro.get("nome", "?")), materia,
			"(silente)" if bool(maestro.get("silente", false)) else inflessione.substr(0, 46)])

	if silenti.size() != 1:
		out.append("i Maestri silenti sono %d: il documento ne prevede uno solo, Scala" % silenti.size())
	elif str(silenti[0]) != "scala":
		out.append("il Maestro silente è «%s», non Scala" % str(silenti[0]))

	# La logica non deve rispondere finché il nome non è restituito.
	var tutti_apparati: Array = []
	for maestro_id in ids:
		tutti_apparati.append(str((MaestriCatalog.MAESTRI[maestro_id] as Dictionary).get("apparato", "")))
	var senza_nome := MaestriCatalog.voices_for(tutti_apparati, false)
	var con_nome := MaestriCatalog.voices_for(tutti_apparati, true)
	if senza_nome.has("scala"):
		out.append("la voce della logica risponde prima che il nome sia restituito")
	if not con_nome.has("scala"):
		out.append("la voce della logica non torna nemmeno dopo la restituzione del nome")
	print("\nvoci con tutti gli apparati riparati: %d prima del nome, %d dopo" % [
		senza_nome.size(), con_nome.size()])

	# Gli apparati condivisi: riparare non basta a decidere quale voce parla.
	# Senza il cancello sulle materie, la voce della geografia si accenderebbe al
	# mondo 5 insieme a quella della fisica.
	var shared := MaestriCatalog.shared_apparatuses()
	for apparatus in shared.keys():
		var abitanti: Array = shared[apparatus]
		var materie: Array = []
		for maestro_id in abitanti:
			materie.append(str((MaestriCatalog.MAESTRI[maestro_id] as Dictionary).get("materia", "")))
		# Con una sola materia incontrata deve rispondere una voce sola.
		var solo_una := MaestriCatalog.voices_for([str(apparatus)], true, [str(materie[0])])
		if solo_una.size() != 1:
			out.append("apparato «%s»: con una materia incontrata rispondono %d voci invece di 1" % [
				apparatus, solo_una.size()])
		print("apparato condiviso: %-16s %s" % [str(apparatus), ", ".join(PackedStringArray(materie))])
	return out

func _check_rispiegamelo() -> Array:
	var out: Array = []
	var opzioni := TeachingCatalog.rispiegamelo_options()
	if opzioni.size() != 3:
		out.append("«rispiegamelo» ha %d opzioni, il documento ne prevede 3" % opzioni.size())
	var giuste := 0
	for entry in opzioni:
		var option := entry as Dictionary
		if bool(option.get("giusta", false)):
			giuste += 1
		if str(option.get("fonte", "")).strip_edges() == "":
			out.append("opzione «%s»: non dichiara da quale campo si compone" % str(option.get("id", "?")))
	if giuste != 1:
		out.append("«rispiegamelo» ha %d opzioni giuste: dev'essere esattamente una" % giuste)

	# La ricompensa sociale: se dà energia o gate, Vera diventa una miniera.
	var premio := (TeachingCatalog.RISPIEGAMELO["ricompensa"]) as Dictionary
	if int(premio.get("energia", 0)) != 0:
		out.append("«rispiegamelo» dà energia: diventerebbe una risorsa da farmare")
	if bool(premio.get("gate", true)):
		out.append("«rispiegamelo» fa avanzare il gate: diventerebbe obbligatorio")
	var frequenza := (TeachingCatalog.RISPIEGAMELO["frequenza"]) as Dictionary
	if int(frequenza.get("per_sessione", 99)) > 1:
		out.append("«rispiegamelo» può ripetersi più volte per sessione: diventa un'interruzione")
	print("rispiegamelo: 3 opzioni, 1 giusta, ricompensa sociale, %d volta per sessione" % [
		int(frequenza.get("per_sessione", 0))])
	return out

func _check_diagnosi() -> Array:
	var out: Array = []
	if TeachingCatalog.DIAGNOSI.size() != 4:
		out.append("la Diagnosi ha %d opzioni, il documento ne prevede 4" % TeachingCatalog.DIAGNOSI.size())
	var nascoste := 0
	for entry in TeachingCatalog.DIAGNOSI:
		var option := entry as Dictionary
		var option_id := str(option.get("id", "?"))
		if bool(option.get("punita", true)):
			out.append("l'opzione «%s» è punita: la conseguenza è sulla sorella, mai sul giocatore" % option_id)
		for field in ["subito", "dopo"]:
			if str(option.get(field, "")).strip_edges() == "":
				out.append("l'opzione «%s» non dichiara l'effetto «%s»" % [option_id, field])
		if not bool(option.get("sempre_disponibile", true)):
			nascoste += 1
	# «Dille la risposta» deve restare sempre lì: bloccarla sarebbe una lezione
	# morale, lasciarla lì la rende una scoperta.
	var risposta := TeachingCatalog.diagnosi_option("dille-la-risposta")
	if risposta.is_empty():
		out.append("manca l'opzione «dille la risposta»: senza, il gioco fa la morale invece di mostrare")
	elif not bool(risposta.get("sempre_disponibile", false)):
		out.append("«dille la risposta» non è sempre disponibile: diventerebbe una punizione")
	if nascoste != 1:
		out.append("le opzioni nascoste sono %d: «chiedile perché» dev'essere l'unica" % nascoste)
	print("diagnosi: 4 opzioni, nessuna punita, 1 nascosta")
	return out

## La rotazione della posizione dell'errore, misurata invece che dichiarata.
func _check_rotazione() -> Array:
	var out: Array = []
	var topics := [
		"matematica:tabelline", "italiano:analisi-logica", "coding:cicli",
		"inglese:present-simple", "fisica:leve", "musica:intervalli",
		"latino:declinazioni", "elettronica:serie-parallelo", "geografia:coordinate",
		"scienze:metodo", "storia:fonti", "logica:sillogismi",
	]
	for steps in [3, 4]:
		var counts: Array = []
		counts.resize(steps)
		counts.fill(0)
		var total := 0
		for topic in topics:
			for attempt in range(24):
				var index := TeachingCatalog.error_step(str(topic), attempt, steps)
				if index < 0 or index >= steps:
					out.append("posizione %d fuori dai %d passi" % [index, steps])
					continue
				counts[index] += 1
				total += 1
		var share := ""
		for index in range(steps):
			var pct := 100.0 * float(counts[index]) / maxf(1.0, float(total))
			share += "p%d %.0f%%  " % [index + 1, pct]
			if counts[index] == 0:
				out.append("con %d passi la posizione %d non esce mai" % [steps, index + 1])
			if pct > 40.0:
				out.append("con %d passi la posizione %d esce nel %.0f%% dei casi: si impara a cliccarla" % [
					steps, index + 1, pct])
		print("errore su %d passi: %s" % [steps, share.strip_edges()])

	# Due tentativi consecutivi sullo stesso topic non devono ripetere la posizione.
	for topic in topics:
		for steps in [3, 4]:
			for attempt in range(12):
				if TeachingCatalog.error_step(str(topic), attempt, steps) == TeachingCatalog.error_step(str(topic), attempt + 1, steps):
					out.append("%s: la posizione si ripete fra il tentativo %d e il %d" % [
						str(topic), attempt, attempt + 1])
	return out
