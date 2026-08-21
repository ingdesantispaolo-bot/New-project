extends SceneTree

## **Quando il pacchetto differito arriva, chi ha ripiegato torna indietro.**
## (20 agosto 2026)
##
## Il difetto che questo audit esiste per impedire, segnalato giocando: *«la
## grafica migliorata dei personaggi e dei guardiani è sparita ed è tornata
## quella base»*.
##
## Non era sparita: non era mai arrivata, in quella sessione. I 74 ritratti, le
## 24 tavole dei guardiani, gli 11 Custodi e i 60 file audio non stanno nel
## pacchetto di avvio — viaggiano in `content.pck`, chiesto in sottofondo a gioco
## già interattivo, perché 27 MB prima del primo fotogramma erano 27 MB di attesa
## per roba che non serve a entrare nel mondo.
##
## Il presupposto era giusto e scritto: ogni consumatore **degrada da solo**, e
## finché il pacchetto non arriva il gioco è completo, non rotto. Mancava la
## seconda metà: **quando arriva, qualcuno deve dirlo a chi è già nato.**
## `content_ready` non aveva un solo ascoltatore in tutto il progetto, e l'unica
## spinta esistente era quella dell'audio. Così il ripiego restava fino al cambio
## di mondo — e siccome la copia locale del pacchetto porta il commit nel nome,
## **ogni build nuova ricominciava da capo**: il primo giro di ogni versione si
## giocava con i gusci vettoriali.
##
## **Perché nessun audit lo aveva visto, ed è la parte che vale.** In editor e
## nell'export desktop il pacchetto c'è sempre: `ResourceLoader.exists()`
## risponde di sì, il ripiego non viene mai percorso e ogni verifica sull'arte
## resta verde. Il difetto vive solo dove le due cose sono separate — sul Web — e
## nessuna misura ci arrivava. Qui la separazione si **simula**: si toglie la
## tavola a un personaggio già costruito, come se fosse nato durante il volo, e
## si pretende che la spinta gliela restituisca.

const NPC_ACTOR := preload("res://scripts/game/npc_actor.gd")
const ENEMY := preload("res://scripts/world_enemy.gd")
const PET := preload("res://scripts/pet_companion.gd")
const LOADER := preload("res://scripts/game/content_pack_loader.gd")

const GRUPPO := "arte_differita"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_un_personaggio_ritrova_il_volto()
	_un_guardiano_ritrova_la_tavola()
	_un_custode_ritrova_il_corpo()
	_chi_non_ha_tavola_si_dichiara()
	print("CONTENT PACK REFRESH audit OK - volti, guardiani e Custodi tornano quando il pacchetto arriva")
	quit(0)

## La spinta vera: si costruisce l'autoload come lo costruisce il gioco e gli si
## chiede di annunciare. Non si chiama il metodo del consumatore a mano —
## sarebbe verificare che il metodo esiste, non che qualcuno lo chiama.
func _annuncia() -> void:
	var loader := LOADER.new()
	loader.name = "ContentPackAudit"
	root.add_child(loader)
	loader.call("_announce")
	loader.queue_free()

func _un_personaggio_ritrova_il_volto() -> void:
	var attore := NPC_ACTOR.new() as Area2D
	root.add_child(attore)
	attore.call("configure", "w01-tobia", {"nome": "Tobia", "ruolo": "audit"}, true)
	var arte := attore.get_node_or_null("NpcArt")
	assert(arte != null, "il personaggio non monta il volto illustrato nemmeno con il pacchetto presente")

	# La sessione in cui il pacchetto era ancora in volo: nessuna tavola, e il
	# personaggio si e' dichiarato in attesa.
	arte.free()
	attore.add_to_group(GRUPPO)
	assert(attore.get_node_or_null("NpcArt") == null, "fixture non valida: il volto e' ancora li'")

	_annuncia()
	assert(attore.get_node_or_null("NpcArt") != null,
		"il pacchetto e' arrivato e il personaggio ha tenuto il ripiego")
	assert(not attore.is_in_group(GRUPPO),
		"il personaggio resta in attesa dopo aver rimontato il volto")
	attore.free()

func _un_guardiano_ritrova_la_tavola() -> void:
	var sacca := ENEMY.new() as WorldEnemy
	root.add_child(sacca)
	sacca.setup(null, Vector2.ZERO, 7, "matematica", Color("ff7b72"), 0)
	var visual := sacca.get("visual") as Node2D
	assert(visual != null, "sacca senza corpo")
	var tavola := visual.get_node_or_null("GuardianGeneratedArt")
	assert(tavola != null, "la sacca non monta il guardiano illustrato con il pacchetto presente")

	tavola.free()
	sacca.add_to_group(GRUPPO)
	_annuncia()

	var rimontata := visual.get_node_or_null("GuardianGeneratedArt") as Sprite2D
	assert(rimontata != null, "il pacchetto e' arrivato e la sacca ha tenuto il guscio vettoriale")
	# Stessa regola di `generated_character_art_audit`: niente si disegna sopra
	# l'illustrazione, nemmeno la sagoma di ruolo che le sta sotto.
	assert(rimontata.get_index() == visual.get_child_count() - 1,
		"il guardiano rimontato non e' l'ultima figlia: qualcosa lo copre")
	assert(not sacca.is_in_group(GRUPPO), "la sacca resta in attesa dopo aver rimontato la tavola")
	sacca.free()

func _un_custode_ritrova_il_corpo() -> void:
	var custode := PET.new() as Node2D
	root.add_child(custode)
	custode.call("setup", "pet-cat", Color("f6c85f"), null, "vivace", true)
	var corpo := custode.get("visual") as Node2D
	assert(corpo != null and corpo.get_node_or_null("PetGeneratedArt") != null,
		"il Custode non monta la propria tavola con il pacchetto presente")

	corpo.get_node("PetGeneratedArt").free()
	custode.add_to_group(GRUPPO)
	_annuncia()

	var nuovo := custode.get("visual") as Node2D
	assert(nuovo != null and nuovo.get_node_or_null("PetGeneratedArt") != null,
		"il pacchetto e' arrivato e il Custode ha tenuto il corpo disegnato")
	assert(not custode.is_in_group(GRUPPO), "il Custode resta in attesa dopo aver rifatto il corpo")
	custode.free()

## Chi non ha una tavola **deve dichiararsi**: e' l'unico modo che la spinta ha
## di trovarlo. Un personaggio che ripiega in silenzio e' esattamente il difetto
## di partenza.
func _chi_non_ha_tavola_si_dichiara() -> void:
	var ignoto := NPC_ACTOR.new() as Area2D
	root.add_child(ignoto)
	ignoto.call("configure", "w99-nessuno", {"nome": "Nessuno", "ruolo": "audit"}, true)
	assert(ignoto.get_node_or_null("NpcArt") == null, "fixture non valida: w99-nessuno ha una tavola")
	assert(ignoto.is_in_group(GRUPPO),
		"un personaggio senza tavola non si dichiara in attesa: la spinta non lo troverebbe")
	ignoto.free()
