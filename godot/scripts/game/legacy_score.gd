class_name LegacyScore
extends RefCounted

## **Il Lascito**: che cosa resta di un giocatore quando la nave riparte.
##
## Serve a scegliere il finale, e il modo in cui è costruito è una decisione di
## progetto più che di codice.
##
## **Che cosa NON pesa, e perché.** Non pesano i frammenti guadagnati, i cosmetici
## comprati, le ore giocate, né la velocità. Se pesassero, un bambino potrebbe
## **comprarsi un finale migliore** — e un gioco che si studia non può vendere il
## proprio epilogo. Non pesa nemmeno il numero di risposte esatte in assoluto:
## chi gioca di più ne accumula di più senza sapere una cosa in più.
##
## **Che cosa pesa.** Cinque dimensioni, tutte già nel salvataggio e tutte
## riferite a qualcosa che il bambino *sa* o *ha cambiato*:
##
##   PADRONANZA   quanto sa, con il nucleo che conta doppio (direzione del
##                6 agosto: italiano, matematica e inglese hanno rango superiore);
##   RITENZIONE   argomenti che il Codex dà per consolidati — sapere che è
##                rimasto, non sapere che è passato;
##   MONDO        incontri risolti nei mondi: le persone e i luoghi che hai
##                effettivamente cambiato, non quelli che hai attraversato;
##   ROTTA        mondi aperti, cioè quanto lontano sei arrivata;
##   INDAGINE     beat di trama visti: quanto della storia hai davvero raccolto.
##
## **Nessuna dimensione può essere negativa e nessuna scende mai.** È lo stesso
## guard-rail del diario e del legame col Custode: un gioco che si studia non
## può togliere qualcosa a chi torna dopo una settimana.

## I pesi. Sommano a 1. La padronanza pesa più di tutto perché è la promessa del
## gioco; l'indagine pesa meno non perché conti poco, ma perché dipende dal
## passare nei mondi, cosa che si fa comunque.
const PESI := {
	"padronanza": 0.30,
	"ritenzione": 0.25,
	"mondo": 0.20,
	"rotta": 0.15,
	"indagine": 0.10,
}

## Quanto vale una materia del nucleo rispetto a una satellite.
const PESO_NUCLEO := 2.0

## Traguardi di riferimento. Non sono massimi teorici — sono i valori oltre i
## quali una dimensione si considera piena: pretendere il 100% teorico
## renderebbe l'ultimo finale irraggiungibile, e un finale irraggiungibile non
## esiste per il giocatore.
const META_CONSOLIDATI := 60      # argomenti consolidati nel Codex
const META_INCONTRI := 90         # incontri risolti nei mondi
const META_BEAT := 24             # beat di trama

static func _clamp01(v: float) -> float:
	return clampf(v, 0.0, 1.0)

## La padronanza media pesata sulle dodici materie.
static func padronanza(save) -> float:
	var somma := 0.0
	var pesi := 0.0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var peso := PESO_NUCLEO if ApparatusConfig.is_core(subject) else 1.0
		somma += _clamp01(float(save.mastery_of(subject))) * peso
		pesi += peso
	return _clamp01(somma / maxf(pesi, 0.01))

static func ritenzione(save) -> float:
	var consolidati := 0
	for stato in Dictionary(save.data.get("codex", {})).values():
		if str(stato) == KnowledgeCodex.STATE_CONSOLIDATED:
			consolidati += 1
	return _clamp01(float(consolidati) / float(META_CONSOLIDATI))

## Gli incontri risolti in tutti i mondi: le persone e i luoghi che hai
## cambiato. Non conta i mondi attraversati — quelli sono la ROTTA.
static func mondo(save) -> float:
	var risolti := 0
	for progresso in Dictionary(save.data.get("worldProgress", {})).values():
		risolti += Array(Dictionary(progresso).get("completedEncounterIds", [])).size()
	return _clamp01(float(risolti) / float(META_INCONTRI))

static func rotta(save) -> float:
	var aperti := Array(Dictionary(save.data.get("worlds", {})).get("unlocked", [])).size()
	return _clamp01(float(aperti) / float(ApparatusConfig.MAX_LEVEL))

static func indagine(save) -> float:
	var visti := Array(Dictionary(save.data.get("narrative", {})).get("seen", [])).size()
	return _clamp01(float(visti) / float(META_BEAT))

## Tutte le dimensioni più il totale pesato. Pura: non scrive niente, così la si
## può chiamare per disegnare una schermata senza effetti collaterali.
static func valuta(save) -> Dictionary:
	var d := {
		"padronanza": padronanza(save),
		"ritenzione": ritenzione(save),
		"mondo": mondo(save),
		"rotta": rotta(save),
		"indagine": indagine(save),
	}
	var totale := 0.0
	for chiave in PESI.keys():
		totale += float(d[chiave]) * float(PESI[chiave])
	d["totale"] = _clamp01(totale)
	d["finale"] = finale_di(d)
	return d

## La dimensione in cui il giocatore ha dato di più, **al netto del suo livello
## generale**: si guarda quanto ogni dimensione supera la media, non il valore
## assoluto. Senza questa normalizzazione vincerebbe sempre la ROTTA, che sale
## da sola avanzando.
static func dominante(d: Dictionary) -> String:
	var media := 0.0
	for chiave in PESI.keys():
		media += float(d.get(chiave, 0.0))
	media /= float(PESI.size())
	var migliore := ""
	var scarto_migliore := 0.0
	# Ordine fisso: a parità di scarto vince sempre la stessa, invece di
	# dipendere dall'ordine di iterazione di un dizionario.
	for chiave in ["ritenzione", "mondo", "indagine", "padronanza", "rotta"]:
		var scarto := float(d.get(chiave, 0.0)) - media
		if scarto > scarto_migliore:
			scarto_migliore = scarto
			migliore = str(chiave)
	# Sotto questa soglia il profilo è equilibrato: nessuna dimensione spicca, e
	# fingere una specializzazione sarebbe una lettura falsa del giocatore.
	if scarto_migliore < 0.12:
		return ""
	return migliore

## Quale finale. `SOGLIA_PIENO` apre l'epilogo lungo; sotto, l'epilogo prende la
## forma di ciò che il giocatore ha fatto di più.
const SOGLIA_PIENO := 0.82

static func finale_di(d: Dictionary) -> String:
	if float(d.get("totale", 0.0)) >= SOGLIA_PIENO:
		return "fondo"
	var dom := dominante(d)
	match dom:
		"ritenzione":
			return "registro"
		"mondo":
			return "circuito"
		"indagine":
			return "soglia"
		"padronanza":
			return "cattedra"
		_:
			return "rotta"
