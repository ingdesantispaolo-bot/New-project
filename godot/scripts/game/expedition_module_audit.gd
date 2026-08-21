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
## Le cinque cose che verifica:
##
## 1. **Ogni modulo esiste e si compra davvero**: sta nel catalogo, è permanente,
##    e la bottega ha una sezione che lo mostra. Un oggetto che nessuna schermata
##    elenca è un oggetto che non esiste.
## 2. **Ogni modulo fa qualcosa di misurabile.** Posseduto o no, un numero deve
##    cambiare — altrimenti è uno dei quattro upgrade bugiardi del 6 agosto con
##    un nome nuovo.
## 3. **Comprare un modulo non tocca l'apprendimento**: padronanza, copertura,
##    conteggi del gate ed energia restano quelli, tolto il prezzo.
## 4. **Nessun modulo è necessario.** Senza, tutto resta raggiungibile: il tetto
##    delle cariche non scende sotto la base, il raggio dell'impulso resta quello
##    che era, lo scatto pure.
## 5. **I moduli non svuotano la bottega.** Costano insieme una frazione
##    dichiarata del catalogo: il sink estetico è tarato su 72.600 energia contro
##    le 42.758-53.783 che una campagna produce, e non c'è spazio per un secondo
##    rubinetto grosso.

const OK := "EXPEDITION MODULE audit VERDE"
const SHOP := preload("res://scripts/ui/outdoor_shop_panel.gd")

## Quanto possono pesare i moduli sul costo totale del catalogo. Misurato: 950 su
## 72.600, cioè l'1,3%. La soglia lascia spazio a un quarto e un quinto modulo e
## prende chi volesse farne un secondo sink.
const QUOTA_MASSIMA_CATALOGO := 0.06

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _save_con(moduli: Array) -> GameSaveManager:
	var save := GameSaveManager.new()
	var cosmetics: Dictionary = save.data.get("cosmetics", {})
	cosmetics["inventory"] = moduli.duplicate()
	save.data["cosmetics"] = cosmetics
	return save

func _init() -> void:
	_esistono_e_si_comprano()
	_fanno_qualcosa()
	_non_toccano_l_apprendimento()
	_nessuno_e_necessario()
	_non_svuotano_la_bottega()
	if errori.is_empty():
		print(OK)
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
func _fanno_qualcosa() -> void:
	var senza := _save_con([])
	var base_scatto := ExpeditionModules.moltiplicatore_scatto(senza)
	var base_distanza := ExpeditionModules.distanza_scatto(senza)

	var base_vista := ExpeditionModules.vista_delle_sacche(senza)
	var base_spinta := ExpeditionModules.spinta_del_morso(senza)
	var con_passo := _save_con([ExpeditionModules.PASSO])
	_controlla(ExpeditionModules.moltiplicatore_scatto(con_passo) > base_scatto,
		"il passo lungo non rende la corsa più veloce")
	_controlla(ExpeditionModules.distanza_scatto(con_passo) > base_distanza,
		"il passo lungo non allunga il balzo")
	var con_felpa := _save_con([ExpeditionModules.FELPA])
	_controlla(ExpeditionModules.vista_delle_sacche(con_felpa) < base_vista,
		"l'andatura felpata non accorcia la vista delle sacche")
	# **E non la azzera.** Una sacca che non nota piu' nessuno non e' un
	# pericolo disinnescato: e' un pericolo cancellato, e il presidio
	# diventerebbe un disegno.
	_controlla(ExpeditionModules.vista_delle_sacche(con_felpa) > 0.4,
		"l'andatura felpata rende Eli invisibile: il presidio smette di esistere")
	var con_zavorra := _save_con([ExpeditionModules.ZAVORRA])
	_controlla(ExpeditionModules.spinta_del_morso(con_zavorra) < base_spinta,
		"la zavorra non accorcia lo spintone")
	_controlla(ExpeditionModules.spinta_del_morso(con_zavorra) > 0.0,
		"la zavorra annulla lo spintone: la sacca smette di essere un ostacolo")
	# **Nessuno dei due satura col grado.** E' la lezione della misura che ha
	# tolto l'impulso: un effetto scritto come differenza fra il grado della
	# sacca e quello di Eli sparisce da solo dal mondo 2 in poi
	# (`costo_delle_sacche_probe`). Questi due sono fattori su numeri che il
	# grado di Eli non tocca, e questa riga e' il posto in cui ce ne si
	# accorge se un giorno qualcuno li riscrivesse come differenze.
	for grado in range(0, 9):
		var forte := _save_con([ExpeditionModules.FELPA, ExpeditionModules.ZAVORRA])
		forte.data["powerRuns"] = 500
		_controlla(ExpeditionModules.vista_delle_sacche(forte) < base_vista
			and ExpeditionModules.spinta_del_morso(forte) < base_spinta,
			"a grado massimo i moduli di spedizione smettono di fare effetto")

	# E l'effetto arriva davvero fino al contratto che la scena legge: un numero
	# che cambia nel modulo ma non nel contratto è un numero che nessuno vedrà.
	var gameplay := OutdoorGameplay.new()
	root.add_child(gameplay)
	var request := NativeWorldState.default_request("expedition-module-audit")
	gameplay.setup(request, NativeWorldState.result_for(request), false)
	var prima: Dictionary = gameplay.runtime_state()
	var cosmetics: Dictionary = gameplay.game_save.data.get("cosmetics", {})
	cosmetics["inventory"] = ExpeditionModules.ids()
	gameplay.game_save.data["cosmetics"] = cosmetics
	var dopo: Dictionary = gameplay.runtime_state()
	_controlla(float(dopo.get("sprintMultiplier", 0.0)) > float(prima.get("sprintMultiplier", 0.0)),
		"la corsa non cambia nel contratto runtime")
	_controlla(float(dopo.get("dashDistance", 0.0)) > float(prima.get("dashDistance", 0.0)),
		"il balzo non cambia nel contratto runtime")
	_controlla(float(dopo.get("enemyNoticeScale", 9.0)) < float(prima.get("enemyNoticeScale", 0.0)),
		"la vista delle sacche non cambia nel contratto runtime")
	_controlla(float(dopo.get("knockbackDistance", 9999.0)) < float(prima.get("knockbackDistance", 0.0)),
		"lo spintone non cambia nel contratto runtime")
	root.remove_child(gameplay)
	gameplay.free()

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
	_controlla(is_equal_approx(
		ExpeditionModules.moltiplicatore_scatto(senza), ExpeditionModules.SCATTO_BASE),
		"senza moduli la corsa non è quella di base")
	_controlla(is_equal_approx(
		ExpeditionModules.distanza_scatto(senza), ExpeditionModules.SCATTO_DISTANZA),
		"senza moduli il balzo non è quello di base")
	_controlla(is_equal_approx(
		ExpeditionModules.vista_delle_sacche(senza), ExpeditionModules.VISTA_PIENA),
		"senza moduli le sacche non hanno la vista piena")
	_controlla(is_equal_approx(
		ExpeditionModules.spinta_del_morso(senza), ExpeditionModules.SPINTA_PIENA),
		"senza moduli lo spintone non è quello di base")

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
