class_name VerbConjugator
extends RefCounted

## **Il coniugatore.** (17 agosto 2026)
##
## Serve al duello delle voci ([[VerbDuel]]) e non esiste per nessun altro
## motivo: dà la voce di un verbo italiano in una casella qualunque del sistema
## — modo, tempo, persona.
##
## **Perché un motore e non una tabella di frasi.** Il duello chiede al bambino di
## *muoversi* dentro il paradigma: da «canto» a «cantavate» a «cantaste». Ogni
## passo deve produrre una forma vera, all'istante, per qualunque verbo del
## catalogo: sono 13 caselle × 6 persone = **78 voci per verbo**, e scriverle a
## mano per trenta verbi vorrebbe dire duemilatrecento stringhe da rileggere una
## per una. Un motore con le desinenze regolari e le sole irregolarità dichiarate
## è più corto, e soprattutto è **controllabile**: `verb_duel_audit` confronta un
## centinaio di voci scelte a mano con quello che il motore produce.
##
## **La regola sopra a tutte.** Un gioco che insegna una coniugazione sbagliata è
## peggio di un gioco che non insegna niente: il bambino si fida, e quello che
## impara qui se lo porta al compito in classe. Quindi ogni irregolarità è
## scritta per esteso — mai «quasi regolare» — e ogni verbo entra nel catalogo
## solo dopo che l'audit ne ha verificato le voci difficili.
##
## **Cosa NON copre, dichiarato.** Imperativo (le sue persone non sono sei, e una
## griglia con dei buchi dentro la riga si legge male), modi indefiniti
## (infinito, participio e gerundio non hanno persona: sarebbero una riga sola in
## una tabella a sei colonne), trapassato remoto (vive solo dentro una
## subordinata temporale, e da solo non si sa leggere). Nessuna di queste tre
## esclusioni toglie qualcosa al calcolo veloce di modi e tempi, che è quello che
## il duello deve allenare.

## Le sei persone, come le dice un bambino e come le chiama la grammatica.
const PERSONE := ["io", "tu", "lui/lei", "noi", "voi", "loro"]
const PERSONE_GRAMMATICA := ["1ª sing.", "2ª sing.", "3ª sing.", "1ª plur.", "2ª plur.", "3ª plur."]

const MODI := ["indicativo", "congiuntivo", "condizionale"]

## **Le caselle che esistono davvero.** Questa è la mappa del sistema, ed è anche
## la ragione per cui la griglia del duello ha dei buchi: il condizionale non ha
## l'imperfetto, il congiuntivo non ha il futuro. Vederlo disegnato è metà della
## lezione — la tabella dei verbi non è un rettangolo pieno, e chi crede che lo
## sia sbaglia per tutta la scuola media.
const TEMPI := {
	"indicativo": [
		"presente", "imperfetto", "passato remoto", "futuro semplice",
		"passato prossimo", "trapassato prossimo", "futuro anteriore",
	],
	"congiuntivo": ["presente", "imperfetto", "passato", "trapassato"],
	"condizionale": ["presente", "passato"],
}

## I tempi composti, e da quale voce dell'ausiliare nascono. La chiave è
## «modo|tempo» perché «passato» esiste sia al congiuntivo sia al condizionale e
## chiede due ausiliari diversi: è esattamente il genere di cosa che una tabella
## indicizzata solo sul tempo sbaglierebbe in silenzio.
const COMPOSTI := {
	"indicativo|passato prossimo": ["indicativo", "presente"],
	"indicativo|trapassato prossimo": ["indicativo", "imperfetto"],
	"indicativo|futuro anteriore": ["indicativo", "futuro semplice"],
	"congiuntivo|passato": ["congiuntivo", "presente"],
	"congiuntivo|trapassato": ["congiuntivo", "imperfetto"],
	"condizionale|passato": ["condizionale", "presente"],
}

