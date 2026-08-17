extends SceneTree

## **Le voci sono giuste?** (17 agosto 2026)
##
## Il duello delle voci muove un verbo dentro il suo paradigma, e il bambino si
## fida di quello che legge: **una coniugazione sbagliata qui se la porta al
## compito in classe**. È l'unico audit del progetto in cui l'errore non è un
## difetto di gioco ma un danno didattico, e per questo confronta il motore con
## voci scritte a mano una per una — non con un'altra funzione del motore, che
## sarebbe come farsi correggere il compito da chi l'ha copiato.
##
## Quattro strati:
##
## 1. **Le voci a mano**: un centinaio di forme prese dai punti in cui il
##    coniugatore può sbagliare — le irregolarità dichiarate, i tempi composti,
##    l'accordo del participio con «essere», gli incoativi in `-isc-`;
## 2. **La forma del sistema**: le caselle che esistono e quelle che non esistono
##    (il condizionale non ha l'imperfetto), perché la griglia del duello disegna
##    quei buchi e devono essere veri;
## 3. **La completezza**: nessuna delle 78 caselle di nessun verbo del catalogo
##    può tornare vuota o contenere la radice nuda;
## 4. **L'ambiguità misurata**: quante voci di un verbo individuano una sola
##    casella. Non è un errore — «cantaste» è davvero due cose — ma il duello ne
##    ha bisogno per non mostrare mai un bersaglio che mente.

const OK := "VERB CONJUGATION audit VERDE"

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

