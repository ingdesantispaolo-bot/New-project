class_name MathExerciseGenerator
extends RefCounted

## Generatore matematico nativo a complessita progressiva. I livelli 1..24
## attraversano otto profili e ampliano il repertorio senza sostituirlo: gli
## esercizi semplici restano disponibili, ma numeri e strutture cambiano.

static func complexity_for_level(level: int) -> int:
	return clampi(1 + floori(float(maxi(0, level - 1)) / 3.0), 1, 8)

func build_nodes(level: int, count: int, rng: RandomNumberGenerator, recent_signatures: Array, review_topics: Array = []) -> Array:
	var complexity := complexity_for_level(level)
	var archetypes := _eligible_archetypes(complexity)
	_shuffle(archetypes, rng)
	if review_topics.has("tabelline"):
		archetypes.erase("multiplication")
		archetypes.push_front("multiplication")
	var nodes: Array = []
	var session_signatures: Array = []
	for index in range(count):
		var preferred := str(archetypes[index % archetypes.size()])
		var node := _unique_node(preferred, complexity, rng, recent_signatures, session_signatures, index)
		if review_topics.has(str(node.get("topic", ""))):
			node["review"] = true
		nodes.append(node)
		session_signatures.append(str(node["signature"]))
		recent_signatures.append(str(node["signature"]))
	while recent_signatures.size() > 28:
		recent_signatures.pop_front()
	return nodes

func _unique_node(preferred: String, complexity: int, rng: RandomNumberGenerator, recent: Array, current: Array, index: int) -> Dictionary:
	var candidate := {}
	for attempt in range(36):
		var archetype := preferred if attempt < 12 else str(_eligible_archetypes(complexity)[rng.randi_range(0, _eligible_archetypes(complexity).size() - 1)])
		candidate = _build_archetype(archetype, complexity, rng, index)
		var signature := str(candidate.get("signature", ""))
		if not recent.has(signature) and not current.has(signature):
			return candidate
	return candidate

func _eligible_archetypes(complexity: int) -> Array:
	var result: Array = ["addition", "subtraction", "multiplication", "sequence"]
	if complexity >= 2: result.append_array(["division", "missing_factor", "two_step"])
	if complexity >= 3: result.append_array(["order_operations", "fraction_of", "perimeter"])
	if complexity >= 4: result.append_array(["area", "proportion", "average"])
	if complexity >= 5: result.append_array(["percentage", "linear_equation", "data_reading"])
	if complexity >= 6: result.append_array(["negative_expression", "scale", "pythagoras"])
	if complexity >= 7: result.append_array(["powers_roots", "coordinate_slope", "inverse_chain"])
	if complexity >= 8: result.append_array(["quadratic_root", "weighted_average", "logic_chain"])
	return result

