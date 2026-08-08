class_name BuildVersion
extends RefCounted

## **Che versione sto giocando?** (7 agosto 2026)
##
## Su richiesta del committente: data e ora del commit nella schermata iniziale.
##
## Serve a una cosa concreta e non decorativa: quando arriva una segnalazione di
## gioco — «la prova di scienze e' sempre la farfalla» — la prima domanda da
## farsi e' **su quale build**. Senza questo numero la risposta e' una
## ricostruzione a memoria, e in questo progetto le build si susseguono di ore.
##
## I valori sono **scritti dallo script di export**, non letti a runtime: dentro
## un export Web non c'e' nessun git da interrogare, e un gioco che provasse a
## chiamarlo mostrerebbe una versione vuota proprio dove serve di piu'.
## Rigenerato da `scripts/stamp-version.mjs`.

const COMMIT := "d710fae"
const DATA := "08/08/2026 16:04"

## La riga da mostrare. Corta di proposito: sta sotto il titolo e non deve
## competere con il pulsante GIOCA.
static func etichetta() -> String:
	return "versione %s · %s" % [COMMIT, DATA]
