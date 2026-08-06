extends SceneTree

## **La padronanza decade se una materia viene trascurata.** (6 agosto 2026)
##
## Nasce da un'indicazione del committente — «se il gioco è troppo facile non
## stimola» — su un difetto reale: la padronanza non scendeva mai col passare
## delle sessioni. Un bambino poteva portare una materia sopra soglia **una
## volta** e non toccarla più per venti mondi. Il gate a dodici materie chiedeva
## lavoro la prima volta e mai più, e quella era la rendita che rendeva il gioco
## facile a metà campagna.
##
## Le quattro proprietà tenute qui, e ognuna evita un modo di rendere stupida la
## penalità:
##
##   1. **morde davvero.** Un decadimento che non fa scendere niente è una
##      manopola morta, ed è il difetto che questo progetto trova più spesso;
##   2. **non punisce chi alterna.** Le prime dodici sessioni non tolgono nulla:
##      passare da una materia all'altra è il comportamento che il gioco chiede;
##   3. **non è un vicolo cieco.** Non si scende sotto metà del proprio massimo;
##   4. **non punisce chi non ha ancora cominciato.** Una materia mai praticata
##      non decade: l'ordine dei mondi non lo decide il bambino.

func _init() -> void:
	_prova_morde()
	_prova_franchigia()
	_prova_pavimento()
	_prova_mai_praticata()
	_prova_il_gate_si_riapre()
	print("DECAY audit OK — la trascuratezza costa, alternare no, e non esiste spirale")
	quit(0)

func _nuovo() -> Array:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	return [save, ProgressionManager.new(save, ContentManager.new())]

## Sessioni di una materia sola: le altre invecchiano.
func _macina(prog: ProgressionManager, subject: String, quante: int) -> void:
	for _i in range(quante):
		prog.record_practice(subject, 4, 4, 0)
		SpacedRepetition.tick(prog.save)

func _prova_morde() -> void:
	var coppia := _nuovo()
	var save: GameSaveManager = coppia[0]
	var prog: ProgressionManager = coppia[1]

	# Latino viene portata in alto, poi abbandonata mentre si gioca altro.
	_macina(prog, "latino", 8)
	var alta := save.mastery_of("latino")
	assert(alta > 0.7, "la fixture non ha portato la materia abbastanza in alto: %.2f" % alta)

	_macina(prog, "matematica", 60)
	var dopo := save.mastery_of("latino")
	assert(dopo < alta - 0.05,
		"sessanta sessioni ignorando latino non le hanno tolto niente: %.3f → %.3f" % [alta, dopo])

	# E la materia praticata non decade mentre la si pratica.
	assert(save.mastery_of("matematica") > 0.7,
		"la materia allenata è calata mentre veniva allenata")

func _prova_franchigia() -> void:
	var coppia := _nuovo()
	var save: GameSaveManager = coppia[0]
	var prog: ProgressionManager = coppia[1]
	_macina(prog, "musica", 6)
	var prima := save.mastery_of("musica")
	# Alternare fra due materie è ciò che il gioco chiede: dentro la franchigia
	# non deve costare niente.
	_macina(prog, "fisica", ProgressionManager.DECADIMENTO_FRANCHIGIA - 1)
	assert(is_equal_approx(save.mastery_of("musica"), prima),
		"alternare dentro la franchigia ha già tolto padronanza: %.4f → %.4f" % [
			prima, save.mastery_of("musica")])

func _prova_pavimento() -> void:
	var coppia := _nuovo()
	var save: GameSaveManager = coppia[0]
	var prog: ProgressionManager = coppia[1]
	_macina(prog, "storia", 8)
	var picco := save.mastery_of("storia")
	# Abbandono lunghissimo: molto oltre quello che serve a toccare il fondo.
	_macina(prog, "coding", 600)
	var finale := save.mastery_of("storia")
	var pavimento := picco * ProgressionManager.DECADIMENTO_PAVIMENTO
	assert(finale >= pavimento - 0.01,
		"la padronanza è sfondata sotto il pavimento: %.3f < %.3f. È una spirale senza ritorno." % [
			finale, pavimento])
	assert(finale > 0.0, "una materia abbandonata è arrivata a zero")

func _prova_mai_praticata() -> void:
	var coppia := _nuovo()
	var save: GameSaveManager = coppia[0]
	var prog: ProgressionManager = coppia[1]
	_macina(prog, "italiano", 80)
	# Elettronica non è mai stata giocata: al mondo 1 non è ancora comparsa.
	assert(save.mastery_never_set("elettronica"),
		"una materia mai giocata risulta già impostata: il decadimento l'ha toccata")
	assert(is_equal_approx(save.mastery_of("elettronica"), 0.0),
		"una materia mai cominciata è stata fatta decadere")

## La conseguenza che dà senso a tutto: una materia lasciata indietro può
## **riscendere sotto la soglia del gate**, e il livello si richiude finché non
## la si riprende. È esattamente la rendita che si voleva togliere.
func _prova_il_gate_si_riapre() -> void:
	var coppia := _nuovo()
	var save: GameSaveManager = coppia[0]
	var prog: ProgressionManager = coppia[1]
	var soglia := ApparatusConfig.subject_mastery_threshold("geografia", 1)
	_macina(prog, "geografia", 10)
	assert(save.mastery_of("geografia") >= soglia,
		"la fixture non ha portato geografia sopra soglia: %.3f < %.3f" % [
			save.mastery_of("geografia"), soglia])

	_macina(prog, "inglese", 200)
	assert(save.mastery_of("geografia") < soglia,
		"duecento sessioni ignorando geografia la lasciano ancora sopra soglia (%.3f): la rendita è intatta" % save.mastery_of("geografia"))

	# E si recupera: riprenderla in mano la riporta su. Senza questo, la
	# penalità sarebbe una condanna invece di una richiesta.
	_macina(prog, "geografia", 12)
	assert(save.mastery_of("geografia") >= soglia,
		"riprendere una materia trascurata non la riporta sopra soglia: %.3f" % save.mastery_of("geografia"))
