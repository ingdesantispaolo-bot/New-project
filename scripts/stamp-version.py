# -*- coding: utf-8 -*-
import io, subprocess

# La versione la scrive il BUILD, non il gioco: dentro l'export non c'e' git.
sha = subprocess.check_output(["git", "log", "-1", "--format=%h"]).decode().strip()
data = subprocess.check_output(
    ["git", "log", "-1", "--format=%cd", "--date=format:%d/%m/%Y %H:%M"]).decode().strip()

p = "godot/scripts/game/build_version.gd"
io.open(p, "w", encoding="utf-8", newline="").write(u'''class_name BuildVersion
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

const COMMIT := "%s"
const DATA := "%s"

## La riga da mostrare. Corta di proposito: sta sotto il titolo e non deve
## competere con il pulsante GIOCA.
static func etichetta() -> String:
	return "versione %%s · %%s" %% [COMMIT, DATA]
''' % (sha, data))
print("build_version.gd: %s  %s" % (sha, data))
