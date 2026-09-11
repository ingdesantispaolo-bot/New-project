class_name PercorsoStudente
extends RefCounted

## **Da qui si vede.** (10 settembre 2026)
##
## Segnalazione del committente: *«lo studente quando si presenta in un mondo
## segue semplicemente il percorso indicatogli dalle istruzioni. Questo puo'
## andar bene ma toglie stimolo ad esplorazione del mondo»*.
##
## ## Perche' il mondo si percorreva come un elenco, misurato
##
## Il difetto non stava nella mappa: stava nel fatto che **la decisione di dove
## andare non era del bambino**. Tre cose la prendevano al posto suo, e tutte e
## tre erano state scritte per buone ragioni:
##
##   - il **quadro degli obiettivi** ([[ObjectiveBriefing.passo]]) nomina **una**
##     materia — «adesso tocca a latino» — perche' nominarne dodici sarebbe
##     illeggibile. Giusto, e resta;
##   - **PORTAMI** punta la palestra di quella materia e imposta il bersaglio del
##     passo. Nato il 21 agosto per un difetto vero: senza, la scelta si prendeva
##     leggendo le etichette una per una, cioe' non si prendeva. Giusto, e resta;
##   - ogni punto d'interesse portava sopra la sua **riga di registro**
##     (`PRATICA · MATEMATICA`), cioe' diceva a quale voce dell'elenco
##     corrispondeva. Questo no: [[NomiDeiLuoghi]] lo sostituisce con un nome.
##
## Messe insieme, le prime due bastano a giocare tutto il mondo senza mai
## guardarsi intorno: si apre il quadro, si preme un pulsante, si cammina in
## linea retta, si ripete. Il mondo diventa il corridoio fra due schermate.
##
## ## La correzione: non togliere la guida, dare da scegliere
##
## Togliere il quadro o PORTAMI sarebbe rispondere a «non esploro» con «adesso ti
## arrangi», e cancellerebbe un difetto misurato per riaprirne un altro gia'
## misurato. **Il pavimento di accessibilita' resta intatto.**
##
## Quello che manca e' l'alternativa: un modo di sapere che cosa c'e' **da dove
## sei**, senza aprire niente, con abbastanza informazione per scegliere e non
## abbastanza per non doverci andare. Lo sguardo intorno e' questo, e ha tre
## regole che lo tengono onesto:
##
##   **Dice solo quello che si vedrebbe davvero.** Un posto entra nella frase se
##   sta entro la portata dell'occhio (una schermata: 1280x720 unita', quindi
##   settecentoventi di raggio) oppure se ci sei gia' passato. Niente altro. Un
##   elenco che nomina l'altro capo del mondo e' di nuovo il quadro degli
##   obiettivi, solo scritto in corsivo.
##
##   **Non punta e non porta.** Nessun bersaglio del passo, nessuna scia: un nome
##   e una direzione. Camminarci resta il gioco — e' la stessa regola che
##   [[_portami_alla_palestra]] si era gia' data.
##
##   **Offre generi diversi, non la cosa migliore.** Fra i primi due nomi non ce
##   ne sono due dello stesso genere: una prova del mondo, un allenamento, un
##   elemento del paesaggio. Se dicesse due allenamenti sarebbe una classifica, e
##   una classifica e' un ordine travestito. Con due generi in mano la scelta
##   torna a essere una scelta.
##
## **E quando non c'e' niente, tace.** Nessuna frase di riempimento: il silenzio
## e' l'unico invito a camminare che non si puo' fraintendere.

## Il genere di una cosa del mondo. Sono tre e non dodici: e' la distinzione che
## un bambino usa davvero quando decide dove andare — qualcosa che fa avanzare il
## mondo, qualcosa che allena, qualcosa che sta li' e basta.
const PROVA := "prova"
const ALLENAMENTO := "allenamento"
const ELEMENTO := "elemento"

