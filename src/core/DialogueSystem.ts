import { dialogues, type DialogueLine } from "../data/dialogues";

export class DialogueSystem {
  getDialogue(id: string): DialogueLine[] {
    return dialogues[id] ?? [];
  }

  format(id: string): string[] {
    return this.getDialogue(id).map((line) => `${line.speaker}: ${line.text}`);
  }
}

export const dialogueSystem = new DialogueSystem();
