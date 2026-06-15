const state = {
  scene: "living",
  selectedHotspot: null,
  inventory: new Set(),
  flags: {
    terminalRead: false,
    cityViewed: false,
    coffeeMade: false,
    photoChecked: false,
    coatTaken: false,
    exitUnlocked: false,
  },
  log: [
    "Ti svegli con il sapore metallico della pioggia nell'aria. Il generatore tossisce dietro una parete.",
  ],
};

const rooms = {
  living: {
    title: "Soggiorno",
    nav: "Soggiorno",
    objective: "Capire cosa ti ha svegliato",
    copy: "Il terminale lampeggia. Fuori, la citta e una parete di luce bagnata.",
    draw: drawLiving,
    hotspots: [
      hotspot("terminal", "Terminale", 23, 42, "Terminale domestico", "Lo schermo ripete un segnale privato, tagliato da disturbi e vecchi log di lavoro.", [
        action("Leggi", () => {
          state.flags.terminalRead = true;
          addLog("Messaggio ricevuto: 'Ascensore abilitato. Scendi quando le luci esterne virano al bianco.'");
          updateExitState();
        }),
        action("Spegni", () => addLog("Il terminale si oscura per un secondo, poi si riaccende da solo.")),
      ]),
      hotspot("window", "Finestra", 64, 36, "Finestra panoramica", "Il vetro amplifica il traffico volante e i messaggi pubblicitari dei piani alti.", [
        action("Affacciati", () => {
          state.flags.cityViewed = true;
          addLog("Sotto il quarantesimo piano, la strada sembra un canale nero. Qualcosa lampeggia sulla torre ORA.");
          updateExitState();
          goToScene("city");
        }),
      ]),
      hotspot("desk", "Scrivania", 27, 57, "Scrivania", "Tazze vuote, vecchi appunti, cavi non etichettati. Una routine piu che una vita.", [
        action("Osserva", () => addLog("Trovi una ricevuta per una riparazione mai richiesta: 'modulo memoria, settore notte'.")),
      ]),
      hotspot("to-entry", "Ingresso", 93, 50, "Porta interna", "La porta scorre male. Il metallo ha imparato a lamentarsi.", [
        action("Vai", () => goToScene("entry")),
      ]),
      hotspot("to-bedroom", "Camera", 8, 47, "Corridoio corto", "La camera resta nel cono d'ombra del vecchio insegna al neon.", [
        action("Vai", () => goToScene("bedroom")),
      ]),
      hotspot("to-kitchen", "Cucina", 78, 70, "Angolo cucina", "Odore di plastica calda e caffe sintetico.", [
        action("Vai", () => goToScene("kitchen")),
      ]),
    ],
  },
  entry: {
    title: "Ingresso",
    nav: "Ingresso",
    objective: "Prepararsi a uscire",
    copy: "La porta esterna riconosce il tuo battito, ma non apre finche la casa non chiude il ciclo di sicurezza.",
    draw: drawEntry,
    hotspots: [
      hotspot("coat", "Cappotto", 29, 45, "Cappotto impermeabile", "Tessuto nero, fodera rinforzata, odore di ozono e vicoli bagnati.", [
        action("Prendi", () => {
          state.flags.coatTaken = true;
          addItem("Cappotto");
          addItem("Chiave magnetica");
          addLog("Indossi il cappotto. La tasca interna contiene una chiave magnetica scheggiata.");
          updateExitState();
        }),
      ]),
      hotspot("intercom", "Citofono", 70, 43, "Citofono cieco", "Nessuna immagine, solo una riga audio intermittente dal piano strada.", [
        action("Ascolta", () => addLog("Una voce compressa ripete: 'Consegna respinta. Destinatario gia registrato in uscita.'")),
      ]),
      hotspot("main-door", "Uscita", 53, 48, "Porta blindata", "Dietro la porta c'e il vano ascensore, poi la citta.", [
        action("Apri", () => {
          if (!state.flags.exitUnlocked) {
            addLog("La serratura resta rossa. Serve il messaggio del terminale, la vista esterna e qualcosa per uscire nella pioggia.");
            return;
          }
          addLog("La porta cede con un soffio idraulico. Il prototipo termina qui: la prossima location sara il vano ascensore.");
        }),
      ]),
      hotspot("to-living", "Soggiorno", 7, 52, "Ritorno", "Il soggiorno pulsa di luce azzurra.", [
        action("Vai", () => goToScene("living")),
      ]),
    ],
  },
  bedroom: {
    title: "Camera",
    nav: "Camera",
    objective: "Ricostruire la routine",
    copy: "La stanza conserva pochi oggetti personali. Alcuni sembrano piu vecchi di te.",
    draw: drawBedroom,
    hotspots: [
      hotspot("photo", "Foto", 10, 36, "Foto scolorita", "Due persone davanti a un mare grigio. Il tuo volto e graffiato via.", [
        action("Osserva", () => {
          state.flags.photoChecked = true;
          addLog("Sul retro della foto leggi: 'Non fidarti dei ricordi che arrivano dopo la pioggia.'");
        }),
        action("Prendi", () => {
          addItem("Foto scolorita");
          addLog("Pieghi la foto e la metti nella tasca interna.");
        }),
      ]),
      hotspot("bed", "Letto", 34, 70, "Letto sfatto", "Le lenzuola sono fredde. Hai dormito poco o non hai dormito affatto.", [
        action("Osserva", () => addLog("Sotto il cuscino trovi polvere di vetro. La finestra non e rotta.")),
      ]),
      hotspot("closet", "Armadio", 80, 45, "Armadio a parete", "Vuoto, tranne un cassetto sigillato con una targhetta cancellata.", [
        action("Apri", () => addLog("Il cassetto non si apre. La chiusura non usa serrature fisiche.")),
      ]),
      hotspot("to-living", "Soggiorno", 92, 64, "Ritorno", "Il salone respira luce dal finestrone.", [
        action("Vai", () => goToScene("living")),
      ]),
    ],
  },
  kitchen: {
    title: "Cucina",
    nav: "Cucina",
    objective: "Riprendere lucidita",
    copy: "La cucina e piccola, efficiente, ostile. Ogni elettrodomestico sembra ascoltare.",
    draw: drawKitchen,
    hotspots: [
      hotspot("coffee", "Caffe", 15, 55, "Macchina del caffe", "La capsula sintetica promette sonno cancellato e mani ferme.", [
        action("Prepara", () => {
          state.flags.coffeeMade = true;
          addLog("Il caffe ha un sapore chimico, ma rimette il mondo a fuoco.");
        }),
      ]),
      hotspot("fridge", "Frigo", 78, 45, "Frigo medico", "Il display mostra una dieta calibrata da un assicuratore, non da un medico.", [
        action("Apri", () => addLog("Dentro trovi solo acqua, due pillole senza etichetta e una nota: 'Non rispondere al canale 19.'")),
      ]),
      hotspot("radio", "Radio", 58, 58, "Radio da banco", "Vecchia, analogica, quindi quasi privata.", [
        action("Accendi", () => addLog("Canale 19: solo rumore bianco, poi tre colpi secchi. Pausa. Altri tre colpi.")),
      ]),
      hotspot("to-living", "Soggiorno", 94, 52, "Ritorno", "Il corridoio e tagliato da luce rosa.", [
        action("Vai", () => goToScene("living")),
      ]),
    ],
  },
  city: {
    title: "Vista sulla citta",
    nav: "Vista citta",
    objective: "Leggere la citta",
    copy: "Da qui la metropoli non e uno sfondo: e il prossimo labirinto.",
    draw: drawCityView,
    hotspots: [
      hotspot("ora-tower", "Torre ORA", 48, 38, "Torre ORA", "La pubblicita verticale perde sincronizzazione. Per un istante mostra il tuo numero di appartamento.", [
        action("Osserva", () => addLog("La torre ORA registra le finestre illuminate. La tua e stata marcata alle 02:17.")),
      ]),
      hotspot("street", "Strada", 28, 75, "Strada inferiore", "I taxi non atterrano piu li. Troppa acqua, troppi blackout.", [
        action("Osserva", () => addLog("Un furgone senza insegne resta fermo sotto il tuo palazzo con i fari spenti.")),
      ]),
      hotspot("ad-ship", "Dirigibile", 81, 22, "Dirigibile pubblicitario", "Ripete slogan sanitari sopra un quartiere senza ospedali.", [
        action("Ascolta", () => addLog("'La memoria e un servizio. La serenita e un abbonamento.' Il messaggio si interrompe sul tuo cognome.")),
      ]),
      hotspot("to-living", "Dentro", 11, 81, "Rientra", "Il vetro chiude la citta fuori, ma non abbastanza.", [
        action("Vai", () => goToScene("living")),
      ]),
    ],
  },
};

