extends SceneTree

## Verifica `engineer_legend_catalog.gd` contro le regole vincolanti di
## `docs/ABITANTI_E_LUOGHI.md` §2.5: una voce per registro, «Paolo» come nome
## proprio confinato a buffo/divertente/caloroso e mai in solenne o
## misterioso, nessuna riga oltre le tre schermate, nessun duplicato, e la
## leggenda non deve mai comparire nei testi vincolati alla trama (24 beat,
## Tracce, colpi di scena) — quelli restano di `mystery_catalog.gd` e
## `narrative_manager.gd`, e questo audit controlla che il pool non li citi né
## viceversa.

const MAX_SCREENS := 3

func _init() -> void:
	var failures: Array = []

	for registro in EngineerLegendCatalog.REGISTRI:
		var lines: Array = EngineerLegendCatalog.POOLS.get(registro, [])
		if lines.size() < 3:
			failures.append("registro «%s»: %d righe, minimo 3" % [registro, lines.size()])
		failures.append_array(_check_screens(registro, lines))

	for key in EngineerLegendCatalog.POOLS.keys():
		if not EngineerLegendCatalog.REGISTRI.has(key):
			failures.append("registro sconosciuto nel pool: «%s»" % key)

	failures.append_array(_check_nome_proprio())
	failures.append_array(_check_duplicati())
	failures.append_array(_check_non_tocca_il_mistero())

	if not failures.is_empty():
		printerr("LEGGENDA DELL'INGEGNERE NON VALIDA — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Engineer legend audit OK — %d registri, %d righe in tutto, nessun collegamento al mistero" % [
		EngineerLegendCatalog.REGISTRI.size(), EngineerLegendCatalog.all_lines().size()])
	quit(0)

func _check_screens(registro: String, lines: Array) -> Array:
	var out: Array = []
	for line_data in lines:
		var screens: Array = line_data
		if screens.is_empty():
			out.append("%s: riga senza schermate" % registro)
		elif screens.size() > MAX_SCREENS:
			out.append("%s: riga di %d schermate, massimo %d" % [registro, screens.size(), MAX_SCREENS])
		for screen in screens:
			if str(screen).strip_edges() == "":
				out.append("%s: schermata vuota" % registro)
	return out

## Regola 1 di §2.5: «Paolo» come nome proprio mai da un registro solenne o
## misterioso, e per costruzione confinato ai tre registri dichiarati.
func _check_nome_proprio() -> Array:
	var out: Array = []
	for registro in EngineerLegendCatalog.REGISTRI:
		var lines: Array = EngineerLegendCatalog.POOLS.get(registro, [])
		var testo := ""
		for line_data in lines:
			testo += " ".join(PackedStringArray(line_data)) + " "
		var menziona := testo.to_lower().contains("paolo")
		if menziona and EngineerLegendCatalog.REGISTRI_SENZA_NOME.has(registro):
			out.append("registro «%s»: nomina «Paolo», ma è un registro che deve dire solo «l'Ingegnere»" % registro)
		if menziona and not EngineerLegendCatalog.REGISTRI_CON_NOME.has(registro):
			out.append("registro «%s»: nomina «Paolo» fuori dai registri autorizzati (%s)" % [
				registro, ", ".join(PackedStringArray(EngineerLegendCatalog.REGISTRI_CON_NOME))])
	return out

func _check_duplicati() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for registro in EngineerLegendCatalog.POOLS.keys():
		for line_data in Array(EngineerLegendCatalog.POOLS[registro]):
			var key := "|".join(PackedStringArray(line_data as Array))
			if seen.has(key):
				out.append("riga ripetuta fra «%s» e «%s»: %s" % [str(seen[key]), registro, key])
			else:
				seen[key] = registro
	return out

## Regola vincolante di TRAMA_E_MISTERO.md §10.10: la leggenda resta un
## pettegolezzo, mai una risposta. Non deve mai nominare i Primi, NORA, il
## Tredicesimo o Scala — collegarla a loro la trasformerebbe in un ottavo
## colpo di scena non seminato e non verificato da `mystery_audit`.
const TERMINI_VIETATI := ["primi", "nora", "tredicesimo", "scala", "meridiana", "silenzio"]

func _check_non_tocca_il_mistero() -> Array:
	var out: Array = []
	for registro in EngineerLegendCatalog.POOLS.keys():
		for line_data in Array(EngineerLegendCatalog.POOLS[registro]):
			var testo := " ".join(PackedStringArray(line_data as Array)).to_lower()
			for termine in TERMINI_VIETATI:
				if testo.contains(termine):
					out.append("registro «%s»: la riga nomina «%s», che appartiene al mistero vero — la leggenda dell'Ingegnere deve restarne separata" % [
						registro, termine])
	return out
