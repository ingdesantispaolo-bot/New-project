extends SceneTree

## **Il minigioco del personaggio, verificato dove conta.** (12 agosto 2026)
##
## Richiesta del committente: un minigioco per personaggio, difficoltà adatta al
## mondo, coerente col personaggio e con la storia, alcuni di velocità e altri di
## riflessione, **e presenti in tutti i mondi**.
##
## La qualità di un minigioco — se diverte — non si verifica con un audit: si
## verifica giocandoci. Qui si tiene solo quello che si può misurare, e sono le
## cose che, se cedono, rendono inutile il divertimento:
##
##   1. **la strategia vecchia deve fallire, e quella nuova riuscire.** È la
##      regola del lotto: il minigioco fa cadere la CONVINZIONE del personaggio,
##      non interroga il bambino. Se contando uno per uno si arrivasse in tempo,
##      Tobia avrebbe ragione e il gioco non insegnerebbe niente;
##   2. **il margine non dipende dalle dita.** Ogni archetipo di velocità ha un
##      tetto noto al ritmo umano — nel mucchio i secondi per tocco, nel ciclo il
##      `cooldown` — e la strategia vecchia deve perdere **anche a quel tetto**.
##      È l'errore che il mucchio ha già fatto una volta;
##   3. **la difficoltà cresce col mondo**, e cresce nel modo giusto: quello che
##      aumenta rende la strategia vecchia sempre meno sufficiente, non i
##      bersagli più piccoli;
##   4. **la consegna non svela la strategia.** Scoprirla è il gioco: dire
##      «raggruppa per dieci» trasformerebbe una scoperta in un'istruzione da
##      eseguire — la stessa azione, con dentro zero;
##   5. **nessun mondo abitato resta scoperto**, e ogni gioco ha il materiale che
##      il suo renderer si aspetta.

