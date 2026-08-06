class_name ProgressBoard
extends RefCounted

## **Il registro dei giocatori.** (6 agosto 2026)
##
## Una tabella per confrontarsi con gli altri e avere un po' di sfida. Sembra
## semplice, e invece è il posto dove questo gioco può farsi più male da solo:
## una classifica per livello premia chi ha cominciato prima, e chi arriva un
## mese dopo è ultimo per sempre senza poterci fare niente. Dopo il lavoro sul
## gate — che misura la padronanza e non la velocità — sarebbe un contrordine.
##
## Da qui le tre famiglie di misure, che convivono di proposito:
##
##   RIPARTE     la settimana: prove superate negli ultimi sette giorni.
##               Chiunque può tornare in testa lunedì. È la gara vera.
##   CUMULATIVO  livello, mondi, giorni giocati, argomenti consolidati.
##               Racconta la strada fatta; non è una gara che si recupera.
##   PER MATERIA dodici classifiche invece di una. Con dodici materie e pochi
##               giocatori, quasi ogni bambino è primo in qualcosa — ed è la
##               ragione per cui `medaglie()` esiste.
##
## E una regola che non si tocca: **nessuna misura scende mai come conseguenza
## di un'assenza**. Niente serie da spezzare, niente decadimento. Chi torna dopo
## un mese trova quello che aveva. Vedi il guard-rail in cima a `play_diary.gd`.

## Gli assi su cui ci si può ordinare. `riparte` distingue la gara che chiunque
## può vincere da quelle che raccontano il passato: la UI mette in evidenza la
## prima, perché è quella che dà sfida senza escludere nessuno.
const ASSI := [
	{
		"id": "settimana", "etichetta": "La settimana", "riparte": true,
		"unita": "prove", "spiega": "Prove superate negli ultimi sette giorni. Riparte da sé: si può tornare primi in qualsiasi momento.",
	},
	{
		"id": "livello", "etichetta": "Il viaggio", "riparte": false,
		"unita": "livello", "spiega": "Quanto lontano sei arrivato. Non si recupera in fretta: è il racconto della strada fatta.",
	},
	{
		"id": "consolidati", "etichetta": "Le cose sapute", "riparte": false,
		"unita": "argomenti", "spiega": "Argomenti che il manuale di NORA dà per consolidati: sapute davvero, non viste una volta.",
	},
	{
		"id": "giorni", "etichetta": "I giorni", "riparte": false,
		"unita": "giorni", "spiega": "Giorni in cui hai giocato. Non è una serie: saltare un giorno non toglie niente.",
	},
]

## La scheda di un giocatore, calcolata dal suo salvataggio. Pura: non scrive.
##
## È anche il formato che viaggia verso il gruppo in cloud, e per questo contiene
## SOLO numeri e un nome. Nessun codice di ripristino, nessun contenuto del
## salvataggio: chi entra in un gruppo vede come vanno gli altri, non può
## toccare le loro partite.
static func scheda(save, nome: String, oggi: String = "") -> Dictionary:
	var materie: Dictionary = {}
	var grezze: Dictionary = save.data.get("mastery", {})
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		var subject := str(subject_data)
		materie[subject] = clampf(float(grezze.get(subject, 0.0)), 0.0, 1.0)

	var consolidati := 0
	for stato in Dictionary(save.data.get("codex", {})).values():
		if str(stato) == KnowledgeCodex.STATE_CONSOLIDATED:
			consolidati += 1

	return {
		"nome": nome,
		"livello": save.level(),
		"mondi": Array(Dictionary(save.data.get("worlds", {})).get("unlocked", [])).size(),
		"giorni": PlayDiary.days_played(save),
		"settimana": PlayDiary.passed_this_week(save, oggi),
		"consolidati": consolidati,
		"materie": materie,
		"aggiornato": int(Time.get_unix_time_from_system()),
	}