const roomOrder = ["living", "entry", "bedroom", "kitchen", "city"];
const assets = {
  living: loadImage("assets/living-room-quality-target.png"),
  entry: loadImage("assets/entry-quality-target.png"),
  bedroom: loadImage("assets/bedroom-quality-target.png"),
  kitchen: loadImage("assets/kitchen-quality-target.png"),
  city: loadImage("assets/city-view-quality-target.png"),
};
const cityWindows = Array.from({ length: 120 }, (_, index) => ({
  x: 0.18 + pseudoRandom(index, 11) * 0.68,
  y: 0.16 + pseudoRandom(index, 23) * 0.58,
  w: 0.0025 + pseudoRandom(index, 37) * 0.004,
  h: 0.002 + pseudoRandom(index, 41) * 0.005,
  phase: pseudoRandom(index, 53) * Math.PI * 2,
  speed: 0.25 + pseudoRandom(index, 67) * 1.7,
  color: pseudoRandom(index, 79) > 0.72 ? "pink" : pseudoRandom(index, 83) > 0.52 ? "amber" : "cyan",
}));
const cityTrafficLanes = [
  { y: 0.21, speed: 0.028, offset: 0.07, color: "#65ffe8", width: 30, depth: 0.55 },
  { y: 0.28, speed: -0.021, offset: 0.38, color: "#9bd8ff", width: 18, depth: 0.38 },
  { y: 0.36, speed: 0.018, offset: 0.75, color: "#ff4e86", width: 24, depth: 0.45 },
  { y: 0.49, speed: -0.012, offset: 0.16, color: "#f1ba55", width: 15, depth: 0.28 },
  { y: 0.66, speed: 0.01, offset: 0.58, color: "#65ffe8", width: 11, depth: 0.22 },
];
const canvas = document.getElementById("scene-canvas");
const ctx = canvas.getContext("2d");
const stage = document.getElementById("stage");
const hotspotLayer = document.getElementById("hotspot-layer");
const roomNav = document.getElementById("room-nav");
const sceneTitle = document.getElementById("scene-title");
const objective = document.getElementById("objective");
const objectiveCopy = document.getElementById("objective-copy");
const hotspotTitle = document.getElementById("hotspot-title");
const hotspotCopy = document.getElementById("hotspot-copy");
const actionRow = document.getElementById("action-row");
const inventory = document.getElementById("inventory");
const logEl = document.getElementById("log");
const clockTime = document.getElementById("clock-time");

let viewW = 1;
let viewH = 1;
let pixelRatio = 1;

function hotspot(id, label, x, y, title, copy, actions, size = 34) {
  return { id, label, x, y, title, copy, actions, size };
}

function action(label, run) {
  return { label, run };
}

function pseudoRandom(index, salt) {
  const value = Math.sin(index * 12.9898 + salt * 78.233) * 43758.5453;
  return value - Math.floor(value);
}

function loadImage(src) {
  const image = new Image();
  image.src = src;
  return image;
}

function resizeCanvas() {
  const rect = stage.getBoundingClientRect();
  viewW = Math.max(1, Math.floor(rect.width));
  viewH = Math.max(1, Math.floor(rect.height));
  pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
  canvas.width = Math.floor(viewW * pixelRatio);
  canvas.height = Math.floor(viewH * pixelRatio);
  ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
  renderHotspots(rooms[state.scene]);
}

function render() {
  const room = rooms[state.scene];
  sceneTitle.textContent = room.title;
  objective.textContent = room.objective;
  objectiveCopy.textContent = getObjectiveCopy(room);
  renderHotspots(room);
  renderNav();
  renderInteraction();
  renderInventory();
  renderLog();
}

function getObjectiveCopy(room) {
  if (state.flags.exitUnlocked && state.scene === "entry") {
    return "La porta e pronta. L'appartamento ha finito di trattenerti.";
  }
  if (state.flags.terminalRead && state.flags.cityViewed && !state.flags.coatTaken) {
    return "Ti manca solo qualcosa contro la pioggia prima di aprire la porta.";
  }
  return room.copy;
}

function renderHotspots(room) {
  hotspotLayer.innerHTML = "";
  room.hotspots.forEach((spot) => {
    const button = document.createElement("button");
    button.className = "hotspot";
    if (spot.id === state.selectedHotspot) {
      button.classList.add("selected");
    }
    button.type = "button";
    button.style.left = `${spot.x}%`;
    button.style.top = `${spot.y}%`;
    button.style.setProperty("--hotspot-size", `${spot.size}px`);
    button.setAttribute("aria-label", spot.label);
    button.innerHTML = `<span>${spot.label}</span>`;
    button.addEventListener("click", () => selectHotspot(spot.id));
    hotspotLayer.appendChild(button);
  });
}

function renderNav() {
  roomNav.innerHTML = "";
  roomOrder.forEach((key) => {
    const room = rooms[key];
    const button = document.createElement("button");
    button.type = "button";
    button.className = "room-button";
    button.textContent = room.nav;
    if (state.scene === key) {
      button.classList.add("active");
    }
    const locked = key === "city" && !state.flags.cityViewed;
    if (locked) {
      button.classList.add("locked");
      button.title = "Prima affacciati dalla finestra del soggiorno.";
    }
    button.addEventListener("click", () => {
      if (locked) {
        addLog("La vista sulla citta si sblocca dalla finestra del soggiorno.");
        renderLog();
        return;
      }
      goToScene(key);
    });
    roomNav.appendChild(button);
  });
}