## Quanto lontano arriva l'occhio. La finestra e' 1280x720 unita' di mondo
## ([[project.godot]], camera senza zoom), quindi da dove sta Eli il bordo dello
## schermo e' a seicentoquaranta unita' in orizzontale e trecentosessanta in
## verticale. Settecentoventi e' la mezza diagonale arrotondata: tutto quello che
## rientra in questo raggio o si vede, o si vede appena muovendosi di un passo.
const PORTATA_VISTA := 720.0

## Sotto questa distanza sei gia' arrivato: nominare il posto su cui stai in
## piedi e' il modo piu' rapido di far smettere di leggere le frasi.
const GIA_QUI := 110.0

## Le tre distanze in parole. Un bambino non stima quattrocento unita'; stima
## «due passi», «un pezzo» e «dall'altra parte».
const VICINO := 260.0

## Quante cose nomina lo sguardo. Due, e non tre: la riga vive nella striscia di
## feedback dell'HUD, che il collaudo del 28 agosto ha gia' segnalato come
## sovraccarica e capace di troncare. Due nomi di generi diversi bastano a
## rendere la scelta una scelta.
const QUANTE := 2

## Gli otto venti dello schermo. La mappa e' vista dall'alto e non ruota mai:
## «in alto» e' sempre in alto, ed e' la sola direzione che un bambino puo'
## verificare senza una bussola.
static func direzione(da: Vector2, a: Vector2) -> String:
	var salto := a - da
	if salto.length() < 1.0:
		return "qui"
	var orizzontale := ""
	var verticale := ""
	if absf(salto.x) > absf(salto.y) * 0.45:
		orizzontale = "a destra" if salto.x > 0.0 else "a sinistra"
	if absf(salto.y) > absf(salto.x) * 0.45:
		verticale = "in basso" if salto.y > 0.0 else "in alto"
	if orizzontale.is_empty():
		return verticale
	if verticale.is_empty():
		return orizzontale
	return "%s %s" % [verticale, orizzontale]

## La distanza in parole.
static func distanza_in_parole(quanto: float) -> String:
	if quanto <= VICINO:
		return "qui vicino"
	if quanto <= PORTATA_VISTA:
		return "poco piu' in la'"
	return "lontano"

## Dove sta una cosa, in una mezza frase: distanza e direzione insieme.
static func dove(da: Vector2, a: Vector2) -> String:
	var verso := direzione(da, a)
	var quanto := distanza_in_parole(da.distance_to(a))
	if verso == "qui":
		return quanto
	return "%s %s" % [quanto, verso]

