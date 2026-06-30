import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { dialogueSystem } from "../core/DialogueSystem";
import { EventBus, GameEvents } from "../core/EventBus";
import type { FeedbackMessage } from "../core/FeedbackSystem";
import { feedbackSystem } from "../core/FeedbackSystem";
import { missionEngine } from "../core/MissionEngine";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import {
  cityDistricts,
  cityRules,
  civicDilemma,
  energyBudget,
  energyMinimums,
  energyPlans,
  type CityDistrict,
  type CityRule,
  type CivicOption,
  type EnergyPlan,
} from "../data/smartCity";
import { Button } from "../ui/Button";
import { DialogueBox } from "../ui/DialogueBox";
import { SceneChrome } from "../ui/SceneChrome";
import { VisualKit } from "../ui/VisualKit";

type CityMode = "diagnose" | "rules" | "energy" | "civic";

const PALETTE = "circuit" as const;

const TILES: Array<{ x: number; y: number }> = [
  { x: 240, y: 300 },
  { x: 588, y: 300 },
  { x: 240, y: 506 },
  { x: 588, y: 506 },
];

export class SmartCityScene extends Phaser.Scene {
  private mode: CityMode = "diagnose";
  private selectedCriticalIds = new Set<string>();
  private solvedRuleIds = new Set<string>();
  private selectedRuleId = cityRules[0].id;
  private diagnosed = false;
  private mapLayer?: Phaser.GameObjects.Container;
  private panelLayer?: Phaser.GameObjects.Container;
  private objectiveText?: Phaser.GameObjects.Text;
  private feedbackText?: Phaser.GameObjects.Text;

  constructor() {
    super("SmartCityScene");
  }

  preload(): void {
    queueSceneAssets(this, "academy", "story");
  }

  create(): void {
    audioManager.playMusic("labAmbience");
    this.restoreFlags();
    this.mode = this.resolveMode();
    this.drawCity();
    this.createHud();
    this.refreshScene();

    EventBus.on(GameEvents.Feedback, this.handleFeedback, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      EventBus.off(GameEvents.Feedback, this.handleFeedback, this);
    });

