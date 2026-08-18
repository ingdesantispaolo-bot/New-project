// Marchia `build_version.gd` con commit e data del build.
//
// La versione la scrive il BUILD, non il gioco: dentro l'export non c'è git.
// Porting di `stamp-version.py` — la pipeline gira in Node sia in locale sia in
// CI, e tenere un solo file Python per trenta righe significava installare un
// secondo toolchain nel workflow.
//
// Uso: node scripts/stamp-version.mjs

import { execFileSync } from "node:child_process";
import { writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const target = join(root, "godot", "scripts", "game", "build_version.gd");

const git = (...args) => execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();

const sha = git("log", "-1", "--format=%h");
const data = git("log", "-1", "--format=%cd", "--date=format:%d/%m/%Y %H:%M");

const source = `class_name BuildVersion
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
## Rigenerato da \`scripts/stamp-version.mjs\`.

const COMMIT := "${sha}"
const DATA := "${data}"

## La riga da mostrare. Corta di proposito: sta sotto il titolo e non deve
## competere con il pulsante GIOCA.
static func etichetta() -> String:
\treturn "versione %s · %s" % [COMMIT, DATA]
`;

await writeFile(target, source, "utf8");
console.log(`build_version.gd: ${sha}  ${data}`);
