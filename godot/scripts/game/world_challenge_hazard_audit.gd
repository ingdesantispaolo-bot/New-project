extends SceneTree

func _init() -> void:
	var entries := WorldChallengeHazardCatalog.all()
	assert(entries.size() == ApparatusConfig.MAX_LEVEL,
		"serve un pericolo specifico per ciascuno dei 24 mondi")
	var names := {}
	var ids := {}
	var sigils := {}
	var reward_ids := {}
	var motifs := {}
	var reward_total := 0
	var subjects := {"matematica": 0, "italiano": 0}
	var previous_contact_cost := 0
	var previous_failure_cost := 0
	var previous_tier := 0
	var manager := MinigameManager.new()
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var level := index + 1
		var name := str(entry.get("name", ""))
		var id := str(entry.get("id", ""))
		var sigil_id := str(entry.get("sigilId", ""))
		var reward_id := str(entry.get("conquestRewardId", ""))
		var subject := str(entry.get("subject", ""))
		var format := str(entry.get("format", ""))
		assert(not name.is_empty() and not names.has(name),
			"nome mancante o duplicato al mondo %d" % level)
		assert(id == "world-danger-%02d" % level and not ids.has(id),
			"id non stabile o duplicato al mondo %d" % level)
		assert(sigil_id == "sigillo-mondo-%02d" % level and not sigils.has(sigil_id),
			"sigillo non stabile o duplicato al mondo %d" % level)
		assert(not str(entry.get("sigilName", "")).is_empty(),
			"sigillo senza nome al mondo %d" % level)
		var conquest := RewardCatalog.conquest_for_world(level)
		assert(not conquest.is_empty(), "nessun Ricordo di conquista al mondo %d" % level)
		assert(reward_id == str(conquest.get("id", "")) and not reward_ids.has(reward_id),
			"Ricordo assente, duplicato o scollegato al mondo %d" % level)
		assert(str(entry.get("conquestRewardName", "")) == str(conquest.get("name", "")),
			"il Pericolo del mondo %d annuncia un Ricordo diverso dalla bottega" % level)
		assert(int(conquest.get("cost", -1)) == int(entry.get("rewardFragments", 0)),
			"il premio del Pericolo %d non permette di scegliere subito il proprio Ricordo" % level)
		assert(str(conquest.get("description", "")).length() >= 45
			and str(conquest.get("origine", "")).length() >= 70,
			"Ricordo del mondo %d non abbastanza autorato" % level)
		if str(conquest.get("slot", "")) == "memento":
			var motif := str(conquest.get("motif", ""))
			assert(not motif.is_empty() and not motifs.has(motif),
				"silhouette del Ricordo duplicata o assente al mondo %d" % level)
			motifs[motif] = true
		assert(subjects.has(subject), "materia non trasversale al mondo %d" % level)
		assert(MinigameManager.runtime_formats_for(subject, level).has(format),
			"il formato %s di %s non e' giocabile al mondo %d" % [format, subject, level])
		var rng := RandomNumberGenerator.new()
		rng.seed = level * 7919
		var session := manager.build_guided_minigame(subject, "", format, level, rng)
		assert(int(session.get("level", 0)) == level and not Array(session.get("nodes", [])).is_empty(),
			"la prova del mondo %d non costruisce contenuto del suo livello" % level)
		assert(str(entry.get("description", "")).length() >= 24,
			"il pericolo del mondo %d non racconta che cosa sta succedendo" % level)
		assert(int(entry.get("challengeLevel", 0)) == level,
			"il minigioco non usa il livello del mondo %d" % level)
		var contact_cost := int(entry.get("contactCost", 0))
		var failure_cost := int(entry.get("failureCost", 0))
		var tier := int(entry.get("threatTier", 0))
		var reward := int(entry.get("rewardFragments", 0))
		assert(reward == FragmentEconomy.premio_pericolo(tier),
			"premio del mondo %d fuori dall'economia centrale" % level)
		reward_total += reward
		assert(contact_cost >= previous_contact_cost and failure_cost >= previous_failure_cost,
			"le penalita' diminuiscono entrando nel mondo %d" % level)
		assert(tier >= previous_tier and tier in [1, 2, 3, 4, 5],
			"grado di rischio non crescente al mondo %d" % level)
		previous_contact_cost = contact_cost
		previous_failure_cost = failure_cost
		previous_tier = tier
		names[name] = true
		ids[id] = true
		sigils[sigil_id] = true
		reward_ids[reward_id] = true
		subjects[subject] = int(subjects[subject]) + 1
	assert(int(subjects["matematica"]) == 12 and int(subjects["italiano"]) == 12,
		"la campagna non alterna equamente italiano e matematica")
	assert(int(entries[0]["contactCost"]) == 3 and int(entries[-1]["contactCost"]) == 8,
		"il costo di contatto non scala da 3 a 8")
	assert(int(entries[0]["failureCost"]) == 2 and int(entries[-1]["failureCost"]) == 6,
		"il fallimento non scala da 2 a 6")
	assert(reward_total == 3320, "i 24 pericoli coniano %d frammenti invece di 3320" % reward_total)
	assert(RewardCatalog.conquest_items().size() == 24 and reward_ids.size() == 24,
		"la collezione dei Pericoli non contiene esattamente 24 Ricordi")
	print("WORLD CHALLENGE HAZARD audit OK — 24 identità, livello 1→24, rischio 1→5, contatto 3→8, fallimento 2→6")
	quit(0)
