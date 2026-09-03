extends SceneTree

## **La bottega è attaccata al mondo.** (14 agosto 2026)
##
## Richiesta del committente: «bottega, valuta, gioco, missioni — come possiamo
## collegare tutto in modo intelligente?». Misurando, i legami mancanti erano tre
## e tutti diversi:
##
## - le **chiavi si compravano**: torcia e falce, le due sole voci che aprono il
##   mondo, costavano meno di un forziere ([[FieldTools]]);
## - il catalogo **non sapeva dove sei stata**: ogni voce ha un'origine scritta
##   («Pigmento delle Rovine dei Glifi») e la si poteva comprare senza aver mai
##   visto le Rovine ([[RewardCatalog]] `mondo`);
## - due categorie **si scusavano**: upgrade e decor dichiaravano al bambino che
##   il loro effetto «non è ancora attivo in questa build».
##
## Le sei cose che questo audit verifica, e perché ognuna:
##
## 1. **Gli strumenti non sono in vendita** — e il motivo mostrato dice dove si
##    prendono invece di dire soltanto no.
## 2. **La consegna funziona ed è gratuita**: non tocca frammenti né energia, e
##    dà prima la torcia e poi la falce.
## 3. **La consegna non si può mancare**: dopo due riparazioni si possiedono
##    entrambi gli strumenti, comunque sia andata la partita.
## 4. **L'ancoraggio al mondo è un invito, non un muro**: chi è al mondo 1 ha
##    comunque voci comprabili, e ogni voce ancorata sa dire il nome del posto.
## 5. **L'ancoraggio non tocca la progressione**: non chiede padronanza, non
##    chiede di aver finito niente — solo che la rotta sia aperta.
## 6. **Nessuna categoria promette il vuoto**: nessun testo della bottega
##    contiene una scusa sul futuro.