## Le desinenze regolari, per gruppo e per casella semplice.
const DESINENZE := {
	"are": {
		"indicativo|presente": ["o", "i", "a", "iamo", "ate", "ano"],
		"indicativo|imperfetto": ["avo", "avi", "ava", "avamo", "avate", "avano"],
		"indicativo|passato remoto": ["ai", "asti", "ò", "ammo", "aste", "arono"],
		"indicativo|futuro semplice": ["erò", "erai", "erà", "eremo", "erete", "eranno"],
		"congiuntivo|presente": ["i", "i", "i", "iamo", "iate", "ino"],
		"congiuntivo|imperfetto": ["assi", "assi", "asse", "assimo", "aste", "assero"],
		"condizionale|presente": ["erei", "eresti", "erebbe", "eremmo", "ereste", "erebbero"],
	},
	"ere": {
		"indicativo|presente": ["o", "i", "e", "iamo", "ete", "ono"],
		"indicativo|imperfetto": ["evo", "evi", "eva", "evamo", "evate", "evano"],
		"indicativo|passato remoto": ["ei", "esti", "é", "emmo", "este", "erono"],
		"indicativo|futuro semplice": ["erò", "erai", "erà", "eremo", "erete", "eranno"],
		"congiuntivo|presente": ["a", "a", "a", "iamo", "iate", "ano"],
		"congiuntivo|imperfetto": ["essi", "essi", "esse", "essimo", "este", "essero"],
		"condizionale|presente": ["erei", "eresti", "erebbe", "eremmo", "ereste", "erebbero"],
	},
	"ire": {
		"indicativo|presente": ["o", "i", "e", "iamo", "ite", "ono"],
		"indicativo|imperfetto": ["ivo", "ivi", "iva", "ivamo", "ivate", "ivano"],
		"indicativo|passato remoto": ["ii", "isti", "ì", "immo", "iste", "irono"],
		"indicativo|futuro semplice": ["irò", "irai", "irà", "iremo", "irete", "iranno"],
		"congiuntivo|presente": ["a", "a", "a", "iamo", "iate", "ano"],
		"congiuntivo|imperfetto": ["issi", "issi", "isse", "issimo", "iste", "issero"],
		"condizionale|presente": ["irei", "iresti", "irebbe", "iremmo", "ireste", "irebbero"],
	},
	## I verbi in -ire «incoativi» (capire, finire, preferire): infilano `-isc-`
	## al presente, e solo dove l'accento cade sulla radice — «capisco» ma
	## «capiamo». È la prima irregolarità che un bambino incontra davvero, e
	## lasciarla fuori avrebbe significato insegnare «capo» al posto di «capisco».
	"ire-isc": {
		"indicativo|presente": ["isco", "isci", "isce", "iamo", "ite", "iscono"],
		"indicativo|imperfetto": ["ivo", "ivi", "iva", "ivamo", "ivate", "ivano"],
		"indicativo|passato remoto": ["ii", "isti", "ì", "immo", "iste", "irono"],
		"indicativo|futuro semplice": ["irò", "irai", "irà", "iremo", "irete", "iranno"],
		"congiuntivo|presente": ["isca", "isca", "isca", "iamo", "iate", "iscano"],
		"congiuntivo|imperfetto": ["issi", "issi", "isse", "issimo", "iste", "issero"],
		"condizionale|presente": ["irei", "iresti", "irebbe", "iremmo", "ireste", "irebbero"],
	},
}

const PARTICIPI := {"are": "ato", "ere": "uto", "ire": "ito", "ire-isc": "ito"}

