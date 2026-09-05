class_name NoraBottegaVoce
extends RefCounted

## **La bottega parla, e dice quello che hai fatto.** (5 settembre 2026)
##
## Richiesta del committente: dare più valore e più interattività a bottega e
## mondi. Fino a oggi la bottega diceva sempre la stessa frase — *«Trasforma i
## frammenti raccolti nei mondi in identità, alleati e nuovi spazi da vivere»* —
## qualunque cosa il bambino avesse fatto. Un negozio che non nota niente non è
## un posto, è un listino.
##
## **Non è un mercante nuovo.** Inventare un personaggio che tratta i prezzi
## sarebbe un'aggiunta vera, con la sua UI e il suo contratto — una decisione di
## prodotto che spetta al committente, non a una riga di NORA. Quello che si può
## fare oggi, senza aggiungere niente, è far parlare **chi già parla ovunque nel
## gioco**: NORA guarda quello che è già scritto nel salvataggio — forzieri
## aperti, pattuglie sciolte, mondi visitati — e lo dice. La bottega diventa
## interattiva restando esattamente quello che è: nessuna nuova meccanica,
## nessun nuovo dato, nessun rischio.
##
## **La voce.** Concreta prima di astratta, un'idea per riga, mai un elogio
## generico: NORA nota un fatto preciso, non dice «bravo». È la stessa regola
## delle sue spiegazioni — vero, mai gonfiato, alla portata di chi ha undici
## anni — spostata dalla didattica all'accoglienza.
##
## **Come si legge questo file.** Le soglie sono ordinate dalla più esigente alla
## più permissiva e si prende la prima che è vera: un bambino che ha aperto
## quaranta forzieri non deve sentirsi dire la frase di chi è appena partito.

## Quanti forzieri-lascito sono stati aperti in tutta la campagna: quelli che
## portano una riga di Eli, non le cianfrusaglie di passaggio. Sono al massimo
## uno ogni due chunk per mondo — vedi [[TreasureCatalog]] — quindi il numero
## resta piccolo anche per chi esplora parecchio, ed è per questo che le soglie
## sotto partono da uno solo.
static func _forzieri_lascito(save) -> int:
	var totale := 0
	for progresso in Dictionary(save.data.get("worldProgress", {})).values():
		totale += Array(Dictionary(progresso).get("collectedTreasureIds", [])).size()
	return totale

static func _pattuglie_sciolte(save) -> int:
	var totale := 0
	for progresso in Dictionary(save.data.get("worldProgress", {})).values():
		totale += Array(Dictionary(progresso).get("defeatedEnemyIds", [])).size()
	return totale

static func _mondi_aperti(save) -> int:
	return Array(Dictionary(save.data.get("worlds", {})).get("unlocked", [])).size()

## La riga che NORA dice aprendo la bottega. Pura: legge il salvataggio e non
## scrive niente, così si può richiamare a ogni apertura senza effetti.
static func riga(save) -> String:
	if save == null:
		return "Trasforma i frammenti raccolti nei mondi in identità, alleati e nuovi spazi da vivere."

	var forzieri := _forzieri_lascito(save)
	var pattuglie := _pattuglie_sciolte(save)
	var mondi := _mondi_aperti(save)

	# **Le pattuglie sciolte vengono prima di tutto.** È il fatto più raro e più
	# faticoso da ottenere — vincere costa un duello, non un tocco — quindi se
	# c'è, è la cosa più interessante da notare.
	if pattuglie >= 20:
		return "Venti sacche non ti danno più fastidio da nessuna parte. La nave lo sente: meno rumore sui sensori, ogni notte."
	if pattuglie >= 8:
		return "Otto guardiane in meno a girare per i mondi. Non tornano: quello che proteggevano è aperto per sempre."
	if pattuglie >= 1:
		return "Ho segnato una sacca che non c'è più. Quello che custodiva adesso è tuo, e resta tuo."

	if forzieri >= 40:
		return "Quaranta forzieri aperti, e in ognuno c'era qualcuno. Comincio a conoscere questa nave meglio dai suoi resti che dai suoi corridoi."
	if forzieri >= 15:
		return "Quindici volte ti sei fermata su qualcosa che qualcun altro aveva lasciato. Non è poco: la maggior parte cammina dritta."
	if forzieri >= 5:
		return "Cinque cose trovate, cinque persone di cui adesso sai un pezzetto senza averle mai incontrate. Continua a guardare per terra."
	if forzieri >= 1:
		return "Hai aperto qualcosa che non dovevi aprire per forza. Quello, più di ogni altra cosa, dice che genere di esploratrice sei."

	if mondi >= 12:
		return "Dodici mondi aperti e ancora nessun forziere fermato. Ci sono cose lasciate là fuori che aspettano solo che qualcuno rallenti."

	return "Trasforma i frammenti raccolti nei mondi in identità, alleati e nuovi spazi da vivere."
