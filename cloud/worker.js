/**
 * Eli Quest — salvataggio in cloud.
 *
 * Un Worker Cloudflare con due sole rotte. Non c'è account, non c'è password,
 * non c'è email: la chiave è un CODICE opaco che il gioco genera al primo
 * avvio e che il bambino (o chi lo segue) tiene da parte.
 *
 *   GET  /save/ABCD-1234   -> restituisce il salvataggio, o 404 se non c'è
 *   PUT  /save/ABCD-1234   -> lo sostituisce
 *
 * Perché così e non con un login: il gioco è per bambini di 10-13 anni, e ogni
 * campo in più che chiedesse un dato personale porterebbe con sé un obbligo di
 * consenso. Un codice casuale non identifica nessuno.
 *
 * Cosa NON fa, di proposito:
 *  - non fonde due salvataggi. L'ultimo che scrive vince, ed è per questo che
 *    il gioco carica dal cloud solo su richiesta esplicita;
 *  - non tiene cronologia. Serve a non perdere i progressi cambiando tablet,
 *    non a fare da archivio;
 *  - non è un'autenticazione. Chi conosce un codice può leggere e sovrascrivere
 *    quel salvataggio: va bene per il progresso di un gioco, non per altro.
 */

// Solo il sito del gioco può chiamare il Worker. Da cambiare se pubblichi
// altrove: con "*" chiunque potrebbe leggere un salvataggio conoscendo il codice
// da una pagina qualunque.
const ORIGINI_AMMESSE = [
  "https://ingdesantispaolo-bot.github.io",
  "http://localhost:5173",
  "http://localhost:4173",
];

// Un salvataggio di Eli Quest sta ampiamente sotto i 100 KB. Il limite serve a
// impedire che qualcuno usi il codice come spazio di archiviazione gratuito.
const LIMITE_BYTE = 256 * 1024;

// I codici hanno una forma precisa: quattro lettere, un trattino, quattro
// cifre. Rifiutare tutto il resto tiene fuori i tentativi di percorso strani.
const FORMA_CODICE = /^[A-Z]{4}-[0-9]{4}$/;

function intestazioni(origin) {
  const consentita = ORIGINI_AMMESSE.includes(origin) ? origin : ORIGINI_AMMESSE[0];
  return {
    "Access-Control-Allow-Origin": consentita,
    "Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
  };
}

function risposta(corpo, stato, origin, tipo = "application/json") {
  return new Response(corpo, {
    status: stato,
    headers: { ...intestazioni(origin), "Content-Type": tipo },
  });
}

export default {
  async fetch(request, env) {
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
      // Un anno senza toccarlo e sparisce: un salvataggio abbandonato non deve
      // restare per sempre, e nessuno ricorda un codice dopo un anno.
      await env.SAVES.put(`save:${codice}`, testo, { expirationTtl: 60 * 60 * 24 * 365 });
      return risposta(JSON.stringify({ ok: true, codice }), 200, origin);
    }

    return risposta(JSON.stringify({ errore: "metodo non ammesso" }), 405, origin);
  },
};
