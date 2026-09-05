extends SceneTree

## **Quanti frammenti offre una campagna, davvero?** (14 agosto 2026)
##
## Serve alla separazione delle valute: dal momento in cui la bottega si paga in
## frammenti e non più in energia, il catalogo (72.600, misurato da
## `economy_probe`) va confrontato con un'offerta di frammenti che **nessuno ha
## mai contato**. Aggiungere un prezzo a un rubinetto non misurato sarebbe
## indovinare, ed è già stato il difetto dei quattro upgrade da 1600 del 6 agosto.
##
## Cosa conta, e con quale fedeltà:
##
## - i **forzieri**: generati da `OutdoorGenerator` con lo stesso seme del gioco e
##   filtrati con gli stessi vincoli di `ChunkManager._profile_filtered_chunk`
##   (dentro i bounds del profilo, fuori dalle zone protette, lontani dal
##   percorso). È la parte esatta: stesso codice, stessi numeri;
## - le **fonti fisse** (incontri, riparazione, camera, varchi): sono tariffe
##   costanti, quindi bastano il conteggio dichiarato e la tariffa.
##
## Quello che la sonda NON sa è quanti forzieri un bambino ne apra davvero: il
## `TASSO_RACCOLTA` è un'assunzione dichiarata, non una misura, ed è il solo
## numero di questo file che si può discutere.
##
## Uso: godot --headless --path godot --script res://scripts/game/fragment_economy_probe.gd

const CHUNK_SIZE := 896
## Quanta parte dei forzieri disponibili viene aperta in una campagna. Non è
## misurato: è l'assunzione centrale della sonda. Metà è già generoso per un
## mondo che si attraversa avendo un obiettivo altrove.
const TASSO_RACCOLTA := 0.5

## Le fonti fisse. Le tariffe vengono da [[FragmentEconomy]] — la sonda non ne
## tiene una copia, altrimenti misurerebbe un gioco diverso da quello giocato.
## I conteggi vengono dalla struttura della campagna (24 mondi).
##
## **Novanta è il numero di incontri che PAGANO, non il traguardo del Lascito.**
## (5 settembre 2026) Prima questa riga si appoggiava a `META_INCONTRI`, che il 5
## settembre è passato da 90 a 560 per tutt'altra ragione — quella meta si
## riempiva al mondo 5 e non distingueva più nessuno. I due numeri non avevano
## niente in comune se non il valore: qui serve una stima di quanti incontri un
## bambino chiude davvero pagati a tariffa, là serve la soglia oltre la quale una
## dimensione del finale si considera piena. Restano novanta, adesso per conto
## proprio.
const INCONTRI_CAMPAGNA := 90
const RIPARAZIONI := 24
const CAMERE := 24
const VARCHI_STIMATI := 48          # due guardiani di forziere per mondo
const TIER_VARCO_MEDIO := 4
const PERICOLI_DEL_MONDO := 24      # uno unico per mondo

