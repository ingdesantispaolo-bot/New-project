import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { feedbackSystem } from "../core/FeedbackSystem";
import { hintLadder } from "../core/HintLadder";
import { mistakeAnalyzer } from "../core/MistakeAnalyzer";
import { missionEngine } from "../core/MissionEngine";
import { circuitPuzzle } from "../data/puzzles";
import type { CircuitFaultType, HintStep } from "../procedural/ProceduralTypes";
import { Button } from "../ui/Button";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type ComponentKey = "battery" | "switch" | "resistor" | "led" | "return";
type RepairKey = "close-switch" | "insert-resistor" | "flip-led" | "replace-wire";
type TesterReading = {
  label: string;
  reading: string;
  interpretation: string;
  focus: ComponentKey;
};

const componentInfo: Record<ComponentKey, { title: string; role: string; principle: string; x: number; color: number }> = {
  battery: {
    title: "Batteria",
    role: "Fornisce energia e crea un polo positivo e uno negativo.",
    principle: "La corrente deve poter partire e tornare: senza ritorno non c'e circuito.",
    x: 210,
    color: 0xf6c85f,
  },
  switch: {
    title: "Interruttore",
    role: "Apre o chiude il percorso della corrente.",
    principle: "Aperto interrompe il circuito; chiuso permette il passaggio.",
    x: 430,
    color: 0x8aa6b0,
  },
  resistor: {
    title: "Resistenza",
    role: "Limita la corrente e protegge il LED.",
    principle: "Non serve ad accendere di piu: serve a non bruciare il componente.",
    x: 650,
    color: 0xffb36b,
  },
  led: {
    title: "LED",
    role: "Emette luce solo se attraversato nel verso corretto.",
    principle: "Il LED ha polarita: invertito resta spento anche se il percorso sembra completo.",
    x: 870,
    color: 0x6be7d6,
  },
  return: {
    title: "Ritorno",
    role: "Riporta la corrente al polo negativo della batteria.",
    principle: "Un circuito e un giro completo, non una linea che finisce al LED.",
    x: 1070,
    color: 0x9ff5e9,
  },
};

const requiredRepairs: RepairKey[] = ["close-switch", "insert-resistor", "flip-led"];
const repairToFault: Record<RepairKey, CircuitFaultType | "extra-wire"> = {
  "close-switch": "open-switch",
  "insert-resistor": "missing-resistor",
  "flip-led": "reversed-led",
  "replace-wire": "extra-wire",
};

const testerReadings: TesterReading[] = [
  {
    label: "Batteria -> Interruttore",
    reading: "Tensione presente, poi percorso aperto.",
    interpretation: "La batteria funziona. Il primo blocco e l'interruttore aperto.",
    focus: "switch",
  },
  {
    label: "Interruttore -> LED",
    reading: "Percorso quasi continuo, ma segnale instabile.",
    interpretation: "Se chiudi il percorso senza resistenza, il LED non e protetto.",
    focus: "resistor",
  },
  {
    label: "Resistenza -> LED",
    reading: "Corrente in arrivo, luce assente.",
    interpretation: "Quando arriva corrente ma il LED resta spento, controlla il verso del LED.",
    focus: "led",
  },
  {
    label: "LED -> Ritorno",
    reading: "Ritorno disponibile.",
    interpretation: "Il problema principale non e il filo di ritorno: sostituirlo sarebbe un intervento inutile.",
    focus: "return",
  },
];

export class CircuitPuzzleScene extends Phaser.Scene {
  private selectedRepairs = new Set<RepairKey>();
  private selectedComponent: ComponentKey = "battery";
  private testerIndex = 0;
  private hintCount = 0;
  private attempts = 0;
  private statusText?: Phaser.GameObjects.Text;
  private infoText?: Phaser.GameObjects.Text;
  private testerText?: Phaser.GameObjects.Text;
  private repairText?: Phaser.GameObjects.Text;
  private ledGlow?: Phaser.GameObjects.Image;
  private circuitLine?: Phaser.GameObjects.Graphics;
  private componentNodes = new Map<ComponentKey, Phaser.GameObjects.Container>();
  private readonly hints: HintStep[] = hintLadder.fromTexts(
    [
      "Parti dal tester: non tutte le parti guaste danno lo stesso sintomo.",
      "Se la corrente non supera l'interruttore, prima devi chiudere il percorso.",
      "Un LED ha bisogno sia del verso corretto sia di una resistenza in serie.",
      "Ripara interruttore, resistenza e verso del LED. Non sostituire il ritorno.",
    ],
    "Un circuito LED sicuro richiede percorso chiuso, polarita corretta e resistenza.",
  );

