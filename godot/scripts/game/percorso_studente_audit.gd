extends SceneTree

## La guardia del percorso studente: i posti hanno un nome proprio e diverso, e
## lo sguardo intorno dice soltanto quello che si vedrebbe davvero.
##
## Nasce con [[NomiDeiLuoghi]] e [[PercorsoStudente]] il 10 settembre 2026. I due
## moduli sono puri: si controllano sui ventiquattro mondi senza costruire una
## scena, ed e' il motivo per cui sono stati scritti puri.
##
## **Il tetto della vista si abbassa e mai si alza.** `COPERTURA_MINIMA` e' la
## percentuale di punti d'interesse dai quali, stando li' in piedi, si vede
## almeno un'altra cosa del mondo. E' la misura di quanto il cammino fra due
## tappe sia muto: sotto questa soglia lo sguardo tacerebbe cosi' spesso da
## diventare inutile, e il bambino tornerebbe al quadro degli obiettivi.

const FIXTURE_SEED := "percorso-studente-fixture"

## Misurata sui 24 mondi il 10 settembre 2026: **97%**. Il pavimento sta due
## punti sotto la misura, non venti: serve a fermare una modifica che diradasse
## il mondo, e un pavimento lontano dalla misura non ferma niente. Si alza quando
## il mondo si infittisce; non si abbassa per far passare una modifica.
const COPERTURA_MINIMA := 0.95

## Quota delle materie che sanno nominare il proprio quartiere. Misurata sui 24
## mondi il 10 settembre 2026: **90%**, su 67 quartieri. Il pavimento sta cinque
## punti sotto la misura; si alza, non si abbassa.
const QUARTIERE_MINIMO := 0.85

