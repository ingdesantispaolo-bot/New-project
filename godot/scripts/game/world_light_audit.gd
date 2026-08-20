extends SceneTree

## **La ricompensa corta: che cosa succede quando una prova va bene.**
## (7 agosto 2026, riscritto il 20 agosto 2026)
##
## Nasce dal verdetto di un collaudo: «noioso, poco stimolante, faticoso».
## Misurando, il difetto era strutturale — **il ciclo di ricompensa durava dai 27
## ai 72 minuti**, perché l'esame era l'unico momento in cui il gioco cambiava.
##
## La risposta di allora fu un velo di nebbia che si alzava di un dodicesimo a
## ogni prova. Ha funzionato, e ha lasciato un debito: teneva occupata la
## **luminosità della scena**, che è il posto dove sta scritto che ora è. Finché
## la teneva occupata, il tempo non poteva tornare a passare — e infatti non
## passava, con ventiquattro ore d'autore ridotte a quattro.
##
## Dal 20 agosto una prova superata **accende un fuoco** ([[WorldAwakening]]) e
## il landmark del mondo avanza di un passo. La luce della scena è tornata a
## `WorldSky`, che risponde solo all'orologio. Le proprietà tenute qui sono le
## stesse di prima, perché il difetto da cui nascono non è cambiato:
##
##   1. **una prova, una ricompensa.** Se un esercizio superato non muovesse
##      niente, saremmo tornati al punto di partenza;
##   2. **non torna mai indietro.** Toglierla dopo un errore sarebbe la minaccia
##      che abbiamo deliberatamente scelto di non fare;
##   3. **il mondo cambia molto prima dell'esame.** È una ricompensa, non un
##      secondo cancello;
##   4. **la barra dice sempre quanto manca.** Una barra che non lo dice è una
##      decorazione, e il bambino non sa se conviene fare un'altra prova adesso;
##   5. **la ricompensa non usa la luminosità.** È la proprietà nuova, ed è
##      quella che impedisce al debito di ricrearsi in silenzio.

func _init() -> void:
	_prova_ricompensa_immediata()
	_prova_non_torna_indietro()
	_prova_ricompensa_prima_dell_esame()
	_prova_i_fuochi_pareggiano_il_contatore()
	_prova_la_ricompensa_non_e_luminosita()
	_prova_gradi()
	print("WORLD LIGHT audit OK — una prova un fuoco, niente torna indietro, la luce non fa piu' da premio")
	quit(0)

func _nuovo() -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return save

func _prova_ricompensa_immediata() -> void:
	var save := _nuovo()
	assert(is_equal_approx(WorldLight.luce(save, "1"), 0.0), "un mondo nuovo non parte da zero")
	var prima := WorldLight.luce(save, "1")
	var dopo := WorldLight.accendi(save, "1")
	assert(dopo > prima, "una prova superata non ha mosso niente: il ciclo corto non esiste")
	# E il fuoco corrispondente si può accendere: è l'oggetto che si vede.
	assert(WorldAwakening.accendi(save, "1", 0), "la prima prova non accende nessun fuoco")
	assert(WorldAwakening.quanti(save, "1") == 1, "il fuoco acceso non risulta acceso")
	# La potenza cresce insieme, ma su un altro orizzonte.
	assert(WorldLight.prove_totali(save) == 0, "la potenza è cresciuta senza che nessuno l'abbia chiesto")
	WorldLight.avanza_potenza(save)
	assert(WorldLight.prove_totali(save) == 1, "la potenza non registra la prova")

func _prova_non_torna_indietro() -> void:
	var save := _nuovo()
	for _i in range(5):
		WorldLight.accendi(save, "3")
		WorldAwakening.accendi(save, "3", WorldAwakening.quanti(save, "3"))
	var alta := WorldLight.luce(save, "3")
	var fuochi := WorldAwakening.quanti(save, "3")
	# Nessuna funzione deve poter abbassare l'una o spegnere gli altri: si prova
	# lavorando in un altro mondo e facendo salire la potenza.
	WorldLight.accendi(save, "4")
	WorldAwakening.accendi(save, "4", 0)
	WorldLight.avanza_potenza(save)
	assert(WorldLight.luce(save, "3") >= alta, "l'avanzamento di un mondo è sceso")
	assert(WorldAwakening.quanti(save, "3") >= fuochi, "un fuoco acceso si è spento")
	# E ogni mondo ha il suo.
	assert(WorldLight.luce(save, "9") < alta, "l'avanzamento di un mondo ha invaso un altro")
	assert(WorldAwakening.quanti(save, "9") == 0, "i fuochi di un mondo sono comparsi in un altro")
	# Riaccendere lo stesso fuoco non conta due volte.
	assert(not WorldAwakening.accendi(save, "4", 0), "lo stesso fuoco si accende due volte")