  constructor() {
    super("CircuitPuzzleScene");
  }

  create(): void {
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "circuit");
    VisualKit.cinematicDepth(this, "circuit", 0.88);
    this.drawLayout();
    this.drawCircuit();
    this.drawPanels();
    this.drawControls();
    this.refresh();
    VisualKit.vignette(this);
  }

  private drawLayout(): void {
    this.add.text(64, 38, "Console diagnostica: circuito LED", {
      fontFamily: "Inter, Arial",
      fontSize: "33px",
      color: "#f5fbff",
      fontStyle: "bold",
    });
    this.add.text(66, 86, "Osserva il sintomo, leggi il tester, poi scegli solo le riparazioni necessarie.", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#c9dce6",
    });
    SceneChrome.consolePanel(this, 54, 126, 820, 470, "Schema del circuito", "circuit");
    SceneChrome.consolePanel(this, 904, 126, 316, 216, "Tester", "circuit");
    SceneChrome.consolePanel(this, 904, 362, 316, 234, "Scheda componente", "circuit");
    VisualKit.glowFrame(this, 44, 116, 840, 490, "circuit");
    VisualKit.scanLine(this, 464, 356, 770, 390, "circuit");
  }

  private drawCircuit(): void {
    this.circuitLine = this.add.graphics();
    (Object.keys(componentInfo) as ComponentKey[]).forEach((key) => {
      const info = componentInfo[key];
      const node = this.add.container(info.x, 328);
      node.add(this.add.rectangle(0, 8, 142, 126, 0x000000, 0.28));
      node.add(this.add.rectangle(0, 0, 142, 126, 0x112432, 0.88).setStrokeStyle(2, info.color, 0.64));
      node.add(this.add.text(0, -48, info.title, {
        fontFamily: "Inter, Arial",
        fontSize: "16px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.drawSymbol(node, key);
      node.setSize(150, 132);
      node.setInteractive(new Phaser.Geom.Rectangle(-75, -66, 150, 132), Phaser.Geom.Rectangle.Contains);
      node.on("pointerdown", () => {
        this.selectedComponent = key;
        audioManager.play("scan");
        this.refresh();
      });
      this.componentNodes.set(key, node);
    });
    this.ledGlow = this.add.image(componentInfo.led.x, 430, "soft-glow").setTint(0x6be7d6).setAlpha(0.07).setScale(1.2);
  }

  private drawSymbol(node: Phaser.GameObjects.Container, key: ComponentKey): void {
    const g = this.add.graphics();
    g.lineStyle(4, componentInfo[key].color, 0.92);
    if (key === "battery") {
      g.lineBetween(-42, 18, -12, 18);
      g.lineBetween(12, 18, 42, 18);
      g.lineBetween(-12, -16, -12, 44);
      g.lineBetween(12, -4, 12, 32);
      node.add(this.add.text(-30, 42, "+", { fontSize: "18px", color: "#f7d37a", fontStyle: "bold" }));
      node.add(this.add.text(28, 42, "-", { fontSize: "18px", color: "#f7d37a", fontStyle: "bold" }));
    } else if (key === "switch") {
      g.lineBetween(-48, 24, -12, 24);
      g.lineBetween(18, 24, 48, 24);
      g.lineBetween(-12, 24, 26, -10);
      g.fillStyle(0xffb36b, 1);
      g.fillCircle(-12, 24, 5);
      g.fillCircle(18, 24, 5);
    } else if (key === "resistor") {
      g.lineBetween(-50, 20, -32, 20);
      let x = -32;
      for (let i = 0; i < 6; i += 1) {
        g.lineBetween(x, 20, x + 10, i % 2 === 0 ? 0 : 40);
        x += 10;
      }
      g.lineBetween(28, 20, 50, 20);
    } else if (key === "led") {
      g.lineBetween(-50, 20, -18, 20);
      g.strokeTriangle(-18, -12, -18, 52, 24, 20);
      g.lineBetween(24, -12, 24, 52);
      g.lineBetween(24, 20, 50, 20);
      g.lineStyle(2, 0xf7d37a, 0.9);
      g.lineBetween(20, -24, 42, -42);
      g.lineBetween(34, -24, 56, -42);
    } else {
      g.lineBetween(-50, 20, 50, 20);
      g.strokeCircle(0, 20, 18);
      g.lineStyle(2, 0x9ff5e9, 0.7);
      g.lineBetween(-12, 8, 12, 32);
    }
    node.add(g);
  }

  private drawPanels(): void {
    this.testerText = this.add.text(928, 180, "", {
      fontFamily: "Inter, Arial",
      fontSize: "16px",
      color: "#d9eaf1",
      wordWrap: { width: 252 },
      lineSpacing: 5,
    });
    this.infoText = this.add.text(928, 416, "", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 252 },
      lineSpacing: 5,
    });
    this.statusText = this.add.text(80, 538, "", {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f5fbff",
      wordWrap: { width: 760 },
      lineSpacing: 5,
    });
    this.repairText = this.add.text(80, 618, "", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      wordWrap: { width: 1120 },
    });
  }

  private drawControls(): void {
    const repairButtons: Array<{ key: RepairKey; label: string; x: number }> = [
      { key: "close-switch", label: "Chiudi interruttore", x: 170 },
      { key: "insert-resistor", label: "Inserisci resistenza", x: 410 },
      { key: "flip-led", label: "Inverti LED", x: 650 },
      { key: "replace-wire", label: "Sostituisci ritorno", x: 890 },
    ];
    repairButtons.forEach((repair) => {
      new Button(this, repair.x, 674, repair.label, () => this.toggleRepair(repair.key), {
        width: 210,
        height: 44,
        fontSize: 14,
        fill: 0x142736,
      });
    });
    new Button(this, 1014, 248, "Leggi tester", () => this.readTester(), { width: 190, height: 42, fontSize: 15, fill: 0x173b36 });
    new Button(this, 1014, 548, "Indizio", () => this.showHint(), { width: 190, height: 42, fontSize: 15, fill: 0x263743 });
    new Button(this, 1134, 674, "Test finale", () => this.testCircuit(), { width: 180, height: 44, fontSize: 15, fill: 0x1f4b46 });
    new Button(this, 88, 674, "Indietro", () => this.scene.start("LaboratoryScene"), { width: 130, height: 44, fontSize: 15, fill: 0x263743 });
  }

  private refresh(): void {
    this.drawCurrentPath();
    const reading = testerReadings[this.testerIndex];
    this.testerText?.setText(`${reading.label}\n\nLettura: ${reading.reading}\n\nInterpretazione: ${reading.interpretation}`);
    const info = componentInfo[this.selectedComponent];
    this.infoText?.setText(`${info.title}\n\nRuolo: ${info.role}\n\nPrincipio: ${info.principle}`);
    this.statusText?.setText(
      "Sintomo: il LED resta spento. Il tester mostra che ci sono piu cause: percorso aperto, protezione mancante e LED orientato male.",
    );
    this.repairText?.setText(`Riparazioni selezionate: ${this.selectedRepairLabels().join(", ") || "nessuna"}.`);
    this.componentNodes.forEach((node, key) => {
      const selected = key === this.selectedComponent || key === reading.focus;
      node.setAlpha(selected ? 1 : 0.82);
      this.tweens.killTweensOf(node);
      if (selected) {
        this.tweens.add({ targets: node, scale: 1.035, duration: 420, yoyo: true, repeat: -1 });
      } else {
        node.setScale(1);
      }
    });
  }

  private drawCurrentPath(): void {
    const closed = this.selectedRepairs.has("close-switch");
    const resistor = this.selectedRepairs.has("insert-resistor");
    const led = this.selectedRepairs.has("flip-led");
    this.circuitLine?.clear();
    this.circuitLine?.lineStyle(8, closed ? 0x6be7d6 : 0x405761, closed ? 0.72 : 0.28);
    this.circuitLine?.beginPath();
    this.circuitLine?.moveTo(282, 328);
    this.circuitLine?.lineTo(358, 328);
    if (closed) {
      this.circuitLine?.lineTo(502, 328);
    } else {
      this.circuitLine?.moveTo(480, 296);
      this.circuitLine?.lineTo(502, 328);
    }
    this.circuitLine?.lineStyle(8, resistor ? 0x6be7d6 : 0xffb36b, resistor ? 0.72 : 0.34);
    this.circuitLine?.lineTo(578, 328);
    this.circuitLine?.lineTo(722, 328);
    this.circuitLine?.lineStyle(8, led ? 0x6be7d6 : 0xc94b55, led ? 0.72 : 0.34);
    this.circuitLine?.lineTo(798, 328);
    this.circuitLine?.lineTo(942, 328);
    this.circuitLine?.lineStyle(8, 0x6be7d6, 0.34);
    this.circuitLine?.lineTo(998, 328);
    this.circuitLine?.lineTo(1140, 328);
    this.circuitLine?.lineTo(1140, 466);
    this.circuitLine?.lineTo(210, 466);
    this.circuitLine?.lineTo(210, 390);
    this.circuitLine?.strokePath();
    const powered = closed && resistor && led;
    this.ledGlow?.setAlpha(powered ? 0.42 : led ? 0.12 : 0.05).setScale(powered ? 1.65 : 1.1);
  }

  private toggleRepair(repair: RepairKey): void {
    if (this.selectedRepairs.has(repair)) {
      this.selectedRepairs.delete(repair);
    } else {
      this.selectedRepairs.add(repair);
    }
    audioManager.play("click");
    this.refresh();
  }

  private readTester(): void {
    this.testerIndex = (this.testerIndex + 1) % testerReadings.length;
    this.selectedComponent = testerReadings[this.testerIndex].focus;
    audioManager.play("scan");
    this.refresh();
  }

  private showHint(): void {
    const hint = hintLadder.next(this.hints, this.hintCount);
    this.hintCount += 1;
    feedbackSystem.publish(hint.text, hint.kind === "quasi-soluzione" ? "warning" : "hint");
    this.statusText?.setColor("#f7d37a").setText(`Indizio ${hint.level}: ${hint.text}`);
    audioManager.play("scan");
  }

  private testCircuit(): void {
    this.attempts += 1;
    const selected = [...this.selectedRepairs];
    const missing = requiredRepairs.filter((repair) => !this.selectedRepairs.has(repair));
    const extras = selected.filter((repair) => !requiredRepairs.includes(repair));

    if (missing.length === 0 && extras.length === 0) {
      missionEngine.completeObjective("circuitFixed", ["elettronica.circuitoChiuso", "problemSolving", "pensieroCritico"], 22);
      audioManager.play("circuitOn");
      this.statusText?.setColor("#9ff5e9").setText("Diagnosi confermata: percorso chiuso, resistenza in serie, LED nel verso corretto. Il circuito e stabile.");
      this.repairText?.setText("Spiegazione: un LED non basta collegarlo. Serve un giro completo, verso corretto e corrente limitata.");
      VisualKit.outcomeFlash(this, "success", 640, 386, 1120, 430);
      VisualKit.particleBurst(this, componentInfo.led.x, 430, "circuit", "success");
      this.time.delayedCall(1200, () => this.scene.start("LaboratoryScene"));
      return;
    }

    audioManager.play("error");
    VisualKit.outcomeFlash(this, "error", 640, 386, 1120, 430);
    VisualKit.particleBurst(this, componentInfo[this.focusForMissing(missing[0] ?? extras[0])].x, 328, "circuit", "error");

    const fault = repairToFault[missing[0] ?? extras[0]];
    const mistakes = mistakeAnalyzer.circuitMistakes();
    const message =
      fault === "open-switch"
        ? mistakes[0].feedback
        : fault === "reversed-led"
          ? mistakes[1].feedback
          : fault === "missing-resistor"
            ? mistakes[2].feedback
            : "Hai scelto un intervento non necessario: un buon log tecnico evita riparazioni che non cambiano il guasto.";
    const explanation =
      this.attempts >= 2
        ? "\n\nPrincipio: separa sempre percorso chiuso, verso del LED e protezione. Non provare tutto: leggi il tester e cambia solo la causa."
        : "";
    this.statusText?.setColor("#f7d37a").setText(`${message}${explanation}`);
    this.repairText?.setText(
      missing.length > 0
        ? `Manca ancora: ${missing.map((repair) => this.repairLabel(repair)).join(", ")}.`
        : `Intervento inutile da rimuovere: ${extras.map((repair) => this.repairLabel(repair)).join(", ")}.`,
    );
  }

  private selectedRepairLabels(): string[] {
    return [...this.selectedRepairs].map((repair) => this.repairLabel(repair));
  }

  private repairLabel(repair: RepairKey): string {
    return {
      "close-switch": "chiudere interruttore",
      "insert-resistor": "inserire resistenza",
      "flip-led": "invertire LED",
      "replace-wire": "sostituire ritorno",
    }[repair];
  }

  private focusForMissing(repair: RepairKey | undefined): ComponentKey {
    if (repair === "close-switch") return "switch";
    if (repair === "insert-resistor") return "resistor";
    if (repair === "flip-led") return "led";
    return "return";
  }
}