function renderInteraction() {
  const spot = getSelectedHotspot();
  actionRow.innerHTML = "";
  if (!spot) {
    hotspotTitle.textContent = "Nessun oggetto selezionato";
    hotspotCopy.textContent = "Seleziona un punto luminoso nella scena.";
    return;
  }

  hotspotTitle.textContent = spot.title;
  hotspotCopy.textContent = spot.copy;
  spot.actions.forEach((spotAction) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "action-button";
    button.textContent = spotAction.label;
    button.addEventListener("click", () => {
      spotAction.run();
      render();
    });
    actionRow.appendChild(button);
  });
}

function renderInventory() {
  inventory.innerHTML = "";
  if (state.inventory.size === 0) {
    const empty = document.createElement("span");
    empty.className = "empty";
    empty.textContent = "Vuoto";
    inventory.appendChild(empty);
    return;
  }
  state.inventory.forEach((item) => {
    const pill = document.createElement("span");
    pill.className = "item-pill";
    pill.textContent = item;
    inventory.appendChild(pill);
  });
}

function renderLog() {
  logEl.innerHTML = "";
  state.log.slice(-8).reverse().forEach((entry) => {
    const line = document.createElement("div");
    line.className = "log-entry";
    line.textContent = entry;
    logEl.appendChild(line);
  });
}

function getSelectedHotspot() {
  return rooms[state.scene].hotspots.find((spot) => spot.id === state.selectedHotspot);
}

function selectHotspot(id) {
  state.selectedHotspot = id;
  render();
}

function goToScene(scene) {
  state.scene = scene;
  state.selectedHotspot = null;
  render();
}

function addLog(text) {
  state.log.push(text);
}

function addItem(item) {
  state.inventory.add(item);
}

function updateExitState() {
  state.flags.exitUnlocked =
    state.flags.terminalRead && state.flags.cityViewed && state.flags.coatTaken;
}

function tickClock() {
  const [hour, minute] = clockTime.textContent.split(":").map(Number);
  const nextMinute = (minute + 1) % 60;
  const nextHour = nextMinute === 0 ? (hour + 1) % 24 : hour;
  clockTime.textContent = `${String(nextHour).padStart(2, "0")}:${String(nextMinute).padStart(2, "0")}`;
}

function frame(time) {
  drawScene(time / 1000);
  requestAnimationFrame(frame);
}

function drawScene(t) {
  ctx.clearRect(0, 0, viewW, viewH);
  rooms[state.scene].draw(t);
  drawFilmGrain(t);
  drawVignette();
}

function drawLiving(t) {
  if (assets.living.complete && assets.living.naturalWidth > 0) {
    drawCoverImage(assets.living, 0, 0, viewW, viewH);
    drawLivingAssetAtmosphere(t);
    return;
  }

  drawInteriorShell("#171717", "#241921", "#090b0c");
  drawWindow(viewW * 0.46, viewH * 0.11, viewW * 0.42, viewH * 0.57, t);
  drawHangingCables(t);
  drawDoor(viewW * 0.78, viewH * 0.3, viewW * 0.11, viewH * 0.42, "#151819");
  drawDesk(viewW * 0.15, viewH * 0.57, viewW * 0.32, viewH * 0.16);
  drawTerminal(viewW * 0.21, viewH * 0.42, viewW * 0.16, viewH * 0.16, t);
  drawLowSofa(viewW * 0.09, viewH * 0.73, viewW * 0.38, viewH * 0.11);
  drawFloorReflection(t, 0.42);
  drawLightBeam(viewW * 0.67, viewH * 0.15, viewW * 0.52, viewH * 0.94, "rgba(255, 78, 134, 0.12)");
}

function drawLivingAssetAtmosphere(t) {
  drawInteriorGlow(t);
  drawWindowSheen(t, viewW * 0.35, viewH * 0.11, viewW * 0.51, viewH * 0.51);
  drawTerminalBloom(t, viewW * 0.23, viewH * 0.41, viewW * 0.12);
  drawFloorWetHighlights(t);
}

function drawEntry(t) {
  if (drawAssetScene("entry", t, "entry")) {
    drawDoorStatusGlow(t, viewW * 0.54, viewH * 0.5);
    return;
  }

  drawInteriorShell("#151719", "#171316", "#08090a");
  drawLightBeam(viewW * 0.24, 0, viewW * 0.62, viewH, "rgba(101, 255, 232, 0.1)");
  drawDoor(viewW * 0.38, viewH * 0.16, viewW * 0.24, viewH * 0.63, "#101316", true);
  drawCoat(viewW * 0.18, viewH * 0.31, viewW * 0.13, viewH * 0.36);
  drawIntercom(viewW * 0.68, viewH * 0.32, viewW * 0.08, viewH * 0.18, t);
  drawBench(viewW * 0.13, viewH * 0.73, viewW * 0.34, viewH * 0.09);
  drawFloorReflection(t, 0.25);
}

function drawBedroom(t) {
  if (drawAssetScene("bedroom", t, "bedroom")) {
    drawWindowSheen(t, viewW * 0.53, viewH * 0.19, viewW * 0.23, viewH * 0.3);
    return;
  }

  drawInteriorShell("#141315", "#202024", "#08090a");
  drawWindow(viewW * 0.66, viewH * 0.15, viewW * 0.23, viewH * 0.38, t);
  drawBed(viewW * 0.17, viewH * 0.61, viewW * 0.45, viewH * 0.17);
  drawShelf(viewW * 0.13, viewH * 0.26, viewW * 0.22);
  drawPhoto(viewW * 0.19, viewH * 0.32, viewW * 0.08, viewH * 0.13);
  drawCloset(viewW * 0.69, viewH * 0.24, viewW * 0.17, viewH * 0.48);
  drawPendantLamp(viewW * 0.48, 0, t);
  drawFloorReflection(t, 0.23);
}

function drawKitchen(t) {
  if (drawAssetScene("kitchen", t, "kitchen")) {
    drawKitchenSteam(t);
    return;
  }

  drawInteriorShell("#171819", "#211817", "#080909");
  drawCabinets(viewW * 0.12, viewH * 0.2, viewW * 0.76, viewH * 0.49);
  drawCoffeeMachine(viewW * 0.19, viewH * 0.42, viewW * 0.13, viewH * 0.17, t);
  drawSink(viewW * 0.44, viewH * 0.48, viewW * 0.18, viewH * 0.08);
  drawFridge(viewW * 0.72, viewH * 0.21, viewW * 0.17, viewH * 0.48, t);
  drawRadio(viewW * 0.51, viewH * 0.52, viewW * 0.12, viewH * 0.08, t);
  drawFloorReflection(t, 0.3);
}

function drawCityView(t) {
  if (drawAnimatedCityAsset(t)) {
    return;
  }

  const bg = ctx.createLinearGradient(0, 0, 0, viewH);
  bg.addColorStop(0, "#0b1420");
  bg.addColorStop(0.45, "#11151f");
  bg.addColorStop(1, "#050607");
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, viewW, viewH);
  drawFog(t, 0.28);
  drawCityscape(0, viewH * 0.08, viewW, viewH * 0.86, t, 1.15);
  drawMegaTower(viewW * 0.43, viewH * 0.12, viewW * 0.14, viewH * 0.74, t);
  drawAerialTraffic(t);
  drawBalconyFrame();
  drawCityGlass(t);
}

