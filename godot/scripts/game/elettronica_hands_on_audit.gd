extends SceneTree

## **Elettronica si impara facendo, non riconoscendo.** (7 agosto 2026)
##
## Direttiva del committente: «dobbiamo creare minigiochi che insegnino i
## concetti e lasciare le domande a scelta multipla solo nell'esame di livello».
## Elettronica è la materia da cui è nata la segnalazione ed è quella su cui la
## direttiva si prova prima di estenderla alle altre undici.
##
## **Che cosa protegge, e perché non basta averlo fatto una volta.** Il mix dei
## formati nasce da una manopola (`MC_TARGET_PER_MATERIA`) e da una tavolozza di
## minigiochi. Se un giorno la tavolozza si assottiglia — per un `minLevel`
## spostato, per una specifica tolta — la sostituzione non trova più materiale e
## **le domande a scelta multipla tornano da sole**, senza che nessuno abbia
## deciso di rimetterle. Questo audit se ne accorge.
##
## Tre cose, e la terza è quella che tiene in piedi le altre due:
##
##   1. fuori dall'esame, in elettronica, **zero** scelta multipla e **zero**
##      risposte aperte a ogni livello;
##   2. nell'esame la scelta multipla c'è, ed è la maggioranza: misurare è
##      un'altra attività dall'imparare, e lì la domanda secca è lo strumento
##      giusto;
##   3. le forme interattive che prendono il posto sono **varie**: sostituire
##      tutta la scelta multipla con un unico formato sarebbe soltanto un altro
##      modo di essere monotoni.

const OK := "ELETTRONICA HANDS-ON audit VERDE"
const MATERIA := "elettronica"
const SESSIONI := 120
const LIVELLI := [1, 3, 5, 8, 12, 16, 20, 24]
## Sotto questo numero di formati distinti la varietà è finta: si sono spostate
## le domande da una gabbia a un'altra.
const FORMATI_MINIMI := 4

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_niente_domande_secche_fuori_dall_esame()
	_l_esame_misura_ancora()
	if errori.is_empty():
		print(OK)
	else:
		printerr("ELETTRONICA HANDS-ON audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _niente_domande_secche_fuori_dall_esame() -> void:
	var content := ContentManager.new()
	for level in LIVELLI:
		var conta: Dictionary = {}
		var totale := 0
		for _giro in range(SESSIONI):
			var sessione := content.build_varied_mission(MATERIA, level, 3, {}, null, 0.3, {})
			for raw in Array(sessione.get("nodes", [])):
				var formato := str(Dictionary(raw).get("format", ""))
				conta[formato] = int(conta.get(formato, 0)) + 1
				totale += 1
		if totale == 0:
			_fallisci("livello %d: nessuna prova generata" % level)
			continue
		var secche := int(conta.get("multiple_choice", 0)) + int(conta.get("short_answer", 0))
		if secche > 0:
			_fallisci(
				"livello %d: %d prove su %d sono ancora domande secche (%.1f%%) — "
				% [level, secche, totale, 100.0 * float(secche) / float(totale)]
				+ "la tavolozza dei minigiochi non copre più tutti gli argomenti")
		if conta.size() < FORMATI_MINIMI:
			_fallisci("livello %d: solo %d formati diversi (%s): varietà di facciata" % [
				level, conta.size(), ", ".join(PackedStringArray(conta.keys()))])
		# Nessun formato può prendersi più di metà dell'esperienza: sostituire la
		# scelta multipla con un solo minigioco ripetuto sarebbe lo stesso difetto
		# con un altro nome.
		for formato in conta.keys():
			var quota := float(conta[formato]) / float(totale)
			if quota > 0.5:
				_fallisci("livello %d: «%s» copre il %.0f%% delle prove" % [
					level, formato, quota * 100.0])

## L'esame resta a domande secche: è il posto in cui si misura, e misurare non è
## insegnare. Se un giorno sparissero anche di lì, la materia non avrebbe più
## nessun momento di verifica — e la direttiva diceva «solo nell'esame», non
## «da nessuna parte».
func _l_esame_misura_ancora() -> void:
	var content := ContentManager.new()
	for level in [1, 8, 20]:
		var secche := 0
		var totale := 0
		for _giro in range(60):
			var esame := content.build_final_exam(MATERIA, level, 5, null, 0.4, {})
			for raw in Array(esame.get("nodes", [])):
				var formato := str(Dictionary(raw).get("format", ""))
				if formato == "multiple_choice" or formato == "short_answer":
					secche += 1
				totale += 1
		if totale == 0:
			_fallisci("esame livello %d: nessuna prova generata" % level)
			continue
		var quota := float(secche) / float(totale)
		if quota < 0.5:
			_fallisci("esame livello %d: solo il %.0f%% di domande dirette, non misura più" % [
				level, quota * 100.0])
