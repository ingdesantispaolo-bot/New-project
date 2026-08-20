class_name WorldSky
extends RefCounted

## **Il tempo torna a passare.** (20 agosto 2026)
##
## Il 7 agosto il ciclo giorno/notte era stato congelato, e per una ragione
## giusta: il mondo si scopriva col lavoro fatto, quindi c'erano **due sorgenti
## di buio che si muovevano da sole** e un bambino non poteva sapere se era scuro
## perche' non aveva ancora lavorato o perche' era calata la notte.
##
## Adesso l'avanzamento ha smesso di toccare la luminosità della scena — accende
## oggetti, non alza il sole (vedi [[WorldAwakening]]) — e quella contraddizione
## non esiste piu'. La regola che tiene le due cose separate, e che va difesa:
##
##   **la luce della SCENA dice soltanto che ora è. Gli OGGETTI che si accendono
##   dicono quanto hai lavorato.**
##
## Quello che il congelamento aveva nascosto, e che questo file ripara: il
## profilo di ogni mondo dichiara un'ora d'autore — ventiquattro etichette tutte
## diverse — ma il riconoscimento era per sottostringa e ne capiva quattro. Su
## ventiquattro mondi **diciotto rendevano a mezzogiorno identico**, compresi
## «neon-notturno» (Città Macchina: «notte» non è dentro «notturno»),
## «blu-profondo» (un abisso oceanico), «bioluminescente» (caverne) e
## «lampi-intermittenti» (una tempesta). Qui l'ora è una tabella, non un indovino.

## Quanto dura un giro completo. Dodici minuti: una sessione di studio ne vede
## due o tre, quindi il tempo si **vede** passare senza che il cielo lampeggi.
## I centoventi secondi di prima erano un'eredità del periodo in cui l'orologio
## non camminava e il numero non lo leggeva nessuno.
const DURATA := 720.0

## La notte è più corta e meno profonda del giorno. Non è realismo: è che questo
## è un gioco che si studia, e un bambino che deve leggere un enigma al buio per
## metà della sessione smette di leggerlo. La curva alza la parte bassa senza
## toccare il mezzogiorno.
const CURVA := 0.55

## **Il pavimento di leggibilità.** Sotto questa luminanza il mondo non scende
## mai, torcia o non torcia. Era una preoccupazione già scritta nel codice
## vecchio — «la notte non deve cancellare Eli, i POI e i percorsi sui pannelli
## scolastici a contrasto ridotto» — ma senza un numero che qualcuno potesse
## verificare. Adesso ce l'ha, e `world_sky_audit` lo misura.
const PAVIMENTO := 0.20

## Ora d'autore e **banda** di ciascun mondo.
##
##   ora     dove parte l'orologio: 0 mezzanotte, 0.25 alba, 0.5 mezzogiorno,
##           0.75 tramonto;
##   min/max l'escursione di luce entro cui quel mondo vive.
##
## La banda è ciò che tiene insieme «il tempo passa» e «questo posto è così»:
## nella Tempesta il sole non arriva mai a picco, nei mondi di notte non sorge
## affatto, e in un abisso o in una cripta — dove un cielo non c'è — min e max
## coincidono e l'orologio non cambia niente. Un mondo a ora fissa non è un caso
## speciale nel codice: è un mondo con la banda larga zero.
const ORE := {
	"mattino-dorato": {"ora": 0.36, "min": 0.10, "max": 1.00},
	"luce-diffusa": {"ora": 0.45, "min": 0.14, "max": 1.00},
	"controluce-metallico": {"ora": 0.62, "min": 0.10, "max": 1.00},
	"tramonto-marino": {"ora": 0.76, "min": 0.08, "max": 1.00},
	"industriale-caldo": {"ora": 0.55, "min": 0.12, "max": 1.00},
	"crepuscolo-iridescente": {"ora": 0.80, "min": 0.10, "max": 1.00},
	"meriggio-polveroso": {"ora": 0.50, "min": 0.12, "max": 1.00},
	# I tre mondi di notte: l'orologio cammina — la luna si alza, il cielo cambia
	# — ma l'alba non arriva. Erano gli unici tre che il riconoscimento vecchio
	# azzeccava, e restano notturni per contratto, non per fortuna.
	"notte-elettrica": {"ora": 0.02, "min": 0.00, "max": 0.42},
	"notte-stellata": {"ora": 0.95, "min": 0.00, "max": 0.38},
	"neon-notturno": {"ora": 0.90, "min": 0.00, "max": 0.40},
	"giorno-limpido": {"ora": 0.48, "min": 0.16, "max": 1.00},
	"verde-diffuso": {"ora": 0.42, "min": 0.18, "max": 1.00},
	"sole-archeologico": {"ora": 0.55, "min": 0.12, "max": 1.00},
	"luce-fredda": {"ora": 0.40, "min": 0.14, "max": 1.00},
	"giorno-vivace": {"ora": 0.50, "min": 0.16, "max": 1.00},
	"cielo-variabile": {"ora": 0.45, "min": 0.10, "max": 1.00},
	# La tempesta ha un cielo, quindi il tempo passa: ma il sole non ci arriva
	# mai a picco, o smetterebbe di essere una tempesta.
	"lampi-intermittenti": {"ora": 0.30, "min": 0.06, "max": 0.66},
	# --- I posti senza cielo: min == max, l'orologio non li tocca -------------
	"ambra-calda": {"ora": 0.70, "min": 0.62, "max": 0.62},
	"blu-profondo": {"ora": 0.08, "min": 0.16, "max": 0.16},
	"vetrate-colorate": {"ora": 0.58, "min": 0.54, "max": 0.54},
	"penombra-solenne": {"ora": 0.12, "min": 0.20, "max": 0.20},
	"bioluminescente": {"ora": 0.05, "min": 0.14, "max": 0.14},
	"luce-d-archivio": {"ora": 0.50, "min": 0.58, "max": 0.58},
	"luce-convergente": {"ora": 0.65, "min": 0.72, "max": 0.72},
}

