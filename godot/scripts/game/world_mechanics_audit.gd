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
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profilo := WorldProfileCatalog.profile(livello)
		var comp := WorldCompositionGenerator.generate("seed-%d" % livello, profilo)

		# --- guadi: mai più del tetto, e stabili
		assert(comp.crossings.size() <= WorldCompositionGenerator.GUADI_MAX,
			"il mondo %d ha %d guadi: una mappa piena di sbarramenti non si esplora" % [
				livello, comp.crossings.size()])
		if comp.crossings.size() > 0:
			con_guado += 1

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

	print("WORLD MECHANICS audit OK — 24 mondi: 3 hazard e 3 edifici ovunque, guadi in %d" % con_guado)
	quit(0)
