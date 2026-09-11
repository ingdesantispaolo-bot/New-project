class_name NomiDeiLuoghi
extends RefCounted

## **Un posto ha un nome; una voce di elenco no.** (10 settembre 2026)
##
## Segnalazione del committente: *«lo studente quando si presenta in un mondo
## segue semplicemente il percorso indicatogli dalle istruzioni; questo toglie
## stimolo ad esplorazione»*.
##
## **Che cosa era, misurato.** Ogni mondo pianta diciotto punti d'interesse —
## sette del focus e undici palestre ([[MissionEventDirector.plan]]) — e sopra
## ognuno la scena scriveva una didascalia composta di due parole: la categoria
## e la materia. `PRATICA · MATEMATICA`, `MISSIONE · STORIA`, `ENIGMA · LOGICA`.
## Diciotto volte per mondo, ventiquattro mondi: **quattrocentotrentadue voci di
## un registro**. Nessuna di quelle didascalie nomina un posto: dicono a quale
## riga dell'elenco corrisponde quel puntino. Un bambino che le legge non sta
## esplorando un mondo, sta spuntando una lista — ed e' esattamente il verdetto
## della segnalazione.
##
## **La cosa peggiore e' che il mondo il nome ce l'aveva gia'.** Il direttore non
## sceglie coordinate a caso: aggancia ogni evento a un **luogo dichiarato**
## della composizione, con un ruolo (`region`, `instrument`, `landmark`,
## `crossing`, `trail`) e una costellazione. Quei due campi viaggiano nel payload
## dell'area fino alla scena, dove — misurato con una ricerca su tutto il
## progetto — **non li legge nessuno**: solo gli audit. E' il difetto ricorrente
## di questo progetto, contenuto scritto e mai collegato; il piano sta in
## `docs/PERCORSO_STUDENTE.md`.
##
## Qui quel ruolo torna a servire: diventa il **sostantivo** del posto. La
## materia diventa il suo **complemento**. «il banco delle misure», «la pietra
## delle date», «il varco dei fili», «il cippo delle rotte».
##
## ## Le due regole di scrittura
##
## **Mai la parola della categoria.** Ne' PRATICA, ne' MISSIONE, ne' ENIGMA: sono
## parole del registro di chi ha costruito il gioco, non del posto. Che cosa sia
## lo dice il disegno — un enigma ha la sua struttura a campate, una palestra il
## suo ripetitore — e chi guarda lo capisce senza che glielo si scriva.
##
## **Mai due posti con lo stesso nome nello stesso mondo.** Due «banco delle
## misure» a quattrocento unita' l'uno dall'altro sono peggio di nessun nome:
## insegnano che i nomi qui non contano, e un bambino smette di leggerli. La
## materia del mondo ha sette eventi e puo' ripetere il ruolo, quindi il
## sostantivo ha tre forme per ruolo e si scorre; `percorso_studente_audit`
## verifica l'unicita' sui ventiquattro mondi invece di fidarsi di questa riga.

## Il sostantivo del posto, per ruolo del luogo dichiarato. **Cinque** forme
## ciascuno: la prima e' quella buona, le altre esistono perche' la materia
## ospite di un mondo ha sette punti e puo' appoggiarne piu' d'uno sullo stesso
## tipo di luogo. Misurato sui ventiquattro mondi: il caso peggiore ne chiede
## quattro (mondo 12, quattro prove di logica su strumenti).
##
## Sono parole di paesaggio e non di arredo scolastico: valgono in una radura,
## in un archivio e in un cratere senza diventare bugie. `banco` e' il tavolo da
## lavoro all'aperto, non il banco di scuola — ed e' il senso in cui lo usa gia'
## il resto del progetto («banco delle domande», «banco-rele'»).
const SOSTANTIVO := {
	"region": ["il campo", "la conca", "la spianata", "il pianoro", "il ripiano"],
	"instrument": ["il banco", "la panca", "il tavolo", "il leggio", "la mensola"],
	"landmark": ["la pietra", "la stele", "la guglia", "la colonna", "il pilastro"],
	"crossing": ["il varco", "il passo", "la breccia", "la soglia", "il valico"],
	"trail": ["il cippo", "il paletto", "il segno", "la tacca", "la pietra miliare"],
}

