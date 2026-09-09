extends SceneTree

## **Quanto quiz c'è davvero dentro un mondo.** (1 settembre 2026)
##
## `format_mix_audit` conta le ETICHETTE di formato e trova «scelta multipla al
## 10%». Il numero è vero e misura la cosa sbagliata: grafico, circuito, caccia
## all'errore, tracciatore, indiziario, bilancia e composizione sono anch'essi
## «tocca una fra tre o quattro», con un disegno intorno. Sommati, per la logica
## facevano il 30,8% — tre volte il numero sorvegliato.
##
## Questo audit raggruppa i formati per **gesto**, che è la cosa che il bambino
## fa davvero:
##
##   MANIPOLA   trascina, ordina, smista, monta, prova. Il gesto È la competenza.
##   SCEGLIE    tocca una alternativa fra N. La competenza è riconoscerla.
##   DIGITA     scrive la risposta. Nessun elenco da cui pescare.
##
## Nessuno dei tre è sbagliato: una materia sana li mescola. Ma «sceglie» non
## deve essere il gesto dominante, e soprattutto non deve esserlo **all'esame**,
## che è l'ultima cosa giocata di un mondo e quella che resta.
##
## ## L'esame si conta a parte, perché era il caso peggiore
##
## Prima del 1 settembre 2026 `build_final_exam` iniettava UN solo nodo non-MC,
## un numero fisso scritto quando l'esame aveva tre campate. Misurato: l'esame di
## logica era manipolazione al 15% e «tocca una fra N» al 61,3%. Il mondo si
## apriva con la pratica al 75% di manipolazione e si chiudeva col quiz.
##
## ## Il cricchetto
##
## I tetti qui sotto sono i valori MISURATI, congelati. Come per
## `bank_scorciatoie_audit`: scendono e mai salgono. Chi sposta contenuto dentro
## un minigioco abbassa il numero; chi aggiunge quesiti a scelta multipla trova
## rosso subito.
##
## Uso: godot --headless --path godot --script res://scripts/game/gesto_audit.gd

const OK := "GESTO audit VERDE"

## Ripetizioni per mondo: la selezione è stocastica e una sola passata darebbe
## numeri che ballano di qualche punto. Otto, come in `format_mix_audit`.
## **Ripetizioni per mondo.** Portate da 8 a 32 il 4 settembre 2026, e la ragione
## è la stessa che il 1 settembre aveva fatto allargare il campione dell'esame.
##
## Con otto ripetizioni la misura del mondo stava su ~1200 nodi per materia, e
## rieseguendo con un solo seme diverso (`7100` → `7777`, nessuna riga di
## contenuto toccata) i numeri si spostavano fino a **2,3 punti** — storia da
## 29,2 a 26,9, geografia da 27,9 a 29,5, inglese da 27,3 a 25,7. La tolleranza
## del cricchetto è 1,0 punto: **il rumore era più largo della tolleranza**, e
## quattro materie risultavano rosse o verdi a seconda del seme.
##
## Un cricchetto che risponde al seme non è un cricchetto: è un termometro del
## rumore, costa un'indagine a mano a ogni rosso e insegna a ignorare l'audit —
## che è il modo peggiore di perdere una guardia. Con 32 ripetizioni il campione
## quadruplica e le due basi di seme concordano entro 0,8 punti (vedi TETTO_MONDO).
const REPEATS := 32

## Base del seme per la misura del mondo. Esiste come costante perché il modo di
## verificare che un tetto sia reale è **rieseguire con un'altra base e
## confrontare**: se i due numeri non concordano, il tetto sta descrivendo il
## seme. Le basi provate sono 7100 e 7777.
const SEME_MONDO := 7100

## Formati in cui si tocca una alternativa fra quelle offerte. Alcuni hanno un
## disegno sopra (il grafico, il circuito, la bilancia): il disegno cambia che
## cosa si legge, non che cosa si fa con le mani.
const SCEGLIE := [
	"multiple_choice", "graph", "circuit", "cycle", "notation", "map", "hotspot",
	"code_debug", "number_line", "balance", "compose", "trace", "clue",
]

