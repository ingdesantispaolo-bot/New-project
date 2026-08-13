extends SceneTree

## Le scelte di posizione e l'arco di Vera: i due sistemi che danno al giocatore
## una voce e a un'amicizia un attrito.
##
## Sono nuovi, e tutti e due possono rompersi nello stesso modo — scrivendo, con
## le migliori intenzioni, una versione «giusta» e una «sbagliata». Una scelta
## con una risposta giusta non è una scelta: è un esame travestito, e in un gioco
## che a un bambino chiede di sbagliare tutto il giorno senza conseguenze
## sarebbe l'unico posto in cui il modo di *sentirsi* può essere sbagliato.
##
## Perciò i controlli sono quasi tutti negativi: nessuna opzione punita, nessuna
## opzione che prometta un vantaggio, nessuna che manchi dell'eco — perché
## l'unica cosa che una scelta deve garantire è che qualcuno se ne ricordi.

const MAX_CARATTERI := 300
const MIN_OPZIONI := 2

## Formule che trasformerebbero una posizione in una ricompensa. Se un'opzione
## promette qualcosa, le altre diventano quella che ti fa perdere qualcosa.
const PREMI := [
	"energia", "frammenti", "ricompensa", "punti", "bonus", "sblocc", "in regalo",
]

## §10.6: nessuno è mai deluso da Eli. Vale doppio in una scelta, dove il
## giocatore ha appena messo la faccia.
const RIMPROVERI := [
	"sei stata cattiva", "hai sbagliato a", "non dovevi", "ti sei comportata male",
	"mi hai delus", "che delusione", "ti pentirai",
]

func _init() -> void:
	var failures: Array = []
	print("Le scelte di posizione — cinque momenti, nessuna risposta giusta\n")

	failures.append_array(_check_scelte())
	failures.append_array(_check_runtime_contract())
	failures.append_array(_check_vera())

	if not failures.is_empty():
		printerr("SCELTE NON VALIDE — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nStance audit OK — nessuna opzione punita, ognuna ha la sua eco, Vera si ricuce")
	quit(0)

func _check_scelte() -> Array:
	var out: Array = []
	var ids: Array = StanceChoices.SCELTE.keys()
	ids.sort()
	if ids.size() < 4:
		out.append("le scelte sono %d: sotto le quattro non si sente di aver deciso niente in ventiquattro mondi" % ids.size())

	for choice_id in ids:
		var scelta := StanceChoices.SCELTE[choice_id] as Dictionary
		for field in ["dove", "dove_eco", "domanda"]:
			if str(scelta.get(field, "")).strip_edges() == "":
				out.append("%s: campo «%s» mancante — chi mette in scena dovrebbe indovinare dove va" % [
					choice_id, field])

		var opzioni: Array = scelta.get("opzioni", [])
		if opzioni.size() < MIN_OPZIONI:
			out.append("%s: %d opzioni, minimo %d" % [choice_id, opzioni.size(), MIN_OPZIONI])
		if opzioni.size() > StanceChoices.MAX_OPZIONI:
			out.append("%s: %d opzioni, oltre %d si legge come un quiz" % [
				choice_id, opzioni.size(), StanceChoices.MAX_OPZIONI])

		var visti: Dictionary = {}
		for raw in opzioni:
			var option: Dictionary = raw
			var option_id := str(option.get("id", ""))
			if option_id == "":
				out.append("%s: un'opzione senza id" % choice_id)
			if visti.has(option_id):
				out.append("%s: due opzioni con id «%s»" % [choice_id, option_id])
			visti[option_id] = true

			# Il cuore dell'audit: nessuna è punita, e nessuna è premiata.
			if bool(option.get("punita", true)):
				out.append("%s/%s è punita: esisterebbe una risposta sbagliata" % [choice_id, option_id])

			var dice := str(option.get("dice", "")).strip_edges()
			var eco := str(option.get("eco", "")).strip_edges()
			if dice == "":
				out.append("%s/%s: Eli non dice niente" % [choice_id, option_id])
			if eco == "":
				out.append("%s/%s: nessuna eco — la scelta non tornerebbe mai, e allora non è stata una scelta" % [
					choice_id, option_id])
			for raw_testo in [dice, eco]:
				var testo := str(raw_testo)
				if testo.length() > MAX_CARATTERI:
					out.append("%s/%s: %d caratteri, massimo %d" % [
						choice_id, option_id, testo.length(), MAX_CARATTERI])
				var lower := testo.to_lower()
				for premio in PREMI:
					if lower.contains(premio):
						out.append("%s/%s promette «%s»: una posizione non si paga" % [
							choice_id, option_id, premio])
				for rimprovero in RIMPROVERI:
					if lower.contains(rimprovero):
						out.append("%s/%s rimprovera Eli («%s») — vietato da §10.6" % [
							choice_id, option_id, rimprovero])

			# L'eco deve essere di qualcuno: senza voce è una didascalia.
			if eco != "" and not eco.contains(":"):
				out.append("%s/%s: l'eco non dice chi la pronuncia" % [choice_id, option_id])

		print("%-22s %d opzioni · %s" % [choice_id, opzioni.size(), str(scelta.get("dove", ""))])
	return out

