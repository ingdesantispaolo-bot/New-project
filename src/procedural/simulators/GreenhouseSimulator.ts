export type PlantNeedProfile = {
  id: string;
  ideal: { water: number; light: number; temperature: number };
  tolerance: { water: number; light: number; temperature: number };
};

export type GreenhouseState = {
  water: number;
  light: number;
  temperature: number;
  health: number;
};

export type GreenhouseAction =
  | { type: "water"; delta: number }
  | { type: "light"; delta: number }
  | { type: "temperature"; delta: number };

export class GreenhouseSimulator {
  scorePlant(profile: PlantNeedProfile, state: GreenhouseState): number {
    const distance =
      Math.abs(state.water - profile.ideal.water) / profile.tolerance.water +
      Math.abs(state.light - profile.ideal.light) / profile.tolerance.light +
      Math.abs(state.temperature - profile.ideal.temperature) / profile.tolerance.temperature;
    return Math.max(0, Math.min(100, 100 - distance * 18));
  }

  applyAction(profile: PlantNeedProfile, state: GreenhouseState, action: GreenhouseAction): GreenhouseState {
    const next = { ...state, [action.type]: Math.max(0, Math.min(100, state[action.type] + action.delta)) };
    const target = this.scorePlant(profile, next);
    return { ...next, health: Math.max(0, Math.min(100, next.health + (target - next.health) * 0.35)) };
  }

  explain(profile: PlantNeedProfile, state: GreenhouseState): string {
    const gaps = [
      { key: "acqua", value: state.water - profile.ideal.water },
      { key: "luce", value: state.light - profile.ideal.light },
      { key: "temperatura", value: state.temperature - profile.ideal.temperature },
    ].sort((a, b) => Math.abs(b.value) - Math.abs(a.value));
    const worst = gaps[0];
    return worst.value > 0
      ? `${worst.key} troppo alta: riduci un parametro e osserva il grafico.`
      : `${worst.key} troppo bassa: aumenta un parametro e osserva il grafico.`;
  }
}
