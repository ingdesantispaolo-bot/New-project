import type {
  DifficultyPreset,
  GeneratedRobotPuzzle,
  GridCommand,
  GridFacing,
  RobotChallengeType,
  RobotCheckpoint,
} from "../ProceduralTypes";
import type { Random } from "../Random";
import { GridPathSolver } from "../solvers/GridPathSolver";

type Cell = { col: number; row: number };
type RouteState = Cell & { facing: GridFacing };

export class RobotGridGenerator {
  private solver = new GridPathSolver();

  generate(random: Random, difficulty: DifficultyPreset, preferredType?: RobotChallengeType): GeneratedRobotPuzzle {
    const cols = difficulty.robotGrid.cols;
    const rows = difficulty.robotGrid.rows;
    const challengeType = preferredType ?? this.pickChallengeType(random, difficulty);
    const minimumPathLength = 5 + difficulty.requiredReasoningSteps * 2 + (challengeType === "minimal-route" ? 2 : 0);

    for (let attempt = 0; attempt < 24; attempt += 1) {
      const layout = this.buildLayout(random.fork(`layout-${attempt}`), cols, rows, challengeType);
      const obstacles = this.buildObstacles(
        random.fork(`obstacles-${attempt}`),
        cols,
        rows,
        difficulty.robotObstacleCount,
        [layout.start, layout.key, layout.exit, ...layout.checkpoints],
      );
      const solutionCommands = this.solveRoute(cols, rows, layout.start, layout.key, layout.exit, obstacles, layout.checkpoints);
      if (!solutionCommands) {
        continue;
      }
      const enoughDepth = solutionCommands.length >= minimumPathLength || attempt >= 18;
      const enoughTurns = solutionCommands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length >= Math.min(4, difficulty.requiredReasoningSteps);
      if (enoughDepth && (enoughTurns || challengeType === "route-planning" || challengeType === "coordinate-routing")) {
        return this.buildPuzzle(cols, rows, layout.start, layout.key, layout.exit, obstacles, solutionCommands, difficulty, challengeType, layout.checkpoints, random);
      }
    }

    return this.fallback(challengeType, random.fork("fallback-layout"));
  }

  private pickChallengeType(random: Random, difficulty: DifficultyPreset): RobotChallengeType {
    if (difficulty.level <= 2) {
      return random.pick(["route-planning", "minimal-route", "coordinate-routing"]);
    }
    if (difficulty.level <= 4) {
      return random.pick(["minimal-route", "checkpoint-order", "coordinate-routing", "debug-program"]);
    }
    if (difficulty.level <= 6) {
      return random.pick(["checkpoint-order", "debug-program", "pattern-routing", "conditional-gate", "minimal-route"]);
    }
    return random.pick(["debug-program", "pattern-routing", "loop-compression", "conditional-gate", "minimal-route", "coordinate-routing"]);
  }

  private buildLayout(random: Random, cols: number, rows: number, type: RobotChallengeType): {
    start: RouteState;
    key: Cell;
    exit: Cell;
    checkpoints: RobotCheckpoint[];
  } {
    const start: RouteState = { col: 0, row: rows - 1, facing: random.pick(["N", "E"] satisfies GridFacing[]) };
    const exit = { col: cols - 1, row: rows - 1 };
    const key = this.uniqueCell(
      { col: random.integer(Math.max(2, Math.floor(cols / 2)), cols - 1), row: random.integer(0, Math.max(1, Math.floor(rows / 2))) },
      cols,
      rows,
      [start, exit],
    );
    const checkpoints = this.checkpointsFor(random, cols, rows, type, [start, key, exit]);
    return { start, key, exit, checkpoints };
  }

