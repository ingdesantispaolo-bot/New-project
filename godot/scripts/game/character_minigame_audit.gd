extends SceneTree

## **Il minigioco del personaggio, verificato dove conta.** (9 agosto 2026)
##
## Richiesta del committente: un minigioco per personaggio, difficoltà adatta al
## mondo, coerente col personaggio e con la storia, alcuni di velocità e altri di
## riflessione.
##
## La qualità di un minigioco — se diverte — non si verifica con un audit: si
## verifica giocandoci. Qui si tiene solo quello che si può misurare, e sono le
## tre cose che, se cedono, rendono inutile il divertimento:
##
##   1. **la strategia vecchia deve fallire, e quella nuova riuscire.** È la
##      regola del lotto: il minigioco fa cadere la CONVINZIONE del personaggio,
##      non interroga il bambino. Se contando uno per uno si arrivasse in tempo,
##      Tobia avrebbe ragione e il gioco non insegnerebbe niente;
##   2. **la difficoltà cresce col mondo**, e cresce nel modo giusto: il tempo
##      aumenta meno della quantità, altrimenti la strategia vecchia continuerebbe
##      a funzionare per sempre;
##   3. **la consegna non svela la strategia.** Scoprirla è il gioco: dire
##      «raggruppa per dieci» trasformerebbe una scoperta in un'istruzione da
##      eseguire — la stessa azione, con dentro zero.

const OK := "CHARACTER MINIGAME audit VERDE"
## Quanto ci mette un bambino a toccare un pezzo alla volta, in secondi. Non è
## un numero di comodo: sotto i 0,45 s per tocco si sta misurando la velocità
## delle dita, che è l'ultima cosa da premiare qui.
const SECONDI_PER_TOCCO := 0.45
## Le parole che svelerebbero la strategia. Se compaiono nella consegna, la
## scoperta è già stata regalata.
const PAROLE_CHE_SVELANO := ["raggrupp", "decin", "per dieci", "a gruppi", "insieme di dieci"]

var errori: Array = []

func _fallisci(messaggio: String) -> void:
	errori.append(messaggio)

func _init() -> void:
	_ogni_gioco_e_coerente()
	_la_strategia_vecchia_fallisce()
	_la_difficolta_segue_il_mondo()
	_le_due_famiglie_esistono_entrambe()
	_il_circuito_muta_senza_mettere_fretta()
	_il_ciclo_premia_la_sequenza_ripetuta()
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
		# uno scarto cosi' un bambino veloce vince contando uno per uno, cioe' la
		# convinzione del personaggio esce CONFERMATA dal gioco che doveva
		# smontarla. Il 30% e' il minimo perche' l'esito non dipenda dalle dita.
		if uno_per_uno <= secondi * 1.3:
			_fallisci("mondo %d: contare uno per uno quasi basta (%.1f s su %.1f) — la convinzione non cade" % [
				world, uno_per_uno, secondi])
		# Con i gruppi servono tanti tocchi quante sono le file piene, più i resti.
		var tocchi := int(floor(float(pezzi) / float(gruppo))) + posmod(pezzi, gruppo)
		var a_gruppi := float(tocchi) * SECONDI_PER_TOCCO
		if a_gruppi > secondi * 0.7:
			_fallisci("mondo %d: anche a gruppi si arriva al pelo (%.1f s su %.1f) — vince la fretta, non l'idea" % [
				world, a_gruppi, secondi])