## **Il catalogo.** Ogni verbo dichiara il gruppo, l'ausiliare dei tempi composti
## e — se serve — la radice (quando toglierle tre lettere non basta: «fare» dà
## «f», ma le sue voci nascono da «fac-») e il participio irregolare.
##
## `irregolari` contiene **solo caselle semplici**, per esteso e tutte e sei le
## persone. I tempi composti non compaiono mai: nascono dall'ausiliare e dal
## participio, e scriverli sarebbe un'occasione in più di sbagliare.
##
## I verbi sono scelti per frequenza, non per varietà: sono quelli che un bambino
## di dieci anni usa e sbaglia. `regolare` distingue i verbi che valgono come
## esempio pulito del gruppo da quelli che valgono come eccezione da imparare.
const VERBI := [
	# --- regolari, i tre gruppi -------------------------------------------------
	{"infinito": "cantare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "parlare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "guardare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "portare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "aspettare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "imparare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "ascoltare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "lavorare", "gruppo": "are", "aux": "avere", "regolare": true},
	{"infinito": "temere", "gruppo": "ere", "aux": "avere", "regolare": true},
	{"infinito": "credere", "gruppo": "ere", "aux": "avere", "regolare": true},
	{"infinito": "ricevere", "gruppo": "ere", "aux": "avere", "regolare": true},
	{"infinito": "vendere", "gruppo": "ere", "aux": "avere", "regolare": true},
	{"infinito": "ripetere", "gruppo": "ere", "aux": "avere", "regolare": true},
	{"infinito": "dormire", "gruppo": "ire", "aux": "avere", "regolare": true},
	{"infinito": "sentire", "gruppo": "ire", "aux": "avere", "regolare": true},
	{"infinito": "servire", "gruppo": "ire", "aux": "avere", "regolare": true},
	{"infinito": "seguire", "gruppo": "ire", "aux": "avere", "regolare": true},
	{"infinito": "partire", "gruppo": "ire", "aux": "essere", "regolare": true},
	{"infinito": "capire", "gruppo": "ire-isc", "aux": "avere", "regolare": true},
	{"infinito": "finire", "gruppo": "ire-isc", "aux": "avere", "regolare": true},
	{"infinito": "preferire", "gruppo": "ire-isc", "aux": "avere", "regolare": true},
	{"infinito": "pulire", "gruppo": "ire-isc", "aux": "avere", "regolare": true},

	# --- irregolari, i più frequenti --------------------------------------------
	{
		"infinito": "essere", "gruppo": "ere", "aux": "essere",
		"radice": "ess", "participio": "stato", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["sono", "sei", "è", "siamo", "siete", "sono"],
			"indicativo|imperfetto": ["ero", "eri", "era", "eravamo", "eravate", "erano"],
			"indicativo|passato remoto": ["fui", "fosti", "fu", "fummo", "foste", "furono"],
			"indicativo|futuro semplice": ["sarò", "sarai", "sarà", "saremo", "sarete", "saranno"],
			"congiuntivo|presente": ["sia", "sia", "sia", "siamo", "siate", "siano"],
			"congiuntivo|imperfetto": ["fossi", "fossi", "fosse", "fossimo", "foste", "fossero"],
			"condizionale|presente": ["sarei", "saresti", "sarebbe", "saremmo", "sareste", "sarebbero"],
		},
	},
	{
		"infinito": "avere", "gruppo": "ere", "aux": "avere",
		"radice": "av", "participio": "avuto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["ho", "hai", "ha", "abbiamo", "avete", "hanno"],
			"indicativo|passato remoto": ["ebbi", "avesti", "ebbe", "avemmo", "aveste", "ebbero"],
			"indicativo|futuro semplice": ["avrò", "avrai", "avrà", "avremo", "avrete", "avranno"],
			"congiuntivo|presente": ["abbia", "abbia", "abbia", "abbiamo", "abbiate", "abbiano"],
			"condizionale|presente": ["avrei", "avresti", "avrebbe", "avremmo", "avreste", "avrebbero"],
		},
	},
	{
		"infinito": "fare", "gruppo": "ere", "aux": "avere",
		"radice": "fac", "participio": "fatto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["faccio", "fai", "fa", "facciamo", "fate", "fanno"],
			"indicativo|passato remoto": ["feci", "facesti", "fece", "facemmo", "faceste", "fecero"],
			"indicativo|futuro semplice": ["farò", "farai", "farà", "faremo", "farete", "faranno"],
			"congiuntivo|presente": ["faccia", "faccia", "faccia", "facciamo", "facciate", "facciano"],
			"condizionale|presente": ["farei", "faresti", "farebbe", "faremmo", "fareste", "farebbero"],
		},
	},
	{
		"infinito": "dire", "gruppo": "ere", "aux": "avere",
		"radice": "dic", "participio": "detto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["dico", "dici", "dice", "diciamo", "dite", "dicono"],
			"indicativo|passato remoto": ["dissi", "dicesti", "disse", "dicemmo", "diceste", "dissero"],
			"indicativo|futuro semplice": ["dirò", "dirai", "dirà", "diremo", "direte", "diranno"],
			"congiuntivo|presente": ["dica", "dica", "dica", "diciamo", "diciate", "dicano"],
			"condizionale|presente": ["direi", "diresti", "direbbe", "diremmo", "direste", "direbbero"],
		},
	},
	{
		"infinito": "andare", "gruppo": "are", "aux": "essere",
		"participio": "andato", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["vado", "vai", "va", "andiamo", "andate", "vanno"],
			"indicativo|futuro semplice": ["andrò", "andrai", "andrà", "andremo", "andrete", "andranno"],
			"congiuntivo|presente": ["vada", "vada", "vada", "andiamo", "andiate", "vadano"],
			"condizionale|presente": ["andrei", "andresti", "andrebbe", "andremmo", "andreste", "andrebbero"],
		},
	},
	{
		"infinito": "potere", "gruppo": "ere", "aux": "avere",
		"participio": "potuto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["posso", "puoi", "può", "possiamo", "potete", "possono"],
			"indicativo|futuro semplice": ["potrò", "potrai", "potrà", "potremo", "potrete", "potranno"],
			"congiuntivo|presente": ["possa", "possa", "possa", "possiamo", "possiate", "possano"],
			"condizionale|presente": ["potrei", "potresti", "potrebbe", "potremmo", "potreste", "potrebbero"],
		},
	},
	{
		"infinito": "volere", "gruppo": "ere", "aux": "avere",
		"participio": "voluto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["voglio", "vuoi", "vuole", "vogliamo", "volete", "vogliono"],
			"indicativo|passato remoto": ["volli", "volesti", "volle", "volemmo", "voleste", "vollero"],
			"indicativo|futuro semplice": ["vorrò", "vorrai", "vorrà", "vorremo", "vorrete", "vorranno"],
			"congiuntivo|presente": ["voglia", "voglia", "voglia", "vogliamo", "vogliate", "vogliano"],
			"condizionale|presente": ["vorrei", "vorresti", "vorrebbe", "vorremmo", "vorreste", "vorrebbero"],
		},
	},
	{
		"infinito": "sapere", "gruppo": "ere", "aux": "avere",
		"participio": "saputo", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["so", "sai", "sa", "sappiamo", "sapete", "sanno"],
			"indicativo|passato remoto": ["seppi", "sapesti", "seppe", "sapemmo", "sapeste", "seppero"],
			"indicativo|futuro semplice": ["saprò", "saprai", "saprà", "sapremo", "saprete", "sapranno"],
			"congiuntivo|presente": ["sappia", "sappia", "sappia", "sappiamo", "sappiate", "sappiano"],
			"condizionale|presente": ["saprei", "sapresti", "saprebbe", "sapremmo", "sapreste", "saprebbero"],
		},
	},
	{
		"infinito": "venire", "gruppo": "ire", "aux": "essere",
		"participio": "venuto", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["vengo", "vieni", "viene", "veniamo", "venite", "vengono"],
			"indicativo|passato remoto": ["venni", "venisti", "venne", "venimmo", "veniste", "vennero"],
			"indicativo|futuro semplice": ["verrò", "verrai", "verrà", "verremo", "verrete", "verranno"],
			"congiuntivo|presente": ["venga", "venga", "venga", "veniamo", "veniate", "vengano"],
			"condizionale|presente": ["verrei", "verresti", "verrebbe", "verremmo", "verreste", "verrebbero"],
		},
	},
	{
		"infinito": "vedere", "gruppo": "ere", "aux": "avere",
		"participio": "visto", "regolare": false,
		"irregolari": {
			"indicativo|passato remoto": ["vidi", "vedesti", "vide", "vedemmo", "vedeste", "videro"],
			"indicativo|futuro semplice": ["vedrò", "vedrai", "vedrà", "vedremo", "vedrete", "vedranno"],
			"condizionale|presente": ["vedrei", "vedresti", "vedrebbe", "vedremmo", "vedreste", "vedrebbero"],
		},
	},
	{
		"infinito": "leggere", "gruppo": "ere", "aux": "avere",
		"participio": "letto", "regolare": false,
		"irregolari": {
			"indicativo|passato remoto": ["lessi", "leggesti", "lesse", "leggemmo", "leggeste", "lessero"],
		},
	},
	{
		"infinito": "prendere", "gruppo": "ere", "aux": "avere",
		"participio": "preso", "regolare": false,
		"irregolari": {
			"indicativo|passato remoto": ["presi", "prendesti", "prese", "prendemmo", "prendeste", "presero"],
		},
	},
	{
		"infinito": "scrivere", "gruppo": "ere", "aux": "avere",
		"participio": "scritto", "regolare": false,
		"irregolari": {
			"indicativo|passato remoto": ["scrissi", "scrivesti", "scrisse", "scrivemmo", "scriveste", "scrissero"],
		},
	},
	{
		"infinito": "stare", "gruppo": "are", "aux": "essere",
		"participio": "stato", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["sto", "stai", "sta", "stiamo", "state", "stanno"],
			"indicativo|passato remoto": ["stetti", "stesti", "stette", "stemmo", "steste", "stettero"],
			"indicativo|futuro semplice": ["starò", "starai", "starà", "staremo", "starete", "staranno"],
			"congiuntivo|presente": ["stia", "stia", "stia", "stiamo", "stiate", "stiano"],
			"congiuntivo|imperfetto": ["stessi", "stessi", "stesse", "stessimo", "steste", "stessero"],
			"condizionale|presente": ["starei", "staresti", "starebbe", "staremmo", "stareste", "starebbero"],
		},
	},
	{
		"infinito": "dare", "gruppo": "are", "aux": "avere",
		"participio": "dato", "regolare": false,
		"irregolari": {
			"indicativo|presente": ["do", "dai", "dà", "diamo", "date", "danno"],
			"indicativo|passato remoto": ["diedi", "desti", "diede", "demmo", "deste", "diedero"],
			"indicativo|futuro semplice": ["darò", "darai", "darà", "daremo", "darete", "daranno"],
			"congiuntivo|presente": ["dia", "dia", "dia", "diamo", "diate", "diano"],
			"congiuntivo|imperfetto": ["dessi", "dessi", "desse", "dessimo", "deste", "dessero"],
			"condizionale|presente": ["darei", "daresti", "darebbe", "daremmo", "dareste", "darebbero"],
		},
	},
]

