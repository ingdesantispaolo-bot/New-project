class_name ExercisePool
extends RefCounted

## SPECIFICHE A INSIEME: una prova non è più un dato fisso, è un'ESTRAZIONE.
##
## Il conto che rende necessaria questa classe (docs/PROFONDITA_CONTENUTI.md):
## ogni materia viene incontrata ~138 volte per partita, quindi cinquanta partite
## senza ripetersi vorrebbero ~7.000 prove distinte per materia, ~84.000 in tutto.
## Autorarle è fuori scala di due ordini di grandezza. Ma una specifica che pesca
## **4 coppie da un insieme di 32** produce da sola C(32,4) = 35.960 prove diverse.
##
## Da qui la regola operativa del piano: ogni insieme deve superare le 10.000
## combinazioni, cioè 24–32 elementi per coppia (materia, formato). Duemila
## elementi autorati invece di ottantaquattromila: è la differenza fra un lavoro
## possibile e uno impossibile.
##
## Contratto (invariato rispetto al resto del progetto):
##  - **deterministico a parità di seed** — l'estrazione usa solo `rng`;
##  - **senza collisioni** — mai due voci che renderebbero la prova ambigua
##    (due lati destri uguali in un abbinamento, due etichette uguali in un
##    ordinamento): sono gli stessi vincoli che `ExerciseInteraction.validate`
##    pretende, applicati PRIMA di costruire il nodo invece che dopo;
##  - **coesistenza** — una specifica statica è semplicemente un insieme da cui si
##    pesca tutto: lo stesso codice serve entrambe, quindi la migrazione è
##    incrementale e ogni passo resta spedibile;
##  - **gate per livello invariato** — `minLevel` continua a valere sull'insieme.

const POOL_KEY := "pool"
const DRAW_KEY := "draw"

## Una specifica è "a insieme" quando dichiara più materiale di quanto ne usi.
static func is_pool(spec: Dictionary) -> bool:
	return spec.has(POOL_KEY)

## Le voci disponibili. `legacy_key` è il campo delle specifiche statiche
## ("pairs", "correctOrder"): la coesistenza sta tutta in questa riga.
static func entries(spec: Dictionary, legacy_key: String = "") -> Array:
	if spec.has(POOL_KEY):
		return Array(spec[POOL_KEY])
	if legacy_key != "":
		return Array(spec.get(legacy_key, []))
	return []

## Quante voci pescare: quanto dichiarato, altrimenti quanto chiede il chiamante,
## comunque mai più di quante ce ne sono.
static func draw_count(spec: Dictionary, wanted: int, available: int) -> int:
	var count := wanted
	if spec.has(DRAW_KEY):
		count = int(spec[DRAW_KEY])
	return mini(count, available)

## Estrazione senza collisioni. `unique_fields` elenca i campi che devono restare
## distinti dentro la prova: indici interi per voci-lista (`[sinistra, destra]` →
## `[0, 1]`), nomi per voci-dizionario (`{"label":…, "value":…}`).
##
## Se i vincoli impediscono di arrivare a `count` si restituisce meno materiale
## invece di violarli: una prova corta è un difetto visibile che gli audit
## prendono, una prova ambigua è un difetto che il bambino paga da solo.
## `can_fill()` verifica staticamente che il caso non possa capitare.
static func draw(
		spec: Dictionary,
		legacy_key: String,
		count: int,
		rng: RandomNumberGenerator,
		unique_fields: Array = []) -> Array:
	var available: Array = entries(spec, legacy_key).duplicate()
	shuffle(available, rng)
	var picked: Array = []
	var used: Dictionary = {}
	for entry in available:
		if picked.size() >= count:
			break
		if _collides(entry, unique_fields, used):
			continue
		_remember(entry, unique_fields, used)
		picked.append(entry)
	return picked

