class_name NpcArc
extends RefCounted

## **I personaggi cambiano perché tu impari.** (8 agosto 2026)
##
## Richiesta del committente: «diamo sostanza alla vita dei mondi, curiamo
## carattere e comportamento dei personaggi dandogli un significato anche
## didattico».
##
## **Il carattere c'era già, e non usciva.** Quarantasei residenti hanno nel
## catalogo `registro`, `tic`, `convinzione`, `bisogno` e un **arco** in tre
## stadi. Cercando chi li leggesse: nessuno tranne il loro stesso audit. Erano
## contenuto scritto, verificato e mai pronunciato — la stessa specie di difetto
## degli `clearedHazardIds`, la parola che compariva una volta sola in tutto
## l'albero.
##
## **E gli archi sono la cosa migliore che ci sia nel catalogo.** Hanno tutti la
## stessa forma, ed è la forma del cambiamento concettuale:
##
##   1. **abitudine cieca** — «conta uno per uno perché così ha sempre fatto, e
##      non sa più perché»;
##   2. **dissonanza** — «ha visto Eli contare a gruppi e il numero tornava lo
##      stesso: cerca l'inganno e non lo trova»;
##   3. **metodo compreso, e insegnato a un altro** — «conta a gruppi di dieci e
##      lo insegna a Puccio».
##
## È esattamente come si impara davvero, ed è per questo che il terzo stadio
## conta più degli altri due: vedere qualcuno che **spiega a qualcun altro** una
## cosa che poco fa non sapeva è la dimostrazione, dentro la finzione, che
## imparare succede. Un bambino che lo guarda sta guardando sé stesso.
##
## **Che cosa fa avanzare lo stadio, e perché il criterio di prima era sbagliato.**
## Lo stadio veniva da `_npc_story_stage()`: contava **quanti incontri erano
## stati chiusi in quella visita al mondo**. Un personaggio che cambia perché hai
## toccato tre cose non insegna niente — cambia con l'orologio, non con te. E
## siccome era una misura sola per tutto il mondo, tutti i residenti cambiavano
## insieme, il che li rendeva un coro invece che persone.
##
## Adesso lo stadio di ciascuno dipende da **quanto il giocatore ha imparato
## nella materia di quel personaggio**, letta dalla stessa prontezza che governa
## il gate. Tobia il contatore cambia quando tu capisci a contare; se non la
## tocchi, resta dov'è — e ha ragione a restarci.

## Le soglie, in frazione della prontezza della materia (0..1: 1 = in linea).
##
## La prima è bassa apposta: la dissonanza nasce presto, appena il bambino fa
## una cosa che al personaggio sembra impossibile. La seconda sta alta perché il
## terzo stadio è una conquista — se arrivasse a metà strada varrebbe meno.
const SOGLIA_DISSONANZA := 0.34
const SOGLIA_METODO := 0.80

## Quanti stadi ha un arco. Tre, e non è un numero rotondo per caso: sotto tre
## non c'è cambiamento (si passa da com'era a com'è, senza il momento in cui
## dubita), sopra tre si diluisce.
const STADI := 3

## Lo stadio del personaggio, 0..2.
##
## `progression` serve a leggere la prontezza della materia; se manca — negli
## audit di solo catalogo — si risponde 0, che è lo stato iniziale onesto.
static func stadio(progression, npc_id: String) -> int:
	if progression == null:
		return 0
	var dati := NpcCatalog.resident(npc_id)
	if dati.is_empty() or Array(dati.get("arco", [])).size() < STADI:
		return 0
	var materia := ApparatusConfig.world_subject(int(dati.get("world", 1)))
	var stato: Dictionary = progression.apparatus_readiness(materia)
	# **Un personaggio non torna indietro.** (16 agosto 2026)
	#
	# `apparatus_readiness` è la misura grezza, e cala anche per cose che non
	# dipendono da questa materia — un ripasso che scade mentre il bambino ne
	# gioca un'altra. Letta da sola, faceva regredire allo stadio 1 chi era già
	# arrivato in fondo al proprio arco: Tobia che aveva imparato a raggruppare
	# tornava a contare uno per uno perché nel frattempo si era giocato musica.
	# Disimparare non è una cosa che questo gioco deve mostrare per sbaglio.
	if bool(progression.materia_in_linea(materia)):
		return STADI - 1
	var quota := float(stato.get("progress", 0.0))
	if quota >= SOGLIA_METODO:
		return STADI - 1
	if quota >= SOGLIA_DISSONANZA:
		return 1
	return 0

## Che cosa si vede fare al personaggio adesso: la riga del suo arco.
##
## È scritta in terza persona nel catalogo — «conta uno per uno perché così ha
## sempre fatto» — ed è giusto lasciarla così: non è una battuta che il
## personaggio pronuncia, è **quello che il bambino osserva**. La differenza
## conta: le persone non annunciano di essere cambiate, si vede.
static func osservazione(progression, npc_id: String) -> String:
	var dati := NpcCatalog.resident(npc_id)
	var arco: Array = Array(dati.get("arco", []))
	if arco.size() < STADI:
		return ""
	return str(arco[clampi(stadio(progression, npc_id), 0, STADI - 1)])

## La materia di cui questo personaggio è testimone. Serve a dire al bambino
## **perché** quella persona sta cambiando: senza, il cambiamento sembra magia.
static func materia_di(npc_id: String) -> String:
	var dati := NpcCatalog.resident(npc_id)
	if dati.is_empty():
		return ""
	return str(ApparatusConfig.world_subject(int(dati.get("world", 1))))

