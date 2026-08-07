extends SceneTree

## **La luce e la potenza: il ciclo di ricompensa corto.** (7 agosto 2026)
##
## Nasce dal verdetto di un collaudo: «noioso, poco stimolante, faticoso».
## Misurando, il difetto era strutturale — **il ciclo di ricompensa durava dai 27
## ai 72 minuti**, perché l'esame era l'unico momento in cui il gioco cambiava.
##
## Le proprietà che questa prova tiene, e ognuna risponde a un modo di sbagliare:
##
##   1. **una prova, una ricompensa.** Se un esercizio superato non muovesse
##      niente, saremmo tornati al punto di partenza;
##   2. **la luce non torna mai indietro.** Toglierla dopo un errore sarebbe la
##      minaccia che abbiamo deliberatamente scelto di non fare;
##   3. **il mondo si scopre molto prima dell'esame.** La luce è una ricompensa,
##      non un secondo cancello: se servisse tutta la fatica del mondo per
##      vedere la mappa, sarebbe un ostacolo travestito da premio;
##   4. **la barra dice sempre quanto manca.** Una barra che non lo dice è una
##      decorazione, e il bambino non sa se conviene fare un'altra prova adesso.

func _init() -> void:
	_prova_ricompensa_immediata()
	_prova_non_torna_indietro()
	_prova_luce_prima_dell_esame()
	_prova_gradi()
	print("WORLD LIGHT audit OK — una prova una ricompensa, luce monòtona, gradi raggiungibili")
	quit(0)

func _nuovo() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _prova_ricompensa_immediata() -> void:
	var save := _nuovo()
	assert(is_equal_approx(WorldLight.luce(save, "1"), 0.0), "un mondo nuovo non parte al buio")
	var prima := WorldLight.luce(save, "1")
	var dopo := WorldLight.accendi(save, "1")
	assert(dopo > prima, "una prova superata non ha scoperto niente: il ciclo corto non esiste")
	# E la potenza cresce insieme, ma su un altro orizzonte.
	assert(WorldLight.prove_totali(save) == 0, "la potenza è cresciuta senza che nessuno l'abbia chiesto")
	WorldLight.avanza_potenza(save)
	assert(WorldLight.prove_totali(save) == 1, "la potenza non registra la prova")

func _prova_non_torna_indietro() -> void:
	var save := _nuovo()
	for _i in range(5):
		WorldLight.accendi(save, "3")
	var alta := WorldLight.luce(save, "3")
	# Nessuna funzione deve poterla abbassare: si controlla che la luce sia
	# monòtona anche accendendo altri mondi e facendo salire la potenza.
	WorldLight.accendi(save, "4")
	WorldLight.avanza_potenza(save)
	assert(WorldLight.luce(save, "3") >= alta, "la luce di un mondo è scesa")
	# E ogni mondo ha la sua.
	assert(WorldLight.luce(save, "9") < alta, "la luce di un mondo ha invaso un altro")

func _prova_luce_prima_dell_esame() -> void:
	# Il mondo 1 chiede una quarantina di prove per l'esame: la mappa deve essere
	# tutta visibile molto prima, o la luce diventa un secondo cancello.
	assert(WorldLight.PROVE_PER_MONDO <= 20,
		"servono %d prove per scoprire il mondo: troppe, la luce smette di essere una ricompensa" % WorldLight.PROVE_PER_MONDO)
	var save := _nuovo()
	for _i in range(WorldLight.PROVE_PER_MONDO):
		WorldLight.accendi(save, "1")
	assert(is_equal_approx(WorldLight.luce(save, "1"), 1.0), "il mondo non si scopre mai del tutto")
	# E non deborda.
	for _i in range(30):
		WorldLight.accendi(save, "1")
	assert(is_equal_approx(WorldLight.luce(save, "1"), 1.0), "la luce ha superato il massimo")

func _prova_gradi() -> void:
	var save := _nuovo()
	assert(WorldLight.grado(save) == 0, "si parte già potenziati")
	var nomi: Dictionary = {}
	var precedente := -1
	for voce in WorldLight.SOGLIE:
		var s: Dictionary = voce
		assert(int(s["prove"]) > precedente or precedente < 0, "le soglie non crescono")
		precedente = int(s["prove"])
		assert(not nomi.has(str(s["nome"])), "due gradi hanno lo stesso nome: %s" % str(s["nome"]))
		nomi[str(s["nome"])] = true

	# Ogni grado deve essere raggiungibile dentro una campagna: la più alta non
	# può chiedere più prove di quante la campagna ne contenga.
	var massima := int(Dictionary(WorldLight.SOGLIE[WorldLight.SOGLIE.size() - 1])["prove"])
	assert(massima <= 400,
		"l'ultimo grado chiede %d prove: è una promessa che nessun bambino vedrà" % massima)

	# La barra dice sempre quanto manca, finché non si è al massimo.
	for _i in range(massima + 5):
		WorldLight.avanza_potenza(save)
		var stato := WorldLight.verso_il_prossimo(save)
		if bool(stato.get("completo", false)):
			continue
		assert(int(stato["mancano"]) > 0, "la barra dice che non manca niente ma il grado non è l'ultimo")
		assert(int(stato["servono"]) > 0, "la barra non sa quante prove servono")
		assert(str(stato.get("prossimo", "")) != "", "la barra non nomina il grado successivo")
	assert(WorldLight.grado(save) == WorldLight.SOGLIE.size() - 1,
		"l'ultimo grado non si raggiunge nemmeno superando tutte le prove previste")
