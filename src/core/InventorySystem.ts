import { saveSystem } from "./SaveSystem";

export class InventorySystem {
  add(itemId: string): void {
    saveSystem.addInventoryItem(itemId);
  }

  has(itemId: string): boolean {
    return saveSystem.data.inventory.includes(itemId);
  }

  list(): string[] {
    return [...saveSystem.data.inventory];
  }
}

export const inventorySystem = new InventorySystem();
