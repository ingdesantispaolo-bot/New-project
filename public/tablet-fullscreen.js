// Schermo intero sul tablet.
//
// Perche' esiste: il gioco disegna 1280x720 e la barra degli indirizzi piu' la
// barra di navigazione di Android/iPadOS si mangiano fra il 15% e il 25% di
// quell'altezza. Non e' solo estetica — il mondo viene scalato con
// `stretch/aspect="expand"`, quindi meno altezza significa meno mondo visibile e
// bersagli tattili piu' piccoli per la mano di un bambino.
//
// Dove gira: iniettato nel guscio HTML generato da Godot tramite
// `html/head_include` (vedi `godot/export_presets.cfg`). NON va messo dentro il
// guscio a mano: quel file lo riscrive Godot a ogni export e la modifica
// sparirebbe senza rumore. `scripts/audit-web-release.mjs` verifica che
// l'aggancio ci sia ancora.
//
// Il punto delicato e' che nessun browser concede lo schermo intero se non
// dentro un gesto dell'utente: la richiesta va fatta nel gestore dell'evento
// DOM, non dal ciclo di gioco di Godot (che gira in `requestAnimationFrame`,
// dove Safari considera il gesto gia' scaduto). Per questo la logica vive qui e
// non in GDScript.
(function () {
  "use strict";

  var PREF_KEY = "eli-quest:schermo-intero";
  var HINT_KEY = "eli-quest:schermo-intero-suggerimento";
  var MAX_TENTATIVI = 3;

  var tentativiFalliti = 0;
  var pulsante = null;

  function leggi(chiave) {
    try {
      return window.localStorage.getItem(chiave);
    } catch (_) {
      // Safari in navigazione privata lancia sull'accesso a localStorage: la
      // preferenza e' un di piu', la sua assenza non deve fermare il gioco.
      return null;
    }
  }

  function scrivi(chiave, valore) {
    try {
      window.localStorage.setItem(chiave, valore);
    } catch (_) {
      /* vedi sopra */
    }
  }

  function parametro() {
    // Via d'uscita per chi prepara i tablet: `?schermo=finestra` lascia il gioco
    // nella pagina, `?schermo=pieno` riabilita. Scrive anche la preferenza, cosi'
    // una visita sola basta e l'indirizzo torna pulito.
    try {
      var valore = new URL(window.location.href).searchParams.get("schermo");
      if (valore === "finestra" || valore === "pieno") {
        scrivi(PREF_KEY, valore);
        return valore;
      }
    } catch (_) {
      /* URL non analizzabile: si va di preferenza salvata */
    }
    return null;
  }

  function sottoSmoke() {
    // `scripts/smoke-godot-web.mjs` marca la sua sessione dentro GODOT_CONFIG.
    // Lo schermo intero cambierebbe la dimensione della finestra a meta' corsa e
    // il rettangolo del canvas — su cui lo smoke calcola OGNI tocco — diventerebbe
    // sbagliato. Il test tocca il gioco, non la cornice del browser.
    //
    // `typeof` e non `window.GODOT_CONFIG`: nel guscio Godot la configurazione e'
    // dichiarata `const`, e un `const` in cima a uno script classico vive
    // nell'ambiente lessicale globale — visibile agli script che seguono, ma MAI
    // come proprieta' di `window`. Cercarla li' dava sempre «non sono sotto
    // test», e il primo tocco sintetico dello smoke portava a schermo intero
    // mandando fuori bersaglio tutti i tocchi successivi.
    var config = typeof GODOT_CONFIG !== "undefined" ? GODOT_CONFIG : window.GODOT_CONFIG;
    return Boolean(config && config.args && config.args.indexOf("--eli-release-smoke") >= 0);
  }

  function inApp() {
    // Avviato dalla schermata Home come app installata: la cornice del browser
    // non c'e' gia', non c'e' niente da chiedere.
    return (
      window.navigator.standalone === true
      || (Boolean(window.matchMedia) && (
        window.matchMedia("(display-mode: standalone)").matches
        || window.matchMedia("(display-mode: fullscreen)").matches
      ))
    );
  }

  function elementoPieno() {
    return document.fullscreenElement || document.webkitFullscreenElement || null;
  }

  function supportato() {
    var root = document.documentElement;
    return Boolean(
      (document.fullscreenEnabled && root.requestFullscreen)
      || (document.webkitFullscreenEnabled && root.webkitRequestFullscreen),
    );
  }

  function entra() {
    // Schermo intero sull'INTERO documento, non sul solo canvas: se si chiedesse
    // il canvas, il pulsante qui sotto — che e' un fratello, non un figlio —
    // resterebbe fuori dallo schermo intero e sparirebbe alla vista.
    var root = document.documentElement;
    try {
      if (root.requestFullscreen) {
        // `navigationUI: "hide"` chiede anche la barra di navigazione: dove
        // l'argomento non e' supportato viene ignorato, non e' un errore.
        var esito = root.requestFullscreen({ navigationUI: "hide" });
        return esito && esito.then ? esito : Promise.resolve();
      }
      if (root.webkitRequestFullscreen) {
        root.webkitRequestFullscreen();
        return Promise.resolve();
      }
    } catch (errore) {
      return Promise.reject(errore);
    }
    return Promise.reject(new Error("schermo intero non disponibile"));
  }

  // --- Il pulsante ----------------------------------------------------------
  //
  // Vive solo FUORI dallo schermo intero: appena il gioco riempie lo schermo
  // sparisce. Non e' pudore grafico — i quattro angoli del canvas sono gia'
  // occupati dall'interfaccia (missione, opzioni, NORA, energia) e un pulsante
  // fisso ruberebbe tocchi al gioco. In alto al centro, dove sta, non c'e' nulla
  // di toccabile.
  function stile() {
    if (document.getElementById("eq-stile-schermo-intero")) return;
    var foglio = document.createElement("style");
    foglio.id = "eq-stile-schermo-intero";
    foglio.textContent = [
      "#eq-schermo-intero{",
      "position:fixed;z-index:2147483000;",
      "top:calc(env(safe-area-inset-top, 0px) + 8px);",
      "left:50%;transform:translateX(-50%);",
      "min-height:44px;padding:8px 16px;",
      "display:flex;align-items:center;gap:8px;",
      "border:1px solid rgba(244,207,105,.55);border-radius:12px;",
      "background:rgba(7,16,24,.78);color:#f4cf69;",
      "font:600 15px/1 system-ui,-apple-system,sans-serif;",
      "cursor:pointer;opacity:.9;transition:opacity .4s ease;",
      "-webkit-tap-highlight-color:transparent;touch-action:manipulation;}",
      "#eq-schermo-intero.eq-in-disparte{opacity:.35;}",
      "#eq-suggerimento{",
      "position:fixed;z-index:2147483000;left:12px;right:12px;",
      "bottom:calc(env(safe-area-inset-bottom, 0px) + 12px);",
      "display:flex;align-items:center;gap:12px;justify-content:center;",
      "padding:12px 16px;border-radius:14px;",
      "border:1px solid rgba(120,224,214,.3);background:rgba(5,21,25,.92);",
      "color:#e4f5f7;font:15px/1.4 system-ui,-apple-system,sans-serif;text-align:center;}",
      "#eq-suggerimento button{",
      "min-height:44px;min-width:44px;padding:0 12px;",
      "border:0;border-radius:10px;background:rgba(255,255,255,.12);",
      "color:#e4f5f7;font:600 18px/1 system-ui,sans-serif;cursor:pointer;}",
    ].join("");
    document.head.appendChild(foglio);
  }

  function mostraPulsante() {
    if (pulsante) return;
    stile();

    pulsante = document.createElement("button");
    pulsante.id = "eq-schermo-intero";
    pulsante.type = "button";
    pulsante.setAttribute("aria-label", "Gioca a schermo intero");

    var icona = document.createElement("span");
    icona.setAttribute("aria-hidden", "true");
    icona.textContent = "⛶";
    var testo = document.createElement("span");
    testo.textContent = "Schermo intero";
    pulsante.appendChild(icona);
    pulsante.appendChild(testo);

    pulsante.addEventListener("click", function (evento) {
      // Il click sul pulsante e' esso stesso un gesto: fermarlo qui evita che il
      // gestore del "primo tocco" parta in parallelo e chieda due volte.
      evento.stopPropagation();
      scrivi(PREF_KEY, "pieno");
      entra().catch(function (errore) {
        // Un rifiuto arrivato da un click vero significa che questo browser non
        // lo concedera' mai: il pulsante non serve piu', serve la strada
        // dell'app installata.
        console.warn("Schermo intero rifiutato:", errore);
        rimuoviPulsante();
        mostraSuggerimento();
      });
    });

    document.body.appendChild(pulsante);

    // Chi ha scelto la finestra se lo ritrova addosso per tutta la partita: dopo
    // qualche secondo si mette in disparte. Sbiadito e non sparito, perche' e'
    // l'unica strada di ritorno allo schermo intero e non deve diventare un
    // indovinello.
    window.setTimeout(function () {
      if (pulsante) pulsante.classList.add("eq-in-disparte");
    }, 8000);
  }

  function rimuoviPulsante() {
    if (!pulsante) return;
    pulsante.remove();
    pulsante = null;
  }

  // --- Quando il browser lo schermo intero non lo da' proprio ----------------
  //
  // Safari su iPhone — e alcune versioni di iPadOS — non espone la Fullscreen
  // API per elementi che non siano video. Li' l'unica strada senza cornice e'
  // l'installazione dalla schermata Home, che il manifest gia' prepara.
  function mostraSuggerimento() {
    if (document.getElementById("eq-suggerimento")) return;
    if (leggi(HINT_KEY) === "visto") return;
    stile();

    var barra = document.createElement("div");
    barra.id = "eq-suggerimento";

    var testo = document.createElement("span");
    testo.innerHTML = "Per giocare senza le barre del browser: menu Condividi &rarr; "
      + "<strong>Aggiungi alla schermata Home</strong>, poi apri Eli Quest da l&igrave;.";
    barra.appendChild(testo);

    var chiudi = document.createElement("button");
    chiudi.type = "button";
    chiudi.setAttribute("aria-label", "Chiudi il suggerimento");
    chiudi.textContent = "×";
    chiudi.addEventListener("click", function (evento) {
      evento.stopPropagation();
      scrivi(HINT_KEY, "visto");
      barra.remove();
    });
    barra.appendChild(chiudi);

    document.body.appendChild(barra);
  }

  // --- Ingresso automatico al primo tocco -----------------------------------
  //
  // Il bambino tocca lo schermo comunque, per giocare: quel tocco e' il gesto
  // che serve al browser. Cosi' lo schermo intero arriva senza che nessuno debba
  // spiegargli un pulsante.
  function armaPrimoGesto() {
    var eventi = ["pointerdown", "touchend", "click", "keydown"];
    var opzioni = { capture: true, passive: true };

    function stacca() {
      eventi.forEach(function (nome) {
        window.removeEventListener(nome, alGesto, opzioni);
      });
    }

    function alGesto() {
      if (elementoPieno()) {
        stacca();
        return;
      }
      entra().then(stacca, function (errore) {
        // Safari non accetta ogni tipo di gesto: `pointerdown` puo' essere
        // rifiutato dove `touchend` passa. Si riprova, ma non all'infinito —
        // dopo tre no resta il pulsante, che e' un gesto accettato sempre.
        tentativiFalliti += 1;
        if (tentativiFalliti >= MAX_TENTATIVI) {
          stacca();
          console.warn("Schermo intero automatico non concesso:", errore);
        }
      });
    }

    eventi.forEach(function (nome) {
      window.addEventListener(nome, alGesto, opzioni);
    });
  }

  function alCambio() {
    if (elementoPieno()) {
      rimuoviPulsante();
      return;
    }
    // Si e' usciti: che sia stato il gesto di sistema o il tasto Esc, e' una
    // volonta' espressa. Il gioco smette di riprendersi lo schermo da solo — al
    // prossimo avvio resta nella pagina — e il pulsante torna disponibile per
    // cambiare idea con un tocco.
    scrivi(PREF_KEY, "finestra");
    mostraPulsante();
  }

  function avvia() {
    if (sottoSmoke() || inApp()) return;

    var richiesta = parametro();
    if (richiesta === "finestra") return;

    if (!supportato()) {
      mostraSuggerimento();
      return;
    }

    document.addEventListener("fullscreenchange", alCambio);
    document.addEventListener("webkitfullscreenchange", alCambio);

    mostraPulsante();
    if (richiesta === "pieno" || leggi(PREF_KEY) !== "finestra") armaPrimoGesto();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", avvia);
  } else {
    avvia();
  }
}());