func _check_runtime_contract() -> Array:
	var out: Array = []
	var fake := {"narrative": {}}
	var choice_id := "squadra-quaderno"
	if not StanceChoices.dovuta(fake, choice_id):
		out.append("una scelta mai incontrata non risulta dovuta")
	StanceChoices.registra_risposta(fake, choice_id, "ci-scrivo")
	if StanceChoices.dovuta(fake, choice_id):
		out.append("la scelta ricompare dopo essere stata presa")
	if StanceChoices.risposta(fake, choice_id) != "ci-scrivo":
		out.append("la posizione scelta non resta nel save")
	var echo_entry := StanceChoices.eco_entry(fake, choice_id)
	if str(echo_entry.get("chi", "")) != "eli" \
			or str(echo_entry.get("stance_echo", "")) != choice_id:
		out.append("l'eco non entra nella regia del finale con voce e marcatore")
	StanceChoices.segna_eco_vista(fake, choice_id)
	if not StanceChoices.eco_pendente(fake, choice_id).is_empty():
		out.append("l'eco torna più di una volta")
	StanceChoices.registra_salto(fake, "meridiana-riga")
	if StanceChoices.dovuta(fake, "meridiana-riga") \
			or not StanceChoices.eco_pendente(fake, "meridiana-riga").is_empty():
		out.append("saltare non chiude il momento oppure inventa un'eco")
	return out

## L'arco di Vera. Le due cose che lo rendono un'amicizia invece di uno stato:
## l'incrinatura si **guadagna** giocando, e la riconciliazione non dipende da
## come hai risposto.
func _check_vera() -> Array:
	var out: Array = []

	if not StanceChoices.SCELTE.has(VeraArc.SCELTA_ID):
		out.append("l'arco di Vera punta alla scelta «%s», che non esiste" % VeraArc.SCELTA_ID)

	if VeraArc.SOGLIA_INCRINATURA < 3:
		out.append("l'incrinatura scatta a %d spiegazioni: troppo presto, il rapporto non c'è ancora" % (
			VeraArc.SOGLIA_INCRINATURA))

	# Ogni stadio deve avere un pool vero nel catalogo, altrimenti Vera ammutolisce.
	for stadio in [VeraArc.STADIO_COMPAGNA, VeraArc.STADIO_INCRINATO, VeraArc.STADIO_RICUCITO]:
		var pool := VeraArc.pool_per_stadio(stadio)
		if ItinerantCatalog.lines_of("itin-vera", pool).is_empty():
			out.append("stadio %d: il pool «%s» di Vera è vuoto" % [stadio, pool])
	for pool in [VeraArc.POOL_INCRINATURA, VeraArc.POOL_DOPO_LA_SCELTA]:
		if ItinerantCatalog.lines_of("itin-vera", pool).is_empty():
			out.append("il pool «%s» di Vera è vuoto" % pool)

	# La riconciliazione è il presupposto, non il premio: esiste una battuta di
	# ritorno e non dipende da quale opzione è stata scelta.
	if ItinerantCatalog.lines_of("itin-vera", VeraArc.POOL_DOPO_LA_SCELTA).size() != 1:
		out.append("«%s» deve avere una battuta sola: Vera torna allo stesso modo qualunque cosa le sia stato risposto" % (
			VeraArc.POOL_DOPO_LA_SCELTA))

	# Nel pool in cui insegna deve **non** dare la risposta: è tutto il punto.
	var insegna := ItinerantCatalog.lines_of("itin-vera", VeraArc.POOL_INSEGNA)
	var trattiene := 0
	for line_data in insegna:
		var joined := " ".join(PackedStringArray(line_data as Array)).to_lower()
		if joined.contains("non ti dico") or joined.contains("solo l'inizio") or joined.contains("il resto"):
			trattiene += 1
	if trattiene < 2:
		out.append("Vera insegna dando tutto in %d battute su %d: avrebbe imparato la cosa sbagliata" % [
			insegna.size() - trattiene, insegna.size()])

	# Lo stato si legge da un conteggio che esiste già: se cambiasse nome, l'arco
	# non partirebbe mai e nessuno se ne accorgerebbe.
	var finto := {"narrative": {"veraExplainedOn": {"a": "x", "b": "x", "c": "x", "d": "x"}}}
	if VeraArc.spiegazioni_ricevute(finto) != 4:
		out.append("il conteggio delle spiegazioni non legge più `narrative.veraExplainedOn`")
	if not VeraArc.incrinatura_dovuta(finto):
		out.append("con %d spiegazioni l'incrinatura non scatta" % VeraArc.SOGLIA_INCRINATURA)
	VeraArc.registra_risposta(finto, "spiegami-tu")
	if VeraArc.stadio(finto) != VeraArc.STADIO_INCRINATO:
		out.append("dopo la risposta l'arco non passa allo stadio incrinato")
	if VeraArc.incrinatura_dovuta(finto):
		out.append("l'incrinatura si ripeterebbe: una volta sola, o è un rimprovero a ripetizione")
	if VeraArc.eco(finto) == "":
		out.append("dopo la risposta non c'è eco da far sentire")
	VeraArc.segna_eco_vista(finto)
	if VeraArc.eco(finto) != "":
		out.append("l'eco si sente due volte: sarebbe un promemoria, non un ricordo")
	VeraArc.registra_ricucitura(finto)
	if VeraArc.stadio(finto) != VeraArc.STADIO_RICUCITO:
		out.append("la ricucitura non porta allo stadio finale")

	# E chi non ha mai giocato con Vera non deve vedere niente.
	if VeraArc.incrinatura_dovuta({"narrative": {}}):
		out.append("l'incrinatura scatta a chi non ha mai spiegato niente a Vera")

	print("\nVera: incrinatura a %d spiegazioni, riconciliazione incondizionata, %d battute in cui insegna" % [
		VeraArc.SOGLIA_INCRINATURA, insegna.size()])
	return out
