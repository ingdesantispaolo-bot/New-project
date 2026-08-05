extends SceneTree

## **Dopo la risposta il gioco dice perché, non cosa fare.** (5 agosto 2026)
##
## Il difetto che questo audit rende impossibile ripetere: i tre formati
## dominanti — abbinamento, ordinamento, classificazione — coprivano il **62% di
## tutto quello che un bambino gioca** e non spiegavano niente.
##
## - abbinamento (22%): «Collega ogni elemento a sinistra con quello giusto a
##   destra» — la stessa identica stringa in ogni materia e in ogni mondo;
## - classificazione (20%): «Ogni tessera va nel gruppo giusto secondo la sua
##   proprietà» — idem;
## - ordinamento (20%): «Ordine giusto: A, B, C» — che ripete la risposta.
##
## Le prime due erano **istruzioni su come si gioca**, mostrate dopo che il
## bambino aveva già giocato. La terza diceva *cosa*, mai *perché quello*.
##
## Il controllo che conta è il terzo qui sotto: una spiegazione ripetuta identica
## su specifiche diverse è il sintomo esatto della malattia. Se un giorno
## qualcuno rimettesse una stringa sola per tutto il formato, questo audit
## diventerebbe rosso alla prima esecuzione.

## Sotto questa soglia non è una spiegazione: è un'etichetta. Le istruzioni
## rimosse stavano fra i 58 e i 62 caratteri, quindi la lunghezza da sola non
## basta — serve insieme al controllo sui duplicati.
const MIN_CARATTERI := 40

const TABELLE := ["MATCHING", "ORDERING", "CLASSIFICATION"]

func _init() -> void:
	var failures: Array = []
	var mg := MinigameManager.new()
	var viste: Dictionary = {}   # testo -> prima specifica che l'ha usato

	for nome in TABELLE:
		var tabella: Dictionary = mg.get(nome)
		var quante := 0
		var corte := 0
		for materia in tabella.keys():
			for spec_data in Array(tabella[materia]):
				var spec := spec_data as Dictionary
				quante += 1
				var etichetta := "%s/%s/%s" % [nome, str(materia), str(spec.get("topic", "?"))]
				var testo := str(spec.get("explanation", "")).strip_edges()

				if testo == "":
					failures.append("%s: nessuna spiegazione" % etichetta)
					continue
				if testo.length() < MIN_CARATTERI:
					corte += 1
					failures.append("%s: spiegazione di %d caratteri, sotto i %d minimi" % [
						etichetta, testo.length(), MIN_CARATTERI])
				# Il controllo che vale: la stessa frase su due specifiche diverse
				# significa che non spiega quella specifica, spiega il formato.
				if viste.has(testo):
					failures.append("%s: spiegazione identica a %s — se vale per entrambe non spiega nessuna delle due" % [
						etichetta, str(viste[testo])])
				else:
					viste[testo] = etichetta
		print("%-16s specifiche %3d · sotto soglia %d" % [nome, quante, corte])

	# --- La prova che conta: arriva davvero al giocatore? ---------------------
	# Una tabella perfetta che il costruttore ignora vale quanto una spiegazione
	# assente. Qui si costruiscono nodi veri e si guarda cosa esce.
	var vietate := [
		"Collega ogni elemento a sinistra con quello giusto a destra.",
		"Ogni tessera va nel gruppo giusto secondo la sua proprietà.",
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var controllati := 0
	for materia in ["matematica", "italiano", "inglese", "scienze", "logica", "musica"]:
		for livello in [3, 12, 22]:
			var sessione := mg.build_minigame(materia, livello, rng)
			for nodo_data in Array(sessione.get("nodes", [])):
				var nodo := nodo_data as Dictionary
				var fmt := str(nodo.get("format", ""))
				if not fmt in ["matching", "ordering", "classification"]:
					continue
				controllati += 1
				var testo := str(nodo.get("explanation", "")).strip_edges()
				if testo == "":
					failures.append("nodo giocato %s/%s senza spiegazione" % [materia, fmt])
				elif vietate.has(testo):
					failures.append("nodo giocato %s/%s: è tornata l'istruzione generica" % [materia, fmt])
				elif fmt == "ordering" and testo.begins_with("Ordine giusto:"):
					failures.append("nodo giocato %s/ordering: solo l'elenco, nessun criterio" % materia)
	print("\nnodi giocati controllati: %d" % controllati)
	if controllati < 20:
		failures.append("troppi pochi nodi controllati (%d): il campione non prova niente" % controllati)

	if failures.is_empty():
		print("Minigame explanation audit OK — %d spiegazioni distinte, nessuna generica nei nodi giocati" % viste.size())
		quit(0)
	else:
		print("\nSPIEGAZIONI ROSSE — %d problemi:" % failures.size())
		for f in failures.slice(0, 25):
			print("  - %s" % f)
		quit(1)
