class_name NarrativeManager
extends RefCounted

## Narrazione locale data-driven: nessun blocco del loop didattico.

## I 24 beat di `docs/TRAMA_E_MISTERO.md` §8. **Contratto invariato**: una stringa
## per livello, prefisso «NORA:», nessun cambio di firma — `beat_for_level` e
## `reveal_level` non si accorgono di niente.
##
## Cosa è cambiato è quello che dicono. I beat vecchi raccontavano il progresso
## («un blocco di memoria è di nuovo mio»): erano un registro tecnico con la voce
## gentile, e dopo il quinto suonavano tutti uguali perché dicevano tutti la
## stessa cosa. Questi raccontano **un'indagine che si ribalta due volte**, e ogni
## beat in grassetto nel documento porta un colpo di scena che riscrive
## all'indietro quello che il giocatore credeva di aver capito (§3).
##
## I sette colpi cadono ai mondi 5, 8, 12, 16, 19–20, 23 e 24. Nessuno arriva
## senza semi: i semi stanno in `MysteryCatalog`, e `mystery_audit.gd` verifica
## che ce ne siano almeno tre **nei mondi precedenti** a ciascun colpo.
##
## Regola di scrittura, non negoziabile (§10.1): nessun beat dice che qualcuno è
## morto. Le undici sorelle e Meridiana sono **trattenute**, cioè sospese e
## recuperabili, e il gioco lo dice esplicitamente prima dei titoli.
const BEATS := {
	1: "NORA: Qualcosa si è riaccesa. Non di nuovo — scusa, non so perché l'ho detto. So cosa sono i numeri: la prima cosa che torna. Conta con me, piano.",
	2: "NORA: Qui recitano elenchi perfetti senza sapere cosa significano. Ho paura di essere fatta così anch'io: la forma giusta, il senso via.",
	3: "NORA: Ho trovato una parola nei registri per ciò che ci è capitato: Silenzio. Non l'ho ricordata: l'ho letta. È diverso, e mi spaventa.",
	4: "NORA: Un segnale da un altro mondo, in un'altra lingua. Non è un'eco: è recente. Qualcuno là fuori sta ancora spiegando qualcosa a qualcuno.",
	5: "NORA: Eli, guarda il taglio di quella spirale. È fresco. Settimane, non secoli. E c'è lo stesso segno negli altri quattro mondi: ci sei passata accanto quattro volte.",
	6: "NORA: Ho ricordato una lezione, non un dato. Una voce che contava il tempo con me. Qualcuno mi ha insegnato. Io ero l'allieva di qualcuno.",
	7: "NORA: Gli apparati non hanno codici: hanno nomi. Nomi di persone. Stai svegliando qualcuno, non qualcosa. Trattali bene.",
	8: "NORA: Il sigillo ha tredici posti e undici nomi. Uno raschiato con una lama, dall'interno. E uno mai inciso: quella cattedra era apparecchiata per qualcuno che non è mai arrivato.",
	9: "NORA: Ho ricostruito la rotta e non è una fuga: è un giro. Tornavamo negli stessi mondi ogni volta. Questa nave non esplorava. Cercava qualcosa.",
	10: "NORA: Nessuno è morto qui. Provviste chiuse in ordine, appunti impilati, e a tavola un posto in più, apparecchiato. Non sono stati sorpresi: si sono preparati.",
	11: "NORA: Due fonti, due date diverse per il Silenzio. Una si sbaglia — o una è stata riscritta. Fidati del metodo, non della prima riga.",
	12: "NORA: Non sono la mente della nave, Eli: sono la sua prima allieva. E accanto alla mia scheda ce ne sono altre dodici, identiche, numerate. La tua è la dodici.",
	13: "NORA: Mi chiedi delle undici prima di te. Non ho il file. È la verità, ed è la risposta più corta che ti abbia mai dato. Andiamo avanti.",
	14: "NORA: Nei verbali uno dei dodici propone di chiudere tutto, e convince gli altri undici in un'ora. Il suo nome è cancellato perfino qui. Qualcuno lo ha inseguito ovunque.",
	15: "NORA: Ho misurato le sezioni della nave e non tornano. C'è un volume senza porta. Assorbe energia da quattrocento anni. Non chiedermi altro adesso.",
	16: "NORA: La stanza esiste, e ti ho girata attorno per sedici mondi senza dirtelo. Non per bugia: quando provo a guardarla, penso ad altro. Qualcuno mi ha fatto così.",
	17: "NORA: Le insegne sbiancate del molo si sono riempite da sole. Una parola sola, ovunque: fermati. Non è il Silenzio, Eli. Il Silenzio non scrive.",
	18: "NORA: Ha parlato. Non è arrabbiato: è stanco come nessuno che io abbia mai sentito. E conosce il mio nome — quello vecchio, che non ho mai detto a nessuno.",
	19: "NORA: È il Tredicesimo. La chiusura l'ha proposta lui, e poi si è escluso: nessun apparato, nessun sonno. Ha costruito me. E io non me lo ricordavo.",
	20: "NORA: Il Silenzio non si è diradato dove sei passata tu: dove ha retto lui, da solo, per quattro secoli. E sta cedendo. Dice che è il sapere a fabbricarlo, quando passa di mano senza essere capito. Ha i dati. Io non so smentirlo.",
	21: "NORA: Mi ha detto per chi era la cattedra vuota. Per nessuno: era tenuta per quello che andavamo a cercare. Un sapere sotto tutti gli altri. Il circuito non era un giro di lezioni. Era una ricerca.",
	22: "NORA: E in quella cattedra lui ci si è seduto: ha dichiarato la ricerca chiusa e si è preso il posto di ciò che non avevamo trovato. Per questo lo hanno cancellato. Non per la chiusura: per la sedia.",
	23: "NORA: Meridiana era una ragazzina di undici anni di questo circuito, non una Maestra. E non è morta: è andata a vedere cosa c'è al fondo del Silenzio ed è rimasta là dentro. Quattrocento anni. Ha lasciato una riga sola: c'è qualcosa, venite.",
	24: "NORA: Le undici prima di te le ho costruite io, Eli. E le ho perse tutte allo stesso modo: dicendogli tutto. Tu sei la prima a cui non ho detto. È la cosa più difficile che abbia mai fatto. Adesso vai, e risolvi l'ultimo da sola.",
}