static func chiave(modo: String, tempo: String) -> String:
	return "%s|%s" % [modo, tempo]

static func casella_esiste(modo: String, tempo: String) -> bool:
	return TEMPI.has(modo) and Array(TEMPI[modo]).has(tempo)

static func composto(modo: String, tempo: String) -> bool:
	return COMPOSTI.has(chiave(modo, tempo))

static func verbo_per_infinito(infinito: String) -> Dictionary:
	for voce in VERBI:
		if str(Dictionary(voce).get("infinito", "")) == infinito:
			return Dictionary(voce).duplicate(true)
	return {}

static func radice_di(verbo: Dictionary) -> String:
	if verbo.has("radice"):
		return str(verbo["radice"])
	var infinito := str(verbo.get("infinito", ""))
	return infinito.substr(0, maxi(infinito.length() - 3, 0))

static func participio_di(verbo: Dictionary) -> String:
	if verbo.has("participio"):
		return str(verbo["participio"])
	return radice_di(verbo) + str(PARTICIPI.get(str(verbo.get("gruppo", "are")), "ato"))

## **La voce.** Il cuore di tutto: dato un verbo e una casella, la forma esatta.
##
## Torna stringa vuota se la casella non esiste — è il modo in cui il duello
## riconosce che «passato remoto del condizionale» non è un posto dove si può
## andare, e spegne la runa che ci porterebbe.
static func voce(verbo: Dictionary, modo: String, tempo: String, persona: int) -> String:
	if verbo.is_empty() or not casella_esiste(modo, tempo):
		return ""
	var indice := clampi(persona, 0, 5)
	var passo := chiave(modo, tempo)
	if COMPOSTI.has(passo):
		var ricetta: Array = COMPOSTI[passo]
		var ausiliare := verbo_per_infinito(str(verbo.get("aux", "avere")))
		var testa := voce(ausiliare, str(ricetta[0]), str(ricetta[1]), indice)
		return "%s %s" % [testa, _participio_accordato(verbo, indice)]
	var irregolari: Dictionary = verbo.get("irregolari", {})
	if irregolari.has(passo):
		return str(Array(irregolari[passo])[indice])
	var tavola: Dictionary = DESINENZE.get(str(verbo.get("gruppo", "are")), DESINENZE["are"])
	if not tavola.has(passo):
		return ""
	return radice_di(verbo) + str(Array(tavola[passo])[indice])