## **Lo sguardo intorno.**
##
## `cose` e' quello che il mondo ha ancora aperto, ognuna cosi':
##   { id, tipo: PROVA|ALLENAMENTO|ELEMENTO, nome, posizione: Vector2,
##     ricordato: bool }
## `ricordato` dice che ci sei gia' passato: e' l'unica cosa che permette di
## nominare un posto fuori dalla portata dell'occhio, ed e' il motivo per cui
## camminare produce qualcosa che resta anche quando non si e' aperto niente.
##
## Restituisce al massimo `quante` letture, ognuna cosi':
##   { id, tipo, nome, quanto, aVista: bool, dove, riga }
static func sguardo(da: Vector2, cose: Array, quante: int = QUANTE) -> Array:
	var candidate: Array = []
	for voce in cose:
		var cosa: Dictionary = voce
		var posizione: Vector2 = cosa.get("posizione", Vector2.INF)
		if posizione == Vector2.INF:
			continue
		var quanto := da.distance_to(posizione)
		if quanto < GIA_QUI:
			continue
		var a_vista := quanto <= PORTATA_VISTA
		if not a_vista and not bool(cosa.get("ricordato", false)):
			continue
		var nome := str(cosa.get("nome", "")).strip_edges()
		if nome.is_empty():
			continue
		candidate.append({
			"id": str(cosa.get("id", "")),
			"tipo": str(cosa.get("tipo", ELEMENTO)),
			"nome": nome,
			"quanto": quanto,
			"aVista": a_vista,
			"nuovo": not bool(cosa.get("ricordato", false)),
			"dove": dove(da, posizione),
		})
	# Prima quello che si vede, poi quello che non hai ancora visto, poi il piu'
	# vicino. L'id chiude l'ordine: due candidati a pari merito devono uscire
	# sempre nello stesso ordine, o la stessa scena direbbe due frasi diverse.
	candidate.sort_custom(func(a, b):
		if bool(a["aVista"]) != bool(b["aVista"]):
			return bool(a["aVista"])
		if bool(a["nuovo"]) != bool(b["nuovo"]):
			return bool(a["nuovo"])
		if not is_equal_approx(float(a["quanto"]), float(b["quanto"])):
			return float(a["quanto"]) < float(b["quanto"])
		return str(a["id"]) < str(b["id"]))

	var letture: Array = []
	var generi: Dictionary = {}
	var presi: Dictionary = {}
	# Primo giro: un solo esemplare per genere. E' la regola che trasforma
	# l'elenco in una scelta.
	for candidato_voce in candidate:
		if letture.size() >= quante:
			break
		var candidato: Dictionary = candidato_voce
		var tipo := str(candidato["tipo"])
		if generi.has(tipo):
			continue
		generi[tipo] = true
		presi[str(candidato["id"])] = true
		letture.append(_scritta(candidato))
	# Secondo giro: se i generi disponibili erano meno delle cose da nominare, si
	# ripesca. Meglio due allenamenti che una frase monca.
	for candidato_voce in candidate:
		if letture.size() >= quante:
			break
		var candidato: Dictionary = candidato_voce
		if presi.has(str(candidato["id"])):
			continue
		presi[str(candidato["id"])] = true
		letture.append(_scritta(candidato))
	return letture

static func _scritta(candidato: Dictionary) -> Dictionary:
	var posto := str(candidato.get("dove", ""))
	return {
		"id": str(candidato["id"]),
		"tipo": str(candidato["tipo"]),
		"nome": str(candidato["nome"]),
		"quanto": float(candidato["quanto"]),
		"aVista": bool(candidato["aVista"]),
		"dove": posto,
		"riga": "%s, %s" % [str(candidato["nome"]), posto] if not posto.is_empty()
			else str(candidato["nome"]),
	}

## **La riga sola che la scena pronuncia.**
##
## Due frasi separate e non una, perche' dicono due cose diverse: quello che si
## vede adesso e quello che ci si ricorda. Impastarle direbbe «si vede» di un
## posto che sta dall'altra parte del mondo, e una guida che esagera di poco e'
## una guida che non si controlla piu'.
##
## Vuota quando non c'e' niente da dire. Il silenzio e' un'informazione: vuol
## dire che da qui non si vede niente, cioe' che conviene camminare.
static func frase(letture: Array) -> String:
	var visti: Array = []
	var ricordati: Array = []
	for lettura_voce in letture:
		var lettura: Dictionary = lettura_voce
		var riga := str(lettura.get("riga", "")).strip_edges()
		if riga.is_empty():
			continue
		if bool(lettura.get("aVista", false)):
			visti.append(riga)
		else:
			ricordati.append(riga)
	var pezzi: Array = []
	if not visti.is_empty():
		pezzi.append("Da qui si vede %s." % _elenco(visti))
	if not ricordati.is_empty():
		pezzi.append("Ti ricordi %s." % _elenco(ricordati))
	return " ".join(PackedStringArray(pezzi))

static func _elenco(righe: Array) -> String:
	if righe.size() == 1:
		return str(righe[0])
	var testa: Array = righe.slice(0, righe.size() - 1)
	return "%s, e %s" % [", ".join(PackedStringArray(testa)), str(righe[righe.size() - 1])]
