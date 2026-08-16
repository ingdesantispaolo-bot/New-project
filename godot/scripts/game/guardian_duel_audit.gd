extends SceneTree

## **Il duello è tarato, e ogni scambio si può vincere?** (16 agosto 2026)
##
## Un minigioco di calcolo a tempo davanti a una ricompensa è la cosa più facile
## da sbagliare di tutto il progetto: se è troppo duro esclude proprio i bambini
## che questo gioco vuole tenere dentro, se è troppo facile il premio non vale
## niente, e se **genera uno scambio irrisolvibile** perde la fiducia di chi lo
## sta giocando in un colpo solo e per sempre.
##
## Quest'ultimo è il controllo che nessun collaudo a mano può fare: uno scambio
## impossibile su cinquecento non lo incontra nessuno provando, e lo incontrano
## tutti giocando. Qui se ne generano migliaia per ogni fascia e si risolvono
## davvero, con lo stesso cercatore che usa il pannello.
##
## La regola sopra a tutte, e l'unica che non è una taratura: **il duello può
## chiudere soltanto frammenti**, cioè cosmetici. Se un giorno qualcosa di
## necessario finisse dietro un guardiano, la promessa del gioco sarebbe rotta e
## nessun altro controllo se ne accorgerebbe.

const OK := "GUARDIAN DUEL audit VERDE"
## I gradi di potenza si leggono dalla scala, non si scrivono qui: una costante a
## mano lascerebbe i gradi nuovi fuori da ogni controllo senza diventare rossa.
static var GRADI: int = WorldLight.SOGLIE.size()
const TIER_MAX := 8
## Quanti scambi si generano per ogni combinazione di mondo e gradi. Duecento per
## fascia sono migliaia in tutto: abbastanza perché un difetto raro esca fuori.
const CAMPIONI := 200

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	_le_fasce_coprono_i_ventiquattro_mondi()
	_nessuna_combinazione_impossibile()
	_il_progresso_aiuta_sempre()
	_il_guardiano_forte_e_piu_duro()
	_ogni_scambio_si_puo_vincere()
	_il_colpo_e_onesto()
	_perdere_non_costa_piu_del_girare_alla_larga()
	if errori.is_empty():
		print(OK)
	else:
		printerr("GUARDIAN DUEL audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Nessun mondo deve cadere fuori dalle fasce, e la difficoltà non deve mai
## scendere salendo di mondo: un bambino che arriva al mondo 15 non può trovarsi
## un duello più facile di quello del mondo 14.
func _le_fasce_coprono_i_ventiquattro_mondi() -> void:
	var passi_precedenti := 0
	var massimo_precedente := 0
	for mondo in range(1, 25):
		var fascia := GuardianDuel.fascia_per_mondo(mondo)
		_controlla(not fascia.is_empty(), "mondo %d senza fascia" % mondo)
		var passi := int(fascia.get("passi", 0))
		var massimo := int(fascia.get("massimo", 0))
		_controlla(passi >= passi_precedenti,
			"mondo %d: la catena si accorcia (%d dopo %d)" % [mondo, passi, passi_precedenti])
		_controlla(massimo >= massimo_precedente,
			"mondo %d: i numeri rimpiccioliscono (%d dopo %d)" % [mondo, massimo, massimo_precedente])
		_controlla(int(fascia.get("mano", 0)) >= passi + 2,
			"mondo %d: la mano non tiene la strada giusta più due esche" % mondo)
		passi_precedenti = passi
		massimo_precedente = massimo
	# E la campagna deve **sentirsi** crescere: l'ultimo mondo non può chiedere
	# quanto il primo, o la difficoltà per mondo è una decorazione.
	var prima := GuardianDuel.fascia_per_mondo(1)
	var ultima := GuardianDuel.fascia_per_mondo(24)
	_controlla(int(ultima["passi"]) > int(prima["passi"]),
		"la catena finale non è più lunga di quella iniziale")
	_controlla(int(ultima["massimo"]) >= int(prima["massimo"]) * 4,
		"i numeri finali non sono sensibilmente più grandi")
	_controlla(Array(ultima["operazioni"]).size() > Array(prima["operazioni"]).size(),
		"le operazioni finali non sono più di quelle iniziali")

## **I due bordi.** Nessuna combinazione di mondo e gradi deve produrre un duello
## che non si può vincere, né uno che si vince senza guardare.
func _nessuna_combinazione_impossibile() -> void:
	for mondo in [1, 7, 12, 17, 24]:
		for tier in range(1, TIER_MAX + 1):
			for grado in range(GRADI):
				var regole := GuardianDuel.regole(mondo, tier, grado)
				var passi := int(regole["passi"])
				var secondi := float(regole["secondi"])
				var per_colpo := secondi / float(passi)
				# Sotto due secondi a colpo non si misura più il calcolo: si
				# misura il tempo di reazione del dito, che è un'altra cosa e che
				# a un bambino non si può insegnare.
				_controlla(per_colpo >= 2.0,
					"mondo %d T%d grado %d: %.1fs per colpo, è una gara di dita" %
					[mondo, tier, grado, per_colpo])
				# E sopra gli otto non è più un combattimento: è un esercizio con
				# un disegno intorno.
				_controlla(per_colpo <= 8.0,
					"mondo %d T%d grado %d: %.1fs per colpo, il guardiano non è un pericolo" %
					[mondo, tier, grado, per_colpo])
				_controlla(int(regole["sigilli"]) >= 2 and int(regole["sigilli"]) <= 4,
					"mondo %d T%d: %d sigilli" % [mondo, tier, int(regole["sigilli"])])
				_controlla(int(regole["tenuta"]) >= 2,
					"grado %d: meno di due colpi incassabili, il primo errore decide tutto" % grado)
				_controlla(int(regole["colpi"]) > passi,
					"mondo %d: nessun colpo di riserva, sottrazioni e divisioni non servono a niente" % mondo)
	# E il movimento ridotto non deve mai togliere tempo.
	for mondo in range(1, 25):
		var pieno := GuardianDuel.regole(mondo, 4, 2, false)
		var ridotto := GuardianDuel.regole(mondo, 4, 2, true)
		_controlla(float(ridotto["secondi"]) > float(pieno["secondi"]),
			"mondo %d: il movimento ridotto non allunga la carica" % mondo)

## **Allenarsi deve servire, sempre.** Contro lo stesso guardiano, salire di
## grado non può mai peggiorare nessuna delle due leve. È la promessa che lega il
## duello al resto del gioco: la potenza si guadagna facendo esercizi.
func _il_progresso_aiuta_sempre() -> void:
	for mondo in [1, 7, 12, 17, 24]:
		for tier in range(1, TIER_MAX + 1):
			for grado in range(1, GRADI):
				var ora := GuardianDuel.regole(mondo, tier, grado)
				var prima := GuardianDuel.regole(mondo, tier, grado - 1)
				_controlla(float(ora["secondi"]) >= float(prima["secondi"]),
					"mondo %d T%d: salendo al grado %d la carica si accorcia" % [mondo, tier, grado])
				_controlla(int(ora["tenuta"]) >= int(prima["tenuta"]),
					"grado %d: si incassano meno colpi del grado precedente" % grado)
			# E il grado massimo deve dare un vantaggio SENTITO: una progressione
			# che non si vede non motiva nessuno.
			var minimo := GuardianDuel.regole(mondo, tier, 0)
			var massimo := GuardianDuel.regole(mondo, tier, GRADI - 1)
			_controlla(int(massimo["tenuta"]) >= int(minimo["tenuta"]) * 2,
				"mondo %d T%d: arrivare al grado massimo raddoppia poco la tenuta" % [mondo, tier])
			_controlla(float(massimo["secondi"]) >= float(minimo["secondi"]) * 1.2,
				"mondo %d T%d: arrivare al grado massimo cambia troppo poco la carica" % [mondo, tier])

## Un guardiano più forte deve essere più duro, altrimenti i suoi gradi sono
## decorazione.
func _il_guardiano_forte_e_piu_duro() -> void:
	for grado in range(GRADI):
		for tier in range(2, TIER_MAX + 1):
			var ora := GuardianDuel.regole(12, tier, grado)
			var prima := GuardianDuel.regole(12, tier - 1, grado)
			_controlla(float(ora["secondi"]) <= float(prima["secondi"]),
				"grado %d: il guardiano T%d carica più lentamente del T%d" % [grado, tier, tier - 1])
			_controlla(int(ora["sigilli"]) >= int(prima["sigilli"]),
				"grado %d: il guardiano T%d ha meno sigilli del T%d" % [grado, tier, tier - 1])
	_controlla(GuardianDuel.premio_frammenti(TIER_MAX) > GuardianDuel.premio_frammenti(1),
		"un guardiano più forte non paga di più")
	_controlla(GuardianDuel.sigilli_richiesti(TIER_MAX) > GuardianDuel.sigilli_richiesti(1),
		"il guardiano più forte non porta più sigilli del più debole")

## **Il controllo che nessuno può fare a mano.** Migliaia di scambi generati e
## risolti davvero: ognuno deve avere una strada, e quella strada deve essere
## lunga quanto la fascia promette. Uno scambio che si spezza con un colpo solo
## sarebbe il chiavistello travestito; uno che non si spezza affatto sarebbe un
## bambino fermo davanti a un guardiano senza sapere perché.
func _ogni_scambio_si_puo_vincere() -> void:
	var rng := RandomNumberGenerator.new()
	for mondo in [1, 5, 10, 15, 20, 24]:
		var regole := GuardianDuel.regole(mondo, 4, 2)
		var passi := int(regole["passi"])
		var colpi := int(regole["colpi"])
		var mano := int(regole["mano"])
		var massimo := int(regole["massimo"])
		var senza_strada := 0
		var troppo_corti := 0
		var mani_sbagliate := 0
		var sigilli_bassi := 0
		var spente_in_partenza := 0
		for campione in range(CAMPIONI):
			rng.seed = hash("duello-%d-%d" % [mondo, campione])
			var scambio := GuardianDuel.genera_scambio(rng, regole)
			var rune: Array = scambio.get("rune", [])
			var partenza := int(scambio.get("partenza", 0))
			var bersaglio := int(scambio.get("bersaglio", 0))
			if rune.size() != mano:
				mani_sbagliate += 1
			if bersaglio < GuardianDuel.SIGILLO_MINIMO or bersaglio > massimo:
				sigilli_bassi += 1
			var percorso := GuardianDuel.percorso_minimo(partenza, bersaglio, rune, colpi)
			if percorso.is_empty():
				senza_strada += 1
			elif percorso.size() < 2:
				troppo_corti += 1
			elif percorso.size() > passi:
				senza_strada += 1
			# La mano non può essere tutta spenta all'inizio: un bambino che apre
			# lo scambio e non può toccare niente non sta pensando, sta aspettando.
			var vive := 0
			for runa in rune:
				if GuardianDuel.applicabile(partenza, runa):
					vive += 1
			if vive < 2:
				spente_in_partenza += 1
			# E le rune non si ripetono: due rune identiche sono una scelta finta.
			var viste: Dictionary = {}
			for runa in rune:
				var chiave := "%s%d" % [str(runa.get("op", "")), int(runa.get("n", 0))]
				if viste.has(chiave):
					mani_sbagliate += 1
					break
				viste[chiave] = true
		_controlla(senza_strada == 0,
			"mondo %d: %d scambi su %d non si possono vincere" % [mondo, senza_strada, CAMPIONI])
		_controlla(troppo_corti == 0,
			"mondo %d: %d scambi su %d si spezzano con un colpo solo" % [mondo, troppo_corti, CAMPIONI])
		_controlla(mani_sbagliate == 0,
			"mondo %d: %d mani con il numero sbagliato di rune o con doppioni" % [mondo, mani_sbagliate])
		_controlla(sigilli_bassi == 0,
			"mondo %d: %d sigilli fuori scala" % [mondo, sigilli_bassi])
		_controlla(spente_in_partenza == 0,
			"mondo %d: %d scambi si aprono con meno di due rune giocabili" % [mondo, spente_in_partenza])

## Il giudizio del colpo: quello che la runa dice è quello che la runa fa. Un
## minigioco di calcolo che mente sul proprio conto è l'unico difetto che non si
## può permettere — un bambino che calcola giusto e legge «sbagliato» impara la
## cosa peggiore, cioè che non conviene calcolare.
func _il_colpo_e_onesto() -> void:
	_controlla(GuardianDuel.applica(12, GuardianDuel.runa("+", 7)) == 19, "12 +7 non fa 19")
	_controlla(GuardianDuel.applica(12, GuardianDuel.runa("-", 5)) == 7, "12 −5 non fa 7")
	_controlla(GuardianDuel.applica(12, GuardianDuel.runa("*", 3)) == 36, "12 ×3 non fa 36")
	_controlla(GuardianDuel.applica(12, GuardianDuel.runa("/", 4)) == 3, "12 ÷4 non fa 3")
	# Le due cose che non entrano, e sono informazione invece che divieto.
	_controlla(GuardianDuel.applica(3, GuardianDuel.runa("-", 5)) < 0,
		"una sottrazione sotto zero viene accettata")
	_controlla(GuardianDuel.applica(8, GuardianDuel.runa("-", 8)) < 0,
		"una sottrazione che spegne l'impulso viene accettata")
	_controlla(GuardianDuel.applica(8, GuardianDuel.runa("-", 7)) == 1,
		"l'impulso non può arrivare a uno")
	_controlla(GuardianDuel.applica(30, GuardianDuel.runa("/", 4)) < 0,
		"una divisione non esatta viene accettata: il duello mentirebbe sul proprio conto")
	_controlla(not GuardianDuel.applicabile(30, GuardianDuel.runa("/", 4)),
		"«÷4» su 30 risulta giocabile")
	_controlla(GuardianDuel.applicabile(30, GuardianDuel.runa("/", 5)),
		"«÷5» su 30 risulta spenta")
	_controlla(GuardianDuel.testo_runa(GuardianDuel.runa("*", 4)) == "×4",
		"la runa non si legge come si applica")
	# Il cercatore: una strada che esiste si trova, una che non esiste no.
	var mano: Array = [
		GuardianDuel.runa("+", 6), GuardianDuel.runa("*", 3), GuardianDuel.runa("+", 100),
	]
	_controlla(GuardianDuel.percorso_minimo(4, 30, mano, 3).size() == 2,
		"la strada 4 +6 ×3 = 30 non viene trovata in due colpi")
	_controlla(GuardianDuel.percorso_minimo(4, 77, mano, 3).is_empty(),
		"viene trovata una strada che non esiste")
	# E la strada più corta è davvero la più corta.
	var doppia: Array = [
		GuardianDuel.runa("*", 5), GuardianDuel.runa("+", 8), GuardianDuel.runa("+", 2),
	]
	_controlla(GuardianDuel.percorso_minimo(2, 10, doppia, 3).size() == 1,
		"il cercatore preferisce una strada lunga a una corta")

## **Provarci non deve costare più che evitare.** Perdere il duello costa quanto
## un morso: se costasse di più, la scelta razionale sarebbe girare alla larga —
## e allora il minigioco non lo giocherebbe nessuno.
func _perdere_non_costa_piu_del_girare_alla_larga() -> void:
	for tier in range(1, TIER_MAX + 1):
		for grado in range(GRADI):
			var duello := GuardianDuel.costo_sconfitta(tier, grado)
			var morso := maxi(0, tier - grado) * WorldEnemy.COSTO_PER_GRADO
			_controlla(duello <= morso,
				"T%d/grado %d: perdere il duello costa %d, più del morso (%d)" %
				[tier, grado, duello, morso])
		_controlla(GuardianDuel.costo_sconfitta(tier, GRADI - 1) >= 0,
			"costo di sconfitta negativo per T%d" % tier)
	_controlla(GuardianDuel.costo_sconfitta(1, 4) == 0,
		"un guardiano molto più debole di Eli fa comunque pagare la sconfitta")
