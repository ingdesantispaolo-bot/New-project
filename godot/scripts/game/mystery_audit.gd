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
	failures.append_array(_check_sbiadito())
	failures.append_array(_check_conta())
	failures.append_array(_check_sorelle())
	failures.append_array(_check_confronto())
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
			# Un seme è **una** schermata di dialogo: se non ci sta, non si legge.
			# Non era controllato, e le Tracce accanto lo erano già.
			out.append_array(_check_schermata(
				"seme del mondo %d (colpo %d)" % [seme_world, numero], str(seme.get("cosa", ""))))
			var eli_line := str(seme.get("eli", "")).strip_edges()
			if eli_line != "":
				out.append_array(_check_morte("riga di Eli al mondo %d" % seme_world, eli_line))
				out.append_array(_check_schermata("riga di Eli al mondo %d" % seme_world, eli_line))
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

## Lo Sbiadito che ripete NORA: **uno solo**, mai spiegato, e la frase deve
## essere davvero una che il giocatore ha già sentito.
func _check_sbiadito() -> Array:
	var out: Array = []
	var s := MysteryCatalog.SBIADITO_RICONOSCIBILE as Dictionary
	var world := int(s.get("world", 0))
	var frase := str(s.get("frase", "")).strip_edges()
	if frase == "":
		out.append("lo Sbiadito riconoscibile non ha una frase")
	if bool(s.get("commentato", true)):
		out.append("lo Sbiadito riconoscibile è commentato: diventerebbe un indizio da seguire invece di un ricordo")
	if world < 12 or world > 23:
		out.append("lo Sbiadito riconoscibile sta al mondo %d: troppo presto per pesare, o troppo tardi per essere ricordato al 24" % world)

	# La frase deve venire davvero da un beat che il giocatore ha sentito prima.
	var trovata := 0
	var da_quale := 0
	for level in NarrativeManager.BEATS.keys():
		if str(NarrativeManager.BEATS[level]).contains(frase):
			trovata += 1
			da_quale = int(level)
	if trovata == 0:
		out.append("«%s» non compare in nessun beat: il giocatore non l'ha mai sentita da NORA" % frase)
	elif da_quale >= world:
		out.append("«%s» viene dal beat del mondo %d, ma lo Sbiadito sta al %d: si sentirebbe l'eco prima della voce" % [
			frase, da_quale, world])
	else:
		print("Sbiadito al mondo %d: ripete una frase del beat %d — «%s»" % [world, da_quale, frase])
	return out

## La conta di nonna Ersilia è la chiave del mondo 24 e non può sentirsi una
## volta sola: se un bambino salta quel dialogo, il finale resta senza serratura.
func _check_conta() -> Array:
	var out: Array = []
	var occorrenze := NpcCatalog.conta_occurrences()
	if occorrenze < 3:
		out.append("le tre sillabe si sentono in %d punti: troppo pochi per una chiave che serve venti mondi dopo" % occorrenze)

	var sillabe: Array = (NpcCatalog.CONTA_ERSILIA as Dictionary).get("sillabe", [])
	var mondi: Array = []
	for entry in NpcCatalog.RIAFFIORAMENTI_CONTA:
		var eco := entry as Dictionary
		var testo := str(eco.get("testo", "")).to_lower()
		mondi.append(int(eco.get("world", 0)))
		for sillaba in sillabe:
			if not testo.contains(str(sillaba)):
				out.append("il riaffioramento del mondo %d non contiene la sillaba «%s»" % [
					int(eco.get("world", 0)), str(sillaba)])
		# Se qualcuno spiega la conta, l'enigma del nome è già risolto.
		if bool(eco.get("spiegato", true)):
			out.append("il riaffioramento del mondo %d è spiegato: risolverebbe l'enigma al posto del giocatore" % int(eco.get("world", 0)))
		if str(eco.get("dove", "")).strip_edges() == "":
			out.append("un riaffioramento non dice dove accade")

	# Distribuiti, non ammucchiati: uno per atto almeno.
	mondi.sort()
	if not mondi.is_empty() and int(mondi[mondi.size() - 1]) - int(mondi[0]) < 6:
		out.append("i riaffioramenti stanno tutti a %d mondi di distanza: vanno distribuiti lungo la campagna" % (
			int(mondi[mondi.size() - 1]) - int(mondi[0])))
	print("conta: %d occorrenze (mondo 1 + riaffioramenti ai mondi %s), nessuna spiegata" % [
		occorrenze, ", ".join(PackedStringArray(mondi.map(func(w): return str(w))))])
	return out

