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
const ARCHETIPO_CIRCUITO := "circuito"         # riflessione · seguire il flusso quando lo schema cambia
const ARCHETIPO_CICLO := "ciclo"                # velocità · registrare una breve sequenza e riusarla
const ARCHETIPO_TRACCIA := "traccia"             # riflessione · fissare segnali esterni prima che spariscano
const ARCHETIPO_RADIO := "radio"                 # velocità · riconoscere l'intenzione oltre le parole
const ARCHETIPO_MERCATO := "mercato"             # riflessione · distinguere richieste quasi uguali

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
	# Ruggine riavvia la macchina a mano ed è fiera di farlo. Il nastro non le
	# chiede di chiamare un ciclo: mostra che una sequenza fissata una volta
	# continua a lavorare anche quando i pezzi arrivano tutti insieme.
	"w03-ruggine": {
		"archetipo": ARCHETIPO_CICLO,
		"forma": FORMA_VELOCITA,
		"titolo": "Cento giri, tre mosse",
		"consegna": "Il nastro si riempie. Prepara il braccio e lascia passare i pezzi.",
		"convinzioneBersaglio": "I cicli sono per i pigri.",
		"vittoria": "Il braccio ripete senza stancarsi. Ruggine smette di chiamarlo pigrizia.",
		"sconfitta": "Il nastro ha traboccato. Ruggine riporta i pezzi all'inizio, uno per uno.",
	},
	"w03-sesto": {
		"archetipo": ARCHETIPO_TRACCIA,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "La traccia fuori dalla testa",
		"consegna": "La stanza si velarà. Lascia una traccia che dica al braccio dove andare.",
		"convinzioneBersaglio": "Se non me lo ricordo, vuol dire che non l'ho mai saputo.",
		"vittoria": "La stanza è nascosta, ma la traccia resta. Sesto riconosce il gesto delle sue mani.",
		"sconfitta": "La nebbia ha coperto la stanza. Sesto lascia i segnali al loro posto e potete riprovare.",
	},
	"w04-marea": {
		"archetipo": ARCHETIPO_RADIO,
		"forma": FORMA_VELOCITA,
		"titolo": "Radio di burrasca",
		"consegna": "La radio è disturbata. Invia ogni messaggio alla luce che gli serve.",
		"convinzioneBersaglio": "Capire è tradurre parola per parola.",
		"vittoria": "Le parole erano diverse, ma le luci hanno capito tutte. Marea ascolta il senso.",
		"sconfitta": "La burrasca ha inghiottito l'ultima chiamata. Marea riaccende la radio e potete riprovare.",
	},
	"w04-lino": {
		"archetipo": ARCHETIPO_MERCATO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il mercato delle venti parole",
		"consegna": "I clienti parlano quasi uguale. Dai a ciascuno quello che ha chiesto.",
		"convinzioneBersaglio": "Per farsi capire bastano venti parole.",
		"vittoria": "Ogni richiesta aveva un dettaglio che cambiava tutto. Lino prende nota, captain.",
		"sconfitta": "Il banco resta aperto. Lino rimette in ordine le cassette e potete riprovare.",
	},
	# **Il terzo archetipo: la stessa funzione, una forma che muta.**
	#
	# Ciro sa riprodurre una fotografia del circuito. Il Delta gli toglie proprio
	# quella scorciatoia: a ogni accensione i collegamenti cambiano posto, mentre
	# batteria, interruttori e lampada continuano a fare la stessa cosa. Non si
	# chiede di nominare un componente; si segue energia visibile dentro una rete.
	"w08-ciro": {
		"archetipo": ARCHETIPO_CIRCUITO,
		"forma": FORMA_RIFLESSIONE,
		"titolo": "Il circuito mutante",
		"consegna": "Il Delta ha spostato tutti i nodi. Accendi la lampada ogni volta che lo schema si ricompone.",
		"convinzioneBersaglio": "Basta ricordare lo schema giusto.",
		"vittoria": "Tre schemi diversi, la stessa corrente. Ciro smette di contare i nodi e segue il lampo.",
		"sconfitta": "Il Delta si spegne senza danni. Ciro ridisegna i collegamenti: adesso sapete dove non passa.",
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
		ARCHETIPO_CIRCUITO:
			# Due grandezze indipendenti: quante volte lo schema muta e quanti
			# interruttori vanno letti in ciascuno. Nessuna delle due restringe i
			# bersagli e nessuna introduce un cronometro.
			return {
				"schemi": clampi(2 + int(floor(float(livello - 1) / 6.0)), 2, 5),
				"passaggi": clampi(2 + int(floor(float(livello - 1) / 5.0)), 2, 6),
				"errori": clampi(5 - int(floor(float(livello - 1) / 8.0)), 3, 5),
				"secondi": 0.0,
			}
		ARCHETIPO_CICLO:
			# Il gesto resta una breve programmazione. Salendo di mondo cresce
			# quanto a lungo il braccio deve ripeterla, non la precisione richiesta.
			return {
				"ripetizioni": clampi(3 + int(floor(float(livello - 1) / 6.0)), 3, 6),
				"secondi": 15.0 + float(livello) * 0.8,
				"mosse": 3,
			}
		ARCHETIPO_TRACCIA:
			return {
				"segnali": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5),
				"errori": clampi(4 - int(floor(float(livello - 1) / 10.0)), 2, 4),
				"secondi": 0.0,
			}
		ARCHETIPO_RADIO:
			return {
				"messaggi": clampi(5 + int(floor(float(livello - 1) / 5.0)), 5, 9),
				"secondi": 4.8 + float(livello) * 0.15,
				"errori": 2,
			}
		ARCHETIPO_MERCATO:
			return {"richieste": clampi(3 + int(floor(float(livello - 1) / 8.0)), 3, 5), "errori": 3, "secondi": 0.0}
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
