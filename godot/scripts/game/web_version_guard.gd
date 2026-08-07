class_name WebVersionGuard
extends RefCounted

## **Sto giocando la versione giusta?** (7 agosto 2026)
##
## Richiesta del committente: «all'avvio del programma online questo controlli se
## sta girando la versione aggiornata, se non è così va riscaricata».
##
## **Perché il controllo che c'era non bastava.** Il lanciatore (`index.html`)
## confronta da tempo il `buildId` del **service worker** con quello di
## `build.json`, e aspetta che il worker nuovo prenda il comando. È giusto, ma
## verifica la cosa sbagliata: dice che il *guardiano della cache* è aggiornato,
## non che il **gioco che sta per partire** lo sia. Fra i due c'è tutto quello
## che può andare storto — la cache HTTP del browser, che serve `index.pck` dallo
## stesso indirizzo di ieri; un aggiornamento che scade il tempo di attesa e
## parte lo stesso; una scheda rimasta aperta per giorni.
##
## Qui si confronta l'unica coppia che conta davvero: **il commit compilato
## dentro questo pacchetto** ([[BuildVersion]]) contro quello che il server
## dichiara adesso in `build.json`. Se differiscono, il gioco lo dice e offre di
## riscaricare — e riscaricare vuol dire per davvero: si cancellano le cache, si
## disiscrive il service worker, si torna al lanciatore.
##
## **Tre cose che questo controllo non fa, di proposito:**
##
##   - **non blocca**. Chi sta giocando può ignorare l'avviso e continuare: una
##     schermata che impedisce di giocare perché c'è una build più nuova punisce
##     il bambino per un problema che non è suo;
##   - **non insiste offline**. Se `build.json` non si raggiunge, la risposta è
##     «non lo so», che non è «sei vecchio». Un avviso che compare in aereo
##     insegna a ignorare gli avvisi;
##   - **non esiste fuori dal web**. Su una build nativa non c'è niente da
##     riscaricare, e chiedere a un file locale se è aggiornato è una domanda
##     senza risposta.

## Dove sta il manifesto rispetto alla pagina del gioco. La pagina esportata vive
## in `/godot/outdoor/index.html`, il manifesto nella radice del sito.
const PERCORSO_MANIFESTO := "../../build.json"

## Quanto si aspetta la risposta prima di lasciar perdere. Mezzo secondo in più
## sarebbe mezzo secondo di attesa davanti al menu per una cosa che quasi sempre
## va bene; mezzo in meno farebbe fallire il controllo su una connessione lenta,
## che è proprio quella su cui una copia vecchia resta appiccicata più a lungo.
const ATTESA_MASSIMA_SEC := 2.5

## Vero se quello che gira non è quello che il server pubblica.
##
## `remoto` vuoto significa **non lo so** — server irraggiungibile, manifesto
## malformato, gioco offline — e in quel caso non si dice niente. È la
## differenza fra un controllo utile e uno che si impara a chiudere senza
## leggerlo.
static func deve_riscaricare(locale: String, remoto: String) -> bool:
	var a := locale.strip_edges()
	var b := remoto.strip_edges()
	if b.is_empty() or a.is_empty():
		return false
	return a != b

## Vero se questo pacchetto sta girando dentro un browser. Altrove il controllo
## non ha senso e non deve nemmeno partire.
static func sul_web() -> bool:
	# `OS.has_feature("web")` da solo: il ponte JavaScript e' una classe statica e
	# non si puo' interrogare per esistenza. Fuori dal browser questa e' falsa e
	# nessuna delle funzioni che lo usano viene mai raggiunta.
	return OS.has_feature("web")

## Avvia la richiesta del manifesto. Non risponde: la risposta si raccoglie con
## `commit_ricevuto`, perché in un browser la fetch è asincrona e bloccare il
## menu per aspettarla sarebbe peggio del difetto che stiamo riparando.
static func chiedi_versione_pubblicata() -> void:
	if not sul_web():
		return
	# `no-store` è il punto della richiesta: chiederlo passando dalla cache
	# significherebbe chiedere alla copia vecchia se è vecchia.
	JavaScriptBridge.eval("""
		window.__eliVersionePubblicata = null;
		fetch('%s?ts=' + Date.now(), { cache: 'no-store' })
			.then(function (r) { return r.ok ? r.json() : null; })
			.then(function (j) { window.__eliVersionePubblicata = (j && j.commit) || ''; })
			.catch(function () { window.__eliVersionePubblicata = ''; });
	""" % PERCORSO_MANIFESTO, true)

## Il commit pubblicato, se è già arrivato. Stringa vuota = ancora niente, o
## niente da sapere: chi chiama tratta i due casi allo stesso modo, cioè tace.
static func commit_ricevuto() -> String:
	if not sul_web():
		return ""
	var risposta = JavaScriptBridge.eval("window.__eliVersionePubblicata", true)
	if risposta == null:
		return ""
	return str(risposta)

## **Riscarica per davvero.**
##
## Cancellare le cache non basta da solo: finché il service worker vecchio ha il
## comando, continuerebbe a servire quello che ha. Quindi nell'ordine: si
## svuotano le cache, si disiscrivono i worker, e solo allora si torna al
## lanciatore — che ne registra uno nuovo e riscarica tutto dalla rete.
static func riscarica() -> void:
	if not sul_web():
		return
	JavaScriptBridge.eval("""
		(async function () {
			try {
				var chiavi = await caches.keys();
				await Promise.all(chiavi
					.filter(function (k) { return k.indexOf('eli-quest-') === 0; })
					.map(function (k) { return caches.delete(k); }));
			} catch (e) {}
			try {
				var reg = await navigator.serviceWorker.getRegistrations();
				await Promise.all(reg.map(function (r) { return r.unregister(); }));
			} catch (e) {}
			window.location.replace('../../index.html?fresh=' + Date.now());
		})();
	""", true)

## Che cosa si legge sul menu. Nomina il commit nuovo perché la segnalazione di
## gioco che arriverà dopo possa dire quale: è lo stesso motivo per cui la
## versione sta scritta sotto il pulsante GIOCA.
static func avviso(remoto: String) -> String:
	var sigla := remoto.strip_edges()
	if sigla.length() > 7:
		sigla = sigla.substr(0, 7)
	return "C'è una versione più recente (%s). Il gioco sta usando una copia vecchia." % sigla
