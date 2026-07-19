class_name OutdoorGenerator
extends RefCounted

## Generatore procedurale del mondo esterno, speculare a
## src/procedural/OutdoorChunkGenerator.ts (generateOutdoorChunk).
##
## PARITÀ: l'ordine e il numero delle estrazioni RNG devono coincidere ESATTAMENTE
## con il generatore TypeScript. Ogni valore che consuma RNG è calcolato in una
## variabile locale nell'ordine sorgente del TS (non ci si affida all'ordine di
## valutazione dei dizionari). Verifica con scripts/build-outdoor-fixtures.mjs +
## godot/scripts/fixture_audit.gd.

const CHUNK_SIZE := 896
const WORLD_CHUNKS := 8
const RNG := preload("res://scripts/deterministic_rng.gd")

const BIOME_STYLE := {
	"academy": {"label": "Radura Accademia", "color": 0x173b36, "accent": 0x6be7d6},
	"ruins": {"label": "Rovine del Relitto", "color": 0x2b2334, "accent": 0xff8f6b},
	"geo": {"label": "Dorsale geografica", "color": 0x1c3d2e, "accent": 0x8fe0a4},
	"logic": {"label": "Cratere logico", "color": 0x1c3148, "accent": 0x9f8cff},
	"wild": {"label": "Bosco variabile", "color": 0x1b3f32, "accent": 0x74f0c5},
	"crystal": {"label": "Nido cristallino", "color": 0x222950, "accent": 0xc7b8ff},
}

const ANCHOR_BIOMES := {
	"0,0": "academy", "1,0": "logic", "-1,0": "wild",
	"0,1": "geo", "1,1": "crystal", "-1,-1": "ruins",
}

const ENCOUNTER_PLANS := {
	"academy": [
		{"kind": "times", "label": "Sentiero tabelline", "enemy": "Drone Moltiplica"},
		{"kind": "mental", "label": "Sprint mentale", "enemy": "Sentinella Rapida"},
	],
	"wild": [
		{"kind": "times", "label": "Radici dei prodotti", "enemy": "Ramo Pattern"},
		{"kind": "physicalGeo", "label": "Sentiero natura", "enemy": "Custode del Bosco"},
	],
	"logic": [
		{"kind": "times", "label": "Anello dei prodotti", "enemy": "Modulo Pattern"},
		{"kind": "mental", "label": "Cratere dei calcoli", "enemy": "Eco Numerico"},
	],
	"crystal": [
		{"kind": "mental", "label": "Specchi numerici", "enemy": "Cristallo Rapido"},
		{"kind": "guardian", "label": "Nido prismatico", "enemy": "Guardiano Prisma"},
	],
	"geo": [
		{"kind": "capital", "label": "Capitali e continenti", "enemy": "Atlante Errante"},
		{"kind": "physicalGeo", "label": "Fiumi, laghi, montagne", "enemy": "Custode delle Carte"},
	],
	"ruins": [
		{"kind": "mental", "label": "Rovine operative", "enemy": "Guardia del Relitto"},
		{"kind": "capital", "label": "Rotte del mondo", "enemy": "Navigatore Smarrito"},
		{"kind": "guardian", "label": "Cuore del Relitto", "enemy": "Sentinella Antica"},
	],
}

