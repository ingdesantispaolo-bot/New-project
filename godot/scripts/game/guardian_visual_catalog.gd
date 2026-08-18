class_name GuardianVisualCatalog
extends RefCounted

## Una forma ostile distinta per ciascuno dei 24 mondi. Il catalogo e' solo
## presentazionale: velocita', danno, inseguimento e ricompense restano in
## WorldEnemy e non dipendono dal nome o dall'illustrazione.

const NAMES := [
	"Guardiano del Rovo Numerico",
	"Strappafrase",
	"Predatore di Loop",
	"Sirena del Rumore",
	"Minotauro a Pistoni",
	"Arpia di Risonanza",
	"Legionario Senza Volto",
	"Idra di Circuiti",
	"Kraken delle Rotte",
	"Chimera Simbiotica",
	"Cronomante Sepolto",
	"Sfinge Assiomatica",
	"Cacciatore Perielio",
	"Divoravoci",
	"Ragno del Controllo",
	"Sentinella di Babele",
	"Leviatano di Pressione",
	"Gargoyle della Dissonanza",
	"Re delle Radici Vuote",
	"Mietitore di Campo",
	"Colosso Tettonico",
	"Predatore della Bioforgia",
	"Tiranno delle Cronache",
	"Drago del Nucleo Nullo",
]

const FAMILIES := [
	"fantasy", "fantasy", "fantascienza", "fantascienza",
	"fantascienza", "fantasy", "fantasy", "fantascienza",
	"fantasy", "fantasy", "fantasy", "fantascienza",
	"fantascienza", "fantasy", "fantascienza", "fantascienza",
	"fantascienza", "fantasy", "fantasy", "fantascienza",
	"fantasy", "fantascienza", "fantasy", "fantascienza",
]

static func name_for(level: int) -> String:
	return str(NAMES[clampi(level, 1, NAMES.size()) - 1])

static func family_for(level: int) -> String:
	return str(FAMILIES[clampi(level, 1, FAMILIES.size()) - 1])

static func path_for(level: int) -> String:
	return "res://assets/guardians/level%02d-v1.png" % clampi(level, 1, NAMES.size())

static func texture_for(level: int) -> Texture2D:
	var path := path_for(level)
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D
