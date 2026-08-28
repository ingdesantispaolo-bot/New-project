extends SceneTree

## **I meccanismi di mappa reggono su tutti e ventiquattro i mondi?** (7 agosto 2026)
##
## Le tappe A-D sono state scritte guardando il mondo 1. Questa prova le misura
## su tutti, ed è nata perché la misura ha trovato due incoerenze vere.
##
##   1. **Gli hazard dipendevano dal primo dado.** Il piazzamento provava UNA
##      posizione e, se cadeva in acqua o in zona protetta, rinunciava: otto
##      mondi ne ricevevano meno di tre, due ne ricevevano uno. Il numero di
##      pericoli variava per niente. Ora si riprova dodici volte, come già
##      faceva il piazzamento dei nemici dieci righe più su.
##   2. **Diciotto mondi su ventiquattro non hanno nessun guado**, perché non
##      hanno torrenti. Non è un difetto del codice — un guado senza acqua non
##      esiste — ma è un limite da dichiarare: la meccanica che apre fisicamente
##      la mappa vive in sei mondi su ventiquattro. Qui è registrata come tetto,
##      non come promessa.

## Quanti mondi hanno almeno un guado. È un numero MISURATO, non desiderato: se
## scende, qualcosa ha cambiato la generazione dell'acqua senza dirlo.
const MONDI_CON_GUADO_MIN := 6

func _init() -> void:
	var con_guado := 0
	var hazard_scarsi: Array = []
	# Quali sbarramenti la generazione mette DAVVERO in gioco, su tutti i mondi.
	# Vedi la guardia in fondo: raccoglierli qui costa una riga, e l'assenza di
	# uno dei tre non si vede giocando un mondo alla volta.
	var sbarramenti_visti := {}
	var mondi_con_due_sbarramenti := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profilo := WorldProfileCatalog.profile(livello)
		var comp := WorldCompositionGenerator.generate("seed-%d" % livello, profilo)

		# --- guadi: mai più del tetto, e stabili
		assert(comp.crossings.size() <= WorldCompositionGenerator.GUADI_MAX,
			"il mondo %d ha %d guadi: una mappa piena di sbarramenti non si esplora" % [
				livello, comp.crossings.size()])
		# **Ogni mondo ha almeno un passaggio da aprire.** (7 agosto 2026)
		#
		# Era la promessa mancata della tappa D: diciotto mondi su ventiquattro
		# non avevano torrenti, quindi non avevano niente da aprire. Ora dove
		# manca l'acqua la composizione mette uno sbarramento di terra — una
		# frana, un cancello, una parete — con la stessa struttura dati.
		assert(comp.crossings.size() >= 1,
			"il mondo %d non ha nessun passaggio da aprire, ne d'acqua ne di terra" % livello)
		var acqua := 0
		var terra := 0
		for voce in comp.crossings:
			if str(Dictionary(voce).get("kind", "")) == "barrier":
				terra += 1
				assert(str(Dictionary(voce).get("label", "")).strip_edges() != "",
					"sbarramento senza nome nel mondo %d" % livello)
				sbarramenti_visti[str(Dictionary(voce).get("label", ""))] = true
			else:
				acqua += 1
		# I due tipi non convivono: dove c'e' l'acqua comanda l'acqua, altrimenti
		# un mondo avrebbe sia guadi sia muri e la lettura si confonderebbe.
		assert(acqua == 0 or terra == 0,
			"il mondo %d mescola guadi d'acqua e sbarramenti di terra" % livello)
		if acqua > 0:
			con_guado += 1
		else:
			# **Nessun mondo di terra ne perde uno per strada.** Il mondo 1 ne
			# aveva UNO invece di due, perche' l'altro gli cadeva nel laghetto e
			# il piazzamento rinunciava al primo tentativo.
			assert(terra == WorldCompositionGenerator.SBARRAMENTI_SLOT.size(),
				"il mondo %d ha %d sbarramenti invece di %d: ne ha perso uno nel piazzamento" % [
					livello, terra, WorldCompositionGenerator.SBARRAMENTI_SLOT.size()])
			mondi_con_due_sbarramenti += 1

		# --- hazard: tre piazzabili ovunque, con i dodici tentativi
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("hazard-%d" % livello)
		var piazzati := 0
		for _indice in range(3):
			for _tentativo in range(12):
				var angolo := rng.randf() * TAU
				var raggio := rng.randf_range(600.0, 1500.0)
				var pos := WorldProfileCatalog.SPAWN + Vector2.RIGHT.rotated(angolo) * raggio
				if comp.is_protected(pos, 60.0):
					continue
				if comp.raw_water_weight(pos) >= 0.4:
					continue
				piazzati += 1
				break
		if piazzati < 3:
			hazard_scarsi.append("L%d:%d" % [livello, piazzati])

		# --- edifici: tre, con l'ingresso e un nome proprio
		var edifici := BuildingCatalog.for_world(livello, profilo)
		assert(edifici.size() == 3, "il mondo %d non ha tre edifici" % livello)
		for e in edifici:
			assert(str(Dictionary(e).get("label", "")).strip_edges().length() > 4,
				"edificio senza nome nel mondo %d" % livello)

		# --- la casa del mestiere allena la materia del MONDO: se divergessero,
		# l'edificio insegnerebbe una materia che quel mondo non ospita.
		assert(str(WorldLessonCatalog.lesson(livello).get("subject", "")) ==
			ApparatusConfig.world_subject(livello),
			"il mondo %d promette una materia e ne ospita un'altra" % livello)

	var elenco := "nessuno" if hazard_scarsi.is_empty() else ", ".join(PackedStringArray(hazard_scarsi))
	assert(hazard_scarsi.is_empty(),
		"mondi che non riescono a piazzare tre hazard: %s" % elenco)

	assert(con_guado >= MONDI_CON_GUADO_MIN,
		"solo %d mondi hanno un guado, erano %d: la generazione dell'acqua è cambiata" % [
			con_guado, MONDI_CON_GUADO_MIN])

	# **Uno sbarramento autorato che non compare mai non esiste.** (28 agosto 2026)
	#
	# Misurato prima della correzione: «il cancello dei Primi» stava in ZERO
	# mondi su ventiquattro. La sua posizione cadeva sul corridoio protetto
	# spawn->nave, il ciclo rinunciava, e un terzo della varietà scritta a mano
	# era codice morto. Nessuna prova se ne accorgeva: tutte guardavano un mondo
	# alla volta, e un mondo alla volta due sbarramenti su tre sembrano una
	# scelta. Questa guarda tutti e ventiquattro insieme, che è l'unico posto da
	# cui quel difetto si vede.
	for nome in ["la frana", "il cancello dei Primi", "la parete incisa"]:
		assert(sbarramenti_visti.has(nome),
			"lo sbarramento «%s» non compare in nessuno dei 24 mondi: è autorato e mai giocato" % nome)

	print("WORLD MECHANICS audit OK — 24 mondi: un passaggio da aprire ovunque (%d d'acqua, %d di terra con due sbarramenti ciascuno), tutte e tre le facce dello sbarramento in gioco, 3 hazard, 3 edifici" % [
		con_guado, mondi_con_due_sbarramenti])
	quit(0)
