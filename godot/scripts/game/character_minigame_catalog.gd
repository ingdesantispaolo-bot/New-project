class_name CharacterMinigameCatalog
extends RefCounted

## **Un minigioco per personaggio.** (9 agosto 2026)
##
## Richiesta del committente: minigiochi originali e divertenti, uno per
## personaggio, con difficoltà adatta al mondo e coerenza col personaggio e con
## la storia. Alcuni di **velocità**, altri di **riflessione**.
##
## **La regola che decide se un minigioco è buono, e vale più di tutto il
## resto.** Il minigioco deve far fallire la **convinzione** del personaggio, non
## interrogare il bambino.
##
## Tobia crede che «contare in fretta è barare». Il suo minigioco non chiede
## quanto fa 6×7: mette davanti un mucchio che **non si riesce a contare uno per
## uno nel tempo dato**, e lascia scoprire che a gruppi di dieci il conto torna.
## La didattica non è nascosta perché travestita — è nascosta perché **è la
## meccanica**. Chi gioca non sta rispondendo, sta risolvendo.
##
## **Perché due famiglie e non una.** La velocità e la riflessione allenano cose
## diverse e, soprattutto, **premiano bambini diversi**. Un gioco tutto di
## velocità esclude chi pensa piano — che spesso è chi pensa meglio; uno tutto di
## riflessione annoia chi ha bisogno di muovere le mani. Metà e metà non è un
## compromesso: è la condizione perché nessuno dei due si senta escluso dalla
## storia, e `character_minigame_audit` la protegge.
##
## **La difficoltà viene dal mondo, non dal catalogo.** Scriverla a mano voce per
## voce vorrebbe dire quarantasei tarature da tenere allineate: al primo
## ritocco della curva sarebbero quarantasei posti da toccare. Qui c'è una
## funzione sola, e il catalogo dice solo *chi* e *cosa*.

const FORMA_VELOCITA := "velocita"
const FORMA_RIFLESSIONE := "riflessione"

## Gli archetipi disponibili. Ognuno è una **dinamica**, non una scenografia: è
## la lezione delle ricette e delle minimissioni — la varietà che conta è quella
## delle azioni.
const ARCHETIPO_MUCCHIO := "mucchio"          # velocità · raggruppare per contare
const ARCHETIPO_SCAFFALE := "scaffale"        # riflessione · ordinare per una regola che non si vede

## I minigiochi scritti finora.
##
## **Uno solo, e per scelta.** La tappa 1 del piano dice «uno fino in fondo,
## prima di moltiplicare per quarantasei»: serve a misurare quanto costa
## costruirne uno e se al collaudo si sente diverso da un esercizio. Scriverne
## dodici a metà avrebbe dato dodici cose da rifare invece di un numero.
const GIOCHI := {
	"w01-tobia": {
		"archetipo": ARCHETIPO_MUCCHIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Il mucchio che non finisce",
		# La consegna non dice MAI la strategia: scoprirla è il gioco. Dire
		# «raggruppa per dieci» trasformerebbe la scoperta in un'istruzione da
		# eseguire, che è esattamente ciò che questo lotto evita.
		"consegna": "Tobia deve consegnare il conto prima che chiuda il deposito. Quanti cristalli ci sono?",
		"convinzioneBersaglio": "Contare in fretta è barare.",
		"vittoria": "Il conto torna, e ci è voluto meno tempo. Tobia guarda le tue mani, non il numero.",
		"sconfitta": "Il deposito ha chiuso. Tobia ricomincia da capo, e uno.",
	},
	# **Il secondo, e di proposito dell'altra famiglia.**
	#
	# La tappa 2 del piano serviva a scoprire se la forma si generalizza. Corinna
	# e' il caso opposto a Tobia sotto ogni aspetto utile: altro mondo, altra
	# materia, e soprattutto **niente cronometro**. La sua convinzione non si
	# smonta con la fretta — si smonta con una regola che non si vede.
	"w02-corinna": {
		"archetipo": ARCHETIPO_SCAFFALE,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Lo scaffale che non si vede",
		"consegna": "Corinna ha svuotato uno scaffale e non sa più dove va ogni parola. Rimettile a posto.",
		"convinzioneBersaglio": "L'ordine giusto è quello che si vede.",
		"vittoria": "Lo scaffale sta in piedi, e nessuna parola è al posto per via di quanto è lunga.",
		"sconfitta": "Lo scaffale è di nuovo un mucchio. Corinna le rimette in fila per lunghezza, per intanto.",
		# **Le parole arrivano ordinate per LUNGHEZZA**, che e' l'ordine di
		# Corinna: e' l'esca. Chi la segue sbaglia, perche' la lunghezza non dice
		# niente sulla funzione — ed e' esattamente la cosa da capire.
		"scaffali": ["COSE", "AZIONI"],
		"parole": [
			["re", 0], ["va", 1], ["sole", 0], ["corre", 1], ["porta", 0],
			["salta", 1], ["nave", 0], ["scrive", 1], ["albero", 0], ["dormire", 1],
			["finestra", 0], ["cantare", 1], ["montagna", 0], ["ascoltare", 1],
			["biblioteca", 0], ["costruire", 1],
		],
	},
}

