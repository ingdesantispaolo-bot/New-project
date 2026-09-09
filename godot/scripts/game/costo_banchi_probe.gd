extends SceneTree

## Quanto costa leggere i dodici banchi, separato dal resto dell'avvio.
## Serve a decidere se R-17 (mondo 1 oltre i 500 ms) sia il prezzo dei banchi
## cresciuti da 4061 a 4854 item, o se il tempo stia altrove.

func _init() -> void:
	var path := "res://data/banks/"
	var files: PackedStringArray = []
	var dir := DirAccess.open(path)
	if dir:
		for f in dir.get_files():
			if f.ends_with(".json"):
				files.append(f)
	files.sort()

	# 1. Solo lettura + parse JSON, senza il ContentManager.
	var totale_lettura := 0.0
	var totale_byte := 0
	var totale_item := 0
	print("=== lettura + parse dei dodici banchi ===")
	print("file                          byte    item     ms")
	for f in files:
		var t0 := Time.get_ticks_usec()
		var testo := FileAccess.get_file_as_string(path + f)
		var dati = JSON.parse_string(testo)
		var ms := float(Time.get_ticks_usec() - t0) / 1000.0
		var n := 0
		if dati is Dictionary:
			n = Array((dati as Dictionary).get("items", [])).size()
		totale_lettura += ms
		totale_byte += testo.length()
		totale_item += n
		print("%-24s %8d %7d %6.1f" % [f, testo.length(), n, ms])
	print("TOTALE                   %8d %7d %6.1f ms" % [totale_byte, totale_item, totale_lettura])

	# 2. La strada vera: ContentManager._load_bank, che oltre al parse costruisce
	#    le cache. Prima volta = a freddo, seconda = a caldo.
	var content := ContentManager.new()
	var freddo := 0.0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var t0 := Time.get_ticks_usec()
		content.bank_difficulty_counts(str(subject_data))
		freddo += float(Time.get_ticks_usec() - t0) / 1000.0
	var caldo := 0.0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var t0 := Time.get_ticks_usec()
		content.bank_difficulty_counts(str(subject_data))
		caldo += float(Time.get_ticks_usec() - t0) / 1000.0
	print("\nContentManager: dodici materie a freddo %.1f ms, a caldo %.1f ms" % [freddo, caldo])

	# 3. Quante di queste letture avvengono davvero all'avvio di un mondo?
	var t0 := Time.get_ticks_usec()
	var fresco := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	fresco.build_varied_mission("matematica", 1, 6, {}, rng)
	print("una prima missione da un ContentManager nuovo: %.1f ms" % (
		float(Time.get_ticks_usec() - t0) / 1000.0))

	quit(0)
