import type { FeedbackTone } from "../types/gameTypes";
import { EventBus, GameEvents } from "./EventBus";

export type FeedbackMessage = {
  text: string;
  tone: FeedbackTone;
};

export class FeedbackSystem {
  publish(text: string, tone: FeedbackTone = "info"): void {
    EventBus.emit(GameEvents.Feedback, { text, tone } satisfies FeedbackMessage);
  }

  circuitOpen(): void {
    this.publish("Il LED non si accende: forse il percorso della corrente è interrotto.", "hint");
  }

  robotWall(): void {
    this.publish("Il robot ha urtato il muro: controlla se hai dato troppi comandi avanti.", "hint");
  }

  mathClose(): void {
    this.publish("Il codice è vicino: hai completato una parte della traccia, ma manca ancora un passaggio.", "hint");
  }

  englishRedButton(): void {
    this.publish("Hai scelto il bottone rosso, ma l'istruzione diceva: Do not press the red button.", "hint");
  }
}

export const feedbackSystem = new FeedbackSystem();