## Formati in cui si sposta, si ordina, si monta o si prova qualcosa.
const MANIPOLA := [
	"matching", "ordering", "classification", "timeline", "swipe",
	"machine_path", "mystery_sample", "verb_decoder", "griglia", "porte",
]

## Formati in cui si scrive la risposta.
const DIGITA := ["numeric_input", "free_text", "text_input", "short_answer"]

## **Quanta oscillazione è rumore e quanta è una scelta.**
##
## La misura è stocastica: la selezione degli esercizi dipende dal seme, e
## spostare contenuto in un'altra materia cambia i semi di tutte. La prima
## stesura congelava il valore esatto con mezzo punto di tolleranza, e otto
## materie su dodici sono diventate rosse per uno scarto che valeva una campata.
##
## Un mondo intero conta più di mille nodi: un nodo vale meno di un decimo di
## punto, e un punto di tolleranza è già generoso. L'esame ne conta ottanta per
## materia: lì un nodo vale 1,25 punti, e sotto i tre punti la differenza è una
## campata in più o in meno, non una decisione di progetto.
##
## I tetti si riscrivono solo VERSO IL BASSO: se una modifica li fa salire,
## la modifica ha peggiorato l'esperienza e va guardata, non ricongelata.
const TOLLERANZA := 1.0
const TOLLERANZA_ESAME := 1.0

## **Quanti esami si costruiscono per (mondo, ripetizione).** (1 settembre 2026)
##
## Con uno solo il campione dell'esame è di ottanta nodi per materia, e un nodo
## vale 1,25 punti: il numero non misurava il progetto, misurava il seme.
## Due prove che lo dimostrano, fatte prima di toccare questa costante:
##
##   - aggiungendo a ITALIANO una sola specifica di linea del tempo — formato
##     manipolativo, contenuto che non può peggiorare niente — il suo esame
##     passava da 38,6% a 42,0% di «sceglie»;
##   - dando all'esame un flusso di numeri casuali suo, senza cambiare una riga
##     di contenuto, elettronica passava da 56,3% a 71,3%.
##
## Un cricchetto che si muove di quindici punti senza che cambi niente non è un
## cricchetto. Cinque campioni per ripetizione portano il campione a quattrocento
## nodi per materia (un nodo vale 0,25 punti) e i numeri smettono di ballare.
const CAMPIONI_ESAME := 15

