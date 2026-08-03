class_name BuildingCatalog
extends RefCounted

## Catalogo visuale dei tre ruoli ricorrenti. Nessuna posizione assoluta: è la
## composizione del mondo a collocarli senza acqua, safe route o POI.

const ROLES := ["work_home", "ritrovo", "first_ruin"]

const WORLD_ONE_NAMES := {
	"work_home": "Casa del Conto",
	"ritrovo": "Fontana dei Filari",
	"first_ruin": "Obelisco dei Numeri",
}

static func for_world(world: int, profile: Dictionary) -> Array:
	var specs: Array = []
	for role in ROLES:
		var label := str(WORLD_ONE_NAMES.get(role, "")) if world == 1 else _generic_label(role, profile)
		specs.append({
			"id": "building-%02d-%s" % [world, role],
			"world": world,
			"role": role,
			"label": label,
			"artKit": str(profile.get("artKit", "natura-rovine")),
		})
	return specs

static func _generic_label(role: String, _profile: Dictionary) -> String:
	match role:
		"work_home":
			return "Casa del mestiere"
		"ritrovo":
			return "Ritrovo"
	return "Rovina dei Primi"