## Le voci scritte a mano: [infinito, modo, tempo, persona, forma attesa].
const ATTESE := [
	# --- regolari, i tre gruppi e i sei posti -----------------------------------
	["cantare", "indicativo", "presente", 0, "canto"],
	["cantare", "indicativo", "presente", 4, "cantate"],
	["cantare", "indicativo", "presente", 5, "cantano"],
	["cantare", "indicativo", "imperfetto", 3, "cantavamo"],
	["cantare", "indicativo", "imperfetto", 4, "cantavate"],
	["cantare", "indicativo", "passato remoto", 2, "cantò"],
	["cantare", "indicativo", "passato remoto", 5, "cantarono"],
	["cantare", "indicativo", "futuro semplice", 0, "canterò"],
	["cantare", "indicativo", "futuro semplice", 5, "canteranno"],
	["cantare", "congiuntivo", "presente", 0, "canti"],
	["cantare", "congiuntivo", "presente", 4, "cantiate"],
	["cantare", "congiuntivo", "presente", 5, "cantino"],
	["cantare", "congiuntivo", "imperfetto", 0, "cantassi"],
	["cantare", "congiuntivo", "imperfetto", 3, "cantassimo"],
	["cantare", "congiuntivo", "imperfetto", 5, "cantassero"],
	["cantare", "condizionale", "presente", 0, "canterei"],
	["cantare", "condizionale", "presente", 3, "canteremmo"],
	["cantare", "condizionale", "presente", 5, "canterebbero"],
	["temere", "indicativo", "presente", 2, "teme"],
	["temere", "indicativo", "presente", 5, "temono"],
	["temere", "indicativo", "imperfetto", 0, "temevo"],
	["temere", "indicativo", "passato remoto", 3, "tememmo"],
	["temere", "congiuntivo", "presente", 0, "tema"],
	["temere", "congiuntivo", "imperfetto", 4, "temeste"],
	["temere", "condizionale", "presente", 1, "temeresti"],
	["dormire", "indicativo", "presente", 4, "dormite"],
	["dormire", "indicativo", "presente", 5, "dormono"],
	["dormire", "indicativo", "imperfetto", 2, "dormiva"],
	["dormire", "indicativo", "passato remoto", 2, "dormì"],
	["dormire", "indicativo", "futuro semplice", 3, "dormiremo"],
	["dormire", "congiuntivo", "presente", 5, "dormano"],
	["dormire", "congiuntivo", "imperfetto", 2, "dormisse"],
	["dormire", "condizionale", "presente", 0, "dormirei"],
	# --- gli incoativi ----------------------------------------------------------
	["capire", "indicativo", "presente", 0, "capisco"],
	["capire", "indicativo", "presente", 2, "capisce"],
	["capire", "indicativo", "presente", 3, "capiamo"],
	["capire", "indicativo", "presente", 5, "capiscono"],
	["capire", "congiuntivo", "presente", 0, "capisca"],
	["capire", "congiuntivo", "presente", 4, "capiate"],
	["capire", "indicativo", "imperfetto", 0, "capivo"],
	["finire", "indicativo", "presente", 1, "finisci"],
	["finire", "indicativo", "futuro semplice", 0, "finirò"],
	# --- essere e avere ---------------------------------------------------------
	["essere", "indicativo", "presente", 2, "è"],
	["essere", "indicativo", "presente", 4, "siete"],
	["essere", "indicativo", "imperfetto", 3, "eravamo"],
	["essere", "indicativo", "passato remoto", 0, "fui"],
	["essere", "indicativo", "passato remoto", 5, "furono"],
	["essere", "indicativo", "futuro semplice", 2, "sarà"],
	["essere", "congiuntivo", "presente", 4, "siate"],
	["essere", "congiuntivo", "imperfetto", 0, "fossi"],
	["essere", "congiuntivo", "imperfetto", 3, "fossimo"],
	["essere", "condizionale", "presente", 3, "saremmo"],
	["avere", "indicativo", "presente", 0, "ho"],
	["avere", "indicativo", "presente", 3, "abbiamo"],
	["avere", "indicativo", "imperfetto", 4, "avevate"],
	["avere", "indicativo", "passato remoto", 0, "ebbi"],
	["avere", "indicativo", "passato remoto", 5, "ebbero"],
	["avere", "indicativo", "futuro semplice", 5, "avranno"],
	["avere", "congiuntivo", "presente", 0, "abbia"],
	["avere", "congiuntivo", "imperfetto", 4, "aveste"],
	["avere", "condizionale", "presente", 2, "avrebbe"],
	# --- gli altri irregolari ---------------------------------------------------
	["fare", "indicativo", "presente", 0, "faccio"],
	["fare", "indicativo", "presente", 4, "fate"],
	["fare", "indicativo", "imperfetto", 0, "facevo"],
	["fare", "indicativo", "passato remoto", 0, "feci"],
	["fare", "congiuntivo", "imperfetto", 0, "facessi"],
	["fare", "condizionale", "presente", 0, "farei"],
	["dire", "indicativo", "presente", 4, "dite"],
	["dire", "indicativo", "imperfetto", 2, "diceva"],
	["dire", "indicativo", "passato remoto", 2, "disse"],
	["dire", "congiuntivo", "presente", 0, "dica"],
	["andare", "indicativo", "presente", 0, "vado"],
	["andare", "indicativo", "presente", 3, "andiamo"],
	["andare", "indicativo", "imperfetto", 0, "andavo"],
	["andare", "indicativo", "passato remoto", 2, "andò"],
	["andare", "indicativo", "futuro semplice", 0, "andrò"],
	["andare", "congiuntivo", "presente", 5, "vadano"],
	["potere", "indicativo", "presente", 2, "può"],
	["potere", "indicativo", "presente", 1, "puoi"],
	["potere", "indicativo", "futuro semplice", 0, "potrò"],
	["potere", "congiuntivo", "presente", 0, "possa"],
	["volere", "indicativo", "presente", 1, "vuoi"],
	["volere", "indicativo", "passato remoto", 0, "volli"],
	["volere", "condizionale", "presente", 0, "vorrei"],
	["sapere", "indicativo", "presente", 0, "so"],
	["sapere", "indicativo", "passato remoto", 2, "seppe"],
	["sapere", "congiuntivo", "presente", 3, "sappiamo"],
	["venire", "indicativo", "presente", 0, "vengo"],
	["venire", "indicativo", "passato remoto", 2, "venne"],
	["venire", "indicativo", "futuro semplice", 0, "verrò"],
	["vedere", "indicativo", "presente", 0, "vedo"],
	["vedere", "indicativo", "passato remoto", 0, "vidi"],
	["vedere", "indicativo", "futuro semplice", 0, "vedrò"],
	["leggere", "indicativo", "presente", 3, "leggiamo"],
	["leggere", "indicativo", "passato remoto", 0, "lessi"],
	["prendere", "indicativo", "passato remoto", 2, "prese"],
	["scrivere", "indicativo", "passato remoto", 5, "scrissero"],
	["stare", "indicativo", "presente", 0, "sto"],
	["stare", "indicativo", "imperfetto", 0, "stavo"],
	["stare", "congiuntivo", "imperfetto", 0, "stessi"],
	["dare", "indicativo", "presente", 2, "dà"],
	["dare", "indicativo", "imperfetto", 0, "davo"],
	["dare", "congiuntivo", "imperfetto", 0, "dessi"],
	# --- i tempi composti -------------------------------------------------------
	["cantare", "indicativo", "passato prossimo", 0, "ho cantato"],
	["cantare", "indicativo", "passato prossimo", 5, "hanno cantato"],
	["cantare", "indicativo", "trapassato prossimo", 4, "avevate cantato"],
	["cantare", "indicativo", "futuro anteriore", 0, "avrò cantato"],
	["cantare", "congiuntivo", "passato", 0, "abbia cantato"],
	["cantare", "congiuntivo", "trapassato", 4, "aveste cantato"],
	["cantare", "condizionale", "passato", 0, "avrei cantato"],
	["temere", "indicativo", "passato prossimo", 2, "ha temuto"],
	["capire", "indicativo", "passato prossimo", 3, "abbiamo capito"],
	["fare", "indicativo", "passato prossimo", 0, "ho fatto"],
	["dire", "congiuntivo", "trapassato", 0, "avessi detto"],
	["vedere", "indicativo", "trapassato prossimo", 0, "avevo visto"],
	["leggere", "condizionale", "passato", 3, "avremmo letto"],
	# --- l'accordo del participio con «essere» ----------------------------------
	["partire", "indicativo", "passato prossimo", 0, "sono partito"],
	["partire", "indicativo", "passato prossimo", 3, "siamo partiti"],
	["partire", "indicativo", "passato prossimo", 4, "siete partiti"],
	["andare", "indicativo", "passato prossimo", 2, "è andato"],
	["andare", "indicativo", "passato prossimo", 5, "sono andati"],
	["andare", "congiuntivo", "trapassato", 4, "foste andati"],
	["essere", "indicativo", "passato prossimo", 0, "sono stato"],
	["essere", "indicativo", "passato prossimo", 3, "siamo stati"],
	["venire", "condizionale", "passato", 0, "sarei venuto"],
	["stare", "indicativo", "trapassato prossimo", 3, "eravamo stati"],
]