func _build_archetype(archetype: String, complexity: int, rng: RandomNumberGenerator, index: int) -> Dictionary:
	match archetype:
		"addition":
			var a := rng.randi_range(3, 12 + complexity * 7)
			var b := rng.randi_range(2, 10 + complexity * 6)
			return _node("calcolo", complexity, "Quanto fa %d + %d?" % [a, b], a + b, [a + b - 2, a + b + 2, a + b + 10], "%d + %d = %d." % [a, b, a + b], rng, index)
		"subtraction":
			var b := rng.randi_range(2, 8 + complexity * 3)
			var answer := rng.randi_range(3, 12 + complexity * 5)
			var a := answer + b
			return _node("calcolo", complexity, "Quanto fa %d - %d?" % [a, b], answer, [answer - 1, answer + 2, a + b], "Sottraendo %d da %d rimane %d." % [b, a, answer], rng, index)
		"multiplication":
			var a := rng.randi_range(2, mini(12, 4 + complexity * 2))
			var b := rng.randi_range(2, mini(12, 5 + complexity * 2))
			return _node("tabelline", complexity, "Quanto fa %d × %d?" % [a, b], a * b, [a * b - a, a * b + b, a + b], "%d gruppi da %d formano %d." % [a, b, a * b], rng, index)
		"sequence":
			var start := rng.randi_range(1, 15 + complexity * 3)
			var step := rng.randi_range(2, 4 + complexity)
			var answer := start + step * 4
			return _node("sequenze", complexity, "Completa la sequenza: %d, %d, %d, %d, ..." % [start, start + step, start + step * 2, start + step * 3], answer, [answer - step, answer + step, answer + 1], "La regola aggiunge sempre %d; il termine successivo è %d." % [step, answer], rng, index)
		"division":
			var divisor := rng.randi_range(2, mini(12, 4 + complexity))
			var answer := rng.randi_range(2, 7 + complexity * 2)
			var dividend := divisor * answer
			return _node("divisioni", complexity, "Quanto fa %d ÷ %d?" % [dividend, divisor], answer, [answer - 1, answer + divisor, divisor], "%d diviso in gruppi da %d produce %d gruppi." % [dividend, divisor, answer], rng, index)
		"missing_factor":
			var factor := rng.randi_range(2, mini(12, 4 + complexity))
			var answer := rng.randi_range(2, mini(12, 5 + complexity))
			return _node("tabelline", complexity, "Quale numero completa %d × ? = %d?" % [factor, factor * answer], answer, [answer - 1, answer + 1, factor], "Dividi %d per %d: il fattore mancante è %d." % [factor * answer, factor, answer], rng, index)
		"two_step":
			var a := rng.randi_range(3, 10 + complexity * 2)
			var b := rng.randi_range(2, 8 + complexity)
			var multiplier := rng.randi_range(2, 4)
			var answer := (a + b) * multiplier
			return _node("problemi", complexity, "Somma %d e %d, poi moltiplica il risultato per %d." % [a, b, multiplier], answer, [a + b * multiplier, a + b, answer - multiplier], "Prima %d + %d = %d; poi %d × %d = %d." % [a, b, a + b, a + b, multiplier, answer], rng, index)
		"order_operations":
			var a := rng.randi_range(2, 12)
			var b := rng.randi_range(2, 9)
			var c := rng.randi_range(2, 7)
			var answer := a + b * c
			return _node("espressioni", complexity, "Calcola rispettando le priorità: %d + %d × %d" % [a, b, c], answer, [(a + b) * c, answer - c, a * b + c], "Prima la moltiplicazione: %d × %d = %d; poi aggiungi %d." % [b, c, b * c, a], rng, index)
		"fraction_of":
			var denominator: int = [2, 3, 4, 5][rng.randi_range(0, 3)]
			var unit := rng.randi_range(2, 6 + complexity)
			var numerator := rng.randi_range(1, denominator - 1)
			var whole := denominator * unit
			var answer := numerator * unit
			return _node("frazioni", complexity, "Quanto vale %d/%d di %d?" % [numerator, denominator, whole], answer, [unit, answer + unit, whole - answer], "Un %d-esimo di %d vale %d; moltiplicando per %d ottieni %d." % [denominator, whole, unit, numerator, answer], rng, index)
		"perimeter":
			var width := rng.randi_range(3, 9 + complexity)
			var height := rng.randi_range(2, 8 + complexity)
			var answer := 2 * (width + height)
			return _node("geometria", complexity, "Un rettangolo misura %d m per %d m. Qual è il perimetro?" % [width, height], answer, [width * height, width + height, answer + 2], "Perimetro = 2 × (%d + %d) = %d m." % [width, height, answer], rng, index)
		"area":
			var width := rng.randi_range(3, 12 + complexity)
			var height := rng.randi_range(2, 9 + complexity)
			var answer := width * height
			return _node("geometria", complexity, "Una piattaforma rettangolare misura %d m × %d m. Qual è l'area?" % [width, height], answer, [2 * (width + height), answer - width, width + height], "Area = base × altezza = %d × %d = %d m²." % [width, height, answer], rng, index)
		"proportion":
			var unit_price := rng.randi_range(2, 8 + complexity)
			var quantity := rng.randi_range(3, 9 + complexity)
			var answer := unit_price * quantity
			return _node("proporzioni", complexity, "Ogni modulo costa %d crediti. Quanto costano %d moduli?" % [unit_price, quantity], answer, [unit_price + quantity, answer - unit_price, answer + quantity], "%d crediti per %d moduli: %d × %d = %d." % [unit_price, quantity, unit_price, quantity, answer], rng, index)
		"average":
			var center := rng.randi_range(8, 24 + complexity * 3)
			var delta := rng.randi_range(2, 7)
			return _node("statistica", complexity, "Qual è la media di %d, %d e %d?" % [center - delta, center, center + delta], center, [center - delta, center + delta, center * 3], "I valori sono simmetrici attorno a %d, quindi la media è %d." % [center, center], rng, index)
		"percentage":
			var percent: int = [10, 20, 25, 50][rng.randi_range(0, 3)]
			var base_unit := 10 if percent in [10, 20] else 4 if percent == 25 else 2
			var whole := base_unit * rng.randi_range(3, 12 + complexity)
			var answer := floori(float(whole * percent) / 100.0)
			return _node("percentuali", complexity, "Calcola il %d%% di %d." % [percent, whole], answer, [whole - answer, answer + base_unit, floori(float(whole * percent) / 10.0)], "%d%% di %d equivale a %d." % [percent, whole, answer], rng, index)
		"linear_equation":
			var answer := rng.randi_range(2, 8 + complexity)
			var coefficient := rng.randi_range(2, 5 + floori(float(complexity) / 2.0))
			var addend := rng.randi_range(2, 12)
			var total := coefficient * answer + addend
			return _node("equazioni", complexity, "Risolvi: %dx + %d = %d" % [coefficient, addend, total], answer, [answer + addend, total - addend, answer + coefficient], "Sottrai %d: %dx = %d. Dividi per %d: x = %d." % [addend, coefficient, total - addend, coefficient, answer], rng, index)
		"data_reading":
			var first := rng.randi_range(8, 22)
			var second := rng.randi_range(8, 22)
			var third := rng.randi_range(8, 22)
			var answer := maxi(first, maxi(second, third))
			return _node("dati", complexity, "Tre sensori leggono %d, %d e %d. Qual è il valore massimo?" % [first, second, third], answer, [mini(first, mini(second, third)), first + second + third, answer - 1], "Confrontando i tre dati, il maggiore è %d." % answer, rng, index)
		"negative_expression":
			var a := rng.randi_range(4, 15)
			var b := rng.randi_range(a + 2, a + 14)
			var c := rng.randi_range(2, 9)
			var answer := a - b + c
			return _node("numeri-relativi", complexity, "Calcola: %d - %d + %d" % [a, b, c], answer, [a - b - c, b - a + c, answer + 2], "%d - %d = %d; aggiungendo %d ottieni %d." % [a, b, a - b, c, answer], rng, index)
		"scale":
			var scale := rng.randi_range(3, 12)
			var map_length := rng.randi_range(2, 9)
			var answer := scale * map_length
			return _node("proporzioni", complexity, "Su una mappa 1 cm rappresenta %d km. Quanti km sono %d cm?" % [scale, map_length], answer, [scale + map_length, answer - scale, answer * 10], "%d cm × %d km/cm = %d km." % [map_length, scale, answer], rng, index)
		"pythagoras":
			var triple: Array = [[3, 4, 5], [5, 12, 13], [8, 15, 17]][rng.randi_range(0, 2)]
			return _node("geometria", complexity, "Un triangolo rettangolo ha cateti %d e %d. Quanto misura l'ipotenusa?" % [triple[0], triple[1]], triple[2], [triple[0] + triple[1], triple[2] - 1, triple[2] + 2], "%d² + %d² = %d², quindi l'ipotenusa è %d." % [triple[0], triple[1], triple[2], triple[2]], rng, index)
		"powers_roots":
			var base := rng.randi_range(3, 12)
			if rng.randf() < 0.5:
				return _node("potenze", complexity, "Quanto fa %d²?" % base, base * base, [base * 2, base * base - base, base * base + 1], "%d² = %d × %d = %d." % [base, base, base, base * base], rng, index)
			return _node("radici", complexity, "Qual è la radice quadrata di %d?" % (base * base), base, [base - 1, base + 1, base * 2], "Poiché %d × %d = %d, la radice è %d." % [base, base, base * base, base], rng, index)
		"coordinate_slope":
			var slope := rng.randi_range(1, 5)
			var dx := rng.randi_range(2, 6)
			var x1 := rng.randi_range(0, 4)
			var y1 := rng.randi_range(0, 6)
			var x2 := x1 + dx
			var y2 := y1 + slope * dx
			return _node("coordinate", complexity, "Qual è la pendenza tra A(%d,%d) e B(%d,%d)?" % [x1, y1, x2, y2], slope, [dx, y2 - y1, slope + 1], "Pendenza = Δy/Δx = %d/%d = %d." % [y2 - y1, dx, slope], rng, index)
		"inverse_chain":
			var start := rng.randi_range(3, 12)
			var multiplier := rng.randi_range(2, 5)
			var addend := rng.randi_range(2, 10)
			var result := start * multiplier + addend
			return _node("operazioni-inverse", complexity, "Un numero viene moltiplicato per %d e poi aumentato di %d, ottenendo %d. Qual era il numero?" % [multiplier, addend, result], start, [start + addend, floori(float(result) / float(multiplier)), start * multiplier], "Togli %d da %d e dividi per %d: (%d - %d) ÷ %d = %d." % [addend, result, multiplier, result, addend, multiplier, start], rng, index)
		"quadratic_root":
			var positive := rng.randi_range(2, 9)
			var other := rng.randi_range(1, 7)
			return _node("equazioni", complexity, "Una parabola ha zeri x = %d e x = -%d. Qual è lo zero positivo?" % [positive, other], positive, [-other, positive + other, positive * other], "Gli zeri sono già indicati: quello positivo è %d." % positive, rng, index)
		"weighted_average":
			var first := rng.randi_range(5, 9)
			var second := rng.randi_range(5, 9)
			var answer := floori(float(first + second * 2) / 3.0)
			# Rende intera la media pesata senza impoverire la struttura.
			second += posmod(first + second * 2, 3)
			answer = floori(float(first + second * 2) / 3.0)
			return _node("statistica", complexity, "Un test vale 1 parte e ha voto %d; un progetto vale 2 parti e ha voto %d. Qual è la media pesata?" % [first, second], answer, [floori(float(first + second) / 2.0), second, answer + 1], "Media pesata = (%d + 2×%d) ÷ 3 = %d." % [first, second, answer], rng, index)
		_:
			var a := rng.randi_range(5, 18)
			var multiplier := rng.randi_range(2, 5)
			var subtract := rng.randi_range(2, a - 1)
			var answer := a * multiplier - subtract
			return _node("problemi", complexity, "Un reattore moltiplica %d per %d e disperde %d unità. Quante ne restano?" % [a, multiplier, subtract], answer, [a * multiplier, answer + subtract, a + multiplier - subtract], "Prima %d × %d = %d; poi %d - %d = %d." % [a, multiplier, a * multiplier, a * multiplier, subtract, answer], rng, index)

func _node(topic: String, difficulty: int, prompt: String, answer: int, distractors: Array, explanation: String, rng: RandomNumberGenerator, index: int) -> Dictionary:
	var multiple_choice := rng.randf() < 0.76 or index == 0
	var options: Array = []
	if multiple_choice:
		var values: Array = [answer]
		for distractor in distractors:
			var value := int(distractor)
			if value != answer and not values.has(value):
				values.append(value)
		var delta := 1
		while values.size() < 4:
			if not values.has(answer + delta): values.append(answer + delta)
			delta += 1
		_shuffle(values, rng)
		for value in values.slice(0, 4): options.append(str(value))
	var signature := "%s|%s" % [topic, prompt]
	return {
		"id": "math-generated-%d-%d" % [difficulty, absi(signature.hash())],
		"subject": "matematica", "topic": topic, "difficulty": difficulty,
		"format": "multiple_choice" if multiple_choice else "numeric_input",
		"prompt": prompt, "options": options, "answer": str(answer),
		"explanation": explanation, "signature": signature,
	}

func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var swap = values[index]
		values[index] = values[other]
		values[other] = swap
