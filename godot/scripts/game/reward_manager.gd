class_name RewardManager
extends RefCounted

## Logica di possesso/acquisto/equip dei cosmetici (C-14), porting di
## src/core/RewardSystem.ts. Non tocca energia/bridge direttamente: la spesa e
## la segnalazione al bridge restano a `OutdoorGameplay` (stesso pattern già
## collaudato per missioni/enigmi: spend_energy + result.energySpent), qui
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

static func _is_unslotted(cosmetic: Dictionary) -> bool:
	var slot := str(cosmetic.get("slot", ""))
	return slot == "upgrade" or slot == "decor"

func owned(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty():
		return false
	var cosmetics := _cosmetics()
	if Array(cosmetics.get("unlocked", [])).has(id):
		return true
	return _is_unslotted(cosmetic) and Array(cosmetics.get("inventory", [])).has(id)

func can_unlock(id: String) -> bool:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or owned(id):
		return false
	return save.level() >= int(cosmetic.get("minLevel", 1))

func can_afford(id: String) -> bool:
	if not can_unlock(id):
		return false
	var cosmetic := RewardCatalog.find(id)
	return save.energy() >= int(cosmetic.get("cost", 0))

## Messaggio per l'HUD quando l'acquisto non è possibile; stringa vuota se lo è
## già o è già posseduto (nessun messaggio da mostrare in quel caso).
func unavailable_reason(id: String) -> String:
	var cosmetic := RewardCatalog.find(id)
	if cosmetic.is_empty() or owned(id):
		return ""
	var min_level := int(cosmetic.get("minLevel", 1))
	if save.level() < min_level:
		return "Richiede livello %d" % min_level
	if save.energy() < int(cosmetic.get("cost", 0)):
		return "Energia insufficiente"
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
	if slot == "upgrade" or slot == "decor":
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