## Estrazione che GARANTISCE ogni categoria rappresentata: uno smistamento con un
## contenitore vuoto non è una prova più facile, è una prova rotta.
static func draw_covering(
		assignments: Dictionary,
		categories: Array,
		count: int,
		rng: RandomNumberGenerator) -> Array:
	var by_category: Dictionary = {}
	for key in assignments.keys():
		var category := str(assignments[key])
		var bucket: Array = by_category.get(category, [])
		bucket.append(key)
		by_category[category] = bucket
	var picked: Array = []
	var taken: Dictionary = {}
	# Prima un elemento per categoria, poi si riempie a caso: così il numero di
	# contenitori non dipende dalla fortuna dell'estrazione.
	for category_data in categories:
		var bucket: Array = by_category.get(str(category_data), [])
		if bucket.is_empty():
			continue
		var key = bucket[rng.randi_range(0, bucket.size() - 1)]
		taken[key] = true
		picked.append(key)
	var rest: Array = []
	for key in assignments.keys():
		if not taken.has(key):
			rest.append(key)
	shuffle(rest, rng)
	for key in rest:
		if picked.size() >= count:
			break
		picked.append(key)
	shuffle(picked, rng)
	return picked

# --- Profondità combinatoria ---------------------------------------------------
# Quante prove DISTINTE una specifica può produrre. È la misura che mancava: le
# ripetizioni osservate dicono se oggi va male, la profondità dice quando una
# materia è finita.

@warning_ignore("integer_division")
static func combinations(n: int, k: int) -> int:
	if n < 0 or k < 0 or k > n:
		return 0
	var steps := mini(k, n - k)
	var result := 1
	for i in range(steps):
		# Il prodotto parziale è sempre C(n, i+1), quindi la divisione è esatta.
		result = result * (n - i) / (i + 1)
	return result

## Sottoinsiemi di `k` elementi che toccano OGNI categoria, per inclusione-esclusione
## sulle categorie escluse. Serve perché lo smistamento non pesca liberamente: le
## estrazioni che lascerebbero un contenitore vuoto non esistono, e contarle
## gonfierebbe la profondità dichiarata.
static func covering_combinations(category_sizes: Array, k: int) -> int:
	var groups := category_sizes.size()
	if groups == 0 or k < groups:
		return 0
	var total := 0
	for size in category_sizes:
		total += int(size)
	var count := 0
	for mask in range(1 << groups):
		var excluded := 0
		var bits := 0
		for i in range(groups):
			if mask & (1 << i):
				excluded += int(category_sizes[i])
				bits += 1
		var term := combinations(total - excluded, k)
		count += -term if bits % 2 == 1 else term
	return maxi(count, 0)

## Verifica STATICA che l'estrazione possa sempre riempirsi rispettando i vincoli.
## Un insieme che non la supera produrrebbe prove corte a runtime, e le prove corte
## le scopre il bambino prima dell'audit.
static func can_fill(spec: Dictionary, legacy_key: String, count: int, unique_fields: Array) -> bool:
	var available: Array = entries(spec, legacy_key)
	if available.size() < count:
		return false
	for field in unique_fields:
		var distinct: Dictionary = {}
		for entry in available:
			distinct[str(field_of(entry, field))] = true
		if distinct.size() < count:
			return false
	return true

static func field_of(entry: Variant, field: Variant) -> Variant:
	if entry is Dictionary:
		return (entry as Dictionary).get(field, null)
	if entry is Array:
		var list := entry as Array
		var index := int(field)
		return list[index] if index >= 0 and index < list.size() else null
	return entry

static func shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = values[i]
		values[i] = values[j]
		values[j] = tmp

static func _collides(entry: Variant, unique_fields: Array, used: Dictionary) -> bool:
	for field in unique_fields:
		if used.has("%s#%s" % [str(field), str(field_of(entry, field))]):
			return true
	return false

static func _remember(entry: Variant, unique_fields: Array, used: Dictionary) -> void:
	for field in unique_fields:
		used["%s#%s" % [str(field), str(field_of(entry, field))]] = true
