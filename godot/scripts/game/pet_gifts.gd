class_name PetGifts
extends RefCounted

## Il regalo inutile. Vedi docs/PET_CUSTODE.md §3.3.
##
## Ogni tanto il Custode porta qualcosa. È un sasso. Una foglia. Una vite storta.
## Un altro sasso. Non serve a niente, non si può chiedere, non scade e non si
## perde — ed è esattamente il punto: è l'unica cosa nel gioco che arriva senza
## essere stata guadagnata.
##
## A cosa serve davvero: la schermata del Custode li tiene in fila con il mondo
## in cui sono stati raccolti. Dopo ventiquattro mondi quella lista è il diario
## del viaggio, e nessuno ha dovuto scriverlo.
##
## GUARDRAIL: nessun regalo dà un vantaggio. Non è valuta, non si spende, non
## sblocca niente. Il momento in cui un regalo diventasse utile, il bambino
## comincerebbe a chiedersi come ottenerne di più — e un compagno che si farma
## non è più un compagno.
##
## ---
##
## # Il diario diceva soltanto il numero del mondo (2 settembre 2026)
##
## **Il difetto misurato**: i regali erano sedici, **identici in tutti e
## ventiquattro i mondi**. `pick()` non sapeva nemmeno dove si trovasse. La riga
## qui sopra prometteva «dopo ventiquattro mondi quella lista è il diario del
## viaggio», e il diario diceva *«Un sasso — mondo 7»*: del mondo 7 non c'era
## niente, solo il suo numero, scritto da `pet_screen` e non dal regalo.
##
## Un diario in cui la voce non dice dove sei stata non è un diario: è un
## registro con una data. E siccome il Custode è il personaggio che accompagna
## tutto il gioco, era anche l'unico sistema affettivo che **non sapeva niente
## dei ventiquattro luoghi** che attraversa.
##
## **La correzione tiene i sedici e ne aggiunge ventiquattro**, uno per mondo.
## Non li sostituisce: il sasso e il bottone sono la battuta, e sono il motivo
## per cui un regalo non vale niente. Ma un regalo su due viene adesso **da lì**
## — una scaglia dell'obelisco, una spora della serra, una scheggia di quarzo
## della faglia — e la lista, riletta a fine campagna, racconta la strada.
##
## Il guard-rail non si muove di un millimetro: i ventiquattro sono inutili
## quanto i sedici. Nessuno vale più di un altro, nessuno si può chiedere,
## nessuno serve a niente. Cambia soltanto che dicono dove eravate.

## Una probabilità su quattro a fine sessione. Abbastanza raro da restare una
## sorpresa, abbastanza frequente da costruire una collezione vera nell'arco di
## una campagna.
const CHANCE := 0.25

## Quanto spesso il regalo viene dal posto invece che dal fondo delle tasche.
## Uno su due: sotto, il mondo non si sentirebbe; sopra, i sassi sparirebbero e
## con loro la battuta che regge tutta la meccanica.
const QUOTA_DEL_LUOGO := 0.5

## I sedici di sempre: roba che il Custode ha trovato per terra, ovunque.
const CATALOG := {
	"sasso": "Un sasso",
	"sasso-liscio": "Un sasso, ma liscio",
	"sasso-altro": "Un altro sasso",
	"foglia": "Una foglia",
	"foglia-secca": "Una foglia già secca",
	"vite": "Una vite storta",
	"bottone": "Un bottone",
	"tappo": "Un tappo",
	"filo": "Un pezzo di filo di rame",
	"guscio": "Un guscio vuoto",
	"pigna": "Una pigna",
	"biglia": "Una biglia opaca",
	"molla": "Una molla che non molleggia più",
	"carta": "Un pezzo di carta piegato con cura",
	"chiave": "Una chiave che non apre niente",
	"stecco": "Uno stecco perfettamente normale",
}

