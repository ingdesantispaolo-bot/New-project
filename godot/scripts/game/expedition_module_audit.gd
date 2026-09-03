extends SceneTree

## **I moduli servono là fuori, mai dentro una domanda.** (14 agosto 2026)
##
## È la decisione vincolante 15, applicata all'unica cosa che la bottega vende
## oltre alla bellezza. Nel momento in cui un modulo sfiorasse una prova — un
## indizio comprabile, una seconda chance, un secondo in più — il gioco
## comincerebbe a vendere l'apprendimento, e lo farebbe in modo invisibile:
## nessuno degli altri audit se ne accorgerebbe, perché per loro sarebbe soltanto
## un cosmetico in più nel catalogo.
##
## Le sei cose che verifica:
##
## 1. **Ogni modulo esiste e si compra davvero**: sta nel catalogo, il possesso è
##    permanente, e la bottega ha una sezione che lo mostra. Un oggetto che
##    nessuna schermata elenca è un oggetto che non esiste.
## 2. **Ogni modulo fa qualcosa di misurabile.** Portato o no, un numero deve
##    cambiare — altrimenti è uno dei quattro upgrade bugiardi del 6 agosto con
##    un nome nuovo.
## 3. **La bardatura è una scelta** (2 settembre 2026). Si possiede tutto e si
##    porta poco: i posti sono meno dei moduli, non si sfondano, crescono con gli
##    apparati riparati, e **un modulo lasciato a bordo non fa niente pur essendo
##    posseduto**. È la riga che distingue una collezione da una decisione, ed è
##    la ragione per cui questa categoria esiste.
## 4. **Comprare un modulo non tocca l'apprendimento**: padronanza, copertura,
##    conteggi del gate ed energia restano quelli, tolto il prezzo.
## 5. **Nessun modulo è necessario.** Senza, tutto resta raggiungibile: la vista
##    delle sacche è piena, la spinta è quella di base, il passo è quello di
##    sempre, e non c'è nessun raggio che qualcuno debba comprare per vederci.
## 6. **I moduli non svuotano la bottega.** Costano insieme una frazione
##    dichiarata del catalogo: il sink estetico è tarato, e non c'è spazio per un
##    secondo rubinetto grosso.

const OK := "EXPEDITION MODULE audit VERDE"
const SHOP := preload("res://scripts/ui/outdoor_shop_panel.gd")

## Quanto possono pesare i moduli sul costo totale del catalogo. Misurato il
## 2 settembre 2026: 3.520 su 80.080, cioè il 4,4%. La soglia lascia spazio a un
## settimo modulo e prende chi volesse farne un secondo sink.
const QUOTA_MASSIMA_CATALOGO := 0.06

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

## Un salvataggio che **possiede** i moduli passati e li porta tutti in
## bardatura, per quanto ci stanno. È la forma normale: si compra e si porta.
func _save_con(moduli: Array, livello := 1) -> GameSaveManager:
	var save := GameSaveManager.new()
	save.set_level(livello)
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	cosmetics["inventory"] = moduli.duplicate()
	cosmetics["loadout"] = moduli.duplicate()
	save.data["cosmetics"] = cosmetics
	return save

## Un salvataggio che possiede i moduli e **non ne porta nessuno**: serve a
## distinguere il possesso dall'effetto, che è tutto il senso della bardatura.
func _save_a_bordo(moduli: Array, livello := 1) -> GameSaveManager:
	var save := _save_con(moduli, livello)
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	cosmetics["loadout"] = []
	save.data["cosmetics"] = cosmetics
	return save

