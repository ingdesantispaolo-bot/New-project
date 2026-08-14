class_name PulseCharge
extends RefCounted

## **L'impulso si guadagna.** (14 agosto 2026)
##
## Il 7 agosto le sacche di Silenzio sono diventate un pericolo vero: il morso
## costa `(grado della sacca − grado di Eli) × 2` energie, e tutto
## [[world_enemy]] è scritto attorno a una promessa — *chi si allena passa in
## mezzo alle sacche senza pagare; chi non si allena le paga tutte*.
##
## **Quella promessa non è mai stata mantenuta**, e non per un difetto di
## bilanciamento. L'impulso stabilizzante non costava niente e si ricaricava in
## **1,25 secondi**: bastava premere il pulsante e passare. Il morso non lo pagava
## nessuno, il grado di potenza non serviva a niente contro le sacche, e la barra
## sullo schermo misurava una forza che non veniva mai messa alla prova. Un
## bottone gratuito con un cooldown di un secondo aveva annullato un lotto intero.
##
## **La riparazione è cambiare specie alla risorsa, non tararla.** Un cooldown
## rigenera da sé e quindi non è un costo: è un'attesa. Le cariche invece si
## **guadagnano**, e si guadagnano nell'unico modo che questo gioco riconosce —
## superando prove. Da qui la catena che il lotto voleva: *studi → hai l'impulso →
## passi*. Chi non studia gira attorno alle sacche, ed è una scelta invece che un
## incidente.
##
## **Non blocca mai, e questa riga vale più delle altre.** A zero cariche si passa
## lo stesso pagando il morso, e il morso a sua volta prende quel che c'è quando
## l'energia non basta. È la regola di tutta la mappa: niente che sta qui può
## fermare la progressione. Se un giorno qualcosa di necessario finisse dietro una
## carica d'impulso, questa riga è la prova che è un errore.
##
## **Perché si parte da zero.** Un nuovo salvataggio non ha cariche: le prime due
## prove ne danno una. Regalarne una all'avvio sembrerebbe gentile e insegnerebbe
## la cosa sbagliata — che l'impulso c'è. Le celle vuote accanto alla barra di
## potenza dicono, senza una riga di testo, che quella cosa **si riempie
## giocando**. E non esiste il vicolo cieco, perché il morso non ferma nessuno.

## Quante prove superate danno una carica. Due: una per ogni carica sarebbe un
## rubinetto aperto (una sessione ne dà tre), quattro renderebbero l'impulso una
## cosa che si vede due volte per mondo.
const PROVE_PER_CARICA := 2

## Il tetto. Tre bastano per attraversare una zona sorvegliata; con più cariche in
## tasca la scelta *passo o giro attorno* smetterebbe di esistere, ed è quella la
## cosa che si sta costruendo.
const MASSIMO := 3

const _CHIAVE := "pulse"

static func _stato(save) -> Dictionary:
	var stato: Dictionary = save.data.get(_CHIAVE, {})
	if stato.is_empty():
		stato = {"charges": 0, "progress": 0}
		save.data[_CHIAVE] = stato
	return stato

static func cariche(save) -> int:
	return clampi(int(_stato(save).get("charges", 0)), 0, MASSIMO)

## Quante prove mancano alla prossima carica. A serbatoio pieno vale zero: non si
## sta accumulando niente, ed è esattamente ciò che il tetto significa.
static func verso_la_prossima(save) -> int:
	if cariche(save) >= MASSIMO:
		return 0
	return maxi(0, PROVE_PER_CARICA - int(_stato(save).get("progress", 0)))

## Una prova superata. Vero se questa prova ha prodotto una carica — il momento
## che vale la pena dire al giocatore.
##
## **A serbatoio pieno non si accumula.** Se il progresso continuasse a salire, chi
## gioca a lungo con tre cariche in tasca si ritroverebbe una riserva invisibile
## che si scarica tutta insieme appena ne spende una: il tetto sarebbe una
## finzione, e la scelta *passo o giro attorno* tornerebbe a non esistere.
static func accredita(save) -> bool:
	var stato := _stato(save)
	if cariche(save) >= MASSIMO:
		stato["progress"] = 0
		save.data[_CHIAVE] = stato
		return false
	var progresso := int(stato.get("progress", 0)) + 1
	if progresso < PROVE_PER_CARICA:
		stato["progress"] = progresso
		save.data[_CHIAVE] = stato
		return false
	stato["progress"] = 0
	stato["charges"] = mini(int(stato.get("charges", 0)) + 1, MASSIMO)
	save.data[_CHIAVE] = stato
	return true

## Spende una carica. Falso se non ce n'erano: chi chiama non deve fare niente
## di diverso, perché a impulso scarico si passa lo stesso pagando il morso.
static func consuma(save) -> bool:
	var stato := _stato(save)
	var quante := cariche(save)
	if quante <= 0:
		return false
	stato["charges"] = quante - 1
	save.data[_CHIAVE] = stato
	return true