function drawAnimatedCityAsset(t) {
  const asset = assets.city;
  if (!asset.complete || asset.naturalWidth <= 0) {
    return false;
  }

  const pad = Math.max(viewW, viewH) * 0.025;
  const driftX = Math.sin(t * 0.08) * pad * 0.9;
  const driftY = Math.cos(t * 0.06) * pad * 0.45;
  drawCoverImage(asset, -pad + driftX, -pad + driftY, viewW + pad * 2, viewH + pad * 2);
  drawRoomGrade(t, "city");
  drawCityWindowLife(t);
  drawCityNeonPulse(t);
  drawAnimatedFogBands(t);
  drawStreetDepthStreams(t);
  drawSearchlights(t);
  drawCityTraffic(t);
  drawCityGlass(t);
  return true;
}

function drawAssetScene(key, t, mood) {
  const asset = assets[key];
  if (!asset.complete || asset.naturalWidth <= 0) {
    return false;
  }

  drawCoverImage(asset, 0, 0, viewW, viewH);
  drawRoomGrade(t, mood);
  return true;
}

function drawRoomGrade(t, mood) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";

  const cyan = ctx.createRadialGradient(viewW * 0.24, viewH * 0.45, 6, viewW * 0.24, viewH * 0.45, viewW * 0.42);
  cyan.addColorStop(0, "rgba(101,255,232,0.055)");
  cyan.addColorStop(1, "rgba(101,255,232,0)");
  ctx.fillStyle = cyan;
  ctx.fillRect(0, 0, viewW, viewH);

  const magenta = ctx.createRadialGradient(viewW * 0.78, viewH * 0.46, 8, viewW * 0.78, viewH * 0.46, viewW * 0.38);
  magenta.addColorStop(0, mood === "city" ? "rgba(255,78,134,0.08)" : "rgba(255,78,134,0.04)");
  magenta.addColorStop(1, "rgba(255,78,134,0)");
  ctx.fillStyle = magenta;
  ctx.fillRect(0, 0, viewW, viewH);
  ctx.restore();

  if (mood !== "city") {
    const calm = ctx.createLinearGradient(0, 0, 0, viewH);
    calm.addColorStop(0, "rgba(0,0,0,0.02)");
    calm.addColorStop(0.7, "rgba(0,0,0,0)");
    calm.addColorStop(1, "rgba(0,0,0,0.18)");
    ctx.fillStyle = calm;
    ctx.fillRect(0, 0, viewW, viewH);
  }
}

function drawDoorStatusGlow(t, x, y) {
  const base = state.flags.exitUnlocked ? "rgba(156,240,125," : "rgba(241,186,85,";
  const glow = ctx.createRadialGradient(x, y, 2, x, y, viewW * 0.07);
  glow.addColorStop(0, `${base}${0.16 + Math.sin(t * 3) * 0.03})`);
  glow.addColorStop(1, `${base}0)`);
  ctx.fillStyle = glow;
  ctx.fillRect(x - viewW * 0.08, y - viewW * 0.08, viewW * 0.16, viewW * 0.16);
}

function drawKitchenSteam(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  for (let i = 0; i < 3; i += 1) {
    const x = viewW * (0.14 + i * 0.025);
    const y = viewH * (0.34 - Math.sin(t * 1.8 + i) * 0.012);
    const steam = ctx.createRadialGradient(x, y, 2, x, y, viewW * 0.05);
    steam.addColorStop(0, "rgba(226,255,250,0.09)");
    steam.addColorStop(1, "rgba(226,255,250,0)");
    ctx.fillStyle = steam;
    ctx.fillRect(x - viewW * 0.06, y - viewH * 0.09, viewW * 0.12, viewH * 0.16);
  }
  ctx.restore();
}

function drawCityGlass(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  const glare = ctx.createLinearGradient(0, 0, viewW, viewH);
  glare.addColorStop(0, "rgba(255,78,134,0.04)");
  glare.addColorStop(0.45, "rgba(255,255,255,0.035)");
  glare.addColorStop(1, "rgba(101,255,232,0.035)");
  ctx.fillStyle = glare;
  ctx.fillRect(0, 0, viewW, viewH);

  for (let i = 0; i < 14; i += 1) {
    const x = (i / 13) * viewW + Math.sin(t * 0.3 + i) * 7;
    line(x, 0, x - viewW * 0.04, viewH, "rgba(220,255,252,0.035)", 1);
  }
  ctx.restore();
}

function drawCityNeonPulse(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";

  const tower = ctx.createRadialGradient(viewW * 0.48, viewH * 0.42, 10, viewW * 0.48, viewH * 0.42, viewW * 0.18);
  tower.addColorStop(0, `rgba(101,255,232,${0.1 + Math.sin(t * 1.4) * 0.035})`);
  tower.addColorStop(1, "rgba(101,255,232,0)");
  ctx.fillStyle = tower;
  ctx.fillRect(viewW * 0.25, viewH * 0.08, viewW * 0.45, viewH * 0.68);

  const magenta = ctx.createRadialGradient(viewW * 0.86, viewH * 0.28, 10, viewW * 0.86, viewH * 0.28, viewW * 0.22);
  magenta.addColorStop(0, `rgba(255,78,134,${0.08 + Math.sin(t * 1.9 + 1.4) * 0.03})`);
  magenta.addColorStop(1, "rgba(255,78,134,0)");
  ctx.fillStyle = magenta;
  ctx.fillRect(viewW * 0.62, 0, viewW * 0.38, viewH * 0.52);

  ctx.restore();
}

function drawCityWindowLife(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  cityWindows.forEach((light, index) => {
    const wave = Math.sin(t * light.speed + light.phase);
    const blink = Math.sin(t * (0.18 + (index % 7) * 0.03) + light.phase * 0.31) > 0.86 ? 0.1 : 1;
    const alpha = Math.max(0, 0.035 + wave * 0.045) * blink;
    const color =
      light.color === "pink"
        ? `rgba(255,78,134,${alpha})`
        : light.color === "amber"
          ? `rgba(241,186,85,${alpha * 0.8})`
          : `rgba(101,255,232,${alpha})`;
    ctx.fillStyle = color;
    ctx.fillRect(light.x * viewW, light.y * viewH, light.w * viewW, light.h * viewH);
  });
  ctx.restore();
}

function drawAnimatedFogBands(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  for (let i = 0; i < 4; i += 1) {
    const y = viewH * (0.3 + i * 0.12);
    const xShift = Math.sin(t * 0.12 + i * 1.7) * viewW * 0.05;
    const fog = ctx.createLinearGradient(-viewW * 0.15 + xShift, y, viewW * 1.1 + xShift, y);
    fog.addColorStop(0, "rgba(210,245,241,0)");
    fog.addColorStop(0.45, `rgba(210,245,241,${0.035 + i * 0.012})`);
    fog.addColorStop(1, "rgba(210,245,241,0)");
    ctx.fillStyle = fog;
    ctx.fillRect(-viewW * 0.15 + xShift, y, viewW * 1.3, viewH * (0.045 + i * 0.008));
  }
  ctx.restore();
}