## Uno per mondo: la cosa che si può raccogliere **solo lì**, e che non serve a
## niente lì come altrove. Il nome dice il posto senza spiegarlo — chi ha
## attraversato la Necropoli riconosce la scaglia di radice, chi non c'è ancora
## arrivato non ha niente da capire.
const CATALOG_DEI_MONDI := {
	1: {"id": "mondo-01-scaglia-obelisco", "label": "Una scaglia dell'obelisco, con mezza tacca sopra"},
	2: {"id": "mondo-02-ceralacca", "label": "Un pezzetto di ceralacca con l'impronta di un dito"},
	3: {"id": "mondo-03-ingranaggio", "label": "Un ingranaggio a cui manca un dente, il terzo"},
	4: {"id": "mondo-04-lente-boa", "label": "Un vetrino verde di una boa, spaiato"},
	5: {"id": "mondo-05-rondella", "label": "Una rondella consumata da una parte sola"},
	6: {"id": "mondo-06-corda", "label": "Un capo di corda ancora accordato, dice lui"},
	7: {"id": "mondo-07-tessera", "label": "Una tessera di mosaico senza il suo mosaico"},
	8: {"id": "mondo-08-morsetto", "label": "Un morsetto che non stringe più niente"},
	9: {"id": "mondo-09-conchiglia-rotta", "label": "Mezza conchiglia con una spirale incisa dentro"},
	10: {"id": "mondo-10-spora", "label": "Una spora secca che al buio fa ancora un po' di luce"},
	11: {"id": "mondo-11-cocci", "label": "Un coccio con sopra due numeri che non concordano"},
	12: {"id": "mondo-12-filo-isa", "label": "Un gomitolo di filo, avanzato da qualcuno che segnava i bivi"},
	13: {"id": "mondo-13-sabbia", "label": "Sabbia di duna, in un tappo. Pesa pochissimo"},
	14: {"id": "mondo-14-segnalibro", "label": "Un segnalibro fermo alla stessa pagina da secoli"},
	15: {"id": "mondo-15-bullone", "label": "Un bullone della Città Macchina, ancora oliato"},
	16: {"id": "mondo-16-gettone", "label": "Un gettone di mercato che vale in una lingua sola"},
	17: {"id": "mondo-17-vetro-marino", "label": "Un vetro smerigliato dal mare, senza spigoli"},
	18: {"id": "mondo-18-scheggia-canna", "label": "Una scheggia di canna d'organo che fischia se ci soffi"},
	19: {"id": "mondo-19-radice", "label": "Un pezzetto di radice con dentro una lettera"},
	20: {"id": "mondo-20-vetro-fulminato", "label": "Un grumo di sabbia fusa da un fulmine"},
	21: {"id": "mondo-21-quarzo", "label": "Una scheggia di quarzo della faglia, con due strati diversi"},
	22: {"id": "mondo-22-membrana", "label": "Una membrana secca, leggera come niente"},
	23: {"id": "mondo-23-timbro", "label": "Un timbro dei copisti, con l'inchiostro finito"},
	24: {"id": "mondo-24-scheggia-prisma", "label": "Una scheggia di prisma che non scompone più niente"},
}

## L'etichetta di un regalo, dai due cataloghi.
static func label_of(gift_id: String) -> String:
	if CATALOG.has(gift_id):
		return str(CATALOG[gift_id])
	for level in CATALOG_DEI_MONDI.keys():
		var voce: Dictionary = CATALOG_DEI_MONDI[level]
		if str(voce.get("id", "")) == gift_id:
			return str(voce.get("label", "Qualcosa"))
	return "Qualcosa"

## Vero se questo identificativo è un regalo, da uno qualsiasi dei due cataloghi.
## Lo usa `PetState.register_gift` per non accettare roba inventata: senza,
## bastava aggiungere i ventiquattro del luogo perché il Custode li portasse e il
## salvataggio li rifiutasse in silenzio.
static func esiste(gift_id: String) -> bool:
	return CATALOG.has(gift_id) or label_of(gift_id) != "Qualcosa"

## Quanti regali diversi esistono. Il Custode può portarne uno di questi, mai
## due volte lo stesso nella stessa sessione — la varietà la misura
## `pet_advanced_audit`, che vuole una collezione che non si ripeta subito.
static func total_count() -> int:
	return CATALOG.size() + CATALOG_DEI_MONDI.size()

## Il regalo del mondo, o stringa vuota fuori dai ventiquattro.
static func regalo_del_mondo(world: int) -> String:
	var voce: Dictionary = CATALOG_DEI_MONDI.get(world, {})
	return str(voce.get("id", ""))

## Sceglie un regalo. Il generatore è quello del chiamante, così una sessione
## rigiocata dallo stesso seme dà lo stesso regalo e gli audit sono ripetibili.
##
## `world` è opzionale: senza, si pesca fra i sedici di sempre — è quello che
## fanno i chiamanti che non sanno dove si trovano, e continua a funzionare.
static func pick(rng: RandomNumberGenerator, world: int = 0) -> String:
	var del_luogo := regalo_del_mondo(world)
	if del_luogo != "" and rng.randf() < QUOTA_DEL_LUOGO:
		return del_luogo
	var ids := CATALOG.keys()
	ids.sort()
	return str(ids[rng.randi_range(0, ids.size() - 1)])

## Vero se questa sessione porta un regalo.
static func rolls_gift(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < CHANCE
