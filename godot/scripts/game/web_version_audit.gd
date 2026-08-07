extends SceneTree

## **La regola del «sto girando la copia vecchia?».** (7 agosto 2026)
##
## La catena web — manifesto, service worker, lanciatore — la verifica
## `audit-web-release.mjs`, che sa leggere JavaScript. Qui si verifica l'unica
## parte che vive in GDScript, ed è quella che decide **se dire qualcosa**.
##
## È una decisione più delicata di quanto sembri: un avviso che compare quando
## non dovrebbe si impara a chiudere senza leggerlo, e allora non serve più
## nemmeno quando ha ragione. Il caso che conta è il terzo — offline, o server
## irraggiungibile: la risposta giusta è **tacere**, non «sei vecchio».

const OK := "WEB VERSION audit VERDE"

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	# Uguali: niente da dire.
	_controlla(not WebVersionGuard.deve_riscaricare("abc1234", "abc1234"),
		"due versioni identiche chiedono di riscaricare")
	# Diverse: si avvisa.
	_controlla(WebVersionGuard.deve_riscaricare("abc1234", "def5678"),
		"una copia vecchia non viene segnalata")
	# **Non lo so.** Manifesto irraggiungibile, risposta vuota, gioco offline:
	# tacere. È il caso per cui questo audit esiste.
	_controlla(not WebVersionGuard.deve_riscaricare("abc1234", ""),
		"senza risposta dal server il gioco si dichiara vecchio")
	_controlla(not WebVersionGuard.deve_riscaricare("abc1234", "   "),
		"una risposta di soli spazi viene presa per una versione")
	# Pacchetto senza marchio: non si può concludere niente, quindi niente.
	_controlla(not WebVersionGuard.deve_riscaricare("", "def5678"),
		"un pacchetto senza commit si dichiara vecchio invece di tacere")

	# Fuori dal web non parte niente: su una build nativa non c'è niente da
	# riscaricare, e le chiamate devono restare innocue.
	_controlla(not WebVersionGuard.sul_web(),
		"l'audit gira in headless: non dovrebbe risultare sul web")
	WebVersionGuard.chiedi_versione_pubblicata()
	WebVersionGuard.riscarica()
	_controlla(WebVersionGuard.commit_ricevuto() == "",
		"fuori dal web arriva una versione dal nulla")

	# L'avviso nomina la versione nuova: senza, una segnalazione di gioco non può
	# dire QUALE, ed è il motivo per cui la versione sta scritta sul menu.
	var testo := WebVersionGuard.avviso("def5678abc")
	_controlla(testo.contains("def5678"), "l'avviso non nomina la versione nuova")
	_controlla(not testo.contains("def5678abc"),
		"l'avviso mostra il commit intero invece della sigla corta")

	# Il marchio del pacchetto deve esistere, altrimenti il confronto non ha un
	# lato sinistro e il controllo è decorativo.
	_controlla(BuildVersion.COMMIT.strip_edges() != "",
		"il pacchetto non dichiara nessun commit")

	if errori.is_empty():
		print(OK)
	else:
		printerr("WEB VERSION audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)
