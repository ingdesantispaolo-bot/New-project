class_name Combo
extends RefCounted

## **La serie.** (13 agosto 2026)
##
## [DESIGN_COMPLETO](../../docs/DESIGN_COMPLETO.md) §6 e §10 la davano per
## esistente da sempre — «moltiplicatore energia (x1.2→x2) visibile; l'errore lo
## azzera» — e la parola `combo` non compariva in **nessuno** script del gioco.
## L'energia valeva dieci punti per risposta giusta, la prima come la ventesima,
## dal mondo 1 al mondo 24.
##
## **Perché serve, e perché proprio qui.** Questo gioco per contratto non
## punisce: l'errore spiega, toglie uno scudo e non cancella niente. È giusto, e
## ha un costo — non esiste nessun momento in cui il bambino abbia qualcosa da
## perdere. Una serie da non spezzare è **l'unica posta in gioco lecita** in un
## gioco così: non toglie niente a chi sbaglia (il moltiplicatore riparte da uno,
## l'energia già guadagnata resta) e dà qualcosa da difendere a chi sta andando
## bene.
##
## **La regola sopra tutte, ed è la decisione vincolante 15.** La serie
## moltiplica **energia**, cioè cosmetici. Non tocca padronanza, copertura,
## ritenzione, gate o esami — mai. Nel momento in cui una risposta veloce facesse
## salire di livello prima di una lenta, questo file starebbe vendendo
## l'apprendimento, ed è esattamente ciò che il progetto ha deciso di non fare.
## Non è una promessa: `record_mission` calcola la padronanza dall'accuratezza e
## riceve l'energia come parametro separato, e `combo_audit` lo verifica passando
## due volte gli stessi esiti con energie diversissime.
##
## **Perché un quarto per volta, e il tetto a due.** Il tetto si raggiunge alla
## **quinta** risposta giusta di fila: è la lunghezza di un esame e della più
## lunga sessione ordinaria. Un tetto che nessuna sessione può toccare sarebbe
## una scala dipinta sul muro; uno che si tocca alla seconda non sarebbe una
## serie. Con quattro gradini, una missione da tre nodi perfetta arriva a ×1,5 e
## un esame perfetto a ×2: il massimo esiste, e va guadagnato tutto.
##
## **Non attraversa le sessioni.** La serie nasce e muore dentro una prova. Una
## serie che si porta dietro il mondo diventa una cosa da proteggere invece che
## da giocare: si smette di provare le materie deboli per non spezzarla, che è il
## contrario di tutto quello che il gioco chiede. E chi la perde per stanchezza a
## quota trenta non riapre il gioco il giorno dopo.

## Quanto cresce il moltiplicatore a ogni risposta giusta consecutiva dopo la
## prima.
const PASSO := 0.25

## Il tetto. Oltre il doppio l'energia di una sessione fortunata comincerebbe a
## contare più della differenza fra le sessioni, e il catalogo della bottega —
## che è tarato sul totale della campagna — si svuoterebbe a metà strada.
const MASSIMO := 2.0

## Sotto due risposte di fila non c'è nessuna serie da mostrare: un ×1 sullo
## schermo è rumore, e un indicatore che c'è sempre non segnala niente.
const SERIE_VISIBILE := 2

## Il moltiplicatore per una serie di `serie` risposte giuste consecutive,
## **inclusa quella che si sta valutando**. Serie 0 o 1 valgono uno: la prima
## risposta giusta non è ancora una serie.
static func moltiplicatore(serie: int) -> float:
	if serie <= 1:
		return 1.0
	return minf(1.0 + float(serie - 1) * PASSO, MASSIMO)

## L'energia di UNA risposta giusta dentro una serie. `base` è
## `rewards.energyPerCorrect` della sessione: la serie lo moltiplica, non lo
## sostituisce, così una taratura delle ricompense resta l'unico posto in cui si
## decide quanto vale una risposta.
static func energia(base: int, serie: int) -> int:
	return maxi(0, roundi(float(base) * moltiplicatore(serie)))

## Quante risposte giuste di fila servono per arrivare al tetto.
static func serie_al_massimo() -> int:
	return 1 + int(ceil((MASSIMO - 1.0) / PASSO))

## Vero se la serie è abbastanza lunga da valere la pena di mostrarla.
static func visibile(serie: int) -> bool:
	return serie >= SERIE_VISIBILE

## L'etichetta da mostrare, con la virgola decimale: «×1,25», «×1,5», «×2».
## Niente zeri finali — «×1,50» si legge come un prezzo.
static func etichetta(serie: int) -> String:
	var valore := moltiplicatore(serie)
	var testo := "%.2f" % valore
	while testo.ends_with("0"):
		testo = testo.left(testo.length() - 1)
	if testo.ends_with("."):
		testo = testo.left(testo.length() - 1)
	return "×%s" % testo.replace(".", ",")
