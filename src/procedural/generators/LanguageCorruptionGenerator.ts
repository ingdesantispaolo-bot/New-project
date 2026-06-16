import { languageTemplates } from "../../data/procedural/languageTemplates";
import type { LanguageTemplate } from "../../data/procedural/languageTemplates";
import type { GeneratedLanguagePuzzle } from "../ProceduralTypes";
import type { Random } from "../Random";

export class LanguageCorruptionGenerator {
  generate(random: Random, difficultyLevel = 1, preferredTemplateIds: string[] = []): GeneratedLanguagePuzzle {
    const eligibleTemplates = languageTemplates.filter((template) => (template.minDifficulty ?? 1) <= difficultyLevel);
    const floor = Math.max(1, difficultyLevel - 2);
    const focusedTemplates = eligibleTemplates.filter((template) => (template.minDifficulty ?? 1) >= floor);
    const pool = focusedTemplates.length > 0 ? focusedTemplates : eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates;
    const preferredPool = preferredTemplateIds.length > 0
      ? (eligibleTemplates.length > 0 ? eligibleTemplates : languageTemplates).filter((template) => preferredTemplateIds.includes(template.id))
      : [];
    const template = random.pick(preferredPool.length > 0 ? preferredPool : pool);
    const options = random.shuffle([template.repaired, ...template.distractors]);
    return this.buildPuzzle(template, options, difficultyLevel);
  }

  private buildPuzzle(template: LanguageTemplate, options: string[], difficultyLevel: number): GeneratedLanguagePuzzle {
    const conceptTags = template.conceptTags ?? this.defaultConceptTags(template.id);
    const optionFeedback = this.buildOptionFeedback(template);
    return {
      id: `language-${template.id}`,
      title: template.title,
      corrupted: template.corrupted,
      repaired: template.repaired,
      options,
      diagnosticSteps: template.diagnosticSteps,
      hints: template.hints,
      competencies: this.competenciesFor(template.id),
      difficultyLabel: `Livello ${Math.max(1, Math.min(8, difficultyLevel))} - ${this.levelName(difficultyLevel)}`,
      conceptTags,
      learningPurpose: template.learningPurpose ?? `Allena ${conceptTags.join(", ")} dentro un messaggio tecnico da rendere eseguibile.`,
      repairGoal: template.repairGoal ?? "Trasforma il log corrotto in una frase chiara, corretta e utile al sistema.",
      method: template.method ?? "Trova soggetto e azione, controlla accordi e connettivi, poi verifica che il significato tecnico non cambi.",
      optionFeedback,
    };
  }

  fallback(): GeneratedLanguagePuzzle {
    const template = languageTemplates[0];
    return { ...this.buildPuzzle(template, [template.repaired, ...template.distractors], 1), id: "language-fallback" };
  }

  private buildOptionFeedback(template: LanguageTemplate): Record<string, string> {
    const feedback: Record<string, string> = {};
    template.distractors.forEach((option, index) => {
      feedback[option] = template.distractorFeedback?.[option]
        ?? `Questa versione sembra plausibile, ma non supera il controllo ${index + 1}: ${template.diagnosticSteps[index % template.diagnosticSteps.length]} ${template.hints[index % template.hints.length]}`;
    });
    feedback[template.repaired] = "Riparazione coerente: grammatica, significato tecnico e ordine operativo restano allineati.";
    return feedback;
  }

  private defaultConceptTags(templateId: string): string[] {
    if (["single-generator", "north-sensor", "sealed-door", "unstable-log", "robot-report"].includes(templateId)) {
      return ["accordo", "soggetto", "coesione"];
    }
    if (["apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return ["ortografia", "accenti", "apostrofi"];
    }
    if (["cause-effect-cooling", "useful-vs-noise"].includes(templateId)) {
      return ["causa-effetto", "connettivi", "informazioni utili"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns"].includes(templateId)) {
      return ["pronomi", "riferimenti", "ambiguita"];
    }
    if (["relative-clause", "relative-cui"].includes(templateId)) {
      return ["frase relativa", "soggetto", "reggenza"];
    }
    if (templateId === "conditional-alert") {
      return ["negazione", "condizione", "sicurezza"];
    }
    if (["technical-summary", "sequence-before-after"].includes(templateId)) {
      return ["ordine logico", "sequenza", "coesione"];
    }
    if (["punctuation-safety"].includes(templateId)) {
      return ["punteggiatura", "condizione", "chiarezza"];
    }
    if (["source-reliability", "thesis-evidence"].includes(templateId)) {
      return ["pensiero critico", "tesi e prova", "fonte"];
    }
    if (["lexical-precision", "nominalization-precision", "register-formal"].includes(templateId)) {
      return ["lessico tecnico", "precisione", "significato"];
    }
    if (["passive-active"].includes(templateId)) {
      return ["forma passiva", "agente", "accordo"];
    }
    if (["reported-speech-log"].includes(templateId)) {
      return ["discorso indiretto", "reggenza", "soglia"];
    }
    if (["main-idea-summary"].includes(templateId)) {
      return ["sintesi", "informazioni utili", "causa-effetto"];
    }
    if (["period-hypothesis"].includes(templateId)) {
      return ["periodo ipotetico", "congiuntivo", "condizionale"];
    }
    if (["implicit-subject"].includes(templateId)) {
      return ["subordinata implicita", "soggetto", "chiarezza"];
    }
    return ["comprensione", "grammatica", "coerenza"];
  }

  private competenciesFor(templateId: string): string[] {
    const base = ["italiano.comprensione", "italiano.grammatica", "pensieroCritico"];
    if (["lexical-precision", "nominalization-precision", "register-formal", "useful-vs-noise"].includes(templateId)) {
      return [...base, "italiano.lessico"];
    }
    if (["main-idea-summary", "technical-summary", "source-reliability", "thesis-evidence"].includes(templateId)) {
      return [...base, "italiano.scritturaBreve", "italiano.argomentazione"];
    }
    if (["punctuation-safety", "apostrophe-accent", "ha-a-control"].includes(templateId)) {
      return [...base, "italiano.punteggiatura"];
    }
    if (["pronoun-reference", "direct-indirect-pronouns", "relative-clause", "relative-cui", "implicit-subject"].includes(templateId)) {
      return [...base, "italiano.coesione"];
    }
    return base;
  }

  private levelName(level: number): string {
    if (level <= 2) return "ortografia e accordi fondamentali";
    if (level <= 4) return "connettivi, pronomi e coerenza";
    if (level <= 6) return "frasi complesse e sintesi";
    return "argomentazione, registro e precisione";
  }
}