## **L'accordo del participio con l'ausiliare «essere»**: «io sono andato», «noi
## siamo andati». Si accorda il numero e non il genere, che è esattamente quello
## che stampa ogni tabella di coniugazione scolastica — la forma di citazione. Il
## duello non sa chi sta parlando, e inventare un genere sarebbe peggio che
## usare quello non marcato.
static func _participio_accordato(verbo: Dictionary, persona: int) -> String:
	var participio := participio_di(verbo)
	if str(verbo.get("aux", "avere")) != "essere" or persona < 3:
		return participio
	if participio.ends_with("o"):
		return participio.substr(0, participio.length() - 1) + "i"
	return participio

## Tutte le 78 voci di un verbo, per chiave «modo|tempo|persona». Serve a chi
## deve cercare fra le forme — per esempio per sapere se una voce ne individua
## una sola casella o se è ambigua ([[VerbDuel]] non mostra mai una voce ambigua
## come bersaglio).
static func tutte_le_voci(verbo: Dictionary) -> Dictionary:
	var fuori: Dictionary = {}
	for modo in MODI:
		for tempo in Array(TEMPI[modo]):
			for persona in range(6):
				fuori["%s|%s|%d" % [modo, str(tempo), persona]] = voce(verbo, modo, str(tempo), persona)
	return fuori

## **Quante caselle produce esattamente questa forma.** Uno significa che la voce
## si lascia riconoscere; due o più significa che è ambigua — «cantaste» è
## passato remoto e congiuntivo imperfetto insieme, «canti» è tre cose diverse.
## Mostrarne una come bersaglio e poi dire «no, intendevo l'altra» sarebbe la
## bugia peggiore che un gioco di grammatica possa raccontare.
static func caselle_che_danno(verbo: Dictionary, forma: String) -> int:
	var quante := 0
	for valore in tutte_le_voci(verbo).values():
		if str(valore) == forma:
			quante += 1
	return quante

## L'etichetta di una casella come la si legge a scuola: «congiuntivo trapassato
## · voi».
static func etichetta(modo: String, tempo: String, persona: int) -> String:
	return "%s %s · %s" % [modo, tempo, str(PERSONE[clampi(persona, 0, 5)])]
