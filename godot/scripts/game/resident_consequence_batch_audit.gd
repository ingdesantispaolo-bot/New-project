extends SceneTree

const OWNERS := {
	2: ["w02-corinna", "w02-bruno"],
	3: ["w03-ruggine", "w03-sesto"],
	4: ["w04-marea", "w04-lino"],
	5: ["w05-gerbo", "w05-tilla"],
}

func _init() -> void:
	for level in OWNERS:
		var specs := BuildingCatalog.for_world(level, WorldProfileCatalog.profile(level))
		for owner_data in OWNERS[level]:
			var owner := str(owner_data)
			assert(ResidentConsequenceVisual.supports(owner), "%s fuori dal lotto C-ART-13" % owner)
			var spec: Dictionary = {}
			for candidate_data in specs:
				var candidate: Dictionary = candidate_data
				if str(candidate.get("residentOwner", "")) == owner:
					spec = candidate
			assert(not spec.is_empty(), "%s senza luogo proprietario" % owner)
			var seen: Array = []
			for stage in [0, 1, 2]:
				var building := BuildingActor.new()
				building.configure(spec, stage, false, true)
				var visual := building.get("resident_consequence") as ResidentConsequenceVisual
				assert(visual != null, "%s non arriva nel proprio luogo" % owner)
				seen.append(str(visual.get_meta("visual_semantic", "")))
				var outcome := visual.get_node_or_null("GeneratedResidentOutcome") as Sprite2D
				assert(visual.get_child_count() == 1 and outcome != null,
					"%s non espone l'esito illustrato" % owner)
				assert(outcome.visible == (stage == 2),
					"%s mostra l'esito allo stadio sbagliato" % owner)
				building.free()
			assert(seen.size() == 3 and seen[0] != seen[1] and seen[1] != seen[2],
				"%s non rende leggibili i tre stadi" % owner)
	print("RESIDENT CONSEQUENCE BATCH audit OK — mondi 2-3, quattro luoghi proprietari")
	quit(0)
