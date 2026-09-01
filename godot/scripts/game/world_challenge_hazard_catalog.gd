class_name WorldChallengeHazardCatalog
extends RefCounted

## Un pericolo dominante per ciascun mondo. L'identita' e' autorata; materia e
## gesto sono trasversali: matematica nei mondi dispari, italiano nei pari.
## `format` e' un desiderio. Se a quel livello il formato non ha ancora
## abbastanza contenuto, `challenge` sceglie deterministicamente un gesto
## realmente disponibile invece di aprire una prova vuota.

const ENTRIES := [
	{"name": "Cerchio delle quantità", "description": "Le pietre cambiano numero a ogni impulso.", "format": "balance"},
	{"name": "Frase rampicante", "description": "Le parole si avvolgono finché la frase perde senso.", "format": "compose"},
	{"name": "Frana dei passi", "description": "La sequenza sbagliata fa cedere il bordo del cratere.", "format": "machine_path"},
	{"name": "Nebbia dei verbi", "description": "I segnali confondono azioni, tempi e persone.", "format": "verb_decoder"},
	{"name": "Binario delle misure", "description": "Le rotaie si allineano soltanto confrontando le grandezze.", "format": "number_line"},
	{"name": "Eco delle frasi", "description": "Il giardino ripete frammenti che vanno ricomposti.", "format": "clue"},
	{"name": "Mosaico delle frazioni", "description": "I glifi dividono ogni figura in parti incompatibili.", "format": "matching"},
	{"name": "Scarica dei periodi", "description": "Il circuito separa soggetto, verbo e completamenti.", "format": "classification"},
	{"name": "Rotta delle coordinate", "description": "Una corrente cancella scale e punti di riferimento.", "format": "graph"},
	{"name": "Spore degli accenti", "description": "Il polline sposta accenti e cambia il suono delle parole.", "format": "swipe"},
	{"name": "Clessidra delle operazioni", "description": "Gli strati scorrono nell'ordine sbagliato.", "format": "ordering"},
	{"name": "Regola spezzata", "description": "Il labirinto obbedisce soltanto a una frase ben costruita.", "format": "compose"},
	{"name": "Orbita delle proporzioni", "description": "Le dune deviano tutto ciò che non resta in rapporto.", "format": "balance"},
	{"name": "Coro dei connettivi", "description": "Le voci si contraddicono finché i legami non sono corretti.", "format": "matching"},
	{"name": "Rete dei calcoli", "description": "Ogni risultato errato riaccende un nodo della città.", "format": "machine_path"},
	{"name": "Varco dei verbi", "description": "Le insegne cambiano tempo prima di poterle leggere.", "format": "verb_decoder"},
	{"name": "Corrente delle frazioni", "description": "La pressione cresce quando le parti non sono equivalenti.", "format": "number_line"},
	{"name": "Riverbero delle frasi", "description": "Ogni parola fuori posto ritorna come un'onda.", "format": "clue"},
	{"name": "Sigillo dei rapporti", "description": "Le radici si stringono attorno a quantità non confrontate.", "format": "matching"},
	{"name": "Campo delle concordanze", "description": "La tempesta separa parole che dovrebbero concordare.", "format": "classification"},
	{"name": "Faglia delle scale", "description": "L'atlante si spezza fra misure che usano scale diverse.", "format": "graph"},
	{"name": "Polline dei periodi", "description": "La biosfera assorbe le frasi lasciate incomplete.", "format": "compose"},
	{"name": "Cronometro dei rapporti", "description": "Le ere si sovrappongono finché i valori non tornano in ordine.", "format": "ordering"},
	{"name": "Eco della sintesi", "description": "Il Cuore mescola azioni e significati di tutti i mondi.", "format": "verb_decoder"},
]

static func challenge(level: int) -> Dictionary:
	var index := clampi(level, 1, ENTRIES.size()) - 1
	var out: Dictionary = Dictionary(ENTRIES[index]).duplicate(true)
	var subject := "matematica" if level % 2 == 1 else "italiano"
	var available := MinigameManager.runtime_formats_for(subject, level)
	var desired := str(out.get("format", ""))
	if not available.has(desired):
		assert(not available.is_empty(), "nessun minigioco %s disponibile al mondo %d" % [subject, level])
		desired = str(available[posmod(level * 5 + 1, available.size())])
	out["id"] = "world-danger-%02d" % level
	out["level"] = level
	out["subject"] = subject
	out["format"] = desired
	out["challengeLevel"] = level
	out["threatTier"] = clampi(1 + int(floor(float(level - 1) / 5.0)), 1, 5)
	# Il contatto deve farsi sentire, ma non puo' togliere energia che non c'e':
	# la scena applica sempre `min(costo, energia corrente)`.
	out["contactCost"] = 2 + int(ceil(float(level) / 4.0))
	out["failureCost"] = 2 + int(floor(float(level - 1) / 5.0))
	out["failureSurgeSeconds"] = 8.0 + float(out["threatTier"]) * 1.6
	out["rewardFragments"] = FragmentEconomy.premio_pericolo(int(out["threatTier"]))
	out["sigilId"] = "sigillo-mondo-%02d" % level
	out["sigilName"] = "Sigillo · %s" % str(out["name"])
	var conquest := RewardCatalog.conquest_for_world(level)
	out["conquestRewardId"] = str(conquest.get("id", ""))
	out["conquestRewardName"] = str(conquest.get("name", ""))
	out["color"] = Color("63e6ff") if subject == "matematica" else Color("d9a6ff")
	out["action"] = "Ricomponi il ritmo dei numeri." if subject == "matematica" \
		else "Rimetti le parole nella loro forma corretta."
	return out

static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in range(1, ENTRIES.size() + 1):
		out.append(challenge(level))
	return out