func _prova_ricompensa_prima_dell_esame() -> void:
	# Il mondo 1 chiede una quarantina di prove per l'esame: il mondo deve aver
	# finito di cambiare molto prima, o la ricompensa diventa un secondo cancello.
	assert(WorldLight.PROVE_PER_MONDO <= 20,
		"servono %d prove per cambiare il mondo: troppe, smette di essere una ricompensa"
		% WorldLight.PROVE_PER_MONDO)
	var save := _nuovo()
	for _i in range(WorldLight.PROVE_PER_MONDO):
		WorldLight.accendi(save, "1")
	assert(is_equal_approx(WorldLight.luce(save, "1"), 1.0), "il mondo non finisce mai di cambiare")
	# E non deborda.
	for _i in range(30):
		WorldLight.accendi(save, "1")
	assert(is_equal_approx(WorldLight.luce(save, "1"), 1.0), "l'avanzamento ha superato il massimo")

func _prova_i_fuochi_pareggiano_il_contatore() -> void:
	# **Un fuoco per prova, esattamente.** Se i due numeri divergessero, o
	# resterebbero fuochi che nessuna prova può accendere, o prove che non
	# accendono niente: in entrambi i casi la promessa «una prova, una
	# ricompensa» si romperebbe senza che nessuno se ne accorga.
	assert(WorldAwakening.FUOCHI == WorldLight.PROVE_PER_MONDO,
		"%d fuochi per %d prove" % [WorldAwakening.FUOCHI, WorldLight.PROVE_PER_MONDO])

	# **Il salvataggio nato prima dei fuochi.** Ha le prove e non ha gli indici:
	# senza il pareggio, chi rientra in un mondo già giocato lo troverebbe spento
	# come il primo giorno, e la ricompensa sembrerebbe tornata indietro.
	var vecchio := _nuovo()
	for _i in range(7):
		WorldLight.accendi(vecchio, "5")
	assert(WorldAwakening.quanti(vecchio, "5") == 0, "il salvataggio di prova non è vergine di fuochi")
	var accesi := WorldAwakening.allinea(vecchio, "5", WorldLight.prove_nel_mondo(vecchio, "5"))
	assert(accesi.size() == 7, "il pareggio ha acceso %d fuochi su 7 prove" % accesi.size())
	# Ed è stabile: rientrare una seconda volta non sposta niente.
	var di_nuovo := WorldAwakening.allinea(vecchio, "5", WorldLight.prove_nel_mondo(vecchio, "5"))
	assert(di_nuovo == accesi, "i fuochi si spostano fra un ingresso e l'altro")

	# Il pareggio non sfora nemmeno se il contatore, per qualsiasi ragione,
	# arrivasse più in alto del numero di fuochi.
	var pieno := _nuovo()
	for _i in range(WorldLight.PROVE_PER_MONDO + 9):
		WorldLight.accendi(pieno, "2")
	var tutti := WorldAwakening.allinea(pieno, "2", 999)
	assert(tutti.size() == WorldAwakening.FUOCHI,
		"il pareggio ha acceso %d fuochi: il mondo ne ha %d" % [tutti.size(), WorldAwakening.FUOCHI])

func _prova_la_ricompensa_non_e_luminosita() -> void:
	# **La riga che difende il cambio del 20 agosto.** Il velo di nebbia esiste
	# ancora, ma come strumento di regia — il momento del buio, la marea — e non
	# deve mai più essere pilotato dall'avanzamento: se ci tornasse, il tempo
	# smetterebbe di potersi muovere e nessun'altra prova se ne accorgerebbe.
	var file := FileAccess.open("res://scripts/outdoor_world.gd", FileAccess.READ)
	assert(file != null, "scena mondo assente")
	var sorgente := file.get_as_text()
	var aggancio := sorgente.find("func _on_world_light_changed")
	assert(aggancio >= 0, "manca l'aggancio della prova superata")
	var corpo := sorgente.substr(aggancio, 900)
	assert(corpo.find("_risveglia_il_fuoco_piu_vicino") >= 0,
		"una prova superata non accende piu' nessun fuoco")
	assert(corpo.find("_aggiorna_nebbia") < 0,
		"l'avanzamento e' tornato a pilotare la nebbia: la luminosita' non e' piu' libera di dire l'ora")

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

	# **La raggiungibilità non si controlla più qui.** (14 agosto 2026)
	#
	# Fino a quel giorno questa riga pretendeva che l'ultima soglia stesse sotto
	# **400 prove**, con la motivazione giusta — «una promessa che nessun bambino
	# vedrà» — e un numero **inventato**: era una stima della lunghezza della
	# campagna fatta prima che qualcuno la misurasse. Misurata con
	# `power_curve_probe`, la campagna vale 590 prove, quindi il tetto vero era
	# un altro e per giunta tagliava fuori i gradi alti che servivano.
	#
	# Non è un cricchetto allentato: è un cricchetto **spostato dove sa il
	# fatto**. `power_curve_audit` possiede la tabella misurata delle prove per
	# mondo e verifica tre cose che qui non si potevano vedere — che ogni grado
	# arrivi dentro la campagna, che l'ultimo arrivi con margine, e che il grado
	# di Eli non resti mai più di due sotto quello delle sacche di quel mondo.
	var massima := int(Dictionary(WorldLight.SOGLIE[WorldLight.SOGLIE.size() - 1])["prove"])

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
