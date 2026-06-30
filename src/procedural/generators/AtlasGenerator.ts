import {
  atlasGrid,
  cardinalLabels,
  DIRECTION_VECTORS,
  OPPOSITE,
  type AtlasBearing,
  type AtlasCoordinate,
  type AtlasScaleProblem,
  type AtlasVariant,
  type Cardinal,
} from "../../data/atlas";
import { Random } from "../Random";

const STATION_NAMES = [
  "Stazione Porto",
  "Stazione Cresta",
  "Stazione Campana",
  "Stazione Faro",
  "Stazione Vedetta",
  "Stazione Molo",
  "Stazione Collina",
  "Stazione Radura",
];

const ENGLISH_DIR: Record<Cardinal, string> = {
  N: "north",
  NE: "north-east",
  E: "east",
  SE: "south-east",
  S: "south",
  SW: "south-west",
  W: "west",
  NW: "north-west",
};

const ALL_DIRECTIONS: Cardinal[] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];

type Station = { id: string; dir: Cardinal; x: number; y: number };

/**
 * Generates a seeded, fully solvable "Atlante Perduto" puzzle: three listening
 * stations whose bearings cross at a single source cell. The geometry is built
 * by placing each station on the ray that points (in a pure cardinal/ordinal
 * direction) at a chosen source, then rejection-validated so the three stations
 * are distinct, on-grid, and never collinear (no opposite directions).
 */
export class AtlasGenerator {
  constructor(private readonly random: Random) {}

  generate(): AtlasVariant {
    const { source, stations } = this.sampleGeometry();
    const names = this.random.shuffle(STATION_NAMES).slice(0, 3);

    const bearings: AtlasBearing[] = stations.map((station, index) => ({
      id: station.id,
      station: names[index],
      radioEnglish: this.radio(names[index], station.dir),
      italianGloss: `"${ENGLISH_DIR[station.dir]}" = ${cardinalLabels[station.dir].toLowerCase()}.`,
      answer: station.dir,
    }));

    const coordinates: AtlasCoordinate[] = stations.map((station, index) => ({
      id: station.id,
      station: names[index],
      x: station.x,
      y: station.y,
      clue: `${names[index]} è registrata in (${station.x}, ${station.y}): colonna ${station.x}, riga ${station.y}.`,
    }));

    return {
      grid: { ...atlasGrid },
      source,
      bearings,
      coordinates,
      scale: this.makeScale(),
    };
  }

  private radio(station: string, dir: Cardinal): string {
    const english = ENGLISH_DIR[dir];
    const templates = [
      `${station} to Academy: the source lies to our ${english}.`,
      `${station} calling: the trace bears ${english} from our position.`,
    ];
    return this.random.pick(templates);
  }

  private sampleGeometry(): { source: { x: number; y: number }; stations: Station[] } {
    for (let attempt = 0; attempt < 400; attempt += 1) {
      const source = {
        x: this.random.integer(3, atlasGrid.cols - 4),
        y: this.random.integer(2, atlasGrid.rows - 3),
      };
      const chosen = this.random.shuffle(ALL_DIRECTIONS).slice(0, 3);
      if (this.hasOppositePair(chosen)) {
        continue;
      }
      const stations: Station[] = chosen.map((dir, index) => {
        const k = this.random.integer(2, 3);
        const vector = DIRECTION_VECTORS[dir];
        return { id: `station-${index}`, dir, x: source.x - vector.dx * k, y: source.y - vector.dy * k };
      });
      if (this.isValid(source, stations)) {
        return { source, stations };
      }
    }
    return this.fallback();
  }

  private hasOppositePair(dirs: Cardinal[]): boolean {
    return dirs.some((a) => dirs.includes(OPPOSITE[a]));
  }

  private isValid(source: { x: number; y: number }, stations: Station[]): boolean {
    const seen = new Set<string>();
    for (const station of stations) {
      if (station.x < 0 || station.x >= atlasGrid.cols || station.y < 0 || station.y >= atlasGrid.rows) {
        return false;
      }
      if (station.x === source.x && station.y === source.y) {
        return false;
      }
      const key = `${station.x},${station.y}`;
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
    }
    return true;
  }

  private fallback(): { source: { x: number; y: number }; stations: Station[] } {
    const source = { x: 5, y: 4 };
    return {
      source,
      stations: [
        { id: "station-0", dir: "SE", x: 3, y: 2 },
        { id: "station-1", dir: "S", x: 5, y: 2 },
        { id: "station-2", dir: "SW", x: 7, y: 2 },
      ],
    };
  }

  private makeScale(): AtlasScaleProblem {
    const col = this.random.integer(1, atlasGrid.cols - 2);
    const ay = this.random.integer(0, atlasGrid.rows - 4);
    const gridDistance = this.random.integer(3, Math.min(5, atlasGrid.rows - 1 - ay));
    const by = ay + gridDistance;
    const kmPerCell = this.random.pick([10, 15, 20, 25]);
    const answerKm = gridDistance * kmPerCell;
    return {
      prompt: `Per raggiungere la sorgente devi sapere quanto è lontana davvero. Sull'atlante il Faro è in (${col}, ${ay}) e il Porto Vecchio in (${col}, ${by}).`,
      fromLabel: `Faro (${col}, ${ay})`,
      toLabel: `Porto Vecchio (${col}, ${by})`,
      gridDistance,
      kmPerCell,
      answerKm,
      hint: `Conta le celle lungo la colonna: da ${ay} a ${by} sono ${gridDistance} celle. Poi moltiplica per la scala (${kmPerCell} km a cella).`,
    };
  }
}