const OK := "CHARACTER MINIGAME audit VERDE"
## Quanto ci mette un bambino a toccare un pezzo alla volta, in secondi. Non è
## un numero di comodo: sotto i 0,45 s per tocco si sta misurando la velocità
## delle dita, che è l'ultima cosa da premiare qui.
const SECONDI_PER_TOCCO := 0.45
## Le parole che svelerebbero la strategia. Se compaiono nella consegna, la
## scoperta è già stata regalata.
const PAROLE_CHE_SVELANO := ["raggrupp", "decin", "per dieci", "a gruppi", "insieme di dieci",
	"una cosa per volta", "una alla volta", "prendi appunti", "scrivi la sequenza",
	"sposta il fulcro", "avvicina il cuneo", "dimezza"]

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_ogni_gioco_e_coerente()
	_ogni_residente_ha_il_suo_gioco()
	_ogni_gioco_ha_il_materiale_del_suo_renderer()
	_la_strategia_vecchia_fallisce()
	_la_difficolta_segue_il_mondo()
	_le_due_famiglie_esistono_entrambe()
	_il_circuito_muta_senza_mettere_fretta()
	_il_ciclo_non_si_vince_a_mano()
	_la_leva_non_cede_alla_forza()
	_la_prova_costringe_a_isolare()
	_la_stima_converge_e_indovinare_no()
	_l_esca_dello_scaffale_non_predice_niente()
	if errori.is_empty():
		print(OK)
	else:
		printerr("CHARACTER MINIGAME audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## Coerenza col personaggio e con la storia: il gioco appartiene a un residente
## vero, e bersaglia la convinzione che quel residente ha davvero nel catalogo.
func _ogni_gioco_e_coerente() -> void:
	for npc_id_data in CharacterMinigameCatalog.GIOCHI.keys():
		var npc_id := str(npc_id_data)
		var dati := NpcCatalog.resident(npc_id)
		if dati.is_empty():
			_fallisci("%s: minigioco di un personaggio che non esiste" % npc_id)
			continue
		var scheda := CharacterMinigameCatalog.scheda(npc_id)
		var bersaglio := str(scheda.get("convinzioneBersaglio", ""))
		var convinzione := str(dati.get("convinzione", ""))
		if bersaglio != convinzione:
			_fallisci("%s: il gioco bersaglia «%s» ma il personaggio crede «%s»" % [
				npc_id, bersaglio, convinzione])
		for campo in ["titolo", "consegna", "vittoria", "sconfitta"]:
			if str(scheda.get(campo, "")).strip_edges().is_empty():
				_fallisci("%s: manca «%s»" % [npc_id, campo])
		if not str(scheda.get("forma", "")) in [
				CharacterMinigameCatalog.FORMA_VELOCITA,
				CharacterMinigameCatalog.FORMA_RIFLESSIONE]:
			_fallisci("%s: forma sconosciuta «%s»" % [npc_id, scheda.get("forma", "")])
		# La consegna non svela la strategia.
		var consegna := str(scheda.get("consegna", "")).to_lower()
		for parola in PAROLE_CHE_SVELANO:
			if consegna.contains(str(parola)):
				_fallisci("%s: la consegna regala la strategia («%s»)" % [npc_id, parola])
		if Dictionary(scheda.get("parametri", {})).is_empty():
			_fallisci("%s: nessun parametro per l'archetipo «%s»" % [npc_id, scheda.get("archetipo", "")])

## **Tutti i mondi**, che è la richiesta esplicita del committente. Un mondo
## scoperto è un mondo dove i personaggi tornano a essere gente che parla e
## basta, e l'arco del residente resta una cosa che succede senza che il bambino
## ci metta le mani.
func _ogni_residente_ha_il_suo_gioco() -> void:
	var mancanti: Array[String] = []
	for npc_id_data in NpcCatalog.RESIDENTS.keys():
		var npc_id := str(npc_id_data)
		var funzione := str(Dictionary(NpcCatalog.RESIDENTS[npc_id]).get("funzione", ""))
		# I Bislacchi sono incontri itineranti, non residenti con arco in tre
		# stadi. Il contratto dei 46 copre specialisti e testimoni.
		if funzione not in ["specialista", "testimone"]:
			continue
		if not CharacterMinigameCatalog.ha_gioco(npc_id):
			mancanti.append(npc_id)
	mancanti.sort()
	if not mancanti.is_empty():
		_fallisci("residenti senza minigioco: %s" % str(mancanti))
	if CharacterMinigameCatalog.GIOCHI.size() != 46:
		_fallisci("il catalogo contiene %d giochi, il contratto ne richiede 46" % CharacterMinigameCatalog.GIOCHI.size())

## Ogni renderer si aspetta del materiale, e il materiale sta nella scheda. Uno
## scaffale senza parole o una prova senza manopole non si accorge di niente
## finché un bambino non ci arriva davanti.
func _ogni_gioco_ha_il_materiale_del_suo_renderer() -> void:
	for npc_id_data in CharacterMinigameCatalog.GIOCHI.keys():
		var npc_id := str(npc_id_data)
		var scheda := CharacterMinigameCatalog.scheda(npc_id)
		var parametri: Dictionary = scheda.get("parametri", {})
		match str(scheda.get("archetipo", "")):
			CharacterMinigameCatalog.ARCHETIPO_RITMO:
				if int(parametri.get("strofe", 0)) < 3:
					_fallisci("%s: meno di tre strofe, il pattern non viene verificato" % npc_id)
				if float(parametri.get("secondi", -1.0)) != 0.0:
					_fallisci("%s: la conta riflessiva ha un cronometro" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_SCAFFALE:
				var scaffali: Array = Array(scheda.get("scaffali", []))
				var parole: Array = Array(scheda.get("parole", []))
				if scaffali.size() < 2:
					_fallisci("%s: scaffale con meno di due destinazioni" % npc_id)
				if parole.size() < int(parametri.get("parole", 6)):
					_fallisci("%s: servono %d parole, ce ne sono %d" % [
						npc_id, int(parametri.get("parole", 6)), parole.size()])
				for voce in parole:
					if int(Array(voce)[1]) >= scaffali.size():
						_fallisci("%s: «%s» va su uno scaffale che non esiste" % [npc_id, str(Array(voce)[0])])
			CharacterMinigameCatalog.ARCHETIPO_TRACCIA:
				var segnali: Array = Array(scheda.get("segnali", []))
				if segnali.size() < int(parametri.get("segnali", 4)):
					_fallisci("%s: servono %d segnali, ce ne sono %d" % [
						npc_id, int(parametri.get("segnali", 4)), segnali.size()])
			CharacterMinigameCatalog.ARCHETIPO_CICLO:
				if Array(scheda.get("comandi", [])).size() != 3:
					_fallisci("%s: il ciclo vuole esattamente tre gesti" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_PROVA:
				var fattori: Array = Array(scheda.get("fattori", []))
				if fattori.size() < int(parametri.get("fattori", 3)):
					_fallisci("%s: servono %d manopole, ce ne sono %d" % [
						npc_id, int(parametri.get("fattori", 3)), fattori.size()])
				for fattore in fattori:
					if Array(Dictionary(fattore).get("valori", [])).size() != 2:
						_fallisci("%s: la manopola «%s» non ha due scatti" % [
							npc_id, str(Dictionary(fattore).get("nome", "?"))])
			CharacterMinigameCatalog.ARCHETIPO_MERCATO:
				var turni: Array = Array(scheda.get("turni", []))
				# Lino usa i turni scritti nel pannello: la scheda può non averne.
				if not turni.is_empty() and turni.size() < int(parametri.get("richieste", 3)):
					_fallisci("%s: servono %d richieste, ce ne sono %d" % [
						npc_id, int(parametri.get("richieste", 3)), turni.size()])
				for turno in turni:
					var scelte: Array = Array(Dictionary(turno).get("scelte", []))
					if scelte.size() != 3 or int(Dictionary(turno).get("giusta", -1)) >= scelte.size():
						_fallisci("%s: una richiesta ha scelte malformate" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_RADIO:
				var messaggi: Array = Array(scheda.get("messaggi", []))
				var destinazioni: Array = Array(scheda.get("destinazioni", []))
				if not messaggi.is_empty():
					if messaggi.size() < int(parametri.get("messaggi", 5)):
						_fallisci("%s: servono %d messaggi, ce ne sono %d" % [
							npc_id, int(parametri.get("messaggi", 5)), messaggi.size()])
					for voce in messaggi:
						if int(Array(voce)[1]) >= maxi(destinazioni.size(), 3):
							_fallisci("%s: un messaggio va a una destinazione che non c'è" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_STIMA:
				for campo in ["grandezza", "azione", "corto", "lungo"]:
					if str(scheda.get(campo, "")).strip_edges().is_empty():
						_fallisci("%s: alla stima manca «%s»" % [npc_id, campo])
			CharacterMinigameCatalog.ARCHETIPO_VIBRAZIONE:
				if int(parametri.get("prove", 0)) < 3:
					_fallisci("%s: meno di tre tremiti da confrontare" % npc_id)
				if int(parametri.get("corde", 0)) < 3:
					_fallisci("%s: meno di tre corde, il confronto è troppo ovvio" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_GLIFI:
				var glifi: Array = Array(scheda.get("glifi", []))
				if glifi.size() < int(parametri.get("glifi", 6)):
					_fallisci("%s: servono %d glifi, ce ne sono %d" % [
						npc_id, int(parametri.get("glifi", 6)), glifi.size()])
				for glifo in glifi:
					var voce: Dictionary = glifo
					if str(voce.get("radice", "")).is_empty() or int(voce.get("funzione", -1)) not in [0, 1]:
						_fallisci("%s: glifo senza radice o funzione valida" % npc_id)
			CharacterMinigameCatalog.ARCHETIPO_PARENTELA:
				var famiglie: Array = Array(scheda.get("famiglie", []))
				if famiglie.size() < int(parametri.get("famiglie", 3)):
					_fallisci("%s: servono %d famiglie, ce ne sono %d" % [
						npc_id, int(parametri.get("famiglie", 3)), famiglie.size()])
				for famiglia_data in famiglie:
					var famiglia: Dictionary = famiglia_data
					var significati: Array = Array(famiglia.get("significati", []))
					var parenti: Array = Array(famiglia.get("parenti", []))
					if str(famiglia.get("antica", "")).is_empty() or significati.size() != 3:
						_fallisci("%s: famiglia senza parola antica o tre ipotesi" % npc_id)
					if parenti.size() < int(parametri.get("indizi", 2)):
						_fallisci("%s: una famiglia non ha due parenti verificabili" % npc_id)
					if int(famiglia.get("giusta", -1)) < 0 or int(famiglia.get("giusta", -1)) >= significati.size():
						_fallisci("%s: famiglia senza significato valido" % npc_id)

## **La regola del lotto, in numeri.** Per ogni mondo: contare uno per uno non
## deve bastare, e raggruppare deve bastare con margine. Senza margine il gioco
## sarebbe vinto dalla fretta invece che dalla strategia.
func _la_strategia_vecchia_fallisce() -> void:
	for world in [1, 6, 12, 18, 24]:
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_MUCCHIO, world)
		var pezzi := int(p["pezzi"])
		var gruppo := int(p["gruppo"])
		var secondi := float(p["secondi"])
		var uno_per_uno := float(pezzi) * SECONDI_PER_TOCCO
		# **Non basta che il metodo vecchio perda: deve perdere con margine.**
		# Alla prima taratura mancava il 4 per mille — 13,5 s contro 13,4 — e con
		# uno scarto così un bambino veloce vince contando uno per uno, cioè la
		# convinzione del personaggio esce CONFERMATA dal gioco che doveva
		# smontarla. Il 30% è il minimo perché l'esito non dipenda dalle dita.
		if uno_per_uno <= secondi * 1.3:
			_fallisci("mondo %d: contare uno per uno quasi basta (%.1f s su %.1f) — la convinzione non cade" % [
				world, uno_per_uno, secondi])
		# Con i gruppi servono tanti tocchi quante sono le file piene, più i resti.
		var tocchi := int(floor(float(pezzi) / float(gruppo))) + posmod(pezzi, gruppo)
		var a_gruppi := float(tocchi) * SECONDI_PER_TOCCO
		if a_gruppi > secondi * 0.7:
			_fallisci("mondo %d: anche a gruppi si arriva al pelo (%.1f s su %.1f) — vince la fretta, non l'idea" % [
				world, a_gruppi, secondi])

## **Velocità E riflessione, non una sola.**
##
## Le due famiglie premiano bambini diversi: tutto velocità esclude chi pensa
## piano — che spesso è chi pensa meglio — e tutto riflessione annoia chi ha
## bisogno di muovere le mani.
##
## Il gioco di riflessione non può avere un cronometro. Non è una preferenza:
## mettere fretta a chi deve accorgersi di una regola misura l'ansia, non l'idea.
func _le_due_famiglie_esistono_entrambe() -> void:
	var conta := CharacterMinigameCatalog.conteggio_forme()
	for forma in [CharacterMinigameCatalog.FORMA_VELOCITA,
			CharacterMinigameCatalog.FORMA_RIFLESSIONE]:
		if int(conta.get(forma, 0)) <= 0:
			_fallisci("nessun minigioco di «%s»: metà dei bambini resta fuori" % forma)
	# Nessuna delle due può ridursi a una comparsa: sotto un terzo del totale la
	# famiglia c'è sulla carta e non nell'esperienza di chi gioca.
	var totale := int(conta.get(CharacterMinigameCatalog.FORMA_VELOCITA, 0)) + int(
		conta.get(CharacterMinigameCatalog.FORMA_RIFLESSIONE, 0))
	for forma in conta.keys():
		if totale > 0 and float(conta[forma]) / float(totale) < 0.33:
			_fallisci("«%s» è solo il %.0f%% dei giochi: quella famiglia è una comparsa" % [
				forma, 100.0 * float(conta[forma]) / float(totale)])
	for npc_id_data in CharacterMinigameCatalog.GIOCHI.keys():
		var scheda := CharacterMinigameCatalog.scheda(str(npc_id_data))
		if str(scheda.get("forma", "")) != CharacterMinigameCatalog.FORMA_RIFLESSIONE:
			continue
		var secondi := float(Dictionary(scheda.get("parametri", {})).get("secondi", 0.0))
		if secondi > 0.0:
			_fallisci("%s: gioco di riflessione con un cronometro (%.0f s)" % [npc_id_data, secondi])
		var errori_concessi := int(Dictionary(scheda.get("parametri", {})).get("errori", 0))
		if errori_concessi < 2:
			_fallisci("%s: %d errori concessi — il primo tocco decide tutto" % [npc_id_data, errori_concessi])

## La difficoltà cresce col mondo, e il tempo cresce **meno** della quantità: è
## ciò che rende la strategia vecchia sempre meno sufficiente.
func _la_difficolta_segue_il_mondo() -> void:
	var precedente := {}
	for world in range(1, 25):
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_MUCCHIO, world)
		if precedente.is_empty():
			precedente = p
			continue
		if int(p["pezzi"]) <= int(precedente["pezzi"]):
			_fallisci("mondo %d: il mucchio non cresce" % world)
		var crescita_pezzi := float(p["pezzi"]) / float(precedente["pezzi"])
		var crescita_tempo := float(p["secondi"]) / float(precedente["secondi"])
		if crescita_tempo >= crescita_pezzi:
			_fallisci("mondo %d: il tempo cresce quanto il mucchio — contare uno per uno resterebbe possibile" % world)
		precedente = p

## **Il circuito deve crescere cambiando il problema, non il dito.** Schemi e
## passaggi aumentano o restano stabili lungo i mondi; il tempo resta zero e i
## tentativi non scendono sotto tre. Al mondo di Ciro ci devono essere almeno tre
## riconfigurazioni: una sola immagine non potrebbe smentire chi la impara a
## memoria.
func _il_circuito_muta_senza_mettere_fretta() -> void:
	var ciro := CharacterMinigameCatalog.scheda("w08-ciro")
	if ciro.is_empty():
		_fallisci("Ciro non ha il suo circuito")
		return
	if int(Dictionary(ciro.get("parametri", {})).get("schemi", 0)) < 3:
		_fallisci("Ciro vede meno di tre schemi: può ancora imparare una fotografia")
	var precedente := CharacterMinigameCatalog.parametri(
		CharacterMinigameCatalog.ARCHETIPO_CIRCUITO, 1)
	for world in range(2, 25):
		var corrente := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_CIRCUITO, world)
		if int(corrente.get("schemi", 0)) < int(precedente.get("schemi", 0)):
			_fallisci("mondo %d: il circuito perde riconfigurazioni" % world)
		if int(corrente.get("passaggi", 0)) < int(precedente.get("passaggi", 0)):
			_fallisci("mondo %d: il circuito perde passaggi" % world)
		if float(corrente.get("secondi", -1.0)) != 0.0:
			_fallisci("mondo %d: il circuito di riflessione ha un cronometro" % world)
		if int(corrente.get("errori", 0)) < 3:
			_fallisci("mondo %d: il circuito concede meno di tre errori" % world)
		precedente = corrente

## **Il ciclo non si vince a mano, e non è questione di dita.**
##
## Il `cooldown` fra un gesto e il successivo mette un tetto al ritmo umano:
## `1/(3·cooldown)` pezzi al secondo, per chiunque. I pezzi arrivano a
## `1/arrivo`, quindi il guadagno netto della mano è la differenza, e il tempo
## che le servirebbe è `pezzi/guadagno`. Deve **eccedere il turno** con margine,
## altrimenti Ruggine ha ragione: il lavoro manuale basta.
##
## Il braccio, che ripete la sequenza, deve invece avanzare con largo margine —
## se vincesse per un pelo il bambino non capirebbe di aver scoperto qualcosa.
func _il_ciclo_non_si_vince_a_mano() -> void:
	for world in range(1, 25):
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_CICLO, world)
		var pezzi := float(p["pezzi"])
		var secondi := float(p["secondi"])
		var arrivi := 1.0 / float(p["arrivo"])
		var ritmo_mano := 1.0 / (3.0 * float(p["cooldown"]))
		var guadagno_mano := ritmo_mano - arrivi
		if guadagno_mano <= 0.0:
			# Il nastro cresce comunque: la mano non ha nessuna speranza, ma
			# nemmeno la sensazione di starci dietro. Serve che ci provi.
			_fallisci("mondo %d: la mano non sgombra niente (%.2f/s contro %.2f/s in arrivo)" % [
				world, ritmo_mano, arrivi])
			continue
		var tempo_a_mano := pezzi / guadagno_mano
		if tempo_a_mano <= secondi * 1.3:
			_fallisci("mondo %d: a mano si arriva quasi in fondo (%.1f s su %.1f) — il ciclo non serve" % [
				world, tempo_a_mano, secondi])
		var guadagno_braccio := 4.0 - arrivi
		var tempo_col_braccio := pezzi / guadagno_braccio
		if tempo_col_braccio > secondi * 0.7:
			_fallisci("mondo %d: nemmeno il braccio ce la fa comodamente (%.1f s su %.1f)" % [
				world, tempo_col_braccio, secondi])

## **La leva: spingere non deve funzionare mai, e un appoggio buono deve esserci
## sempre.** Sono le due metà della stessa regola. Se al mondo 1 la posizione di
## partenza sollevasse, Gerbo avrebbe ragione al primo tentativo; se al mondo 24
## non esistesse nessun appoggio valido, il gioco sarebbe una punizione.
func _la_leva_non_cede_alla_forza() -> void:
	var precedente := 0.0
	for world in range(1, 25):
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_LEVA, world)
		var peso := float(p["peso"])
		if LeverMinigamePanel.solleva(peso, LeverMinigamePanel.FULCRO_INIZIALE):
			_fallisci("mondo %d: il masso si alza senza spostare il cuneo — la forza bruta funziona" % world)
		var utile := LeverMinigamePanel.fulcro_utile(peso)
		if utile <= 0:
			_fallisci("mondo %d: nessun appoggio solleva il masso (peso %.0f)" % [world, peso])
		if peso <= precedente:
			_fallisci("mondo %d: il masso non pesa più di quello prima" % world)
		precedente = peso

## **La prova controllata: le prove concesse devono bastare al metodo e non al
## disordine.** Cambiando una manopola per volta ne servono quante sono le
## manopole; chi cambia a caso ha molte più configurazioni che tentativi. Se le
## prove fossero abbondanti, anche il disordine arriverebbe in fondo e il gioco
## non direbbe niente su come ci si arriva.
func _la_prova_costringe_a_isolare() -> void:
	for world in range(1, 25):
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_PROVA, world)
		var fattori := int(p["fattori"])
		var prove := int(p["prove"])
		if prove < fattori:
			_fallisci("mondo %d: %d prove per %d manopole — nemmeno il metodo ci sta" % [
				world, prove, fattori])
		var configurazioni := int(pow(2.0, float(fattori)))
		if prove >= configurazioni:
			_fallisci("mondo %d: %d prove per %d configurazioni — si arriva in fondo provandole tutte" % [
				world, prove, configurazioni])
		if float(p.get("secondi", -1.0)) != 0.0:
			_fallisci("mondo %d: la prova controllata ha un cronometro" % world)