func _init() -> void:
	var punti_totali := 0
	var punti_con_vista := 0
	var quartieri_totali := 0
	var materie_totali := 0
	var materie_con_quartiere := 0
	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		var context := {
			"missionsRequired": MissionEventDirector.HOST_EVENTS,
			"weakTopics": ["fragile"],
			"dueTopics": ["ripasso"],
			"recentFormats": [],
		}
		var events := MissionEventDirector.plan(profile, context, FIXTURE_SEED)
		assert(not events.is_empty(), "mondo %d senza eventi" % level)

		# --- I nomi dei posti ------------------------------------------------
		var nomi := NomiDeiLuoghi.mappa(events)
		var visti: Dictionary = {}
		for event_data in events:
			var event: Dictionary = event_data
			var id := str(event.get("id", ""))
			assert(nomi.has(id), "mondo %d: l'evento %s resta senza nome" % [level, id])
			var nome := str(nomi[id])
			assert(not nome.strip_edges().is_empty(),
				"mondo %d: nome vuoto per %s" % [level, id])
			assert(not visti.has(nome),
				"mondo %d: due posti si chiamano «%s»" % [level, nome])
			visti[nome] = true
			# Il ripiego numerato esiste per non essere mai ambiguo, non per
			# essere usato: se compare, i sostantivi di quel ruolo sono finiti e
			# ne va aggiunto uno, non tollerato un «(2)» sulla mappa.
			assert(not nome.contains("("),
				"mondo %d: «%s» e' finito sul ripiego numerato" % [level, nome])
			for parola in NomiDeiLuoghi.PAROLE_DEL_REGISTRO:
				assert(not nome.to_lower().contains(str(parola)),
					"mondo %d: «%s» e' una voce di registro, non il nome di un posto" % [
						level, nome])
			var materia := str(event.get("subject", ""))
			assert(NomiDeiLuoghi.COMPLEMENTO.has(materia),
				"mondo %d: la materia %s non ha un complemento di luogo" % [level, materia])
			assert(not NomiDeiLuoghi.richiesta(materia).is_empty(),
				"mondo %d: la materia %s non dice che cosa chiede" % [level, materia])
			# Ogni grammatica che il direttore emette dev'essere una delle tre
			# che [[ScopertaLuogo]] sa leggere: una quarta cadrebbe sul ripiego
			# e il posto si leggerebbe da lontano senza che nessuno l'abbia
			# deciso.
			var cue := str(event.get("discoveryCue", ""))
			assert(ScopertaLuogo.LETTURA.has(cue),
				"mondo %d: grammatica di scoperta «%s» che nessuno sa leggere" % [level, cue])

		# --- I quartieri ------------------------------------------------------
		var quartieri := NomiDeiLuoghi.quartieri(events)
		var nomi_di_quartiere: Dictionary = {}
		for costellazione in quartieri.keys():
			var nome_quartiere := str(quartieri[costellazione])
			assert(nome_quartiere.begins_with("il quartiere "),
				"mondo %d: «%s» non e' scritto come un quartiere" % [level, nome_quartiere])
			# La preposizione articolata: «il quartiere di il campo» e' il modo
			# piu' rapido di far smettere di leggere queste righe.
			for storpiatura in ["di il ", "di lo ", "di la ", "di i ", "di le ", "di gli "]:
				assert(not nome_quartiere.contains(str(storpiatura)),
					"mondo %d: preposizione non articolata in «%s»" % [level, nome_quartiere])
			assert(not nomi_di_quartiere.has(nome_quartiere),
				"mondo %d: due quartieri si chiamano «%s»" % [level, nome_quartiere])
			nomi_di_quartiere[nome_quartiere] = true
			# Un quartiere esiste solo dove ci sono almeno due posti: altrimenti
			# la frase sarebbe «il banco delle misure, nel quartiere del banco
			# delle misure».
			var quanti := 0
			for event_data in events:
				if str(Dictionary(event_data).get("locationCluster", "")) == str(costellazione):
					quanti += 1
			assert(quanti >= 2,
				"mondo %d: «%s» e' un quartiere con un posto solo" % [level, nome_quartiere])
		quartieri_totali += quartieri.size()
		for materia_data in ApparatusConfig.SUBJECT_CYCLE:
			materie_totali += 1
			if not NomiDeiLuoghi.quartiere_di(events, str(materia_data)).is_empty():
				materie_con_quartiere += 1

		# --- Lo sguardo intorno ----------------------------------------------
		var cose: Array = []
		for event_data in events:
			var event: Dictionary = event_data
			cose.append({
				"id": str(event.get("id", "")),
				"tipo": PercorsoStudente.PROVA if bool(event.get("countsForGate", false))
					else PercorsoStudente.ALLENAMENTO,
				"nome": str(nomi[str(event.get("id", ""))]),
				"posizione": event.get("position", Vector2.ZERO),
				"ricordato": false,
			})

		var spawn: Vector2 = profile["spawn"]
		var vedute: Array = [spawn]
		for cosa_data in cose:
			vedute.append(Vector2(Dictionary(cosa_data).get("posizione", spawn)))

		for punto_data in vedute:
			var punto: Vector2 = punto_data
			var letture := PercorsoStudente.sguardo(punto, cose)
			# Determinismo: la stessa scena non puo' dire due frasi diverse.
			var ancora := PercorsoStudente.sguardo(punto, cose)
			assert(letture.size() == ancora.size(),
				"mondo %d: lo sguardo non e' deterministico" % level)
			for indice in range(letture.size()):
				assert(str(Dictionary(letture[indice])["id"]) == str(Dictionary(ancora[indice])["id"]),
					"mondo %d: lo sguardo cambia ordine fra due chiamate" % level)

			var generi: Dictionary = {}
			for lettura_data in letture:
				var lettura: Dictionary = lettura_data
				var quanto := float(lettura.get("quanto", 0.0))
				assert(quanto >= PercorsoStudente.GIA_QUI,
					"mondo %d: lo sguardo nomina il posto su cui sei in piedi" % level)
				assert(quanto <= PercorsoStudente.PORTATA_VISTA,
					("mondo %d: nominato «%s» a %.0f unita' senza esserci mai passato"
						% [level, str(lettura.get("nome", "")), quanto]))
				assert(bool(lettura.get("aVista", false)),
					"mondo %d: lettura fuori vista dichiarata a vista" % level)
				assert(not str(lettura.get("dove", "")).is_empty(),
					"mondo %d: lettura senza direzione" % level)
				generi[str(lettura.get("tipo", ""))] = true
			assert(letture.size() <= PercorsoStudente.QUANTE,
				"mondo %d: lo sguardo nomina piu' di %d cose" % [level, PercorsoStudente.QUANTE])
			# La regola della scelta: due letture, due generi — quando i generi
			# disponibili a vista erano davvero due.
			if letture.size() == 2:
				var disponibili: Dictionary = {}
				for cosa_data in cose:
					var cosa: Dictionary = cosa_data
					var distanza := punto.distance_to(Vector2(cosa.get("posizione", punto)))
					if distanza >= PercorsoStudente.GIA_QUI \
							and distanza <= PercorsoStudente.PORTATA_VISTA:
						disponibili[str(cosa.get("tipo", ""))] = true
				if disponibili.size() >= 2:
					assert(generi.size() == 2,
						"mondo %d: due letture dello stesso genere: e' una classifica, non una scelta" % level)

			var frase := PercorsoStudente.frase(letture)
			if letture.is_empty():
				assert(frase.is_empty(),
					"mondo %d: frase di riempimento con niente da dire" % level)
			else:
				assert(not frase.is_empty(), "mondo %d: letture mute" % level)
				assert(not frase.contains("%"),
					"mondo %d: percentuale nella frase dello sguardo" % level)
				for parola in NomiDeiLuoghi.PAROLE_DEL_REGISTRO:
					assert(not frase.to_lower().contains(str(parola)),
						"mondo %d: parola di registro nella frase: «%s»" % [level, frase])

		# La copertura si misura dai punti d'interesse, non dallo spawn: e' li'
		# che il bambino si trova quando deve decidere dove andare adesso.
		for cosa_data in cose:
			var cosa: Dictionary = cosa_data
			punti_totali += 1
			if not PercorsoStudente.sguardo(Vector2(cosa.get("posizione", spawn)), cose).is_empty():
				punti_con_vista += 1

	# --- La distanza di lettura del nome ([[ScopertaLuogo]]) -----------------
	#
	# La forbice: sopra il raggio d'interazione (88) e sotto la mezza diagonale
	# dello schermo (734). Fuori da li' la grammatica non descrive piu' niente —
	# un nome leggibile solo quando ci sei sopra, o leggibile prima ancora di
	# vedere il posto.
	var grammatiche := [
		ScopertaLuogo.DISTANT_SIGNAL, ScopertaLuogo.LOCAL_CLUE, ScopertaLuogo.PROXIMITY]
	for cue_data in grammatiche:
		var cue := str(cue_data)
		var soglia := ScopertaLuogo.distanza_di_lettura(cue)
		assert(soglia > 88.0 and soglia < 734.0,
			"«%s»: distanza di lettura %.0f fuori dalla forbice utile" % [cue, soglia])
		# Monotona: allontanandosi il nome non torna mai piu' leggibile.
		var precedente := 2.0
		for passo in range(0, 40):
			var quanto := float(passo) * 30.0
			var adesso := ScopertaLuogo.opacita_del_nome(cue, quanto)
			assert(adesso <= precedente + 0.001,
				"«%s»: il nome torna leggibile allontanandosi" % cue)
			precedente = adesso
		assert(is_equal_approx(ScopertaLuogo.opacita_del_nome(cue, 0.0), 1.0),
			"«%s»: il nome non e' leggibile nemmeno da fermo sul posto" % cue)
		assert(is_equal_approx(ScopertaLuogo.opacita_del_nome(cue, 5000.0, true), 1.0),
			"«%s»: l'alto contrasto non tiene acceso il nome" % cue)
	assert(ScopertaLuogo.distanza_di_lettura(ScopertaLuogo.DISTANT_SIGNAL)
			> ScopertaLuogo.distanza_di_lettura(ScopertaLuogo.LOCAL_CLUE)
		and ScopertaLuogo.distanza_di_lettura(ScopertaLuogo.LOCAL_CLUE)
			> ScopertaLuogo.distanza_di_lettura(ScopertaLuogo.PROXIMITY),
		"le tre grammatiche non sono ordinate: la scoperta non ha tre distanze")
	assert(not ScopertaLuogo.si_annuncia(ScopertaLuogo.PROXIMITY)
		and ScopertaLuogo.si_annuncia(ScopertaLuogo.DISTANT_SIGNAL)
		and ScopertaLuogo.si_annuncia(ScopertaLuogo.LOCAL_CLUE),
		"il buco voluto della mappa non e' piu' il cippo lungo il sentiero")
	# Il ripiego dev'essere il piu' generoso: un nome che non si legge mai
	# somiglia a un posto rotto, uno che si legge presto e' solo brutto.
	assert(ScopertaLuogo.distanza_di_lettura("grammatica-che-non-esiste")
			>= ScopertaLuogo.distanza_di_lettura(ScopertaLuogo.DISTANT_SIGNAL),
		"il ripiego della grammatica e' piu' stretto della piu' generosa")

	var copertura := float(punti_con_vista) / maxf(1.0, float(punti_totali))
	assert(copertura >= COPERTURA_MINIMA,
		"da %.0f%% dei punti d'interesse non si vede nient'altro (pavimento %.0f%%)" % [
			copertura * 100.0, COPERTURA_MINIMA * 100.0])

	# **Quante materie sanno dire dove si allenano.** Misurata il 10 settembre
	# 2026. Il pavimento si alza quando i quartieri si addensano; non si abbassa
	# per far passare una modifica. Sotto questa quota il quadro degli obiettivi
	# tornerebbe a rispondere «da qualche parte nel mondo».
	var con_quartiere := float(materie_con_quartiere) / maxf(1.0, float(materie_totali))
	assert(con_quartiere >= QUARTIERE_MINIMO,
		"solo il %.0f%% delle materie sa dire in che quartiere si allena (pavimento %.0f%%)" % [
			con_quartiere * 100.0, QUARTIERE_MINIMO * 100.0])

	print(("Percorso studente audit OK - 24 mondi: nomi unici, sguardo deterministico, "
		+ "copertura %.0f%%, %d quartieri, %.0f%% delle materie sa dove si allena") % [
		copertura * 100.0, quartieri_totali, con_quartiere * 100.0])
	quit(0)
