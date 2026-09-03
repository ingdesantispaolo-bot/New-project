extends SceneTree

## Audit headless della bottega (C-14): acquisto/equip cosmetici via
## OutdoorGameplay. Verifica che la spesa passi da game_save E da
## result.fragmentsSpent (stesso pattern delle missioni con l'energia), il gating
## per livello, l'auto-equip/scambio di slot, la semantica upgrade/decor
## (inventory, non equipped) e il blocco su frammenti insufficienti o doppio
## acquisto.
##
## Dal 14 agosto 2026 la bottega si paga in FRAMMENTI: l'energia non compra più
## niente, ed è verificato qui punto per punto — ogni acquisto controlla anche
## che l'energia sia rimasta dov'era. Vedi [[FragmentEconomy]].
## Uso: godot --headless --path godot --script res://scripts/game/reward_audit.gd

func _init() -> void:
	var gameplay := _new_gameplay(5000, 1)

	# 1) Acquisto lecito: spende frammenti, aggiorna il delta della sessione e
	# non tocca l'energia — che è la ragione stessa della separazione.
	var energy_before: int = int(gameplay.runtime_state()["energy"])
	var fragments_before: int = int(gameplay.runtime_state()["fragments"])
	assert(gameplay.try_purchase_cosmetic("bot-lime"), "acquisto valido riuscito")
	var state := gameplay.runtime_state()
	assert(int(state["fragments"]) == int(fragments_before) - 120, "frammenti scalati del costo")
	assert(int(state["energy"]) == energy_before, "l'acquisto non tocca l'energia")
	assert(int(gameplay.result["fragmentsSpent"]) == 120, "delta sessione aggiornato")
	assert(Array(state["cosmeticsUnlocked"]).has("bot-lime"), "sbloccato")
	assert(str(state["cosmeticsEquipped"]["bot"]) == "bot-lime", "auto-equip sullo slot bot")

	# 2) Un secondo acquisto nello stesso slot sostituisce l'equip.
	assert(gameplay.try_purchase_cosmetic("bot-gold"), "secondo acquisto slot bot")
	state = gameplay.runtime_state()
	assert(str(state["cosmeticsEquipped"]["bot"]) == "bot-gold", "equip sostituito dal più recente")
	assert(Array(state["cosmeticsUnlocked"]).has("bot-lime"), "il primo resta posseduto")

	# 3) Ri-equip manuale del primo (già posseduto, non nuovo acquisto: nessuna spesa).
	var fragments_after_two := int(gameplay.runtime_state()["fragments"])
	assert(gameplay.equip_cosmetic("bot-lime"), "equip di un cosmetico già posseduto")
	assert(int(gameplay.runtime_state()["fragments"]) == fragments_after_two, "l'equip non spende frammenti")
	assert(str(gameplay.runtime_state()["cosmeticsEquipped"]["bot"]) == "bot-lime", "equip applicato")

	# 4) Gating per livello: un item con minLevel alto non è acquistabile a liv.1.
	assert(not gameplay.try_purchase_cosmetic("avatar-pilot"), "minLevel blocca l'acquisto")
	assert(gameplay.reward_manager.unavailable_reason("avatar-pilot") != "", "motivo mostrato all'HUD")
	assert(not Array(gameplay.runtime_state()["cosmeticsUnlocked"]).has("avatar-pilot"), "nessuno sblocco")

	# 5) Frammenti insufficienti: acquisto rifiutato, nessuna spesa fantasma — e
	# nemmeno un ripiego sull'energia, che è l'errore che questo blocco sorveglia.
	var poor := _new_gameplay(50, 1)
	var poor_fragments_before := int(poor.runtime_state()["fragments"])
	var poor_energy_before := int(poor.runtime_state()["energy"])
	assert(not poor.try_purchase_cosmetic("bot-lime"), "frammenti insufficienti bloccano l'acquisto")
	assert(int(poor.runtime_state()["fragments"]) == poor_fragments_before, "frammenti invariati")
	assert(int(poor.runtime_state()["energy"]) == poor_energy_before, "energia invariata")
	assert(int(poor.result.get("fragmentsSpent", 0)) == 0, "nessun delta riportato")

	# 6) upgrade/decor: va in inventory, "posseduto" = "equipaggiato", niente slot.
	assert(gameplay.try_purchase_cosmetic("nora-lens"), "acquisto upgrade")
	state = gameplay.runtime_state()
	assert(Array(state["cosmeticsInventory"]).has("nora-lens"), "upgrade in inventory")
	assert(not (state["cosmeticsEquipped"] as Dictionary).has("upgrade"), "upgrade non occupa uno slot equipaggiato")
	assert(gameplay.reward_manager.is_equipped("nora-lens"), "upgrade posseduto = equipaggiato")

	# 7) Doppio acquisto dello stesso id: nessuna spesa aggiuntiva.
	var fragments_before_repeat := int(gameplay.runtime_state()["fragments"])
	assert(not gameplay.try_purchase_cosmetic("bot-lime"), "riacquisto di un posseduto rifiutato")
	assert(int(gameplay.runtime_state()["fragments"]) == fragments_before_repeat, "nessuna spesa sul riacquisto")

	# 8) Unequip.
	gameplay.unequip_cosmetic("bot")
	assert(str(gameplay.reward_manager.equipped_id("bot")) == "", "slot liberato")

	# 9) Tutto il catalogo, a ogni mondo. Non basta provare due acquisti: una
	# provenienza spostata o un livello impossibile al mondo 17 resterebbero
	# invisibili fino a quando li incontra uno studente. La fixture considera
	# superati i Pericoli già raggiunti, così isola mondo, livello e categoria.
	for world in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var save := GameSaveManager.new()
		save.data = GameSaveManager._default_data()
		save.set_level(world)
		save.add_fragments(1_000_000)
		save.data["worlds"] = {"unlocked": range(1, world + 1), "current": world}
		for cleared_world in range(1, world + 1):
			save.mark_hazard_cleared(
				str(cleared_world), "world-danger-%02d" % cleared_world)
		var manager := RewardManager.new(save)
		for cosmetic_data in RewardCatalog.CATALOG:
			var cosmetic: Dictionary = cosmetic_data
			var id := str(cosmetic.get("id", ""))
			var source_world := int(cosmetic.get("mondo", 0))
			var encountered := source_world <= 0 or source_world <= world
			assert(manager.incontrato(id) == encountered,
				"mondo %d: disponibilità geografica errata per %s" % [world, id])
			var hazard_world := int(cosmetic.get("requiresHazardWorld", 0))
			var conquered := hazard_world <= 0 or hazard_world <= world
			assert(manager.conquistato(id) == conquered,
				"mondo %d: requisito Pericolo errato per %s" % [world, id])
			var expected_unlock := not FieldTools.is_field_tool(id) \
				and encountered and conquered \
				and world >= int(cosmetic.get("minLevel", 1))
			assert(manager.can_unlock(id) == expected_unlock,
				"mondo %d: stato di acquisto errato per %s" % [world, id])

	print("Reward audit OK — 24 mondi e tutto il catalogo: provenienza, livello, Pericoli, acquisto ed equip verificati")
	quit(0)

## `energy` è anche la dotazione di frammenti della fixture: i due valori erano
## la stessa cosa quando la bottega si pagava in energia, e tenerli uguali fa sì
## che ogni assert sull'energia intatta abbia una controparte vera da confrontare.
func _new_gameplay(energy: int, level: int) -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": energy},
		"initialSave": {
			"schemaVersion": 1, "playerId": "local", "level": level, "energy": energy, "fragments": energy,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0, "fragmentsSpent": 0,
		"completedEncounterIds": [], "collectedTreasureIds": [],
	}
	# Fixture isolata: non deve dipendere dal save lasciato da altri audit.
	gameplay.setup(request, result, false)
	return gameplay
