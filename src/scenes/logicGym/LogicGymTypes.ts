export type GymActivityKey = "tables" | "mental" | "geo" | "geoPhysical" | "simon" | "memory" | "code" | "seq" | "balance" | "flash" | "firewall";

export type LogicGymActivityDefinition = {
  key: GymActivityKey;
  title: string;
  glyph: string;
  icon: string;
  theme: string;
  desc: string;
  color: number;
};

export type ActivityMeta = LogicGymActivityDefinition & { start: () => void };

export type MemoryCard = {
  pairId: string;
  label: string;
  rect: Phaser.GameObjects.Rectangle;
  text: Phaser.GameObjects.Text;
  matched: boolean;
  flipped: boolean;
};

export type TablesChallengeMode = "product" | "missing" | "division" | "mental";
export type TablesChallenge = {
  mode: TablesChallengeMode;
  prompt: string;
  answer: number;
  options: number[];
  explanation: string;
  a: number;
  b: number;
};

export type MentalChallengeMode = "bridge" | "difference" | "chain" | "doubleHalf" | "percent" | "splitProduct";
export type MentalChallenge = {
  mode: MentalChallengeMode;
  prompt: string;
  answer: number;
  options: number[];
  explanation: string;
  focus: string;
  chips: string[];
};

export type GeoContinent = "Europa" | "Africa" | "Asia" | "America del Nord" | "America del Sud" | "Oceania";
export type GeoZone = "ovest" | "centro" | "est" | "nord" | "sud";
export type GeoItem = { country: string; capital: string; continent: GeoContinent; zone: GeoZone; fact: string; x: number; y: number };
export type GeoChallengeMode = "continent" | "capital" | "country" | "region";
export type GeoChallenge = {
  mode: GeoChallengeMode;
  item: GeoItem;
  prompt: string;
  answer: string;
  options: string[];
  explanation: string;
  focus: string;
};

export type PhysicalKind = "fiume" | "lago" | "montagna" | "catena montuosa" | "deserto" | "mare" | "stretto";
export type PhysicalFeature = { name: string; kind: PhysicalKind; continent: GeoContinent; region: GeoZone; clue: string; x: number; y: number };
export type PhysicalChallengeMode = "kind" | "continent" | "name" | "clue";
export type PhysicalChallenge = {
  mode: PhysicalChallengeMode;
  feature: PhysicalFeature;
  prompt: string;
  answer: string;
  options: string[];
  explanation: string;
  focus: string;
};

export type FirewallAction = "allow" | "block" | "quarantine" | "inspect";
export type FirewallLens = "identity" | "content" | "route" | "priority";
export type FirewallPayload = "pulito" | "rumoroso" | "criptato" | "esca";
export type FirewallRoute = "interna" | "esterna" | "sconosciuta";
export type FirewallSignal = {
  id: string;
  scenario: string;
  task: string;
  color: "blu" | "verde" | "rosso" | "ambra" | "viola";
  origin: string;
  port: number;
  signature: "stabile" | "mancante" | "alterata" | "incerta";
  payload: FirewallPayload;
  route: FirewallRoute;
  repeated: boolean;
  priority: boolean;
  threat: number;
  diagnosis: string;
  correctAction: FirewallAction;
  reason: string;
};