static func ha_arco(npc_id: String) -> bool:
	return Array(NpcCatalog.resident(npc_id).get("arco", [])).size() >= STADI

## **La cosa che crede, e che smetterà di credere.** (9 agosto 2026)
##
## È il pezzo più prezioso del catalogo, e anche questo non usciva: ogni
## residente ha una `convinzione` e un `bisogno`. Lette in fila, le quarantasei
## convinzioni sono un elenco di **misconcezioni** vere, precise e specifiche per
## materia — «Contare in fretta è barare», «I cicli sono per i pigri», «Capire è
## tradurre parola per parola», «L'ordine giusto è quello che si vede».
##
## Sono esattamente gli errori di ragionamento che un bambino di quell'età fa
## davvero, e il `bisogno` è la situazione concreta in cui quella convinzione
## smette di funzionare — che è il solo modo in cui una misconcezione si smonta:
## non dicendo che è sbagliata, ma mettendola davanti a un caso che non regge.
##
## **Perché mostrarla ha valore didattico e non è colore.** Un bambino che legge
## «Tobia crede che contare in fretta sia barare» riconosce un pensiero che ha
## avuto anche lui. E quando, più avanti, quella stessa riga compare come
## «CREDEVA che… adesso non più», vede una cosa che il gioco non può insegnare in
## nessun altro modo: **le idee si cambiano, e cambiarle è come si impara**.
##
## La convinzione non viene mai commentata dal gioco. Non si dice «sbagliava»:
## si mostra prima, e poi si mostra che non la pensa più così. Chi guarda tira
## la conclusione da solo, ed è l'unico modo in cui quella conclusione resta.
static func credenza(progression, npc_id: String) -> Dictionary:
	var dati := NpcCatalog.resident(npc_id)
	var convinzione := str(dati.get("convinzione", "")).strip_edges()
	if convinzione.is_empty():
		return {}
	return {
		"convinzione": convinzione,
		"bisogno": str(dati.get("bisogno", "")).strip_edges(),
		"superata": stadio(progression, npc_id) >= STADI - 1,
	}

## La riga da mostrare accanto all'osservazione. Vuota se non c'è niente da dire.
static func riga_di_credenza(progression, npc_id: String) -> String:
	var c := credenza(progression, npc_id)
	if c.is_empty():
		return ""
	if bool(c["superata"]):
		return "Credeva che: «%s» — adesso non più." % str(c["convinzione"])
	var riga := "Crede che: «%s»" % str(c["convinzione"])
	var bisogno := str(c.get("bisogno", ""))
	if not bisogno.is_empty():
		riga += "
%s" % bisogno
	return riga

## **Che cosa si vede fare da lontano.** (8 agosto 2026)
##
## Tre parole sopra la testa, una per stadio. Servono perché il cambiamento
## finora si leggeva soltanto parlandoci: attraversando il mondo, un personaggio
## che ha capito e uno che non ha capito erano identici.
##
## Sono generiche apposta, e vale la pena dire perché. La tentazione era di
## scriverne una su misura per ciascuno dei quarantasei — sarebbe più bello e
## sarebbe **falso** per due di loro: Lino e Marco arrivano in fondo restando
## convinti di aver ragione. «Insegna quello che ha capito» sopra la testa di
## Lino sarebbe una bugia scritta a caratteri grandi.
##
## Queste tre valgono per tutti, compresi quei due: dicono che qualcosa si è
## mosso, senza dire che cosa. Il che cosa lo si scopre parlandoci, ed è giusto
## che costi l'avvicinarsi.
const ATTIVITA := [
	"come ha sempre fatto",
	"qualcosa non gli torna",
	"non è più quello di prima",
]

static func attivita(progression, npc_id: String) -> String:
	if not ha_arco(npc_id):
		return ""
	return str(ATTIVITA[clampi(stadio(progression, npc_id), 0, ATTIVITA.size() - 1)])

## Vero quando il personaggio ha completato il suo arco: è il momento in cui la
## scena lo avvicina a qualcun altro, perché una cosa capita da soli e una cosa
## capita insieme si vedono diverse anche da lontano.
static func in_fondo_all_arco(progression, npc_id: String) -> bool:
	return ha_arco(npc_id) and stadio(progression, npc_id) >= STADI - 1

## La riga che accompagna l'osservazione allo stadio più alto.
##
## Solo al terzo stadio, e solo lì. Agli altri il gioco non commenta —
## commentare «guarda, non ha ancora capito» sarebbe una cattiveria verso il
## personaggio e una lezione sbagliata verso chi guarda.
##
## **La frase non dice che cosa ha capito.** La prima versione diceva «ha
## imparato, e adesso lo spiega a qualcun altro»: per la maggior parte dei
## residenti è vero, per due — che restano convinti di aver ragione, e sono
## scritti così apposta — sarebbe stata una bugia. Il gioco dice l'unica cosa che
## sa con certezza: che quella persona è cambiata, e quando.
static func nota_di_traguardo(progression, npc_id: String) -> String:
	if stadio(progression, npc_id) < STADI - 1:
		return ""
	var materia := materia_di(npc_id)
	if materia.is_empty():
		return ""
	return "Non è più quello di prima. È cambiato mentre tu imparavi %s." % materia
