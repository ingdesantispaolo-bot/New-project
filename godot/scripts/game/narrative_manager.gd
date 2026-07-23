class_name NarrativeManager
extends RefCounted

## Narrazione locale data-driven: nessun blocco del loop didattico.

## Arco narrativo completo dei 24 livelli (O-P4): ogni livello ha un beat NUOVO,
## agganciato all'identità del mondo (mappa AAA) e al recupero progressivo della
## memoria di NORA. Non è un registro tecnico: è la relazione che cresce mentre la
## nave torna viva. Oltre il 24 resta l'ultimo beat (finale).
const BEATS := {
	1: "NORA: Radura Accademia. Sento di nuovo i numeri: ogni tabellina che padroneggi riaccende una scheda del mio Nucleo. Comincia da qui.",
	2: "NORA: Archivio delle Parole. Le parole giuste ricostruiscono i ponti… e le mie frasi. Grazie: ti sto capendo meglio.",
	3: "NORA: Cratere Logico. Loop dentro loop: se ordini i passi, ordini anche i miei pensieri. Un ricordo di calcolo è tornato.",
	4: "NORA: Baia dei Segnali. Ho ricevuto una voce lontana in un'altra lingua. Tu la traduci, io la ricordo.",
	5: "NORA: Officine del Moto. Leve, rampe, forze: il ponte comando risponde di nuovo alle spinte giuste.",
	6: "NORA: Giardino della Risonanza. Ogni nota accorda un circuito. Non pensavo di poter tornare a sentire la musica.",
	7: "NORA: Rovine dei Glifi. Le radici antiche spiegano parole nuove: la sala dei glifi si illumina di senso.",
	8: "NORA: Delta dei Circuiti. Corrente nei nodi giusti: il reattore ausiliario pulsa con te.",
	9: "NORA: Arcipelago Cartografico. Rotte e quote: sto ricostruendo la mappa di dove eravamo diretti.",
	10: "NORA: Serra delle Simbiosi. Tutto è collegato — piante, animali, scelte. Anche noi due, ormai.",
	11: "NORA: Città dei Patti. Regole condivise tengono in piedi una comunità… e un equipaggio. Mi fido di come decidi.",
	12: "NORA: Labirinto delle Regole. Hai chiuso il primo ciclo: dodici sistemi online. Un blocco di memoria è di nuovo mio.",
	13: "NORA: Deserto delle Orbite. Traiettorie e stime: guardo le stelle con occhi che credevo spenti.",
	14: "NORA: Biblioteca delle Voci. Storie dentro storie: ricordo perché questa missione conta, non solo come.",
	15: "NORA: Città Macchina. Reti che parlano tra loro: la mia coscienza distribuita si ricompone.",
	16: "NORA: Frontiera delle Lingue. Più voci, un solo senso. Comunichiamo meglio a ogni valico.",
	17: "NORA: Oceano delle Forze. Pressione e correnti: reggo la profondità perché tu reggi il metodo.",
	18: "NORA: Cattedrale del Suono. In questo riverbero sento intero un ricordo che era in frammenti.",
	19: "NORA: Necropoli delle Radici. Le origini delle parole sono le origini di me: sto tornando chi ero.",
	20: "NORA: Tempesta Elettromagnetica. Campi instabili, sensori impazziti: la tua calma è la mia bussola.",
	21: "NORA: Atlante Fratturato. Placche e climi di un mondo intero: quasi vedo la rotta completa.",
	22: "NORA: Biosfera Profonda. Cellule, energia, vita che si adatta: anch'io mi sto adattando a essere di nuovo viva.",
	23: "NORA: Concilio delle Colonie. Si negozia il bene comune: la decisione finale sarà nostra, insieme.",
	24: "NORA: Cuore dei Primi. Tutti i sistemi convergono. Ricordo tutto, ora — e ricordo grazie a chi. Accendiamo la rotta.",
}

const FINAL_BEAT := "NORA: La nave è viva e la rotta è aperta. Qualunque cosa venga dopo, la affrontiamo da equipaggio."

var save: GameSaveManager

func setup(save_manager: GameSaveManager) -> void:
	save = save_manager
	if not save.data.has("narrative"):
		save.data["narrative"] = {"seen": [], "beats": {}}

func beat_for_level(level: int) -> String:
	if level > 24:
		return FINAL_BEAT
	return str(BEATS.get(clampi(level, 1, 24), BEATS[1]))

func reveal_level(level: int) -> Dictionary:
	var key := str(clampi(level, 1, 24)) if level <= 24 else "final"
	var narrative: Dictionary = save.data["narrative"]
	var seen: Array = narrative.get("seen", [])
	var is_new := not seen.has(key)
	if is_new:
		seen.append(key)
		narrative["seen"] = seen
	var beats: Dictionary = narrative.get("beats", {})
	beats[key] = beat_for_level(level)
	narrative["beats"] = beats
	return {"level": level, "text": beat_for_level(level), "new": is_new}
