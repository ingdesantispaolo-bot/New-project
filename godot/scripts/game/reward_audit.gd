extends SceneTree

## Audit headless della bottega (C-14): acquisto/equip cosmetici via
## OutdoorGameplay. Verifica che la spesa passi da game_save E da
## result.energySpent (stesso pattern delle missioni), il gating per livello,
## l'auto-equip/scambio di slot, la semantica upgrade/decor (inventory, non
## equipped) e il blocco su energia insufficiente o doppio acquisto.
## Uso: godot --headless --path godot --script res://scripts/game/reward_audit.gd

func _init() -> void:
	var gameplay := _new_gameplay(5000, 1)

	# 1) Acquisto lecito: spende energia E riporta il delta al bridge.
	var energy_before := gameplay.runtime_state()["energy"]
	assert(gameplay.try_purchase_cosmetic("bot-lime"), "acquisto valido riuscito")
	var state := gameplay.runtime_state()
	assert(int(state["energy"]) == int(energy_before) - 120, "energia scalata del costo")
	assert(int(gameplay.result["energySpent"]) == 120, "delta riportato al bridge")
	assert(Array(state["cosmeticsUnlocked"]).has("bot-lime"), "sbloccato")
	assert(str(state["cosmeticsEquipped"]["bot"]) == "bot-lime", "auto-equip sullo slot bot")

	# 2) Un secondo acquisto nello stesso slot sostituisce l'equip.
	assert(gameplay.try_purchase_cosmetic("bot-gold"), "secondo acquisto slot bot")
	state = gameplay.runtime_state()
	assert(str(state["cosmeticsEquipped"]["bot"]) == "bot-gold", "equip sostituito dal più recente")
	assert(Array(state["cosmeticsUnlocked"]).has("bot-lime"), "il primo resta posseduto")

	# 3) Ri-equip manuale del primo (già posseduto, non nuovo acquisto: nessuna spesa).
	var energy_after_two := int(gameplay.runtime_state()["energy"])
	assert(gameplay.equip_cosmetic("bot-lime"), "equip di un cosmetico già posseduto")
	assert(int(gameplay.runtime_state()["energy"]) == energy_after_two, "l'equip non spende energia")
	assert(str(gameplay.runtime_state()["cosmeticsEquipped"]["bot"]) == "bot-lime", "equip applicato")

	# 4) Gating per livello: un item con minLevel alto non è acquistabile a liv.1.
	assert(not gameplay.try_purchase_cosmetic("avatar-pilot"), "minLevel blocca l'acquisto")
	assert(gameplay.reward_manager.unavailable_reason("avatar-pilot") != "", "motivo mostrato all'HUD")
	assert(not Array(gameplay.runtime_state()["cosmeticsUnlocked"]).has("avatar-pilot"), "nessuno sblocco")

	# 5) Energia insufficiente: acquisto rifiutato, nessuna spesa fantasma.
	var poor := _new_gameplay(50, 1)
	var poor_energy_before := int(poor.runtime_state()["energy"])
	assert(not poor.try_purchase_cosmetic("bot-lime"), "energia insufficiente blocca l'acquisto")
	assert(int(poor.runtime_state()["energy"]) == poor_energy_before, "energia invariata")
	assert(int(poor.result.get("energySpent", 0)) == 0, "nessun delta riportato")

	# 6) upgrade/decor: va in inventory, "posseduto" = "equipaggiato", niente slot.
	assert(gameplay.try_purchase_cosmetic("nora-lens"), "acquisto upgrade")
	state = gameplay.runtime_state()
	assert(Array(state["cosmeticsInventory"]).has("nora-lens"), "upgrade in inventory")
	assert(not (state["cosmeticsEquipped"] as Dictionary).has("upgrade"), "upgrade non occupa uno slot equipaggiato")
	assert(gameplay.reward_manager.is_equipped("nora-lens"), "upgrade posseduto = equipaggiato")

	# 7) Doppio acquisto dello stesso id: nessuna spesa aggiuntiva.
	var energy_before_repeat := int(gameplay.runtime_state()["energy"])
	assert(not gameplay.try_purchase_cosmetic("bot-lime"), "riacquisto di un posseduto rifiutato")
	assert(int(gameplay.runtime_state()["energy"]) == energy_before_repeat, "nessuna spesa sul riacquisto")

	# 8) Unequip.
	gameplay.unequip_cosmetic("bot")
	assert(str(gameplay.reward_manager.equipped_id("bot")) == "", "slot liberato")

	print("Reward audit OK — acquisto, gating livello, energia, upgrade/decor e unequip verificati")
	quit(0)

func _new_gameplay(energy: int, level: int) -> OutdoorGameplay:
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := {
		"outdoorState": {"fragments": 0},
		"godotSave": {
			"schemaVersion": 1, "playerId": "local", "level": level, "energy": energy, "fragments": 0,
			"mastery": {}, "missionsBySubject": {}, "apparatus": {},
			"cosmetics": {"unlocked": [], "equipped": {}, "inventory": []}, "modules": {"owned": [], "equipped": []},
		},
	}
	var result := {
		"schemaVersion": 1, "energyEarned": 0, "energySpent": 0, "fragmentsEarned": 0,
		"completedEncounterIds": [], "collectedTreasureIds": [],
	}
	gameplay.setup(request, result)
	return gameplay
