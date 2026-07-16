import Phaser from "phaser";
import { audioManager } from "../../core/AudioManager";
import { feedbackSystem } from "../../core/FeedbackSystem";
import { noraKnowledge } from "../../core/NoraKnowledge";
import { noraPresence } from "../../ui/NoraPresence";
import type { ProceduralPuzzleKind } from "../../procedural/ProceduralTypes";
import { theoryTopics, type TheoryTopic } from "../../data/theoryCatalog";
import { Button } from "../../ui/Button";
import { SceneChrome } from "../../ui/SceneChrome";
import { drawTheoryVisual } from "../../ui/TheoryVisual";
import { VisualKit } from "../../ui/VisualKit";

export type NoraTheoryPuzzle = Parameters<typeof noraKnowledge.topicForPuzzle>[1];

export function noraTheoryTopicFor(kind: ProceduralPuzzleKind, puzzle?: NoraTheoryPuzzle): TheoryTopic | undefined {
  return noraKnowledge.topicForPuzzle(kind, puzzle);
}

export function addNoraTheoryButton(
  scene: Phaser.Scene,
  overlay: Phaser.GameObjects.Container,
  kind: ProceduralPuzzleKind | undefined,
  puzzle: NoraTheoryPuzzle,
  x: number,
  y: number,
  onOpenStudyPage: (topic: TheoryTopic) => void,
): void {
  if (!kind) return;
  const topic = noraTheoryTopicFor(kind, puzzle);
  if (!topic) return;
  overlay.add(new Button(scene, x, y, "Teoria NORA", () => showNoraTheoryPanel(scene, topic, onOpenStudyPage), {
    width: 148,
    height: 38,
    fontSize: 12,
    fill: 0x173b36,
    stroke: 0xf6c85f,
  }));
}

/**
 * Pannello di PRIMO incontro con un concetto, registro prima media: aggancio
 * concreto, parole nuove, un solo esempio guidato. La scheda densa dell'Atlante
 * resta a un tocco ("Approfondisci"). Se il topic non ha un intro dedicato,
 * ripiega sulla scheda NORA classica.
 */