func generate_chunk(seed: String, chunk_x: int, chunk_y: int) -> Dictionary:
	var random := RNG.new("%s:chunk:%d:%d" % [seed, chunk_x, chunk_y])
	var biome := _biome_for_chunk(seed, chunk_x, chunk_y)
	var style: Dictionary = BIOME_STYLE[biome]
	var world_x := chunk_x * CHUNK_SIZE
	var world_y := chunk_y * CHUNK_SIZE
	var distance := sqrt(float(chunk_x * chunk_x + chunk_y * chunk_y))

	# patch (4 estrazioni: x, y, w, h)
	var patch_x := world_x - random.between(22, 54)
	var patch_y := world_y - random.between(22, 54)
	var patch_w := CHUNK_SIZE + random.between(44, 108)
	var patch_h := CHUNK_SIZE + random.between(44, 108)
	var patch := {
		"id": biome, "label": style["label"], "color": style["color"], "accent": style["accent"],
		"x": patch_x, "y": patch_y, "w": patch_w, "h": patch_h,
	}

	# obstacles: count + per elemento kind(1), pos(2), r(1)
	var obstacle_count := random.between(15, 24)
	var obstacles: Array = []
	for index in range(obstacle_count):
		var kind := _obstacle_kind(random, biome)
		var pos := _world_pos(random, chunk_x, chunk_y, 72)
		var r := random.between(16, 42)
		obstacles.append({
			"id": "obs-%d_%d-%d" % [chunk_x, chunk_y, index],
			"x": pos.x, "y": pos.y, "r": r, "kind": kind, "color": _obstacle_color(kind),
		})

	# props: count + per elemento pos(2), kind(variabile)
	var prop_count := random.between(6, 11)
	var props: Array = []
	for index in range(prop_count):
		var pos := _world_pos(random, chunk_x, chunk_y, 78)
		var kind := _prop_kind(random, biome, index)
		props.append({
			"id": "prop-%d_%d-%d" % [chunk_x, chunk_y, index],
			"x": pos.x, "y": pos.y, "kind": kind, "color": style["accent"],
		})

	# landmark: plan(0/1) poi pos(2) se presente
	var landmark_plan := _landmark_for_chunk(random, biome, chunk_x, chunk_y)
	var landmarks: Array = []
	if not landmark_plan.is_empty():
		var pos := _world_pos(random, chunk_x, chunk_y, 180)
		landmarks.append({
			"id": "landmark-%d_%d-0" % [chunk_x, chunk_y],
			"x": pos.x, "y": pos.y, "biome": biome,
			"kind": landmark_plan["kind"], "label": landmark_plan["label"], "color": style["accent"],
		})

	# encounters: piani (count + shuffle) poi per elemento difficulty(0/1), pos(2)
	var plans := _encounter_plans(random, biome, chunk_x, chunk_y)
	var encounters: Array = []
	for index in range(plans.size()):
		var plan: Dictionary = plans[index]
		var difficulty: int
		if plan["kind"] == "guardian":
			difficulty = 4 + min(3, floori(distance / 2.0))
		else:
			difficulty = 1 + int(floor(random.next_float() * 3.0)) + min(2, floori(distance / 4.0))
		var pos := _world_pos(random, chunk_x, chunk_y, 132)
		var reward := (72 + difficulty * 6) if plan["kind"] == "guardian" else (22 + difficulty * 8)
		encounters.append({
			"id": "enc-%d_%d-%d" % [chunk_x, chunk_y, index],
			"x": pos.x, "y": pos.y, "biome": biome,
			"kind": plan["kind"], "label": plan["label"], "enemy": plan["enemy"],
			"difficulty": difficulty, "reward": reward,
		})

	# treasures: count + per elemento pos(2), label(1/2), rewardEnergy(1), rewardFragments(2)
	var treasure_count := random.between(1, 3)
	var treasures: Array = []
	for index in range(treasure_count):
		var pos := _world_pos(random, chunk_x, chunk_y, 120)
		var label := _treasure_label(random, index)
		var reward_energy := random.between(7, 24) + min(18, floori(distance * 2.0))
		var reward_fragments_base := random.between(2, 9)
		var reward_fragments := reward_fragments_base + (4 if random.next_float() > 0.78 else 0)
		treasures.append({
			"id": "treasure-%d_%d-%d" % [chunk_x, chunk_y, index],
			"x": pos.x, "y": pos.y, "biome": biome, "label": label,
			"rewardEnergy": reward_energy, "rewardFragments": reward_fragments,
		})

	var center := _chunk_center(chunk_x, chunk_y)
	var path_points: Array = [
		{"x": world_x, "y": center.y},
		{"x": center.x, "y": center.y},
		{"x": world_x + CHUNK_SIZE, "y": center.y},
		{"x": center.x, "y": center.y},
		{"x": center.x, "y": world_y},
		{"x": center.x, "y": center.y},
		{"x": center.x, "y": world_y + CHUNK_SIZE},
	]

	return {
		"id": "chunk-%d_%d" % [chunk_x, chunk_y],
		"chunkX": chunk_x, "chunkY": chunk_y, "worldX": world_x, "worldY": world_y,
		"size": CHUNK_SIZE, "biome": biome, "patch": patch,
		"obstacles": obstacles, "props": props, "landmarks": landmarks,
		"treasures": treasures, "encounters": encounters, "pathPoints": path_points,
	}

func _round(value: float) -> int:
	return floori(value + 0.5)

func _world_pos(random, chunk_x: int, chunk_y: int, pad: int) -> Vector2i:
	var span := float(CHUNK_SIZE - pad * 2)
	var x := _round(float(chunk_x * CHUNK_SIZE + pad) + random.next_float() * span)
	var y := _round(float(chunk_y * CHUNK_SIZE + pad) + random.next_float() * span)
	return Vector2i(x, y)

