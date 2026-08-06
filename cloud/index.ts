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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get("Origin") ?? "";
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: intestazioni(origin) });
    }

    const url = new URL(request.url);
    const pezzi = url.pathname.split("/").filter(Boolean);
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