## Le undici sorelle. Il filo regge se e solo se: sono undici, stanno **fra** il
## colpo 3 e il colpo 7 (prima non hanno senso, dopo arrivano tardi), sono una per
## mondo, e ognuna porta la materia del suo mondo — perché la risposta del finale
## («l'unica che tiene dodici modi di capire nella stessa testa») è vera solo se
## ciascuna ne teneva davvero uno solo.
func _check_sorelle() -> Array:
	var out: Array = []
	var sorelle: Array = SistersThread.SORELLE
	if sorelle.size() != 11:
		out.append("le sorelle sono %d, il colpo 7 ne dichiara undici" % sorelle.size())

	var numeri: Dictionary = {}
	var mondi: Dictionary = {}
	var nomi: Dictionary = {}
	# Un nome già preso da un abitante trasformerebbe una sorella in un cameo.
	var presi := _nomi_gia_usati()
	for raw in sorelle:
		var sorella: Dictionary = raw
		var numero := int(sorella.get("numero", 0))
		var world := int(sorella.get("world", 0))
		var nome := str(sorella.get("nome", "")).strip_edges()

		if numero < 1 or numero > 11:
			out.append("sorella «%s»: numero %d fuori da 1-11" % [nome, numero])
		if numeri.has(numero):
			out.append("due sorelle hanno il numero %d" % numero)
		numeri[numero] = true

		if world <= 12 or world >= 24:
			out.append("sorella %d «%s»: mondo %d — le tracce stanno fra il colpo 3 (12) e il colpo 7 (24)" % [
				numero, nome, world])
		if mondi.has(world):
			out.append("due sorelle nel mondo %d: una per mondo, o si leggono come una collezione" % world)
		mondi[world] = true

		if nome == "":
			out.append("sorella %d senza nome" % numero)
		if nomi.has(nome):
			out.append("due sorelle si chiamano %s" % nome)
		nomi[nome] = true
		if presi.has(nome.to_lower()):
			out.append("sorella %d si chiama %s, come un personaggio che il giocatore incontra davvero" % [
				numero, nome])

		var attesa := ApparatusConfig.world_subject(world)
		if str(sorella.get("materia", "")) != attesa:
			out.append("sorella %d «%s» al mondo %d porta «%s», ma quel mondo insegna «%s»" % [
				numero, nome, world, str(sorella.get("materia", "")), attesa])

		for campo in ["cosa", "eli"]:
			var testo := str(sorella.get(campo, "")).strip_edges()
			if testo == "":
				out.append("sorella %d «%s»: campo «%s» vuoto" % [numero, nome, campo])
				continue
			out.append_array(_check_morte("sorella %s (%s)" % [nome, campo], testo))
			out.append_array(_check_schermata("sorella %s (%s)" % [nome, campo], testo))

	# Le tracce devono arrivare nel mondo per la stessa strada dei semi: se
	# `tutti_i_semi` non le contiene, esistono solo su carta.
	var nei_semi := 0
	for seme in MysteryCatalog.tutti_i_semi():
		if str((seme as Dictionary).get("sorella", "")) != "":
			nei_semi += 1
	if nei_semi != sorelle.size():
		out.append("le sorelle sono %d ma i semi che le portano sono %d: non diventerebbero oggetti nel mondo" % [
			sorelle.size(), nei_semi])

	print("\nsorelle: %d, mondi %s, una materia ciascuna" % [
		sorelle.size(),
		", ".join(PackedStringArray(SistersThread.mondi().map(func(w): return str(w))))])
	out.append_array(_check_prima_meta(sorelle))
	return out

