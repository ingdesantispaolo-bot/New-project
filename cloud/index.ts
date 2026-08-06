/**
 * Eli Quest — salvataggio in cloud.
 *
 * Versione TypeScript, per il flusso del pannello Cloudflare che crea
 * `index.ts` + `wrangler.jsonc`. È lo stesso codice di `worker.js`: se usi
 * questo, quello si può ignorare.
 *
 *   GET  /save/ABCD-1234   -> restituisce il salvataggio, o 404 se non c'è
 *   PUT  /save/ABCD-1234   -> lo sostituisce
 *
 * Nessun account, nessuna email, nessuna password: la chiave è un CODICE opaco
 * che il gioco genera al primo avvio. Il gioco è per bambini di 10-13 anni, e
 * ogni campo che chiedesse un dato personale porterebbe con sé un obbligo di
 * consenso. Un codice casuale non identifica nessuno.
 */

export interface Env {
  // `SAVES` è il nome del COLLEGAMENTO, non quello dello spazio KV.
  // Nel pannello lo spazio può chiamarsi `Eli_game`: è il `wrangler.jsonc`
  // (o la schermata Settings → Bindings) a dire «lo spazio Eli_game, qui
  // dentro, si chiama SAVES». Se cambi questo nome, cambialo in entrambi i
  // posti o il Worker non parte.
  SAVES: KVNamespace;
}

// Solo il sito del gioco può chiamare il Worker. Con "*" chiunque potrebbe
// leggere un salvataggio conoscendo il codice, da una pagina qualunque.
const ORIGINI_AMMESSE = [
  "https://ingdesantispaolo-bot.github.io",
  "http://localhost:5173",
  "http://localhost:4173",
];

// Un salvataggio di Eli Quest sta ampiamente sotto i 100 KB. Il limite impedisce
// che il codice diventi spazio di archiviazione gratuito.
const LIMITE_BYTE = 256 * 1024;

// Quattro lettere, un trattino, quattro cifre. Rifiutare il resto tiene fuori i
// tentativi di percorso strani.
const FORMA_CODICE = /^[A-Z]{4}-[0-9]{4}$/;

// Il codice di un GRUPPO (registro dei giocatori) è volutamente più corto:
// tre lettere e tre cifre. Serve a non poterlo confondere con un codice di
// ripristino — sono due cose molto diverse e finiscono in due caselle di testo
// vicine. Un codice gruppo incollato per errore nel campo del ripristino non
// deve nemmeno passare il controllo di forma.
const FORMA_GRUPPO = /^[A-Z]{3}-[0-9]{3}$/;

// Chi sta in un gruppo è identificato da una sigla opaca, generata dal gioco.
// NON è il codice di ripristino, e questa è la scelta di sicurezza più
// importante del file: il codice di ripristino SOVRASCRIVE un salvataggio, e se
// viaggiasse nel registro chiunque conoscesse il codice del gruppo potrebbe
// cancellare la partita di un altro bambino.
const FORMA_MEMBRO = /^[A-Z0-9]{8}$/;

// Una classe sta sotto i trenta. Il limite esiste perché un gruppo vive in una
// chiave sola: senza, una sola chiave potrebbe crescere fino a rendere lenta
// ogni lettura per tutti quelli che la condividono.
const MAX_MEMBRI = 40;

// Una scheda è un riepilogo di numeri, non un salvataggio.
const LIMITE_SCHEDA = 4 * 1024;

function intestazioni(origin: string): Record<string, string> {
  const consentita = ORIGINI_AMMESSE.includes(origin) ? origin : ORIGINI_AMMESSE[0];
  return {
    "Access-Control-Allow-Origin": consentita,
    "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
  };
}

function risposta(corpo: string, stato: number, origin: string): Response {
  return new Response(corpo, {
    status: stato,
    headers: { ...intestazioni(origin), "Content-Type": "application/json" },
  });
}

/**
 * Il registro dei giocatori.
 *
 *   GET /group/ABC-123           -> { membri: [scheda, ...] }
 *   PUT /group/ABC-123/AB12CD34  -> aggiorna la scheda di UN membro
 *
 * Un gruppo intero vive in una chiave sola. È la forma più semplice che
 * funziona, e ha un limite dichiarato: due tablet che scrivono nello stesso
 * istante si sovrascrivono, e una delle due schede resta indietro fino al
 * rinfresco successivo. Per un registro che si aggiorna da solo ogni pochi
 * minuti è un difetto che si ripara da sé; per un dato che non si può perdere
 * non basterebbe, e infatti i salvataggi veri stanno altrove, una chiave per
 * ciascuno.
 *
 * Quello che passa di qui è un RIEPILOGO: nome, livello, qualche numero. Mai un
 * salvataggio, mai un codice di ripristino.
 */
