extends SceneTree

## Sonda (non un audit): che FORMA hanno le sessioni di pratica, materia per
## materia e livello per livello. Serve a rispondere a «i minigiochi sono
## abbastanza vari?» con una sequenza vera invece che con un'impressione.

const SUBJECTS := [
	"matematica", "italiano", "coding", "inglese", "fisica", "musica",
	"latino", "elettronica", "geografia", "scienze", "storia", "logica",
]

func _init() -> void:
	var mg := MinigameManager.new()
	print("Forma delle sessioni di pratica — 6 estrazioni per materia e livello\n")
	print("%-13s %-6s %s" % ["MATERIA", "LIV", "sequenze osservate"])
	var forme_globali: Dictionary = {}
	for subject in SUBJECTS:
		for livello in [1, 8, 16, 24]:
			var forme: Dictionary = {}
			for seme in range(6):
				var rng := RandomNumberGenerator.new()
				rng.seed = seme * 977 + livello
				var sessione := mg.build_minigame(subject, livello, rng)
				var seq: Array = []
				for nodo in Array(sessione.get("nodes", [])):
					seq.append(str((nodo as Dictionary).get("format", "?")))
				var chiave := " ".join(PackedStringArray(seq))
				forme[chiave] = int(forme.get(chiave, 0)) + 1
				forme_globali[chiave] = int(forme_globali.get(chiave, 0)) + 1
			var righe: Array = []
			for k in forme.keys():
				righe.append("%s (x%d)" % [str(k), int(forme[k])])
			print("%-13s %-6d %s" % [subject, livello, " | ".join(PackedStringArray(righe))])

	print("\nForme distinte in tutto il gioco: %d" % forme_globali.size())
	# Quante campate sono uguali in ogni forma?
	var prime_tre: Dictionary = {}
	for chiave in forme_globali.keys():
		var pezzi := str(chiave).split(" ")
		var testa: Array = []
		for i in mini(3, pezzi.size()):
			testa.append(pezzi[i])
		var t := " ".join(PackedStringArray(testa))
		prime_tre[t] = int(prime_tre.get(t, 0)) + int(forme_globali[chiave])
	print("\nAperture (prime tre campate) e quante sessioni le usano:")
	for k in prime_tre.keys():
		print("  %-46s %d" % [str(k), int(prime_tre[k])])
	quit(0)