function drawCityTraffic(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  cityTrafficLanes.forEach((lane, index) => {
    const cycle = ((t * lane.speed + lane.offset) % 1 + 1) % 1;
    const x = cycle * (viewW + lane.width * 2) - lane.width;
    const y = viewH * lane.y + Math.sin(t * 0.6 + index) * viewH * 0.004;
    shadowBlur(10 + lane.depth * 18, lane.color);
    ctx.fillStyle = lane.color;
    roundedRect(x, y, lane.width, 2 + lane.depth * 4, 4);
    ctx.fill();
    ctx.fillStyle = "rgba(255,255,255,0.35)";
    roundedRect(x + lane.width * 0.72, y, lane.width * 0.2, 1 + lane.depth * 2, 3);
    ctx.fill();
    shadowBlur(0);
  });
  ctx.restore();
}

function drawStreetDepthStreams(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  const lanes = [
    { x1: 0.19, y1: 0.72, x2: 0.34, y2: 0.47, color: "rgba(241,186,85,", phase: 0 },
    { x1: 0.32, y1: 0.77, x2: 0.47, y2: 0.55, color: "rgba(101,255,232,", phase: 1.2 },
    { x1: 0.68, y1: 0.72, x2: 0.56, y2: 0.52, color: "rgba(255,78,134,", phase: 2.4 },
  ];

  lanes.forEach((lane) => {
    for (let i = 0; i < 9; i += 1) {
      const p = ((t * 0.08 + lane.phase + i * 0.13) % 1 + 1) % 1;
      const x = lerp(lane.x1, lane.x2, p) * viewW;
      const y = lerp(lane.y1, lane.y2, p) * viewH;
      const size = lerp(8, 2, p);
      ctx.fillStyle = `${lane.color}${lerp(0.11, 0.02, p)})`;
      shadowBlur(size * 2.2, ctx.fillStyle);
      roundedRect(x, y, size, Math.max(1.5, size * 0.33), 4);
      ctx.fill();
      shadowBlur(0);
    }
  });
  ctx.restore();
}

function drawSearchlights(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  const lights = [
    { x: 0.77, y: 0.16, angle: Math.sin(t * 0.23) * 0.14 + 1.95, length: 0.34 },
    { x: 0.5, y: 0.18, angle: Math.sin(t * 0.18 + 1.7) * 0.16 + 2.65, length: 0.25 },
  ];

  lights.forEach((light) => {
    const baseX = light.x * viewW;
    const baseY = light.y * viewH;
    const len = light.length * viewW;
    const spread = 0.08;
    const x1 = baseX + Math.cos(light.angle - spread) * len;
    const y1 = baseY + Math.sin(light.angle - spread) * len;
    const x2 = baseX + Math.cos(light.angle + spread) * len;
    const y2 = baseY + Math.sin(light.angle + spread) * len;
    const beam = ctx.createLinearGradient(baseX, baseY, (x1 + x2) * 0.5, (y1 + y2) * 0.5);
    beam.addColorStop(0, "rgba(155,216,255,0.12)");
    beam.addColorStop(1, "rgba(155,216,255,0)");
    ctx.fillStyle = beam;
    polygon([[baseX, baseY], [x1, y1], [x2, y2]]);
  });
  ctx.restore();
}

function lerp(a, b, p) {
  return a + (b - a) * p;
}

function drawInteriorShell(wallA, wallB, floorColor) {
  const wall = ctx.createLinearGradient(0, 0, viewW, viewH);
  wall.addColorStop(0, wallA);
  wall.addColorStop(0.5, "#111416");
  wall.addColorStop(1, wallB);
  ctx.fillStyle = wall;
  ctx.fillRect(0, 0, viewW, viewH);

  ctx.fillStyle = "rgba(255,255,255,0.035)";
  for (let i = 0; i < 9; i += 1) {
    const x = (i / 8) * viewW;
    line(x, 0, viewW * 0.5 + (x - viewW * 0.5) * 0.25, viewH * 0.63, "rgba(255,255,255,0.035)", 1);
  }

  const floorY = viewH * 0.64;
  const floor = ctx.createLinearGradient(0, floorY, 0, viewH);
  floor.addColorStop(0, "#191615");
  floor.addColorStop(1, floorColor);
  ctx.fillStyle = floor;
  polygon([
    [0, floorY],
    [viewW, floorY * 0.98],
    [viewW, viewH],
    [0, viewH],
  ]);

  for (let i = 0; i < 12; i += 1) {
    const p = i / 11;
    line(viewW * p, viewH, viewW * (0.5 + (p - 0.5) * 0.32), floorY, "rgba(255,255,255,0.045)", 1);
  }
  for (let i = 0; i < 7; i += 1) {
    const y = floorY + i * viewH * 0.06;
    line(0, y, viewW, y - i * 4, "rgba(255,255,255,0.025)", 1);
  }
}

function drawCoverImage(image, x, y, w, h) {
  const imageRatio = image.naturalWidth / image.naturalHeight;
  const targetRatio = w / h;
  let sx = 0;
  let sy = 0;
  let sw = image.naturalWidth;
  let sh = image.naturalHeight;

  if (imageRatio > targetRatio) {
    sw = image.naturalHeight * targetRatio;
    sx = (image.naturalWidth - sw) * 0.5;
  } else {
    sh = image.naturalWidth / targetRatio;
    sy = (image.naturalHeight - sh) * 0.5;
  }

  ctx.drawImage(image, sx, sy, sw, sh, x, y, w, h);
}

function drawInteriorGlow(t) {
  const cyan = ctx.createRadialGradient(viewW * 0.23, viewH * 0.42, 8, viewW * 0.23, viewH * 0.42, viewW * 0.3);
  cyan.addColorStop(0, `rgba(101,255,232,${0.12 + Math.sin(t * 2.2) * 0.025})`);
  cyan.addColorStop(1, "rgba(101,255,232,0)");
  ctx.fillStyle = cyan;
  ctx.fillRect(0, 0, viewW * 0.55, viewH);

  const amber = ctx.createRadialGradient(viewW * 0.91, viewH * 0.11, 6, viewW * 0.91, viewH * 0.11, viewW * 0.22);
  amber.addColorStop(0, "rgba(241,186,85,0.12)");
  amber.addColorStop(1, "rgba(241,186,85,0)");
  ctx.fillStyle = amber;
  ctx.fillRect(viewW * 0.66, 0, viewW * 0.34, viewH * 0.45);
}

function drawWindowSheen(t, x, y, w, h) {
  ctx.save();
  ctx.beginPath();
  ctx.rect(x, y, w, h);
  ctx.clip();
  const glare = ctx.createLinearGradient(x, y, x + w, y + h);
  glare.addColorStop(0, "rgba(255,255,255,0)");
  glare.addColorStop(0.48, `rgba(255,255,255,${0.035 + Math.sin(t * 0.8) * 0.01})`);
  glare.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = glare;
  ctx.fillRect(x, y, w, h);
  ctx.restore();
}

function drawTerminalBloom(t, x, y, radius) {
  const bloom = ctx.createRadialGradient(x, y, 1, x, y, radius);
  bloom.addColorStop(0, `rgba(101,255,232,${0.14 + Math.sin(t * 3) * 0.03})`);
  bloom.addColorStop(0.5, "rgba(101,255,232,0.055)");
  bloom.addColorStop(1, "rgba(101,255,232,0)");
  ctx.fillStyle = bloom;
  ctx.fillRect(x - radius, y - radius, radius * 2, radius * 2);
}