  private checkpointsFor(
    random: Random,
    cols: number,
    rows: number,
    type: RobotChallengeType,
    reserved: Cell[],
  ): RobotCheckpoint[] {
    if (type === "checkpoint-order") {
      const first = this.uniqueCell({ col: random.integer(1, Math.max(1, Math.floor(cols / 2))), row: random.integer(0, rows - 2) }, cols, rows, reserved);
      return [{ ...first, label: "A", order: 1 }];
    }
    if (type === "conditional-gate") {
      const first = this.uniqueCell({ col: random.integer(1, Math.max(1, Math.floor(cols / 2))), row: random.integer(0, rows - 2) }, cols, rows, reserved);
      const second = this.uniqueCell({ col: random.integer(Math.max(2, Math.floor(cols / 2)), cols - 2), row: random.integer(1, rows - 2) }, cols, rows, [...reserved, first]);
      return [
        { ...first, label: "S1", order: 1 },
        { ...second, label: "S2", order: 2 },
      ];
    }
    if (type === "pattern-routing" || type === "loop-compression") {
      const first = this.uniqueCell({ col: Math.max(1, Math.floor(cols / 3)), row: 1 }, cols, rows, reserved);
      const second = this.uniqueCell({ col: Math.min(cols - 2, Math.floor((cols * 2) / 3)), row: rows - 2 }, cols, rows, [...reserved, first]);
      return [
        { ...first, label: type === "loop-compression" ? "M1" : "A", order: 1 },
        { ...second, label: type === "loop-compression" ? "M2" : "B", order: 2 },
      ];
    }
    return [];
  }

  private uniqueCell(candidate: Cell, cols: number, rows: number, reserved: Cell[]): Cell {
    for (let radius = 0; radius < cols + rows; radius += 1) {
      for (let dc = -radius; dc <= radius; dc += 1) {
        const dr = radius - Math.abs(dc);
        for (const sign of [-1, 1]) {
          const cell = {
            col: Math.max(0, Math.min(cols - 1, candidate.col + dc)),
            row: Math.max(0, Math.min(rows - 1, candidate.row + dr * sign)),
          };
          if (!reserved.some((item) => item.col === cell.col && item.row === cell.row)) {
            return cell;
          }
        }
      }
    }
    return { col: 0, row: 0 };
  }

  private buildObstacles(random: Random, cols: number, rows: number, count: number, reserved: Cell[]): Cell[] {
    const reservedKeys = new Set(reserved.map((cell) => `${cell.col}:${cell.row}`));
    const obstacles: Cell[] = [];
    let guard = 0;
    while (obstacles.length < count && guard < 180) {
      guard += 1;
      const cell = { col: random.integer(0, cols - 1), row: random.integer(0, rows - 1) };
      const key = `${cell.col}:${cell.row}`;
      const tooCloseToStart = Math.abs(cell.col) + Math.abs(cell.row - (rows - 1)) <= 1;
      if (!tooCloseToStart && !reservedKeys.has(key) && !obstacles.some((obstacle) => obstacle.col === cell.col && obstacle.row === cell.row)) {
        obstacles.push(cell);
      }
    }
    return obstacles;
  }

  private solveRoute(
    cols: number,
    rows: number,
    start: RouteState,
    key: Cell,
    exit: Cell,
    obstacles: Cell[],
    checkpoints: RobotCheckpoint[],
  ): GridCommand[] | undefined {
    let state: RouteState = { ...start };
    const commands: GridCommand[] = [];
    for (const target of [...checkpoints, key]) {
      const path = this.solver.findCommandPath(cols, rows, state, target, obstacles, cols * rows * 4);
      if (!path) {
        return undefined;
      }
      commands.push(...path);
      state = this.solver.simulate(state, path);
    }
    commands.push("PICK_UP");
    const toExit = this.solver.findCommandPath(cols, rows, state, exit, obstacles, cols * rows * 4);
    if (!toExit) {
      return undefined;
    }
    commands.push(...toExit, "EXIT");
    return commands;
  }

