extends SceneTree

## **Se un argomento conta per la copertura, deve poter comparire in un esame.**
## (6 agosto 2026)
##
## Difetto trovato indagando come i minigiochi completano la gamma: i due
## vocabolari di argomento divergevano. La COPERTURA del gate conta gli argomenti
## toccati — anche quelli praticati nei minigiochi — ma il bersaglio si calcola su
## `reachable_topic_count`, che campiona il **banco**. Risultato: 104 argomenti su
## 241 potevano soddisfare la copertura di un livello senza che l'esame, che nasce
## dal banco, potesse mai interrogarli.
##
## Era massimo proprio dove i minigiochi danno il contributo migliore: inglese
## (21), coding (14), scienze (13), fisica (12), elettronica (11).
##
## Questo è un **cricchetto di avvicinamento**: il numero può solo scendere.
## Non si pretende zero — sarebbe una promessa che blocca il lavoro invece di
## guidarlo — si pretende che nessuna modifica lo faccia risalire.

## **104 → 102 il 18 agosto 2026.** Prima discesa del cricchetto.
##
## Il primo tentativo di allineamento — 63 item di grammatica inglese su 21
## argomenti — portava il totale da 104 a 88, ed era stato annullato.
## `topic_density_audit` dichiara inglese COMPLETA allo standard di quindici item
## per argomento, e quei ventun argomenti nuovi ne avevano tre: avrebbe allargato
## la gamma degradando una garanzia di profondità già guadagnata. Portarli allo
## standard vuol dire duecentocinquantadue item in più per la sola inglese: è il
## costo vero dell'allineamento, e va pianificato.
##
## La discesa a 102 è italiano, e paga il prezzo pieno invece di aggirarlo.
## `tempi-indicativo`, `modi-verbali` e `modi-indefiniti` erano tre argomenti che
## i minigiochi servivano da tempo e che l'esame non poteva chiedere: ora hanno
## quindici item ciascuno, la soglia di densità, non tre.
##
## Restano sei argomenti italiani fuori — categorie, contrari, definizioni,
## modi-di-dire, morfologia, sinonimi — e sono tutti di area lessicale. È il
## prossimo lotto sensato: hanno bisogno dello stesso trattamento, non di una
## soglia più larga.
const DISALLINEATI_MAX := 102

const LIVELLI := [1, 4, 8, 12, 16, 20, 24]
const GIRI := 20

func _init() -> void:
	var content := ContentManager.new()
	var mg := MinigameManager.new()
	var totale := 0
	var peggiore := ""
	var peggiore_n := 0
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		var banco: Dictionary = {}
		var mini: Dictionary = {}
		for livello in LIVELLI:
			for seme in range(GIRI):
				var r1 := RandomNumberGenerator.new()
				r1.seed = seme * 7919 + livello * 131
				for n in Array(content.build_mission(subject, livello, 4, {}, r1).get("nodes", [])):
					banco[str((n as Dictionary).get("topic", ""))] = true
				var r2 := RandomNumberGenerator.new()
				r2.seed = seme * 104729 + livello * 17
				for n in Array(mg.build_minigame(subject, livello, r2).get("nodes", [])):
					mini[str((n as Dictionary).get("topic", ""))] = true
		var soli := 0
		for t in mini.keys():
			if not banco.has(t):
				soli += 1
		totale += soli
		if soli > peggiore_n:
			peggiore_n = soli
			peggiore = subject
	assert(totale <= DISALLINEATI_MAX,
		"argomenti che il gate conta ma l'esame non può interrogare: %d (massimo %d). Peggiore: %s con %d." % [
			totale, DISALLINEATI_MAX, peggiore, peggiore_n])
	print("TOPIC ALIGNMENT audit OK — %d argomenti ancora solo-minigioco (tetto %d, peggiore %s)" % [
		totale, DISALLINEATI_MAX, peggiore])
	quit(0)