func _chunk_center(chunk_x: int, chunk_y: int) -> Vector2i:
	return Vector2i(
		_round(float(chunk_x * CHUNK_SIZE) + CHUNK_SIZE / 2.0),
		_round(float(chunk_y * CHUNK_SIZE) + CHUNK_SIZE / 2.0),
	)

func _biome_for_chunk(seed: String, chunk_x: int, chunk_y: int) -> String:
	var anchored: String = ANCHOR_BIOMES.get("%d,%d" % [chunk_x, chunk_y], "")
	if anchored != "":
		return anchored
	var random := RNG.new("%s:biome:%d:%d" % [seed, floori(chunk_x / 2.0), floori(chunk_y / 2.0)])
	var distance := sqrt(float(chunk_x * chunk_x + chunk_y * chunk_y))
	var pool: Array = ["academy", "logic", "wild", "geo", "ruins", "crystal"] if distance < 2.5 else ["wild", "geo", "ruins", "logic", "crystal"]
	return random.pick(pool)

func _obstacle_kind(random, biome: String) -> String:
	if biome == "academy":
		return random.pick(["tree", "rock", "bush"])
	if biome == "ruins":
		return random.pick(["ruin", "crystal", "rock", "pillar"])
	if biome == "wild":
		return random.pick(["tree", "bush", "mushroom"])
	if biome == "crystal":
		return random.pick(["crystal", "pillar", "rock"])
	if biome == "geo":
		return random.pick(["rock", "tree", "bush"])
	return random.pick(["rock", "crystal", "pillar"])

func _obstacle_color(kind: String) -> int:
	if kind == "tree":
		return 0x235b3a
	if kind == "bush":
		return 0x2b6c45
	if kind == "mushroom":
		return 0x9f8cff
	if kind == "crystal":
		return 0x7ad7ff
	if kind == "ruin" or kind == "pillar":
		return 0x4b4252
	return 0x46545c

func _prop_kind(random, biome: String, index: int) -> String:
	var signature: String
	if biome == "academy":
		signature = "camp"
	elif biome == "geo":
		signature = random.pick(["river", "waterfall", "bridge"])
	elif biome == "ruins":
		signature = random.pick(["tower", "arch", "statue"])
	elif biome == "wild":
		signature = random.pick(["garden", "well", "river"])
	elif biome == "crystal":
		signature = random.pick(["beacon", "arch", "garden"])
	else:
		signature = "lamp"
	if index == 0:
		return signature
	return random.pick(["sign", "lamp", "river", "tower", "camp", "waterfall", "bridge", "statue", "beacon", "garden", "well", "arch"])

func _landmark_for_chunk(random, biome: String, chunk_x: int, chunk_y: int) -> Dictionary:
	if chunk_x == 0 and chunk_y == 0:
		return {"kind": "forge", "label": "Forgia Esterna"}
	if chunk_x == 1 and chunk_y == 0:
		return {"kind": "logicSpire", "label": "Spira Logica"}
	if chunk_x == 0 and chunk_y == 1:
		return {"kind": "atlasGate", "label": "Porta dell'Atlante"}
	if chunk_x == -1 and chunk_y == -1:
		return {"kind": "ancientCore", "label": "Nucleo Antico"}
	if chunk_x == -1 and chunk_y == 0:
		return {"kind": "skyTree", "label": "Albero dei Percorsi"}
	if chunk_x == 1 and chunk_y == 1:
		return {"kind": "crystalNest", "label": "Nido Prisma"}
	if random.next_float() > 0.18:
		return {}
	if biome == "geo":
		return {"kind": "atlasGate", "label": "Porta dell'Atlante"}
	if biome == "logic":
		return {"kind": "logicSpire", "label": "Spira Logica"}
	if biome == "ruins":
		return {"kind": "ancientCore", "label": "Nucleo Antico"}
	if biome == "wild":
		return {"kind": "skyTree", "label": "Albero dei Percorsi"}
	if biome == "crystal":
		return {"kind": "crystalNest", "label": "Nido Prisma"}
	return {"kind": "forge", "label": "Campo officina"}

func _encounter_plans(random, biome: String, chunk_x: int, chunk_y: int) -> Array:
	var count := 2
	if not (chunk_x == 0 and chunk_y == 0):
		count = 2 if random.next_float() > 0.56 else 1
	var shuffled := random.shuffle(ENCOUNTER_PLANS[biome])
	return shuffled.slice(0, count)

func _treasure_label(random, index: int) -> String:
	if index == 0:
		if random.next_float() > 0.68:
			return "scrigno raro"
	if random.next_float() > 0.52:
		return "cassa energia"
	return "frammenti dispersi"