## **Quota massima di «sceglie» nel mondo intero, materia per materia.**
##
## **Ritarati il 4 settembre 2026 su uno strumento diverso, e va spiegato
## perché non è un allentamento.**
##
## I valori del 1 settembre venivano da otto ripetizioni, cioè ~1200 nodi per
## materia. Su quel campione due basi di seme diverse davano numeri che si
## spostavano fino a **2,3 punti**, contro una tolleranza di 1,0: quattro materie
## risultavano rosse o verdi a seconda del seme, e il cricchetto stava misurando
## il seme quanto il contenuto. Portate le ripetizioni a 32 (~4600–6100 nodi per
## materia), le stesse due basi concordano entro **0,5 punti**.
##
## Quindi i numeri qui sotto **non sono confrontabili con quelli di prima**: sono
## la stessa quantità misurata con uno strumento quattro volte più fine. Ritarare
## un tetto quando si scopre che descriveva il rumore è la stessa eccezione onesta
## già usata il 27 agosto sulle correzioni di NORA — si fa con la misura in mano e
## si scrive la ragione accanto. Da qui in giù, e solo in giù.
##
## Ogni valore è il **peggiore delle due basi**, non la media: un tetto va tenuto
## dal caso sfavorevole.
##
## Quello che il ritaraggio NON cancella: **coding sta al 32,0%**, ed è la sola
## materia vicina al tetto di progetto del 33%. Non è rumore — con entrambe le
## basi e con entrambi i campioni resta la più alta del gioco. È il caso da
## guardare per primo quando si torna sul contenuto.
## ## Riportati sul misurato il 9 settembre 2026
##
## Due lotti dello stesso giorno hanno cambiato questi numeri: il riequilibrio di
## `NONMC_FORMAT_WEIGHTS` — grafico, circuito e caccia all'errore da 25 a 14,
## smistamento e ordinamento da 13 e 15 a 20 — e le due opzioni manipolative
## aggiunte alle fasce 1 e 5 del catalogo di italiano, che hanno chiuso R-18.
##
## Otto tetti su dodici scendono, e alcuni di molto: inglese da 26,6 a 21,3,
## coding da 32,0 a 29,2, italiano da 22,3 a 21,5. Quattro restano dove sono
## perche' il valore misurato piu' un punto di margine li supererebbe, e un
## cricchetto non si allenta: fisica, musica, logica e matematica.
##
## La regola e' la stessa dell'esame: tetto = misurato + 1,0 punto, contro un
## rumore dello strumento di 0,6.
const TETTO_MONDO := {
	#                    base 7100   base 7777
	"matematica": 22.8,
	"italiano": 21.5,
	"coding": 29.2,
	"inglese": 21.3,
	"fisica": 23.5,
	"musica": 24.3,
	"latino": 23.7,
	"elettronica": 23.5,
	"geografia": 25.8,
	"scienze": 25.7,
	"storia": 27.7,
	"logica": 18.0,
	# La logica resta la materia con più manipolazione del gioco (80,6%): scelta
	# multipla e inserimento numerico fuori da tutto ciò che non è l'esame, le sei
	# liste di analogie tornate a italiano, e due formati nuovi in cui il gesto è
	# la deduzione — la griglia degli incroci e le porte.
	#
	# Musica scende da 27,3 a 24,3 e latino da 24,9 a 24,4 senza che nessuno
	# abbia tolto una crocetta: sono le ricette `compose` aggiunte il 4 settembre
	# (undici, per chiudere `explanation_coverage_audit`) che hanno spostato la
	# scelta dello specialista. Anche inglese scende di sette decimi.
}

