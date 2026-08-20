class_name BuildingCatalog
extends RefCounted

## Catalogo visuale dei tre ruoli ricorrenti. Nessuna posizione assoluta: è la
## composizione del mondo a collocarli senza acqua, safe route o POI.

const ROLES := ["work_home", "ritrovo", "first_ruin"]

## Tre atlanti 4×6: una cella per mondo in ognuna delle tre famiglie. Il
## fallback vettoriale resta disponibile se un asset non puo' essere caricato.
const GENERATED_ART := {
	"work_home": {"artPath": "res://assets/building-work-home-atlas-v1.png", "artScale": 0.72, "artBaseline": -96.0},
	"ritrovo": {"artPath": "res://assets/building-ritrovo-atlas-v1.png", "artScale": 0.72, "artBaseline": -96.0},
	"first_ruin": {"artPath": "res://assets/building-first-ruin-atlas-v1.png", "artScale": 0.72, "artBaseline": -96.0},
}

## **Tre edifici con un nome, in ognuno dei ventiquattro mondi.**
##
## Difetto trovato il 6 agosto 2026: i nomi esistevano **solo per il mondo 1**.
## Gli altri ventitre ricevevano «Casa del mestiere», «Ritrovo», «Rovina dei
## Primi» — le stesse tre etichette, identiche, in ogni mondo. Un edificio che si
## chiama «Ritrovo» e' un segnaposto; uno che si chiama «Fontana dei Filari» e'
## un posto, e un posto si ricorda.
##
## I tre ruoli non sono decorativi, e i nomi li rispettano:
##
##   work_home    dove si lavora la materia del mondo. Porta il mestiere nel
##                nome, perche' dice al bambino di che cosa si occupa la gente
##                di qui;
##   ritrovo      dove gli abitanti si parlano fra loro. Porta il nome di un
##                luogo di incontro vero — una fontana, un molo, un chiostro;
##   first_ruin   cio' che i Primi hanno lasciato. E' l'unico dei tre che
##                appartiene alla TRAMA e non al mondo: ogni rovina e' un pezzo
##                del circuito, e messe in fila raccontano che qualcuno e'
##                passato di qui prima, dodici volte.
const WORLD_NAMES := {
	1:  ["Casa del Conto", "Fontana dei Filari", "Obelisco dei Numeri"],
	2:  ["Scriptorium delle Radici", "Chiostro dei Lettori", "Ponte delle Frasi Rotte"],
	3:  ["Officina dei Cicli", "Terrazza dei Gradoni", "Macchina che Ripete"],
	4:  ["Capanno del Radiotelegrafista", "Molo delle Voci", "Faro dei Messaggi Muti"],
	5:  ["Fucina delle Leve", "Mensa dei Carrellisti", "Grande Leva Ferma"],
	6:  ["Bottega del Liutaio", "Terrazza dell'Eco", "Albero Risonante"],
	7:  ["Casa del Copista", "Foro delle Iscrizioni", "Arco dei Glifi Cancellati"],
	8:  ["Quadro di Manovra", "Chiusa dei Barcaioli", "Nodo Centrale Spento"],
	9:  ["Casa del Cartografo", "Approdo delle Correnti", "Rosa dei Venti Incisa"],
	10: ["Vivaio delle Talee", "Serra Comune", "Colonna delle Simbiosi"],
	11: ["Bottega dell'Antiquario", "Portico delle Cronache", "Meridiana Ferma"],
	12: ["Casa del Filo", "Piazza dei Bivi", "Porta a Tre Regole"],
	13: ["Torre dell'Astronomo", "Pozzo delle Carovane", "Anello delle Orbite"],
	14: ["Casa della Narratrice", "Sala delle Voci", "Indice Interrotto"],
	15: ["Officina del Manutentore", "Cortile dei Turni", "Motore Primo"],
	16: ["Casa dell'Interprete", "Valico dei Mercanti", "Stele Bilingue"],
	17: ["Rimessa dello Scafandro", "Pontile dei Palombari", "Campana Sommersa"],
	18: ["Cantoria dell'Organista", "Sagrato delle Prove", "Organo a Dodici Canne"],
	19: ["Casa dell'Erborista", "Ipogeo degli Epigrafisti", "Radice Iscritta"],
	20: ["Cabina dei Quadri", "Riparo dei Fulmini", "Parafulmine dei Primi"],
	21: ["Casa del Pastore", "Fienile del Calendario", "Atlante Spezzato"],
	22: ["Rifugio della Biologa", "Caverna delle Lampade", "Vena Fosforescente"],
	23: ["Studio dell'Archivista", "Sala di Lettura", "Sigillo a Tredici Posti"],
	24: ["Officina dei Primi", "Refettorio del Posto in Piu'", "Cattedra Vuota"],
}