## Il ripiego per un'etichetta che non conosciamo: pieno giorno con l'orologio
## acceso. È lo stesso posto in cui finivano diciotto mondi su ventiquattro, con
## la differenza che adesso ci finisce solo chi ha scritto una parola nuova nel
## profilo — e `world_sky_audit` se ne accorge prima che lo faccia un bambino.
const RIPIEGO := {"ora": 0.50, "min": 0.12, "max": 1.00}

static func scheda(lighting: String) -> Dictionary:
	return Dictionary(ORE.get(lighting.to_lower(), RIPIEGO))

## L'ora da cui parte un mondo, in giri (0..1).
static func ora_iniziale(lighting: String) -> float:
	return float(scheda(lighting).get("ora", 0.5))

## Il tempo passa, qui? Falso per gli interni e gli abissi.
static func cammina(lighting: String) -> bool:
	var s := scheda(lighting)
	return float(s.get("max", 1.0)) > float(s.get("min", 0.0))

## Quanta luce c'è a un dato punto del giro, dentro la banda del mondo.
##
## `giro` è in 0..1 e si ripete: chi chiama non deve preoccuparsi di riportarlo
## dentro l'intervallo.
static func luce_del_cielo(lighting: String, giro: float) -> float:
	var s := scheda(lighting)
	var grezza := (sin(fposmod(giro, 1.0) * TAU - PI / 2.0) + 1.0) * 0.5
	# La curva accorcia la notte: senza, su dodici minuti se ne passerebbero sei
	# al buio, e metà delle prove si leggerebbero peggio dell'altra metà.
	var addolcita: float = pow(grezza, CURVA)
	var minimo := float(s.get("min", 0.0))
	var massimo := float(s.get("max", 1.0))
	return minimo + (massimo - minimo) * addolcita

## Il nome della fase, per l'HUD e per l'audio.
##
## `giro` serve a distinguere alba da tramonto: hanno la stessa luce e non sono
## la stessa cosa. L'audio riceve comunque due soli ambienti — giorno e notte —
## perché sono quelli che esistono in `NativeAudio`.
static func fase(luce: float, giro: float) -> String:
	if luce > 0.72:
		return "giorno"
	if luce > 0.34:
		return "alba" if fposmod(giro, 1.0) < 0.5 else "tramonto"
	return "notte"

## Le fasi che il resto del gioco conosce da sempre: `WorldLife` e l'audio non
## devono imparare parole nuove per una distinzione che è solo di targa.
static func fase_di_sistema(fase_estesa: String) -> String:
	return "alba" if fase_estesa == "tramonto" else fase_estesa

## Alza un colore fin sopra il pavimento di leggibilità, conservandone la tinta.
##
## Si lavora sulla luminanza percepita e non sul singolo canale: scurire un blu
## notturno e scurire un ambra caldo dello stesso 20% dà due leggibilità molto
## diverse, ed è il motivo per cui un valore fisso di «quanto scurire» non basta
## come garanzia.
static func sopra_il_pavimento(colore: Color) -> Color:
	# Il nero puro non e' un caso da saltare: e' il caso che il pavimento esiste
	# per raccogliere. La formula regge — la luminanza e' lineare nei canali,
	# quindi lo scarto verso il bianco si calcola esatto invece che a tentativi.
	var luminanza := luminanza_di(colore)
	if luminanza >= PAVIMENTO:
		return colore
	return colore.lerp(Color.WHITE, clampf((PAVIMENTO - luminanza) / maxf(1.0 - luminanza, 0.001), 0.0, 1.0))

static func luminanza_di(colore: Color) -> float:
	return 0.2126 * colore.r + 0.7152 * colore.g + 0.0722 * colore.b
