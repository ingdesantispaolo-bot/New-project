extends SceneTree

func _etichette(spec: Dictionary, fmt: String) -> Array:
	var out: Array = []
	if fmt == "matching":
		for coppia in Array(spec.get("pairs", [])) + Array(spec.get("pool", [])):
			for lato in Array(coppia):
				out.append(str(lato))
	elif fmt == "ordering":
		for v in Array(spec.get("correctOrder", [])):
			out.append(str(v))
		for v in Array(spec.get("pool", [])):
			if typeof(v) == TYPE_DICTIONARY:
				out.append(str((v as Dictionary).get("label", "")))
			elif typeof(v) == TYPE_ARRAY:
				out.append(str((v as Array)[0]))
	elif fmt == "classification":
		for k in Dictionary(spec.get("items", {})).keys():
			out.append(str(k))
	return out

func _init() -> void:
	for subject in ["storia", "geografia"]:
		for fmt in ["matching", "ordering", "classification"]:
			var scoperti: Dictionary = {}
			var tot := 0
			var cop := 0
			for spec_data in Array(MinigameManager.table_for(fmt).get(subject, [])):
				var spec: Dictionary = spec_data
				var topic := str(spec.get("topic", ""))
				for etichetta in _etichette(spec, fmt):
					if str(etichetta).strip_edges() == "":
						continue
					tot += 1
					if TavoleRiferimento.copre(subject, topic, str(etichetta)):
						cop += 1
					else:
						var chiave := "%s | %s" % [topic, str(etichetta)]
						scoperti[chiave] = int(scoperti.get(chiave, 0)) + 1
			if tot > 0:
				print("### %s %s: %d/%d coperti, %d etichette scoperte distinte" % [subject, fmt, cop, tot, scoperti.size()])
				var chiavi: Array = scoperti.keys()
				chiavi.sort()
				for k in chiavi:
					print("   %s" % k)
	quit(0)