## Il ripiego, quando il luogo non dichiara un ruolo riconosciuto. Non e' il
## sostantivo di nessun ruolo, di proposito: se compare in gioco vuol dire che
## qualcuno ha aggiunto un ruolo alla composizione senza passare di qui, e deve
## saltare all'occhio invece di mimetizzarsi. Stessa scelta di
## [[SubjectPalette.NEUTRO]].
const SOSTANTIVO_NEUTRO := ["il posto", "il luogo", "la sosta"]

## Il complemento del posto, per materia: **di che cosa** e' quel banco.
##
## Non e' il nome della materia. «il banco di matematica» sarebbe la didascalia
## di prima con una preposizione in mezzo; «il banco delle misure» dice che cosa
## ci si fa, e un bambino che l'ha letto una volta sa gia' che cosa aspettarsi
## quando lo rivede fra sei mondi. E' la stessa scelta che il progetto fa gia'
## per le condizioni del gate ([[ObjectiveBriefing.AZIONE]]): mai il nome della
## misura, sempre il nome dell'azione.
const COMPLEMENTO := {
	"matematica": "delle misure",
	"italiano": "delle parole",
	"inglese": "delle voci",
	"latino": "delle radici",
	"coding": "delle sequenze",
	"logica": "delle regole",
	"fisica": "delle spinte",
	"elettronica": "dei fili",
	"scienze": "dei viventi",
	"musica": "dei battiti",
	"storia": "delle date",
	"geografia": "delle rotte",
}

## Che cosa ti chiede quel posto, quando ci sei davanti. Verbi, non sostantivi:
## si legge a due passi dal luogo e deve dire che cosa si sta per fare, non come
## si chiama la disciplina sul registro di classe.
const RICHIESTA := {
	"matematica": "contare e misurare",
	"italiano": "mettere in ordine le parole",
	"inglese": "dire le cose nell'altra lingua",
	"latino": "risalire alla forma giusta",
	"coding": "dare gli ordini nel giusto ordine",
	"logica": "scoprire la regola nascosta",
	"fisica": "prevedere come va a finire",
	"elettronica": "far passare la corrente",
	"scienze": "guardare bene e classificare",
	"musica": "tenere il tempo",
	"storia": "rimettere in fila il tempo",
	"geografia": "capire dove sono le cose",
}

## Le parole vietate in un nome di posto: sono le tre categorie del direttore.
## Servono all'audit, che le cerca dentro i nomi generati invece di fidarsi
## della regola scritta qui sopra.
const PAROLE_DEL_REGISTRO := ["pratica", "missione", "enigma", "evento"]

## **Le parole che in un nome proprio restano minuscole.**
##
## `String.capitalize()` di Godot mette la maiuscola a **ogni** parola, che e' la
## regola dell'inglese e non dell'italiano: «obelisco-dei-numeri» ne usciva come
## «Obelisco Dei Numeri». Quel nome finisce sul cartello del landmark e nella
## riga che si legge stando li' davanti, cioe' e' un errore di ortografia messo
## in mostra da un gioco che insegna l'italiano.
const PAROLE_MINUSCOLE := [
	"di", "del", "dello", "della", "dei", "degli", "delle",
	"da", "dal", "dallo", "dalla", "dai", "dagli", "dalle",
	"a", "al", "allo", "alla", "ai", "agli", "alle",
	"in", "nel", "nello", "nella", "nei", "negli", "nelle",
	"su", "sul", "sullo", "sulla", "sui", "sugli", "sulle",
	"con", "per", "tra", "fra", "e", "ed",
	"il", "lo", "la", "i", "gli", "le", "un", "uno", "una",
]