## **La prima metà ha una sorella anche lei.** (2 settembre 2026)
##
## `SistersThread` copre i mondi 13-23 e chiude benissimo la seconda metà. Nei
## mondi 1-11 restavano quattro semi che *provano* l'esistenza delle undici — un
## bollo di collaudo, una targhetta, una frase di Mirta — e le prove non fanno
## compagnia: per undici mondi la cosa più importante della vita di Eli era un
## indizio d'archivio, e lei non aveva una riga.
##
## Adesso la prima metà segue **l'undicesima**, quella immediatamente prima di
## Eli, il cui fascicolo al mondo 23 ha «l'inchiostro di poche settimane fa»:
## stessa strada, appena percorsa. Questo controllo tiene insieme le due metà —
## il nome dei segni deve essere quello dell'ultima sorella, non un personaggio
## nuovo — e pretende che Eli abbia una voce anche prima del colpo 3.
func _check_prima_meta(sorelle: Array) -> Array:
	var out: Array = []
	if sorelle.is_empty():
		return out
	var ultima: Dictionary = sorelle[sorelle.size() - 1]
	var nome := str(ultima.get("nome", ""))
	var mondi_toccati: Array = []
	var con_voce := 0
	var nomina_l_ultima := false
	for seme_data in MysteryCatalog.seeds_of("dodici-schede"):
		var seme: Dictionary = seme_data
		var world := int(seme.get("world", 0))
		if world <= 0 or world > 11:
			continue
		if not mondi_toccati.has(world):
			mondi_toccati.append(world)
		if str(seme.get("eli", "")).strip_edges() != "":
			con_voce += 1
		if nome != "" and str(seme.get("cosa", "")).contains(nome):
			nomina_l_ultima = true
	mondi_toccati.sort()
	if mondi_toccati.size() < 5:
		out.append("prima metà: solo %d mondi su 11 portano un segno di chi è passata prima di Eli" % mondi_toccati.size())
	if con_voce < 5:
		out.append("prima metà: solo %d di quei semi hanno una riga di Eli — prima del colpo 3 resterebbe muta" % con_voce)
	if not nomina_l_ultima:
		out.append("prima metà: nessun segno porta il nome dell'ultima sorella (%s): il filo non si chiude al mondo 23" % nome)
	# E il nome non può essere inventato: dev'essere una delle undici, altrimenti
	# la prima metà racconterebbe una dodicesima persona che non esiste.
	var nomi: Array = []
	for s in sorelle:
		nomi.append(str((s as Dictionary).get("nome", "")))
	for seme_data in MysteryCatalog.seeds_of("dodici-schede"):
		var seme: Dictionary = seme_data
		if int(seme.get("world", 0)) > 11:
			continue
		for parola in str(seme.get("cosa", "")).split(" "):
			var pulita := str(parola).strip_edges().trim_prefix("«").trim_suffix("»").trim_suffix(".").trim_suffix(",")
			if pulita.length() > 3 and pulita[0] == pulita[0].to_upper() and nomi.has(pulita) and pulita != nome:
				out.append("prima metà: un segno nomina %s, che non è l'ultima sorella" % pulita)
	print("prima metà: %d segni in %d mondi, %d con la voce di Eli, il nome è %s" % [
		MysteryCatalog.seeds_of("dodici-schede").filter(
			func(s): return int((s as Dictionary).get("world", 0)) <= 11).size(),
		mondi_toccati.size(), con_voce, nome])
	return out

## Il confronto del mondo 24. Le due cose che lo rendono quella scena e non un
## altro monologo: **Eli parla**, e parla per prima.
func _check_confronto() -> Array:
	var out: Array = []
	var scena: Array = SistersThread.CONFRONTO
	if scena.is_empty():
		out.append("il confronto del mondo 24 è vuoto")
		return out

	var voci: Dictionary = {}
	for raw in scena:
		var blocco: Dictionary = raw
		var chi := str(blocco.get("chi", ""))
		if chi != "eli" and chi != "nora":
			out.append("nel confronto parla «%s»: la scena è a due" % chi)
		voci[chi] = int(voci.get(chi, 0)) + 1
		var dice: Array = blocco.get("dice", [])
		if dice.is_empty():
			out.append("un blocco del confronto non dice niente")
		for riga in dice:
			var testo := str(riga).strip_edges()
			if testo == "":
				out.append("riga vuota nel confronto")
				continue
			out.append_array(_check_morte("confronto (%s)" % chi, testo))
			out.append_array(_check_schermata("confronto (%s)" % chi, testo))

	if int(voci.get("eli", 0)) == 0:
		out.append("nel confronto Eli non parla: è esattamente il difetto che la scena esiste per togliere")
	if str((scena[0] as Dictionary).get("chi", "")) != "eli":
		out.append("il confronto non lo apre Eli: la scena è sua, non un'altra confessione di NORA")

	print("confronto del mondo 24: %d blocchi · Eli %d, NORA %d" % [
		scena.size(), int(voci.get("eli", 0)), int(voci.get("nora", 0))])
	return out

## I nomi che il giocatore sente addosso a qualcuno di vivo e presente.
func _nomi_gia_usati() -> Dictionary:
	var out: Dictionary = {}
	for gruppo in [NpcCatalog.RESIDENTS, NpcCatalog.BISLACCHI, ItinerantCatalog.ITINERANTI]:
		for key in (gruppo as Dictionary).keys():
			var nome := str(((gruppo as Dictionary)[key] as Dictionary).get("nome", "")).strip_edges()
			if nome != "":
				out[nome.to_lower()] = true
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

## Una schermata è una schermata: §10.2 dà quattro righe, e oltre `MAX_CARATTERI`
## il testo o esce dal riquadro o diventa un muro che nessuno legge.
func _check_schermata(where: String, text: String) -> Array:
	if text.length() <= MAX_CARATTERI:
		return []
	return ["%s: %d caratteri, massimo %d — va letta, non recitata" % [
		where, text.length(), MAX_CARATTERI]]

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