## **L'esca dello scaffale non deve predire lo scaffale**, ed è la regola più
## importante di tutto l'archetipo.
##
## Le voci arrivano ordinate per una cosa che si vede — la lunghezza per
## Corinna, quanti lo ripetono per Danio, la forza per Vesca — e quella cosa deve
## essere **inutile**. Se seguendola si indovinasse, il gioco confermerebbe la
## convinzione invece di smontarla: è esattamente l'errore che il mercato di Lino
## aveva fatto, dove bastava accoppiare le lettere.
##
## Si misura così: ordinate come le vede il bambino, quante volte la destinazione
## **cambia** passando da una voce alla successiva. Se l'esca predicesse, le
## voci arriverebbero già raggruppate per scaffale e i cambi sarebbero pochissimi.
func _l_esca_dello_scaffale_non_predice_niente() -> void:
	for npc_id_data in CharacterMinigameCatalog.giochi_con_archetipo(
			CharacterMinigameCatalog.ARCHETIPO_SCAFFALE):
		var npc_id := str(npc_id_data)
		var scheda := CharacterMinigameCatalog.scheda(npc_id)
		var voci: Array = Array(scheda.get("parole", [])).duplicate(true)
		if voci.size() < 4:
			continue
		voci.sort_custom(func(a, b): return _peso_esca(a) < _peso_esca(b))
		var quante := mini(int(Dictionary(scheda.get("parametri", {})).get("parole", 6)), voci.size())
		var cambi := 0
		for i in range(1, quante):
			if int(Array(voci[i])[1]) != int(Array(voci[i - 1])[1]):
				cambi += 1
		var frazione := float(cambi) / float(maxi(1, quante - 1))
		if frazione < 0.4:
			_fallisci("%s: seguendo l'ordine che si vede si indovina il %.0f%% delle volte — l'esca non è un'esca" % [
				npc_id, 100.0 * (1.0 - frazione)])