function drawFloorWetHighlights(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  for (let i = 0; i < 5; i += 1) {
    const x = viewW * (0.42 + i * 0.08);
    const y = viewH * (0.72 + i * 0.032);
    const glow = ctx.createLinearGradient(x - viewW * 0.08, y, x + viewW * 0.12, y);
    glow.addColorStop(0, "rgba(101,255,232,0)");
    glow.addColorStop(0.5, i % 2 ? "rgba(255,78,134,0.09)" : "rgba(101,255,232,0.08)");
    glow.addColorStop(1, "rgba(101,255,232,0)");
    ctx.fillStyle = glow;
    ctx.fillRect(x - viewW * 0.08, y + Math.sin(t + i) * 1.5, viewW * 0.2, 2);
  }
  ctx.restore();
}

function drawWindow(x, y, w, h, t) {
  shadowBlur(34, "rgba(101,255,232,0.12)");
  panel(x, y, w, h, "#061017", "rgba(143,210,211,0.26)", 2);
  shadowBlur(0);

  ctx.save();
  ctx.beginPath();
  ctx.rect(x + 5, y + 5, w - 10, h - 10);
  ctx.clip();
  drawCityscape(x, y, w, h, t, 0.72);
  drawFog(t, 0.17, x, y, w, h);
  ctx.restore();

  line(x + w * 0.5, y + 5, x + w * 0.5, y + h - 5, "rgba(198,235,234,0.2)", 2);
  line(x + 5, y + h * 0.64, x + w - 5, y + h * 0.64, "rgba(198,235,234,0.16)", 2);
  line(x, y, x + w, y, "rgba(255,255,255,0.1)", 1);
}

function drawCityscape(x, y, w, h, t, scale = 1) {
  const sky = ctx.createLinearGradient(0, y, 0, y + h);
  sky.addColorStop(0, "#07121e");
  sky.addColorStop(0.62, "#111926");
  sky.addColorStop(1, "#030506");
  ctx.fillStyle = sky;
  ctx.fillRect(x, y, w, h);

  const buildings = [
    [0.03, 0.34, 0.13], [0.18, 0.58, 0.11], [0.31, 0.46, 0.16],
    [0.51, 0.78, 0.13], [0.67, 0.52, 0.18], [0.88, 0.66, 0.12],
  ];
  buildings.forEach(([bx, bh, bw], index) => {
    const px = x + bx * w;
    const pw = bw * w * scale;
    const ph = bh * h;
    const py = y + h - ph;
    const grad = ctx.createLinearGradient(px, py, px + pw, py + ph);
    grad.addColorStop(0, index % 2 ? "#121923" : "#0d141d");
    grad.addColorStop(1, "#06090d");
    ctx.fillStyle = grad;
    ctx.fillRect(px, py, pw, ph);
    for (let row = 0; row < 18; row += 1) {
      const wy = py + 12 + row * 15 * scale;
      if (wy > y + h - 8) continue;
      for (let col = 0; col < 4; col += 1) {
        const lit = ((row * 7 + col * 11 + index) % 5) < 2;
        ctx.fillStyle = lit ? (index % 2 ? "rgba(255,78,134,0.45)" : "rgba(101,255,232,0.38)") : "rgba(255,255,255,0.035)";
        ctx.fillRect(px + 9 + col * pw * 0.2, wy, Math.max(3, pw * 0.1), 2.2);
      }
    }
  });

  const glowX = x + w * (0.67 + Math.sin(t * 0.4) * 0.03);
  const glow = ctx.createRadialGradient(glowX, y + h * 0.25, 1, glowX, y + h * 0.25, w * 0.22);
  glow.addColorStop(0, "rgba(255,78,134,0.36)");
  glow.addColorStop(1, "rgba(255,78,134,0)");
  ctx.fillStyle = glow;
  ctx.fillRect(x, y, w, h);
}

function drawMegaTower(x, y, w, h, t) {
  panel(x, y, w, h, "#0d1219", "rgba(101,255,232,0.18)", 1);
  const glow = ctx.createLinearGradient(x, y, x + w, y);
  glow.addColorStop(0, "rgba(101,255,232,0)");
  glow.addColorStop(0.5, "rgba(101,255,232,0.18)");
  glow.addColorStop(1, "rgba(255,78,134,0)");
  ctx.fillStyle = glow;
  ctx.fillRect(x, y, w, h);

  ctx.save();
  ctx.translate(x + w * 0.5, y + h * 0.22);
  ctx.rotate(Math.PI / 2);
  ctx.font = `${Math.max(28, w * 0.42)}px Inter, sans-serif`;
  ctx.fillStyle = `rgba(255,78,134,${0.76 + Math.sin(t * 4) * 0.12})`;
  ctx.shadowColor = "#ff4e86";
  ctx.shadowBlur = 22;
  ctx.textAlign = "center";
  ctx.fillText("ORA", 0, 8);
  ctx.restore();

  shadowBlur(0);
  for (let i = 0; i < 28; i += 1) {
    ctx.fillStyle = i % 2 ? "rgba(101,255,232,0.22)" : "rgba(255,78,134,0.19)";
    ctx.fillRect(x + w * 0.13, y + h * 0.38 + i * h * 0.019, w * 0.72, 2);
  }
}

function drawDesk(x, y, w, h) {
  panel(x, y, w, h, "#272b2b", "rgba(255,255,255,0.1)", 1);
  ctx.fillStyle = "rgba(101,255,232,0.08)";
  ctx.fillRect(x + w * 0.05, y + h * 0.12, w * 0.9, h * 0.14);
  panel(x + w * 0.1, y + h * 0.72, w * 0.16, h * 1.45, "#101313", "rgba(255,255,255,0.05)", 1);
  panel(x + w * 0.76, y + h * 0.72, w * 0.16, h * 1.45, "#101313", "rgba(255,255,255,0.05)", 1);
}

function drawTerminal(x, y, w, h, t) {
  shadowBlur(28, "rgba(101,255,232,0.28)");
  panel(x, y, w, h, "#071111", "rgba(101,255,232,0.55)", 1.4);
  shadowBlur(0);
  ctx.fillStyle = "rgba(101,255,232,0.22)";
  ctx.fillRect(x + w * 0.12, y + h * 0.15, w * 0.76, h * 0.52);
  for (let i = 0; i < 6; i += 1) {
    ctx.fillStyle = i === 1 ? "rgba(255,78,134,0.55)" : "rgba(226,255,250,0.42)";
    ctx.fillRect(x + w * 0.18, y + h * (0.22 + i * 0.075), w * (0.52 + Math.sin(t + i) * 0.12), 2);
  }
  ctx.fillStyle = "rgba(0,0,0,0.35)";
  ctx.fillRect(x + w * 0.1, y + h * 0.73, w * 0.8, h * 0.12);
}

