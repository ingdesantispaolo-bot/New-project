extends SceneTree

## **Le tavole d'inglese sono raggiungibili?** (8 settembre 2026)
##
## Il difetto ricorrente di questo progetto è il contenuto scritto e mai
## collegato: dati corretti, audit verde, e nessun lettore fuori dagli audit.
## Sei tavole nuove valgono zero se nessuna risposta del banco le tocca.
##
## Qui si simula quello che fa `KnowledgeCodex.recall_fact`: si prende la
## risposta di ogni item d'inglese, la si tratta da etichetta e si chiede a
## `TavoleRiferimento.trova` se quella etichetta sta su una casella. Un argomento
## con una tavola dichiarata e zero risposte raggiunte è una tavola morta.
##
## Uso: godot --headless --path godot --script res://scripts/game/inglese_tavole_probe.gd

func _init() -> void:
	var cm := ContentManager.new()
	var per_topic: Dictionary = {}
	for entry in cm._load_bank("inglese"):
		var item := entry as Dictionary
		var topic := str(item.get("topic", ""))
		var risposta := str(item.get("answer", "")).strip_edges()
		if risposta == "" or risposta.split(" ", false).size() > 3:
			continue
		var stato: Dictionary = per_topic.get(topic, {"con_tavola": 0, "raggiunte": 0, "totali": 0})
		stato["totali"] = int(stato["totali"]) + 1
		if TavoleRiferimento.ha_tavola("inglese", topic):
			stato["con_tavola"] = 1
			if not TavoleRiferimento.trova("inglese", topic, risposta).is_empty():
				stato["raggiunte"] = int(stato["raggiunte"]) + 1
		per_topic[topic] = stato

	var morte: Array = []
	var chiavi := per_topic.keys()
	chiavi.sort()
	print("%-22s %8s %10s" % ["ARGOMENTO", "risposte", "su tavola"])
	for topic in chiavi:
		var stato: Dictionary = per_topic[topic]
		if int(stato["con_tavola"]) == 0:
			continue
		print("%-22s %8d %10d" % [str(topic), int(stato["totali"]), int(stato["raggiunte"])])
		if int(stato["raggiunte"]) == 0:
			morte.append(str(topic))

	if not morte.is_empty():
		push_error("TAVOLE INGLESE: %d argomenti hanno una tavola che nessuna risposta raggiunge: %s" % [
			morte.size(), ", ".join(morte)])
		quit(1)
		return
	print("\nTAVOLE INGLESE probe VERDE")
	quit(0)
