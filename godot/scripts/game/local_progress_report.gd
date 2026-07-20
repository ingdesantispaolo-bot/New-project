class_name LocalProgressReport
extends RefCounted

## Report locale in memoria: il chiamante può persisterlo nel save, mai inviarlo
## a servizi remoti.

var events: Array = []

func record(level: int, subject: String, mastery: float, missions: int, seconds: float) -> void:
	events.append({"level": level, "subject": subject, "mastery": clampf(mastery, 0.0, 1.0), "missions": maxi(0, missions), "seconds": maxf(0.0, seconds)})

func summary() -> Dictionary:
	var total_seconds := 0.0
	var total_missions := 0
	for event in events:
		total_seconds += float(event.get("seconds", 0.0))
		total_missions += int(event.get("missions", 0))
	return {"sessions": events.size(), "missions": total_missions, "seconds": total_seconds, "events": events.duplicate(true)}