  private buildPuzzle(
    cols: number,
    rows: number,
    start: RouteState,
    key: Cell,
    exit: Cell,
    obstacles: Cell[],
    solutionCommands: GridCommand[],
    difficulty: DifficultyPreset,
    challengeType: RobotChallengeType,
    checkpoints: RobotCheckpoint[],
    random: Random,
  ): GeneratedRobotPuzzle {
    const buggedCommands = challengeType === "debug-program" ? this.mutateProgram(solutionCommands, random) : undefined;
    const maxCommands = challengeType === "minimal-route" || challengeType === "loop-compression"
      ? solutionCommands.length + (difficulty.level <= 2 ? 2 : 1)
      : solutionCommands.length + Math.max(2, 6 - difficulty.level);
    return {
      id: `robot-grid-${challengeType}`,
      title: this.titleFor(challengeType),
      instructions: this.instructionsFor(challengeType, checkpoints),
      cols,
      rows,
      start,
      key,
      exit,
      obstacles,
      solutionCommands,
      maxCommands,
      challengeType,
      checkpoints,
      buggedCommands,
      debugBrief: buggedCommands ? "Il log registrato contiene un programma quasi corretto ma instabile: non copiarlo, usalo per cercare il primo comando che rompe la rotta." : undefined,
      successConditions: this.successConditionsFor(challengeType, checkpoints, maxCommands),
      conceptTags: this.conceptsFor(challengeType, checkpoints),
      requiredConcepts: this.conceptsFor(challengeType, checkpoints),
      routeBrief: this.routeBriefFor(challengeType, checkpoints, solutionCommands),
      visualFocus: this.visualFocusFor(challengeType),
      coordinateLabels: challengeType === "coordinate-routing",
      planningPrompt: this.planningPromptFor(challengeType),
      hints: this.hintsFor(challengeType, checkpoints),
      competencies: this.competenciesFor(challengeType),
    };
  }

  private mutateProgram(commands: GridCommand[], random: Random): GridCommand[] {
    const mutableIndexes = commands
      .map((command, index) => ({ command, index }))
      .filter(({ command }) => command !== "PICK_UP" && command !== "EXIT");
    if (mutableIndexes.length === 0) {
      return commands;
    }
    const picked = random.pick(mutableIndexes);
    const replacement = picked.command === "MOVE_FORWARD"
      ? random.pick(["TURN_LEFT", "TURN_RIGHT"] satisfies GridCommand[])
      : "MOVE_FORWARD";
    return commands.map((command, index) => (index === picked.index ? replacement : command));
  }

  private titleFor(type: RobotChallengeType): string {
    return {
      "route-planning": "Robot: rotta operativa",
      "minimal-route": "Robot: percorso minimo",
      "checkpoint-order": "Robot: checkpoint ordinati",
      "debug-program": "Robot: programma da debuggare",
      "pattern-routing": "Robot: pattern di rotta",
      "coordinate-routing": "Robot: coordinate operative",
      "conditional-gate": "Robot: porta condizionata",
      "loop-compression": "Robot: blocco ripetuto",
    }[type];
  }