function drawDoor(x, y, w, h, color, main = false) {
  panel(x, y, w, h, color, "rgba(176,210,205,0.16)", 2);
  line(x + w * 0.22, y, x + w * 0.22, y + h, "rgba(255,255,255,0.05)", 1);
  line(x + w * 0.78, y, x + w * 0.78, y + h, "rgba(0,0,0,0.32)", 2);
  const led = main && state.flags.exitUnlocked ? "rgba(156,240,125,0.95)" : "rgba(241,186,85,0.9)";
  shadowBlur(14, led);
  ctx.fillStyle = led;
  circle(x + w * 0.78, y + h * 0.52, Math.max(4, w * 0.035));
  shadowBlur(0);
}

function drawLowSofa(x, y, w, h) {
  panel(x, y, w, h, "#222727", "rgba(255,255,255,0.07)", 1);
  panel(x + w * 0.08, y - h * 0.38, w * 0.48, h * 0.44, "#333a3a", "rgba(255,255,255,0.07)", 1);
  panel(x + w * 0.6, y - h * 0.18, w * 0.3, h * 0.26, "#303637", "rgba(255,255,255,0.06)", 1);
}

function drawCoat(x, y, w, h) {
  line(x + w * 0.5, y - h * 0.2, x + w * 0.5, y, "rgba(255,255,255,0.18)", 2);
  const coat = ctx.createLinearGradient(x, y, x + w, y + h);
  coat.addColorStop(0, "#182023");
  coat.addColorStop(0.5, "#0b0f11");
  coat.addColorStop(1, "#20242b");
  ctx.fillStyle = coat;
  polygon([
    [x + w * 0.34, y],
    [x + w * 0.66, y],
    [x + w, y + h],
    [x + w * 0.58, y + h * 0.93],
    [x + w * 0.5, y + h * 0.35],
    [x + w * 0.42, y + h * 0.93],
    [x, y + h],
  ]);
  line(x + w * 0.5, y + h * 0.12, x + w * 0.5, y + h * 0.88, "rgba(101,255,232,0.12)", 1);
}

function drawIntercom(x, y, w, h, t) {
  panel(x, y, w, h, "#101416", "rgba(176,210,205,0.16)", 1);
  ctx.fillStyle = "rgba(101,255,232,0.18)";
  ctx.fillRect(x + w * 0.18, y + h * 0.16, w * 0.64, h * 0.24);
  shadowBlur(10, "#ff4e86");
  ctx.fillStyle = `rgba(255,78,134,${0.4 + Math.sin(t * 5) * 0.2})`;
  circle(x + w * 0.5, y + h * 0.7, w * 0.12);
  shadowBlur(0);
}

function drawBench(x, y, w, h) {
  panel(x, y, w, h, "#252929", "rgba(255,255,255,0.06)", 1);
  panel(x + w * 0.08, y + h * 0.9, w * 0.08, h * 1.2, "#101313", "rgba(255,255,255,0.04)", 1);
  panel(x + w * 0.84, y + h * 0.9, w * 0.08, h * 1.2, "#101313", "rgba(255,255,255,0.04)", 1);
}

function drawBed(x, y, w, h) {
  panel(x, y, w, h, "#293033", "rgba(255,255,255,0.08)", 1);
  panel(x + w * 0.05, y - h * 0.4, w * 0.32, h * 0.48, "#394147", "rgba(255,255,255,0.08)", 1);
  const blanket = ctx.createLinearGradient(x, y, x + w, y + h);
  blanket.addColorStop(0, "rgba(255,78,134,0.2)");
  blanket.addColorStop(1, "rgba(101,255,232,0.06)");
  ctx.fillStyle = blanket;
  polygon([[x + w * 0.28, y], [x + w, y + h * 0.18], [x + w * 0.92, y + h], [x + w * 0.18, y + h]]);
}

function drawShelf(x, y, w) {
  panel(x, y, w, 7, "#323737", "rgba(255,255,255,0.07)", 1);
  for (let i = 0; i < 5; i += 1) {
    panel(x + 10 + i * w * 0.14, y - 28, w * 0.08, 28, i % 2 ? "#222a2c" : "#2e2429", "rgba(255,255,255,0.04)", 1);
  }
}

function drawPhoto(x, y, w, h) {
  panel(x, y, w, h, "#141616", "rgba(255,255,255,0.16)", 3);
  const photo = ctx.createLinearGradient(x, y, x + w, y + h);
  photo.addColorStop(0, "rgba(255,78,134,0.46)");
  photo.addColorStop(1, "rgba(101,255,232,0.22)");
  ctx.fillStyle = photo;
  ctx.fillRect(x + w * 0.12, y + h * 0.12, w * 0.76, h * 0.76);
  ctx.fillStyle = "rgba(255,255,255,0.5)";
  circle(x + w * 0.48, y + h * 0.34, w * 0.07);
}

function drawCloset(x, y, w, h) {
  panel(x, y, w, h, "#171b1d", "rgba(176,210,205,0.14)", 1);
  line(x + w * 0.5, y, x + w * 0.5, y + h, "rgba(255,255,255,0.06)", 1);
  ctx.fillStyle = "rgba(241,186,85,0.7)";
  circle(x + w * 0.45, y + h * 0.48, 3);
  circle(x + w * 0.55, y + h * 0.48, 3);
}

function drawPendantLamp(x, y, t) {
  line(x, y, x, viewH * 0.2, "rgba(176,210,205,0.18)", 2);
  shadowBlur(30, "rgba(101,255,232,0.4)");
  ctx.fillStyle = `rgba(101,255,232,${0.68 + Math.sin(t * 2) * 0.08})`;
  roundedRect(x - 42, viewH * 0.2, 84, 13, 9);
  ctx.fill();
  shadowBlur(0);
}

function drawCabinets(x, y, w, h) {
  panel(x, y + h * 0.48, w, h * 0.28, "#1c1f20", "rgba(255,255,255,0.08)", 1);
  for (let i = 0; i < 5; i += 1) {
    panel(x + i * w * 0.2, y, w * 0.18, h * 0.3, "#171a1c", "rgba(176,210,205,0.12)", 1);
  }
  ctx.fillStyle = "rgba(241,186,85,0.08)";
  ctx.fillRect(x, y + h * 0.46, w, h * 0.04);
}

function drawCoffeeMachine(x, y, w, h, t) {
  panel(x, y, w, h, "#111719", "rgba(101,255,232,0.2)", 1);
  ctx.fillStyle = "rgba(101,255,232,0.2)";
  ctx.fillRect(x + w * 0.2, y + h * 0.2, w * 0.6, h * 0.22);
  for (let i = 0; i < 3; i += 1) {
    const sx = x + w * (0.36 + i * 0.08);
    const steam = ctx.createRadialGradient(sx, y - h * 0.1 - Math.sin(t * 2 + i) * 8, 1, sx, y - h * 0.1, 36);
    steam.addColorStop(0, "rgba(226,255,250,0.16)");
    steam.addColorStop(1, "rgba(226,255,250,0)");
    ctx.fillStyle = steam;
    ctx.fillRect(sx - 36, y - h * 0.55, 72, h * 0.6);
  }
}

function drawSink(x, y, w, h) {
  panel(x, y, w, h, "#293033", "rgba(255,255,255,0.08)", 1);
  ctx.strokeStyle = "rgba(176,210,205,0.22)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(x + w * 0.5, y + h * 0.3, w * 0.32, 0, Math.PI);
  ctx.stroke();
  line(x + w * 0.5, y - h * 0.6, x + w * 0.5, y, "rgba(176,210,205,0.22)", 3);
}

