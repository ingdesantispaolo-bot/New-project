class_name OutdoorDeterministicRng
extends RefCounted

## PRNG seeded (mulberry32 + hash FNV-1a) speculare a `rng()` di
## src/procedural/OutdoorChunkGenerator.ts. Ogni estrazione deve coincidere
## bit a bit con il lato TypeScript: non modificare la sequenza senza
## rigenerare le fixture di parità (scripts/build-outdoor-fixtures.mjs).

var state: int

func _init(seed_text: String) -> void:
	state = _hash_seed(seed_text)

func next_float() -> float:
	state = (state + 0x6D2B79F5) & 0xFFFFFFFF
	var t := state
	t = _imul(t ^ (t >> 15), t | 1)
	t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & 0xFFFFFFFF
	t = (t ^ (t >> 14)) & 0xFFFFFFFF
	return float(t) / 4294967296.0

## Equivalente a Math.round(min + f*(max-min)): round-half-up, corretto anche
## per valori negativi (a differenza di round() di GDScript che arrotonda
## allontanandosi da zero).
func between(min_value: int, max_value: int) -> int:
	return floori(float(min_value) + next_float() * float(max_value - min_value) + 0.5)

## Equivalente a values[Math.floor(random() * values.length)].
func pick(values: Array):
	return values[int(floor(next_float() * float(values.size())))]

## Fisher-Yates speculare a shuffle() di OutdoorChunkGenerator.ts: consuma
## esattamente (n-1) estrazioni.
func shuffle(values: Array) -> Array:
	var copy := values.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := int(floor(next_float() * float(i + 1)))
		var tmp = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy

func _imul(left: int, right: int) -> int:
	return (left * right) & 0xFFFFFFFF

func _hash_seed(seed_text: String) -> int:
	var hash_value := 2166136261
	for character in seed_text:
		hash_value = (hash_value ^ character.unicode_at(0)) & 0xFFFFFFFF
		hash_value = (hash_value * 16777619) & 0xFFFFFFFF
	return hash_value
