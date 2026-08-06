extends SceneTree

## **La voce di NORA.** (6 agosto 2026)
##
## Nasce da un'analisi del cast che ha trovato la voce distribuita al contrario:
## NORA parla dopo ogni prova — venti o venticinque volte per mondo — e aveva
## **dodici battute in tutto**, mentre un Bislacco di sfondo, incontrato una
## volta sola in tutta la partita, ne ha quattro. Chi parlava di più aveva il
## repertorio più piccolo.
##
## Le tre proprietà tenute qui, in ordine di importanza:
##
##   1. **nessun pozzo sotto il minimo.** È il cricchetto: si può salire, mai
##      scendere. Senza, la prossima riscrittura può tornare a dodici battute
##      senza che nessuno se ne accorga;
##   2. **gli atti non si sovrappongono.** Se una frase comparisse in due atti,
##      la voce smetterebbe di raccontare a che punto è l'indagine — che è
##      l'intero motivo per cui gli atti esistono;
##   3. **nessun ricordo nell'atto primo.** I ricordi alludono a rivelazioni che
##      lì non sono ancora avvenute: sarebbe il gioco che si anticipa da solo.

func _init() -> void:
	_prova_carattere()
	_prova_repertorio()
	_prova_atti_distinti()
	_prova_ricordi()
	_prova_estrazione()
	print("NORA VOICE audit OK — %d battute, tre atti distinti, ricordi solo dopo le rivelazioni" % _totale())
	quit(0)

func _totale() -> int:
	var n := 0
	for atto in NoraVoice.LINES.keys():
		for beat in Dictionary(NoraVoice.LINES[atto]).keys():
			n += Array(Dictionary(NoraVoice.LINES[atto])[beat]).size()
	for atto in NoraVoice.RICORDI.keys():
		n += Array(NoraVoice.RICORDI[atto]).size()
	return n

## NORA deve avere un carattere dichiarato come ogni residente del gioco: era
## l'unico personaggio che non ne aveva, e si sentiva nelle battute.
func _prova_carattere() -> void:
	for tratto in [NoraVoice.REGISTRO, NoraVoice.TIC, NoraVoice.CONVINZIONE, NoraVoice.BISOGNO]:
		assert(str(tratto).length() > 20,
			"un tratto di carattere di NORA è vuoto o generico: «%s»" % str(tratto))

func _prova_repertorio() -> void:
	var beat_attesi := ["solve", "victory", "defeat", "scaffold"]
	for atto_data in ["atto1", "atto2", "atto3"]:
		var atto := str(atto_data)
		assert(NoraVoice.LINES.has(atto), "manca l'atto %s" % atto)
		var pozzi: Dictionary = NoraVoice.LINES[atto]
		for beat_data in beat_attesi:
			var beat := str(beat_data)
			assert(pozzi.has(beat), "%s non ha il momento «%s»" % [atto, beat])
			var pool: Array = pozzi[beat]
			assert(pool.size() >= NoraVoice.MIN_BATTUTE,
				"%s/%s ha %d battute, il minimo è %d: chi parla a ogni prova non può avere il repertorio più corto del gioco" % [
					atto, beat, pool.size(), NoraVoice.MIN_BATTUTE])
			for frase_data in pool:
				var frase := str(frase_data)
				assert(frase.strip_edges().length() > 25,
					"battuta troppo scarna in %s/%s: «%s»" % [atto, beat, frase])
				# Registro dichiarato: mai superlativi sulla PERSONA. Si loda
				# quello che Eli ha fatto, non quello che sarebbe.
				var basso := frase.to_lower()
				for proibito in ["bravissima", "sei un genio", "perfetta!", "fantastica"]:
					assert(not basso.contains(str(proibito)),
						"«%s» loda la persona invece dell'azione, contro il registro dichiarato" % frase)

