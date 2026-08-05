extends SceneTree

## **Ogni chiave del salvataggio deve avere qualcuno che la legge.** (5 agosto 2026)
##
## Il difetto che questo audit esiste per impedire si è ripetuto **quattro volte**
## nello stesso progetto:
##
## - `gifts` — i regali del Custode: la schermata ne stampava il numero, e nessuno
##   ne scriveva mai uno. Il contatore diceva zero a tutti, per sempre.
## - `daily` — giorni giocati e serie: dichiarato il primo giorno, mai scritto né
##   letto. I giorni giocati semplicemente non esistevano.
## - `modules` — equipaggiamento moduli: copiato nelle fixture di sette audit,
##   citato nel documento di architettura, mai toccato da una riga di gioco.
## - (fuori dal salvataggio, stessa malattia) i segnali `near_unexplored` e
##   `near_faded`, dichiarati e mai emessi.
##
## Il meccanismo è sempre lo stesso: si dichiara la struttura dati insieme al
## progetto, e poi si costruisce solo metà della funzionalità. La struttura resta
## lì, sembra viva perché è nello schema, e nessun controllo se ne accorge —
## perché tutto quello che la nomina è coerente con se stesso.
##
## La regola qui è minima e meccanica: una chiave dichiarata in `_default_data()`
## deve comparire in **almeno un file di produzione** al di fuori della
## dichiarazione stessa. Non prova che la funzionalità sia finita; prova che
## qualcuno, da qualche parte, quella chiave la usa.
##
## Le fixture degli audit non contano di proposito: `modules` compariva in sette
## audit e in zero righe di gioco. Copiare una chiave in un salvataggio di prova
## non è usarla.

const RADICE := "res://scripts"
const SAVE_MANAGER := "res://scripts/game/save_manager.gd"

func _init() -> void:
	var sorgenti := _sorgenti_di_produzione()
	var corpo := _corpo_default_data()
	assert(corpo != "", "non riesco a leggere `_default_data()` da save_manager.gd")

	var chiavi := GameSaveManager._default_data().keys()
	var orfane: Array = []
	print("Schema del salvataggio — %d chiavi, %d file di produzione\n" % [
		chiavi.size(), sorgenti.size()])

	for chiave_data in chiavi:
		var chiave := str(chiave_data)
		var ago := '"%s"' % chiave
		var lettori: Array = []
		for percorso in sorgenti.keys():
			var testo := str(sorgenti[percorso])
			if percorso == SAVE_MANAGER:
				# Nel gestore la dichiarazione non conta: conta il resto del file,
				# cioè gli accessori. È la differenza fra `mastery` (che ha
				# `mastery_of`/`set_mastery`) e `modules`, che non aveva niente.
				testo = testo.replace(corpo, "")
			if testo.contains(ago):
				lettori.append(percorso.get_file())
		if lettori.is_empty():
			orfane.append(chiave)
		print("%-20s %s" % [
			chiave,
			"ORFANA" if lettori.is_empty() else ", ".join(PackedStringArray(lettori.slice(0, 3)))])

	if orfane.is_empty():
		print("\nSave schema audit OK — nessuna chiave orfana su %d" % chiavi.size())
		quit(0)
	else:
		print("\nSCHEMA ROSSO — %d chiavi dichiarate e mai lette dal gioco:" % orfane.size())
		for chiave in orfane:
			print("  - «%s»: o la si usa, o la si toglie dallo schema." % chiave)
		quit(1)

## Il corpo di `_default_data()`, per poterlo escludere dalla ricerca.
func _corpo_default_data() -> String:
	var testo := _leggi(SAVE_MANAGER)
	var da := testo.find("static func _default_data()")
	if da < 0:
		return ""
	# Il corpo finisce alla prima riga che non è indentata (la funzione dopo).
	var fine := testo.find("\nfunc ", da)
	if fine < 0:
		fine = testo.length()
	return testo.substr(da, fine - da)

func _leggi(percorso: String) -> String:
	var file := FileAccess.open(percorso, FileAccess.READ)
	return file.get_as_text() if file != null else ""

## Tutti i `.gd` sotto res://scripts, esclusi audit, sonde e strumenti di prova:
## una chiave copiata in una fixture non è una chiave usata.
func _sorgenti_di_produzione() -> Dictionary:
	var out := {}
	_raccogli(RADICE, out)
	return out

func _raccogli(cartella: String, out: Dictionary) -> void:
	var dir := DirAccess.open(cartella)
	if dir == null:
		return
	dir.list_dir_begin()
	var nome := dir.get_next()
	while nome != "":
		var percorso := "%s/%s" % [cartella, nome]
		if dir.current_is_dir():
			_raccogli(percorso, out)
		elif nome.ends_with(".gd") and not _e_di_prova(nome):
			out[percorso] = _leggi(percorso)
		nome = dir.get_next()
	dir.list_dir_end()

func _e_di_prova(nome: String) -> bool:
	return nome.contains("_audit") or nome.contains("probe") or nome.contains("autoplay")