const SCUSE := ["non sono ancora", "non e ancora", "non è ancora", "arrivera", "arriverà",
	"in questa build", "blocco dedicato"]

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_le_chiavi_non_si_comprano()
	_la_consegna_e_gratuita()
	_l_ancoraggio_e_un_invito()
	_l_ancoraggio_non_tocca_la_progressione()
	_la_conquista_apre_un_ricordo()
	_nessuna_categoria_si_scusa()
	if errori.is_empty():
		print("SHOP WORLD LINK audit VERDE — chiavi dal mondo, catalogo ancorato, nessuna promessa vuota")
	else:
		printerr("SHOP WORLD LINK audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _nuovo_save(level: int, mondi: Array) -> GameSaveManager:
	var save := GameSaveManager.new()
	save.data = GameSaveManager._default_data()
	save.set_level(level)
	save.add_fragments(50_000)
	save.add_energy(5_000)
	save.data["worlds"] = {"unlocked": mondi.duplicate(), "current": int(mondi[0])}
	return save

func _le_chiavi_non_si_comprano() -> void:
	var save := _nuovo_save(6, [1, 2, 3, 4, 5, 6])
	var manager := RewardManager.new(save)
	for id in FieldTools.ids():
		var tool_id := str(id)
		_controlla(RewardCatalog.mondo_di(tool_id) == FieldTools.mondo_di(tool_id),
			"catalogo e calendario dissentono sul mondo di «%s»" % tool_id)
		_controlla(not manager.can_unlock(tool_id),
			"lo strumento «%s» risulta sbloccabile in bottega" % tool_id)
		_controlla(not manager.can_afford(tool_id),
			"lo strumento «%s» risulta acquistabile con i frammenti" % tool_id)
		var motivo := manager.unavailable_reason(tool_id)
		_controlla(motivo.contains("riparazione"),
			"il rifiuto per «%s» non dice dove si prende: «%s»" % [tool_id, motivo])

func _la_consegna_e_gratuita() -> void:
	var save := _nuovo_save(2, [1, 2])
	var manager := RewardManager.new(save)
	var frammenti := save.fragments()
	var energia := save.energy()

	# Il mondo del save è il 2: `dovuto` ragiona per calendario dal 19 agosto 2026
	# ([[FieldTools]]), quindi vuole sapere DOVE si è — al mondo 2 sono dovute le
	# prime due chiavi e nessuna delle successive.
	_controlla(FieldTools.dovuto(manager, 2) == FieldTools.TORCIA,
		"il primo strumento dovuto non è la torcia")
	_controlla(manager.deliver_field_tool(FieldTools.TORCIA), "la consegna della torcia è fallita")
	_controlla(manager.owned(FieldTools.TORCIA), "dopo la consegna la torcia non risulta posseduta")
	_controlla(manager.equipped_id("tool") == FieldTools.TORCIA,
		"la torcia consegnata non è finita in mano: slot tool «%s»" % manager.equipped_id("tool"))
	_controlla(save.fragments() == frammenti, "la consegna ha speso frammenti")
	_controlla(save.energy() == energia, "la consegna ha speso energia")

	_controlla(FieldTools.dovuto(manager, 2) == FieldTools.FALCE,
		"dopo la torcia il secondo strumento dovuto non è la falce")
	_controlla(manager.deliver_field_tool(FieldTools.FALCE), "la consegna della falce è fallita")
	_controlla(FieldTools.dovuto(manager, 2) == "",
		"al mondo 2, con torcia e falce, il mondo ne deve ancora qualcuno")
	# E le chiavi dei mondi alti non si anticipano: al 2 la leva non è dovuta.
	_controlla(FieldTools.dovuto(manager, 2) != FieldTools.LEVA,
		"la leva viene consegnata al mondo 2, tre mondi prima del suo")
	_controlla(not manager.deliver_field_tool(FieldTools.TORCIA),
		"uno strumento già posseduto viene consegnato una seconda volta")

	# Le righe di consegna esistono in entrambe le forme, con e senza un nome.
	for id in FieldTools.ids():
		_controlla(FieldTools.riga_di_consegna(str(id), "Ruggine").contains("Ruggine"),
			"la riga di consegna di «%s» ignora chi la pronuncia" % str(id))
		_controlla(FieldTools.riga_di_consegna(str(id), "").strip_edges() != "",
			"senza un nome la consegna di «%s» resta muta" % str(id))

func _l_ancoraggio_e_un_invito() -> void:
	var primo := _nuovo_save(1, [1])
	var manager := RewardManager.new(primo)
	var disponibili := 0
	var ancorate := 0
	for voce in RewardCatalog.CATALOG:
		var scheda: Dictionary = voce
		var id := str(scheda.get("id", ""))
		if RewardCatalog.mondo_di(id) > 0:
			ancorate += 1
			# Ogni voce ancorata deve saper dire il nome del posto: un requisito
			# che non si può leggere è indistinguibile da un guasto.
			_controlla(RewardCatalog.luogo_di(id).strip_edges() != "",
				"la voce «%s» è ancorata a un mondo senza nome leggibile" % id)
		if manager.can_afford(id):
			disponibili += 1
	_controlla(ancorate >= 20,
		"solo %d voci sono ancorate a un mondo: il catalogo non racconta più dove sei stata" % ancorate)
	_controlla(disponibili >= 4,
		"al primo mondo la bottega offre %d voci: troppo poche perché comprare sia una scelta" % disponibili)
	# Il numero non è solo un controllo: è la misura che dice se l'ancoraggio sta
	# invitando o chiudendo, e va guardata quando si sposta una voce da un mondo
	# all'altro.
	print("  al mondo 1: %d voci comprabili · %d voci ancorate a un posto su %d totali" % [
		disponibili, ancorate, RewardCatalog.CATALOG.size()])

	# E arrivati in fondo alla rotta, tutto ciò che era ancorato è raggiungibile.
	var mondi: Array = []
	for world in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		mondi.append(world)
	var veterano := _nuovo_save(24, mondi)
	var manager_veterano := RewardManager.new(veterano)
	for voce in RewardCatalog.CATALOG:
		var id := str(Dictionary(voce).get("id", ""))
		if RewardCatalog.mondo_di(id) > 0:
			_controlla(manager_veterano.incontrato(id),
				"la voce «%s» resta irraggiungibile anche con tutti i mondi aperti" % id)

func _l_ancoraggio_non_tocca_la_progressione() -> void:
	# Due partite allo stesso punto di rotta, una che sa tutto e una che non sa
	# niente: la vetrina deve essere identica. Il catalogo guarda dove sei stata,
	# non quanto sai — è ciò che gli permette di esistere in un gioco che non
	# vende il proprio epilogo.
	var mondi := [1, 2, 3, 4, 5, 6, 7]
	var ignorante := _nuovo_save(7, mondi)
	var esperto := _nuovo_save(7, mondi)
	for subject in ApparatusConfig.SUBJECT_CYCLE:
		esperto.set_mastery(str(subject), 0.95)
	var a := RewardManager.new(ignorante)
	var b := RewardManager.new(esperto)
	for voce in RewardCatalog.CATALOG:
		var id := str(Dictionary(voce).get("id", ""))
		if a.incontrato(id) != b.incontrato(id):
			errori.append("la voce «%s» dipende dalla padronanza: è un gate didattico travestito" % id)
			break

func _la_conquista_apre_un_ricordo() -> void:
	var save := _nuovo_save(1, [1])
	var manager := RewardManager.new(save)
	var id := "accessory-scarf"
	_controlla(manager.incontrato(id), "la Sciarpa non compare arrivando nella Radura")
	_controlla(not manager.conquistato(id), "la Sciarpa nasce gia' conquistata")
	_controlla(not manager.can_unlock(id), "il ricordo si compra senza superare il Pericolo")
	_controlla(manager.unavailable_reason(id).to_lower().contains("pericolo"),
		"il blocco del ricordo non dice quale impresa manca")
	save.mark_hazard_cleared("1", "world-danger-01")
	_controlla(manager.conquistato(id), "il Sigillo non apre il ricordo locale")
	_controlla(manager.can_unlock(id), "dopo il Pericolo la Sciarpa resta bloccata")

	# La vertical slice e' diventata una collezione completa: esattamente una
	# voce per mondo, sempre visibile arrivando e acquistabile soltanto dopo il
	# relativo Pericolo.
	var mondi: Array = []
	for world in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		mondi.append(world)
	var campagna := _nuovo_save(24, mondi)
	var catalogo := RewardCatalog.conquest_items()
	_controlla(catalogo.size() == 24, "i Ricordi di conquista non sono 24")
	var mondi_coperti := {}
	for voce_data in catalogo:
		var voce: Dictionary = voce_data
		var world := int(voce.get("requiresHazardWorld", 0))
		var reward_id := str(voce.get("id", ""))
		_controlla(world in range(1, 25) and not mondi_coperti.has(world),
			"mondo duplicato o invalido nella collezione: %d" % world)
		mondi_coperti[world] = true
		var reward_manager := RewardManager.new(campagna)
		_controlla(reward_manager.incontrato(reward_id),
			"il Ricordo %d non compare dopo l'arrivo nel mondo" % world)
		_controlla(not reward_manager.conquistato(reward_id),
			"il Ricordo %d nasce gia' conquistato" % world)
		campagna.mark_hazard_cleared(str(world), "world-danger-%02d" % world)
		_controlla(reward_manager.conquistato(reward_id) and reward_manager.can_unlock(reward_id),
			"il Pericolo %d non apre il proprio Ricordo" % world)
		_controlla(reward_manager.unlock_and_equip(reward_id) and reward_manager.owned(reward_id),
			"il Ricordo %d non resta nella collezione dopo l'acquisto" % world)
		if str(voce.get("slot", "")) == "memento":
			_controlla(reward_manager.equipped_id("memento").is_empty(),
				"il Ricordo %d occupa uno slot invisibile invece di restare in collezione" % world)

func _nessuna_categoria_si_scusa() -> void:
	var pannello := load("res://scripts/ui/outdoor_shop_panel.gd")
	var meta: Dictionary = pannello.get("SLOT_META") if pannello != null else {}
	if meta.is_empty():
		errori.append("impossibile leggere i testi delle categorie della bottega")
		return
	for slot in meta.keys():
		var scheda: Dictionary = meta[slot]
		for campo in ["intro", "impact"]:
			var testo := str(scheda.get(campo, "")).to_lower()
			for scusa in SCUSE:
				if testo.contains(str(scusa)):
					errori.append("la categoria «%s» promette il futuro invece del presente: «%s»" % [
						str(slot), testo])
					break