## Le schede di chi gioca su QUESTO dispositivo.
##
## Senza profili l'elenco è vuoto, e la scheda «di casa» non ha niente da
## mostrare: è corretto, perché con un giocatore solo non c'è confronto — e la
## UI in quel caso invita a creare una seconda casella invece di disegnare una
## classifica con una riga.
static func schede_locali(oggi: String = "") -> Array:
	var out: Array = []
	for p in PlayerProfiles.all():
		var profilo: Dictionary = p
		var save := GameSaveManager.new(str(profilo.get("file", "")))
		save.load_save()
		out.append(scheda(save, str(profilo.get("name", "")), oggi))
	return out

## Vero se la scheda ha la forma attesa. Serve al gruppo in cloud: quello che
## arriva da fuori non è mai da credere sulla parola.
static func scheda_valida(s: Dictionary) -> bool:
	for chiave in ["nome", "livello", "settimana", "giorni", "consolidati"]:
		if not s.has(chiave):
			return false
	if str(s["nome"]).strip_edges().is_empty():
		return false
	return true

static func valore(s: Dictionary, asse: String) -> float:
	if asse.begins_with("materia:"):
		return float(Dictionary(s.get("materie", {})).get(asse.substr(8), 0.0))
	return float(s.get(asse, 0))

## Schede ordinate su un asse, dal primo all'ultimo.
##
## A parità di valore vince chi ha il nome prima in alfabeto — non chi è stato
## letto per primo. Un ordine che dipende dall'ordine di lettura cambierebbe da
## solo fra un'apertura e l'altra, e due bambini a pari merito si vedrebbero
## scavalcare a turno senza aver fatto niente.
static func ordina(schede: Array, asse: String) -> Array:
	var copia := schede.duplicate()
	copia.sort_custom(func(a, b):
		var va := valore(a, asse)
		var vb := valore(b, asse)
		if is_equal_approx(va, vb):
			return str(Dictionary(a).get("nome", "")).naturalnocasecmp_to(
				str(Dictionary(b).get("nome", ""))) < 0
		return va > vb)
	return copia

## Per ogni giocatore, gli assi in cui è primo.
##
## È il cuore del compromesso: con dodici materie e quattro assi generali, in un
## gruppo di quattro bambini è raro che qualcuno non sia primo in niente. Un
## bambino che non guida nessuna classifica NON compare qui, e la UI in quel caso
## non scrive «nessuna medaglia» — non scrive niente: un premio vuoto dichiarato
## a voce alta è peggio del silenzio.
##
## Un primo posto conta solo se il valore è maggiore di zero: essere «primo» in
## una materia che nessuno ha ancora toccato non è un traguardo.
static func medaglie(schede: Array) -> Dictionary:
	var out: Dictionary = {}
	if schede.size() < 2:
		return out
	var assi: Array = []
	for a in ASSI:
		assi.append(str(Dictionary(a)["id"]))
	for subject_data in ApparatusConfig.SUBJECT_CYCLE:
		assi.append("materia:%s" % str(subject_data))

	for asse in assi:
		var ordinate := ordina(schede, str(asse))
		if ordinate.is_empty():
			continue
		var primo: Dictionary = ordinate[0]
		if valore(primo, str(asse)) <= 0.0:
			continue
		# Un primato condiviso non è un primato: se il secondo ha lo stesso
		# valore, nessuno dei due lo rivendica.
		if ordinate.size() > 1 and is_equal_approx(
				valore(primo, str(asse)), valore(ordinate[1], str(asse))):
			continue
		var nome := str(primo.get("nome", ""))
		var elenco: Array = out.get(nome, [])
		elenco.append(str(asse))
		out[nome] = elenco
	return out

## L'etichetta leggibile di un asse.
static func etichetta(asse: String) -> String:
	if asse.begins_with("materia:"):
		return asse.substr(8)
	for a in ASSI:
		if str(Dictionary(a)["id"]) == asse:
			return str(Dictionary(a)["etichetta"])
	return asse

## Come si scrive il valore di un asse in una riga di tabella.
static func testo_valore(s: Dictionary, asse: String) -> String:
	if asse.begins_with("materia:"):
		return "%d%%" % int(round(valore(s, asse) * 100.0))
	return str(int(valore(s, asse)))