export function showFirstEncounterPanel(
  scene: Phaser.Scene,
  topic: TheoryTopic,
  onOpenStudyPage: (topic: TheoryTopic) => void,
  onProceed: () => void,
): void {
  const intro = topic.intro;
  if (!intro) {
    showNoraTheoryPanel(scene, topic, onOpenStudyPage);
    return;
  }
  audioManager.playOutcome("hint");
  noraPresence.speak(scene, "Questo è nuovo: te lo spiego io prima, poi provi tu. Nessuna fretta.", "info", 4600);

  const modal = scene.add.container(0, 0).setDepth(1800);
  SceneChrome.modalInputBlocker(scene, modal);
  modal.add(scene.add.rectangle(640, 360, 1280, 720, 0x02080d, 0.62));
  modal.add(VisualKit.glassPanel(scene, 250, 96, 780, 528, "archive", 0.97));
  modal.add(scene.add.rectangle(250, 96, 780, 5, 0x6be7d6, 0.95).setOrigin(0));
  const yearTag = topic.schoolYear ? ` · ${topic.schoolYear}ª media` : "";
  modal.add(scene.add.text(284, 122, `Concetto nuovo — impariamolo insieme${yearTag}`, {
    fontFamily: "Inter, Arial", fontSize: "14px", color: "#6be7d6", fontStyle: "bold",
  }));
  modal.add(scene.add.text(284, 146, topic.title, {
    fontFamily: "Inter, Arial", fontSize: "27px", color: "#f5fbff", fontStyle: "bold", wordWrap: { width: 700 },
  }));

  // Riga "si appoggia su" — mostra i mattoni precedenti, senza appesantire.
  const prereqTitles = (topic.prerequisites ?? [])
    .map((id) => theoryTopics.find((candidate) => candidate.id === id)?.title)
    .filter((title): title is string => Boolean(title));
  let hookTop = 194;
  if (prereqTitles.length > 0) {
    modal.add(scene.add.text(284, 184, `Si appoggia su: ${prereqTitles.join(" · ")}`, {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0", wordWrap: { width: 700 },
    }));
    hookTop = 210;
  }

  // Aggancio concreto.
  modal.add(scene.add.text(284, hookTop, intro.hook, {
    fontFamily: "Inter, Arial", fontSize: "17px", color: "#eaf4f8", wordWrap: { width: 712, useAdvancedWrap: true }, lineSpacing: 6,
  }));

  let cursorY = hookTop + measureHeight(scene, intro.hook, 17, 712, 6) + 22;

  // Parole nuove.
  if (intro.newWords) {
    const boxTop = cursorY;
    const textH = measureHeight(scene, intro.newWords, 14, 690, 5);
    modal.add(scene.add.rectangle(284, boxTop, 712, textH + 44, 0x0b2230, 0.8).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.3));
    modal.add(scene.add.text(300, boxTop + 12, "PAROLE NUOVE", {
      fontFamily: "Inter, Arial", fontSize: "12px", color: "#6be7d6", fontStyle: "bold",
    }));
    modal.add(scene.add.text(300, boxTop + 32, intro.newWords, {
      fontFamily: "Inter, Arial", fontSize: "14px", color: "#d9eaf1", wordWrap: { width: 690, useAdvancedWrap: true }, lineSpacing: 5,
    }));
    cursorY = boxTop + textH + 44 + 18;
  }

  // Esempio guidato.
  const guidedTop = cursorY;
  const guidedH = measureHeight(scene, intro.guided, 15, 690, 5);
  modal.add(scene.add.rectangle(284, guidedTop, 712, guidedH + 44, 0x10261d, 0.82).setOrigin(0).setStrokeStyle(1, 0x70d68a, 0.34));
  modal.add(scene.add.text(300, guidedTop + 12, "PROVIAMO INSIEME", {
    fontFamily: "Inter, Arial", fontSize: "12px", color: "#70d68a", fontStyle: "bold",
  }));
  modal.add(scene.add.text(300, guidedTop + 32, intro.guided, {
    fontFamily: "Inter, Arial", fontSize: "15px", color: "#f5fbff", wordWrap: { width: 690, useAdvancedWrap: true }, lineSpacing: 5,
  }));

  modal.add(new Button(scene, 452, 588, "Ho capito, provo!", () => {
    modal.destroy(true);
    onProceed();
  }, { width: 262, height: 46, fontSize: 15, fill: 0x1f5a51, stroke: 0x70d68a, soundKey: "confirm" }));
  modal.add(new Button(scene, 792, 588, "Approfondisci nell'Atlante", () => {
    modal.destroy(true);
    onOpenStudyPage(topic);
  }, { width: 300, height: 46, fontSize: 13, fill: 0x173b36, stroke: 0x6be7d6 }));
}

/** Stima l'altezza di un testo con wrap, per impilare i riquadri senza sovrapposizioni. */
function measureHeight(scene: Phaser.Scene, text: string, fontSize: number, wrapWidth: number, lineSpacing: number): number {
  const probe = scene.add.text(0, 0, text, {
    fontFamily: "Inter, Arial", fontSize: `${fontSize}px`, wordWrap: { width: wrapWidth, useAdvancedWrap: true }, lineSpacing,
  }).setVisible(false);
  const height = probe.height;
  probe.destroy();
  return height;
}

export function showNoraTheoryForPuzzle(
  scene: Phaser.Scene,
  kind: ProceduralPuzzleKind,
  puzzle: NoraTheoryPuzzle,
  onOpenStudyPage: (topic: TheoryTopic) => void,
): void {
  const topic = noraTheoryTopicFor(kind, puzzle);
  if (!topic) {
    feedbackSystem.publish("NORA non ha ancora una scheda teorica pronta per questa console.", "hint");
    return;
  }
  showNoraTheoryPanel(scene, topic, onOpenStudyPage);
}

