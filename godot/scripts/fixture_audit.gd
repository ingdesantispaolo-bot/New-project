extends SceneTree

## Audit di parità Godot ↔ TypeScript.
## Ricarica la fixture prodotta da `node scripts/build-outdoor-fixtures.mjs`
## (dal generatore reale Phaser) e verifica che OutdoorGenerator riproduca
## esattamente ogni chunk. Uso:
##   godot --headless --script res://scripts/fixture_audit.gd

const FIXTURE_PATH := "res://data/parity-fixtures.json"

func _init() -> void:
	if not FileAccess.file_exists(FIXTURE_PATH):
		push_error("parity-fixtures.json mancante: esegui prima `node scripts/build-outdoor-fixtures.mjs`")
		quit(1)
		return
	var file := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
	var fixture = JSON.parse_string(file.get_as_text())
	if typeof(fixture) != TYPE_DICTIONARY or not fixture.has("cases"):
		push_error("Fixture di parità non valida")
		quit(1)
		return
	var generator := OutdoorGenerator.new()
	var failures := 0
	for item in fixture["cases"]:
		var chunk := generator.generate_chunk(str(item["seed"]), int(item["chunkX"]), int(item["chunkY"]))
		var mismatch := _first_mismatch(chunk, item["chunk"], "chunk")
		if mismatch != "":
			failures += 1
			push_error("Parità fallita %s (%d,%d): %s" % [item["seed"], int(item["chunkX"]), int(item["chunkY"]), mismatch])
	if failures == 0:
		print("Parità Godot ↔ TS OK su %d chunk" % fixture["cases"].size())
		quit(0)
	else:
		push_error("Parità fallita su %d/%d chunk" % [failures, fixture["cases"].size()])
		quit(1)

func _is_numeric(value) -> bool:
	return value is int or value is float

# Ritorna "" se uguali, altrimenti il percorso del primo campo divergente.
func _first_mismatch(a, b, path: String) -> String:
	if _is_numeric(a) and _is_numeric(b):
		return "" if float(a) == float(b) else "%s: %s != %s" % [path, a, b]
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return "%s: dimensione dizionario %d != %d" % [path, a.size(), b.size()]
		for key in a:
			if not b.has(key):
				return "%s: chiave mancante '%s'" % [path, key]
			var inner := _first_mismatch(a[key], b[key], "%s.%s" % [path, key])
			if inner != "":
				return inner
		return ""
	if a is Array and b is Array:
		if a.size() != b.size():
			return "%s: lunghezza array %d != %d" % [path, a.size(), b.size()]
		for i in a.size():
			var inner := _first_mismatch(a[i], b[i], "%s[%d]" % [path, i])
			if inner != "":
				return inner
		return ""
	return "" if a == b else "%s: %s != %s" % [path, a, b]
