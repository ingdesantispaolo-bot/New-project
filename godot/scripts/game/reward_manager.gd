class_name RewardManager
extends RefCounted

## Logica di possesso/acquisto/equip dei cosmetici (C-14), porting di
## src/core/RewardSystem.ts. Non tocca la valuta o il riepilogo direttamente: la
## spesa e la segnalazione restano a `OutdoorGameplay` (stesso pattern già
## collaudato per missioni/enigmi: spend_fragments + result.fragmentsSpent), qui
## vive solo "chi possiede/equipaggia cosa e a quali condizioni".
##
## Slot upgrade/decor non occupano `cosmetics.equipped`: finiscono in
## `cosmetics.inventory` e sono "equipaggiati" per il solo fatto di esistere
## (come nel prototipo Phaser: sono vantaggi permanenti, non skin a slot unico).

var save  # GameSaveManager

func _init(save_manager) -> void:
	save = save_manager

func _cosmetics() -> Dictionary:
	if not save.data.has("cosmetics"):
		save.data["cosmetics"] = {"unlocked": [], "equipped": {}, "inventory": []}
	return save.data["cosmetics"]

## Acquisti PERMANENTI: non si equipaggiano, non si sostituiscono, restano.
## I moduli di spedizione entrano di qui (14 agosto 2026) e non hanno avuto
## bisogno di una chiave nuova nel salvataggio: `cosmetics.inventory` fa già
## esattamente questo, con i suoi lettori. Una chiave in meno da tenere viva.
static func _is_unslotted(cosmetic: Dictionary) -> bool:
	var slot := str(cosmetic.get("slot", ""))
	return slot == "upgrade" or slot == "decor" or slot == "module" or slot == "memento"

func owned(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty():
		return false
	var cosmetics := _cosmetics()
	if Array(cosmetics.get("unlocked", [])).has(id):
		return true
	return _is_unslotted(cosmetic) and Array(cosmetics.get("inventory", [])).has(id)

## Gli strumenti di campo NON sono acquistabili (14 agosto 2026): li consegna il
## mondo dopo una riparazione. Vedi [[FieldTools]].
func can_unlock(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or owned(id):
		return false
	if FieldTools.is_field_tool(id):
		return false
	if not incontrato(id):
		return false
	if not conquistato(id):
		return false
	return save.level() >= int(cosmetic.get("minLevel", 1))

## Alcuni ricordi prestigiosi non entrano in vendita arrivando in un luogo: si
## vedono subito in anteprima, ma diventano acquistabili quando il Pericolo di
## quel mondo e' stato davvero superato. La vittoria regala gia' il Sigillo;
## questa e' la scelta estetica che si apre dopo.
func conquistato(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty():
		return false
	var world := int(cosmetic.get("requiresHazardWorld", 0))
	if world <= 0:
		return true
	return Array(save.world_progress(str(world)).get("clearedHazardIds", [])).has(
		"world-danger-%02d" % world)

## **Hai visto il posto da cui viene?** (14 agosto 2026)
##
## Una voce ancorata a un mondo entra in vetrina quando quel mondo è fra le
## destinazioni aperte. Non chiede di averlo finito né di sapere qualcosa: chiede
## di esserci potuta andare. Vedi [[RewardCatalog]].
func incontrato(id: String) -> bool:
	var world := RewardCatalog.mondo_di(id)
	if world <= 0:
		return true
	return save.unlocked_worlds().has(world)

## La consegna dal mondo: sblocca ed equipaggia SENZA prezzo e senza controlli di
## livello. È l'unica porta che scavalca `can_unlock`, ed esiste perché uno
## strumento è una chiave, non una ricompensa.
func deliver_field_tool(id: String) -> bool:
	if not FieldTools.is_field_tool(id) or owned(id):
		return false
	return unlock_and_equip(id)

## La bottega si paga in FRAMMENTI dal 14 agosto 2026: l'energia resta la valuta
## delle prove e non compra più niente. Vedi [[FragmentEconomy]].
func can_afford(id: String) -> bool:
	if not can_unlock(id):
		return false
	var cosmetic := RewardCatalog.find(id)
	return save.fragments() >= int(cosmetic.get("cost", 0))

## Messaggio per l'HUD quando l'acquisto non è possibile; stringa vuota se lo è
## già o è già posseduto (nessun messaggio da mostrare in quel caso).
func unavailable_reason(id: String) -> String:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or owned(id):
		return ""
	if FieldTools.is_field_tool(id):
		return FieldTools.motivo_non_in_vendita()
	if not incontrato(id):
		return "Si trova a %s: passa di lì e comparirà qui." % RewardCatalog.luogo_di(id)
	if not conquistato(id):
		return "Supera il Pericolo di %s: il ricordo resterà qui ad aspettarti." % RewardCatalog.luogo_di(id)
	var min_level := int(cosmetic.get("minLevel", 1))
	if save.level() < min_level:
		return "Richiede livello %d" % min_level
	if save.fragments() < int(cosmetic.get("cost", 0)):
		return "Frammenti insufficienti"
	return ""

func equipped_id(slot: String) -> String:
	return str(_cosmetics().get("equipped", {}).get(slot, ""))

func is_equipped(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty():
		return false
	if _is_unslotted(cosmetic):
		return owned(id)
	return equipped_id(str(cosmetic.get("slot", ""))) == id

## Sblocca e, se lo slot lo prevede, equipaggia subito (come l'acquisto in
## RewardSystem.ts). Non controlla il costo: la spesa è del chiamante.
func unlock_and_equip(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or owned(id):
		return false
	_unlock(cosmetic)
	if not _is_unslotted(cosmetic):
		_equip(str(cosmetic.get("slot", "")), id)
	return true

func equip(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or not owned(id) or _is_unslotted(cosmetic):
		return false
	_equip(str(cosmetic.get("slot", "")), id)
	return true

func unequip(slot: String) -> void:
	if slot == "upgrade" or slot == "decor" or slot == "memento":
		return
	_equip(slot, "")

func _unlock(cosmetic: Dictionary) -> void:
	var cosmetics := _cosmetics()
	var id := str(cosmetic.get("id", ""))
	var key := "inventory" if _is_unslotted(cosmetic) else "unlocked"
	var list: Array = cosmetics.get(key, [])
	if not list.has(id):
		list.append(id)
	cosmetics[key] = list

func _equip(slot: String, id: String) -> void:
	var cosmetics := _cosmetics()
	var equipped: Dictionary = cosmetics.get("equipped", {})
	if id == "":
		equipped.erase(slot)
	else:
		equipped[slot] = id
	cosmetics["equipped"] = equipped
