extends SceneTree

## Fotografia dell'inglese GIOCATO: quali ricette di minigioco esistono, su quali
## argomenti, in quali fasce — e quanto della sessione resta scelta multipla.
## Serve a decidere dove aggiungere meccaniche, non a promuovere o bocciare.
## Uso: godot --headless --path godot --script res://scripts/game/inglese_minigiochi_probe.gd

const ExerciseInteraction = preload("res://scripts/game/exercise_interaction.gd")
const RIPETIZIONI := 24

func _init() -> void:
	var content := ContentManager.new()
	_inventario()
	_mondi_inglese()
	_copertura_argomenti(content)
	_mix(content)
	_due_per_due(content)
	quit(0)

func _inventario() -> void:
	print("\n=== RICETTE DI MINIGIOCO PER L'INGLESE (formato · argomento · minLevel · fascia del minLevel) ===")
	var per_topic: Dictionary = {}
	for fmt_data in MinigameManager.FORMATS:
		var fmt := str(fmt_data)
		var tabella := MinigameManager.table_for(fmt)
		if not tabella.has("inglese"):
			continue
		var specs: Array = tabella["inglese"]
		print("-- %s (%d ricette)" % [fmt, specs.size()])
		for spec_data in specs:
			var spec: Dictionary = spec_data
			var topic := str(spec.get("topic", "?"))
			var min_level := int(spec.get("minLevel", 0))
			print("   %-18s minLevel %2d  → fascia %d" % [
				topic, min_level, ContentManager.target_difficulty(maxi(1, min_level))])
			var lista: Array = per_topic.get(topic, [])
			lista.append(fmt)
			per_topic[topic] = lista
	var chiavi: Array = per_topic.keys()
	chiavi.sort()
	print("\nArgomenti toccati dai minigiochi: %d" % chiavi.size())
	for t in chiavi:
		print("   %-20s %s" % [str(t), ", ".join(PackedStringArray(per_topic[t]))])

func _mondi_inglese() -> void:
	print("\n=== FORMATI DISPONIBILI MONDO PER MONDO ===")
	print("%5s %6s %8s  %s" % ["LIV", "FASCIA", "RICETTE", "FORMATI"])
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var formati := MinigameManager.runtime_formats_for("inglese", level)
		var totali := 0
		for fmt in formati:
			totali += MinigameManager.eligible_specs("inglese", str(fmt), level).size()
		var marca := " <-- mondo d'inglese" if str(WorldProfileCatalog.profile(level)["learningFocus"]["subject"]) == "inglese" else ""
		print("%5d %6d %8d  %s%s" % [level, ContentManager.target_difficulty(level), totali, ", ".join(formati), marca])

func _copertura_argomenti(content: ContentManager) -> void:
	print("\n=== ARGOMENTI DEL BANCO SENZA NESSUN MINIGIOCO ===")
	var minigioco: Dictionary = {}
	for fmt_data in MinigameManager.FORMATS:
		var tabella := MinigameManager.table_for(str(fmt_data))
		for spec_data in Array(tabella.get("inglese", [])):
			minigioco[str((spec_data as Dictionary).get("topic", ""))] = true
	var banco: Dictionary = {}
	for item_data in content._load_bank("inglese"):
		var item: Dictionary = item_data
		var t := str(item.get("topic", ""))
		var d := int(item.get("difficulty", 1))
		var info: Dictionary = banco.get(t, {"n": 0, "min": 9, "max": 0})
		info["n"] = int(info["n"]) + 1
		info["min"] = mini(int(info["min"]), d)
		info["max"] = maxi(int(info["max"]), d)
		banco[t] = info
	var scoperti: Array = []
	var coperti: Array = []
	var chiavi: Array = banco.keys()
	chiavi.sort()
	for t in chiavi:
		var info: Dictionary = banco[t]
		var riga := "%-22s %4d item · fasce %d-%d" % [str(t), int(info["n"]), int(info["min"]), int(info["max"])]
		if minigioco.has(str(t)):
			coperti.append(riga)
		else:
			scoperti.append(riga)
	for riga in scoperti:
		print("   " + str(riga))
	print("scoperti %d argomenti su %d" % [scoperti.size(), banco.size()])
	print("\n=== ARGOMENTI CON MINIGIOCO ===")
	for riga in coperti:
		print("   " + str(riga))