## Un nome proprio scritto come si scrive in italiano: maiuscola alla prima
## parola e alle parole piene, minuscola alle preposizioni e agli articoli in
## mezzo. Accetta sia «obelisco-dei-numeri» sia «obelisco dei numeri».
static func nome_proprio(grezzo: String) -> String:
	var parole := grezzo.replace("-", " ").replace("_", " ").strip_edges().split(" ", false)
	var fuori: Array = []
	for indice in range(parole.size()):
		var parola := str(parole[indice]).to_lower()
		if indice > 0 and PAROLE_MINUSCOLE.has(parola):
			fuori.append(parola)
		else:
			fuori.append(parola.substr(0, 1).to_upper() + parola.substr(1))
	return " ".join(PackedStringArray(fuori))

## Il nome di un posto, dato il ruolo del luogo, la materia e quante volte quella
## coppia e' gia' stata usata in questo mondo.
static func nome(ruolo: String, materia: String, ripetizione: int = 0) -> String:
	var forme: Array = SOSTANTIVO.get(ruolo, SOSTANTIVO_NEUTRO)
	var sostantivo := str(forme[clampi(ripetizione, 0, forme.size() - 1)])
	var complemento := str(COMPLEMENTO.get(materia, ""))
	if complemento.is_empty():
		return sostantivo
	return "%s %s" % [sostantivo, complemento]

## **Il quartiere.** (10 settembre 2026, lotto 3 della corsia)
##
## Un nome dice *che cosa* è un posto; non dice *dove*. Undici palestre si
## raccolgono in poche costellazioni — misurate 2,9 di media per mondo, sei nel
## caso peggiore — e quella costellazione è la cosa che un bambino può imparare a
## memoria: «gli allenamenti stanno di là». Il campo `locationCluster` la
## descrive da mesi e non lo leggeva nessuno.
##
## **Il quartiere prende il nome del suo posto più vistoso**, che è come nascono
## i nomi dei quartieri veri. La prominenza non è un'opinione: è il ruolo del
## luogo, cioè quanto quella cosa si vede da lontano.
##
## **Una costellazione con un posto solo non è un quartiere.** Chiamarla col nome
## del suo unico posto darebbe «il banco delle misure, nel quartiere del banco
## delle misure»: una tautologia, e una tautologia detta a un bambino insegna che
## queste righe non vanno lette. Dove il quartiere non c'è, non si dice niente.
const PROMINENZA := {
	"landmark": 4, "crossing": 3, "region": 2, "instrument": 1, "trail": 0,
}

## «il campo» → «del campo»; «la pietra» → «della pietra». Le preposizioni
## articolate non si compongono incollando: `"di " + nome` darebbe «di il campo».
static func di_luogo(nome_del_posto: String) -> String:
	if nome_del_posto.begins_with("il "):
		return "del %s" % nome_del_posto.substr(3)
	if nome_del_posto.begins_with("lo "):
		return "dello %s" % nome_del_posto.substr(3)
	if nome_del_posto.begins_with("la "):
		return "della %s" % nome_del_posto.substr(3)
	if nome_del_posto.begins_with("l'"):
		return "dell'%s" % nome_del_posto.substr(2)
	if nome_del_posto.begins_with("i "):
		return "dei %s" % nome_del_posto.substr(2)
	if nome_del_posto.begins_with("le "):
		return "delle %s" % nome_del_posto.substr(3)
	if nome_del_posto.begins_with("gli "):
		return "degli %s" % nome_del_posto.substr(4)
	return "di %s" % nome_del_posto