function drawFridge(x, y, w, h, t) {
  panel(x, y, w, h, "#15191b", "rgba(176,210,205,0.14)", 1);
  line(x, y + h * 0.38, x + w, y + h * 0.38, "rgba(255,255,255,0.06)", 1);
  shadowBlur(13, "#9cf07d");
  ctx.fillStyle = `rgba(156,240,125,${0.38 + Math.sin(t * 3) * 0.08})`;
  ctx.fillRect(x + w * 0.13, y + h * 0.1, w * 0.34, h * 0.05);
  shadowBlur(0);
}

function drawRadio(x, y, w, h, t) {
  panel(x, y, w, h, "#141819", "rgba(255,255,255,0.1)", 1);
  for (let i = 0; i < 5; i += 1) {
    line(x + w * 0.18, y + h * (0.25 + i * 0.12), x + w * 0.65, y + h * (0.25 + i * 0.12), "rgba(176,210,205,0.28)", 1);
  }
  ctx.fillStyle = `rgba(255,78,134,${0.45 + Math.sin(t * 8) * 0.18})`;
  circle(x + w * 0.8, y + h * 0.52, h * 0.16);
}

function drawHangingCables(t) {
  for (let i = 0; i < 4; i += 1) {
    const x = viewW * (0.16 + i * 0.08);
    line(x, 0, x + Math.sin(t + i) * 6, viewH * (0.2 + i * 0.06), "rgba(0,0,0,0.45)", 2);
  }
}

function drawFloorReflection(t, strength) {
  const glow = ctx.createRadialGradient(viewW * 0.58, viewH * 0.83, 10, viewW * 0.58, viewH * 0.83, viewW * 0.42);
  glow.addColorStop(0, `rgba(255,78,134,${strength * 0.32})`);
  glow.addColorStop(0.42, `rgba(101,255,232,${strength * 0.18})`);
  glow.addColorStop(1, "rgba(0,0,0,0)");
  ctx.fillStyle = glow;
  ctx.fillRect(0, viewH * 0.58, viewW, viewH * 0.42);

  for (let i = 0; i < 5; i += 1) {
    ctx.fillStyle = `rgba(101,255,232,${0.04 + i * 0.01})`;
    ctx.fillRect(viewW * (0.42 + i * 0.04), viewH * (0.7 + i * 0.035), viewW * 0.18, 2);
  }
}

function drawLightBeam(x1, y1, x2, y2, color) {
  const beam = ctx.createLinearGradient(x1, y1, x2, y2);
  beam.addColorStop(0, color);
  beam.addColorStop(0.55, "rgba(255,255,255,0.025)");
  beam.addColorStop(1, "rgba(255,255,255,0)");
  ctx.fillStyle = beam;
  polygon([
    [x1 - viewW * 0.09, y1],
    [x1 + viewW * 0.08, y1],
    [x2 + viewW * 0.16, y2],
    [x2 - viewW * 0.12, y2],
  ]);
}

function drawFog(t, alpha, x = 0, y = 0, w = viewW, h = viewH) {
  for (let i = 0; i < 3; i += 1) {
    const fy = y + h * (0.18 + i * 0.18);
    const fog = ctx.createLinearGradient(x, fy, x + w, fy);
    fog.addColorStop(0, "rgba(255,255,255,0)");
    fog.addColorStop(0.5, `rgba(185,226,224,${alpha * (0.4 + i * 0.15)})`);
    fog.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = fog;
    ctx.save();
    ctx.translate(Math.sin(t * 0.2 + i) * w * 0.06, 0);
    ctx.fillRect(x - w * 0.1, fy, w * 1.2, h * 0.08);
    ctx.restore();
  }
}

function drawAerialTraffic(t) {
  const lanes = [
    [0.24, 0.22, "#65ffe8", -0.1],
    [0.57, 0.48, "#ff4e86", 0.4],
    [0.76, 0.3, "#f1ba55", 0.75],
  ];
  lanes.forEach(([y, speed, color, offset]) => {
    const x = ((t * speed + offset) % 1.25) * viewW - viewW * 0.15;
    shadowBlur(18, color);
    ctx.fillStyle = color;
    roundedRect(x, viewH * y, 34, 5, 5);
    ctx.fill();
    shadowBlur(0);
  });
}

function drawBalconyFrame() {
  line(viewW * 0.09, 0, viewW * 0.16, viewH, "rgba(209,237,234,0.16)", 3);
  line(viewW * 0.91, 0, viewW * 0.84, viewH, "rgba(209,237,234,0.16)", 3);
  line(0, viewH * 0.86, viewW, viewH * 0.82, "rgba(209,237,234,0.2)", 3);
}

function drawFilmGrain(t) {
  ctx.save();
  ctx.globalCompositeOperation = "screen";
  for (let i = 0; i < 85; i += 1) {
    const x = (Math.sin(i * 19.17 + t * 0.7) * 0.5 + 0.5) * viewW;
    const y = (Math.sin(i * 31.91 + t * 0.53) * 0.5 + 0.5) * viewH;
    ctx.fillStyle = i % 3 === 0 ? "rgba(255,255,255,0.018)" : "rgba(101,255,232,0.012)";
    ctx.fillRect(x, y, 1.4, 1.4);
  }
  ctx.restore();
}

function drawVignette() {
  const vignette = ctx.createRadialGradient(viewW * 0.52, viewH * 0.42, viewW * 0.18, viewW * 0.52, viewH * 0.42, viewW * 0.72);
  vignette.addColorStop(0, "rgba(0,0,0,0)");
  vignette.addColorStop(0.58, "rgba(0,0,0,0.08)");
  vignette.addColorStop(1, "rgba(0,0,0,0.68)");
  ctx.fillStyle = vignette;
  ctx.fillRect(0, 0, viewW, viewH);
}

function panel(x, y, w, h, fill, stroke, width = 1) {
  ctx.fillStyle = fill;
  ctx.fillRect(x, y, w, h);
  ctx.strokeStyle = stroke;
  ctx.lineWidth = width;
  ctx.strokeRect(x, y, w, h);
}

function polygon(points) {
  ctx.beginPath();
  points.forEach(([x, y], index) => {
    if (index === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  });
  ctx.closePath();
  ctx.fill();
}

function line(x1, y1, x2, y2, color, width = 1) {
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.beginPath();
  ctx.moveTo(x1, y1);
  ctx.lineTo(x2, y2);
  ctx.stroke();
}

function circle(x, y, radius) {
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.fill();
}

function roundedRect(x, y, w, h, r) {
  const radius = Math.min(r, w * 0.5, h * 0.5);
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + w - radius, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + radius);
  ctx.lineTo(x + w, y + h - radius);
  ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h);
  ctx.lineTo(x + radius, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

function shadowBlur(blur, color = "transparent") {
  ctx.shadowBlur = blur;
  ctx.shadowColor = color;
}

window.addEventListener("resize", resizeCanvas);
resizeCanvas();
render();
setInterval(tickClock, 9000);
requestAnimationFrame(frame);