func _init() -> void:
	_esistono_e_si_comprano()
	_fanno_qualcosa()
	_la_bardatura_e_una_scelta()
	_non_toccano_l_apprendimento()
	_nessuno_e_necessario()
	_non_svuotano_la_bottega()
	if errori.is_empty():
		print("%s — %d moduli, %d posti al primo mondo" % [
			OK, ExpeditionModules.ids().size(), ExpeditionModules.POSTI_BASE])
	else:
		printerr("EXPEDITION MODULE audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _esistono_e_si_comprano() -> void:
	_controlla(SHOP.SLOT_ORDER.has("module"),
		"la bottega non elenca la sezione dei moduli: sarebbero invisibili e quindi inesistenti")
	_controlla(SHOP.SLOT_LABELS.has("module") and SHOP.SLOT_META.has("module"),
		"la sezione dei moduli non ha titolo o descrizione in bottega")
	# La sezione della bottega e il catalogo devono contenere gli stessi moduli:
	# una voce con `slot: module` che [[ExpeditionModules]] non conosce sarebbe
	# comprabile e senza effetto, cioè esattamente il difetto del 6 agosto.
	var in_vetrina: Array = []
	for voce_data in RewardCatalog.CATALOG:
		if str(Dictionary(voce_data).get("slot", "")) == "module":
			in_vetrina.append(str(Dictionary(voce_data).get("id", "")))
	in_vetrina.sort()
	var dichiarati := ExpeditionModules.ids()
	dichiarati.sort()
	_controlla(in_vetrina == dichiarati,
		"la vetrina dei moduli e il catalogo degli effetti non coincidono: %s contro %s" % [
			str(in_vetrina), str(dichiarati)])
	for id_data in ExpeditionModules.ids():
		var id := str(id_data)
		var voce := RewardCatalog.find(id)
		_controlla(not voce.is_empty(), "il modulo «%s» non è nel catalogo della bottega" % id)
		if voce.is_empty():
			continue
		_controlla(str(voce.get("slot", "")) == "module",
			"il modulo «%s» sta nello slot «%s»" % [id, str(voce.get("slot", ""))])
		_controlla(int(voce.get("cost", 0)) > 0, "il modulo «%s» è gratuito" % id)
		_controlla(str(voce.get("description", "")).strip_edges() != ""
			and str(voce.get("origine", "")).strip_edges() != "",
			"il modulo «%s» non dice che cosa fa o da dove viene" % id)
		# Permanente: finisce nell'inventario, non in uno slot da sostituire.
		var save := _save_con([])
		var manager := RewardManager.new(save)
		save.add_energy(int(voce.get("cost", 0)) + 10)
		_controlla(manager.unlock_and_equip(id), "il modulo «%s» non si acquista" % id)
		var cosmetics: Dictionary = save.data.get("cosmetics", {})
		_controlla(Array(cosmetics.get("inventory", [])).has(id),
			"il modulo «%s» non risulta permanente dopo l'acquisto" % id)
		_controlla(not Dictionary(cosmetics.get("equipped", {})).values().has(id),
			"il modulo «%s» occupa uno slot: potrebbe essere sostituito e perso" % id)

## **Un modulo deve cambiare un numero.** È la regola che i quattro upgrade del
## 6 agosto non rispettavano: promettevano meccaniche e non toccavano niente.
##
## La tabella qui sotto è il contratto: id → lettura → confronto col valore base.
## Aggiungere un modulo senza aggiungere la sua riga rende rosso questo audit,
## ed è voluto — è l'unico posto in cui «l'ho scritto nel catalogo» e «fa
## qualcosa» smettono di essere la stessa frase.
func _misure() -> Array:
	return [
		{"id": ExpeditionModules.FELPA, "nome": "la vista delle sacche",
			"leggi": func(s): return ExpeditionModules.vista_delle_sacche(s),
			"base": ExpeditionModules.VISTA_PIENA, "verso": -1},
		{"id": ExpeditionModules.ZAVORRA, "nome": "lo spintone",
			"leggi": func(s): return ExpeditionModules.spinta_del_morso(s),
			"base": ExpeditionModules.SPINTA_PIENA, "verso": -1},
		{"id": ExpeditionModules.PASSO, "nome": "il passo",
			"leggi": func(s): return ExpeditionModules.passo(s),
			"base": ExpeditionModules.PASSO_BASE, "verso": 1},
		{"id": ExpeditionModules.RIFLETTORE, "nome": "il cono della torcia",
			"leggi": func(s): return ExpeditionModules.raggio_torcia(s),
			"base": ExpeditionModules.RAGGIO_TORCIA_SPENTO, "verso": 1},
		{"id": ExpeditionModules.RABDOMANTE, "nome": "il raggio del radar",
			"leggi": func(s): return ExpeditionModules.raggio_radar(s),
			"base": ExpeditionModules.RAGGIO_RADAR_SPENTO, "verso": 1},
		{"id": ExpeditionModules.TACCUINO, "nome": "la resa dei forzieri",
			"leggi": func(s): return ExpeditionModules.resa_dei_forzieri(s),
			"base": ExpeditionModules.RESA_PIENA, "verso": 1},
	]

func _fanno_qualcosa() -> void:
	var misurati := {}
	for misura_data in _misure():
		var misura: Dictionary = misura_data
		var id := str(misura["id"])
		misurati[id] = true
		var portato := _save_con([id])
		var valore := float(misura["leggi"].call(portato))
		var base := float(misura["base"])
		if int(misura["verso"]) < 0:
			_controlla(valore < base, "«%s» non riduce %s" % [id, str(misura["nome"])])
			_controlla(valore > 0.0,
				"«%s» azzera %s: l'ostacolo non è attenuato, è cancellato" % [id, str(misura["nome"])])
		else:
			_controlla(valore > base, "«%s» non aumenta %s" % [id, str(misura["nome"])])
	for id_data in ExpeditionModules.ids():
		_controlla(misurati.has(str(id_data)),
			"il modulo «%s» non ha una misura in questo audit: nessuno può dire se fa qualcosa" % str(id_data))

	# **La felpata non rende invisibili.** Una sacca che non nota più nessuno non
	# è un pericolo disinnescato: è un pericolo cancellato, e il presidio
	# diventerebbe un disegno.
	_controlla(ExpeditionModules.vista_delle_sacche(_save_con([ExpeditionModules.FELPA])) > 0.4,
		"l'andatura felpata rende Eli invisibile: il presidio smette di esistere")

	# **Nessuno satura col grado.** È la lezione della misura che ha tolto
	# l'impulso: un effetto scritto come differenza fra il grado della sacca e
	# quello di Eli sparisce da solo dal mondo 2 in poi
	# (`costo_delle_sacche_probe`). Questi sono fattori su numeri che il grado di
	# Eli non tocca, e questa riga è il posto in cui ce ne si accorge se un giorno
	# qualcuno li riscrivesse come differenze.
	for prove in [0, 50, 200, 500]:
		var forte := _save_con([ExpeditionModules.FELPA, ExpeditionModules.ZAVORRA])
		forte.data["powerRuns"] = prove
		_controlla(ExpeditionModules.vista_delle_sacche(forte) < ExpeditionModules.VISTA_PIENA
			and ExpeditionModules.spinta_del_morso(forte) < ExpeditionModules.SPINTA_PIENA,
			"a %d prove superate i moduli di spedizione smettono di fare effetto" % prove)

	# E l'effetto arriva davvero fino al contratto che la scena legge: un numero
	# che cambia nel modulo ma non nel contratto è un numero che nessuno vedrà.
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := NativeWorldState.default_request("expedition-module-audit")
	gameplay.setup(request, NativeWorldState.result_for(request), false)
	var prima: Dictionary = gameplay.runtime_state()
	var cosmetics: Dictionary = gameplay.game_save.data.get("cosmetics", {})
	cosmetics["inventory"] = ExpeditionModules.ids()
	# Al primo mondo i posti sono due: il contratto non può mostrare gli effetti
	# di sei moduli, e questo audit non deve pretenderlo. Si verificano i due
	# portati, uno per ciascuna delle due chiavi che la scena legge da sempre.
	cosmetics["loadout"] = [ExpeditionModules.FELPA, ExpeditionModules.ZAVORRA]
	gameplay.game_save.data["cosmetics"] = cosmetics
	var dopo: Dictionary = gameplay.runtime_state()
	_controlla(float(dopo.get("enemyNoticeScale", 9.0)) < float(prima.get("enemyNoticeScale", 0.0)),
		"la vista delle sacche non cambia nel contratto runtime")
	_controlla(float(dopo.get("knockbackDistance", 9999.0)) < float(prima.get("knockbackDistance", 0.0)),
		"lo spintone non cambia nel contratto runtime")
	# E le quattro chiavi nuove esistono nel contratto, anche a zero: la scena le
	# legge sempre, e una chiave assente le farebbe usare un valore di ripiego.
	for chiave in ["playerSpeed", "torchRadius", "treasureRadarRadius", "treasureYield",
			"moduleLoadout", "moduleSlots"]:
		_controlla(prima.has(chiave),
			"il contratto runtime non pubblica «%s»: la scena non può disegnarlo" % chiave)
	# Cambiando bardatura cambia il contratto, e senza rientrare nel mondo.
	cosmetics["loadout"] = [ExpeditionModules.PASSO, ExpeditionModules.RABDOMANTE]
	gameplay.game_save.data["cosmetics"] = cosmetics
	var terzo: Dictionary = gameplay.runtime_state()
	_controlla(float(terzo.get("playerSpeed", 0.0)) > float(prima.get("playerSpeed", 9999.0)),
		"il passo non cambia nel contratto runtime")
	_controlla(float(terzo.get("treasureRadarRadius", 0.0)) > 0.0,
		"il raggio del radar non arriva al contratto runtime")
	_controlla(is_equal_approx(float(terzo.get("enemyNoticeScale", 0.0)), ExpeditionModules.VISTA_PIENA),
		"un modulo lasciato a bordo continua a fare effetto nel contratto runtime")
	root.remove_child(gameplay)
	gameplay.free()

## **La bardatura è una scelta.** (2 settembre 2026) Il possesso è permanente e
## non è mai in discussione; quello che si porta è limitato, e il limite è la
## sola ragione per cui la sezione dei moduli è una decisione invece che una
## lista della spesa.
func _la_bardatura_e_una_scelta() -> void:
	var tutti := ExpeditionModules.ids()

	# I posti sono meno dei moduli, a qualunque punto della campagna. Se un
	# giorno si potesse portare tutto, la scelta sparirebbe senza che nessuno se
	# ne accorga: sarebbe solo un negozio che si finisce.
	for livello in [1, 9, 17, 24]:
		var save := _save_con(tutti, livello)
		_controlla(ExpeditionModules.posti(save) < tutti.size(),
			"al mondo %d si portano tutti i %d moduli: la bardatura non è più una scelta" % [
				livello, tutti.size()])
		_controlla(ExpeditionModules.bardatura(save).size() <= ExpeditionModules.posti(save),
			"al mondo %d la bardatura sfonda i posti disponibili" % livello)

	# E crescono: due, tre, quattro. Un limite che non si muove per ventiquattro
	# mondi è un limite che a metà campagna il bambino smette di guardare.
	_controlla(ExpeditionModules.posti(_save_con([], 1)) == ExpeditionModules.POSTI_BASE,
		"i posti di partenza non sono quelli dichiarati")
	_controlla(
		ExpeditionModules.posti(_save_con([], ExpeditionModules.LIVELLO_TERZO_POSTO))
		> ExpeditionModules.posti(_save_con([], ExpeditionModules.LIVELLO_TERZO_POSTO - 1)),
		"il terzo posto non arriva al mondo dichiarato")
	_controlla(
		ExpeditionModules.posti(_save_con([], ExpeditionModules.LIVELLO_QUARTO_POSTO))
		> ExpeditionModules.posti(_save_con([], ExpeditionModules.LIVELLO_QUARTO_POSTO - 1)),
		"il quarto posto non arriva al mondo dichiarato")

	# **Posseduto non è portato.** È la riga che regge tutto: se un modulo
	# lasciato a bordo facesse comunque effetto, la bardatura sarebbe un
	# ornamento e la sezione tornerebbe a essere una lista di acquisti.
	for misura_data in _misure():
		var misura: Dictionary = misura_data
		var id := str(misura["id"])
		var a_bordo := _save_a_bordo([id])
		_controlla(ExpeditionModules.posseduto(a_bordo, id),
			"«%s» non risulta posseduto quando resta a bordo" % id)
		_controlla(is_equal_approx(float(misura["leggi"].call(a_bordo)), float(misura["base"])),
			"«%s» fa effetto anche restando a bordo: la bardatura non conta niente" % id)

	# Portare e lasciare non toccano il possesso e non costano niente.
	var save := _save_a_bordo(tutti)
	var frammenti := save.fragments()
	var energia := save.energy()
	_controlla(ExpeditionModules.porta(save, tutti[0]), "un modulo posseduto non entra in bardatura")
	_controlla(ExpeditionModules.porta(save, tutti[1]), "il secondo posto non si riempie")
	_controlla(not ExpeditionModules.porta(save, tutti[2]),
		"la bardatura accetta più moduli dei posti che dichiara")
	_controlla(ExpeditionModules.lascia(save, tutti[0]), "un modulo in bardatura non si lascia a bordo")
	_controlla(ExpeditionModules.posseduto(save, tutti[0]),
		"lasciare a bordo un modulo lo fa sparire: un acquisto permanente si è perso")
	_controlla(ExpeditionModules.porta(save, tutti[2]),
		"liberato un posto, la bardatura resta piena")
	_controlla(save.fragments() == frammenti and save.energy() == energia,
		"cambiare bardatura costa valuta: si pagherebbe due volte lo stesso acquisto")

	# Non si porta quello che non si ha, e un salvataggio manomesso non regala
	# effetti: la lista si riconcilia sempre con il possesso e con i posti.
	var vuoto := _save_con([])
	_controlla(not ExpeditionModules.porta(vuoto, tutti[0]),
		"si porta in spedizione un modulo mai comprato")
	var manomesso := _save_a_bordo([tutti[0]])
	var cosmetics: Dictionary = manomesso.data.get("cosmetics", {})
	cosmetics["loadout"] = tutti.duplicate()
	manomesso.data["cosmetics"] = cosmetics
	_controlla(ExpeditionModules.bardatura(manomesso) == [tutti[0]],
		"una bardatura scritta a mano nel salvataggio regala moduli mai comprati")

	# E la bottega sa dirlo: i testi della sezione parlano della scelta, non solo
	# dell'acquisto. Un limite che nessuna schermata nomina è un limite che il
	# bambino scopre sbagliando.
	var meta: Dictionary = SHOP.SLOT_META.get("module", {})
	var testo := ("%s %s" % [str(meta.get("intro", "")), str(meta.get("impact", ""))]).to_lower()
	_controlla(testo.contains("bardatura"),
		"la sezione dei moduli non nomina la bardatura: il limite resta invisibile")

## **La prova che conta.** Comprare potere non deve spostare di un centesimo
## quello che il gioco sa di ciò che il bambino ha imparato.
func _non_toccano_l_apprendimento() -> void:
	var contenuti := ContentManager.new()
	var senza := _save_con([])
	var con := _save_con(ExpeditionModules.ids())
	for save in [senza, con]:
		var prog := ProgressionManager.new(save, contenuti)
		prog.record_mission("matematica", 3, 4, 0, true)
		prog.record_practice("italiano", 2, 4, 0)
	_controlla(
		is_equal_approx(senza.mastery_of("matematica"), con.mastery_of("matematica"))
		and is_equal_approx(senza.mastery_of("italiano"), con.mastery_of("italiano")),
		"la padronanza cambia a seconda dei moduli posseduti")
	_controlla(
		senza.missions_toward_gate("matematica") == con.missions_toward_gate("matematica"),
		"il conteggio del gate cambia a seconda dei moduli posseduti")
	var readiness_senza: Dictionary = ProgressionManager.new(senza, contenuti).readiness()
	var readiness_con: Dictionary = ProgressionManager.new(con, contenuti).readiness()
	_controlla(str(readiness_senza.get("missing", [])) == str(readiness_con.get("missing", [])),
		"la prontezza al livello successivo cambia a seconda dei moduli posseduti")

## **Nessun modulo è necessario.** Senza comprare niente, tutto resta quello che
## era: se un giorno il gioco desse per scontato un modulo, chi non lo compra
## troverebbe una mappa più povera invece che uguale.
func _nessuno_e_necessario() -> void:
	var senza := _save_con([])
	for misura_data in _misure():
		var misura: Dictionary = misura_data
		_controlla(is_equal_approx(float(misura["leggi"].call(senza)), float(misura["base"])),
			"senza moduli %s non è quello di base" % str(misura["nome"]))
	# I due raggi partono spenti, e non è un dettaglio: se il radar o il cono
	# fossero necessari per trovare qualcosa, un forziere diventerebbe contenuto
	# a pagamento invece che contenuto trovato.
	_controlla(is_equal_approx(ExpeditionModules.raggio_radar(senza), 0.0)
		and is_equal_approx(ExpeditionModules.raggio_torcia(senza), 0.0),
		"radar o cono sono accesi senza il modulo: qualcosa nel mondo li dà per scontati")

func _non_svuotano_la_bottega() -> void:
	var moduli := 0
	var totale := 0
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var costo := int(voce.get("cost", 0))
		totale += costo
		if str(voce.get("slot", "")) == "module":
			moduli += costo
	_controlla(totale > 0, "il catalogo della bottega è vuoto")
	if totale > 0:
		var quota := float(moduli) / float(totale)
		_controlla(quota <= QUOTA_MASSIMA_CATALOGO,
			"i moduli costano %d su %d, cioè il %.1f%% del catalogo (massimo %.0f%%)" % [
				moduli, totale, quota * 100.0, QUOTA_MASSIMA_CATALOGO * 100.0])
		print("  moduli: %d frammenti su %d di catalogo (%.1f%%)" % [moduli, totale, quota * 100.0])