async function gruppo(
  request: Request,
  env: Env,
  origin: string,
  pezzi: string[],
): Promise<Response> {
  const codice = (pezzi[1] ?? "").toUpperCase();
  if (!FORMA_GRUPPO.test(codice)) {
    return risposta(JSON.stringify({ errore: "codice gruppo non valido" }), 400, origin);
  }
  const chiave = `group:${codice}`;

  if (request.method === "GET" && pezzi.length === 2) {
    const grezzo = await env.SAVES.get(chiave);
    if (grezzo === null) {
      return risposta(JSON.stringify({ errore: "gruppo non trovato" }), 404, origin);
    }
    const membri = Object.values(JSON.parse(grezzo) as Record<string, unknown>);
    return risposta(JSON.stringify({ membri }), 200, origin);
  }

  if (request.method === "PUT" && pezzi.length === 3) {
    const membro = pezzi[2].toUpperCase();
    if (!FORMA_MEMBRO.test(membro)) {
      return risposta(JSON.stringify({ errore: "membro non valido" }), 400, origin);
    }
    const testo = await request.text();
    if (testo.length > LIMITE_SCHEDA) {
      return risposta(JSON.stringify({ errore: "scheda troppo grande" }), 413, origin);
    }
    let scheda: unknown;
    try {
      scheda = JSON.parse(testo);
    } catch {
      return risposta(JSON.stringify({ errore: "non è JSON" }), 400, origin);
    }

    const grezzo = await env.SAVES.get(chiave);
    const attuale: Record<string, unknown> = grezzo === null ? {} : JSON.parse(grezzo);
    // Il limite non caccia chi c'è già: un membro che aggiorna la propria scheda
    // deve poterlo fare anche a gruppo pieno, altrimenti resterebbe congelato
    // alla sua ultima riga per sempre.
    if (!(membro in attuale) && Object.keys(attuale).length >= MAX_MEMBRI) {
      return risposta(JSON.stringify({ errore: "gruppo pieno" }), 409, origin);
    }
    attuale[membro] = scheda;
    await env.SAVES.put(chiave, JSON.stringify(attuale), {
      expirationTtl: 60 * 60 * 24 * 365,
    });
    return risposta(JSON.stringify({ ok: true, membri: Object.keys(attuale).length }), 200, origin);
  }

  return risposta(JSON.stringify({ errore: "metodo non ammesso" }), 405, origin);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get("Origin") ?? "";
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: intestazioni(origin) });
    }

    const url = new URL(request.url);
    const pezzi = url.pathname.split("/").filter(Boolean);

    if (pezzi[0] === "group") {
      return gruppo(request, env, origin, pezzi);
    }

    if (pezzi.length !== 2 || pezzi[0] !== "save") {
      return risposta(JSON.stringify({ errore: "rotta sconosciuta" }), 404, origin);
    }

    const codice = pezzi[1].toUpperCase();
    if (!FORMA_CODICE.test(codice)) {
      return risposta(JSON.stringify({ errore: "codice non valido" }), 400, origin);
    }

    if (request.method === "GET") {
      const salvataggio = await env.SAVES.get(`save:${codice}`);
      if (salvataggio === null) {
        return risposta(JSON.stringify({ errore: "nessun salvataggio" }), 404, origin);
      }
      return risposta(salvataggio, 200, origin);
    }

    if (request.method === "PUT") {
      const testo = await request.text();
      if (testo.length > LIMITE_BYTE) {
        return risposta(JSON.stringify({ errore: "salvataggio troppo grande" }), 413, origin);
      }
      try {
        JSON.parse(testo);
      } catch {
        return risposta(JSON.stringify({ errore: "non è JSON" }), 400, origin);
      }
      // Un anno senza toccarlo e sparisce: nessuno ricorda un codice dopo un
      // anno, e i dati abbandonati non devono restare per sempre.
      await env.SAVES.put(`save:${codice}`, testo, { expirationTtl: 60 * 60 * 24 * 365 });
      return risposta(JSON.stringify({ ok: true, codice }), 200, origin);
    }

    return risposta(JSON.stringify({ errore: "metodo non ammesso" }), 405, origin);
  },
};
