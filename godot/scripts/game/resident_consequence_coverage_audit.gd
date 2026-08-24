extends SceneTree

## C-ART-13: ogni residente proprietario di un luogo deve avere una conseguenza
## leggibile nei tre stadi, senza aggiungere nodi, input o stato di gioco.

const EXPECTED_OWNERS := 46

func _init() -> void:
	var seen: Array[String] = []
	for level in range(1, 24):
		var specs := BuildingCatalog.for_world(level, WorldProfileCatalog.profile(level))
		for spec_data in specs:
			var spec: Dictionary = spec_data
			var owner := str(spec.get("residentOwner", ""))
			if owner.is_empty():
				continue
			assert(not seen.has(owner), "%s proprietario duplicato" % owner)
			seen.append(owner)
			assert(ResidentConsequenceVisual.supports(owner), "%s fuori da C-ART-13" % owner)
			var semantics: Array[String] = []
			for stage in [0, 1, 2]:
				var building := BuildingActor.new()
				building.configure(spec, stage, false, true)
				var visual := building.get("resident_consequence") as ResidentConsequenceVisual
				assert(visual != null, "%s non arriva nel proprio luogo" % owner)
				assert(visual.get_child_count() == 0, "%s aggiunge nodi" % owner)
				semantics.append(str(visual.get_meta("visual_semantic", "")))
				building.free()
			assert(semantics.size() == 3 and semantics[0] != semantics[1] and semantics[1] != semantics[2],
				"%s non rende leggibili i tre stadi" % owner)
	assert(seen.size() == EXPECTED_OWNERS, "copertura C-ART-13: %d/%d residenti" % [seen.size(), EXPECTED_OWNERS])
	print("RESIDENT CONSEQUENCE COVERAGE audit OK — 46 luoghi proprietari, tre stadi e zero nodi aggiunti")
	quit(0)