## Gli atti devono raccontare punti diversi della storia: una frase condivisa
## farebbe dire a NORA al mondo 20 la stessa cosa del mondo 1, che è esattamente
## il difetto da cui nasce questa struttura.
func _prova_atti_distinti() -> void:
	var viste: Dictionary = {}
	for atto_data in NoraVoice.LINES.keys():
		var atto := str(atto_data)
		for beat_data in Dictionary(NoraVoice.LINES[atto]).keys():
			for frase_data in Array(Dictionary(NoraVoice.LINES[atto])[str(beat_data)]):
				var frase := str(frase_data)
				assert(not viste.has(frase),
					"la stessa battuta compare in due atti: «%s» (%s e %s)" % [
						frase, str(viste.get(frase, "")), atto])
				viste[frase] = atto

	# I confini: il mondo 1 è nel primo atto, il 24 nel terzo, e nessun livello
	# cade fuori.
	assert(NoraVoice.atto_di(1) == "atto1", "il mondo 1 non è nel primo atto")
	assert(NoraVoice.atto_di(NoraVoice.ATTO_II_DA - 1) == "atto1", "confine del primo atto sbagliato")
	assert(NoraVoice.atto_di(NoraVoice.ATTO_II_DA) == "atto2", "il secondo atto non comincia dove dichiarato")
	assert(NoraVoice.atto_di(NoraVoice.ATTO_III_DA) == "atto3", "il terzo atto non comincia dove dichiarato")
	assert(NoraVoice.atto_di(24) == "atto3", "il mondo 24 non è nel terzo atto")
	for livello in range(1, 25):
		assert(NoraVoice.LINES.has(NoraVoice.atto_di(livello)),
			"il mondo %d cade in un atto che non esiste" % livello)

func _prova_ricordi() -> void:
	assert(not NoraVoice.RICORDI.has("atto1"),
		"ci sono ricordi nel primo atto: alluderebbero a rivelazioni non ancora avvenute")
	for atto_data in ["atto2", "atto3"]:
		var atto := str(atto_data)
		assert(NoraVoice.RICORDI.has(atto), "l'atto %s non ha ricordi" % atto)
		var pool: Array = NoraVoice.RICORDI[atto]
		assert(pool.size() >= NoraVoice.MIN_BATTUTE,
			"%s ha %d ricordi, il minimo è %d" % [atto, pool.size(), NoraVoice.MIN_BATTUTE])
		for frase_data in pool:
			# Il tic dichiarato: NORA si INTERROMPE. Un ricordo che comincia
			# come una frase normale non è un'interruzione, è un'altra battuta.
			assert(str(frase_data).begins_with("…"),
				"un ricordo non si apre come un'interruzione: «%s»" % str(frase_data))

func _prova_estrazione() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var voce := NoraVoice.new()

	# Ogni atto pesca dal proprio pozzo, e mai da quello di un altro.
	for livello in [1, 5, 9, 14, 17, 24]:
		voce.level = livello
		var atto := NoraVoice.atto_di(livello)
		for _i in range(40):
			var frase := voce.line("defeat", rng)
			assert(Array(Dictionary(NoraVoice.LINES[atto])["defeat"]).has(frase),
				"al mondo %d NORA parla con le battute di un altro atto: «%s»" % [livello, frase])

	# Un momento che non esiste non deve inventare niente.
	assert(voce.line("inesistente", rng) == "", "un momento sconosciuto produce una frase")

	# I ricordi arrivano a gocce, non a ogni prova: una frase che c'è sempre
	# smette di essere un'interruzione e diventa una formula.
	voce = NoraVoice.new()
	voce.level = 20
	var con_ricordo := 0
	var giri := 60
	for _i in range(giri):
		if voce.line("solve", rng).contains("…"):
			con_ricordo += 1
	var quota := float(con_ricordo) / float(giri)
	assert(quota > 0.0, "nel terzo atto NORA non si interrompe mai: il tic non arriva al giocatore")
	assert(quota <= 1.0 / float(NoraVoice.RICORDO_SU) + 0.05,
		"NORA si interrompe troppo spesso (%.0f%%): diventa una macchietta" % (quota * 100.0))

	# E nel primo atto non si interrompe mai.
	voce = NoraVoice.new()
	voce.level = 3
	for _i in range(60):
		assert(not voce.line("solve", rng).contains("…"),
			"nel primo atto NORA allude a qualcosa che non ha ancora scoperto")
