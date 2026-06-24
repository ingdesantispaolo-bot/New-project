import Phaser from "phaser";

export const EventBus = new Phaser.Events.EventEmitter();

export const GameEvents = {
  SaveChanged: "save:changed",
  Feedback: "feedback",
  InventoryChanged: "inventory:changed",
  CompetencyChanged: "competency:changed",
  MissionChanged: "mission:changed",
  SettingsChanged: "settings:changed",
} as const;
