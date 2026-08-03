extends SceneTree

## `mystery_audit.gd` di `docs/TRAMA_E_MISTERO.md` §11, parte contenuti.
##
## Verifica le tre cose che rendono onesto un mistero, e che si rompono in
## silenzio mentre si scrive:
##
## 1. **Ogni colpo ha almeno tre semi nei mondi precedenti** (§10.7). È la
##    differenza fra una rivelazione e un colpo di mano. Chi rigioca deve poter
##    dire «era lì e non l'ho visto», mai «non era lì»;
## 2. **Nessun testo dice che qualcuno è morto** (§10.1) — nemmeno di sfuggita,
##    nemmeno nel passato. Il controllo capisce le negazioni: «nessuno è morto
##    qui» è esattamente la frase che il gioco *deve* poter dire;
## 3. **Niente blocca il loop** (§10.2): le Tracce decisive hanno un beat di
##    ripiego, così chi non entra in nessuna Rovina capisce il finale lo stesso.
##
## Quello che questo audit **non** controlla è la geometria: che le Tracce stiano
## fuori da `safeRadius` e dalla `safeRoute` lo verifica `world_life_audit`, che
## ha accesso alle posizioni. Qui si controlla il testo.

const MIN_SEMI := 3
const MIN_TIPI_SEME := 2      # semi tutti dello stesso tipo si leggono come una lista
const MAX_SCHERMATE := 3
const MAX_CARATTERI := 300    # ~4 righe piene su schermo stretto (§10.2)
const TRACCE_DECISIVE := 3

## §10.1. Ogni termine è ammesso solo se negato: la lista non vieta la parola,
## vieta l'affermazione.
const MORTE := [
	"è morto", "e morto", "è morta", "e morta", "sono morti", "sono morte",
	"morire", "ucciso", "uccisa", "uccidere", "defunt", "cadavere",
	"perduto per sempre", "perduta per sempre",
]
const NEGAZIONI := ["non ", "nessuno ", "nessuna ", "né ", "ne ", "mai "]

