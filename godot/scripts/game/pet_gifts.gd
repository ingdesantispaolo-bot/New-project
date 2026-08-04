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

## Una probabilità su quattro a fine sessione. Abbastanza raro da restare una
## sorpresa, abbastanza frequente da costruire una collezione vera nell'arco di
## una campagna.
const CHANCE := 0.25

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

static func label_of(gift_id: String) -> String:
	return str(CATALOG.get(gift_id, "Qualcosa"))

static func total_count() -> int:
	return CATALOG.size()

## Sceglie un regalo. Il generatore è quello del chiamante, così una sessione
## rigiocata dallo stesso seme dà lo stesso regalo e gli audit sono ripetibili.
static func pick(rng: RandomNumberGenerator) -> String:
	var ids := CATALOG.keys()
	ids.sort()
	return str(ids[rng.randi_range(0, ids.size() - 1)])

## Vero se questa sessione porta un regalo.
static func rolls_gift(rng: RandomNumberGenerator) -> bool:
	return rng.randf() < CHANCE