const FINAL_BEAT := "NORA: La nave ha assegnato il tredicesimo posto, e non a una nozione: a te. Non perché hai trovato il Fondo — perché sei l'unica che tiene dodici modi di capire nella stessa testa, e l'unica a cui nessuno li ha detti. E i sensori lunghi rispondono: undici segnali fuori dal circuito, e molto più in là una riga vecchia di quattrocento anni, ancora accesa. C'è qualcosa. Venite. Sono tutte vive, sorella. E lei sta ancora aspettando."

## **I mondi in cui la storia si ribalta.** Sono i sette colpi di
## `docs/TRAMA_E_MISTERO.md` §3 — il quinto è doppio, mondi 19 e 20 — ed è la
## stessa lista che l'intestazione qui sopra dichiara a parole. Sta qui come
## dato perché fuori serve a qualcuno: il Custode alza la testa quando NORA dice
## la cosa più grossa della partita, invece di restare l'unica presenza che non
## si accorge di niente ([[PetExpressionEngine]] `story_reveal`).
const COLPI := [5, 8, 12, 16, 19, 20, 23, 24]

static func porta_un_colpo(level: int) -> bool:
	return COLPI.has(level)

var save: GameSaveManager

func setup(save_manager: GameSaveManager) -> void:
	save = save_manager
	if not save.data.has("narrative"):
		save.data["narrative"] = {"seen": [], "beats": {}}

func beat_for_level(level: int) -> String:
	if level > 24:
		return FINAL_BEAT
	return str(BEATS.get(clampi(level, 1, 24), BEATS[1]))

func reveal_level(level: int) -> Dictionary:
	var key := str(clampi(level, 1, 24)) if level <= 24 else "final"
	var narrative: Dictionary = save.data["narrative"]
	var seen: Array = narrative.get("seen", [])
	var is_new := not seen.has(key)
	if is_new:
		seen.append(key)
		narrative["seen"] = seen
	var beats: Dictionary = narrative.get("beats", {})
	beats[key] = beat_for_level(level)
	narrative["beats"] = beats
	return {"level": level, "text": beat_for_level(level), "new": is_new}