static func for_world(world: int, profile: Dictionary) -> Array:
	var specs: Array = []
	for role in ROLES:
		var label := _label(world, role, profile)
		var spec := {
			"id": "building-%02d-%s" % [world, role],
			"world": world,
			"role": role,
			"label": label,
			"artKit": str(profile.get("artKit", "natura-rovine")),
			"residentOwner": _resident_owner(world, role),
		}
		var generated_art := _generated_art_for(world, role)
		if not generated_art.is_empty():
			spec.merge(generated_art, true)
		specs.append(spec)
	return specs

static func _generated_art_for(world: int, role: String) -> Dictionary:
	if not GENERATED_ART.has(role):
		return {}
	var art := Dictionary(GENERATED_ART[role]).duplicate(true)
	art["artAtlasGrid"] = Vector2i(4, 6)
	art["artAtlasCell"] = Vector2i(posmod(world - 1, 4), int((world - 1) / 4))
	# La stazione del primo mondo resta un oggetto didattico separato, non una
	# parte dell'illustrazione: puo' ancora cambiare senza rigenerare la casa.
	if world == 1 and role == "work_home":
		art.merge({
			"activityPropPath": "res://assets/radura-stazione-conto-v1.png",
			"activityPropScale": 0.09,
			"activityPropOffset": Vector2(-164, -10),
			"activityTags": ["matematica", "raggruppamento", "misura", "ordine"],
		}, true)
	return art

## Ogni luogo vivo appartiene a una persona: lo specialista lavora nella casa
## del mestiere, il testimone presidia il Ritrovo. La Rovina resta dei Primi.
## Questa associazione è data-driven e copre tutti i mondi; il pilot del mondo 1
## aggiunge anche oggetti autoriali specifici sopra la trasformazione edilizia.
static func _resident_owner(world: int, role: String) -> String:
	if role == "first_ruin":
		return ""
	var wanted := "specialista" if role == "work_home" else "testimone"
	var residents: Array = NpcCatalog.for_world(world).get("residents", [])
	for npc_id_data in residents:
		var npc_id := str(npc_id_data)
		if str(NpcCatalog.resident(npc_id).get("funzione", "")) == wanted:
			return npc_id
	# Un catalogo incompleto non deve attribuire il luogo alla persona sbagliata.
	return ""

## Il nome dell'edificio. Fuori dalla scala dei ventiquattro mondi si ripiega
## sull'etichetta generica: e' un caso che non dovrebbe capitare, e una rovina
## senza nome e' meno grave di una scena che non si costruisce.
static func _label(world: int, role: String, profile: Dictionary) -> String:
	var nomi: Array = WORLD_NAMES.get(world, [])
	var indice := ROLES.find(role)
	if indice >= 0 and indice < nomi.size() and str(nomi[indice]) != "":
		return str(nomi[indice])
	return _generic_label(role, profile)

static func _generic_label(role: String, _profile: Dictionary) -> String:
	match role:
		"work_home":
			return "Casa del mestiere"
		"ritrovo":
			return "Ritrovo"
	return "Rovina dei Primi"