func _init() -> void:
	var failures: Array = []
	print("Il mistero — semi, Tracce, e nessuno che muore\n")

	failures.append_array(_check_colpi())
	failures.append_array(_check_tracce())
	failures.append_array(_check_beats())

	if not failures.is_empty():
		printerr("MISTERO NON VALIDO — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("\nMystery audit OK — ogni colpo ha i suoi semi, nessuno muore, niente blocca il loop")
	quit(0)

func _check_colpi() -> Array:
	var out: Array = []
	var colpi := MysteryCatalog.colpi_ordinati()
	if colpi.size() != 7:
		out.append("i colpi sono %d, il documento ne prevede 7" % colpi.size())

	var previous_world := 0
	var numeri: Dictionary = {}
	for colpo in colpi:
		var colpo_id := str(colpo["id"])
		var world := int(colpo["world"])
		var numero := int(colpo["numero"])
		if numeri.has(numero):
			out.append("due colpi hanno il numero %d" % numero)
		numeri[numero] = true
		if world < 1 or world > 24:
			out.append("colpo %d: mondo %d fuori dalla campagna" % [numero, world])
		if world <= previous_world:
			out.append("colpo %d cade al mondo %d, non dopo il precedente (%d): l'ordine è parte del contratto" % [
				numero, world, previous_world])
		previous_world = world

		var semi := MysteryCatalog.seeds_of(colpo_id)
		var prima: Array = []
		var tipi: Dictionary = {}
		for seme in semi:
			var seme_world := int(seme["world"])
			if seme_world >= world:
				out.append("colpo %d: il seme del mondo %d non precede il colpo (mondo %d)" % [
					numero, seme_world, world])
			else:
				prima.append(seme_world)
			tipi[str(seme.get("dove", ""))] = true
			if str(seme.get("cosa", "")).strip_edges() == "":
				out.append("colpo %d: un seme è vuoto" % numero)
			out.append_array(_check_morte("seme del colpo %d" % numero, str(seme.get("cosa", ""))))
		if prima.size() < MIN_SEMI:
			out.append("colpo %d «%s»: %d semi nei mondi precedenti, minimo %d — arriverebbe come un colpo di mano" % [
				numero, str(colpo["titolo"]), prima.size(), MIN_SEMI])
		if tipi.size() < MIN_TIPI_SEME:
			out.append("colpo %d: i semi sono tutti dello stesso tipo (%s): si leggono come una lista" % [
				numero, ", ".join(PackedStringArray(tipi.keys()))])
		if str(colpo.get("riscrive", "")).strip_edges() == "":
			out.append("colpo %d: non dichiara cosa riscrive all'indietro" % numero)
		if str(colpo.get("domanda", "")).strip_edges() == "":
			out.append("colpo %d: non lascia una domanda nuova" % numero)

		print("colpo %d · mondo %-3d %-42s semi: %d (mondi %s)" % [
			numero, world, str(colpo["titolo"]), prima.size(),
			", ".join(PackedStringArray(prima.map(func(w): return str(w))))])
	return out

func _check_tracce() -> Array:
	var out: Array = []
	print("")
	for world in range(1, 25):
		var traccia := MysteryCatalog.traccia_for(world)
		if traccia.is_empty():
			out.append("mondo %d: nessuna Traccia nella Rovina" % world)
			continue
		var testo: Array = traccia.get("testo", [])
		if testo.is_empty() or testo.size() > MAX_SCHERMATE:
			out.append("Traccia %d: %d schermate, ammesse 1-%d" % [
				world, testo.size(), MAX_SCHERMATE])
		for screen in testo:
			var text := str(screen)
			if text.strip_edges() == "":
				out.append("Traccia %d: schermata vuota" % world)
			if text.length() > MAX_CARATTERI:
				out.append("Traccia %d: schermata di %d caratteri, massimo %d — non ci sta e va letta, non recitata" % [
					world, text.length(), MAX_CARATTERI])
			out.append_array(_check_morte("Traccia %d" % world, text))
		if str(traccia.get("oggetto", "")).strip_edges() == "":
			out.append("Traccia %d: senza oggetto — una Traccia è una cosa, non un testo che fluttua" % world)

		# Se porta un colpo, dev'essere un colpo vero e cadere nel mondo giusto.
		var colpo_id := str(traccia.get("colpo", ""))
		if colpo_id != "":
			if not MysteryCatalog.COLPI.has(colpo_id):
				out.append("Traccia %d: dichiara il colpo «%s», che non esiste" % [world, colpo_id])
			elif int((MysteryCatalog.COLPI[colpo_id] as Dictionary).get("world", 0)) != world:
				out.append("Traccia %d: porta un colpo che cade al mondo %d" % [
					world, int((MysteryCatalog.COLPI[colpo_id] as Dictionary).get("world", 0))])

		# Le decisive devono avere il ripiego: senza, la Rovina diventa obbligatoria.
		if bool(traccia.get("decisiva", false)):
			if str(traccia.get("ripiego", "")).strip_edges() == "":
				out.append("Traccia %d è decisiva e non ha beat di ripiego: renderebbe obbligatoria la Rovina" % world)
			else:
				out.append_array(_check_morte("ripiego %d" % world, str(traccia["ripiego"])))
		elif traccia.has("ripiego"):
			out.append("Traccia %d ha un ripiego e non è decisiva: o è decisiva, o il ripiego è di troppo" % world)

	var decisive := MysteryCatalog.tracce_decisive()
	if decisive.size() != TRACCE_DECISIVE:
		out.append("le Tracce decisive sono %d, il documento ne prevede %d" % [
			decisive.size(), TRACCE_DECISIVE])
	print("Tracce: %d su 24 · decisive con ripiego: %s" % [
		MysteryCatalog.TRACCE.size(),
		", ".join(PackedStringArray(decisive.map(func(w): return str(w))))])
	return out

func _check_beats() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for level in range(1, 25):
		if not NarrativeManager.BEATS.has(level):
			out.append("manca il beat del mondo %d" % level)
			continue
		var text := str(NarrativeManager.BEATS[level])
		if text.strip_edges() == "":
			out.append("beat %d vuoto" % level)
		if not text.begins_with("NORA:"):
			out.append("beat %d: prefisso diverso da «NORA:» — cambia il contratto" % level)
		if seen.has(text):
			out.append("beat %d identico a quello del mondo %d" % [level, int(seen[text])])
		seen[text] = level
		out.append_array(_check_morte("beat %d" % level, text))

	var final_beat := str(NarrativeManager.FINAL_BEAT)
	out.append_array(_check_morte("beat finale", final_beat))
	# §10.4: che siano vive lo deve dire il gioco, esplicitamente, prima dei titoli.
	if not final_beat.to_lower().contains("vive"):
		out.append("il beat finale non dice esplicitamente che le undici e Meridiana sono vive (§10.4)")
	print("\nbeat: %d su 24, nessuno ripetuto · il beat finale le dichiara vive" % NarrativeManager.BEATS.size())
	return out

## Il termine è vietato solo se **affermato**. Guardo le venti battute prima:
## se c'è una negazione, la frase sta dicendo il contrario ed è quella giusta.
func _check_morte(where: String, text: String) -> Array:
	var out: Array = []
	var lower := text.to_lower()
	for term in MORTE:
		var from := 0
		while true:
			var at := lower.find(term, from)
			if at < 0:
				break
			from = at + 1
			var before := lower.substr(maxi(0, at - 20), mini(20, at))
			var negato := false
			for negazione in NEGAZIONI:
				if before.contains(negazione):
					negato = true
					break
			if not negato:
				out.append("%s: dice che qualcuno è morto («%s») — vietato da §10.1" % [where, term])
	return out
