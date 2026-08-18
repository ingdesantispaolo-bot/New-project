class_name EngineerLegendCatalog
extends RefCounted

## La leggenda dell'Ingegnere: DATI e basta, come `NpcCatalog` e
## `ItinerantCatalog`. Nessuna logica di scelta vive qui.
##
## `docs/ABITANTI_E_LUOGHI.md` §2.5. **Non è un ottavo colpo di scena** — non è
## in `mystery_catalog.gd`, non ha semi, non si risolve mai. È un pettegolezzo
## di paese su chi ha stabilito le regole del mondo prima che ci fosse
## qualcuno a ricordarlo: un artigiano senza volto che qualcuno chiama
## «l'Ingegnere» e, quando la storia si scalda, «Paolo».
##
## Una voce per `registro` (§2.2), non una per personaggio: è così che resta
## scalabile a tutti i 76 abitanti senza settantasei leggende diverse. Ogni
## personaggio la dice con il proprio `tic` incollato sopra, non parola per
## parola da qui.
##
## Regole vincolanti, verificate da `engineer_legend_audit.gd`:
## 1. Il nome proprio «Paolo» esce solo nei registri buffo, divertente e
##    caloroso — mai in solenne o misterioso, che dicono sempre «l'Ingegnere».
## 2. Nessuna riga supera le tre schermate (`MAX_SCREENS` di
##    `npc_catalog_audit.gd`).
## 3. Nessuna riga è duplicata, né dentro lo stesso registro né fra registri.
## 4. **Non ancora agganciata al gioco.** Chi la userà (fase successiva a
##    questa, per costruzione — §8 nota del 16 agosto 2026) deve pescarla come
##    riempimento raro, **al massimo 1 estrazione su 10**, mai come sostituto
##    delle battute proprie del personaggio.

const REGISTRI := [
	"curioso", "misterioso", "buffo", "divertente",
	"caloroso", "burbero", "solenne", "sognante",
]

## Registri in cui il nome proprio «Paolo» può comparire. Deliberatamente un
## sottoinsieme stretto: anche dove non è vietato, dev'essere raro.
const REGISTRI_CON_NOME := ["buffo", "divertente", "caloroso"]

## Registri in cui «Paolo» come nome proprio non deve mai comparire: dicono
## sempre e solo «l'Ingegnere».
const REGISTRI_SENZA_NOME := ["solenne", "misterioso"]

const POOLS := {
	"curioso": [
		["Ma chi ha deciso che sette per sette fa quarantanove?", "Qualcuno l'avrà pur deciso. Non è mica caduto già scritto dal cielo."],
		["Ho una lista di sedici domande per l'Ingegnere, ammesso che esista.", "La prima è: perché le tabelline finiscono al dieci e non all'undici?"],
		["Se un giorno lo incontro, gli chiedo una cosa sola.", "Non «come hai fatto». «Ti sei mai sbagliato»."],
	],
	"misterioso": [
		["C'è chi dice che il mondo avesse già le sue regole, ben prima che arrivasse chiunque a insegnarle.", "E che qualcuno le abbia solo trascritte. Non dico che sia vero.", "Dico solo che nessuno l'ha mai smentito."],
		["L'Ingegnere non costruisce le cose.", "Costruisce il perché delle cose. È più difficile da trovare, e più difficile da bruciare."],
		["Se cerchi la sua firma, non guardare gli apparati.", "Guarda dove due regole si toccano senza contraddirsi.", "Lì, dicono, ci ha lavorato più a lungo."],
	],
	"buffo": [
		["L'Ingegnere si chiamerebbe Paolo, dice mio zio.", "O forse mio zio si chiama Paolo e si è confuso.", "Aspetta: io come mi chiamo?"],
		["Dicono che l'Ingegnere abbia inventato pure la fatica.", "Bel lavoro. Proprio quello che serviva."],
		["Un giorno gli scrivo una lettera: «Caro Ingegnere, la leva del pozzo si incastra sempre. Ripensaci.»", "Poi non so dove spedirla.", "Ecco il vero difetto del progetto."],
	],
	"divertente": [
		["Un consiglio, se incontri l'Ingegnere: non chiedergli perché il mio cappotto ha sempre una tasca bucata.", "Quella domanda non gli va giù bene."],
		["Ho barattato una domanda con un vecchio che si faceva chiamare «Paolo, l'Ingegnere» e giurava di aver disegnato lui il tramonto.", "Bella chiacchierata. Tramonto discutibile."],
		["Se passa da queste parti, digli che il ponte numero tre stona di un tono.", "Sa di cosa parlo. Almeno spero."],
	],
	"caloroso": [
		["Mia nonna diceva sempre: le regole buone sono come il pane.", "Non si vedono le mani che l'hanno impastato, ma si sente la pazienza."],
		["Non so se l'Ingegnere esista, tesoro — mia madre lo chiamava Paolo, come se lo conoscesse.", "Se esiste, spero avesse qualcuno che gli scaldava la cena mentre lavorava fino a tardi. A tutti serve."],
		["Il tuo Custode dorme meglio se gli racconto che il mondo ha un ideatore gentile, da qualche parte.", "Non so se sia vero. So che funziona."],
	],
	"burbero": [
		["L'Ingegnere. Mah.", "Se uno ha progettato davvero tutto questo, poteva pensarci meglio alle scale ripide del molo."],
		["Ne ho sentite tante, di storie sul chi-ha-inventato-cosa. Nessuna regge a una seconda domanda.", "— E se te la faccio, la seconda domanda?", "…Mah."],
		["Un Ingegnere che sparisce appena finito il lavoro non è un Ingegnere.", "È uno che se la squaglia. — Anche se il lavoro, quello, regge ancora."],
	],
	"solenne": [
		["Ogni regola porta il segno di chi l'ha scritta, anche quando il nome è caduto.", "Chiamalo l'Ingegnere, chiamalo altrimenti: qualcuno ha deciso che il mondo dovesse reggersi in piedi."],
		["Non tutte le mani che costruiscono restano nella storia.", "Alcune scelgono di restare nella struttura."],
		["Se troverai la sua firma, non sarà su una targa.", "Sarà nel fatto che tutto, qui, continua a funzionare anche quando nessuno guarda."],
	],
	"sognante": [
		["A volte penso che l'Ingegnere sia ancora qui, che disegni una regola nuova ogni notte e la nasconda in qualcosa di piccolo.", "Una farfalla che vola sempre nello stesso modo. Un'eco che torna sempre uguale."],
		["Ho sognato una stanza piena di fili di luce, e qualcuno che ne annodava due dicendo «ecco, ora reggono insieme».", "Al risveglio non ricordavo il viso.", "Ricordavo il nodo."],
		["Se l'Ingegnere esiste, spero che ogni tanto smetta di lavorare e guardi il mondo funzionare.", "Se l'ho fatto bene anch'io, una volta, vorrei che lo facesse anche lui."],
	],
}

## Copia delle righe per un registro; array vuoto se il registro non esiste.
static func for_registro(registro: String) -> Array:
	return Array(POOLS.get(registro, [])).duplicate(true)

## Tutte le righe di tutti i registri, per gli audit.
static func all_lines() -> Array:
	var out: Array = []
	for registro in POOLS.keys():
		out.append_array(POOLS[registro])
	return out
