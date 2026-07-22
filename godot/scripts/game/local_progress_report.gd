class_name LocalProgressReport
extends RefCounted

## Report locale persistito nel save canonico quando viene fornito un manager.
## Non effettua mai rete o telemetria remota.

var events: Array = []
var save: GameSaveManager

func setup(save_manager: GameSaveManager) -> void:
	save = save_manager
	if not save.data.has("progressReport"):
		save.data["progressReport"] = {"events": []}
	events = Array(save.data["progressReport"].get("events", [])).duplicate(true)

func record(level: int, subject: String, mastery: float, missions: int, seconds: float) -> void:
	events.append({"level": level, "subject": subject, "mastery": clampf(mastery, 0.0, 1.0), "missions": maxi(0, missions), "seconds": maxf(0.0, seconds)})
	if save != null:
		save.data["progressReport"] = {"events": events.duplicate(true)}

func summary() -> Dictionary:
	var total_seconds := 0.0
	var total_missions := 0
	for event in events:
		total_seconds += float(event.get("seconds", 0.0))
		total_missions += int(event.get("missions", 0))
	return {"sessions": events.size(), "missions": total_missions, "seconds": total_seconds, "events": events.duplicate(true)}