    if (!saveSystem.data.flags.mission6IntroSeen) {
      saveSystem.setFlag("mission6IntroSeen", true);
      new DialogueBox(this, dialogueSystem.format("mission6Opening"), () => {
        feedbackSystem.publish("Prima osserva la rete: quali nodi chiedono più di quanto ricevono?", "info");
      });
    }
  }

  private restoreFlags(): void {
    if (saveSystem.data.flags.cityGridDiagnosed) {
      this.diagnosed = true;
      cityDistricts.filter((d) => d.load > d.capacity).forEach((d) => this.selectedCriticalIds.add(d.id));
    }
    if (saveSystem.data.flags.cityRulesSet) {
      cityRules.forEach((rule) => this.solvedRuleIds.add(rule.id));
    }
  }

  private resolveMode(): CityMode {
    if (!saveSystem.data.flags.cityGridDiagnosed) {
      return "diagnose";
    }
    if (!saveSystem.data.flags.cityRulesSet) {
      return "rules";
    }
    if (!saveSystem.data.flags.cityEnergyBalanced) {
      return "energy";
    }
    return "civic";
  }

  private isCritical(district: CityDistrict): boolean {
    return district.load > district.capacity;
  }

  private drawCity(): void {
    VisualKit.applyCinematicGrade(this, PALETTE);
    SceneChrome.drawTwoColumnMissionChrome(
      this,
      PALETTE,
      "La Città Intelligente",
      "Salva la rete urbana: diagnosi, regole se/allora, energia e una scelta civica.",
      "Rete cittadina",
      "story-phase-04-restored-bg",
    );
  }

  private createHud(): void {
    SceneChrome.consolePanel(this, 820, 130, 420, 132, "Centrale di rete", PALETTE);
    this.objectiveText = this.add.text(842, 184, "", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 388 },
      lineSpacing: 4,
    });
    this.feedbackText = SceneChrome.bottomLog(this, SceneChrome.twoColumnLayout.bottom, "");

    new Button(this, 1110, 58, "Diario", () => this.scene.start("JournalScene"), {
      width: 150,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
    new Button(this, 930, 58, "Storia", () => this.scene.start("CampaignScene"), {
      width: 132,
      height: 44,
      fontSize: 16,
      fill: 0x142736,
    });
  }

  private refreshScene(): void {
    this.mapLayer?.destroy(true);
    this.panelLayer?.destroy(true);
    this.mapLayer = this.add.container(0, 0);
    this.panelLayer = this.add.container(0, 0);

    this.drawDistrictTiles();

    if (this.mode === "diagnose") {
      this.drawDiagnosePanel();
    } else if (this.mode === "rules") {
      this.drawRulesPanel();
    } else if (this.mode === "energy") {
      this.drawEnergyPanel();
    } else {
      this.drawCivicPanel();
    }
    this.updateObjective();
  }

  private drawDistrictTiles(): void {
    cityDistricts.forEach((district, index) => {
      const tile = TILES[index];
      const critical = this.isCritical(district);
      const selected = this.selectedCriticalIds.has(district.id);
      const showCritical = (this.diagnosed || this.mode !== "diagnose") && critical;
      const border = showCritical ? 0xc94b55 : selected ? 0x6be7d6 : 0x315766;
      const container = this.add.container(tile.x, tile.y);
      container.add(this.add.rectangle(0, 0, 330, 184, 0x09151f, 0.9).setStrokeStyle(2, border, 0.85));
      container.add(this.add.rectangle(0, -90, 330, 6, border, 0.8));
      container.add(this.add.text(-150, -78, district.name, {
        fontFamily: "Inter, Arial",
        fontSize: "17px",
        color: "#f5fbff",
        fontStyle: "bold",
      }));
      container.add(this.add.text(-150, -48, `Richiesta ${district.load}  ·  Capacità ${district.capacity}`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: showCritical ? "#ffb36b" : "#9ff5e9",
      }));
      // Load vs capacity bars.
      const barW = 286;
      const maxVal = Math.max(district.load, district.capacity, 1);
      container.add(this.add.rectangle(-150, -14, barW, 14, 0x0d1b26, 0.9).setOrigin(0, 0.5).setStrokeStyle(1, 0x315766, 0.6));
      container.add(this.add.rectangle(-150, -14, barW * (district.capacity / maxVal), 14, 0x4a8f68, 0.7).setOrigin(0, 0.5));
      container.add(this.add.rectangle(-150, 10, barW, 12, 0x0d1b26, 0.9).setOrigin(0, 0.5).setStrokeStyle(1, 0x315766, 0.6));
      container.add(this.add.rectangle(-150, 10, barW * (district.load / maxVal), 12, showCritical ? 0xc94b55 : 0xf6c85f, 0.8).setOrigin(0, 0.5));
      container.add(this.add.text(-150, 30, district.note, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9aaab0",
        wordWrap: { width: 300 },
      }));
      if (this.mode === "diagnose" && selected) {
        container.add(this.add.text(126, -78, "✓", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#6be7d6", fontStyle: "bold" }).setOrigin(0.5));
      }
      this.mapLayer?.add(container);
    });
  }

  // --- Phase 1: diagnose ----------------------------------------------------

  private drawDiagnosePanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Diagnosi della rete", PALETTE));
    this.panelLayer?.add(this.add.text(842, 322, "Un nodo è in sovraccarico quando la richiesta supera la capacità. Seleziona i nodi critici.", {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    cityDistricts.forEach((district, index) => {
      const selected = this.selectedCriticalIds.has(district.id);
      this.panelLayer?.add(new Button(this, 1028, 392 + index * 40, `${selected ? "[x]" : "[ ]"} ${district.name}`, () => this.toggleCritical(district), {
        width: 354,
        height: 34,
        fontSize: 13,
        fill: selected ? 0x243d33 : 0x20233a,
      }));
    });
    this.panelLayer?.add(new Button(this, 1018, 588, "Verifica diagnosi", () => this.checkDiagnosis(), {
      width: 250,
      height: 44,
      fontSize: 16,
      fill: 0x173b36,
    }));
  }

  private toggleCritical(district: CityDistrict): void {
    if (this.selectedCriticalIds.has(district.id)) {
      this.selectedCriticalIds.delete(district.id);
    } else {
      this.selectedCriticalIds.add(district.id);
    }
    audioManager.play("click");
    this.refreshScene();
  }

  private checkDiagnosis(): void {
    const criticalIds = new Set(cityDistricts.filter((d) => this.isCritical(d)).map((d) => d.id));
    const selected = this.selectedCriticalIds;
    const exact = selected.size === criticalIds.size && [...selected].every((id) => criticalIds.has(id));
    if (!exact) {
      feedbackSystem.publish("Diagnosi imprecisa: confronta richiesta e capacità di ogni nodo. Critico solo se la richiesta supera la capacità.", "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 470, 430, 320);
      return;
    }
    this.diagnosed = true;
    missionEngine.completeObjective("cityGridDiagnosed", ["scienze.osservazione", "scienze.dati", "matematica.logica"], 16);
    audioManager.play("success");
    feedbackSystem.publish("Nodi critici individuati: Centro Storico e Porto Merci. Ora servono regole di controllo.", "success");
    VisualKit.particleBurst(this, 1030, 470, PALETTE, "success");
    this.mode = "rules";
    this.refreshScene();
  }

  // --- Phase 2: conditional rules -------------------------------------------

  private drawRulesPanel(): void {
    const rule = cityRules.find((entry) => entry.id === this.selectedRuleId) ?? cityRules[0];
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Regole se/allora", PALETTE));

    cityRules.forEach((entry, index) => {
      const done = this.solvedRuleIds.has(entry.id);
      const focused = entry.id === rule.id;
      this.panelLayer?.add(new Button(this, 1028, 330 + index * 34, `${done ? "✓" : "•"} ${entry.condition}`, () => {
        this.selectedRuleId = entry.id;
        audioManager.play("click");
        this.refreshScene();
      }, {
        width: 354,
        height: 30,
        fontSize: 12,
        fill: focused ? 0x1f5a51 : done ? 0x173b36 : 0x20233a,
      }));
    });

    this.panelLayer?.add(this.add.text(842, 438, `🇬🇧 ${rule.english}`, {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 360 },
    }));

    if (this.solvedRuleIds.has(rule.id)) {
      this.panelLayer?.add(this.add.text(842, 482, `Regola attiva: ${rule.condition} ${rule.answer}.`, {
        fontFamily: "Inter, Arial",
        fontSize: "14px",
        color: "#9ff5e9",
        wordWrap: { width: 360 },
      }));
      return;
    }

    this.panelLayer?.add(this.add.text(842, 478, "…ALLORA quale azione?", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
    }));
    rule.options.forEach((option, index) => {
      this.panelLayer?.add(new Button(this, 1028, 512 + index * 36, option, () => this.tryRule(rule, option), {
        width: 354,
        height: 30,
        fontSize: 12,
        fill: 0x263743,
      }));
    });
  }

  private tryRule(rule: CityRule, choice: string): void {
    if (choice !== rule.answer) {
      feedbackSystem.publish(`Azione sbagliata. ${rule.hint}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "error", 1030, 540, 430, 160);
      return;
    }
    this.solvedRuleIds.add(rule.id);
    audioManager.play("success");
    feedbackSystem.publish(`${rule.condition} ${rule.answer}.`, "success");
    VisualKit.particleBurst(this, 1030, 520, PALETTE, "success");
    if (this.solvedRuleIds.size === cityRules.length) {
      missionEngine.completeObjective("cityRulesSet", ["coding.condizioni", "inglese.istruzioni", "pensieroCritico"], 16);
      this.mode = "energy";
    } else {
      const next = cityRules.find((entry) => !this.solvedRuleIds.has(entry.id));
      if (next) {
        this.selectedRuleId = next.id;
      }
    }
    this.refreshScene();
  }

  // --- Phase 3: energy budget -----------------------------------------------

  private drawEnergyPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Distribuzione energia", PALETTE));
    this.panelLayer?.add(this.add.text(842, 320, `Budget di rete: ${energyBudget}. Minimi: ospedale ${energyMinimums.ospedale}, trasporti ${energyMinimums.trasporti}, acqua ${energyMinimums.acqua}.`, {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    this.panelLayer?.add(this.add.text(842, 380, "Scegli il piano che porta ogni servizio sopra il minimo senza superare il budget.", {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
    }));
    energyPlans.forEach((plan, index) => {
      const total = plan.allocation.ospedale + plan.allocation.trasporti + plan.allocation.acqua;
      this.panelLayer?.add(new Button(
        this,
        1028,
        440 + index * 54,
        `${plan.label}: O${plan.allocation.ospedale} · T${plan.allocation.trasporti} · A${plan.allocation.acqua} (tot ${total})`,
        () => this.tryEnergy(plan),
        { width: 354, height: 44, fontSize: 13, fill: 0x263743 },
      ));
    });
  }

  private tryEnergy(plan: EnergyPlan): void {
    if (!plan.valid) {
      feedbackSystem.publish(`${plan.label}: ${plan.reason}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 500, 430, 260);
      return;
    }
    missionEngine.completeObjective("cityEnergyBalanced", ["elettronica.energia", "matematica.logica", "problemSolving"], 16);
    audioManager.play("success");
    feedbackSystem.publish(`${plan.label}: ${plan.reason}`, "success");
    VisualKit.particleBurst(this, 1030, 500, PALETTE, "success");
    this.mode = "civic";
    this.refreshScene();
  }

  // --- Phase 4: civic decision ----------------------------------------------

  private drawCivicPanel(): void {
    this.panelLayer?.add(SceneChrome.consolePanel(this, 820, 270, 420, 354, "Decisione civica", PALETTE));
    this.panelLayer?.add(this.add.text(842, 320, civicDilemma.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      wordWrap: { width: 360 },
      lineSpacing: 4,
    }));
    this.panelLayer?.add(this.add.text(842, 408, "Metti al primo posto vita, sicurezza e servizi essenziali.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#d9eaf1",
      wordWrap: { width: 360 },
    }));
    civicDilemma.options.forEach((option, index) => {
      this.panelLayer?.add(new Button(this, 1028, 460 + index * 50, option.label, () => this.tryCivic(option), {
        width: 354,
        height: 42,
        fontSize: 14,
        fill: 0x263743,
      }));
    });
  }

  private tryCivic(option: CivicOption): void {
    if (!option.correct) {
      feedbackSystem.publish(`${option.label}: ${option.reason}`, "hint");
      audioManager.play("error");
      VisualKit.outcomeFlash(this, "warning", 1030, 500, 430, 260);
      return;
    }
    missionEngine.completeObjective("cityDecisionMade", ["cittadinanza.tecnologica", "pensieroCritico"], 18);
    audioManager.play("success");
    feedbackSystem.publish(`${option.label}: ${option.reason}`, "success");
    VisualKit.outcomeFlash(this, "success");
    VisualKit.particleBurst(this, 640, 360, PALETTE, "success");
    missionEngine.completeMissionSix(option.label);
    this.time.delayedCall(1100, () => this.scene.start("CampaignScene"));
  }

  private updateObjective(): void {
    const text: Record<CityMode, string> = {
      diagnose: "Confronta richiesta e capacità di ogni distretto e seleziona i nodi in sovraccarico.",
      rules: "Abbina a ogni condizione l'azione se/allora che la risolve (leggi anche l'inglese).",
      energy: "Scegli il piano energetico che rispetta tutti i minimi senza superare il budget.",
      civic: "L'energia non basta per tutti: scegli chi proteggere per primo, mettendo prima la vita.",
    };
    this.objectiveText?.setText(text[this.mode]);
  }

  private handleFeedback(message: FeedbackMessage): void {
    const colors = {
      info: "#d9eaf1",
      hint: "#f7d37a",
      success: "#9ff5e9",
      warning: "#ffb36b",
    };
    this.feedbackText?.setColor(colors[message.tone]).setText(message.text);
  }
}