## **Quota massima di «sceglie» nel solo esame di fine mondo.**
##
## Qui il debito è ancora grosso e va detto: metà dei nodi dell'esame è ancora
## «tocca una fra N». È già molto meglio di com'era — la logica stava al 61,3% e
## la manipolazione al 15%; ora sono 41,3% e 33,8%, e ogni materia è salita — ma
## un esame che chiude un mondo dovrebbe chiedere la competenza con lo stesso
## gesto con cui l'ha insegnata.
##
## Che cosa manca per scendere ancora, misurato e non ipotizzato:
##
##   1. `NONMC_FORMAT_WEIGHTS` pesa grafico, circuito e caccia all'errore (25)
##      più di abbinamento, ordinamento e smistamento (20, 15, 13) — cioè
##      favorisce i formati che sono a loro volta «sceglie». La preferenza
##      passata dall'esame lo corregge in parte, non alla radice;
##   2. `formati_da_sostituire` porta fuori solo la scelta multipla: i nodi da
##      digitare restano, e in logica sono il 25% dell'esame.
##
## Elettronica resta la più alta (63,8%) ed è coerente col suo progetto: lì la
## scelta multipla è stata tolta da tutto il resto e vive solo qui.
const TETTO_ESAME := {
	# ## Riportati sul misurato il 9 settembre 2026 — e scendono tutti e dodici
	#
	# La riscrittura dell'esame sulle fasce di priorita' (8 settembre) ha guarito
	# questa misura senza proporselo: l'esame pesca ora da tutte e dodici le
	# materie con quote fisse, «manipola» sta al **70,0% su ognuna** e «sceglie»
	# in una forbice di un punto e mezzo, fra il 22,8% e il 24,5%.
	#
	# I tetti erano rimasti dove li aveva messi la misura del 4 settembre, e
	# avevano fino a **quarantun punti d'aria**: elettronica a 63,0 su un valore
	# reale di 22,8. Un tetto che nessuno sfiora non e' un cricchetto, e' un
	# ornamento — non trattiene nessuna regressione, perche' qualunque
	# peggioramento resta comodamente sotto.
	#
	# **La regola applicata:** tetto = valore misurato oggi + 1,0 punto. Il rumore
	# dello strumento, misurato su due basi di seme indipendenti con 19200 nodi
	# per materia, e' 0,6 punti: un punto di margine lo copre e non di piu'.
	# Insieme ai tetti scende anche `TOLLERANZA_ESAME`, da 3,0 a 1,0, per la
	# stessa ragione — una tolleranza cinque volte piu' larga del rumore rendeva
	# il tetto vero tre punti piu' in alto di quello scritto.
	#
	# Matematica resta a 23,7 e non sale a 23,9: il cricchetto non si allenta
	# nemmeno di due decimi.
	#
	# **Due debiti si chiudono qui.**
	#
	# *Storia* era il rosso allentato a 36,0 per decisione del committente il 6
	# settembre — un debito dichiarato non pagato, solo spostato. Oggi sta a
	# **23,7%** e il suo tetto torna a 24,7. Non e' stato pagato lavorando sui
	# formati: e' stato pagato dalla ricostruzione dell'esame, che ha cambiato da
	# dove vengono i nodi.
	#
	# *Elettronica* stava a 63,0 apposta, perche' la materia aveva portato la
	# scelta multipla a zero in tutto il resto e l'esame era il solo posto in cui
	# misurava. Quella situazione e' finita: con le quote di priorita' l'esame di
	# un mondo di elettronica contiene per meta' altre materie, e il suo valore e'
	# 22,8%. Il tetto scende con lui. Se un giorno il progetto rimettesse la
	# crocetta di elettronica tutta nel suo esame, quel numero risalirebbe e
	# andrebbe deciso di nuovo, con la stessa esplicitezza di allora.
	#
	# **Da qui in giu', e solo in giu'.**
	"matematica": 23.7,
	"italiano": 23.9,
	"coding": 24.2,
	"inglese": 24.9,
	"fisica": 25.0,
	"musica": 25.5,
	"latino": 23.8,
	"elettronica": 23.8,
	"geografia": 23.9,
	"scienze": 24.7,
	"storia": 24.7,
	"logica": 23.8,
}


var _fallimenti: Array = []


func _init() -> void:
	var content := ContentManager.new()
	var mondo: Dictionary = {}   # materia -> {gesto: n}
	var esame: Dictionary = {}   # materia -> {gesto: n}

	for level in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var subject := str(profile["learningFocus"]["subject"])
		var events := MissionEventDirector.plan(profile, {}, "audit-gesto-%d" % level)
		for repeat in range(REPEATS):
			var rng := RandomNumberGenerator.new()
			rng.seed = SEME_MONDO + level * 131 + repeat
			for event in events:
				var kind := str((event as Dictionary).get("kind", "mission"))
				var session: Dictionary = {}
				if kind == "enigma":
					session = content.build_enigma(subject, level, 4, {}, rng)
				elif kind == "practice":
					session = content.minigame_manager.build_minigame(subject, level, rng)
				else:
					session = content.build_varied_mission(subject, level, 3, {}, rng)
				_conta(mondo, subject, session)
			# **L'esame ha un seme suo.** (1 settembre 2026)
			#
			# Prima l'esame continuava a pescare dallo stesso `rng` che avevano
			# appena consumato missioni, enigmi e pratica. Conseguenza misurata:
			# aggiungendo a italiano UNA specifica di linea del tempo — un formato
			# manipolativo, contenuto che non può peggiorare niente — il suo esame
			# passava da 38,6% a 42,0% di «sceglie». Non era cambiato l'esame: era
			# cambiato di quante estrazioni si era spostato il flusso prima di
			# arrivarci, e con esso quali item del banco finivano nella prova.
			#
			# Con un flusso separato l'esame si muove solo quando cambia il
			# contenuto che l'esame usa davvero. È la condizione perché i tetti qui
			# sotto siano un cricchetto e non un termometro del rumore.
			for campione in range(CAMPIONI_ESAME):
				var rng_esame := RandomNumberGenerator.new()
				rng_esame.seed = 91000 + level * 131 + repeat * CAMPIONI_ESAME + campione
				var prova := content.build_final_exam(subject, level, 3, rng_esame)
				if campione == 0:
					_conta(mondo, subject, prova)
				_conta(esame, subject, prova)

	_stampa("IL MONDO INTERO (missioni, enigmi, pratica, esame)", mondo, TETTO_MONDO)
	print("")
	_stampa("SOLO L'ESAME DI FINE MONDO", esame, TETTO_ESAME)
	_giudica(mondo, TETTO_MONDO, "mondo")
	_giudica(esame, TETTO_ESAME, "esame")

	if not _fallimenti.is_empty():
		printerr("GESTO — %d materie sopra il tetto dichiarato:" % _fallimenti.size())
		for riga in _fallimenti:
			printerr("  - %s" % str(riga))
		quit(1)
		return
	print("")
	print(OK)
	quit(0)


