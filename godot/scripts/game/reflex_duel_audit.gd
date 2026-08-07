extends SceneTree

## **Il varco è tarato?** (7 agosto 2026)
##
## Un minigioco di riflessi in un gioco che si studia è la cosa più facile da
## sbagliare di tutto il progetto: se è troppo duro esclude proprio i bambini
## che questo gioco vuole tenere dentro, e se è troppo facile il premio non vale
## niente. Questo audit tiene i due bordi.
##
## La regola sopra a tutte, e l'unica che non è una taratura: **il varco può
## chiudere soltanto frammenti**. I frammenti comprano cosmetici. Se un giorno
## qualcosa di necessario finisse dietro una prova di abilità, la promessa del
## gioco sarebbe rotta — e nessun altro controllo se ne accorgerebbe.

const OK := "REFLEX DUEL audit VERDE"
const GRADI := 5      # i gradi di potenza esistenti, 0..4
const TIER_MAX := 8   # i gradi delle sacche, 1..8

var errori: Array = []

func _controlla(condizione: bool, messaggio: String) -> void:
	if not condizione:
		errori.append(messaggio)

func _init() -> void:
	_nessuna_combinazione_impossibile()
	_il_progresso_aiuta_sempre()
	_la_sacca_forte_e_piu_dura()
	_perdere_non_costa_piu_del_girare_alla_larga()
	_il_giudizio_del_colpo()
	if errori.is_empty():
		print(OK)
	else:
		printerr("REFLEX DUEL audit ROSSO")
		for e in errori:
			printerr("  - %s" % e)
	quit(0 if errori.is_empty() else 1)

## **I due bordi.** Nessuna combinazione di gradi deve produrre un duello che
## non si può vincere, né uno che si vince senza guardare.
func _nessuna_combinazione_impossibile() -> void:
	for tier in range(1, TIER_MAX + 1):
		for grado in range(GRADI):
			var quota := ReflexDuel.quota_utile(tier, grado)
			# Sotto il 5% della pista il varco è una fessura: a quel punto non è
			# difficile, è casuale, e un bambino impara solo che il gioco bara.
			_controlla(quota >= 0.05,
				"sacca T%d contro grado %d: il varco copre solo il %.1f%% della pista" %
				[tier, grado, quota * 100.0])
			# Sopra metà pista non si sta più mirando: si tocca e basta.
			_controlla(quota <= 0.5,
				"sacca T%d contro grado %d: il varco copre il %.1f%% della pista, è un regalo" %
				[tier, grado, quota * 100.0])
			var v := ReflexDuel.velocita(tier, grado)
			_controlla(v >= ReflexDuel.VELOCITA_MINIMA and v <= ReflexDuel.VELOCITA_MASSIMA,
				"sacca T%d contro grado %d: velocità %.0f fuori dai limiti leggibili" % [tier, grado, v])
			var regole := ReflexDuel.regole(tier, grado)
			_controlla(int(regole["colpi"]) >= 2 and int(regole["colpi"]) <= 5,
				"sacca T%d: %d colpi richiesti" % [tier, int(regole["colpi"])])
			_controlla(int(regole["errori"]) >= 1,
				"grado %d: nessun errore concesso, il primo tocco decide tutto" % grado)

## **Allenarsi deve servire, sempre.** Contro la stessa sacca, salire di grado
## non può mai peggiorare nessuna delle tre leve. È la promessa che lega il
## duello al resto del gioco: la potenza si guadagna facendo esercizi.
func _il_progresso_aiuta_sempre() -> void:
	for tier in range(1, TIER_MAX + 1):
		for grado in range(1, GRADI):
			_controlla(
				ReflexDuel.semi_varco(tier, grado) >= ReflexDuel.semi_varco(tier, grado - 1),
				"sacca T%d: salendo al grado %d il varco si stringe" % [tier, grado])
			_controlla(
				ReflexDuel.velocita(tier, grado) <= ReflexDuel.velocita(tier, grado - 1),
				"sacca T%d: salendo al grado %d il cursore accelera" % [tier, grado])
			_controlla(
				ReflexDuel.errori_ammessi(grado) >= ReflexDuel.errori_ammessi(grado - 1),
				"grado %d: si concedono meno errori del grado precedente" % grado)
		# E a parità di sacca, il grado massimo deve dare un vantaggio SENTITO:
		# una progressione che non si vede non motiva nessuno.
		_controlla(
			ReflexDuel.quota_utile(tier, GRADI - 1) >= ReflexDuel.quota_utile(tier, 0) * 1.4,
			"sacca T%d: arrivare al grado massimo cambia troppo poco" % tier)

## Una sacca più forte deve essere più dura, altrimenti i gradi delle sacche
## sono decorazione.
func _la_sacca_forte_e_piu_dura() -> void:
	for grado in range(GRADI):
		for tier in range(2, TIER_MAX + 1):
			_controlla(
				ReflexDuel.semi_varco(tier, grado) <= ReflexDuel.semi_varco(tier - 1, grado),
				"grado %d: la sacca T%d ha un varco più largo della T%d" % [grado, tier, tier - 1])
			_controlla(
				ReflexDuel.velocita(tier, grado) >= ReflexDuel.velocita(tier - 1, grado),
				"grado %d: la sacca T%d è più lenta della T%d" % [grado, tier, tier - 1])
		_controlla(ReflexDuel.premio_frammenti(TIER_MAX) > ReflexDuel.premio_frammenti(1),
			"una sacca più forte non paga di più")

## **Provarci non deve costare più che evitare.** Perdere il duello costa quanto
## un morso: se costasse di più, la scelta razionale sarebbe girare alla larga —
## e allora il minigioco non lo giocherebbe nessuno.
func _perdere_non_costa_piu_del_girare_alla_larga() -> void:
	for tier in range(1, TIER_MAX + 1):
		for grado in range(GRADI):
			var duello := ReflexDuel.costo_sconfitta(tier, grado)
			var morso := maxi(0, tier - grado) * WorldEnemy.COSTO_PER_GRADO
			_controlla(duello <= morso,
				"T%d/grado %d: perdere il varco costa %d, più del morso (%d)" %
				[tier, grado, duello, morso])
		# Chi è più forte della sacca non paga niente nemmeno perdendo.
		_controlla(ReflexDuel.costo_sconfitta(tier, GRADI - 1) >= 0,
			"costo di sconfitta negativo per T%d" % tier)
	_controlla(ReflexDuel.costo_sconfitta(1, 4) == 0,
		"una sacca molto più debole di Eli fa comunque pagare la sconfitta")

## Il giudizio del colpo: dentro è dentro, il bordo vale, fuori no.
func _il_giudizio_del_colpo() -> void:
	_controlla(ReflexDuel.colpito(100.0, 100.0, 20.0), "il centro esatto non conta come colpo")
	_controlla(ReflexDuel.colpito(120.0, 100.0, 20.0), "il bordo del varco non conta come colpo")
	_controlla(ReflexDuel.colpito(80.0, 100.0, 20.0), "il bordo sinistro non conta come colpo")
	_controlla(not ReflexDuel.colpito(121.0, 100.0, 20.0), "un colpo fuori varco conta")
	_controlla(not ReflexDuel.colpito(0.0, 100.0, 20.0), "un colpo lontanissimo conta")