## **Velocita' E riflessione, non una sola.**
##
## Le due famiglie premiano bambini diversi: tutto velocita' esclude chi pensa
## piano — che spesso e' chi pensa meglio — e tutto riflessione annoia chi ha
## bisogno di muovere le mani. La regola vale gia' adesso che i giochi sono due,
## e proprio adesso e' il momento in cui serve: e' scrivendo il terzo e il quarto
## che si scivola nella famiglia che si sa costruire meglio.
##
## Il gioco di riflessione non puo' avere un cronometro. Non e' una preferenza:
## mettere fretta a chi deve accorgersi di una regola misura l'ansia, non l'idea.
func _le_due_famiglie_esistono_entrambe() -> void:
	var conta := CharacterMinigameCatalog.conteggio_forme()
	for forma in [CharacterMinigameCatalog.FORMA_VELOCITA,
			CharacterMinigameCatalog.FORMA_RIFLESSIONE]:
		if int(conta.get(forma, 0)) <= 0:
			_fallisci("nessun minigioco di «%s»: meta' dei bambini resta fuori" % forma)
	for npc_id_data in CharacterMinigameCatalog.GIOCHI.keys():
		var scheda := CharacterMinigameCatalog.scheda(str(npc_id_data))
		if str(scheda.get("forma", "")) != CharacterMinigameCatalog.FORMA_RIFLESSIONE:
			continue
		var secondi := float(Dictionary(scheda.get("parametri", {})).get("secondi", 0.0))
		if secondi > 0.0:
			_fallisci("%s: gioco di riflessione con un cronometro (%.0f s)" % [npc_id_data, secondi])
		var errori := int(Dictionary(scheda.get("parametri", {})).get("errori", 0))
		if errori < 2:
			_fallisci("%s: %d errori concessi — il primo tocco decide tutto" % [npc_id_data, errori])

## La difficoltà cresce col mondo, e il tempo cresce **meno** della quantità:
## è ciò che rende la strategia vecchia sempre meno sufficiente.
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

## **Il terzo archetipo deve crescere cambiando il problema, non il dito.**
## Schemi e passaggi aumentano o restano stabili lungo i mondi; il tempo resta
## zero e i tentativi non scendono sotto tre. Al mondo di Ciro ci devono essere
## almeno tre riconfigurazioni: una sola immagine non potrebbe smentire chi la
## impara a memoria.
func _il_circuito_muta_senza_mettere_fretta() -> void:
	var ciro := CharacterMinigameCatalog.scheda("w08-ciro")
	if ciro.is_empty():
		_fallisci("Ciro non ha il suo terzo pilot")
		return
	if str(ciro.get("archetipo", "")) != CharacterMinigameCatalog.ARCHETIPO_CIRCUITO:
		_fallisci("Ciro non usa il Circuito mutante")
	var al_delta: Dictionary = ciro.get("parametri", {})
	if int(al_delta.get("schemi", 0)) < 3:
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

## Ruggine deve avere una sequenza breve da impostare una volta, ma abbastanza
## giri da rendere visibile il vantaggio della ripetizione; la fretta cresce
## senza trasformare i pulsanti in bersagli più piccoli.
func _il_ciclo_premia_la_sequenza_ripetuta() -> void:
	var ruggine := CharacterMinigameCatalog.scheda("w03-ruggine")
	if ruggine.is_empty() or str(ruggine.get("archetipo", "")) != CharacterMinigameCatalog.ARCHETIPO_CICLO:
		_fallisci("Ruggine non usa il ciclo ripetuto")
		return
	var precedente := CharacterMinigameCatalog.parametri(CharacterMinigameCatalog.ARCHETIPO_CICLO, 1)
	for world in range(1, 25):
		var corrente := CharacterMinigameCatalog.parametri(CharacterMinigameCatalog.ARCHETIPO_CICLO, world)
		if int(corrente.get("mosse", 0)) != 3:
			_fallisci("mondo %d: il ciclo non è una sequenza breve di tre mosse" % world)
		if int(corrente.get("ripetizioni", 0)) < 3:
			_fallisci("mondo %d: il braccio non ripete abbastanza da smentire il lavoro manuale" % world)
		if world > 1 and int(corrente.get("ripetizioni", 0)) < int(precedente.get("ripetizioni", 0)):
			_fallisci("mondo %d: il ciclo perde ripetizioni" % world)
		precedente = corrente
