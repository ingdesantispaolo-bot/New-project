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
      if (enoughDepth && (enoughTurns || challengeType === "route-planning")) {
        return this.buildPuzzle(cols, rows, layout.start, layout.key, layout.exit, obstacles, solutionCommands, difficulty, challengeType, layout.checkpoints, random);
      }
    }

    return this.fallback(challengeType);
  }

  private pickChallengeType(random: Random, difficulty: DifficultyPreset): RobotChallengeType {
    if (difficulty.level <= 2) {
      return random.pick(["route-planning", "minimal-route"]);
    }
    if (difficulty.level <= 4) {
      return random.pick(["minimal-route", "checkpoint-order", "debug-program"]);
    }
    return random.pick(["checkpoint-order", "debug-program", "pattern-routing", "minimal-route"]);
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
    if (type === "pattern-routing") {
      const first = this.uniqueCell({ col: Math.max(1, Math.floor(cols / 3)), row: 1 }, cols, rows, reserved);
      const second = this.uniqueCell({ col: Math.min(cols - 2, Math.floor((cols * 2) / 3)), row: rows - 2 }, cols, rows, [...reserved, first]);
      return [
        { ...first, label: "A", order: 1 },
        { ...second, label: "B", order: 2 },
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
    const maxCommands = challengeType === "minimal-route"
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
    concepts.push("raccolta contestuale", "uscita finale");
    return concepts;
  }

  private competenciesFor(type: RobotChallengeType): string[] {
    const base = ["coding.sequenze", "coding.orientamento", "problemSolving"];
    if (type === "minimal-route") return [...base, "coding.efficienza", "pensieroCritico"];
    if (type === "debug-program") return [...base, "coding.debugging", "coding.testMentale", "pensieroCritico"];
    if (type === "checkpoint-order" || type === "pattern-routing") return [...base, "coding.decomposizione", "coding.testMentale"];
    return [...base, "coding.debugging"];
  }

  fallback(challengeType: RobotChallengeType = "route-planning"): GeneratedRobotPuzzle {
    const checkpoints = challengeType === "checkpoint-order" || challengeType === "pattern-routing"
      ? [{ col: 1, row: 1, label: "A", order: 1 }]
      : [];
    const solutionCommands: GridCommand[] = checkpoints.length > 0
      ? ["TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"]
      : ["MOVE_FORWARD", "MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "MOVE_FORWARD", "PICK_UP", "TURN_RIGHT", "MOVE_FORWARD", "TURN_RIGHT", "MOVE_FORWARD", "MOVE_FORWARD", "EXIT"];
    return {
      id: `robot-grid-fallback-${challengeType}`,
      title: this.titleFor(challengeType),
      instructions: this.instructionsFor(challengeType, checkpoints),
      cols: 5,
      rows: 4,
      start: { col: 0, row: 3, facing: "E" },
      key: checkpoints.length > 0 ? { col: 3, row: 1 } : { col: 3, row: 1 },
      exit: { col: 4, row: 3 },
      obstacles: [{ col: 2, row: 2 }],
      solutionCommands,
      maxCommands: solutionCommands.length + 2,
      challengeType,
      checkpoints,
      buggedCommands: challengeType === "debug-program" ? ["MOVE_FORWARD", "MOVE_FORWARD", "TURN_LEFT", "MOVE_FORWARD", "PICK_UP", "EXIT"] : undefined,
      debugBrief: challengeType === "debug-program" ? "Il log guasto prova a raccogliere troppo presto: correggi la rotta completa." : undefined,
      successConditions: this.successConditionsFor(challengeType, checkpoints, solutionCommands.length + 2),
      requiredConcepts: this.conceptsFor(challengeType, checkpoints),
      conceptTags: this.conceptsFor(challengeType, checkpoints),
      hints: this.hintsFor(challengeType, checkpoints),
      competencies: this.competenciesFor(challengeType),
    };
  }
}
