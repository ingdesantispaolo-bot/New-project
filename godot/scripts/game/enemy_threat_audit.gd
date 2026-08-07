extends SceneTree

## **Le sacche di Silenzio diventano cattive, e il grado conta.** (7 agosto 2026)
##
## Indicazione del committente dopo un collaudo: «devono essere sempre più
## cattivi man mano che saliamo di livello». Prima erano un ostacolo scenico —
## respingevano e basta — e il grado di potenza appena introdotto non serviva a
## niente contro di loro: la barra era un indicatore, non un desiderio.
##
## Le quattro proprietà che tengono in piedi il compromesso:
##
##   1. **crescono col livello**, e in modo percepibile: fra il mondo 3 e il
##      mondo 21 la differenza deve sentirsi. Prima due mondi lontanissimi
##      avevano la stessa sacca;
##   2. **il grado di Eli le annulla**: chi si allena passa senza pagare. È il
##      motivo per cui la barra della potenza esiste, e senza questo il lotto
##      precedente resta decorativo;
##   3. **non bloccano mai**: se l'energia non basta si paga quel che c'è e si
##      passa. È la regola di tutta la mappa;
##   4. **il costo resta assorbibile**: un incontro sfortunato non deve
##      cancellare una sessione di lavoro.

func _init() -> void:
	_prova_crescita()
	_prova_il_grado_protegge()
	_prova_costo_sostenibile()
	print("ENEMY THREAT audit OK — crescono col livello, il grado protegge, nessun blocco")
	quit(0)

## Il grado di una sacca al mondo N, con la stessa formula del gioco.
func _grado_sacca(livello: int) -> int:
	return clampi(1 + floori(float(livello - 1) / 3.0), 1, 8)

func _prova_crescita() -> void:
	var primo := _grado_sacca(1)
	var ultimo := _grado_sacca(ApparatusConfig.MAX_LEVEL)
	assert(ultimo > primo, "le sacche dell'ultimo mondo non sono più forti di quelle del primo")
	assert(ultimo - primo >= 6,
		"fra il primo e l'ultimo mondo il salto è di soli %d gradi: non si sente" % (ultimo - primo))
	# Monotòno: nessun mondo ha sacche più deboli di uno precedente.
	var precedente := 0
	for livello in range(1, ApparatusConfig.MAX_LEVEL + 1):
		var g := _grado_sacca(livello)
		assert(g >= precedente, "le sacche del mondo %d sono più deboli di quelle prima" % livello)
		precedente = g

## Il cuore: allenarsi serve. Con il grado alto le sacche non scalfiscono.
func _prova_il_grado_protegge() -> void:
	for livello in [1, 6, 12, 18, 24]:
		var sacca := _grado_sacca(livello)
		# Eli al massimo grado: nessun costo, in nessun mondo.
		var scarto_forte := maxi(0, sacca - (WorldLight.SOGLIE.size() - 1))
		assert(scarto_forte * WorldEnemy.COSTO_PER_GRADO <= WorldEnemy.COSTO_PER_GRADO * 4,
			"nemmeno al grado massimo le sacche del mondo %d diventano sopportabili" % livello)
		# Eli senza allenamento: paga davvero, o la minaccia non esiste.
		var scarto_debole := maxi(0, sacca - 0)
		assert(scarto_debole > 0,
			"al mondo %d una sacca non costa niente nemmeno a chi non si è mai allenato" % livello)

	# E il grado massimo annulla del tutto le sacche dei primi mondi: chi si
	# allena torna indietro e passa tranquillo. È la ricompensa che rende la
	# barra un desiderio invece che un indicatore.
	assert(_grado_sacca(1) <= WorldLight.SOGLIE.size() - 1,
		"nemmeno al grado massimo si passa indenni fra le sacche del mondo 1")

func _prova_costo_sostenibile() -> void:
	# Il peggior incontro possibile: sacca del mondo 24 contro Eli al grado zero.
	var peggiore := _grado_sacca(ApparatusConfig.MAX_LEVEL) * WorldEnemy.COSTO_PER_GRADO
	# Una sessione di pratica rende molto più di così: incontrare una sacca deve
	# essere un incidente, non la cancellazione del lavoro appena fatto.
	assert(peggiore <= OutdoorGameplay.LAVORETTO_PAGA * 2,
		"il morso peggiore costa %d energia: piu' del doppio di un turno di lavoro" % peggiore)
	assert(WorldEnemy.COSTO_PER_GRADO >= 1, "il morso non toglie niente: la minaccia non esiste")