  private instructionsFor(type: RobotChallengeType, checkpoints: RobotCheckpoint[]): string[] {
    const checkpointLine = checkpoints.length > 0
      ? `Passa sui checkpoint ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")} prima di raccogliere la chiave.`
      : "Non ci sono checkpoint: concentrati su posizione, direzione e budget.";
    return {
      "route-planning": [
        "Obiettivo: porta il robot sulla stella, usa Raccogli, poi raggiungi il quadrato di uscita e usa Esci.",
        "La punta indica la direzione iniziale; le rotazioni cambiano solo direzione, non casella.",
        "Prima simula mentalmente tre comandi: posizione, direzione, nuova posizione.",
      ],
      "minimal-route": [
        "Obiettivo: stessa missione, ma con budget stretto. Ogni comando inutile consuma energia.",
        "Cerca corridoi lunghi prima di aggiungere svolte.",
        "Se due rotazioni consecutive si annullano, probabilmente puoi accorciare il programma.",
      ],
      "checkpoint-order": [
        checkpointLine,
        "Dividi il programma in sottoproblemi: start -> checkpoint -> chiave -> uscita.",
        "Non raccogliere la chiave prima del checkpoint: il sistema non certifichera la rotta.",
      ],
      "debug-program": [
        "Un programma precedente e quasi corretto ma contiene un errore. Devi riscrivere la rotta stabile.",
        "Non provare a caso: individua dove cambia posizione o direzione rispetto all'obiettivo.",
        "Esegui solo quando sai spiegare perche il programma corretto arriva a chiave e uscita.",
      ],
      "pattern-routing": [
        checkpointLine,
        "La griglia nasconde un pattern: alterna tratti lunghi e svolte controllate.",
        "Costruisci la sequenza per segmenti, poi verifica che l'ultimo segmento arrivi all'uscita.",
      ],
      "coordinate-routing": [
        "Leggi la griglia come coordinate: colonne da sinistra a destra, righe dall'alto verso il basso.",
        "Prima individua coordinate di robot, chiave e uscita; poi trasforma gli spostamenti in comandi.",
        "La direzione iniziale conta: uno spostamento verso destra non e sempre un Avanza immediato.",
      ],
      "conditional-gate": [
        checkpointLine,
        "I sensori aprono la porta solo se vengono attivati nell'ordine indicato.",
        "Pensa come un algoritmo con condizioni: se S1 e S2 sono attivi, allora puoi raccogliere e uscire.",
      ],
      "loop-compression": [
        checkpointLine,
        "Cerca un blocco di comandi che si ripete: tratto dritto, svolta, tratto dritto.",
        "Non devi usare un comando Repeat: devi pero riconoscere il pattern per scrivere meno tentativi.",
      ],
    }[type];
  }

  private successConditionsFor(type: RobotChallengeType, checkpoints: RobotCheckpoint[], maxCommands: number): string[] {
    const conditions = [
      "Raccogli la chiave dalla stessa casella della stella.",
      "Raggiungi il quadrato di uscita e usa Esci.",
      `Non superare ${maxCommands} comandi.`,
    ];
    if (checkpoints.length > 0) {
      conditions.unshift(`Visita i checkpoint in ordine: ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")}.`);
    }
    if (type === "debug-program") {
      conditions.unshift("Correggi il programma guasto invece di copiarlo.");
    }
    if (type === "conditional-gate") {
      conditions.unshift("Attiva i sensori prima della chiave: la porta finale accetta solo una procedura condizionata.");
    }
    if (type === "coordinate-routing") {
      conditions.unshift("Usa le coordinate come piano, non come risposta: il robot esegue solo comandi.");
    }
    if (type === "loop-compression") {
      conditions.unshift("Riconosci il blocco ripetuto prima di eseguire: evita comandi esplorativi.");
    }
    return conditions;
  }

  private hintsFor(type: RobotChallengeType, checkpoints: RobotCheckpoint[]): string[] {
    const base = [
      "Segna la direzione del robot dopo ogni svolta: molti errori nascono da una punta dimenticata.",
      "Dividi la rotta in segmenti e controlla un segmento alla volta.",
      "Prima di eseguire, leggi la sequenza come se fossi il robot.",
    ];
    if (type === "minimal-route") {
      return ["Il percorso piu breve spesso usa il bordo come corridoio.", "Elimina rotazioni che non cambiano la prossima cella utile.", ...base];
    }
    if (type === "debug-program") {
      return ["Confronta il log guasto con la mappa: il primo urto e la vera informazione.", "Un solo comando sbagliato puo cambiare tutte le caselle successive.", ...base];
    }
    if (type === "coordinate-routing") {
      return ["Scrivi le coordinate di partenza, chiave e uscita: poi conta colonne e righe.", "Una rotazione cambia verso, non posizione: dopo ogni svolta aggiorna la freccia.", ...base];
    }
    if (type === "conditional-gate") {
      return ["Tratta i checkpoint come condizioni da rendere vere prima della chiave.", "Se raccogli prima dei sensori, il programma sembra vicino ma non e valido.", ...base];
    }
    if (type === "loop-compression") {
      return ["Cerca due segmenti simili: spesso la stessa idea si ripete con direzioni diverse.", "Scrivi il blocco una volta su carta, poi adattalo alla seconda tappa.", ...base];
    }
    if (checkpoints.length > 0) {
      return [`Prima punta al checkpoint ${checkpoints[0].label}, poi riparti da li come se fosse un nuovo inizio.`, ...base];
    }
    return base;
  }

