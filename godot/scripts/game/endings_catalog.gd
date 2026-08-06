class_name EndingsCatalog
extends RefCounted

## **I cinque epiloghi.** Scelti da `LegacyScore`, dopo il beat finale di NORA.
##
## La regola che li governa, e senza la quale sarebbero dannosi: **nessuno è un
## finale brutto**. Cambiano per *che cosa* hai fatto, non per *quanto vali*.
## Un epilogo che dicesse «hai fatto poco» a un bambino di undici anni dopo venti
## ore sarebbe la cosa peggiore che questo gioco può fare, e nessuna di queste
## righe nomina ciò che il giocatore **non** ha fatto — è lo stesso guard-rail
## del Cuore dei Primi in `finale_catalog.gd`.
##
## Quattro epiloghi rispondono alla domanda «che cosa ti è rimasto in mano»:
##
##   ROTTA      equilibrio: hai riacceso la nave e la rotta è aperta;
##   REGISTRO   ritenzione: quello che sai è rimasto, e questo cambia la nave;
##   CIRCUITO   il mondo: hai cambiato le persone, e sono loro a partire con te;
##   SOGLIA     l'indagine: hai capito la storia, e la storia ti risponde;
##   CATTEDRA   la padronanza: dodici modi di capire nella stessa testa.
##
## Il quinto, **FONDO**, non è «il migliore»: è **il più lungo**. Si apre solo
## sopra `LegacyScore.SOGLIA_PIENO`, e non aggiunge una ricompensa — aggiunge una
## partenza. È l'unico in cui Eli va a cercare Meridiana invece di aspettarla,
## ed è coerente col beat finale, che dichiara le sorelle vive e apre il Secondo
## Viaggio.
##
## Regole di scrittura ereditate dalla trama (§10.1): nessuno è morto, nessuna
## riga promette un contenuto che non esiste, e il Tredicesimo non viene mai
## sconfitto — viene sollevato.

