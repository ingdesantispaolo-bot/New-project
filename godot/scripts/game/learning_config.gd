class_name LearningConfig
extends RefCounted

## Configurazione dell'esperienza (O-P6): fascia scolastica, curriculum e materie
## ATTIVE. Permette di adattare il gioco a una classe/curriculum senza toccare il
## codice o i contenuti. Vive nel save (`config`). Convenzione: `activeSubjects`
## vuoto = tutte le 12 materie attive (default inclusivo). Le materie disattivate
## non vengono proposte come focus/eventi (il consumer le salta).
##
## Contratto read-only per il runtime: chi genera missioni/eventi consulta
## `is_subject_active`; nessuna materia disattivata deve comparire.
##
## ATTENZIONE (decisione utente del 29 luglio 2026): nel prodotto le 12 materie
## sono TUTTE obbligatorie — i 24 mondi sono 12 materie × 2 comparse e il finale
## accende i dodici sistemi. `activeSubjects` resta un aggancio per sperimentazioni
## in classe, non una configurazione supportata dal gate di consegna: con meno di
## 12 materie la mappa dei mondi e il finale trasversale non hanno più senso.

## Fascia di lancio decisa dall'utente il 29 luglio 2026: 10-13 anni, cioè la
## fine della primaria e la scuola media. È l'arco che i contenuti coprono davvero
## (tabelline e lessico base nei primi mondi, equazioni, Pitagora, declinazioni e
## false friends nei mondi alti) e su cui è tarata la rampa di difficoltà.
const BAND_LAUNCH := "primaria-secondaria-1"
const SCHOOL_BANDS := [BAND_LAUNCH, "primaria", "secondaria-1", "secondaria-2"]
const ALL_SUBJECTS := ["matematica", "italiano", "coding", "inglese", "fisica", "musica", "latino", "elettronica", "geografia", "scienze", "storia", "logica"]

static func _config(save) -> Dictionary:
	if not save.data.has("config"):
		save.data["config"] = {"schoolBand": BAND_LAUNCH, "curriculum": "base", "activeSubjects": []}
	return save.data["config"]

static func school_band(save) -> String:
	return str(_config(save).get("schoolBand", BAND_LAUNCH))

static func set_school_band(save, band: String) -> void:
	if SCHOOL_BANDS.has(band):
		_config(save)["schoolBand"] = band

static func curriculum(save) -> String:
	return str(_config(save).get("curriculum", "base"))

# Materie attive: la lista configurata, oppure TUTTE se la lista è vuota.
static func active_subjects(save) -> Array:
	var configured: Array = Array(_config(save).get("activeSubjects", []))
	if configured.is_empty():
		return ALL_SUBJECTS.duplicate()
	var out: Array = []
	for s in ALL_SUBJECTS:
		if configured.has(s):
			out.append(s)
	return out

static func is_subject_active(save, subject: String) -> bool:
	return active_subjects(save).has(subject)

# Imposta l'insieme di materie attive (deve restare non vuoto: almeno una materia).
static func set_active_subjects(save, subjects: Array) -> bool:
	var valid: Array = []
	for s in subjects:
		if ALL_SUBJECTS.has(str(s)) and not valid.has(str(s)):
			valid.append(str(s))
	if valid.is_empty():
		return false
	_config(save)["activeSubjects"] = valid
	return true