  private conceptsFor(type: RobotChallengeType, checkpoints: RobotCheckpoint[]): string[] {
    const concepts = ["direzione", "sequenza", "simulazione mentale"];
    if (checkpoints.length > 0) concepts.push("decomposizione in sotto-obiettivi");
    if (type === "minimal-route") concepts.push("ottimizzazione", "budget di comandi");
    if (type === "debug-program") concepts.push("debugging", "traccia di errore");
    if (type === "pattern-routing") concepts.push("pattern spaziale");
    if (type === "coordinate-routing") concepts.push("coordinate", "assi della griglia");
    if (type === "conditional-gate") concepts.push("condizione se-allora", "stato del sistema");
    if (type === "loop-compression") concepts.push("pattern ripetuto", "astrazione di blocco");
    concepts.push("raccolta contestuale", "uscita finale");
    return concepts;
  }

  private competenciesFor(type: RobotChallengeType): string[] {
    const base = ["coding.sequenze", "coding.orientamento", "problemSolving"];
    if (type === "minimal-route") return [...base, "coding.efficienza", "pensieroCritico"];
    if (type === "debug-program") return [...base, "coding.debugging", "coding.testMentale", "pensieroCritico"];
    if (type === "coordinate-routing") return [...base, "coding.testMentale", "matematica.logica"];
    if (type === "conditional-gate") return [...base, "coding.decomposizione", "matematica.logica", "pensieroCritico"];
    if (type === "loop-compression") return [...base, "coding.decomposizione", "coding.efficienza", "pensieroCritico"];
    if (type === "checkpoint-order" || type === "pattern-routing") return [...base, "coding.decomposizione", "coding.testMentale"];
    return [...base, "coding.debugging"];
  }

  private routeBriefFor(type: RobotChallengeType, checkpoints: RobotCheckpoint[], solutionCommands: GridCommand[]): string {
    const turns = solutionCommands.filter((command) => command === "TURN_LEFT" || command === "TURN_RIGHT").length;
    const checkpointsText = checkpoints.length > 0 ? ` Tappe obbligatorie: ${checkpoints.map((checkpoint) => checkpoint.label).join(" -> ")}.` : "";
    return {
      "route-planning": `Pianifica una rotta completa: chiave, uscita e comando finale.${checkpointsText}`,
      "minimal-route": `Budget stretto: soluzione di riferimento ${solutionCommands.length} comandi, con ${turns} rotazioni.`,
      "checkpoint-order": `Scomponi in tappe: ogni checkpoint crea un nuovo sotto-problema.${checkpointsText}`,
      "debug-program": "Usa il log guasto come indizio: cerca il primo comando che cambia direzione o posizione nel punto sbagliato.",
      "pattern-routing": `Cerca una struttura visiva ricorrente tra le tappe.${checkpointsText}`,
      "coordinate-routing": "Trasforma coordinate e direzione in comandi: colonna/riga non bastano se la freccia punta altrove.",
      "conditional-gate": `Algoritmo con stato: prima rendi veri i sensori, poi raccogli e apri.${checkpointsText}`,
      "loop-compression": `Individua il blocco ripetuto: una buona sequenza nasce da segmenti riconoscibili.${checkpointsText}`,
    }[type];
  }