## Quanti pezzi ha il mucchio, e quanto tempo c'è: la difficoltà del mondo.
##
## **Il tempo cresce con la quantità, ma meno che proporzionalmente**, ed è tutto
## il punto del gioco: contare uno per uno resta possibile all'inizio e diventa
## impossibile dopo, senza che nessuno lo dica. Se il tempo crescesse in
## proporzione, la strategia vecchia funzionerebbe sempre e il personaggio non
## avrebbe nessun motivo di cambiare idea.
static func parametri(archetipo: String, world: int) -> Dictionary:
	var livello := clampi(world, 1, 24)
	match archetipo:
		ARCHETIPO_MUCCHIO:
			# **Il mucchio parte gia' grande.** Con trenta pezzi e tredici secondi
			# — la prima taratura — contare uno per uno costava 13,5 s contro 13,4
			# concessi: un bambino svelto ce la faceva **col metodo vecchio**, e
			# la convinzione di Tobia sarebbe uscita confermata. Il margine adesso
			# e' del 47%, e `character_minigame_audit` non lo lascia scendere.
			var pezzi := 36 + livello * 6
			return {
				"pezzi": pezzi,
				"secondi": 12.0 + float(livello) * 0.9,
				# Quanti pezzi entrano in un gruppo. Dieci sempre: è la base del
				# sistema numerico, e cambiarla da un mondo all'altro
				# insegnerebbe che è una convenzione arbitraria del gioco.
				"gruppo": 10,
			}
		ARCHETIPO_SCAFFALE:
			# Nessun cronometro: e' un gioco di riflessione, e mettere fretta a chi
			# deve capire una regola invisibile misurerebbe l'ansia, non l'idea.
			#
			# Gli errori concessi calano salendo di mondo, ma non scendono mai a
			# zero: una prova in cui il primo tocco decide tutto non si gioca, si
			# subisce.
			return {
				"parole": clampi(6 + int(floor(float(livello) / 3.0)) * 2, 6, 16),
				"errori": clampi(4 - int(floor(float(livello) / 8.0)), 2, 4),
				"secondi": 0.0,
			}
	return {}

static func ha_gioco(npc_id: String) -> bool:
	return GIOCHI.has(npc_id)

## La scheda completa di un minigioco: testo autoriale + parametri del mondo.
static func scheda(npc_id: String) -> Dictionary:
	if not GIOCHI.has(npc_id):
		return {}
	var voce: Dictionary = Dictionary(GIOCHI[npc_id]).duplicate(true)
	var dati := NpcCatalog.resident(npc_id)
	var world := int(dati.get("world", 1))
	voce["npc"] = npc_id
	voce["nome"] = str(dati.get("nome", npc_id))
	voce["world"] = world
	voce["materia"] = ApparatusConfig.world_subject(world)
	voce["parametri"] = parametri(str(voce["archetipo"]), world)
	return voce

## Quanti giochi per famiglia. Serve all'audit: il giorno in cui il catalogo
## sarà pieno, deve risultare bilanciato fra velocità e riflessione.
static func conteggio_forme() -> Dictionary:
	var out := {FORMA_VELOCITA: 0, FORMA_RIFLESSIONE: 0}
	for npc_id in GIOCHI.keys():
		var forma := str(Dictionary(GIOCHI[npc_id])["forma"])
		out[forma] = int(out.get(forma, 0)) + 1
	return out