## Lo stesso criterio del pannello: chi pesa meno viene mostrato per primo. Con
## quattro elementi conta il valore dichiarato, al contrario; con due la
## lunghezza del testo.
func _peso_esca(voce: Variant) -> float:
	var riga: Array = Array(voce)
	if riga.size() > 3:
		return -float(riga[3])
	return float(str(riga[0]).length())

## **La stima converge, l'indovinare no.** In ogni mondo la ricerca guidata dal
## riscontro — dimezzare l'intervallo a ogni tiro — deve entrare nei tiri
## concessi, e la ricerca cieca deve restarne fuori. È la differenza fra stimare
## e tirare a indovinare scritta in aritmetica invece che in una spiegazione, e
## se le due si toccano il gioco dà ragione a Solano.
func _la_stima_converge_e_indovinare_no() -> void:
	for world in range(1, 25):
		var p := CharacterMinigameCatalog.parametri(
			CharacterMinigameCatalog.ARCHETIPO_STIMA, world)
		var intervallo := float(p["intervallo"])
		var tolleranza := float(p["tolleranza"])
		var tiri := int(p["tiri"])
		var caselle := intervallo / (2.0 * tolleranza)
		var tiri_guidati := int(ceil(log(caselle) / log(2.0)))
		if tiri_guidati > tiri:
			_fallisci("mondo %d: nemmeno stringendo si arriva (%d tiri servono, %d concessi)" % [
				world, tiri_guidati, tiri])
		if caselle <= float(tiri):
			_fallisci("mondo %d: le caselle sono %.0f e i tiri %d — si vince provandole a caso" % [
				world, caselle, tiri])