  private visualFocusFor(type: RobotChallengeType): string {
    return {
      "route-planning": "rotta completa",
      "minimal-route": "efficienza",
      "checkpoint-order": "sotto-obiettivi",
      "debug-program": "primo errore",
      "pattern-routing": "pattern spaziale",
      "coordinate-routing": "coordinate",
      "conditional-gate": "se -> allora",
      "loop-compression": "blocco ripetuto",
    }[type];
  }

  private planningPromptFor(type: RobotChallengeType): string {
    return {
      "route-planning": "Scrivi la sequenza solo quando sai dove saranno posizione e direzione dopo i primi tre comandi.",
      "minimal-route": "Prima elimina svolte inutili: un programma corretto ma lungo non supera il budget.",
      "checkpoint-order": "Risolvi una tappa alla volta, poi unisci i segmenti senza perdere la direzione finale.",
      "debug-program": "Non copiare il log: confrontalo con la mappa e correggi la prima divergenza.",
      "pattern-routing": "Cerca simmetrie e corridoi: spesso il percorso si costruisce per segmenti simili.",
      "coordinate-routing": "Annota coordinate e verso iniziale: conta spostamenti, poi converti in Avanza/Gira.",
      "conditional-gate": "Pensa a variabili di stato: sensore attivo oppure no. La chiave vale solo dopo le condizioni.",
      "loop-compression": "Trova il blocco ripetuto e riscrivilo con variazioni minime di direzione.",
    }[type];
  }

  fallback(challengeType: RobotChallengeType = "route-planning", random?: Random): GeneratedRobotPuzzle {
    const mirror = random?.bool() ?? false;
    const cell = (col: number, row: number) => ({ col: mirror ? 4 - col : col, row });
    const commands = (items: GridCommand[]): GridCommand[] => mirror
      ? items.map((command) => command === "TURN_LEFT" ? "TURN_RIGHT" : command === "TURN_RIGHT" ? "TURN_LEFT" : command)
      : items;
    const checkpoints = ["checkpoint-order", "pattern-routing", "conditional-gate", "loop-compression"].includes(challengeType)
      ? [{ col: 1, row: 1, label: challengeType === "conditional-gate" ? "S1" : "A", order: 1 }]
      : [];
    const baseSolutionCommands: GridCommand[] = checkpoints.length > 0
      ? ["TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"]
      : ["MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "TURN_RIGHT", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"];
    const solutionCommands = commands(baseSolutionCommands);
    const variedCheckpoints = checkpoints.map((checkpoint) => ({ ...cell(checkpoint.col, checkpoint.row), label: checkpoint.label, order: checkpoint.order }));
    return {
      id: `robot-grid-fallback-${challengeType}-${mirror ? "mirror" : "base"}`,
      title: this.titleFor(challengeType),
      instructions: this.instructionsFor(challengeType, variedCheckpoints),
      cols: 5,
      rows: 4,
      start: { ...cell(0, 3), facing: mirror ? "W" : "E" },
      key: cell(3, 1),
      exit: cell(4, 3),
      obstacles: [cell(2, 2)],
      solutionCommands,
      maxCommands: solutionCommands.length + 2,
      challengeType,
      checkpoints: variedCheckpoints,
      buggedCommands: challengeType === "debug-program" ? commands(["MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "PICK_UP", "EXIT"]) : undefined,
      debugBrief: challengeType === "debug-program" ? "Il log guasto prova a raccogliere troppo presto: correggi la rotta completa." : undefined,
      successConditions: this.successConditionsFor(challengeType, variedCheckpoints, solutionCommands.length + 2),
      requiredConcepts: this.conceptsFor(challengeType, variedCheckpoints),
      conceptTags: this.conceptsFor(challengeType, variedCheckpoints),
      routeBrief: this.routeBriefFor(challengeType, variedCheckpoints, solutionCommands),
      visualFocus: this.visualFocusFor(challengeType),
      coordinateLabels: challengeType === "coordinate-routing",
      planningPrompt: this.planningPromptFor(challengeType),
      hints: this.hintsFor(challengeType, variedCheckpoints),
      competencies: this.competenciesFor(challengeType),
    };
  }
}
