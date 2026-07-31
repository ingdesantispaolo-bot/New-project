extends SceneTree

## Audit di VARIETÀ REALE: quante prove DISTINTE vede uno studente giocando.
##
## Nasce da una segnalazione grave (31 luglio): «italiano e matematica sono sempre
## gli stessi, non solo la tipologia ma anche gli stessi numeri: lo studente si
## trova due prove uguali».
##
## Gli audit esistenti misurano la varietà dei FORMATI (`format_mix`) e la
## profondità degli argomenti (`content_depth`). Nessuno misurava la cosa che il
## bambino percepisce: **quante prove diverse gli capitano davvero**. Un mondo può
## essere perfetto su formati e argomenti e servire cinque volte la stessa
## identica moltiplicazione.
##
## La firma di una prova è il testo + la risposta: due nodi con la stessa firma
## sono la stessa prova per chi la gioca, anche se hanno id diversi.

const MISSIONS := 10
const NODES_PER_MISSION := 3

# --- CRICCHETTO, non promozione ------------------------------------------------
# Questi due numeri sono lo stato ATTUALE, non lo stato accettabile. Servono a
# impedire che la varietà peggiori mentre il contenuto cresce; **possono solo
# scendere**. Chi li alza sta nascondendo una regressione.
#
# UNICA ECCEZIONE, il 31 luglio 2026 (Fase 0): sono stati rialzati da 0,38 e ×8 a
# 0,67 e ×8 perché è cambiata la MISURA, non il contenuto. Fino a quel giorno la
# firma serializzava i payload così com'erano, quindi la stessa identica prova
# ripresentata con gli elementi in altro ordine — o con le righe rimescolate —
# contava come nuova. I vecchi numeri descrivevano un gioco più vario di quello
# che esisteva davvero. I nuovi sono i primi onesti, e da qui in poi la regola
# torna valida senza eccezioni.
#
# Nota: sotto la misura onesta alcune materie sono MIGLIORATE (fisica ×8 → ×4,
# scienze ×7 → ×5, inglese ×6 → ×2), perché unificando la firma la memoria
# anti-ripetizione ha ricominciato a scattare sui formati specialisti, dove era
# spenta da sempre. Altre sono peggiorate sulla carta (storia, logica, musica):
# erano già così, non si vedeva.
#
# Bersaglio dichiarato: MAX_SAME_EXERCISE = 3 e MAX_REPEAT_SHARE = 0.20.
# Non è raggiungibile con l'algoritmo: ai livelli bassi il gate `minLevel` lascia
# UNA SOLA specifica per formato specialista, e l'80% delle campate passa di lì.
# Serve contenuto — specifiche a insieme o banchi più profondi — non selezione
# più furba. Il piano è in docs/PROFONDITA_CONTENUTI.md; quanto contenuto serve
# davvero lo dice `combinatorial_depth_audit`, non questo audit.
#
# SECONDA E ULTIMA correzione di misura, sempre il 31 luglio (Fase 1). L'audit
# giocava UNA partita casuale: la stessa materia oscillava fra il 60% e il 70% da
# un giro all'altro, quindi passava o falliva a seconda della fortuna. Ora gioca
# cinque partite a semi fissi e riporta la peggiore — deterministico e più severo.
# I numeri salgono da 0,60/×7 a 0,70/×8 perché la partita peggiore era già lì e
# non veniva sempre pescata.
#
# Con questo la strumentazione è finita: da qui in poi ogni movimento di questi
# due numeri è contenuto, e possono solo scendere.
#
# Il nucleo — italiano, matematica, inglese — è a ×1 e 0–3%, cioè oltre il
# bersaglio finale. Questi due numeri restano alti perché li detta STORIA, la
# materia più povera, che tocca alla Fase 2: un cricchetto globale misura sempre
# il peggiore, mai la media.
#
# Fase 2 (banchi magri): 0,70 → 0,50 e ×8 → ×7.
# Fase 3 (latino, geografia, logica): 0,50 → 0,17 e ×7 → ×4.
#
# Dodici materie su dodici sono ora fra ×1 e ×4, e il bersaglio dichiarato in
# docs/PROFONDITA_CONTENUTI.md era ×3 · 0,20. La quota di ripetizioni è **sotto**
# il bersaglio; il ×4 residuo è di logica al primo mondo e NON è un problema di
# insiemi: viene dalla caccia all'errore, che è un formato a dato fisso dove ogni
# specifica vale una prova sola. Portarlo a ×3 vuol dire più specifiche
# specialiste ai livelli bassi — che è la Fase 4, non altro contenuto a insieme.
const MAX_REPEAT_SHARE := 0.17
const MAX_SAME_EXERCISE := 4