## I quartieri di un mondo: `{ id costellazione: nome del quartiere }`.
##
## Ci sono solo le costellazioni con almeno due posti: le altre non sono
## quartieri. Il nome è già pronto per essere incastrato in una frase — «nel
## quartiere della pietra delle date».
static func quartieri(eventi: Array) -> Dictionary:
	var nomi := mappa(eventi)
	var per_costellazione: Dictionary = {}
	for voce in eventi:
		var evento: Dictionary = voce
		var costellazione := str(evento.get("locationCluster", ""))
		if costellazione.is_empty() or costellazione == "fallback":
			continue
		var gruppo: Array = per_costellazione.get(costellazione, [])
		gruppo.append(evento)
		per_costellazione[costellazione] = gruppo
	var fuori: Dictionary = {}
	for costellazione in per_costellazione.keys():
		var gruppo: Array = per_costellazione[costellazione]
		if gruppo.size() < 2:
			continue
		var migliore: Dictionary = {}
		var punteggio := -1
		for voce in gruppo:
			var evento: Dictionary = voce
			var quanto := int(PROMINENZA.get(str(evento.get("locationRole", "")), 0))
			# A pari prominenza vince l'id più basso: due partite devono dare lo
			# stesso nome allo stesso quartiere.
			if quanto > punteggio or (quanto == punteggio
					and str(evento.get("id", "")) < str(migliore.get("id", "~"))):
				punteggio = quanto
				migliore = evento
		var nome_del_posto := str(nomi.get(str(migliore.get("id", "")), ""))
		if nome_del_posto.is_empty():
			continue
		fuori[str(costellazione)] = "il quartiere %s" % di_luogo(nome_del_posto)
	return fuori

## In quale quartiere si allena una materia, già pronto per la frase: «nel
## quartiere della pietra delle date». Vuoto se quella materia non ha un posto
## aperto in questo mondo, o se il suo posto sta da solo.
static func quartiere_di(eventi: Array, materia: String) -> String:
	var mappa_quartieri := quartieri(eventi)
	for voce in eventi:
		var evento: Dictionary = voce
		if str(evento.get("subject", "")) != materia:
			continue
		if str(evento.get("kind", "")) != "practice":
			continue
		var costellazione := str(evento.get("locationCluster", ""))
		if mappa_quartieri.has(costellazione):
			return str(mappa_quartieri[costellazione])
	return ""

## Il nome come va su un cartello: prima lettera maiuscola e basta. Non
## `capitalize()`, che maiuscolerebbe anche «delle».
static func sul_cartello(nome_del_posto: String) -> String:
	if nome_del_posto.is_empty():
		return ""
	return nome_del_posto.substr(0, 1).to_upper() + nome_del_posto.substr(1)

## Che cosa chiede questo posto, in una riga. Vuota per una materia sconosciuta:
## meglio il silenzio di una frase che finisce a meta'.
static func richiesta(materia: String) -> String:
	return str(RICHIESTA.get(materia, ""))

## **I nomi di tutti i posti di un mondo, in un colpo solo.**
##
## Si costruisce dalla lista degli eventi pianificati — la stessa che il
## direttore restituisce, quindi deterministica per seme — e garantisce
## l'unicita': la seconda volta che una coppia (ruolo, materia) ricompare scorre
## il sostantivo, la quarta aggiunge la costellazione per non tornare al primo.
##
## Restituisce `{ id evento: nome del posto }`.
static func mappa(eventi: Array) -> Dictionary:
	var fuori: Dictionary = {}
	var usati: Dictionary = {}
	var presi: Dictionary = {}
	for voce in eventi:
		var evento: Dictionary = voce
		var id := str(evento.get("id", ""))
		if id.is_empty():
			continue
		var ruolo := str(evento.get("locationRole", "route"))
		var materia := str(evento.get("subject", ""))
		var chiave := "%s|%s" % [ruolo, materia]
		var quante := int(usati.get(chiave, 0))
		usati[chiave] = quante + 1
		var proposto := nome(ruolo, materia, quante)
		# Oltre la quinta forma i sostantivi finiscono, e allora resta il numero:
		# brutto e vero. Meglio brutto che ambiguo — e sui ventiquattro mondi non
		# succede mai, come misura `percorso_studente_audit`.
		#
		# **Non la costellazione.** La prima stesura ci appendeva il nome del
		# quartiere, e il risultato era «la spianata delle radici, glyph forum»:
		# gli id dei socket sono in inglese perche' li scrive il generatore, e una
		# parola inglese in mezzo a un nome italiano e' esattamente il genere di
		# svista che un gioco che insegna l'italiano non si puo' permettere.
		var tentativo := 2
		var radice := proposto
		while presi.has(proposto):
			proposto = "%s (%d)" % [radice, tentativo]
			tentativo += 1
		presi[proposto] = true
		fuori[id] = proposto
	return fuori