func _conta(dove: Dictionary, subject: String, session: Dictionary) -> void:
	var conti: Dictionary = dove.get(subject, {"MANIPOLA": 0, "SCEGLIE": 0, "DIGITA": 0, "?": 0})
	for node_data in Array(session.get("nodes", [])):
		var fmt := str((node_data as Dictionary).get("format", ""))
		var gesto := "?"
		if fmt in MANIPOLA:
			gesto = "MANIPOLA"
		elif fmt in SCEGLIE:
			gesto = "SCEGLIE"
		elif fmt in DIGITA:
			gesto = "DIGITA"
		conti[gesto] = int(conti[gesto]) + 1
	dove[subject] = conti


func _quota(conti: Dictionary, gesto: String) -> float:
	var totale := 0
	for k in conti.keys():
		totale += int(conti[k])
	if totale <= 0:
		return 0.0
	return 100.0 * float(conti[gesto]) / float(totale)


func _stampa(titolo: String, misure: Dictionary, tetti: Dictionary) -> void:
	print(titolo)
	print("MATERIA        NODI  MANIPOLA  SCEGLIE  DIGITA  IGNOTO   TETTO")
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var s := str(subject_data)
		if not misure.has(s):
			continue
		var conti: Dictionary = misure[s]
		var totale := 0
		for k in conti.keys():
			totale += int(conti[k])
		print("%-13s %5d   %6.1f%%  %6.1f%% %6.1f%%  %5.1f%%  %6s" % [
			s, totale, _quota(conti, "MANIPOLA"), _quota(conti, "SCEGLIE"),
			_quota(conti, "DIGITA"), _quota(conti, "?"), _etichetta_tetto(tetti, s)])


func _etichetta_tetto(tetti: Dictionary, subject: String) -> String:
	if not tetti.has(subject):
		return "—"
	return "%.1f" % float(tetti[subject])


func _giudica(misure: Dictionary, tetti: Dictionary, dove: String) -> void:
	for subject in misure.keys():
		var s := str(subject)
		var sceglie := _quota(misure[s], "SCEGLIE")
		var ignoto := _quota(misure[s], "?")
		if ignoto > 0.0:
			_fallimenti.append(
				"%s / %s: il %.1f%% dei nodi usa un formato che nessun gesto classifica" % [
					s, dove, ignoto])
		if not tetti.has(s):
			continue
		var tetto := float(tetti[s])
		var margine := TOLLERANZA_ESAME if dove == "esame" else TOLLERANZA
		if sceglie > tetto + margine:
			_fallimenti.append(
				"%s / %s: «sceglie» al %.1f%% (tetto %.1f%%)" % [s, dove, sceglie, tetto])