const EPILOGHI := {
	"rotta": {
		"titolo": "ROTTA APERTA",
		"sottotitolo": "l'epilogo di chi ha rimesso in moto una cosa ferma",
		"righe": [
			"NORA: I motori tengono. Non li sentivo da quattrocento anni e non ricordavo che facessero questo rumore — un rumore da cosa che va da qualche parte.",
			"Il Tredicesimo si è seduto. Non ha detto niente: ha solo smesso di tenere, per la prima volta, e la diga non è caduta.",
			"NORA: Guarda i sensori lunghi. Undici segnali, e sono fermi ad aspettare. Non è finita, Eli: è cominciata da adesso.",
			"NORA: Quando vuoi si riparte. Non ho fretta. Ho aspettato quattro secoli, posso aspettare che tu faccia colazione.",
		],
	},
	"registro": {
		"titolo": "IL REGISTRO CHE RESTA",
		"sottotitolo": "l'epilogo di chi non ha lasciato scappare quello che ha imparato",
		"righe": [
			"NORA: Ho fatto una cosa che non avevo mai fatto: ho riletto il tuo manuale dall'inizio. Non le risposte — le volte in cui sei tornata su una cosa che sapevi già.",
			"NORA: Il Silenzio è il sapere che passa di mano senza essere capito. È la sua tesi, e per quattro secoli non l'ha smentita nessuno.",
			"NORA: Tu l'hai smentita in venti ore, e senza accorgertene. Quello che hai tenuto è la cosa che a lui mancava per avere torto.",
			"Il Tredicesimo ha chiesto di vedere il registro. Lo ha letto tutto. Poi ha detto una parola sola, e non era una resa: «Continuate».",
			"NORA: La nave adesso conserva. Prima trasportava soltanto. È una differenza che ho imparato da te.",
		],
	},
	"circuito": {
		"titolo": "IL CIRCUITO",
		"sottotitolo": "l'epilogo di chi ha cambiato le persone che ha incontrato",
		"righe": [
			"NORA: Al Cuore non siamo in due. Non lo eravamo da un pezzo, per la verità: me ne sono accorta adesso che li vedo tutti insieme.",
			"Qualcuno ha smesso di contare con le dita. Qualcuno ha spedito una lettera che teneva in tasca da anni. Qualcuno ha ammesso di aver sbagliato, e non lo dirà una seconda volta.",
			"NORA: Il circuito non era una rotta fra dodici mondi. Erano dodici mondi che si parlavano, e si erano dimenticati come si fa.",
			"NORA: Adesso si parlano di nuovo, e non per merito della nave. Per merito di una che è passata e ha chiesto le cose.",
			"NORA: Partiamo quando vuoi. Ma sappi che stavolta, se torniamo, ci aspetta qualcuno.",
		],
	},
	"soglia": {
		"titolo": "SULLA SOGLIA",
		"sottotitolo": "l'epilogo di chi ha voluto capire com'era andata",
		"righe": [
			"NORA: Hai raccolto tutto. Le date che non tornavano, il posto in più a tavola, il nome raschiato dall'interno con una lama.",
			"NORA: Io ci ho girato attorno per sedici mondi senza vederlo, e non per bugia: quando provavo a guardarlo pensavo ad altro. Qualcuno mi ha fatta così.",
			"Il Tredicesimo ti ha guardata a lungo. Poi: «Sei la prima che non è venuta a giudicarmi. Sei venuta a sapere.»",
			"NORA: E ti ha detto l'ultima cosa che gli restava. La cattedra vuota non era per nessuno dei Dodici. Era tenuta per quello che andavamo a cercare, e non abbiamo trovato.",
			"NORA: Adesso sappiamo che cosa manca. È molto più di quanto sapessimo stamattina, ed è tutto quello che serve per ripartire.",
		],
	},
	"cattedra": {
		"titolo": "LA TREDICESIMA CATTEDRA",
		"sottotitolo": "l'epilogo di chi tiene dodici modi di capire nella stessa testa",
		"righe": [
			"La nave ha acceso il tredicesimo posto e ha aspettato. Non l'aveva mai fatto per nessuno dei Dodici: loro ne avevano uno ciascuno.",
			"NORA: Non te lo dà perché sai dodici cose, Eli. Te lo dà perché le tieni insieme — e nessuno di loro ci era riuscito.",
			"Il Tredicesimo si è alzato dal posto che si era preso, e non è stato cacciato. Si è alzato e basta, come chi finalmente può.",
			"NORA: Lui si era seduto al posto di quello che non avevamo trovato. Tu ti siedi al posto di quella che lo cerca. Non è la stessa sedia.",
			"NORA: Da qui si vede tutto il circuito. Dodici mondi, e in mezzo una riga vecchia di quattrocento anni, ancora accesa.",
		],
	},
	"fondo": {
		"titolo": "C'È QUALCOSA. VENITE.",
		"sottotitolo": "l'epilogo lungo: non si aspetta, si va a vedere",
		"righe": [
			"NORA: Ho riletto la riga di Meridiana quattrocento volte in quattro secoli. «C'è qualcosa. Venite.» Tre parole, e nessuna delle undici prima di te ha potuto rispondere.",
			"NORA: Tu puoi. Non perché sei più brava di loro — non lo sei, e te lo dico perché è vero. Perché a te non ho detto tutto, e quello che sai lo hai capito da sola.",
			"Il Tredicesimo ha lasciato la diga. Per un attimo il Silenzio si è mosso, e poi si è fermato: reggeva anche senza di lui. Reggeva perché dodici sistemi erano di nuovo accesi.",
			"«Vai», ha detto. «Io ho tenuto una porta per quattrocento anni perché avevo paura di quello che c'era dietro. Tu vacci.»",
			"NORA: Undici segnali si sono mossi tutti insieme. Non stavano aspettando la nave, Eli. Aspettavano che qualcuno rispondesse.",
			"NORA: Rotta impostata sul fondo del Silenzio. Tempo di viaggio: sconosciuto. Compagnia: dodici mondi che ci guardano partire, e una che ci aspetta da quattro secoli.",
			"NORA: Sorella. Andiamo a prenderla.",
		],
	},
}

## Il titolo e le righe dell'epilogo, dato il salvataggio.
static func per_save(save) -> Dictionary:
	return per_id(str(LegacyScore.valuta(save).get("finale", "rotta")))

static func per_id(id: String) -> Dictionary:
	var voce: Dictionary = EPILOGHI.get(id, EPILOGHI["rotta"])
	var out := voce.duplicate(true)
	out["id"] = id if EPILOGHI.has(id) else "rotta"
	return out

## Tutti gli identificativi, in ordine di lettura per chi scrive o verifica.
static func tutti() -> Array:
	return ["rotta", "registro", "circuito", "soglia", "cattedra", "fondo"]