func _init() -> void:
	_le_voci_a_mano()
	_la_forma_del_sistema()
	_nessuna_casella_vuota()
	_ambiguita_misurata()
	if errori.is_empty():
		print("%s — %d voci a mano, %d verbi, %d caselle per verbo" % [
			OK, ATTESE.size(), VerbConjugator.VERBI.size(), _caselle()])
	else:
		printerr("VERB CONJUGATION audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

func _caselle() -> int:
	var quante := 0
	for modo in VerbConjugator.MODI:
		quante += Array(VerbConjugator.TEMPI[modo]).size()
	return quante

func _le_voci_a_mano() -> void:
	for riga in ATTESE:
		var caso: Array = riga
		var verbo := VerbConjugator.verbo_per_infinito(str(caso[0]))
		if verbo.is_empty():
			errori.append("«%s» non è nel catalogo" % str(caso[0]))
			continue
		var ottenuta := VerbConjugator.voce(verbo, str(caso[1]), str(caso[2]), int(caso[3]))
		_controlla(ottenuta == str(caso[4]),
			"%s · %s %s · %s: il motore dice «%s», si scrive «%s»" % [
				str(caso[0]), str(caso[1]), str(caso[2]),
				str(VerbConjugator.PERSONE[int(caso[3])]), ottenuta, str(caso[4])])

## Le caselle che esistono e quelle che non esistono. La griglia del duello
## disegna i buchi del sistema, e se questi buchi fossero sbagliati il gioco
## insegnerebbe una tabella che non è quella dei verbi.
func _la_forma_del_sistema() -> void:
	for accoppiata in [
		["indicativo", "presente"], ["indicativo", "trapassato prossimo"],
		["congiuntivo", "imperfetto"], ["congiuntivo", "trapassato"],
		["condizionale", "presente"], ["condizionale", "passato"],
	]:
		_controlla(VerbConjugator.casella_esiste(str(accoppiata[0]), str(accoppiata[1])),
			"la casella %s %s dovrebbe esistere" % [str(accoppiata[0]), str(accoppiata[1])])
	for fantasma in [
		["condizionale", "imperfetto"], ["condizionale", "futuro semplice"],
		["congiuntivo", "futuro semplice"], ["congiuntivo", "passato remoto"],
		["congiuntivo", "passato prossimo"], ["indicativo", "trapassato"],
	]:
		_controlla(not VerbConjugator.casella_esiste(str(fantasma[0]), str(fantasma[1])),
			"la casella %s %s non esiste in italiano" % [str(fantasma[0]), str(fantasma[1])])
	# E i composti nascono dall'ausiliare giusto: «congiuntivo passato» vuole il
	# congiuntivo presente dell'ausiliare, non l'indicativo.
	_controlla(VerbConjugator.composto("indicativo", "passato prossimo"),
		"il passato prossimo non risulta composto")
	_controlla(not VerbConjugator.composto("indicativo", "passato remoto"),
		"il passato remoto risulta composto")

func _nessuna_casella_vuota() -> void:
	for scheda in VerbConjugator.VERBI:
		var verbo: Dictionary = scheda
		var infinito := str(verbo.get("infinito", "?"))
		var radice := VerbConjugator.radice_di(verbo)
		for modo in VerbConjugator.MODI:
			for tempo in Array(VerbConjugator.TEMPI[modo]):
				for persona in range(6):
					var forma := VerbConjugator.voce(verbo, modo, str(tempo), persona)
					if forma.is_empty():
						errori.append("%s · %s %s · %d: voce vuota" % [
							infinito, modo, str(tempo), persona])
						continue
					# La radice nuda è il modo in cui una desinenza mancante si
					# maschera da forma vera: «cant» invece di «canto».
					if forma == radice:
						errori.append("%s · %s %s · %d: è la radice nuda «%s»" % [
							infinito, modo, str(tempo), persona, forma])
					if forma.contains("  ") or forma.begins_with(" ") or forma.ends_with(" "):
						errori.append("%s · %s %s · %d: spazi sbagliati in «%s»" % [
							infinito, modo, str(tempo), persona, forma])

## Non è un controllo di errore ma di **disponibilità**: il duello, dai mondi 10
## in su, mostra come bersaglio una voce vera invece dell'etichetta, e può usare
## soltanto le voci che individuano una casella sola. Se un verbo ne avesse
## troppo poche, quel verbo non potrebbe fare da campione e il duello resterebbe
## senza bersagli.
func _ambiguita_misurata() -> void:
	for scheda in VerbConjugator.VERBI:
		var verbo: Dictionary = scheda
		var uniche := 0
		var voci := VerbConjugator.tutte_le_voci(verbo)
		var conteggio: Dictionary = {}
		for forma in voci.values():
			conteggio[str(forma)] = int(conteggio.get(str(forma), 0)) + 1
		for forma in voci.values():
			if int(conteggio[str(forma)]) == 1:
				uniche += 1
		_controlla(uniche >= 40,
			"%s: solo %d voci su %d individuano una casella sola, non basta per fare da campione" % [
				str(verbo.get("infinito", "?")), uniche, voci.size()])