func _mix(content: ContentManager) -> void:
	print("
=== NODI D'INGLESE DAVVERO GIOCATI, MONDO PER MONDO (solo subject=inglese) ===")
	print("%5s %6s %7s %7s | %s" % ["LIV", "FASCIA", "NODI", "MC+SA", "FORMATI"])
	var globale: Dictionary = {}
	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var subject := str(profile["learningFocus"]["subject"])
		var events := MissionEventDirector.plan(profile, {}, "probe-inglese-%d" % level)
		var counts: Dictionary = {}
		var topics: Dictionary = {}
		for repeat in range(RIPETIZIONI):
			var rng := RandomNumberGenerator.new()
			rng.seed = 7000 + level * 31 + repeat
			for event in events:
				var kind := str((event as Dictionary).get("kind", "mission"))
				var session: Dictionary = {}
				if kind == "enigma":
					session = content.build_enigma(subject, level, 4, {}, rng)
				elif kind == "practice":
					session = content.minigame_manager.build_minigame(subject, level, rng)
				else:
					session = content.build_varied_mission(subject, level, 3, {}, rng)
				_conta(counts, topics, session)
			var exam := content.build_final_exam(subject, level, 3, rng)
			_conta(counts, topics, exam)
		var totale := 0
		for f in counts.keys():
			totale += int(counts[f])
			globale[f] = int(globale.get(f, 0)) + int(counts[f])
		if totale == 0:
			continue
		var carta := int(counts.get("multiple_choice", 0)) + int(counts.get("short_answer", 0))
		var pezzi: Array = []
		var chiavi: Array = counts.keys()
		chiavi.sort()
		for f in chiavi:
			pezzi.append("%s %d" % [str(f), int(counts[f])])
		print("%5d %6d %7d %6.0f%% | %s" % [
			level, ContentManager.target_difficulty(level), totale,
			float(carta) / float(totale) * 100.0, ", ".join(PackedStringArray(pezzi))])
		var argomenti: Array = topics.keys()
		argomenti.sort()
		print("        argomenti: %s" % ", ".join(PackedStringArray(argomenti)))
	var g_tot := 0
	for f in globale.keys():
		g_tot += int(globale[f])
	var g_carta := int(globale.get("multiple_choice", 0)) + int(globale.get("short_answer", 0))
	print("TOTALE inglese: %d nodi · carta (MC + risposta scritta) %.0f%%" % [g_tot, float(g_carta) / float(maxi(1, g_tot)) * 100.0])
	var gk: Array = globale.keys()
	gk.sort()
	for f in gk:
		print("   %-18s %5d  %5.1f%%" % [str(f), int(globale[f]), float(int(globale[f])) / float(maxi(1, g_tot)) * 100.0])

func _conta(counts: Dictionary, topics: Dictionary, session: Dictionary) -> void:
	for node_data in session.get("nodes", []):
		var node: Dictionary = node_data
		if str(node.get("subject", "")) != "inglese":
			continue
		var fmt := ExerciseInteraction.format_of(node)
		counts[fmt] = int(counts.get(fmt, 0)) + 1
		topics[str(node.get("topic", "?"))] = true

## Grammatica contro lessico: quale delle due arriva alle mani e quale resta
## sulla carta, nei due mondi che l'inglese chiama casa.
const GRAMMATICA := [
	"to-be", "have-got", "articles", "plurals", "pronouns", "there-is",
	"third-person", "do-does", "present-continuous", "possessives", "prepositions",
	"quantifiers", "modals", "past-tense", "irregular-past", "past-continuous",
	"present-perfect", "future", "comparatives", "question", "relatives",
	"phrasal-verbs", "word-family", "conditionals", "passive", "past-perfect",
	"reported-speech", "gerund-infinitive", "linkers", "connectors",
	"sentence", "negative", "wh-question", "contractions", "irregular-plural",
	"parts-of-speech", "verbs", "nouns", "spelling",
]

func _due_per_due(content: ContentManager) -> void:
	print("\n=== GRAMMATICA O LESSICO, MANI O CARTA (mondi 4 e 16) ===")
	for level in [4, 16]:
		var profile := WorldProfileCatalog.profile(level)
		var subject := str(profile["learningFocus"]["subject"])
		var events := MissionEventDirector.plan(profile, {}, "probe-inglese-%d" % level)
		var quadro := {"gram_mani": 0, "gram_carta": 0, "less_mani": 0, "less_carta": 0}
		var gram_mani_topic: Dictionary = {}
		for repeat in range(RIPETIZIONI):
			var rng := RandomNumberGenerator.new()
			rng.seed = 7000 + level * 31 + repeat
			var sessioni: Array = []
			for event in events:
				var kind := str((event as Dictionary).get("kind", "mission"))
				if kind == "enigma":
					sessioni.append(content.build_enigma(subject, level, 4, {}, rng))
				elif kind == "practice":
					sessioni.append(content.minigame_manager.build_minigame(subject, level, rng))
				else:
					sessioni.append(content.build_varied_mission(subject, level, 3, {}, rng))
			sessioni.append(content.build_final_exam(subject, level, 3, rng))
			for sessione in sessioni:
				for node_data in Array((sessione as Dictionary).get("nodes", [])):
					var node: Dictionary = node_data
					if str(node.get("subject", "")) != "inglese":
						continue
					var fmt := ExerciseInteraction.format_of(node)
					var carta := fmt == "multiple_choice" or fmt == "short_answer"
					var gram := GRAMMATICA.has(str(node.get("topic", "")))
					var chiave := "%s_%s" % ["gram" if gram else "less", "carta" if carta else "mani"]
					quadro[chiave] = int(quadro[chiave]) + 1
					if gram and not carta:
						gram_mani_topic[str(node.get("topic", ""))] = int(gram_mani_topic.get(str(node.get("topic", "")), 0)) + 1
		var totale := 0
		for k in quadro.keys():
			totale += int(quadro[k])
		print("-- mondo %d (fascia %d), %d nodi d'inglese" % [level, ContentManager.target_difficulty(level), totale])
		print("     grammatica con le mani %5d (%4.1f%%) | grammatica sulla carta %5d (%4.1f%%)" % [
			int(quadro["gram_mani"]), float(int(quadro["gram_mani"])) / float(maxi(1, totale)) * 100.0,
			int(quadro["gram_carta"]), float(int(quadro["gram_carta"])) / float(maxi(1, totale)) * 100.0])
		print("     lessico    con le mani %5d (%4.1f%%) | lessico    sulla carta %5d (%4.1f%%)" % [
			int(quadro["less_mani"]), float(int(quadro["less_mani"])) / float(maxi(1, totale)) * 100.0,
			int(quadro["less_carta"]), float(int(quadro["less_carta"])) / float(maxi(1, totale)) * 100.0])
		var chiavi: Array = gram_mani_topic.keys()
		chiavi.sort()
		var pezzi: Array = []
		for t in chiavi:
			pezzi.append("%s %d" % [str(t), int(gram_mani_topic[t])])
		print("     grammatica toccata con le mani: %s" % ", ".join(PackedStringArray(pezzi)))
