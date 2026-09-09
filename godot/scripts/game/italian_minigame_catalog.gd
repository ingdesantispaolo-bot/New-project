extends RefCounted

## Percorso di italiano in otto fasce.
##
## Ogni fascia contiene due sfide complete e usa un gesto coerente con ciò che
## si sta imparando: prima si completa, poi si ordina e si smista, infine si
## revisiona un testo. Il catalogo è separato dal manager generale per rendere
## leggibile la progressione didattica e verificabile la sua copertura.

const BAND_CHALLENGES := {
	1: [
		{"title": "Accordo lampo", "format": "compose", "complexity": 1, "spec": {
			"topic": "analisi-grammaticale", "prompt": "Completa la frase: scegli il verbo che si accorda con il soggetto.",
			"slots": [{"text": "Il gatto"}, {"text": ""}, {"text": "sul cuscino"}],
			"targets": [{"id": "a", "label": "dormono"}, {"id": "b", "label": "dorme"}, {"id": "c", "label": "dormite"}],
			"answer": "b", "explanation": "«Il gatto» è uno solo: il verbo va alla terza persona singolare, quindi «dorme»."}},
		{"title": "Articolo al posto giusto", "format": "compose", "complexity": 1, "spec": {
			"topic": "analisi-grammaticale", "prompt": "Completa la frase con l'articolo che concorda con il nome.",
			"slots": [{"text": ""}, {"text": "amiche preparano lo zaino"}],
			"targets": [{"id": "a", "label": "Le"}, {"id": "b", "label": "Il"}, {"id": "c", "label": "Gli"}],
			"answer": "a", "explanation": "«Amiche» è femminile plurale: l'articolo determinativo che concorda è «le»."}},
		# **Aggiunte il 9 settembre 2026, e sono la riparazione di R-18.**
		#
		# Le fasce 1 e 5 avevano due sfide ciascuna, e tutte e quattro erano
		# `compose`. Non e' un dettaglio: italiano e' materia del mondo soltanto ai
		# mondi 2 e 14, che stanno esattamente in quelle due fasce, e
		# `build_minigame` mette **una campata calibrata in ogni sessione**. Quindi
		# ogni sessione di italiano dei suoi due mondi conteneva una `compose`
		# garantita — e `gesto_audit` conta `compose` fra i «sceglie», perche' si
		# tocca una fra le alternative offerte.
		#
		# Misurato: `compose` era il 14,6% dei nodi al mondo 2 e il 17,0% al mondo
		# 14, piu' della scelta multipla stessa. Con quattro opzioni per fascia,
		# meta' manipolative, la campata garantita smette di essere sempre lo
		# stesso gesto.
		{"title": "Squadra di parole", "format": "classification", "complexity": 1, "spec": {
			"topic": "morfologia", "draw": 6, "prompt": "Porta ogni parola nel contenitore che le corrisponde.",
			"categories": ["una cosa o una persona", "un'azione", "una qualita'"],
			"assignments": {"barca": "una cosa o una persona", "maestra": "una cosa o una persona", "montagna": "una cosa o una persona",
				"cane": "una cosa o una persona", "finestra": "una cosa o una persona", "bambino": "una cosa o una persona",
				"corre": "un'azione", "dorme": "un'azione", "scrive": "un'azione",
				"nuota": "un'azione", "ride": "un'azione", "salta": "un'azione",
				"veloce": "una qualita'", "alto": "una qualita'", "rosso": "una qualita'",
				"felice": "una qualita'", "pesante": "una qualita'", "gentile": "una qualita'"},
			"explanation": "Il nome dice che cosa c'e', il verbo che cosa succede, l'aggettivo com'e'. Prima si riconosce il mestiere della parola nella frase, poi si impara il nome che i grammatici gli hanno dato."}},
		{"title": "Ordine di lettura", "format": "ordering", "complexity": 1, "spec": {
			"topic": "lessico", "prompt": "Metti le parole in ordine alfabetico.",
			"correctOrder": ["albero", "barca", "casa", "dono"],
			"explanation": "L'ordine alfabetico si decide sulla prima lettera diversa. E' la stessa regola con cui si cerca su un dizionario, ed e' il motivo per cui cercare una parola richiede pochi secondi invece di sfogliare tutto."}},
	],
	2: [
		{"title": "Frase in officina", "format": "ordering", "complexity": 2, "spec": {
			"topic": "sintassi", "prompt": "Rimonta la frase partendo da chi compie l'azione.",
			"correctOrder": ["La piccola volpe", "attraversa", "il bosco", "in silenzio"],
			"explanation": "La frase base parte dal soggetto, continua con il verbo e aggiunge che cosa, dove o come avviene l'azione."}},
		{"title": "Storia in quattro scene", "format": "ordering", "complexity": 2, "spec": {
			"topic": "testo-narrativo", "prompt": "Metti in fila le scene: ogni fatto deve rendere possibile il successivo.",
			"correctOrder": ["Sara trova un seme", "Lo pianta in un vaso", "Ogni giorno lo annaffia", "Spunta una foglia"],
			"explanation": "Prima si trova e si pianta il seme, poi lo si cura; soltanto dopo può spuntare la foglia. È un ordine di causa, non di suono."}},
	],
	3: [
		{"title": "Smistaparole", "format": "classification", "complexity": 3, "spec": {
			"topic": "analisi-grammaticale", "draw": 6, "prompt": "Porta ogni parola nel contenitore della sua parte del discorso.",
			"categories": ["nome", "verbo", "aggettivo"],
			"assignments": {"fiume": "nome", "coraggio": "nome", "saltare": "verbo", "costruisce": "verbo", "luminoso": "aggettivo", "gentile": "aggettivo", "viaggio": "nome", "osservano": "verbo", "sottile": "aggettivo"},
			"explanation": "Il nome indica qualcosa, il verbo dice un'azione o uno stato, l'aggettivo aggiunge una qualità al nome."}},
		{"title": "Nomi visibili e invisibili", "format": "classification", "complexity": 3, "spec": {
			"topic": "lessico", "draw": 6, "prompt": "Smista i nomi: si percepiscono con i sensi oppure esistono come idee e sentimenti?",
			"categories": ["concreto", "astratto"],
			"assignments": {"campana": "concreto", "profumo": "concreto", "nebbia": "concreto", "amicizia": "astratto", "pazienza": "astratto", "libertà": "astratto", "quaderno": "concreto", "nostalgia": "astratto"},
			"explanation": "Un nome concreto si può percepire con almeno un senso; un nome astratto indica un'idea, una qualità o un sentimento."}},
	],
	4: [
		{"title": "Caccia all'errore", "format": "code_debug", "complexity": 4, "spec": {
			"topic": "ortografia", "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre frasi sono sul pannello: quale contiene l'errore di ortografia?",
			"codeLines": ["Qual è la strada giusta?", "Non ce' più acqua.", "Ho comprato un po' di pane.", "# tocca la riga da riparare"],
			"explanation": "Riga 2: si scrive «c'è», perché unisce «ci» ed «è». «Ce» senza apostrofo ha un altro lavoro."}},
		{"title": "Tempo fuori posto", "format": "code_debug", "complexity": 4, "spec": {
			"topic": "tempi-indicativo", "answerLine": 3, "shuffleLines": true,
			"prompt": "Quale frase usa un tempo verbale incompatibile con l'indizio temporale?",
			"codeLines": ["Ogni estate andavamo al lago.", "Domani partiremo presto.", "Ieri gioco con Marta.", "# trova il tempo fuori posto"],
			"explanation": "Riga 3: «ieri» colloca l'azione nel passato; serve «ho giocato» o «giocavo», non il presente «gioco»."}},
	],
	5: [
		{"title": "Connettivo decisivo", "format": "compose", "complexity": 5, "spec": {
			"topic": "sintassi", "prompt": "Completa il periodo con il connettivo che esprime un contrasto.",
			"slots": [{"text": "Il sentiero era ripido,"}, {"text": ""}, {"text": "continuammo a salire"}],
			"targets": [{"id": "a", "label": "perciò"}, {"id": "b", "label": "tuttavia"}, {"id": "c", "label": "infatti"}],
			"answer": "b", "explanation": "«Tuttavia» segnala un contrasto: la salita è difficile, ma l'azione continua. «Perciò» indicherebbe una conseguenza."}},
		{"title": "Pronome senza equivoci", "format": "compose", "complexity": 5, "spec": {
			"topic": "morfologia", "prompt": "Sostituisci la ripetizione con il pronome corretto: «Ho visto Marta e ho salutato Marta».",
			"slots": [{"text": "Ho visto Marta e"}, {"text": ""}, {"text": "ho salutata"}],
			"targets": [{"id": "a", "label": "gli"}, {"id": "b", "label": "la"}, {"id": "c", "label": "le"}],
			"answer": "b", "explanation": "Marta e' il complemento oggetto femminile singolare: il pronome che la sostituisce e' «la»."}},
		{"title": "Reggenti e dipendenti", "format": "classification", "complexity": 5, "spec": {
			"topic": "sintassi", "draw": 6, "prompt": "Smista ogni pezzo: puo' stare da solo oppure ha bisogno di un altro?",
			"categories": ["sta in piedi da solo", "ha bisogno di un altro pezzo"],
			"assignments": {"Marta e' tornata": "sta in piedi da solo", "il treno partiva alle otto": "sta in piedi da solo",
				"nevicava tutta la notte": "sta in piedi da solo", "abbiamo chiuso la porta": "sta in piedi da solo",
				"il cane abbaiava forte": "sta in piedi da solo", "sono arrivati in ritardo": "sta in piedi da solo",
				"quando il sole calava": "ha bisogno di un altro pezzo", "perche' era stanco": "ha bisogno di un altro pezzo",
				"se avessi tempo": "ha bisogno di un altro pezzo", "mentre tutti aspettavano": "ha bisogno di un altro pezzo",
				"affinche' fosse chiaro": "ha bisogno di un altro pezzo", "dopo che ebbe finito": "ha bisogno di un altro pezzo"},
			"explanation": "La proposizione principale regge da sola; la subordinata comincia con una parola che la aggancia a qualcos'altro e senza quel qualcosa resta sospesa. Riconoscere quale delle due si ha davanti e' il primo passo dell'analisi del periodo."}},
		{"title": "Catena dei fatti", "format": "ordering", "complexity": 5, "spec": {
			"topic": "tipologie-testuali", "prompt": "Metti in fila i fatti: ognuno deve rendere possibile il successivo.",
			"correctOrder": ["Il fiume esondo' nella notte", "Il ponte fu chiuso al traffico", "I camion presero la strada alta", "Il paese resto' isolato per due giorni"],
			"explanation": "In un racconto l'ordine non e' cronologico per caso: e' causale. Se due fatti si possono scambiare senza che il testo perda senso, uno dei due non stava spiegando l'altro."}},
	],
	6: [
		{"title": "Architettura del periodo", "format": "classification", "complexity": 6, "spec": {
			"topic": "analisi-del-periodo", "draw": 6, "prompt": "Smista ogni proposizione secondo il legame che crea.",
			"categories": ["causa", "tempo", "scopo"],
			"assignments": {"perché era tardi": "causa", "dato che pioveva": "causa", "quando arrivammo": "tempo", "mentre il sole calava": "tempo", "per trovare la strada": "scopo", "affinché tutti capissero": "scopo", "poiché mancava la luce": "causa", "prima che facesse buio": "tempo", "per non perdere il segnale": "scopo"},
			"explanation": "La causale spiega perché, la temporale dice quando, la finale dichiara per quale scopo si compie l'azione."}},
		{"title": "Complementi in rotta", "format": "classification", "complexity": 6, "spec": {
			"topic": "analisi-logica", "draw": 6, "prompt": "Smista i sintagmi guardando la domanda a cui rispondono, non soltanto la preposizione.",
			"categories": ["termine", "mezzo", "causa"],
			"assignments": {"a mia sorella": "termine", "agli esploratori": "termine", "con la bussola": "mezzo", "per posta": "mezzo", "per la pioggia": "causa", "dalla paura": "causa", "al custode": "termine", "in bicicletta": "mezzo", "a causa del vento": "causa"},
			"explanation": "Il termine risponde «a chi?», il mezzo «con che cosa?», la causa «per quale motivo?». La stessa preposizione puo' introdurre funzioni diverse."}},
	],
	7: [
		{"title": "Argomento in costruzione", "format": "cycle", "complexity": 7, "spec": {
			"topic": "testo-argomentativo", "prompt": "Ricostruisci un paragrafo argomentativo completo.",
			"stages": [{"id": "tesi", "label": "Dichiara la tesi", "glyph": "question"}, {"id": "prova", "label": "Porta una prova", "glyph": "book"}, {"id": "obiezione", "label": "Considera un'obiezione", "glyph": "gear"}, {"id": "risposta", "label": "Rispondi e concludi", "glyph": "check"}],
			"correctOrder": ["tesi", "prova", "obiezione", "risposta"],
			"explanation": "Un'argomentazione dichiara la tesi, la sostiene, prende sul serio un'obiezione e infine mostra perché la tesi regge ancora."}},
		{"title": "Revisione a strati", "format": "cycle", "complexity": 7, "spec": {
			"topic": "scrittura", "prompt": "Metti in ordine una revisione efficace, dal contenuto ai dettagli.",
			"stages": [{"id": "senso", "label": "Controlla se il testo dice ciò che deve", "glyph": "question"}, {"id": "ordine", "label": "Riordina paragrafi e frasi", "glyph": "book"}, {"id": "lessico", "label": "Rendi precise le parole", "glyph": "pen"}, {"id": "segni", "label": "Correggi ortografia e punteggiatura", "glyph": "check"}],
			"correctOrder": ["senso", "ordine", "lessico", "segni"],
			"explanation": "Si corregge prima la struttura: lucidare una frase destinata a essere eliminata spreca lavoro. Ortografia e punteggiatura vengono nell'ultimo passaggio."}},
	],
	8: [
		{"title": "Sala di revisione", "format": "code_debug", "complexity": 8, "spec": {
			"topic": "coesione-testuale", "answerLine": 3, "shuffleLines": true,
			"prompt": "Quale frase rompe la coesione usando un pronome senza referente chiaro?",
			"codeLines": ["Marta raccolse le mappe e le mise nello zaino.", "Il custode accese il faro, che illuminò la costa.", "Luca parlò con Marco mentre era agitato.", "# trova la frase ambigua"],
			"explanation": "Riga 3: «era agitato» può riferirsi sia a Luca sia a Marco. Una revisione efficace nomina la persona e toglie l'ambiguità."}},
		{"title": "Registro sotto esame", "format": "code_debug", "complexity": 8, "spec": {
			"topic": "registro-linguistico", "answerLine": 2, "shuffleLines": true,
			"prompt": "Tre righe appartengono a una relazione formale: quale usa un registro inadatto?",
			"codeLines": ["L'esperimento ha prodotto risultati coerenti.", "Alla fine è venuta fuori una roba strana.", "I dati sono riportati nella tabella seguente.", "# individua la frase da riscrivere"],
			"explanation": "Riga 2: «una roba strana» è vaga e colloquiale. In una relazione serve una descrizione precisa del risultato inatteso."}},
	],
}

static func options_for_band(band: int) -> Array:
	return Array(BAND_CHALLENGES.get(clampi(band, 1, 8), [])).duplicate(true)

static func pick(band: int, rng: RandomNumberGenerator) -> Dictionary:
	var options := options_for_band(band)
	if options.is_empty():
		return {}
	return (options[rng.randi_range(0, options.size() - 1)] as Dictionary).duplicate(true)

static func all_challenges() -> Array:
	var result: Array = []
	for band in range(1, 9):
		for challenge in options_for_band(band):
			var entry := (challenge as Dictionary).duplicate(true)
			entry["band"] = band
			result.append(entry)
	return result