## La firma è quella condivisa con il gioco (`ExerciseSignature`), non una copia.
##
## La versione precedente serializzava i payload così com'erano: gli elementi
## mescolati e il numero della riga giusta finivano nella chiave, quindi la stessa
## identica prova ripresentata in altro ordine risultava NUOVA. La misura vedeva
## varietà dove il bambino vedeva lo stesso esercizio. Un audit che misura una
## chiave diversa da quella che il gioco usa per non ripetersi misura la cosa
## sbagliata due volte.
static func signature(node: Dictionary) -> String:
	return ExerciseSignature.of(node)

## Semi fissi. Prima l'audit lasciava che ContentManager si randomizzasse da solo:
## la stessa materia oscillava fra il 60% e il 70% di ripetizioni da un giro
## all'altro, e un cricchetto su un numero che balla non difende niente — o passa
## per fortuna, o fallisce per sfortuna. Con semi fissi il verdetto è ripetibile;
## per non misurare una singola partita fortunata se ne giocano cinque e si
## riporta la PEGGIORE, che è la partita che un bambino può davvero capitare.
const SEEDS := [11, 404, 1337, 90210, 777001]

func _init() -> void:
	var failures: Array = []
	print("Varietà reale — %d missioni da %d campate per materia, peggiore di %d partite" % [
		MISSIONS, NODES_PER_MISSION, SEEDS.size()])
	print("%-13s %s" % ["MATERIA", "  L1: distinte/tot (ripetute)   L13: distinte/tot (ripetute)   peggiore"])

	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var low := _worst_of_seeds(subject, 1)
		var high := _worst_of_seeds(subject, 13)
		print("%-13s   L1: %2d/%2d (%3.0f%%)            L13: %2d/%2d (%3.0f%%)          ×%d %s" % [
			subject,
			int(low["distinct"]), int(low["total"]), float(low["repeatShare"]) * 100.0,
			int(high["distinct"]), int(high["total"]), float(high["repeatShare"]) * 100.0,
			int(low["worst"]), str(low["worstFormat"])])
		for stats in [low, high]:
			if int(stats["worst"]) > MAX_SAME_EXERCISE:
				failures.append("%s L%d: la stessa prova (%s) ricapita %d volte su %d (max %d)" % [
					subject, int(stats["level"]), str(stats["worstFormat"]),
					int(stats["worst"]), int(stats["total"]), MAX_SAME_EXERCISE])
			if float(stats["repeatShare"]) > MAX_REPEAT_SHARE:
				failures.append("%s L%d: il %.0f%% delle prove è una ripetizione (max %.0f%%), la peggiore vista %d volte" % [
					subject, int(stats["level"]), float(stats["repeatShare"]) * 100.0,
					MAX_REPEAT_SHARE * 100.0, int(stats["worst"])])

	if not failures.is_empty():
		printerr("VARIETÀ ROSSA — %d problemi:" % failures.size())
		for failure in failures:
			printerr("  - %s" % failure)
		quit(1)
		return
	print("Variety audit OK — nessuna materia oltre il %.0f%% di ripetizioni" % (MAX_REPEAT_SHARE * 100.0))
	quit(0)

## La partita peggiore fra i semi: si giudica su quella, non sulla media.
func _worst_of_seeds(subject: String, level: int) -> Dictionary:
	var worst: Dictionary = {}
	for seed_value in SEEDS:
		var stats := _measure(subject, level, int(seed_value))
		if worst.is_empty() or float(stats["repeatShare"]) > float(worst["repeatShare"]):
			worst = stats
		elif int(stats["worst"]) > int(worst["worst"]):
			worst = stats
	return worst

## Simula una sessione di gioco realistica: missioni consecutive della stessa
## materia con lo STESSO ContentManager (la memoria anti-ripetizione dura quanto
## il mondo), a partire da un seme dichiarato.
func _measure(subject: String, level: int, seed_value: int) -> Dictionary:
	var content := ContentManager.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var seen: Dictionary = {}
	var formats: Dictionary = {}
	var total := 0
	for index in range(MISSIONS):
		var session := content.build_varied_mission(subject, level, NODES_PER_MISSION, {}, rng)
		for node_data in session.get("nodes", []):
			var key := signature(node_data)
			seen[key] = int(seen.get(key, 0)) + 1
			formats[key] = str((node_data as Dictionary).get("format", "?"))
			total += 1
	var worst := 0
	var worst_format := ""
	for key in seen.keys():
		if int(seen[key]) > worst:
			worst = int(seen[key])
			worst_format = str(formats.get(key, "?"))
	var distinct := seen.size()
	return {
		"level": level,
		"total": total,
		"distinct": distinct,
		"worst": worst,
		"repeatShare": float(total - distinct) / float(maxi(1, total)),
		"worstFormat": worst_format,
	}
