class_name NarrativeManager
extends RefCounted

## Narrazione locale data-driven: nessun blocco del loop didattico.

const BEATS := {
	1: "NORA: La Radura Accademia è il primo passo. Ogni esercizio accende una parte della nave.",
	2: "NORA: Il Nucleo risponde. La tua costanza trasforma energia in conoscenza.",
	3: "NORA: Le mappe della Dorsale mostrano nuove rotte: osserva, prova, ricorda.",
	4: "NORA: Anche l'errore è un segnale. Riprova con una strategia diversa.",
	5: "NORA: Le materie si sostengono a vicenda: il sapere è una rete.",
	6: "NORA: Il prossimo apparato attende la tua padronanza.",
}

var save: GameSaveManager

func setup(save_manager: GameSaveManager) -> void:
	save = save_manager
	if not save.data.has("narrative"):
		save.data["narrative"] = {"seen": [], "beats": {}}

func beat_for_level(level: int) -> String:
	return str(BEATS.get(clampi(level, 1, 6), BEATS[6]))

func reveal_level(level: int) -> Dictionary:
	var key := str(clampi(level, 1, 6))
	var narrative: Dictionary = save.data["narrative"]
	var seen: Array = narrative.get("seen", [])
	var is_new := not seen.has(key)
	if is_new:
		seen.append(key)
		narrative["seen"] = seen
	var beats: Dictionary = narrative.get("beats", {})
	beats[key] = beat_for_level(level)
	narrative["beats"] = beats
	return {"level": level, "text": beat_for_level(level), "new": is_new}