func _init() -> void:
	var generator := OutdoorGenerator.new()
	var totale_forzieri := 0
	var totale_frammenti_forzieri := 0
	var righe: Array = []

	for level in range(1, WorldProfileCatalog.MAX_LEVEL + 1):
		var profile := WorldProfileCatalog.profile(level)
		if profile.is_empty():
			continue
		var seed := "outdoor-dev-1::%s" % str(profile.get("id", "world-%02d" % level))
		var composition := WorldCompositionGenerator.generate(seed, profile)
		var ship: Vector2 = profile.get("shipEntrance", {}).get("position", Vector2.ZERO)
		var half_extent := float(profile.get("worldHalfExtent", 2200.0))
		var bounds := Rect2(ship - Vector2.ONE * half_extent, Vector2.ONE * half_extent * 2.0)

		var forzieri := 0
		var frammenti := 0
		var lasciti := 0
		var custodi := 0
		var min_chunk := floori((ship.x - half_extent) / CHUNK_SIZE)
		var max_chunk := floori((ship.x + half_extent) / CHUNK_SIZE)
		for cx in range(min_chunk, max_chunk + 1):
			for cy in range(min_chunk, max_chunk + 1):
				var chunk := generator.generate_chunk(seed, cx, cy)
				for treasure in chunk.get("treasures", []):
					var treasure_id := str(treasure.get("id", ""))
					# La densità del catalogo, prima di tutto il resto: è il
					# filtro che ChunkManager applica per primo.
					if not TreasureCatalog.presente(treasure_id):
						continue
					var position := Vector2(float(treasure.get("x", 0.0)), float(treasure.get("y", 0.0)))
					# Gli stessi tre vincoli di ChunkManager, nello stesso ordine.
					if not bounds.grow(-18.0).has_point(position):
						continue
					if composition.is_protected(position, 56.0):
						continue
					if not composition.is_path_clear(position, 74.0):
						continue
					# E il quarto, di chunk_visual: un forziere sull'acqua si salta.
					if composition.water_weight(position) > 0.08:
						continue
					forzieri += 1
					var tipo := TreasureCatalog.tipo_di(treasure_id)
					if tipo == TreasureCatalog.TIPO_LASCITO:
						lasciti += 1
					elif tipo == TreasureCatalog.TIPO_CUSTODE:
						custodi += 1
					frammenti += TreasureCatalog.frammenti_di(treasure_id, tipo)
		righe.append("mondo %2d · %-28s forzieri %3d (lasciti %2d · custode %2d) · frammenti %5d" % [
			level, str(profile.get("id", "?")), forzieri, lasciti, custodi, frammenti])
		totale_forzieri += forzieri
		totale_frammenti_forzieri += frammenti

	var premio_pericoli := 0
	for level in range(1, PERICOLI_DEL_MONDO + 1):
		var tier := clampi(1 + int(floor(float(level - 1) / 5.0)), 1, 5)
		premio_pericoli += FragmentEconomy.premio_pericolo(tier)
	var fissi := (
		INCONTRI_CAMPAGNA * FragmentEconomy.PREMIO_INCONTRO
		+ RIPARAZIONI * FragmentEconomy.PREMIO_RIPARAZIONE
		+ CAMERE * FragmentEconomy.PREMIO_CAMERA
		+ VARCHI_STIMATI * FragmentEconomy.premio_varco(TIER_VARCO_MEDIO)
		+ premio_pericoli
	)
	var raccolti := int(round(float(totale_frammenti_forzieri) * TASSO_RACCOLTA))
	var offerta := raccolti + fissi
	# Il catalogo si misura dalla fonte autorevole: i Ricordi di conquista lo
	# fanno crescere durante l'autoring e un totale copiato a mano mentirebbe alla
	# prima nuova voce. Gli strumenti restano esclusi perché non sono in vendita.
	var catalogo_cosmetici := 0
	var catalogo_moduli := 0
	var catalogo_ricordi := 0
	for voce_data in RewardCatalog.CATALOG:
		var voce: Dictionary = voce_data
		var slot := str(voce.get("slot", ""))
		if int(voce.get("requiresHazardWorld", 0)) > 0:
			catalogo_ricordi += int(voce.get("cost", 0))
		if slot == "tool":
			continue
		if slot == "module":
			catalogo_moduli += int(voce.get("cost", 0))
		else:
			catalogo_cosmetici += int(voce.get("cost", 0))
	var catalogo := catalogo_cosmetici + catalogo_moduli

	for riga in righe:
		print(riga)
	print("")
	print("forzieri raggiungibili in campagna : %d" % totale_forzieri)
	print("frammenti nei forzieri (offerta)   : %d" % totale_frammenti_forzieri)
	print("  di cui raccolti al %d%%            : %d" % [int(TASSO_RACCOLTA * 100.0), raccolti])
	print("frammenti da fonti fisse           : %d" % fissi)
	print("  di cui Pericoli del Mondo         : %d" % premio_pericoli)
	print("TOTALE campagna                    : %d" % offerta)
	print("catalogo bottega + moduli          : %d" % catalogo)
	print("  di cui Ricordi di conquista       : %d" % catalogo_ricordi)
	print("rapporto catalogo/offerta          : %.1f×" % (float(catalogo) / maxf(float(offerta), 1.0)))
	print("quota del catalogo comprabile      : %d%%" % int(round(float(offerta) / float(catalogo) * 100.0)))
	print("")
	print("Riferimento: prima della separazione la bottega si pagava in energia e")
	print("una campagna ne comprava fra il 59% e il 74% (economy_probe). La quota")
	print("qui sopra deve stare in quella fascia — sopra il 100% il catalogo")
	print("smetterebbe di essere una scelta.")
	quit(0)
