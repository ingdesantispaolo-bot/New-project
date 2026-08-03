class_name RitrovoCatalog
extends RefCounted

## Le conversazioni al Ritrovo: DATI. La regia è di `world_life.gd`.
##
## «La feature più importante di questa sezione» secondo il documento abitanti
## (§6.3), e il motivo è semplice: sono l'unica cosa che fa sembrare che il mondo
## viva anche quando Eli non c'è. Due o tre abitanti parlano **fra loro**; Eli può
## avvicinarsi e ascoltare, e non è un dialogo — è una scena che accade comunque.
##
## Contratto di ogni scena:
##
## - **4–6 battute alternate**, con i tic dei personaggi;
## - una **battuta di notizia** che cita qualcosa che ha fatto il giocatore, senza
##   rivolgersi a lui. Sostituisce la battuta all'indice indicato quando c'è una
##   notizia in coda; senza notizia, la scena resta intera e sensata;
## - un **congedo**: se Eli si avvicina se ne accorgono **alla fine**, non subito.
##   Essere visti *dopo* è ciò che fa sembrare che vivessero anche senza di te —
##   interromperli all'istante li trasformerebbe in distributori di battute;
## - una scena **per stadio del mondo**: allo stadio 0 si discute il gesto vuoto,
##   allo stadio 2 uno insegna all'altro.
##
## Stato: **mondo 1 completo** come fixture di C6 (A5 · Vita di mondo). Le altre
## 69 scene entrano nella stessa forma. Dove una scena manca, il Ritrovo resta un
## luogo normale: nessun errore.

const SCENES := {
	# -- Mondo 1 · Radura Accademia -------------------------------------------
	# Le scene di stadio 0 e 2 sono quelle scritte in ABITANTI_E_LUOGHI.md §6.3:
	# le riporto come stanno perché sono già giuste, e perché l'esempio del
	# documento è il metro su cui misurare le altre settanta.
	"w01-s0": {
		"world": 1,
		"stadio": 0,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-tobia", "dice": "Filari da sei. Sempre sei. Uno, due, tre… e uno."},
			# «cuore» aggiunto rispetto all'esempio del documento: lì Ersilia non
			# dice mai il suo tic, e l'audit l'ha preso. L'esempio è un esempio,
			# la regola dei tic vale anche al Ritrovo.
			{"chi": "w01-ersilia", "dice": "Canta invece di contare, cuore, che fai prima."},
			{"chi": "w01-tobia", "dice": "La tua canzone non è contare, nonna."},
			{"chi": "w01-ersilia", "dice": "No? «Sette, quattordici, ventuno…» Boh. Mia madre la faceva così."},
		],
		"notizia": {
			"indice": 1,
			"chi": "w01-ersilia",
			"dice": "Dicono che quella ragazzina nuova abbia contato il filare est in tre respiri.",
		},
		"congedo": {"chi": "w01-ersilia", "dice": "Oh! Cuore, eri lì? Vieni, che il pane è ancora caldo."},
	},
	"w01-s1": {
		"world": 1,
		"stadio": 1,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-tobia", "dice": "Nonna. Quella tua canzone. Di quanto sale per volta?"},
			{"chi": "w01-ersilia", "dice": "Sale? Non sale niente, cuore. Canta."},
			{"chi": "w01-tobia", "dice": "Sette, quattordici, ventuno. Sono sette. Sette per volta, e uno."},
			{"chi": "w01-ersilia", "dice": "…e allora? È sempre andata così."},
			{"chi": "w01-tobia", "dice": "E allora niente. Solo che io conto a uno a uno e ci metto un'ora, e uno."},
		],
		"notizia": {
			"indice": 3,
			"chi": "w01-ersilia",
			"dice": "Quella ragazzina l'ha rifatto stamattina, al deposito. Senza nemmeno fermarsi, cuore.",
		},
		"congedo": {"chi": "w01-tobia", "dice": "…tu. Da quanto ascolti? Niente, ho perso il segno lo stesso, e uno."},
	},
	"w01-s2": {
		"world": 1,
		"stadio": 2,
		"cast": ["w01-tobia", "w01-ersilia"],
		"scena": [
			{"chi": "w01-ersilia", "dice": "…ventotto, trentacinque. Ecco. E tu dicevi che non era contare."},
			{"chi": "w01-tobia", "dice": "È contare a gruppi. Me l'ha spiegato Eli. Salti di sette, e uno."},
			{"chi": "w01-ersilia", "dice": "E allora perché la mia canzone lo sapeva e io no, cuore?"},
			{"chi": "w01-tobia", "dice": "Perché qualcuno te l'ha insegnata e poi ha smesso di dirti il perché."},
			{"chi": "w01-ersilia", "dice": "…Mah. Cantiamo il nove, adesso?"},
		],
		"notizia": {
			"indice": 2,
			"chi": "w01-ersilia",
			"dice": "Da quando è arrivata quella ragazzina, qui si fanno i conti cantando, cuore.",
		},
		"congedo": {"chi": "w01-ersilia", "dice": "Cuore! Siamo qui a contare in musica. Vieni a sentire."},
	},
}

static func scene(scene_id: String) -> Dictionary:
	return (SCENES.get(scene_id, {}) as Dictionary).duplicate(true)

## La scena di un mondo per lo stadio richiesto, se esiste. Vuota vuol dire
## «Ritrovo normale», non errore.
static func scene_for(world: int, stadio: int) -> Dictionary:
	for key in SCENES.keys():
		var data := SCENES[key] as Dictionary
		if int(data.get("world", 0)) == world and int(data.get("stadio", -1)) == stadio:
			var out := data.duplicate(true)
			out["id"] = str(key)
			return out
	return {}

## Le battute nell'ordine in cui vanno recitate. Con `con_notizia` la battuta
## all'indice dichiarato viene sostituita da quella che cita il giocatore.
static func lines_of(scene_id: String, con_notizia: bool = false) -> Array:
	var data := SCENES.get(scene_id, {}) as Dictionary
	if data.is_empty():
		return []
	var lines: Array = (data.get("scena", []) as Array).duplicate(true)
	if con_notizia and data.has("notizia"):
		var news := data["notizia"] as Dictionary
		var index := int(news.get("indice", -1))
		if index >= 0 and index < lines.size():
			lines[index] = {"chi": str(news["chi"]), "dice": str(news["dice"])}
	return lines

## Quanti mondi hanno tutte e tre le scene.
static func complete_worlds() -> Array:
	var per_world: Dictionary = {}
	for key in SCENES.keys():
		var data := SCENES[key] as Dictionary
		var world := int(data.get("world", 0))
		var stages: Array = per_world.get(world, [])
		stages.append(int(data.get("stadio", -1)))
		per_world[world] = stages
	var complete: Array = []
	for world in per_world.keys():
		var stages: Array = per_world[world]
		if stages.has(0) and stages.has(1) and stages.has(2):
			complete.append(int(world))
	complete.sort()
	return complete
