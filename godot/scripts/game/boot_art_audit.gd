extends SceneTree

## **L'arte dei personaggi parte con il gioco, sempre.** (21 agosto 2026)
##
## Decisione del committente, dopo aver visto il difetto: *«eliminiamo le figure
## di ripiego, il gioco deve partire con la grafica migliore sempre»*.
##
## Prima i 74 ritratti, le 24 tavole dei guardiani, gli 11 Custodi e i 5
## itineranti viaggiavano nel pacchetto differito insieme all'audio: chi entrava
## nel mondo nei primi venti secondi vedeva i gusci vettoriali. Il rimontaggio
## all'arrivo del pacchetto ha chiuso il difetto, ma la finestra restava — e una
## finestra in cui il gioco si mostra peggio di com'e' non e' un compromesso che
## questo progetto vuole fare.
##
## Adesso quelle tavole stanno nel pacchetto d'avvio. Nel differito resta solo
## l'audio, che degrada in silenzio e non ha una faccia.
##
## **Perche' serve un audit per una riga di configurazione.** Il filtro di export
## non lo esegue nessuno: e' una stringa in un `.cfg` che nessun test tocca, e
## rimetterci dentro `assets/npcs/**/*` costa un secondo e non rompe niente —
## in editor. Il difetto ricomparirebbe solo sul Web, solo nei primi venti
## secondi, solo alla prima apertura di una build: esattamente le condizioni in
## cui e' gia' vissuto un mese senza che nessuno lo vedesse.

const PRESETS := "res://export_presets.cfg"

## Le cartelle che devono stare nel pacchetto d'avvio: tutto cio' che ha una
## faccia e un ripiego disegnato.
const CON_UNA_FACCIA := [
	"assets/npcs",
	"assets/guardians",
	"assets/custodi",
	"assets/itinerants",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var file := FileAccess.open(PRESETS, FileAccess.READ)
	assert(file != null, "export_presets.cfg non leggibile")
	var testo := file.get_as_text()
	file.close()

	var difetti: Array = []
	for riga in testo.split("\n"):
		var pulita := str(riga).strip_edges()
		if pulita.begins_with("exclude_filter="):
			for cartella in CON_UNA_FACCIA:
				if pulita.contains(cartella):
					difetti.append("un preset esclude «%s» dal pacchetto d'avvio: quei personaggi tornerebbero al ripiego" % cartella)
		if pulita.begins_with("export_files="):
			for cartella in CON_UNA_FACCIA:
				if pulita.contains(cartella):
					difetti.append("il pacchetto differito contiene «%s»: quelle tavole arriverebbero dopo il primo mondo" % cartella)

	# L'audio invece **deve** restare differito: sono 60 file che non servono a
	# entrare nel mondo e che degradano in silenzio. Se sparisse da li', il
	# giocatore aspetterebbe prima del primo fotogramma per qualcosa che puo'
	# arrivare dopo.
	assert(testo.contains("assets/audio/*.wav"),
		"l'audio non e' piu' differito: il primo fotogramma aspetterebbe 60 file che non servono ad arrivarci")

	for difetto in difetti:
		print("  · %s" % difetto)
	_verdetto(difetti)
	if difetti.is_empty():
		print("BOOT ART audit OK - ritratti, guardiani, Custodi e itineranti partono con il gioco")
	quit(0 if difetti.is_empty() else 1)

## L'assert sta a parte: fallendo interromperebbe `_run` prima di `quit()` e il
## processo resterebbe appeso fino al timeout del runner.
func _verdetto(difetti: Array) -> void:
	assert(difetti.is_empty(),
		"l'arte con una faccia non parte piu' con il gioco: %d difetti" % difetti.size())
