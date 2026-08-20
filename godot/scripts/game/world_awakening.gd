class_name WorldAwakening
extends RefCounted

## **Il risveglio: che cosa si vede quando una prova va bene.** (20 agosto 2026)
##
## Fino a oggi la ricompensa immediata era un **velo di nebbia che si alzava**:
## il mondo nasceva coperto e ogni prova ne scopriva un pezzo. Ha fatto il suo
## lavoro — prima di quel velo l'unico momento in cui il gioco cambiava era
## l'esame, a mezz'ora di distanza — ma teneva occupato il canale sbagliato. La
## luminosità della scena è **che ora è**, e finché l'avanzamento la usava, il
## tempo non poteva tornare a passare ([[WorldSky]]).
##
## Adesso una prova superata **accende un fuoco**: il più vicino a Eli fra quelli
## ancora spenti. Non è una metafora della luce del mondo — è un oggetto, in un
## punto preciso, ancorato a una casa o a un punto d'interesse che esiste già.
## Le proprietà che questo cambio deve conservare, perché erano il motivo del
## velo e non sono negoziabili:
##
##   1. **una prova, un cambiamento**, e lo si vede entro un secondo;
##   2. **non torna mai indietro**: un fuoco acceso resta acceso anche se la
##      prova dopo va male. Toglierlo sarebbe la minaccia che questo gioco ha
##      scelto di non fare;
##   3. **non nasconde niente**: il velo, anche al massimo, era trasparente
##      apposta; un fuoco spento non copre nulla per definizione, quindi il
##      rischio del «secondo cancello» qui non esiste proprio;
##   4. **si vede dove stai guardando**: il velo cambiava dappertutto e quindi in
##      nessun posto in particolare. Il fuoco più vicino, no.
##
## Il contatore è lo stesso di prima ([[WorldLight]], chiave di salvataggio
## `worldLight`): **nessuna migrazione**. Qui si tiene soltanto *quali* fuochi
## sono accesi, che il contatore da solo non può dire.

## Quanti fuochi ha un mondo. Uguale a `WorldLight.PROVE_PER_MONDO`: se i due
## numeri divergessero, o resterebbero fuochi che nessuna prova può accendere, o
## prove che non accendono niente. `world_awakening_audit` tiene l'uguaglianza.
const FUOCHI := 12

const CHIAVE := "worldAwakening"

## Gli indici accesi in un mondo, in ordine di accensione.
static func accesi(save, world_id: String) -> Array:
	return Array(Dictionary(save.data.get(CHIAVE, {})).get(world_id, []))

static func quanti(save, world_id: String) -> int:
	return accesi(save, world_id).size()

static func e_acceso(save, world_id: String, indice: int) -> bool:
	return accesi(save, world_id).has(indice)

## Accende un fuoco. Ritorna falso se era già acceso o se l'indice non esiste:
## chi chiama usa l'esito per decidere se vale la pena animare qualcosa.
static func accendi(save, world_id: String, indice: int) -> bool:
	if indice < 0 or indice >= FUOCHI:
		return false
	var tutti: Dictionary = save.data.get(CHIAVE, {})
	var lista: Array = Array(tutti.get(world_id, []))
	if lista.has(indice):
		return false
	lista.append(indice)
	tutti[world_id] = lista
	save.data[CHIAVE] = tutti
	return true

## Gli indici ancora spenti, in ordine crescente.
static func spenti(save, world_id: String) -> Array:
	var gia := accesi(save, world_id)
	var out: Array = []
	for indice in range(FUOCHI):
		if not gia.has(indice):
			out.append(indice)
	return out

## **Il pareggio con il contatore.** Un salvataggio nato prima di oggi ha le
## prove ma non sa quali fuochi fossero accesi — il velo non aveva indici. Senza
## questo passaggio chi rientra in un mondo già giocato lo troverebbe spento come
## il primo giorno, e la prova dopo accenderebbe il primo fuoco: la ricompensa
## sembrerebbe **tornata indietro**, che è l'unica cosa che avevamo promesso di
## non fare mai.
##
## Ritorna gli indici accesi adesso, così chi chiama può disegnarli senza
## rileggere.
static func allinea(save, world_id: String, prove: int) -> Array:
	var mancanti := mini(prove, FUOCHI) - quanti(save, world_id)
	for indice in spenti(save, world_id):
		if mancanti <= 0:
			break
		accendi(save, world_id, int(indice))
		mancanti -= 1
	return accesi(save, world_id)