export function showNoraTheoryPanel(
  scene: Phaser.Scene,
  topic: TheoryTopic,
  onOpenStudyPage: (topic: TheoryTopic) => void,
): void {
  audioManager.playOutcome("hint");
  noraPresence.speak(scene, noraKnowledge.noraBrief(topic), "info", 5200);

  const modal = scene.add.container(0, 0).setDepth(1800);
  SceneChrome.modalInputBlocker(scene, modal);
  modal.add(scene.add.rectangle(640, 360, 1280, 720, 0x02080d, 0.58));
  modal.add(VisualKit.glassPanel(scene, 210, 82, 860, 556, "archive", 0.96));
  modal.add(scene.add.rectangle(210, 82, 860, 5, 0xf6c85f, 0.95).setOrigin(0));
  modal.add(scene.add.text(244, 112, `NORA spiega · ${topic.title}`, {
    fontFamily: "Inter, Arial",
    fontSize: "25px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 760 },
  }));
  modal.add(scene.add.text(246, 148, `${topic.area} · profondità ${topic.levelRange[0]}-${topic.levelRange[1]} · ${topic.tags.slice(0, 4).join(" · ")}`, {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#f7d37a",
    wordWrap: { width: 760 },
  }));

  modal.add(drawTheoryVisual(scene, topic, 248, 188, { width: 220, height: 154 }));
  modal.add(scene.add.text(512, 192, topic.noraExplanation, {
    fontFamily: "Inter, Arial",
    fontSize: "14px",
    color: "#eaf4f8",
    wordWrap: { width: 500, useAdvancedWrap: true },
    lineSpacing: 4,
  }));
  modal.add(scene.add.text(512, 286, `Metodo: ${topic.method.slice(0, 3).join("  ->  ")}`, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#9ff5e9",
    wordWrap: { width: 500, useAdvancedWrap: true },
    lineSpacing: 4,
  }));

  modal.add(scene.add.rectangle(246, 384, 786, 124, 0x07151d, 0.78).setOrigin(0).setStrokeStyle(1, 0x6be7d6, 0.28));
  modal.add(scene.add.text(268, 402, "ESEMPIO", {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#6be7d6",
    fontStyle: "bold",
  }));
  modal.add(scene.add.text(268, 424, topic.example.prompt, {
    fontFamily: "Inter, Arial",
    fontSize: "13px",
    color: "#f5fbff",
    fontStyle: "bold",
    wordWrap: { width: 350 },
  }));
  modal.add(scene.add.text(640, 408, [...topic.example.steps.slice(0, 3), `= ${topic.example.answer}`].map((step) => `- ${step}`).join("\n"), {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#d9eaf1",
    wordWrap: { width: 360, useAdvancedWrap: true },
    lineSpacing: 4,
  }));

  modal.add(scene.add.rectangle(246, 526, 786, 64, 0x1a1410, 0.86).setOrigin(0).setStrokeStyle(1, 0xffb36b, 0.36));
  modal.add(scene.add.text(268, 542, `Attenzione: ${topic.watchOut.slice(0, 2).join("  ·  ")}`, {
    fontFamily: "Inter, Arial",
    fontSize: "12px",
    color: "#f3d9c4",
    wordWrap: { width: 740, useAdvancedWrap: true },
  }));

  modal.add(new Button(scene, 444, 620, "Apri scheda nell'Atlante", () => {
    modal.destroy(true);
    onOpenStudyPage(topic);
  }, { width: 270, height: 38, fontSize: 13, fill: 0x173b36, stroke: 0x6be7d6 }));
  modal.add(new Button(scene, 806, 620, "Torna all'esercizio", () => modal.destroy(true), {
    width: 220,
    height: 38,
    fontSize: 13,
    fill: 0x263743,
  }));
}
