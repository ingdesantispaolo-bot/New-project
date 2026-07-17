import Phaser from "phaser";
import { audioManager } from "../core/AudioManager";
import { competencyTracker } from "../core/CompetencyTracker";
import { playerSystem } from "../core/PlayerSystem";
import { saveSystem } from "../core/SaveSystem";
import { queueSceneAssets } from "../core/SceneAssetLoader";
import { settingsSystem } from "../core/SettingsSystem";
import { buildMemoryPairs, generateBalance, LogicSequenceGenerator, type BalancePuzzle, type LogicSequence, type MemoryPair } from "../procedural/generators/LogicGymContent";
import { Random } from "../procedural/Random";
import type { LogicGymBonusActivityKey, LogicGymBonusResult, LogicGymSceneData } from "../types/logicGymBonus";
import { Button } from "../ui/Button";
import { VisualKit } from "../ui/VisualKit";
import { CODE_SYMBOLS, GYM_MAX_LEVEL, GYM_MIN_LEVEL, LOGIC_GYM_ACTIVITIES, PAD_COLORS, logicGymActivityLevelLine, logicGymLevelSubtitle, type LogicGymLevelMetrics } from "./logicGym/LogicGymActivities";
import { accuracyPercent, activityAward, firewallScore, memoryEfficiencyScore, missionBonusResult, roundAccuracyScore, timedActivityScore } from "./logicGym/LogicGymScoring";
import { renderLogicGymBackBar, renderLogicGymHub, type LogicGymHubActivity } from "./logicGym/LogicGymHud";
import type { ActivityMeta, FirewallAction, FirewallLens, FirewallPayload, FirewallRoute, FirewallSignal, GeoChallenge, GeoChallengeMode, GeoContinent, GeoItem, GeoZone, GymActivityKey, MemoryCard, MentalChallenge, MentalChallengeMode, PhysicalChallenge, PhysicalChallengeMode, PhysicalFeature, PhysicalKind, TablesChallenge, TablesChallengeMode } from "./logicGym/LogicGymTypes";
const GEO_CONTINENTS: GeoContinent[] = ["Europa", "Africa", "Asia", "America del Nord", "America del Sud", "Oceania"];
const GEO_ATLAS: GeoItem[] = [
  { country: "Italia", capital: "Roma", continent: "Europa", zone: "sud", fact: "penisola nel Mediterraneo", x: 596, y: 304 },
  { country: "Francia", capital: "Parigi", continent: "Europa", zone: "ovest", fact: "tra Atlantico e Mediterraneo", x: 564, y: 282 },
  { country: "Spagna", capital: "Madrid", continent: "Europa", zone: "sud", fact: "occupa gran parte della penisola iberica", x: 526, y: 316 },
  { country: "Germania", capital: "Berlino", continent: "Europa", zone: "centro", fact: "cuore dell'Europa centrale", x: 594, y: 256 },
  { country: "Portogallo", capital: "Lisbona", continent: "Europa", zone: "ovest", fact: "affacciato sull'Atlantico", x: 500, y: 320 },
  { country: "Grecia", capital: "Atene", continent: "Europa", zone: "sud", fact: "ponte tra Balcani e Mediterraneo orientale", x: 650, y: 332 },
  { country: "Regno Unito", capital: "Londra", continent: "Europa", zone: "ovest", fact: "isola a nord-ovest dell'Europa", x: 536, y: 246 },
  { country: "Irlanda", capital: "Dublino", continent: "Europa", zone: "ovest", fact: "isola verde dell'Atlantico", x: 510, y: 242 },
  { country: "Norvegia", capital: "Oslo", continent: "Europa", zone: "nord", fact: "fiordi e coste del Nord Europa", x: 586, y: 198 },
  { country: "Svezia", capital: "Stoccolma", continent: "Europa", zone: "nord", fact: "penisola scandinava", x: 620, y: 206 },
  { country: "Finlandia", capital: "Helsinki", continent: "Europa", zone: "nord", fact: "tra Baltico e grandi foreste", x: 656, y: 210 },
  { country: "Polonia", capital: "Varsavia", continent: "Europa", zone: "est", fact: "pianura dell'Europa centro-orientale", x: 628, y: 262 },
  { country: "Austria", capital: "Vienna", continent: "Europa", zone: "centro", fact: "area alpina e danubiana", x: 610, y: 286 },
  { country: "Ungheria", capital: "Budapest", continent: "Europa", zone: "centro", fact: "attraversata dal Danubio", x: 630, y: 294 },
  { country: "Romania", capital: "Bucarest", continent: "Europa", zone: "est", fact: "tra Carpazi e Mar Nero", x: 664, y: 304 },
  { country: "Ucraina", capital: "Kyiv", continent: "Europa", zone: "est", fact: "grande paese dell'Europa orientale", x: 682, y: 274 },
  { country: "Turchia", capital: "Ankara", continent: "Asia", zone: "ovest", fact: "tra Anatolia e ponte euroasiatico", x: 700, y: 334 },
  { country: "Egitto", capital: "Il Cairo", continent: "Africa", zone: "nord", fact: "attraversato dal Nilo", x: 670, y: 410 },
  { country: "Marocco", capital: "Rabat", continent: "Africa", zone: "nord", fact: "tra Atlantico, Mediterraneo e Atlante", x: 500, y: 392 },
  { country: "Algeria", capital: "Algeri", continent: "Africa", zone: "nord", fact: "grande paese del Maghreb", x: 548, y: 404 },
  { country: "Tunisia", capital: "Tunisi", continent: "Africa", zone: "nord", fact: "vicina alla Sicilia", x: 594, y: 386 },
  { country: "Nigeria", capital: "Abuja", continent: "Africa", zone: "ovest", fact: "paese popoloso dell'Africa occidentale", x: 570, y: 480 },
  { country: "Ghana", capital: "Accra", continent: "Africa", zone: "ovest", fact: "sul Golfo di Guinea", x: 540, y: 486 },
  { country: "Senegal", capital: "Dakar", continent: "Africa", zone: "ovest", fact: "punta occidentale del continente africano", x: 486, y: 462 },
  { country: "Etiopia", capital: "Addis Abeba", continent: "Africa", zone: "est", fact: "altopiani del Corno d'Africa", x: 706, y: 480 },
  { country: "Kenya", capital: "Nairobi", continent: "Africa", zone: "est", fact: "attraversato dall'Equatore", x: 704, y: 520 },
  { country: "Tanzania", capital: "Dodoma", continent: "Africa", zone: "est", fact: "area dei grandi laghi africani", x: 692, y: 548 },
  { country: "Cina", capital: "Pechino", continent: "Asia", zone: "est", fact: "grande paese dell'Asia orientale", x: 900, y: 322 },
  { country: "Giappone", capital: "Tokyo", continent: "Asia", zone: "est", fact: "arcipelago del Pacifico", x: 1012, y: 340 },
  { country: "Corea del Sud", capital: "Seul", continent: "Asia", zone: "est", fact: "penisola coreana meridionale", x: 966, y: 330 },
  { country: "India", capital: "Nuova Delhi", continent: "Asia", zone: "sud", fact: "subcontinente dell'Asia meridionale", x: 814, y: 408 },
  { country: "Indonesia", capital: "Giacarta", continent: "Asia", zone: "sud", fact: "arcipelago tra oceano Indiano e Pacifico", x: 912, y: 520 },
  { country: "Thailandia", capital: "Bangkok", continent: "Asia", zone: "sud", fact: "Sud-est asiatico continentale", x: 884, y: 438 },
  { country: "Vietnam", capital: "Hanoi", continent: "Asia", zone: "sud", fact: "costa lunga sul Mar Cinese Meridionale", x: 914, y: 426 },
  { country: "Filippine", capital: "Manila", continent: "Asia", zone: "sud", fact: "arcipelago del Pacifico occidentale", x: 966, y: 434 },
  { country: "Arabia Saudita", capital: "Riad", continent: "Asia", zone: "ovest", fact: "penisola arabica", x: 730, y: 414 },
  { country: "Emirati Arabi Uniti", capital: "Abu Dhabi", continent: "Asia", zone: "ovest", fact: "costa del Golfo Persico", x: 762, y: 420 },
  { country: "Iran", capital: "Teheran", continent: "Asia", zone: "ovest", fact: "altopiano tra Medio Oriente e Asia centrale", x: 746, y: 374 },
  { country: "Canada", capital: "Ottawa", continent: "America del Nord", zone: "nord", fact: "grande paese del Nord America", x: 270, y: 228 },
  { country: "Stati Uniti", capital: "Washington, D.C.", continent: "America del Nord", zone: "centro", fact: "tra Atlantico e Pacifico", x: 290, y: 316 },
  { country: "Messico", capital: "Citta del Messico", continent: "America del Nord", zone: "sud", fact: "tra Stati Uniti e America centrale", x: 246, y: 392 },
  { country: "Cuba", capital: "L'Avana", continent: "America del Nord", zone: "sud", fact: "isola dei Caraibi", x: 336, y: 404 },
  { country: "Brasile", capital: "Brasilia", continent: "America del Sud", zone: "est", fact: "il piu grande paese sudamericano", x: 430, y: 530 },
  { country: "Argentina", capital: "Buenos Aires", continent: "America del Sud", zone: "sud", fact: "verso il cono sud", x: 394, y: 616 },
  { country: "Cile", capital: "Santiago", continent: "America del Sud", zone: "sud", fact: "striscia lunga lungo le Ande", x: 350, y: 610 },
  { country: "Peru", capital: "Lima", continent: "America del Sud", zone: "ovest", fact: "Ande e costa pacifica", x: 346, y: 512 },
  { country: "Colombia", capital: "Bogota", continent: "America del Sud", zone: "nord", fact: "porta nord-occidentale del Sud America", x: 356, y: 460 },
  { country: "Venezuela", capital: "Caracas", continent: "America del Sud", zone: "nord", fact: "costa caraibica sudamericana", x: 390, y: 448 },
  { country: "Australia", capital: "Canberra", continent: "Oceania", zone: "sud", fact: "grande isola-continente", x: 1014, y: 606 },
  { country: "Nuova Zelanda", capital: "Wellington", continent: "Oceania", zone: "sud", fact: "arcipelago a sud-est dell'Australia", x: 1120, y: 640 },
  { country: "Figi", capital: "Suva", continent: "Oceania", zone: "est", fact: "arcipelago del Pacifico meridionale", x: 1126, y: 552 },
  { country: "Papua Nuova Guinea", capital: "Port Moresby", continent: "Oceania", zone: "nord", fact: "a nord dell'Australia", x: 1018, y: 510 },
];
const PHYSICAL_KINDS: PhysicalKind[] = ["fiume", "lago", "montagna", "catena montuosa", "deserto", "mare", "stretto"];
const PHYSICAL_FEATURES: PhysicalFeature[] = [
  { name: "Alpi", kind: "catena montuosa", continent: "Europa", region: "centro", clue: "arco montuoso tra Italia, Francia, Svizzera e Austria", x: 588, y: 292 },
  { name: "Appennini", kind: "catena montuosa", continent: "Europa", region: "sud", clue: "dorsale che attraversa la penisola italiana", x: 602, y: 316 },
  { name: "Danubio", kind: "fiume", continent: "Europa", region: "centro", clue: "grande fiume europeo che scorre verso il Mar Nero", x: 632, y: 296 },
  { name: "Reno", kind: "fiume", continent: "Europa", region: "centro", clue: "fiume dell'Europa occidentale collegato al Mare del Nord", x: 574, y: 272 },
  { name: "Mar Mediterraneo", kind: "mare", continent: "Europa", region: "sud", clue: "mare tra Europa meridionale, Africa settentrionale e Asia occidentale", x: 594, y: 360 },
  { name: "Mar Baltico", kind: "mare", continent: "Europa", region: "nord", clue: "mare interno del Nord Europa", x: 642, y: 222 },
  { name: "Stretto di Gibilterra", kind: "stretto", continent: "Europa", region: "sud", clue: "passaggio tra Atlantico e Mediterraneo", x: 500, y: 352 },
  { name: "Sahara", kind: "deserto", continent: "Africa", region: "nord", clue: "il piu grande deserto caldo del mondo", x: 560, y: 414 },
  { name: "Nilo", kind: "fiume", continent: "Africa", region: "nord", clue: "grande fiume africano legato all'Egitto", x: 672, y: 430 },
  { name: "Lago Vittoria", kind: "lago", continent: "Africa", region: "est", clue: "grande lago dell'Africa orientale vicino all'Equatore", x: 704, y: 522 },
  { name: "Kilimangiaro", kind: "montagna", continent: "Africa", region: "est", clue: "alto vulcano isolato dell'Africa orientale", x: 710, y: 544 },
  { name: "Congo", kind: "fiume", continent: "Africa", region: "centro", clue: "fiume dell'Africa equatoriale con enorme bacino", x: 612, y: 520 },
  { name: "Atlante", kind: "catena montuosa", continent: "Africa", region: "nord", clue: "rilievo del Maghreb tra Marocco, Algeria e Tunisia", x: 528, y: 390 },
  { name: "Mar Rosso", kind: "mare", continent: "Africa", region: "est", clue: "mare stretto tra Africa nord-orientale e penisola arabica", x: 702, y: 414 },
  { name: "Himalaya", kind: "catena montuosa", continent: "Asia", region: "sud", clue: "catena con le cime piu alte del pianeta", x: 828, y: 382 },
  { name: "Everest", kind: "montagna", continent: "Asia", region: "sud", clue: "la vetta piu alta del mondo", x: 842, y: 386 },
  { name: "Gange", kind: "fiume", continent: "Asia", region: "sud", clue: "fiume sacro e densamente popolato dell'India settentrionale", x: 830, y: 414 },
  { name: "Lago Baikal", kind: "lago", continent: "Asia", region: "nord", clue: "profondissimo lago della Siberia", x: 900, y: 286 },
  { name: "Deserto del Gobi", kind: "deserto", continent: "Asia", region: "est", clue: "deserto freddo tra Mongolia e Cina", x: 890, y: 330 },
  { name: "Mar Caspio", kind: "mare", continent: "Asia", region: "ovest", clue: "grande bacino chiuso tra Europa orientale e Asia occidentale", x: 734, y: 342 },
  { name: "Stretto di Malacca", kind: "stretto", continent: "Asia", region: "sud", clue: "passaggio marittimo tra penisola malese e Sumatra", x: 900, y: 486 },
  { name: "Montagne Rocciose", kind: "catena montuosa", continent: "America del Nord", region: "ovest", clue: "grande dorsale dell'America nord-occidentale", x: 240, y: 300 },
  { name: "Mississippi", kind: "fiume", continent: "America del Nord", region: "centro", clue: "fiume principale degli Stati Uniti centrali", x: 304, y: 338 },
  { name: "Grandi Laghi", kind: "lago", continent: "America del Nord", region: "nord", clue: "sistema di grandi laghi tra Canada e Stati Uniti", x: 322, y: 270 },
  { name: "Golfo del Messico", kind: "mare", continent: "America del Nord", region: "sud", clue: "bacino marino tra Stati Uniti, Messico e Cuba", x: 300, y: 392 },
  { name: "Stretto di Bering", kind: "stretto", continent: "America del Nord", region: "nord", clue: "passaggio tra Alaska e Siberia", x: 210, y: 190 },
  { name: "Ande", kind: "catena montuosa", continent: "America del Sud", region: "ovest", clue: "lunga catena montuosa lungo il Pacifico sudamericano", x: 350, y: 560 },
  { name: "Rio delle Amazzoni", kind: "fiume", continent: "America del Sud", region: "nord", clue: "fiume immenso della foresta equatoriale sudamericana", x: 402, y: 500 },
  { name: "Lago Titicaca", kind: "lago", continent: "America del Sud", region: "ovest", clue: "alto lago andino tra Peru e Bolivia", x: 350, y: 536 },
  { name: "Deserto di Atacama", kind: "deserto", continent: "America del Sud", region: "ovest", clue: "deserto costiero molto arido del Cile settentrionale", x: 338, y: 588 },
  { name: "Rio de la Plata", kind: "fiume", continent: "America del Sud", region: "sud", clue: "grande estuario tra Argentina e Uruguay", x: 396, y: 612 },
  { name: "Grande Catena Divisoria", kind: "catena montuosa", continent: "Oceania", region: "est", clue: "rilievo lungo l'Australia orientale", x: 1042, y: 604 },
  { name: "Deserto Victoria", kind: "deserto", continent: "Oceania", region: "sud", clue: "grande deserto dell'Australia meridionale", x: 1004, y: 592 },
  { name: "Lago Eyre", kind: "lago", continent: "Oceania", region: "sud", clue: "bacino lacustre interno dell'Australia", x: 1014, y: 580 },
  { name: "Mar dei Coralli", kind: "mare", continent: "Oceania", region: "est", clue: "mare tropicale a nord-est dell'Australia", x: 1060, y: 546 },
  { name: "Stretto di Cook", kind: "stretto", continent: "Oceania", region: "sud", clue: "passaggio tra le due isole principali della Nuova Zelanda", x: 1120, y: 638 },
];

/**
 * "Palestra della Mente" — a transversal logic & memory gym with four distinct,
 * challenging activities that feed the cross-cutting competencies (memoria di
 * lavoro, ragionamento logico) and therefore the Academy's mastery and Core.
 */
export class LogicGymScene extends Phaser.Scene {
  private tracked: Phaser.GameObjects.GameObject[] = [];
  private currentRestart: (() => void) | null = null;
  private gymLevel = 1;
  private bonusMode = false;
  private bonusActivity?: LogicGymBonusActivityKey;
  private bonusId = "";
  private bonusReturnScene = "ProceduralMissionScene";
  private bonusRoundOverride?: number;

  // Tabelline
  private tablesRound = 0;
  private tablesCorrect = 0;
  private tablesCombo = 0;
  private tablesBestCombo = 0;
  private tablesTimeBonus = 0;
  private tablesTotal = 10;
  private tablesLocked = false;
  private tablesStartedAt = 0;
  private tablesTimeLimitMs = 10_000;
  private tablesTimerEvent?: Phaser.Time.TimerEvent;
  private tablesStatus?: Phaser.GameObjects.Text;
  private tablesTimeText?: Phaser.GameObjects.Text;

  // Calcolo mentale
  private mentalRound = 0;
  private mentalCorrect = 0;
  private mentalCombo = 0;
  private mentalBestCombo = 0;
  private mentalTimeBonus = 0;
  private mentalTotal = 10;
  private mentalLocked = false;
  private mentalStartedAt = 0;
  private mentalTimeLimitMs = 10_000;
  private mentalTimerEvent?: Phaser.Time.TimerEvent;
  private mentalStatus?: Phaser.GameObjects.Text;
  private mentalTimeText?: Phaser.GameObjects.Text;

  // Geografia capitali/continenti
  private geoRound = 0;
  private geoCorrect = 0;
  private geoCombo = 0;
  private geoBestCombo = 0;
  private geoTimeBonus = 0;
  private geoTotal = 10;
  private geoLocked = false;
  private geoStartedAt = 0;
  private geoTimeLimitMs = 10_000;
  private geoTimerEvent?: Phaser.Time.TimerEvent;
  private geoStatus?: Phaser.GameObjects.Text;
  private geoTimeText?: Phaser.GameObjects.Text;

  // Geografia fisica
  private physRound = 0;
  private physCorrect = 0;
  private physCombo = 0;
  private physBestCombo = 0;
  private physTimeBonus = 0;
  private physTotal = 10;
  private physLocked = false;
  private physStartedAt = 0;
  private physTimeLimitMs = 10_000;
  private physTimerEvent?: Phaser.Time.TimerEvent;
  private physStatus?: Phaser.GameObjects.Text;
  private physTimeText?: Phaser.GameObjects.Text;

  // Sequenza Luminosa
  private simonPads: Phaser.GameObjects.Rectangle[] = [];
  private simonSeq: number[] = [];
  private simonInput: number[] = [];
  private simonLocked = true;
  private simonStatus?: Phaser.GameObjects.Text;

  // Memory delle Coppie
  private memCards: MemoryCard[] = [];
  private memFlipped: number[] = [];
  private memMoves = 0;
  private memMatched = 0;
  private memPairs = 6;
  private memLocked = false;
  private memStatus?: Phaser.GameObjects.Text;

  // Codice Segreto
  private codeSecret: number[] = [];
  private codeGuess: number[] = [];
  private codeAttempts = 0;
  private codeMax = 8;
  private codeLen = 4;
  private codeSlots: Phaser.GameObjects.Text[] = [];
  private codeStatus?: Phaser.GameObjects.Text;
  private codeHistoryY = 150;

  // Sequenze Logiche
  private seqRound = 0;
  private seqCorrect = 0;
  private seqTotal = 6;

  // Bilancia Logica
  private balRound = 0;
  private balCorrect = 0;
  private balTotal = 6;

  // Griglia Lampo
  private flashCells: Phaser.GameObjects.Rectangle[] = [];
  private flashTarget = new Set<number>();
  private flashTargetOrder: number[] = [];
  private flashPicked = new Set<number>();
  private flashRound = 0;
  private flashLocked = true;
  private flashStatus?: Phaser.GameObjects.Text;

  // Firewall NORA
  private firewallSignals: FirewallSignal[] = [];
  private firewallIndex = 0;
  private firewallCorrect = 0;
  private firewallErrors = 0;
  private firewallLocked = false;
  private firewallStatus?: Phaser.GameObjects.Text;
  private firewallPacket?: Phaser.GameObjects.Container;
  private firewallRoundObjects: Phaser.GameObjects.GameObject[] = [];
  private firewallStreak = 0;
  private firewallBestStreak = 0;
  private firewallStability = 100;
  private firewallRevealed = new Set<FirewallLens>();
  private firewallScansLeft = 0;

  constructor() {
    super("LogicGymScene");
  }

  init(data?: LogicGymSceneData): void {
    this.bonusMode = data?.mode === "missionBonus" && this.isMissionBonusActivity(data.activityKey);
    this.bonusActivity = this.bonusMode ? data?.activityKey : undefined;
    this.bonusId = data?.bonusId ?? `bonus-${Date.now()}`;
    this.bonusReturnScene = data?.returnScene ?? "ProceduralMissionScene";
    this.bonusRoundOverride = this.bonusMode && data?.rounds
      ? Phaser.Math.Clamp(Math.round(data.rounds), 3, 8)
      : undefined;
    if (this.bonusMode && data?.level) {
      this.gymLevel = Phaser.Math.Clamp(Math.round(data.level), GYM_MIN_LEVEL, GYM_MAX_LEVEL);
    }
  }

  preload(): void {
    queueSceneAssets(this, "academy", "logicGym");
  }

  create(): void {
    playerSystem.load();
    saveSystem.load();
    if (!this.bonusMode) {
      this.gymLevel = Phaser.Math.Clamp(saveSystem.data.logicGym?.level ?? 1, GYM_MIN_LEVEL, GYM_MAX_LEVEL);
    }
    this.cameras.main.setBackgroundColor("#071018");
    VisualKit.background(this, "academy", "logic-gym-hub-bg");
    VisualKit.vignette(this);
    if (this.bonusMode) {
      this.startMissionBonusActivity();
      return;
    }
    this.showHub();
  }

  private isMissionBonusActivity(key: unknown): key is LogicGymBonusActivityKey {
    return key === "tables" || key === "mental" || key === "geo" || key === "geoPhysical";
  }

  private startMissionBonusActivity(): void {
    const activity = this.activities().find((item) => item.key === this.bonusActivity);
    if (!activity || !this.isMissionBonusActivity(activity.key)) {
      this.returnFromMissionBonus({
        id: this.bonusId,
        activityKey: "mental",
        label: "Frattura energetica",
        level: this.gymLevel,
        rounds: 0,
        correct: 0,
        score: 0,
        accuracy: 0,
        passed: false,
        perfect: false,
        energyAward: 0,
        timeAwardMs: 0,
        summary: "Evento bonus non disponibile.",
      });
      return;
    }
    this.t(this.add.rectangle(640, 360, 1280, 720, 0x02070b, 0.3));
    this.t(this.add.text(640, 292, "Frattura energetica", {
      fontFamily: "Inter, Arial",
      fontSize: "30px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.t(this.add.text(640, 334, `${activity.title} · ${this.bonusRoundTotal(5)} round rapidi`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.time.delayedCall(520, () => activity.start());
  }

  private bonusRoundTotal(defaultTotal: number): number {
    return this.bonusMode ? (this.bonusRoundOverride ?? Math.min(defaultTotal, 5)) : defaultTotal;
  }

  private activities(): ActivityMeta[] {
    const starts: Record<GymActivityKey, () => void> = {
      tables: () => this.startTables(),
      mental: () => this.startMental(),
      geo: () => this.startGeo(),
      geoPhysical: () => this.startPhysical(),
      simon: () => this.startSimon(),
      memory: () => this.startMemory(),
      code: () => this.startCode(),
      seq: () => this.startSeq(),
      balance: () => this.startBalance(),
      flash: () => this.startFlash(),
      firewall: () => this.startFirewall(),
    };
    return LOGIC_GYM_ACTIVITIES.map((activity) => ({ ...activity, start: starts[activity.key] }));
  }

  // -- Tracking helpers ---------------------------------------------------

  private t<T extends Phaser.GameObjects.GameObject>(object: T): T {
    this.tracked.push(object);
    return object;
  }

  private ft<T extends Phaser.GameObjects.GameObject>(object: T): T {
    this.firewallRoundObjects.push(object);
    return this.t(object);
  }

  private clearFirewallRound(): void {
    const doomed = new Set(this.firewallRoundObjects);
    this.firewallRoundObjects.forEach((object) => object.destroy());
    this.tracked = this.tracked.filter((object) => !doomed.has(object));
    this.firewallRoundObjects = [];
    this.firewallPacket = undefined;
  }

  private clearScreen(): void {
    this.tablesTimerEvent?.remove(false);
    this.tablesTimerEvent = undefined;
    this.tablesStatus = undefined;
    this.tablesTimeText = undefined;
    this.mentalTimerEvent?.remove(false);
    this.mentalTimerEvent = undefined;
    this.mentalStatus = undefined;
    this.mentalTimeText = undefined;
    this.geoTimerEvent?.remove(false);
    this.geoTimerEvent = undefined;
    this.geoStatus = undefined;
    this.geoTimeText = undefined;
    this.physTimerEvent?.remove(false);
    this.physTimerEvent = undefined;
    this.physStatus = undefined;
    this.physTimeText = undefined;
    this.firewallRoundObjects = [];
    this.tracked.forEach((object) => object.destroy());
    this.tracked = [];
    this.simonPads = [];
    this.memCards = [];
    this.memFlipped = [];
    this.codeSlots = [];
    this.firewallPacket = undefined;
  }

  private best(key: string): number {
    return this.bestForLevel(key as GymActivityKey, this.gymLevel);
  }

  private bestForLevel(key: GymActivityKey, level: number): number {
    return saveSystem.data.logicGym?.bestByLevel?.[key]?.[String(level)] ?? 0;
  }

  private setGymLevel(delta: number): void {
    this.gymLevel = Phaser.Math.Clamp(this.gymLevel + delta, GYM_MIN_LEVEL, GYM_MAX_LEVEL);
    saveSystem.data.logicGym = {
      best: saveSystem.data.logicGym?.best ?? {},
      bestByLevel: saveSystem.data.logicGym?.bestByLevel ?? {},
      level: this.gymLevel,
    };
    saveSystem.persistData();
    this.showHub();
  }

  private levelSubtitle(): string {
    return logicGymLevelSubtitle(this.gymLevel);
  }

  // -- Hub ----------------------------------------------------------------

  private showHub(): void {
    this.clearScreen();
    this.currentRestart = null;
    const activities: LogicGymHubActivity[] = this.activities().map((activity) => ({
      ...activity,
      levelLine: this.activityLevelLine(activity.key),
      record: this.best(activity.key),
    }));
    renderLogicGymHub(this, (object) => this.t(object), {
      gymLevel: this.gymLevel,
      levelSubtitle: this.levelSubtitle(),
      activities,
      onLevelDelta: (delta) => this.setGymLevel(delta),
      onMenu: () => this.scene.start("MainMenuScene"),
    });
  }

  private backBar(restart: () => void): void {
    this.currentRestart = restart;
    renderLogicGymBackBar(this, (object) => this.t(object), {
      bonusMode: this.bonusMode,
      gymLevel: this.gymLevel,
      levelSubtitle: this.levelSubtitle(),
      onBack: () => {
        if (this.bonusMode) {
          this.abortMissionBonus();
          return;
        }
        this.showHub();
      },
    });
  }

  private activityLevelLine(key: GymActivityKey): string {
    return logicGymActivityLevelLine(key, this.gymLevel, this.levelMetrics());
  }

  private levelMetrics(): LogicGymLevelMetrics {
    const rounds = this.roundsForLevel();
    return {
      tablesTotal: this.tablesTotalForLevel(),
      tablesMaxFactor: this.tablesMaxFactor(),
      mentalTotal: this.mentalTotalForLevel(),
      mentalNumberCap: this.mentalNumberCap(),
      geoTotal: this.geoTotalForLevel(),
      geoPoolSize: this.geoPoolForLevel().length,
      physicalTotal: this.physicalTotalForLevel(),
      physicalPoolSize: this.physicalPoolForLevel().length,
      simonPadCount: this.simonPadCount(),
      memoryPairCount: this.memoryPairCount(),
      codeLength: this.codeLengthForLevel(),
      codeMaxAttempts: this.codeMaxForLevel(),
      rounds,
      maxSequenceLevel: this.sequenceLevelForRound(rounds - 1),
      flashGridSize: this.flashGridSize(),
      firewallRoundCount: this.firewallRoundCount(),
      firewallRuleCount: this.firewallRuleCount(),
    };
  }

  private simonPadCount(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel <= 3 ? 4 : this.gymLevel <= 5 ? 5 : 6;
  }

  private simonStartLength(): number {
    return this.gymLevel >= 7 ? 2 : 1;
  }

  private simonTargetLength(): number {
    return 5 + this.gymLevel * 2;
  }

  private simonStepMs(): number {
    const base = settingsSystem.effectsReduced() ? 520 : 700 - this.gymLevel * 38;
    return Math.max(settingsSystem.effectsReduced() ? 430 : 360, base);
  }

  private memoryPairCount(): number {
    return this.gymLevel <= 1 ? 4 : this.gymLevel <= 3 ? 6 : this.gymLevel <= 6 ? 7 : 8;
  }

  private codeLengthForLevel(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel >= 6 ? 5 : 4;
  }

  private codeMaxForLevel(): number {
    if (this.gymLevel <= 1) return 8;
    if (this.gymLevel <= 3) return 8;
    if (this.gymLevel <= 5) return 7;
    return 6;
  }

  private roundsForLevel(): number {
    return this.gymLevel >= 6 ? 8 : 6;
  }

  private sequenceLevelForRound(round: number): number {
    return Phaser.Math.Clamp(this.gymLevel - 1 + Math.floor(round / 2), 1, 8);
  }

  private flashGridSize(): number {
    return this.gymLevel >= 6 ? 5 : 4;
  }

  private flashBaseCount(): number {
    return this.gymLevel <= 2 ? 3 : this.gymLevel <= 4 ? 4 : this.gymLevel <= 6 ? 5 : 6;
  }

  private flashSequentialMode(): boolean {
    return this.gymLevel >= 7;
  }

  private firewallRoundCount(): number {
    return this.gymLevel <= 2 ? 6 : this.gymLevel <= 5 ? 8 : 10;
  }

  private firewallRuleCount(): number {
    return this.gymLevel <= 1 ? 3 : this.gymLevel <= 2 ? 4 : this.gymLevel <= 4 ? 5 : this.gymLevel <= 6 ? 6 : 7;
  }

  private firewallAvailableActions(): FirewallAction[] {
    return ["allow", "block", "quarantine", "inspect"];
  }

  private firewallScanLimit(): number {
    if (this.gymLevel <= 2) return 3;
    if (this.gymLevel <= 5) return 2;
    return 2;
  }

  private firewallMinimumScans(): number {
    return this.gymLevel <= 2 ? 2 : 1;
  }

  // -- Tabelline Reactor (multiplication fluency + mental agility) --------

  private startTables(): void {
    this.tablesRound = 0;
    this.tablesCorrect = 0;
    this.tablesCombo = 0;
    this.tablesBestCombo = 0;
    this.tablesTimeBonus = 0;
    this.tablesTotal = this.bonusRoundTotal(this.tablesTotalForLevel());
    audioManager.playContext("math");
    this.nextTablesRound();
  }

  private nextTablesRound(): void {
    this.clearScreen();
    if (this.tablesRound >= this.tablesTotal) {
      const accuracy = accuracyPercent(this.tablesCorrect, this.tablesTotal);
      const score = timedActivityScore({ correct: this.tablesCorrect, total: this.tablesTotal, bestCombo: this.tablesBestCombo, timeBonus: this.tablesTimeBonus, level: this.gymLevel, comboWeight: 8, levelWeight: 3 });
      const award = activityAward({ correct: this.tablesCorrect, bestCombo: this.tablesBestCombo, level: this.gymLevel });
      const summary = `Reattore carico: ${this.tablesCorrect}/${this.tablesTotal} corrette, precisione ${accuracy}%, combo migliore x${this.tablesBestCombo}, bonus tempo +${this.tablesTimeBonus}.`;
      this.finishActivity("tables", "Tabelline Reactor", score, ["matematica.calcolo", "matematica.operazioni"], award, summary);
      return;
    }

    const challenge = this.generateTablesChallenge(new Random(`tables-${Date.now()}-${this.gymLevel}-${this.tablesRound}`));
    this.tablesLocked = false;
    this.tablesStartedAt = this.time.now;
    this.tablesTimeLimitMs = this.tablesTimeLimitForLevel();

    this.drawTablesBackdrop(challenge);
    this.t(this.add.text(56, 28, `Tabelline Reactor · Profondità ${this.gymLevel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    this.t(this.add.text(58, 70, "Scegli il valore che chiude il circuito. Le risposte vicine sono trappole: leggi fattori, inversa e segno prima di premere.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 820 },
    }));
    this.tablesStatus = this.t(this.add.text(1000, 40, `Round ${this.tablesRound + 1}/${this.tablesTotal} · Combo x${this.tablesCombo}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      align: "right",
    }).setOrigin(0.5));
    this.tablesTimeText = this.t(this.add.text(1000, 66, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      align: "right",
    }).setOrigin(0.5));

    this.t(this.add.rectangle(640, 214, 760, 132, 0x07151d, 0.94).setStrokeStyle(2, 0xf6c85f, 0.62));
    this.t(this.add.text(640, 186, challenge.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "52px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.t(this.add.text(640, 252, this.tablesModeLabel(challenge.mode), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    }).setOrigin(0.5));

    this.drawTablesEnergyCores(challenge);

    const optionW = 236;
    const optionH = 74;
    challenge.options.forEach((option, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      const x = 640 - optionW - 24 + col * (optionW + 24);
      const y = 410 + row * 96;
      this.t(new Button(this, x, y, String(option), () => this.answerTables(challenge, option), {
        width: optionW,
        height: optionH,
        fontSize: 28,
        fill: 0x173244,
        stroke: 0xf6c85f,
      }));
    });

    const timerBg = this.t(this.add.rectangle(300, 620, 680, 14, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8));
    const timerFill = this.t(this.add.rectangle(300, 620, 680, 14, 0xf6c85f, 0.92).setOrigin(0));
    const updateTimer = (): void => {
      if (this.tablesLocked) return;
      const elapsed = this.time.now - this.tablesStartedAt;
      const remaining = Math.max(0, this.tablesTimeLimitMs - elapsed);
      const ratio = remaining / this.tablesTimeLimitMs;
      timerFill.displayWidth = Math.max(0, 680 * ratio);
      timerFill.setFillStyle(ratio < 0.28 ? 0xff5d7a : ratio < 0.55 ? 0xf6c85f : 0x70d68a, 0.92);
      this.tablesTimeText?.setText(`Tempo ${Math.ceil(remaining / 1000)}s · ${this.tablesBestCombo > 0 ? `miglior combo x${this.tablesBestCombo}` : "costruisci combo"}`);
      if (remaining <= 0) {
        this.answerTables(challenge, Number.NaN);
      }
    };
    updateTimer();
    this.tablesTimerEvent = this.time.addEvent({ delay: 100, loop: true, callback: updateTimer });
    this.backBar(() => this.startTables());
    timerBg.setDepth(timerBg.depth + 1);
    timerFill.setDepth(timerFill.depth + 1);
  }

  private answerTables(challenge: TablesChallenge, choice: number): void {
    if (this.tablesLocked) return;
    this.tablesLocked = true;
    this.tablesTimerEvent?.remove(false);
    this.tablesTimerEvent = undefined;
    const correct = choice === challenge.answer;
    const remaining = Math.max(0, this.tablesTimeLimitMs - (this.time.now - this.tablesStartedAt));
    if (correct) {
      this.tablesCorrect += 1;
      this.tablesCombo += 1;
      this.tablesBestCombo = Math.max(this.tablesBestCombo, this.tablesCombo);
      this.tablesTimeBonus += Math.ceil(remaining / 1000);
      audioManager.play("mathKey");
      audioManager.playToneSequence([
        { frequency: 420 + this.tablesCombo * 20, durationMs: 80 },
        { frequency: 560 + this.tablesCombo * 22, durationMs: 90 },
      ]);
    } else {
      this.tablesCombo = 0;
      audioManager.play("error");
    }

    const tone = correct ? 0x70d68a : 0xff5d7a;
    this.t(this.add.rectangle(640, 620, 930, 86, 0x07151d, 0.97).setStrokeStyle(2, tone, 0.78));
    this.t(this.add.text(640, 606, correct
      ? `Circuito chiuso. ${challenge.explanation}`
      : Number.isNaN(choice)
        ? `Tempo scaduto. ${challenge.explanation}`
        : `Quasi: ${choice} non chiude il circuito. ${challenge.explanation}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: correct ? "#9ff5c0" : "#ffd0da",
      align: "center",
      wordWrap: { width: 880 },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(640, 644, `Risposta: ${challenge.answer} · Combo x${this.tablesCombo} · Corrette ${this.tablesCorrect}/${this.tablesRound + 1}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
    }).setOrigin(0.5));
    this.time.delayedCall(correct ? 850 : 1450, () => {
      this.tablesRound += 1;
      this.nextTablesRound();
    });
  }

  private generateTablesChallenge(random: Random): TablesChallenge {
    const factors = this.tablesFactorsForLevel();
    const a = random.pick(factors);
    const b = random.pick(factors);
    const product = a * b;
    const modes: TablesChallengeMode[] = this.gymLevel <= 2
      ? ["product", "product", "product"]
      : this.gymLevel <= 4
        ? ["product", "missing", "division"]
        : this.gymLevel <= 6
          ? ["product", "missing", "division", "division"]
          : ["product", "missing", "division", "mental", "mental"];
    const mode = random.pick(modes);
    if (mode === "missing") {
      const missingFirst = random.bool();
      const answer = missingFirst ? a : b;
      const prompt = missingFirst ? `? x ${b} = ${product}` : `${a} x ? = ${product}`;
      return {
        mode,
        prompt,
        answer,
        options: this.tablesOptions(answer, random, "factor", a, b),
        explanation: `${a} x ${b} = ${product}, quindi il fattore mancante e ${answer}.`,
        a,
        b,
      };
    }
    if (mode === "division") {
      const answer = random.bool() ? a : b;
      const divisor = answer === a ? b : a;
      return {
        mode,
        prompt: `${product} : ${divisor} = ?`,
        answer,
        options: this.tablesOptions(answer, random, "factor", a, b),
        explanation: `Divisione inversa: ${product} nasce da ${a} x ${b}, quindi ${product} : ${divisor} = ${answer}.`,
        a,
        b,
      };
    }
    if (mode === "mental") {
      const add = random.bool();
      const step = random.bool() ? a : b;
      const answer = add ? product + step : product - step;
      return {
        mode,
        prompt: `${a} x ${b} ${add ? "+" : "-"} ${step} = ?`,
        answer,
        options: this.tablesOptions(answer, random, "product", a, b),
        explanation: `Prima ${a} x ${b} = ${product}, poi ${add ? "aggiungi" : "togli"} ${step}: risultato ${answer}.`,
        a,
        b,
      };
    }
    return {
      mode,
      prompt: `${a} x ${b} = ?`,
      answer: product,
      options: this.tablesOptions(product, random, "product", a, b),
      explanation: `${a} gruppi da ${b} fanno ${product}.`,
      a,
      b,
    };
  }

  private tablesOptions(answer: number, random: Random, kind: "product" | "factor", a: number, b: number): number[] {
    const candidates = new Set<number>([answer]);
    const push = (value: number): void => {
      if (Number.isFinite(value) && value >= 0 && value <= 180) candidates.add(Math.round(value));
    };
    if (kind === "factor") {
      [answer - 2, answer - 1, answer + 1, answer + 2, a + b, Math.abs(a - b), a, b].forEach(push);
      while (candidates.size < 6) push(random.integer(2, this.tablesMaxFactor()));
    } else {
      [answer - a, answer + a, answer - b, answer + b, a + b, a * (b + 1), (a + 1) * b, answer + 10, answer - 10].forEach(push);
      while (candidates.size < 6) push(answer + random.integer(-18, 18));
    }
    return random.shuffle([...candidates].filter((value) => value >= 0)).slice(0, 6);
  }

  private drawTablesBackdrop(challenge: TablesChallenge): void {
    this.t(this.add.rectangle(640, 360, 1280, 720, 0x061019, 0.36));
    const grid = this.t(this.add.graphics());
    grid.lineStyle(1, 0xf6c85f, 0.08);
    for (let x = 80; x <= 1200; x += 80) grid.lineBetween(x, 104, x, 650);
    for (let y = 120; y <= 640; y += 52) grid.lineBetween(40, y, 1240, y);
    grid.lineStyle(3, 0xf6c85f, 0.34);
    grid.strokeRoundedRect(42, 112, 1196, 538, 18);

    const pulse = this.t(this.add.circle(640, 330, 128, 0xf6c85f, 0.045).setStrokeStyle(2, 0xf6c85f, 0.18));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: pulse, scale: 1.14, alpha: 0.12, duration: 900, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
    this.t(this.add.text(640, 334, `${challenge.a} x ${challenge.b}`, {
      fontFamily: "Inter, Arial",
      fontSize: "18px",
      color: "#f7d37a",
      fontStyle: "bold",
    }).setOrigin(0.5));
  }

  private drawTablesEnergyCores(challenge: TablesChallenge): void {
    const leftX = 314;
    const rightX = 966;
    const y = 312;
    [[leftX, challenge.a, "fattore A"], [rightX, challenge.b, "fattore B"]].forEach(([x, value, label]) => {
      const ring = this.t(this.add.circle(Number(x), y, 60, 0x07151d, 0.96).setStrokeStyle(3, 0xf6c85f, 0.72));
      this.t(this.add.circle(Number(x), y, 28, 0xf6c85f, 0.34).setStrokeStyle(2, 0x9ff5e9, 0.68));
      this.t(this.add.text(Number(x), y - 6, String(value), {
        fontFamily: "Inter, Arial",
        fontSize: "32px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.t(this.add.text(Number(x), y + 48, String(label), {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: "#9ff5e9",
      }).setOrigin(0.5));
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: ring, angle: 360, duration: 4200, repeat: -1 });
      }
    });
    const beam = this.t(this.add.graphics());
    beam.lineStyle(5, 0xf6c85f, 0.32).lineBetween(leftX + 72, y, rightX - 72, y);
    beam.lineStyle(2, 0x9ff5e9, 0.52).lineBetween(leftX + 72, y + 16, rightX - 72, y + 16);
  }

  private tablesModeLabel(mode: TablesChallengeMode): string {
    switch (mode) {
      case "product": return "Prodotto diretto";
      case "missing": return "Fattore mancante";
      case "division": return "Operazione inversa";
      case "mental": return "Calcolo mentale in due passi";
    }
  }

  private tablesTotalForLevel(): number {
    return this.gymLevel >= 6 ? 12 : 10;
  }

  private tablesMaxFactor(): number {
    if (this.gymLevel <= 1) return 5;
    if (this.gymLevel <= 2) return 6;
    if (this.gymLevel <= 3) return 8;
    if (this.gymLevel <= 4) return 9;
    return 12;
  }

  private tablesFactorsForLevel(): number[] {
    if (this.gymLevel <= 1) return [2, 3, 4, 5, 10];
    const max = this.tablesMaxFactor();
    const factors = Array.from({ length: max - 1 }, (_, index) => index + 2);
    return this.gymLevel <= 2 ? [...factors, 10] : factors;
  }

  private tablesTimeLimitForLevel(): number {
    return Math.max(7_200, 17_500 - this.gymLevel * 1_050);
  }

  // -- Calcolo Mentale (fast arithmetic strategies) ----------------------

  private startMental(): void {
    this.mentalRound = 0;
    this.mentalCorrect = 0;
    this.mentalCombo = 0;
    this.mentalBestCombo = 0;
    this.mentalTimeBonus = 0;
    this.mentalTotal = this.bonusRoundTotal(this.mentalTotalForLevel());
    audioManager.playContext("math");
    this.nextMentalRound();
  }

  private nextMentalRound(): void {
    this.clearScreen();
    if (this.mentalRound >= this.mentalTotal) {
      const accuracy = accuracyPercent(this.mentalCorrect, this.mentalTotal);
      const score = timedActivityScore({ correct: this.mentalCorrect, total: this.mentalTotal, bestCombo: this.mentalBestCombo, timeBonus: this.mentalTimeBonus, level: this.gymLevel, comboWeight: 9, levelWeight: 4 });
      const award = activityAward({ correct: this.mentalCorrect, bestCombo: this.mentalBestCombo, level: this.gymLevel });
      const summary = `Sprint completato: ${this.mentalCorrect}/${this.mentalTotal} corrette, precisione ${accuracy}%, combo migliore x${this.mentalBestCombo}, bonus tempo +${this.mentalTimeBonus}.`;
      this.finishActivity("mental", "Calcolo Mentale", score, ["matematica.calcolo", "matematica.operazioni", "pensieroCritico"], award, summary);
      return;
    }

    const challenge = this.generateMentalChallenge(new Random(`mental-${Date.now()}-${this.gymLevel}-${this.mentalRound}`));
    this.mentalLocked = false;
    this.mentalStartedAt = this.time.now;
    this.mentalTimeLimitMs = this.mentalTimeLimitForLevel();

    this.drawMentalBackdrop(challenge);
    this.t(this.add.text(56, 28, `Calcolo Mentale · Profondità ${this.gymLevel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    this.t(this.add.text(58, 70, "Non fare tutto in colonna: cerca la scorciatoia mentale. Arrotonda, scomponi, compensa, poi conferma.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 820 },
    }));
    this.mentalStatus = this.t(this.add.text(1000, 40, `Round ${this.mentalRound + 1}/${this.mentalTotal} · Combo x${this.mentalCombo}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      align: "right",
    }).setOrigin(0.5));
    this.mentalTimeText = this.t(this.add.text(1000, 66, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      align: "right",
    }).setOrigin(0.5));

    this.t(this.add.rectangle(640, 208, 820, 136, 0x07151d, 0.94).setStrokeStyle(2, 0x5ec8ff, 0.62));
    this.t(this.add.text(640, 178, challenge.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: challenge.prompt.length > 18 ? "42px" : "50px",
      color: "#f5fbff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.t(this.add.text(640, 248, this.mentalModeLabel(challenge.mode), {
      fontFamily: "Inter, Arial",
      fontSize: "14px",
      color: "#9ff5e9",
    }).setOrigin(0.5));

    this.drawMentalNumberTrack(challenge);

    const optionW = 236;
    const optionH = 72;
    challenge.options.forEach((option, index) => {
      const col = index % 3;
      const row = Math.floor(index / 3);
      const x = 640 - optionW - 24 + col * (optionW + 24);
      const y = 410 + row * 94;
      this.t(new Button(this, x, y, String(option), () => this.answerMental(challenge, option), {
        width: optionW,
        height: optionH,
        fontSize: 28,
        fill: 0x123146,
        stroke: 0x5ec8ff,
      }));
    });

    const timerBg = this.t(this.add.rectangle(300, 620, 680, 14, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8));
    const timerFill = this.t(this.add.rectangle(300, 620, 680, 14, 0x5ec8ff, 0.92).setOrigin(0));
    const updateTimer = (): void => {
      if (this.mentalLocked) return;
      const elapsed = this.time.now - this.mentalStartedAt;
      const remaining = Math.max(0, this.mentalTimeLimitMs - elapsed);
      const ratio = remaining / this.mentalTimeLimitMs;
      timerFill.displayWidth = Math.max(0, 680 * ratio);
      timerFill.setFillStyle(ratio < 0.28 ? 0xff5d7a : ratio < 0.55 ? 0xf6c85f : 0x5ec8ff, 0.92);
      this.mentalTimeText?.setText(`Tempo ${Math.ceil(remaining / 1000)}s · ${challenge.focus}`);
      if (remaining <= 0) {
        this.answerMental(challenge, Number.NaN);
      }
    };
    updateTimer();
    this.mentalTimerEvent = this.time.addEvent({ delay: 100, loop: true, callback: updateTimer });
    this.backBar(() => this.startMental());
    timerBg.setDepth(timerBg.depth + 1);
    timerFill.setDepth(timerFill.depth + 1);
  }

  private answerMental(challenge: MentalChallenge, choice: number): void {
    if (this.mentalLocked) return;
    this.mentalLocked = true;
    this.mentalTimerEvent?.remove(false);
    this.mentalTimerEvent = undefined;
    const correct = choice === challenge.answer;
    const remaining = Math.max(0, this.mentalTimeLimitMs - (this.time.now - this.mentalStartedAt));
    if (correct) {
      this.mentalCorrect += 1;
      this.mentalCombo += 1;
      this.mentalBestCombo = Math.max(this.mentalBestCombo, this.mentalCombo);
      this.mentalTimeBonus += Math.ceil(remaining / 1000);
      audioManager.play("mathKey");
      audioManager.playToneSequence([
        { frequency: 500 + this.mentalCombo * 18, durationMs: 70 },
        { frequency: 660 + this.mentalCombo * 20, durationMs: 85 },
      ]);
    } else {
      this.mentalCombo = 0;
      audioManager.play("error");
    }

    const tone = correct ? 0x70d68a : 0xff5d7a;
    this.t(this.add.rectangle(640, 620, 930, 88, 0x07151d, 0.97).setStrokeStyle(2, tone, 0.78));
    this.t(this.add.text(640, 604, correct
      ? `Scatto pulito. ${challenge.explanation}`
      : Number.isNaN(choice)
        ? `Tempo scaduto. ${challenge.explanation}`
        : `Risposta ${choice}: fuori traiettoria. ${challenge.explanation}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: correct ? "#9ff5c0" : "#ffd0da",
      align: "center",
      wordWrap: { width: 880 },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(640, 645, `Risposta: ${challenge.answer} · Combo x${this.mentalCombo} · Corrette ${this.mentalCorrect}/${this.mentalRound + 1}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
    }).setOrigin(0.5));
    this.time.delayedCall(correct ? 760 : 1420, () => {
      this.mentalRound += 1;
      this.nextMentalRound();
    });
  }

  private generateMentalChallenge(random: Random): MentalChallenge {
    const modes: MentalChallengeMode[] = this.gymLevel <= 2
      ? ["bridge", "bridge", "difference", "chain"]
      : this.gymLevel <= 4
        ? ["bridge", "difference", "chain", "doubleHalf", "splitProduct"]
        : this.gymLevel <= 6
          ? ["bridge", "difference", "chain", "doubleHalf", "percent", "splitProduct"]
          : ["difference", "chain", "doubleHalf", "percent", "percent", "splitProduct"];
    const mode = random.pick(modes);
    const cap = this.mentalNumberCap();

    if (mode === "difference") {
      const b = random.integer(18, Math.max(24, Math.floor(cap * 0.62)));
      const a = b + random.integer(12, Math.max(24, Math.floor(cap * 0.48)));
      const answer = a - b;
      const bridge = Math.ceil(b / 10) * 10;
      const explanation = bridge > b && bridge < a
        ? `Vai per ponti: da ${b} a ${bridge} sono ${bridge - b}, poi fino a ${a} sono ${a - bridge}. Totale ${answer}.`
        : `${a} - ${b} = ${answer}: togli prima le decine, poi aggiusta le unita.`;
      return {
        mode,
        prompt: `${a} - ${b} = ?`,
        answer,
        options: this.mentalOptions(answer, random, [a, b]),
        explanation,
        focus: "differenza rapida",
        chips: [`parti da ${b}`, `ponte ${bridge}`, `arriva a ${a}`],
      };
    }

    if (mode === "chain") {
      const terms = this.gymLevel >= 6 ? 4 : 3;
      let value = random.integer(16, Math.max(30, Math.floor(cap * 0.42)));
      const pieces = [String(value)];
      const chips = [`start ${value}`];
      for (let i = 1; i < terms; i += 1) {
        const delta = random.integer(6, this.gymLevel >= 5 ? 28 : 18);
        const add = value - delta < 8 || random.bool(0.58);
        value = add ? value + delta : value - delta;
        pieces.push(`${add ? "+" : "-"} ${delta}`);
        chips.push(`${add ? "+" : "-"}${delta}`);
      }
      return {
        mode,
        prompt: `${pieces.join(" ")} = ?`,
        answer: value,
        options: this.mentalOptions(value, random, chips.map((chip) => Number.parseInt(chip.replace(/[^0-9-]/g, ""), 10)).filter(Number.isFinite)),
        explanation: `Tieni un totale corrente: ${pieces.join(" ")} porta a ${value}. Raggruppa i passi facili prima di scegliere.`,
        focus: "totale corrente",
        chips,
      };
    }

    if (mode === "doubleHalf") {
      const a = random.integer(12, Math.max(20, Math.floor(cap / 3)));
      const b = random.integer(8, Math.max(16, Math.floor(cap / 4))) * 2;
      const answer = a * 2 + b / 2;
      return {
        mode,
        prompt: `doppio ${a} + meta ${b} = ?`,
        answer,
        options: this.mentalOptions(answer, random, [a, b]),
        explanation: `Doppio di ${a} = ${a * 2}; meta di ${b} = ${b / 2}. Somma finale ${answer}.`,
        focus: "doppio e meta",
        chips: [`2 x ${a}`, `${b} : 2`, `somma`],
      };
    }

    if (mode === "percent") {
      const percent = random.pick(this.gymLevel >= 7 ? [10, 20, 25, 50, 75] : [10, 25, 50]);
      const unit = percent === 25 || percent === 75 ? 4 : percent === 20 ? 5 : 10;
      const base = random.integer(6, Math.max(10, Math.floor(cap / unit))) * unit;
      const answer = Math.round((base * percent) / 100);
      const explanation = percent === 75
        ? `75% significa tre quarti: ${base} : 4 = ${base / 4}, poi x3 = ${answer}.`
        : percent === 25
          ? `25% e' un quarto: ${base} : 4 = ${answer}.`
          : percent === 20
            ? `20% e' un quinto: ${base} : 5 = ${answer}.`
            : `${percent}% di ${base}: sposta o dimezza secondo la percentuale, risultato ${answer}.`;
      return {
        mode,
        prompt: `${percent}% di ${base} = ?`,
        answer,
        options: this.mentalOptions(answer, random, [base, percent]),
        explanation,
        focus: "percentuale",
        chips: [`base ${base}`, `${percent}%`, `risultato`],
      };
    }

    if (mode === "splitProduct") {
      const a = random.integer(this.gymLevel >= 6 ? 14 : 11, this.gymLevel >= 6 ? 24 : 18);
      const b = random.integer(4, this.gymLevel >= 5 ? 12 : 9);
      const answer = a * b;
      const tens = Math.floor(a / 10) * 10;
      const rest = a - tens;
      return {
        mode,
        prompt: `${a} x ${b} = ?`,
        answer,
        options: this.mentalOptions(answer, random, [a, b, tens, rest]),
        explanation: `Scomponi ${a} in ${tens}+${rest}: ${tens} x ${b} = ${tens * b}, ${rest} x ${b} = ${rest * b}, totale ${answer}.`,
        focus: "scomposizione",
        chips: [`${tens} x ${b}`, `${rest} x ${b}`, `somma`],
      };
    }

    const a = random.integer(18, Math.max(26, Math.floor(cap * 0.56)));
    const b = random.integer(17, Math.max(24, Math.floor(cap * 0.52)));
    const answer = a + b;
    const targetTen = Math.ceil(a / 10) * 10;
    const move = Math.max(0, targetTen - a);
    const explanation = move > 0 && b >= move
      ? `Compensa: ${a}+${move} = ${targetTen}; restano ${b - move}. ${targetTen}+${b - move} = ${answer}.`
      : `${a}+${b} = ${answer}: somma decine e unita, poi ricomponi.`;
    return {
      mode,
      prompt: `${a} + ${b} = ?`,
      answer,
      options: this.mentalOptions(answer, random, [a, b]),
      explanation,
      focus: "arrotonda e compensa",
      chips: [`${a} -> ${targetTen}`, `resto ${Math.max(0, b - move)}`, `totale`],
    };
  }

  private mentalOptions(answer: number, random: Random, anchors: number[]): number[] {
    const candidates = new Set<number>([answer]);
    const push = (value: number): void => {
      if (Number.isFinite(value) && value >= 0 && value <= 999) candidates.add(Math.round(value));
    };
    [answer - 10, answer + 10, answer - 5, answer + 5, answer - 2, answer + 2, answer - 1, answer + 1].forEach(push);
    anchors.forEach((anchor) => {
      push(answer + anchor);
      push(answer - anchor);
      push(anchor);
    });
    while (candidates.size < 6) push(answer + random.integer(-24, 24));
    return random.shuffle([...candidates].filter((value) => value >= 0)).slice(0, 6);
  }

  private drawMentalBackdrop(challenge: MentalChallenge): void {
    this.t(this.add.rectangle(640, 360, 1280, 720, 0x061019, 0.38));
    const grid = this.t(this.add.graphics());
    grid.lineStyle(1, 0x5ec8ff, 0.08);
    for (let x = 70; x <= 1210; x += 76) grid.lineBetween(x, 104, x, 650);
    for (let y = 118; y <= 642; y += 48) grid.lineBetween(40, y, 1240, y);
    grid.lineStyle(3, 0x5ec8ff, 0.32);
    grid.strokeRoundedRect(42, 112, 1196, 538, 18);
    grid.lineStyle(2, 0xf6c85f, 0.34);
    grid.lineBetween(250, 334, 1030, 334);
    grid.lineStyle(2, 0xff9ad2, 0.28);
    grid.lineBetween(330, 352, 950, 352);

    const dial = this.t(this.add.circle(640, 332, 118, 0x5ec8ff, 0.045).setStrokeStyle(2, 0x5ec8ff, 0.22));
    this.t(this.add.circle(640, 332, 74, 0xf6c85f, 0.035).setStrokeStyle(2, 0xf6c85f, 0.18));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: dial, angle: 360, duration: 5200, repeat: -1 });
    }
  }

  private drawMentalNumberTrack(challenge: MentalChallenge): void {
    const colors = [0x5ec8ff, 0xf6c85f, 0xff9ad2, 0x70d68a];
    const startX = 352;
    challenge.chips.slice(0, 4).forEach((chip, index) => {
      const x = startX + index * 192;
      const color = colors[index % colors.length];
      const box = this.t(this.add.rectangle(x, 318, 156, 58, 0x07151d, 0.96).setStrokeStyle(2, color, 0.7));
      this.t(this.add.text(x, 318, chip, {
        fontFamily: "Inter, Arial",
        fontSize: chip.length > 10 ? "13px" : "15px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: box, alpha: 0.76, duration: 720 + index * 80, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    });
  }

  private mentalModeLabel(mode: MentalChallengeMode): string {
    switch (mode) {
      case "bridge": return "Somma con compensazione";
      case "difference": return "Differenza per ponti";
      case "chain": return "Catena di operazioni";
      case "doubleHalf": return "Doppio, meta e ricomposizione";
      case "percent": return "Percentuale mentale";
      case "splitProduct": return "Moltiplicazione scomposta";
    }
  }

  private mentalTotalForLevel(): number {
    return this.gymLevel >= 6 ? 12 : 10;
  }

  private mentalNumberCap(): number {
    if (this.gymLevel <= 1) return 60;
    if (this.gymLevel <= 2) return 80;
    if (this.gymLevel <= 4) return 120;
    if (this.gymLevel <= 6) return 180;
    return 240;
  }

  private mentalTimeLimitForLevel(): number {
    return Math.max(7_000, 16_500 - this.gymLevel * 980);
  }

  // -- Geo Atlante (capitals, countries, continents) ---------------------

  private startGeo(): void {
    this.geoRound = 0;
    this.geoCorrect = 0;
    this.geoCombo = 0;
    this.geoBestCombo = 0;
    this.geoTimeBonus = 0;
    this.geoTotal = this.bonusRoundTotal(this.geoTotalForLevel());
    audioManager.play("scan");
    this.nextGeoRound();
  }

  private nextGeoRound(): void {
    this.clearScreen();
    if (this.geoRound >= this.geoTotal) {
      const accuracy = accuracyPercent(this.geoCorrect, this.geoTotal);
      const score = timedActivityScore({ correct: this.geoCorrect, total: this.geoTotal, bestCombo: this.geoBestCombo, timeBonus: this.geoTimeBonus, level: this.gymLevel, comboWeight: 8, levelWeight: 4 });
      const award = activityAward({ correct: this.geoCorrect, bestCombo: this.geoBestCombo, level: this.gymLevel });
      const summary = `Rotta completata: ${this.geoCorrect}/${this.geoTotal} corrette, precisione ${accuracy}%, combo migliore x${this.geoBestCombo}, bonus tempo +${this.geoTimeBonus}.`;
      this.finishActivity("geo", "Geo Atlante", score, ["geografia.orientamento", "geografia.scale", "pensieroCritico"], award, summary);
      return;
    }

    const challenge = this.generateGeoChallenge(new Random(`geo-${Date.now()}-${this.gymLevel}-${this.geoRound}`));
    this.geoLocked = false;
    this.geoStartedAt = this.time.now;
    this.geoTimeLimitMs = this.geoTimeLimitForLevel();

    this.drawGeoBackdrop(challenge);
    this.t(this.add.text(56, 28, `Geo Atlante · Profondità ${this.gymLevel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    this.t(this.add.text(58, 70, "Leggi la rotta: continente, posizione e capitale si confermano a vicenda. Non premere prima di aver orientato il pin.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 780 },
    }));
    this.geoStatus = this.t(this.add.text(1010, 40, `Round ${this.geoRound + 1}/${this.geoTotal} · Combo x${this.geoCombo}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      align: "right",
    }).setOrigin(0.5));
    this.geoTimeText = this.t(this.add.text(1010, 66, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      align: "right",
    }).setOrigin(0.5));

    this.t(this.add.rectangle(1010, 188, 384, 174, 0x07151d, 0.94).setStrokeStyle(2, 0x70d68a, 0.62));
    this.t(this.add.text(1010, 138, this.geoModeLabel(challenge.mode), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.t(this.add.text(1010, 190, challenge.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: "24px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 330, useAdvancedWrap: true },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(1010, 260, challenge.focus, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      align: "center",
      wordWrap: { width: 330, useAdvancedWrap: true },
    }).setOrigin(0.5));

    const optionW = 182;
    const optionH = 68;
    challenge.options.forEach((option, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const x = 912 + col * 198;
      const y = 356 + row * 88;
      this.t(new Button(this, x, y, option, () => this.answerGeo(challenge, option), {
        width: optionW,
        height: optionH,
        fontSize: option.length > 16 ? 15 : 18,
        wordWrapWidth: optionW - 20,
        fill: 0x16362f,
        stroke: 0x70d68a,
        soundKey: "scan",
      }));
    });

    const timerBg = this.t(this.add.rectangle(300, 620, 680, 14, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8));
    const timerFill = this.t(this.add.rectangle(300, 620, 680, 14, 0x70d68a, 0.92).setOrigin(0));
    const updateTimer = (): void => {
      if (this.geoLocked) return;
      const elapsed = this.time.now - this.geoStartedAt;
      const remaining = Math.max(0, this.geoTimeLimitMs - elapsed);
      const ratio = remaining / this.geoTimeLimitMs;
      timerFill.displayWidth = Math.max(0, 680 * ratio);
      timerFill.setFillStyle(ratio < 0.28 ? 0xff5d7a : ratio < 0.55 ? 0xf6c85f : 0x70d68a, 0.92);
      this.geoTimeText?.setText(`Tempo ${Math.ceil(remaining / 1000)}s · ${challenge.item.continent}`);
      if (remaining <= 0) {
        this.answerGeo(challenge, "");
      }
    };
    updateTimer();
    this.geoTimerEvent = this.time.addEvent({ delay: 100, loop: true, callback: updateTimer });
    this.backBar(() => this.startGeo());
    timerBg.setDepth(timerBg.depth + 1);
    timerFill.setDepth(timerFill.depth + 1);
  }

  private answerGeo(challenge: GeoChallenge, choice: string): void {
    if (this.geoLocked) return;
    this.geoLocked = true;
    this.geoTimerEvent?.remove(false);
    this.geoTimerEvent = undefined;
    const correct = choice === challenge.answer;
    const remaining = Math.max(0, this.geoTimeLimitMs - (this.time.now - this.geoStartedAt));
    if (correct) {
      this.geoCorrect += 1;
      this.geoCombo += 1;
      this.geoBestCombo = Math.max(this.geoBestCombo, this.geoCombo);
      this.geoTimeBonus += Math.ceil(remaining / 1000);
      audioManager.play(this.geoCombo > 0 && this.geoCombo % 3 === 0 ? "circuitOn" : "success");
      audioManager.playToneSequence([
        { frequency: 460 + this.geoCombo * 16, durationMs: 80 },
        { frequency: 620 + this.geoCombo * 18, durationMs: 90 },
      ]);
    } else {
      this.geoCombo = 0;
      audioManager.play("error");
    }

    const tone = correct ? 0x70d68a : 0xff5d7a;
    this.t(this.add.rectangle(640, 620, 930, 90, 0x07151d, 0.97).setStrokeStyle(2, tone, 0.78));
    this.t(this.add.text(640, 602, correct
      ? `Pin agganciato. ${challenge.explanation}`
      : choice === ""
        ? `Tempo scaduto. ${challenge.explanation}`
        : `Rotta sbagliata: ${choice}. ${challenge.explanation}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: correct ? "#9ff5c0" : "#ffd0da",
      align: "center",
      wordWrap: { width: 880, useAdvancedWrap: true },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(640, 646, `Risposta: ${challenge.answer} · Combo x${this.geoCombo} · Corrette ${this.geoCorrect}/${this.geoRound + 1}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
    }).setOrigin(0.5));
    this.time.delayedCall(correct ? 820 : 1500, () => {
      this.geoRound += 1;
      this.nextGeoRound();
    });
  }

  private generateGeoChallenge(random: Random): GeoChallenge {
    const pool = this.geoPoolForLevel();
    const item = random.pick(pool);
    const modes: GeoChallengeMode[] = this.gymLevel <= 2
      ? ["continent", "continent", "capital"]
      : this.gymLevel <= 4
        ? ["continent", "capital", "capital", "country"]
        : this.gymLevel <= 6
          ? ["capital", "country", "region", "continent"]
          : ["capital", "country", "country", "region", "region"];
    const mode = random.pick(modes);

    if (mode === "continent") {
      return {
        mode,
        item,
        prompt: `In quale continente si trova ${item.country}?`,
        answer: item.continent,
        options: this.geoOptions(item.continent, GEO_CONTINENTS, random, 4),
        explanation: `${item.country} e in ${item.continent}; capitale: ${item.capital}. Indizio: ${item.fact}.`,
        focus: `Paese: ${item.country} · capitale: ${item.capital}`,
      };
    }

    if (mode === "country") {
      return {
        mode,
        item,
        prompt: `${item.capital} e la capitale di quale paese?`,
        answer: item.country,
        options: this.geoOptions(item.country, pool.filter((other) => other.continent === item.continent).map((other) => other.country), random, 4),
        explanation: `${item.capital} e la capitale di ${item.country}, in ${item.continent}.`,
        focus: `${item.continent} · area ${item.zone}`,
      };
    }

    if (mode === "region") {
      const sameContinent = pool.filter((other) => other.continent === item.continent);
      return {
        mode,
        item,
        prompt: `Quale paese corrisponde all'indizio: ${item.fact}?`,
        answer: item.country,
        options: this.geoOptions(item.country, sameContinent.map((other) => other.country), random, 4),
        explanation: `L'indizio punta a ${item.country}; la capitale e ${item.capital} e il continente e ${item.continent}.`,
        focus: `${item.continent} · capitale ${item.capital}`,
      };
    }

    return {
      mode,
      item,
      prompt: `Qual e la capitale di ${item.country}?`,
      answer: item.capital,
      options: this.geoOptions(item.capital, pool.filter((other) => other.continent === item.continent).map((other) => other.capital), random, 4),
      explanation: `La capitale di ${item.country} e ${item.capital}. Si trova in ${item.continent}: ${item.fact}.`,
      focus: `${item.continent} · area ${item.zone}`,
    };
  }

  private geoOptions(answer: string, candidates: string[], random: Random, total: number): string[] {
    const options = new Set<string>([answer]);
    const local = random.shuffle(candidates.filter((candidate) => candidate !== answer));
    local.forEach((candidate) => {
      if (options.size < total) options.add(candidate);
    });
    const fallback = random.shuffle(GEO_ATLAS.flatMap((item) => [item.country, item.capital, item.continent]).filter((candidate) => candidate !== answer));
    fallback.forEach((candidate) => {
      if (options.size < total) options.add(candidate);
    });
    return random.shuffle([...options]).slice(0, total);
  }

  private drawGeoBackdrop(challenge: GeoChallenge): void {
    this.t(this.add.rectangle(640, 360, 1280, 720, 0x061019, 0.34));
    const frame = this.t(this.add.rectangle(432, 356, 760, 482, 0x07151d, 0.72).setStrokeStyle(2, 0x70d68a, 0.42));
    frame.setOrigin(0.5);
    const mapX = (value: number): number => 92 + (value - 180) * 700 / 980;
    const mapY = (value: number): number => 138 + (value - 180) * 372 / 480;

    const map = this.t(this.add.graphics());
    map.fillStyle(0x123247, 0.78);
    map.fillRoundedRect(72, 124, 720, 404, 18);
    map.lineStyle(1, 0x9ff5e9, 0.12);
    for (let x = 112; x <= 752; x += 80) map.lineBetween(x, 138, x, 512);
    for (let y = 158; y <= 498; y += 56) map.lineBetween(86, y, 778, y);
    map.lineStyle(2, 0x70d68a, 0.18);
    map.strokeRoundedRect(72, 124, 720, 404, 18);

    this.drawGeoLandmass(mapX(192), mapY(248), 136, 92, 0x2f7c62, "NORD AMERICA");
    this.drawGeoLandmass(mapX(352), mapY(492), 94, 132, 0x2f7c62, "SUD AMERICA");
    this.drawGeoLandmass(mapX(592), mapY(254), 110, 72, 0x3f8f6b, "EUROPA");
    this.drawGeoLandmass(mapX(610), mapY(454), 116, 152, 0x9f8b45, "AFRICA");
    this.drawGeoLandmass(mapX(852), mapY(338), 186, 126, 0x4f9a72, "ASIA");
    this.drawGeoLandmass(mapX(1028), mapY(588), 112, 66, 0x8fae57, "OCEANIA");

    const pinX = mapX(challenge.item.x);
    const pinY = mapY(challenge.item.y);
    const coast = this.t(this.add.graphics());
    coast.lineStyle(3, 0xf6c85f, 0.62);
    coast.lineBetween(432, 356, pinX, pinY);
    coast.lineStyle(1, 0x9ff5e9, 0.7);
    coast.lineBetween(432, 372, pinX, pinY + 10);

    const pin = this.t(this.add.circle(pinX, pinY, 10, 0xf6c85f, 0.98).setStrokeStyle(3, 0xffffff, 0.85));
    if (this.textures.exists("logic-gym") && this.textures.getFrame("logic-gym", "geo-pin")) {
      this.t(this.add.image(pinX, pinY - 13, "logic-gym", "geo-pin").setDisplaySize(44, 44));
    }
    this.t(this.add.circle(pinX, pinY, 22, 0xf6c85f, 0.12).setStrokeStyle(2, 0xf6c85f, 0.38));
    this.t(this.add.text(pinX, pinY - 32, challenge.item.country, {
      fontFamily: "Inter, Arial",
      fontSize: challenge.item.country.length > 14 ? "10px" : "12px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 110, useAdvancedWrap: true },
      shadow: { offsetX: 0, offsetY: 2, color: "#000000", blur: 4, fill: true },
    }).setOrigin(0.5));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: pin, scale: 1.26, duration: 560, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }

    this.t(this.add.text(118, 142, "Mappa tattica", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      fontStyle: "bold",
    }));
    this.t(this.add.text(118, 508, `Pin: ${challenge.item.capital} · ${challenge.item.continent}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
    }));
  }

  private drawGeoLandmass(x: number, y: number, w: number, h: number, color: number, label: string): void {
    const land = this.t(this.add.ellipse(x, y, w, h, color, 0.34).setStrokeStyle(2, color, 0.45));
    this.t(this.add.ellipse(x + w * 0.18, y + h * 0.08, w * 0.58, h * 0.64, color, 0.22).setStrokeStyle(1, 0x9ff5e9, 0.12));
    this.t(this.add.text(x, y, label, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#c7dce7",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: land, alpha: 0.24, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private geoModeLabel(mode: GeoChallengeMode): string {
    switch (mode) {
      case "continent": return "Orientamento continentale";
      case "capital": return "Capitale da paese";
      case "country": return "Paese da capitale";
      case "region": return "Indizio geografico";
    }
  }

  private geoTotalForLevel(): number {
    return this.gymLevel >= 6 ? 12 : 10;
  }

  private geoPoolForLevel(): GeoItem[] {
    if (this.gymLevel <= 1) return GEO_ATLAS.filter((item) => ["Europa", "America del Nord", "America del Sud"].includes(item.continent)).slice(0, 22);
    if (this.gymLevel <= 2) return GEO_ATLAS.filter((item) => item.continent !== "Oceania").slice(0, 34);
    if (this.gymLevel <= 4) return GEO_ATLAS.filter((item) => item.continent !== "Oceania");
    return GEO_ATLAS;
  }

  private geoTimeLimitForLevel(): number {
    return Math.max(8_000, 18_000 - this.gymLevel * 900);
  }

  // -- Geo Rilievi (physical geography basics) ---------------------------

  private startPhysical(): void {
    this.physRound = 0;
    this.physCorrect = 0;
    this.physCombo = 0;
    this.physBestCombo = 0;
    this.physTimeBonus = 0;
    this.physTotal = this.bonusRoundTotal(this.physicalTotalForLevel());
    audioManager.play("scan");
    this.nextPhysicalRound();
  }

  private nextPhysicalRound(): void {
    this.clearScreen();
    if (this.physRound >= this.physTotal) {
      const accuracy = accuracyPercent(this.physCorrect, this.physTotal);
      const score = timedActivityScore({ correct: this.physCorrect, total: this.physTotal, bestCombo: this.physBestCombo, timeBonus: this.physTimeBonus, level: this.gymLevel, comboWeight: 8, levelWeight: 4 });
      const award = activityAward({ correct: this.physCorrect, bestCombo: this.physBestCombo, level: this.gymLevel });
      const summary = `Rilievi calibrati: ${this.physCorrect}/${this.physTotal} corretti, precisione ${accuracy}%, combo migliore x${this.physBestCombo}, bonus tempo +${this.physTimeBonus}.`;
      this.finishActivity("geoPhysical", "Geo Rilievi", score, ["geografia.orientamento", "geografia.scale", "scienze.osservazione"], award, summary);
      return;
    }

    const challenge = this.generatePhysicalChallenge(new Random(`phys-${Date.now()}-${this.gymLevel}-${this.physRound}`));
    this.physLocked = false;
    this.physStartedAt = this.time.now;
    this.physTimeLimitMs = this.physicalTimeLimitForLevel();

    this.drawPhysicalBackdrop(challenge);
    this.t(this.add.text(56, 28, `Geo Rilievi · Profondità ${this.gymLevel}`, {
      fontFamily: "Inter, Arial",
      fontSize: "28px",
      color: "#f5fbff",
      fontStyle: "bold",
    }));
    this.t(this.add.text(58, 70, "Osserva forma, colore e posizione: acqua, rilievi e deserti hanno tracce diverse sulla mappa.", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#9ff5e9",
      wordWrap: { width: 780 },
    }));
    this.physStatus = this.t(this.add.text(1010, 40, `Round ${this.physRound + 1}/${this.physTotal} · Combo x${this.physCombo}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: "#f7d37a",
      fontStyle: "bold",
      align: "right",
    }).setOrigin(0.5));
    this.physTimeText = this.t(this.add.text(1010, 66, "", {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
      align: "right",
    }).setOrigin(0.5));

    this.t(this.add.rectangle(1010, 188, 384, 174, 0x07151d, 0.94).setStrokeStyle(2, 0x9f8cff, 0.62));
    const featureFrame = this.physicalKindFrame(challenge.feature.kind);
    if (this.textures.exists("logic-gym") && this.textures.getFrame("logic-gym", featureFrame)) {
      this.t(this.add.image(844, 142, "logic-gym", featureFrame).setDisplaySize(48, 48));
    }
    this.t(this.add.text(1010, 138, this.physicalModeLabel(challenge.mode), {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#cfc7ff",
      fontStyle: "bold",
    }).setOrigin(0.5));
    this.t(this.add.text(1010, 190, challenge.prompt, {
      fontFamily: "Inter, Arial",
      fontSize: challenge.prompt.length > 54 ? "21px" : "24px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 332, useAdvancedWrap: true },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(1010, 260, challenge.focus, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
      align: "center",
      wordWrap: { width: 330, useAdvancedWrap: true },
    }).setOrigin(0.5));

    const optionW = 182;
    const optionH = 68;
    challenge.options.forEach((option, index) => {
      const col = index % 2;
      const row = Math.floor(index / 2);
      const x = 912 + col * 198;
      const y = 356 + row * 88;
      this.t(new Button(this, x, y, option, () => this.answerPhysical(challenge, option), {
        width: optionW,
        height: optionH,
        fontSize: option.length > 16 ? 15 : 18,
        wordWrapWidth: optionW - 20,
        fill: 0x231f3f,
        stroke: 0x9f8cff,
        soundKey: "scan",
      }));
    });

    const timerBg = this.t(this.add.rectangle(300, 620, 680, 14, 0x0a1a24, 1).setOrigin(0).setStrokeStyle(1, 0x244451, 0.8));
    const timerFill = this.t(this.add.rectangle(300, 620, 680, 14, 0x9f8cff, 0.92).setOrigin(0));
    const updateTimer = (): void => {
      if (this.physLocked) return;
      const elapsed = this.time.now - this.physStartedAt;
      const remaining = Math.max(0, this.physTimeLimitMs - elapsed);
      const ratio = remaining / this.physTimeLimitMs;
      timerFill.displayWidth = Math.max(0, 680 * ratio);
      timerFill.setFillStyle(ratio < 0.28 ? 0xff5d7a : ratio < 0.55 ? 0xf6c85f : 0x9f8cff, 0.92);
      this.physTimeText?.setText(`Tempo ${Math.ceil(remaining / 1000)}s · ${this.physicalKindLabel(challenge.feature.kind)}`);
      if (remaining <= 0) {
        this.answerPhysical(challenge, "");
      }
    };
    updateTimer();
    this.physTimerEvent = this.time.addEvent({ delay: 100, loop: true, callback: updateTimer });
    this.backBar(() => this.startPhysical());
    timerBg.setDepth(timerBg.depth + 1);
    timerFill.setDepth(timerFill.depth + 1);
  }

  private answerPhysical(challenge: PhysicalChallenge, choice: string): void {
    if (this.physLocked) return;
    this.physLocked = true;
    this.physTimerEvent?.remove(false);
    this.physTimerEvent = undefined;
    const correct = choice === challenge.answer;
    const remaining = Math.max(0, this.physTimeLimitMs - (this.time.now - this.physStartedAt));
    if (correct) {
      this.physCorrect += 1;
      this.physCombo += 1;
      this.physBestCombo = Math.max(this.physBestCombo, this.physCombo);
      this.physTimeBonus += Math.ceil(remaining / 1000);
      audioManager.play(this.physCombo > 0 && this.physCombo % 3 === 0 ? "circuitOn" : "success");
      audioManager.playToneSequence([
        { frequency: 380 + this.physCombo * 18, durationMs: 80 },
        { frequency: 560 + this.physCombo * 20, durationMs: 95 },
      ]);
    } else {
      this.physCombo = 0;
      audioManager.play("error");
    }

    const tone = correct ? 0x70d68a : 0xff5d7a;
    this.t(this.add.rectangle(640, 620, 930, 90, 0x07151d, 0.97).setStrokeStyle(2, tone, 0.78));
    this.t(this.add.text(640, 602, correct
      ? `Traccia letta. ${challenge.explanation}`
      : choice === ""
        ? `Tempo scaduto. ${challenge.explanation}`
        : `Traccia sbagliata: ${choice}. ${challenge.explanation}`, {
      fontFamily: "Inter, Arial",
      fontSize: "15px",
      color: correct ? "#9ff5c0" : "#ffd0da",
      align: "center",
      wordWrap: { width: 880, useAdvancedWrap: true },
      lineSpacing: 4,
    }).setOrigin(0.5));
    this.t(this.add.text(640, 646, `Risposta: ${challenge.answer} · Combo x${this.physCombo} · Corrette ${this.physCorrect}/${this.physRound + 1}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#c7dce7",
    }).setOrigin(0.5));
    this.time.delayedCall(correct ? 820 : 1500, () => {
      this.physRound += 1;
      this.nextPhysicalRound();
    });
  }

  private generatePhysicalChallenge(random: Random): PhysicalChallenge {
    const pool = this.physicalPoolForLevel();
    const feature = random.pick(pool);
    const modes: PhysicalChallengeMode[] = this.gymLevel <= 2
      ? ["kind", "kind", "continent"]
      : this.gymLevel <= 4
        ? ["kind", "continent", "name", "clue"]
        : this.gymLevel <= 6
          ? ["name", "clue", "continent", "kind"]
          : ["name", "clue", "clue", "continent", "kind"];
    const mode = random.pick(modes);

    if (mode === "kind") {
      return {
        mode,
        feature,
        prompt: `Che elemento fisico e ${feature.name}?`,
        answer: this.physicalKindLabel(feature.kind),
        options: this.physicalOptions(this.physicalKindLabel(feature.kind), PHYSICAL_KINDS.map((kind) => this.physicalKindLabel(kind)), random, 4),
        explanation: `${feature.name} e ${this.physicalKindArticle(feature.kind)} ${this.physicalKindLabel(feature.kind)} in ${feature.continent}. Indizio: ${feature.clue}.`,
        focus: `${feature.continent} · area ${feature.region}`,
      };
    }

    if (mode === "continent") {
      return {
        mode,
        feature,
        prompt: `In quale continente si trova ${feature.name}?`,
        answer: feature.continent,
        options: this.physicalOptions(feature.continent, GEO_CONTINENTS, random, 4),
        explanation: `${feature.name} si trova in ${feature.continent}; e ${this.physicalKindArticle(feature.kind)} ${this.physicalKindLabel(feature.kind)}.`,
        focus: `Tipo: ${this.physicalKindLabel(feature.kind)}`,
      };
    }

    if (mode === "clue") {
      const sameKind = pool.filter((item) => item.kind === feature.kind);
      return {
        mode,
        feature,
        prompt: `Quale elemento corrisponde all'indizio: ${feature.clue}?`,
        answer: feature.name,
        options: this.physicalOptions(feature.name, sameKind.map((item) => item.name), random, 4),
        explanation: `L'indizio descrive ${feature.name}, ${this.physicalKindArticle(feature.kind)} ${this.physicalKindLabel(feature.kind)} in ${feature.continent}.`,
        focus: `${this.physicalKindLabel(feature.kind)} · ${feature.continent}`,
      };
    }

    return {
      mode,
      feature,
      prompt: `Quale elemento fisico e ${this.physicalKindArticle(feature.kind)} ${this.physicalKindLabel(feature.kind)} in ${feature.continent}?`,
      answer: feature.name,
      options: this.physicalOptions(feature.name, pool.filter((item) => item.kind === feature.kind || item.continent === feature.continent).map((item) => item.name), random, 4),
      explanation: `La traccia punta a ${feature.name}: ${feature.clue}.`,
      focus: `${feature.continent} · area ${feature.region}`,
    };
  }

  private physicalOptions(answer: string, candidates: string[], random: Random, total: number): string[] {
    const options = new Set<string>([answer]);
    const local = random.shuffle(candidates.filter((candidate) => candidate !== answer));
    local.forEach((candidate) => {
      if (options.size < total) options.add(candidate);
    });
    const fallback = random.shuffle(PHYSICAL_FEATURES.flatMap((item) => [item.name, item.continent, this.physicalKindLabel(item.kind)]).filter((candidate) => candidate !== answer));
    fallback.forEach((candidate) => {
      if (options.size < total) options.add(candidate);
    });
    return random.shuffle([...options]).slice(0, total);
  }

  private drawPhysicalBackdrop(challenge: PhysicalChallenge): void {
    this.t(this.add.rectangle(640, 360, 1280, 720, 0x061019, 0.36));
    const frame = this.t(this.add.rectangle(432, 356, 760, 482, 0x07151d, 0.74).setStrokeStyle(2, 0x9f8cff, 0.42));
    frame.setOrigin(0.5);
    const mapX = (value: number): number => 92 + (value - 180) * 700 / 980;
    const mapY = (value: number): number => 138 + (value - 180) * 372 / 480;

    const map = this.t(this.add.graphics());
    map.fillStyle(0x11243a, 0.82);
    map.fillRoundedRect(72, 124, 720, 404, 18);
    map.lineStyle(1, 0x9ff5e9, 0.10);
    for (let x = 112; x <= 752; x += 80) map.lineBetween(x, 138, x, 512);
    for (let y = 158; y <= 498; y += 56) map.lineBetween(86, y, 778, y);
    map.lineStyle(2, 0x9f8cff, 0.18);
    map.strokeRoundedRect(72, 124, 720, 404, 18);

    this.drawPhysicalZone(mapX(192), mapY(248), 136, 92, 0x2f7c62, "NORD AMERICA");
    this.drawPhysicalZone(mapX(352), mapY(492), 94, 132, 0x2f7c62, "SUD AMERICA");
    this.drawPhysicalZone(mapX(592), mapY(254), 110, 72, 0x3f8f6b, "EUROPA");
    this.drawPhysicalZone(mapX(610), mapY(454), 116, 152, 0x9f8b45, "AFRICA");
    this.drawPhysicalZone(mapX(852), mapY(338), 186, 126, 0x4f9a72, "ASIA");
    this.drawPhysicalZone(mapX(1028), mapY(588), 112, 66, 0x8fae57, "OCEANIA");

    const featureX = mapX(challenge.feature.x);
    const featureY = mapY(challenge.feature.y);
    const path = this.t(this.add.graphics());
    path.lineStyle(3, this.physicalKindColor(challenge.feature.kind), 0.66);
    path.lineBetween(432, 356, featureX, featureY);
    path.lineStyle(1, 0xffffff, 0.38);
    path.lineBetween(432, 372, featureX, featureY + 10);

    this.drawPhysicalMarker(featureX, featureY, challenge.feature.kind);
    this.t(this.add.text(featureX, featureY - 34, challenge.feature.name, {
      fontFamily: "Inter, Arial",
      fontSize: challenge.feature.name.length > 16 ? "10px" : "12px",
      color: "#f5fbff",
      fontStyle: "bold",
      align: "center",
      wordWrap: { width: 124, useAdvancedWrap: true },
      shadow: { offsetX: 0, offsetY: 2, color: "#000000", blur: 4, fill: true },
    }).setOrigin(0.5));

    this.t(this.add.text(118, 142, "Carta fisica", {
      fontFamily: "Inter, Arial",
      fontSize: "13px",
      color: "#cfc7ff",
      fontStyle: "bold",
    }));
    this.t(this.add.text(118, 508, `Traccia: ${this.physicalKindLabel(challenge.feature.kind)} · ${challenge.feature.continent}`, {
      fontFamily: "Inter, Arial",
      fontSize: "12px",
      color: "#f7d37a",
    }));
  }

  private drawPhysicalZone(x: number, y: number, w: number, h: number, color: number, label: string): void {
    const land = this.t(this.add.ellipse(x, y, w, h, color, 0.24).setStrokeStyle(2, color, 0.36));
    this.t(this.add.ellipse(x + w * 0.18, y + h * 0.08, w * 0.58, h * 0.64, 0x9f8cff, 0.08).setStrokeStyle(1, 0x9ff5e9, 0.10));
    this.t(this.add.text(x, y, label, {
      fontFamily: "Inter, Arial",
      fontSize: "10px",
      color: "#c7dce7",
      fontStyle: "bold",
    }).setOrigin(0.5));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: land, alpha: 0.18, duration: 1700, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private drawPhysicalMarker(x: number, y: number, kind: PhysicalKind): void {
    const color = this.physicalKindColor(kind);
    const frame = this.physicalKindFrame(kind);
    if (this.textures.exists("logic-gym") && this.textures.getFrame("logic-gym", frame)) {
      this.t(this.add.image(x, y, "logic-gym", frame).setDisplaySize(kind === "fiume" || kind === "stretto" ? 58 : 50, 50));
      const pulse = this.t(this.add.circle(x, y, 24, color, 0.12).setStrokeStyle(2, color, 0.42));
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({ targets: pulse, scale: 1.24, alpha: 0.05, duration: 760, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
      return;
    }
    if (kind === "fiume") {
      const river = this.t(this.add.graphics());
      river.lineStyle(5, color, 0.9);
      river.beginPath();
      river.moveTo(x - 32, y + 12);
      river.lineTo(x - 12, y - 6);
      river.lineTo(x + 8, y + 8);
      river.lineTo(x + 30, y - 12);
      river.strokePath();
    } else if (kind === "lago" || kind === "mare") {
      this.t(this.add.ellipse(x, y, kind === "mare" ? 58 : 42, kind === "mare" ? 28 : 26, color, 0.68).setStrokeStyle(3, 0xffffff, 0.48));
    } else if (kind === "montagna" || kind === "catena montuosa") {
      const peaks = this.t(this.add.graphics());
      peaks.fillStyle(color, 0.86);
      peaks.lineStyle(2, 0xffffff, 0.52);
      peaks.fillTriangle(x - 28, y + 20, x, y - 24, x + 28, y + 20);
      peaks.strokeTriangle(x - 28, y + 20, x, y - 24, x + 28, y + 20);
      if (kind === "catena montuosa") {
        peaks.fillTriangle(x - 48, y + 18, x - 24, y - 12, x, y + 18);
        peaks.strokeTriangle(x - 48, y + 18, x - 24, y - 12, x, y + 18);
        peaks.fillTriangle(x, y + 18, x + 24, y - 12, x + 48, y + 18);
        peaks.strokeTriangle(x, y + 18, x + 24, y - 12, x + 48, y + 18);
      }
    } else if (kind === "deserto") {
      this.t(this.add.rectangle(x, y, 58, 30, color, 0.55).setStrokeStyle(2, 0xf6c85f, 0.58));
      const dunes = this.t(this.add.graphics());
      dunes.lineStyle(2, 0xf6c85f, 0.7);
      dunes.arc(x - 14, y + 2, 18, Math.PI, 0);
      dunes.arc(x + 18, y + 8, 14, Math.PI, 0);
    } else {
      this.t(this.add.rectangle(x, y, 50, 18, color, 0.74).setStrokeStyle(3, 0xffffff, 0.52));
    }
    const pulse = this.t(this.add.circle(x, y, 24, color, 0.12).setStrokeStyle(2, color, 0.42));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: pulse, scale: 1.24, alpha: 0.05, duration: 760, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private physicalModeLabel(mode: PhysicalChallengeMode): string {
    switch (mode) {
      case "kind": return "Tipo di elemento";
      case "continent": return "Posizione continentale";
      case "name": return "Nome dell'elemento";
      case "clue": return "Indizio fisico";
    }
  }

  private physicalKindLabel(kind: PhysicalKind): string {
    return kind;
  }

  private physicalKindArticle(kind: PhysicalKind): string {
    if (kind === "stretto") return "uno";
    return kind === "montagna" || kind === "catena montuosa" ? "una" : "un";
  }

  private physicalKindColor(kind: PhysicalKind): number {
    switch (kind) {
      case "fiume": return 0x5ec8ff;
      case "lago": return 0x6be7d6;
      case "mare": return 0x358cff;
      case "montagna": return 0xc7dce7;
      case "catena montuosa": return 0xf6c85f;
      case "deserto": return 0xd6a84f;
      case "stretto": return 0xff9ad2;
    }
  }

  private physicalKindFrame(kind: PhysicalKind): string {
    switch (kind) {
      case "fiume": return "geo-river";
      case "lago": return "geo-lake";
      case "mare": return "geo-lake";
      case "montagna": return "geo-mountain";
      case "catena montuosa": return "geo-mountain";
      case "deserto": return "geo-desert";
      case "stretto": return "geo-river";
    }
  }

  private physicalTotalForLevel(): number {
    return this.gymLevel >= 6 ? 12 : 10;
  }

  private physicalPoolForLevel(): PhysicalFeature[] {
    if (this.gymLevel <= 1) return PHYSICAL_FEATURES.filter((item) => ["Europa", "Africa", "America del Nord"].includes(item.continent)).slice(0, 18);
    if (this.gymLevel <= 2) return PHYSICAL_FEATURES.filter((item) => item.continent !== "Oceania").slice(0, 26);
    if (this.gymLevel <= 4) return PHYSICAL_FEATURES.filter((item) => item.continent !== "Oceania");
    return PHYSICAL_FEATURES;
  }

  private physicalTimeLimitForLevel(): number {
    return Math.max(8_200, 18_500 - this.gymLevel * 900);
  }

  // -- Sequenza Luminosa (sequential working memory) ----------------------

  private startSimon(): void {
    this.clearScreen();
    this.simonSeq = [];
    this.simonInput = [];
    this.simonLocked = true;
    this.t(this.add.text(640, 40, `🧠 Sequenza Luminosa · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.simonStatus = this.t(this.add.text(640, 86, "Guarda bene…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const padCount = this.simonPadCount();
    const cols = padCount <= 4 ? 2 : 3;
    const padW = 168;
    const padH = 128;
    const gap = 26;
    const totalW = cols * padW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + padW / 2;
    const startY = padCount <= 4 ? 286 : 240;
    PAD_COLORS.slice(0, padCount).forEach((color, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (padW + gap);
      const y = startY + row * (padH + gap);
      const pad = this.t(this.add.rectangle(x, y, padW, padH, color, 0.32).setStrokeStyle(3, color, 0.8).setInteractive({ useHandCursor: true }));
      pad.on("pointerdown", () => this.simonClick(index));
      this.simonPads.push(pad);
    });
    this.backBar(() => this.startSimon());
    this.time.delayedCall(700, () => this.simonNextRound());
  }

  private simonNextRound(): void {
    this.simonInput = [];
    this.simonLocked = true;
    const random = new Random(`simon-${Date.now()}-${this.simonSeq.length}`);
    const additions = this.simonSeq.length === 0 ? this.simonStartLength() : 1;
    for (let i = 0; i < additions; i += 1) {
      this.simonSeq.push(random.integer(0, this.simonPadCount() - 1));
    }
    this.simonStatus?.setText(`Turno ${this.simonSeq.length} · Guarda la sequenza…`);
    const step = this.simonStepMs();
    this.simonSeq.forEach((padIndex, i) => {
      this.time.delayedCall(400 + i * step, () => this.flashPad(padIndex));
    });
    this.time.delayedCall(400 + this.simonSeq.length * step, () => {
      this.simonLocked = false;
      this.simonStatus?.setText("Ripeti la sequenza!");
    });
  }

  private flashPad(index: number): void {
    const pad = this.simonPads[index];
    if (!pad) return;
    audioManager.play("levelSelect");
    pad.setFillStyle(PAD_COLORS[index], 1);
    this.tweens.add({ targets: pad, scale: 1.08, duration: 180, yoyo: true, onComplete: () => pad.setFillStyle(PAD_COLORS[index], 0.32) });
  }

  private simonClick(index: number): void {
    if (this.simonLocked) return;
    this.flashPad(index);
    this.simonInput.push(index);
    const pos = this.simonInput.length - 1;
    if (this.simonInput[pos] !== this.simonSeq[pos]) {
      audioManager.play("error");
      const reached = this.simonSeq.length - 1;
      const expected = this.simonSeq[pos];
      this.finishActivity("simon", "Sequenza Luminosa", reached, ["trasversali.memoria"], Math.min(22, 4 + reached + this.gymLevel), `Errore al passo ${pos + 1}: hai premuto la luce ${index + 1}, ma la sequenza chiedeva la luce ${expected + 1}.`);
      return;
    }
    if (this.simonInput.length === this.simonSeq.length) {
      this.simonLocked = true;
      this.simonStatus?.setText("Perfetto! Sequenza più lunga…");
      audioManager.play("success");
      if (this.simonSeq.length >= this.simonTargetLength()) {
        this.finishActivity("simon", "Sequenza Luminosa", this.simonTargetLength(), ["trasversali.memoria"], 22, "Hai raggiunto la sequenza obiettivo della profondità.");
        return;
      }
      this.time.delayedCall(750, () => this.simonNextRound());
    }
  }

  // -- Memory delle Coppie (visual memory + knowledge) --------------------

  private startMemory(): void {
    this.clearScreen();
    this.memFlipped = [];
    this.memMoves = 0;
    this.memMatched = 0;
    this.memLocked = false;
    this.memPairs = this.memoryPairCount();
    const random = new Random(`memory-${Date.now()}`);
    const pairs: MemoryPair[] = buildMemoryPairs(random, this.memPairs);
    const deck = random.shuffle(pairs.flatMap((pair) => [
      { pairId: pair.id, label: pair.a },
      { pairId: pair.id, label: pair.b },
    ]));

    this.t(this.add.text(640, 36, `🃏 Memory delle Coppie · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.memStatus = this.t(this.add.text(640, 78, `Mosse: 0 · Coppie: 0/${this.memPairs}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#9ff5e9" }).setOrigin(0.5));

    const cols = 4;
    const cardW = this.memPairs >= 8 ? 206 : this.memPairs >= 7 ? 214 : 230;
    const cardH = this.memPairs >= 7 ? 94 : 116;
    const gap = this.memPairs >= 7 ? 14 : 18;
    const totalW = cols * cardW + (cols - 1) * gap;
    const startX = 640 - totalW / 2 + cardW / 2;
    const startY = 190;
    deck.forEach((card, index) => {
      const col = index % cols;
      const row = Math.floor(index / cols);
      const x = startX + col * (cardW + gap);
      const y = startY + row * (cardH + gap);
      const rect = this.t(this.add.rectangle(x, y, cardW, cardH, 0x123247, 1).setStrokeStyle(2, 0x6be7d6, 0.6).setInteractive({ useHandCursor: true }));
      const text = this.t(this.add.text(x, y, "?", { fontFamily: "Inter, Arial", fontSize: "26px", color: "#6be7d6", fontStyle: "bold" }).setOrigin(0.5));
      const entry = { pairId: card.pairId, label: card.label, rect, text, matched: false, flipped: false };
      rect.on("pointerdown", () => this.memClick(this.memCards.indexOf(entry)));
      this.memCards.push(entry);
    });
    this.backBar(() => this.startMemory());
  }

  private memClick(index: number): void {
    if (this.memLocked) return;
    const card = this.memCards[index];
    if (!card || card.matched || card.flipped) return;
    card.flipped = true;
    card.text.setText(card.label).setColor("#ffffff");
    card.rect.setFillStyle(0x1f5a51, 1);
    this.memFlipped.push(index);
    if (this.memFlipped.length < 2) return;

    this.memMoves += 1;
    const [a, b] = this.memFlipped.map((i) => this.memCards[i]);
    if (a.pairId === b.pairId) {
      audioManager.play("success");
      a.matched = true;
      b.matched = true;
      [a, b].forEach((entry) => entry.rect.setFillStyle(0x173b36, 1).setStrokeStyle(2, 0x70d68a, 0.9));
      this.memFlipped = [];
      this.memMatched += 1;
      this.updateMemStatus();
      if (this.memMatched >= this.memPairs) {
        const { efficiency, score } = memoryEfficiencyScore(this.memPairs, this.memMoves, this.gymLevel);
        this.finishActivity("memory", "Memory delle Coppie", score, ["trasversali.memoria", "pensieroCritico"], Math.min(20, 6 + Math.round(efficiency / 12) + Math.floor(this.gymLevel / 3)), `Tutte le ${this.memPairs} coppie trovate in ${this.memMoves} mosse. Efficienza: ${efficiency}%.`);
      }
    } else {
      audioManager.play("error");
      this.memLocked = true;
      this.updateMemStatus();
      this.time.delayedCall(850, () => {
        [a, b].forEach((entry) => {
          entry.flipped = false;
          entry.text.setText("?").setColor("#6be7d6");
          entry.rect.setFillStyle(0x123247, 1);
        });
        this.memFlipped = [];
        this.memLocked = false;
      });
    }
  }

  private updateMemStatus(): void {
    this.memStatus?.setText(`Mosse: ${this.memMoves} · Coppie: ${this.memMatched}/${this.memPairs}`);
  }

  // -- Codice Segreto (deductive logic, Mastermind) -----------------------

  private startCode(): void {
    this.clearScreen();
    this.codeLen = this.codeLengthForLevel();
    this.codeMax = this.codeMaxForLevel();
    this.codeAttempts = 0;
    this.codeGuess = [];
    this.codeHistoryY = 150;
    const random = new Random(`code-${Date.now()}`);
    this.codeSecret = random.shuffle(CODE_SYMBOLS.map((_, i) => i)).slice(0, this.codeLen);

    this.t(this.add.text(56, 30, `🔐 Codice Segreto · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 70, `Indovina i ${this.codeLen} simboli (tutti diversi). ⚫ = giusto al posto giusto · ⚪ = c'è ma in un'altra posizione.`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#c7dce7", wordWrap: { width: 1160 } }));
    this.codeStatus = this.t(this.add.text(58, 100, `Tentativo 1 di ${this.codeMax}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#f7d37a" }));

    // Current guess slots (right side).
    this.codeSlots = [];
    const slotStartX = this.codeLen >= 5 ? 786 : 820;
    for (let i = 0; i < this.codeLen; i += 1) {
      this.t(this.add.rectangle(slotStartX + i * 66, 560, 58, 60, 0x0c1d2a, 1).setStrokeStyle(2, 0x6be7d6, 0.6));
      this.codeSlots.push(this.t(this.add.text(slotStartX + i * 66, 560, "·", { fontFamily: "Inter, Arial", fontSize: "30px", color: "#6be7d6" }).setOrigin(0.5)));
    }
    this.t(this.add.text(820, 516, "Il tuo tentativo (tocca uno slot per cancellare):", { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0" }));
    this.codeSlots.forEach((slot, i) => {
      slot.setInteractive({ useHandCursor: true }).on("pointerdown", () => {
        if (this.codeGuess.length > i) {
          this.codeGuess.splice(i, 1);
          this.renderCodeGuess();
        }
      });
    });

    // Palette.
    CODE_SYMBOLS.forEach((symbol, index) => {
      this.t(new Button(this, 540 + (index % 3) * 80, 540 + Math.floor(index / 3) * 70, symbol, () => this.codePick(index), { width: 64, height: 60, fontSize: 26, fill: 0x21162a, stroke: 0x6be7d6 }));
    });
    this.t(new Button(this, 1140, 560, "Prova", () => this.codeSubmit(), { width: 120, height: 60, fill: 0x1f5a51, stroke: 0xf6c85f }));
    this.backBar(() => this.startCode());
  }

  private codePick(symbolIndex: number): void {
    if (this.codeGuess.length >= this.codeLen) return;
    if (this.codeGuess.includes(symbolIndex)) return; // distinct symbols only
    this.codeGuess.push(symbolIndex);
    audioManager.play("uiSelect");
    this.renderCodeGuess();
  }

  private renderCodeGuess(): void {
    this.codeSlots.forEach((slot, i) => {
      slot.setText(this.codeGuess[i] !== undefined ? CODE_SYMBOLS[this.codeGuess[i]] : "·");
    });
  }

  private codeSubmit(): void {
    if (this.codeGuess.length < this.codeLen) {
      this.codeStatus?.setText(`Completa il codice con ${this.codeLen} simboli diversi.`);
      audioManager.play("error");
      return;
    }
    this.codeAttempts += 1;
    let exact = 0;
    let present = 0;
    this.codeGuess.forEach((symbol, i) => {
      if (this.codeSecret[i] === symbol) exact += 1;
      else if (this.codeSecret.includes(symbol)) present += 1;
    });

    const y = this.codeHistoryY;
    this.t(this.add.text(58, y, `${this.codeAttempts}.`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#7d93a0" }));
    this.codeGuess.forEach((symbol, i) => {
      this.t(this.add.text(96 + i * 44, y, CODE_SYMBOLS[symbol], { fontFamily: "Inter, Arial", fontSize: "24px" }));
    });
    this.t(this.add.text(300, y + 4, `${"⚫".repeat(exact)}${"⚪".repeat(present)}${"▫".repeat(this.codeLen - exact - present)}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: "#dbe6ee" }));
    this.codeHistoryY += 42;

    if (exact === this.codeLen) {
      audioManager.play("success");
      const score = (this.codeMax - this.codeAttempts + 1) * (8 + this.gymLevel);
      this.finishActivity("code", "Codice Segreto", score, ["trasversali.logica", "pensieroCritico"], Math.min(24, 6 + (this.codeMax - this.codeAttempts) * 2 + Math.floor(this.gymLevel / 3)), `Codice da ${this.codeLen} simboli decifrato in ${this.codeAttempts} tentativi.`);
      return;
    }
    if (this.codeAttempts >= this.codeMax) {
      audioManager.play("error");
      this.finishActivity("code", "Codice Segreto", 0, ["trasversali.logica"], 4, `Codice non trovato. Era: ${this.codeSecret.map((s) => CODE_SYMBOLS[s]).join(" ")}`);
      return;
    }
    this.codeGuess = [];
    this.renderCodeGuess();
    this.codeStatus?.setText(`Tentativo ${this.codeAttempts + 1} di ${this.codeMax}`);
  }

  // -- Sequenze Logiche (inductive reasoning) -----------------------------

  private startSeq(): void {
    this.seqRound = 0;
    this.seqCorrect = 0;
    this.seqTotal = this.roundsForLevel();
    this.nextSeq();
  }

  private nextSeq(): void {
    this.clearScreen();
    if (this.seqRound >= this.seqTotal) {
      const score = roundAccuracyScore(this.seqCorrect, this.seqTotal, this.gymLevel);
      this.finishActivity("seq", "Sequenze Logiche", score, ["trasversali.logica", "pensieroCritico"], Math.min(22, 4 + this.seqCorrect * 2 + Math.floor(this.gymLevel / 2)), `Hai risolto ${this.seqCorrect} schemi su ${this.seqTotal}.`);
      return;
    }
    const level = this.sequenceLevelForRound(this.seqRound);
    const puzzle = new LogicSequenceGenerator().generate(new Random(`seq-${Date.now()}-${this.seqRound}`), level);

    this.t(this.add.text(640, 40, `🔢 Sequenze Logiche · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Schema ${this.seqRound + 1}/${this.seqTotal} · regola profondità ${level} · corrette: ${this.seqCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

    this.t(this.add.text(640, 200, `${puzzle.sequence.join("   ,   ")}   ,   ?`, { fontFamily: "Inter, Arial", fontSize: "40px", color: "#f6c85f", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 280, puzzle.question, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#c7dce7" }).setOrigin(0.5));

    puzzle.options.forEach((option, index) => {
      const x = 360 + (index % 2) * 560;
      const y = 380 + Math.floor(index / 2) * 90;
      this.t(new Button(this, x, y, option, () => this.answerSeq(puzzle, index), { width: 500, height: 70, fontSize: 24, fill: 0x21162a, stroke: 0x70d68a }));
    });
    this.backBar(() => this.startSeq());
  }

  private answerSeq(puzzle: LogicSequence, choice: number): void {
    const correct = choice === puzzle.correctIndex;
    if (correct) {
      this.seqCorrect += 1;
      audioManager.play("success");
    } else {
      audioManager.play("error");
    }
    this.t(this.add.rectangle(640, 600, 1100, 90, 0x0c1d2a, 0.96).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.7));
    this.t(this.add.text(640, 600, `${correct ? "✓ Esatto! " : "✗ Quasi! "}${puzzle.explanation}`, { fontFamily: "Inter, Arial", fontSize: "15px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1060 } }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    this.time.delayedCall(1900, () => {
      this.seqRound += 1;
      this.nextSeq();
    });
  }

  // -- Bilancia Logica (deductive reasoning) ------------------------------

  private startBalance(): void {
    this.balRound = 0;
    this.balCorrect = 0;
    this.balTotal = this.roundsForLevel();
    this.nextBalance();
  }

  private nextBalance(): void {
    this.clearScreen();
    if (this.balRound >= this.balTotal) {
      const score = roundAccuracyScore(this.balCorrect, this.balTotal, this.gymLevel);
      this.finishActivity("balance", "Bilancia Logica", score, ["trasversali.logica", "pensieroCritico"], Math.min(22, 4 + this.balCorrect * 2 + Math.floor(this.gymLevel / 2)), `Hai risolto ${this.balCorrect} deduzioni su ${this.balTotal}.`);
      return;
    }
    const level = this.sequenceLevelForRound(this.balRound);
    const puzzle = generateBalance(new Random(`bal-${Date.now()}-${this.balRound}`), level);

    this.t(this.add.text(640, 40, `⚖️ Bilancia Logica · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.t(this.add.text(640, 82, `Deduzione ${this.balRound + 1}/${this.balTotal} · regola profondità ${level} · corrette: ${this.balCorrect}`, { fontFamily: "Inter, Arial", fontSize: "14px", color: "#9ff5e9" }).setOrigin(0.5));

    this.t(this.add.text(640, 150, "Indizi:", { fontFamily: "Inter, Arial", fontSize: "16px", color: "#f7d37a", fontStyle: "bold" }).setOrigin(0.5));
    puzzle.clues.forEach((clue, i) => {
      this.t(this.add.text(640, 188 + i * 34, clue, { fontFamily: "Inter, Arial", fontSize: "22px", color: "#f5fbff" }).setOrigin(0.5));
    });
    this.t(this.add.text(640, 188 + puzzle.clues.length * 34 + 14, puzzle.question, { fontFamily: "Inter, Arial", fontSize: "20px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));

    puzzle.options.forEach((option, index) => {
      const compact = option.length > 4;
      const x = 640 - ((puzzle.options.length - 1) * 180) / 2 + index * 180;
      this.t(new Button(this, x, 470, option, () => this.answerBalance(puzzle, index), { width: compact ? 176 : 130, height: 110, fontSize: compact ? 16 : 44, fill: 0x21162a, stroke: 0xf6c85f, wordWrapWidth: compact ? 142 : undefined }));
    });
    this.backBar(() => this.startBalance());
  }

  private answerBalance(puzzle: BalancePuzzle, choice: number): void {
    const correct = choice === puzzle.correctIndex;
    if (correct) {
      this.balCorrect += 1;
      audioManager.play("success");
    } else {
      audioManager.play("error");
    }
    this.t(this.add.rectangle(640, 600, 1100, 90, 0x0c1d2a, 0.96).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.7));
    this.t(this.add.text(640, 600, `${correct ? "✓ Esatto! " : "✗ Quasi! "}${puzzle.explanation}`, { fontFamily: "Inter, Arial", fontSize: "16px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1060 } }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    this.time.delayedCall(2000, () => {
      this.balRound += 1;
      this.nextBalance();
    });
  }

  // -- Griglia Lampo (spatial memory) -------------------------------------

  private startFlash(): void {
    this.clearScreen();
    this.flashRound = 0;
    this.t(this.add.text(640, 40, `⚡ Griglia Lampo · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    this.flashStatus = this.t(this.add.text(640, 84, this.flashSequentialMode() ? "Memorizza ordine e posizione…" : "Memorizza le caselle accese…", { fontFamily: "Inter, Arial", fontSize: "18px", color: "#9ff5e9" }).setOrigin(0.5));

    const size = this.flashGridSize();
    const cell = size >= 5 ? 74 : 96;
    const gap = size >= 5 ? 10 : 12;
    const total = size * cell + (size - 1) * gap;
    const startX = 640 - total / 2 + cell / 2;
    const startY = 200;
    this.flashCells = [];
    for (let i = 0; i < size * size; i += 1) {
      const col = i % size;
      const row = Math.floor(i / size);
      const x = startX + col * (cell + gap);
      const y = startY + row * (cell + gap);
      const rect = this.t(this.add.rectangle(x, y, cell, cell, 0x123247, 1).setStrokeStyle(2, 0x6be7d6, 0.5).setInteractive({ useHandCursor: true }));
      rect.on("pointerdown", () => this.flashClick(i));
      this.flashCells.push(rect);
    }
    this.backBar(() => this.startFlash());
    this.time.delayedCall(700, () => this.flashShow());
  }

  private flashShow(): void {
    this.flashLocked = true;
    this.flashPicked = new Set();
    this.flashTarget = new Set();
    this.flashTargetOrder = [];
    const count = this.flashBaseCount() + this.flashRound;
    const random = new Random(`flash-${Date.now()}-${this.flashRound}`);
    while (this.flashTarget.size < Math.min(count, this.flashCells.length - 1)) {
      this.flashTarget.add(random.integer(0, this.flashCells.length - 1));
    }
    this.flashTargetOrder = [...this.flashTarget];
    this.flashStatus?.setText(this.flashSequentialMode()
      ? `Turno ${this.flashRound + 1} · memorizza ${this.flashTarget.size} caselle in ordine…`
      : `Turno ${this.flashRound + 1} · memorizza ${this.flashTarget.size} caselle…`);
    audioManager.play("scan");
    if (this.flashSequentialMode()) {
      const stepMs = settingsSystem.effectsReduced() ? 360 : 460 - this.gymLevel * 18;
      this.flashTargetOrder.forEach((index, i) => {
        this.time.delayedCall(420 + i * stepMs, () => {
          this.flashCells[index].setFillStyle(0xf6c85f, 1);
          this.time.delayedCall(Math.max(160, stepMs - 90), () => this.flashCells[index].setFillStyle(0x123247, 1));
        });
      });
      this.time.delayedCall(560 + this.flashTargetOrder.length * stepMs, () => {
        this.flashLocked = false;
        this.flashStatus?.setText("Ora ripeti lo stesso ordine!");
      });
      return;
    }
    this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0xf6c85f, 1));
    const showMs = settingsSystem.effectsReduced() ? 1600 : Math.max(720, 1250 + this.flashTarget.size * 110 - this.gymLevel * 80);
    this.time.delayedCall(showMs, () => {
      this.flashTarget.forEach((index) => this.flashCells[index].setFillStyle(0x123247, 1));
      this.flashLocked = false;
      this.flashStatus?.setText("Ora tocca le caselle che erano accese!");
    });
  }

  private flashClick(index: number): void {
    if (this.flashLocked || this.flashPicked.has(index)) return;
    const expected = this.flashSequentialMode() ? this.flashTargetOrder[this.flashPicked.size] : undefined;
    if (!this.flashTarget.has(index) || (this.flashSequentialMode() && index !== expected)) {
      audioManager.play("error");
      this.flashCells[index].setFillStyle(0xff5d7a, 1);
      this.flashLocked = true;
      const message = this.flashSequentialMode() && expected !== undefined
        ? `Ordine interrotto: serviva la casella ${expected + 1}, non la ${index + 1}.`
        : `Hai ricostruito ${this.flashRound} griglie.`;
      this.finishActivity("flash", "Griglia Lampo", this.flashRound + this.gymLevel * 2, ["trasversali.memoria"], Math.min(22, 4 + this.flashRound * 2 + Math.floor(this.gymLevel / 2)), message);
      return;
    }
    audioManager.play("uiSelect");
    this.flashPicked.add(index);
    this.flashCells[index].setFillStyle(0x70d68a, 1);
    if (this.flashPicked.size === this.flashTarget.size) {
      audioManager.play("success");
      this.flashLocked = true;
      this.flashRound += 1;
      this.flashStatus?.setText("Perfetto! Griglia più grande…");
      const targetRounds = this.gymLevel >= 6 ? 8 : 10;
      if (this.flashRound >= targetRounds) {
        this.finishActivity("flash", "Griglia Lampo", targetRounds + this.gymLevel * 3, ["trasversali.memoria"], 22, this.flashSequentialMode() ? "Hai ricostruito tutte le sequenze spaziali." : "Memoria spaziale eccezionale!");
        return;
      }
      this.time.delayedCall(800, () => {
        this.flashCells.forEach((rect) => rect.setFillStyle(0x123247, 1));
        this.flashShow();
      });
    }
  }

  // -- Firewall NORA (rule switching + cyber-logic) ----------------------

  private startFirewall(): void {
    this.clearScreen();
    this.firewallIndex = 0;
    this.firewallCorrect = 0;
    this.firewallErrors = 0;
    this.firewallStreak = 0;
    this.firewallBestStreak = 0;
    this.firewallStability = 100;
    this.firewallRevealed = new Set();
    this.firewallScansLeft = this.firewallScanLimit();
    this.firewallLocked = false;
    this.firewallSignals = this.buildFirewallSignals(new Random(`firewall-${Date.now()}-${this.gymLevel}`));

    this.drawFirewallBackdrop();

    const bg = this.t(this.add.graphics());
    bg.fillStyle(0x06131c, 0.42);
    bg.fillRoundedRect(34, 92, 1212, 560, 10);
    bg.lineStyle(2, 0x5ec8ff, 0.34);
    bg.strokeRoundedRect(34, 92, 1212, 560, 10);
    for (let x = 90; x <= 1190; x += 74) {
      bg.lineStyle(1, 0x5ec8ff, 0.06);
      bg.lineBetween(x, 112, x, 626);
    }
    for (let y = 132; y <= 612; y += 48) {
      bg.lineStyle(1, 0x5ec8ff, 0.05);
      bg.lineBetween(54, y, 1226, y);
    }

    this.t(this.add.text(56, 32, `FW  Firewall NORA · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "24px", color: "#f5fbff", fontStyle: "bold" }));
    this.t(this.add.text(58, 70, "Indaga il segnale con gli strumenti, capisci il problema e applica il protocollo giusto. Meno scansioni usi, più NORA resta stabile.", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", wordWrap: { width: 920 } }));
    this.firewallStatus = this.t(this.add.text(1042, 54, "", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f7d37a", fontStyle: "bold", align: "right" }).setOrigin(0.5));

    this.drawFirewallRound();
    this.backBar(() => this.startFirewall());
  }

  private drawFirewallBackdrop(): void {
    if (this.textures.exists("logic-gym-firewall-bg")) {
      const backdrop = this.t(this.add.image(640, 360, "logic-gym-firewall-bg"));
      backdrop.setDisplaySize(1334, 750).setAlpha(0.9);
      if (!settingsSystem.effectsReduced()) {
        this.tweens.add({
          targets: backdrop,
          scaleX: backdrop.scaleX * 1.018,
          scaleY: backdrop.scaleY * 1.018,
          duration: 14000,
          yoyo: true,
          repeat: -1,
          ease: "Sine.easeInOut",
        });
      }
    }
    const shade = this.t(this.add.graphics());
    shade.fillStyle(0x02070b, 0.3);
    shade.fillRect(0, 0, 1280, 720);
    shade.fillGradientStyle(0x02070b, 0x02070b, 0x02070b, 0x02070b, 0.72, 0.22, 0.22, 0.72);
    shade.fillRect(0, 0, 1280, 720);
    shade.fillStyle(0x5ec8ff, 0.05);
    shade.fillCircle(640, 312, 210);
    shade.lineStyle(1, 0x5ec8ff, 0.1);
    for (let x = 58; x <= 1222; x += 84) {
      shade.lineBetween(x, 98, x + 130, 650);
    }
    const pulse = this.t(this.add.circle(640, 330, 112, 0x5ec8ff, 0.055).setStrokeStyle(2, 0x5ec8ff, 0.22));
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: pulse, scale: 1.35, alpha: 0.01, duration: 1600, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }
  }

  private buildFirewallSignals(random: Random): FirewallSignal[] {
    const total = this.firewallRoundCount();
    const signals: FirewallSignal[] = [];
    const guardTypes = this.firewallAvailableActions();
    let attempts = 0;
    while (signals.length < total && attempts < total * 12) {
      attempts += 1;
      const signal = this.buildFirewallSignal(random, signals.length + attempts);
      if (!guardTypes.includes(signal.correctAction)) continue;
      signals.push(signal);
    }
    while (signals.length < total) {
      const fallback = this.buildFirewallSignal(random, signals.length + 100);
      fallback.color = signals.length % 2 === 0 ? "blu" : "rosso";
      fallback.signature = fallback.color === "rosso" ? "alterata" : "stabile";
      fallback.payload = fallback.color === "rosso" ? "esca" : "pulito";
      fallback.route = "interna";
      fallback.repeated = false;
      fallback.priority = false;
      const classified = this.classifyFirewallSignal(fallback);
      signals.push({ ...fallback, ...classified });
    }
    return random.shuffle(signals);
  }

  private buildFirewallSignal(random: Random, index: number): FirewallSignal {
    const colors = this.gymLevel <= 2
      ? (["blu", "verde", "rosso", "viola"] as const)
      : this.gymLevel <= 4
        ? (["blu", "verde", "rosso", "viola"] as const)
        : (["blu", "verde", "rosso", "ambra", "viola"] as const);
    const signatures = this.gymLevel <= 2
      ? (["stabile", "alterata", "mancante"] as const)
      : this.gymLevel <= 4
        ? (["stabile", "alterata", "mancante"] as const)
        : (["stabile", "alterata", "mancante", "incerta"] as const);
    const payloads = this.gymLevel <= 1
      ? (["pulito", "rumoroso", "esca"] as const)
      : this.gymLevel <= 4
        ? (["pulito", "rumoroso", "criptato", "esca"] as const)
        : (["pulito", "rumoroso", "criptato", "esca"] as const);
    const routes = this.gymLevel <= 1
      ? (["interna", "sconosciuta"] as const)
      : (["interna", "esterna", "sconosciuta"] as const);
    const origins = ["NORA-Core", "Archivio", "Serra", "Fabbrica", "Laboratorio", "Nodo Ombra", "Biblioteca", "Osservatorio"];
    const ports = [12, 24, 37, 48, 64, 81, 96, 108];
    const scenario = this.firewallScenario(random);
    const signal = {
      id: `N-${String(index).padStart(3, "0")}`,
      scenario: scenario.title,
      task: scenario.task,
      color: random.pick(colors),
      origin: random.pick(origins),
      port: random.pick(ports),
      signature: random.pick(signatures),
      payload: random.pick(payloads),
      route: random.pick(routes),
      repeated: this.gymLevel >= 1 && random.bool(this.gymLevel >= 6 ? 0.34 : 0.24),
      priority: this.gymLevel >= 7 && random.bool(0.22),
      threat: 0,
      diagnosis: "",
      correctAction: "allow" as FirewallAction,
      reason: "",
    };
    const classified = this.classifyFirewallSignal(signal);
    return { ...signal, ...classified };
  }

  private firewallScenario(random: Random): { title: string; task: string } {
    return random.pick([
      { title: "Archivio studenti", task: "Una richiesta vuole leggere un registro: proteggi i dati senza bloccare il lavoro." },
      { title: "Serra automatica", task: "Un modulo irrigazione chiede accesso: evita falsi allarmi, ma non fidarti dei segnali incompleti." },
      { title: "Porta laboratorio", task: "Una porta riceve un comando remoto: se il messaggio e' dubbio, non deve arrivare al motore." },
      { title: "Biblioteca NORA", task: "Un indice digitale sta sincronizzando: separa rumore, esche e traffico sicuro." },
      { title: "Nucleo energia", task: "Un canale ad alta priorita' chiede passaggio: controlla prima identita' e contenuto." },
      { title: "Banchi officina", task: "Una console segnala manutenzione: decidi se farla proseguire, isolarla o analizzarla." },
    ]);
  }

  private classifyFirewallSignal(signal: Pick<FirewallSignal, "color" | "signature" | "payload" | "route" | "repeated" | "priority">): Pick<FirewallSignal, "correctAction" | "reason" | "threat" | "diagnosis"> {
    const threat = this.firewallThreat(signal);
    if (this.gymLevel >= 7 && signal.priority && signal.signature === "stabile" && signal.color !== "rosso" && signal.payload !== "esca") {
      return { correctAction: "allow", threat, diagnosis: "Canale prioritario affidabile", reason: "La priorita' non basta da sola: qui funziona perche' firma e contenuto sono coerenti." };
    }
    if (signal.color === "rosso" || signal.signature === "alterata" || signal.payload === "esca") {
      return { correctAction: "block", threat, diagnosis: "Minaccia attiva", reason: "Una esca, una firma alterata o un segnale rosso non si isola soltanto: va fermato." };
    }
    if (this.gymLevel >= 2 && (signal.signature === "incerta" || signal.payload === "criptato" || signal.color === "ambra")) {
      return { correctAction: "inspect", threat, diagnosis: "Dato ambiguo", reason: "Quando il contenuto non e' leggibile o la firma e' incerta, la scelta didattica e' ispezionare." };
    }
    if (this.gymLevel >= 4 && signal.route === "esterna" && signal.repeated) {
      return { correctAction: "block", threat, diagnosis: "Pattern aggressivo", reason: "Rotta esterna ripetuta: non e' un dubbio isolato, e' un comportamento aggressivo." };
    }
    if (signal.signature === "mancante" || signal.repeated || signal.payload === "rumoroso" || signal.route === "sconosciuta" || signal.color === "viola" || threat >= 3) {
      return { correctAction: "quarantine", threat, diagnosis: "Rischio isolabile", reason: "Gli indizi sono incompleti o rumorosi: quarantena significa separare senza distruggere." };
    }
    return { correctAction: "allow", threat, diagnosis: "Traffico pulito", reason: "Identita', contenuto e percorso sono coerenti: lasciar passare e' la scelta efficiente." };
  }

  private firewallThreat(signal: Pick<FirewallSignal, "color" | "signature" | "payload" | "route" | "repeated" | "priority">): number {
    let threat = 0;
    if (signal.color === "rosso") threat += 4;
    if (signal.color === "ambra") threat += 2;
    if (signal.color === "viola") threat += 1;
    if (signal.signature === "alterata") threat += 4;
    if (signal.signature === "mancante") threat += 2;
    if (signal.signature === "incerta") threat += 2;
    if (signal.payload === "esca") threat += 4;
    if (signal.payload === "criptato") threat += 2;
    if (signal.payload === "rumoroso") threat += 1;
    if (signal.route === "sconosciuta") threat += 1;
    if (signal.route === "esterna") threat += 1;
    if (signal.repeated) threat += 2;
    if (signal.priority) threat -= 2;
    return Phaser.Math.Clamp(threat, 0, 9);
  }

  private drawFirewallInvestigation(signal: FirewallSignal): void {
    const x = 66;
    const y = 124;
    this.ft(this.add.rectangle(x, y, 318, 470, 0x0b1f2d, 0.94).setOrigin(0).setStrokeStyle(2, 0x5ec8ff, 0.42));
    this.ft(this.add.text(x + 22, y + 18, "1 · Indaga", { fontFamily: "Inter, Arial", fontSize: "20px", color: "#f5fbff", fontStyle: "bold" }));
    this.ft(this.add.text(x + 22, y + 48, `Scansioni: ${this.firewallScansLeft}/${this.firewallScanLimit()} · minime: ${this.firewallMinimumScans()}`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", fontStyle: "bold" }));
    this.ft(this.add.text(x + 22, y + 76, signal.scenario, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#9ff5e9", fontStyle: "bold", wordWrap: { width: 270 } }));
    this.ft(this.add.text(x + 22, y + 104, signal.task, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#c7dce7", wordWrap: { width: 270 }, lineSpacing: 3 }));

    const lenses: FirewallLens[] = ["identity", "content", "route", "priority"];
    lenses.forEach((lens, index) => {
      const info = this.firewallLensInfo(signal, lens);
      const rowY = y + 188 + index * 58;
      const revealed = this.firewallRevealed.has(lens);
      this.ft(new Button(this, x + 92, rowY + 22, `${revealed ? "✓ " : ""}${info.label}`, () => this.scanFirewall(lens), {
        width: 136,
        height: 42,
        fontSize: 13,
        fill: revealed ? 0x173b36 : 0x143247,
        stroke: info.color,
        wordWrapWidth: 116,
      }));
      this.ft(this.add.text(x + 174, rowY + 8, revealed ? info.shortValue : info.lesson, {
        fontFamily: "Inter, Arial",
        fontSize: "11px",
        color: revealed ? "#f5fbff" : "#8aa6b0",
        wordWrap: { width: 118 },
      }));
    });

    this.ft(this.add.text(x + 22, y + 426, "Obiettivo: scegli poche scansioni, poi applica il protocollo. Non ogni anomalia va bloccata.", {
      fontFamily: "Inter, Arial",
      fontSize: "11px",
      color: "#f7d37a",
      wordWrap: { width: 270 },
    }));
  }

  private drawFirewallRound(): void {
    this.clearFirewallRound();
    if (this.firewallIndex >= this.firewallSignals.length) {
      this.finishFirewall();
      return;
    }
    this.firewallLocked = false;
    const signal = this.firewallSignals[this.firewallIndex];
    this.firewallStatus?.setText(`Segnale ${this.firewallIndex + 1}/${this.firewallSignals.length} · Scan ${this.firewallScansLeft} · Combo x${this.firewallStreak} · Stabilità ${this.firewallStability}%`);
    this.drawFirewallInvestigation(signal);
    this.drawFirewallGrid(signal);

    const actions = this.firewallAvailableActions();
    this.ft(this.add.text(1042, 382, "3 · Applica protocollo", { fontFamily: "Inter, Arial", fontSize: "15px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
    actions.forEach((action, index) => {
      const x = 945 + (index % 2) * 168;
      const y = 410 + Math.floor(index / 2) * 82;
      this.ft(new Button(this, x, y, this.firewallActionLabel(action), () => this.answerFirewall(action), {
        width: 148,
        height: 58,
        fontSize: 15,
        fill: this.firewallActionFill(action),
        stroke: this.firewallActionColor(action),
        wordWrapWidth: 126,
      }));
    });
  }

  private firewallLensInfo(signal: FirewallSignal, lens: FirewallLens): { label: string; lesson: string; shortValue: string; color: number } {
    switch (lens) {
      case "identity":
        return {
          label: "Identità",
          lesson: "chi parla?",
          shortValue: `${signal.signature}, ${signal.color}`,
          color: this.firewallSignatureColor(signal.signature),
        };
      case "content":
        return {
          label: "Contenuto",
          lesson: "cosa porta?",
          shortValue: `${signal.payload}, rischio ${signal.threat}`,
          color: this.firewallPayloadColor(signal.payload),
        };
      case "route":
        return {
          label: "Percorso",
          lesson: "da dove passa?",
          shortValue: `${signal.route}${signal.repeated ? ", ripetuto" : ""}`,
          color: this.firewallRouteColor(signal.route),
        };
      case "priority":
        return {
          label: "Priorità",
          lesson: "ha permessi?",
          shortValue: signal.priority ? "prioritario" : "normale",
          color: signal.priority ? 0x9f8cff : 0x7d93a0,
        };
    }
  }

  private drawFirewallGrid(signal: FirewallSignal): void {
    const field = this.ft(this.add.graphics());
    field.lineStyle(2, 0x5ec8ff, 0.42);
    field.strokeRoundedRect(424, 136, 408, 344, 12);
    field.fillStyle(0x09202d, 0.82);
    field.fillRoundedRect(424, 136, 408, 344, 12);
    field.lineStyle(2, this.firewallSignalColor(signal.color), 0.72);
    field.strokeRoundedRect(454, 174, 348, 248, 10);
    const riskKnown = this.firewallRevealed.size >= 2 || this.firewallRevealed.has("content");
    field.fillStyle(0x071018, 0.82);
    field.fillRoundedRect(478, 438, 300, 18, 6);
    field.fillStyle(riskKnown ? (signal.threat >= 6 ? 0xff5d7a : signal.threat >= 3 ? 0xf6c85f : 0x70d68a) : 0x42515a, 0.9);
    field.fillRoundedRect(482, 442, riskKnown ? Math.max(14, (292 * signal.threat) / 9) : 24, 10, 5);
    field.lineStyle(3, 0x5ec8ff, 0.2);
    field.lineBetween(454, 300, 802, 300);
    field.lineBetween(628, 174, 628, 422);

    const nodes = [
      { x: 486, y: 226 }, { x: 486, y: 376 }, { x: 770, y: 226 }, { x: 770, y: 376 },
      { x: 628, y: 174 }, { x: 628, y: 422 },
    ];
    nodes.forEach((node, i) => {
      field.lineStyle(1, 0x9ff5e9, 0.18);
      field.lineBetween(628, 300, node.x, node.y);
      field.fillStyle(i % 2 === 0 ? 0x5ec8ff : 0xf6c85f, 0.72);
      field.fillCircle(node.x, node.y, 7);
    });

    const packetColor = this.firewallSignalColor(signal.color);
    const packet = this.ft(this.add.container(628, 300));
    const outer = this.add.circle(0, 0, 58, packetColor, 0.16).setStrokeStyle(3, packetColor, 0.9);
    const inner = this.add.rectangle(0, 0, 78, 46, 0x071018, 0.94).setStrokeStyle(2, packetColor, 0.9);
    const label = this.add.text(0, -5, signal.id, { fontFamily: "Inter, Arial", fontSize: "18px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5);
    const port = this.add.text(0, 17, `porta ${signal.port}`, { fontFamily: "Inter, Arial", fontSize: "11px", color: "#9ff5e9" }).setOrigin(0.5);
    packet.add([outer, inner, label, port]);
    this.firewallPacket = packet;
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: outer, scale: 1.18, alpha: 0.34, duration: 620, yoyo: true, repeat: -1 });
      this.tweens.add({ targets: packet, y: 292, duration: 900, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
    }

    const dataX = 874;
    const dataY = 128;
    this.ft(this.add.rectangle(dataX, dataY, 332, 276, 0x0b1f2d, 0.92).setOrigin(0).setStrokeStyle(2, 0x5ec8ff, 0.38));
    this.ft(this.add.text(dataX + 22, dataY + 18, "2 · Taccuino NORA", { fontFamily: "Inter, Arial", fontSize: "19px", color: "#f5fbff", fontStyle: "bold" }));
    const rows = this.firewallNotebookRows(signal);
    rows.forEach(([labelText, value, color], index) => {
      const rowY = dataY + 58 + index * 26;
      this.ft(this.add.text(dataX + 24, rowY, `${labelText}:`, { fontFamily: "Inter, Arial", fontSize: "12px", color: "#9aaab0" }));
      this.ft(this.add.text(dataX + 116, rowY, String(value), { fontFamily: "Inter, Arial", fontSize: "13px", color: Phaser.Display.Color.IntegerToColor(color as number).rgba, fontStyle: "bold", wordWrap: { width: 170 } }));
    });

    this.ft(this.add.text(628, 512, riskKnown ? `Rischio stimato ${signal.threat}/9` : "Rischio non stimato: scansiona almeno due aspetti", { fontFamily: "Inter, Arial", fontSize: "13px", color: "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
    audioManager.play("scan");
  }

  private firewallNotebookRows(signal: FirewallSignal): Array<[string, string, number]> {
    const hidden: [string, string, number] = ["?", "non scansionato", 0x7d93a0];
    const rows: Array<[string, string, number]> = [];
    if (this.firewallRevealed.has("identity")) {
      rows.push(["Colore", signal.color.toUpperCase(), this.firewallSignalColor(signal.color)]);
      rows.push(["Origine", signal.origin, 0x9ff5e9]);
      rows.push(["Firma", signal.signature.toUpperCase(), this.firewallSignatureColor(signal.signature)]);
    } else {
      rows.push(["Identità", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("content")) {
      rows.push(["Payload", signal.payload.toUpperCase(), this.firewallPayloadColor(signal.payload)]);
      rows.push(["Rischio", `${signal.threat}/9`, signal.threat >= 6 ? 0xff5d7a : signal.threat >= 3 ? 0xf6c85f : 0x70d68a]);
    } else {
      rows.push(["Contenuto", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("route")) {
      rows.push(["Rotta", signal.route.toUpperCase(), this.firewallRouteColor(signal.route)]);
      rows.push(["Ripetuto", signal.repeated ? "SI" : "NO", signal.repeated ? 0xf6c85f : 0x70d68a]);
    } else {
      rows.push(["Percorso", hidden[1], hidden[2]]);
    }
    if (this.firewallRevealed.has("priority")) {
      rows.push(["Priorità", signal.priority ? "SI" : "NO", signal.priority ? 0x9f8cff : 0x7d93a0]);
    } else {
      rows.push(["Priorità", hidden[1], hidden[2]]);
    }
    return rows.slice(0, 8);
  }

  private scanFirewall(lens: FirewallLens): void {
    if (this.firewallLocked) return;
    const signal = this.firewallSignals[this.firewallIndex];
    if (!signal) return;
    if (this.firewallRevealed.has(lens)) {
      audioManager.play("hint");
      this.firewallStatus?.setText(`${this.firewallLensInfo(signal, lens).label} e' gia' nel taccuino.`);
      return;
    }
    if (this.firewallScansLeft <= 0) {
      audioManager.play("error");
      this.firewallStatus?.setText("Scanner scarichi: ora devi decidere con gli indizi raccolti.");
      return;
    }
    this.firewallRevealed.add(lens);
    this.firewallScansLeft -= 1;
    this.firewallStability = Phaser.Math.Clamp(this.firewallStability - (this.gymLevel >= 6 ? 3 : 1), 0, 100);
    audioManager.play("scan");
    this.drawFirewallRound();
  }

  private answerFirewall(action: FirewallAction): void {
    if (this.firewallLocked) return;
    const signal = this.firewallSignals[this.firewallIndex];
    if (!signal) return;
    if (this.firewallRevealed.size < this.firewallMinimumScans()) {
      audioManager.play("hint");
      this.firewallStatus?.setText(`Prima raccogli almeno ${this.firewallMinimumScans()} indizi: una decisione senza osservazione vale poco.`);
      return;
    }
    this.firewallLocked = true;
    const correct = action === signal.correctAction;
    const scanBonus = Math.max(0, this.firewallScansLeft);
    if (correct) {
      this.firewallCorrect += 1;
      this.firewallStreak += 1;
      this.firewallBestStreak = Math.max(this.firewallBestStreak, this.firewallStreak);
      this.firewallStability = Phaser.Math.Clamp(this.firewallStability + 4 + scanBonus * 2 + Math.min(5, this.firewallStreak), 0, 100);
      audioManager.play(this.firewallStreak > 0 && this.firewallStreak % 3 === 0 ? "circuitOn" : "success");
    } else {
      this.firewallErrors += 1;
      this.firewallStreak = 0;
      this.firewallStability = Phaser.Math.Clamp(this.firewallStability - 18, 0, 100);
      audioManager.play("error");
      this.cameras.main.shake(120, 0.003);
    }
    this.firewallPacket?.each((child: Phaser.GameObjects.GameObject) => {
      if (child instanceof Phaser.GameObjects.Shape) {
        child.setAlpha(correct ? 0.95 : 0.82);
      }
    });
    this.revealFirewallAnswer(signal);
    this.ft(this.add.rectangle(640, 590, 1060, 108, 0x071018, 0.98).setStrokeStyle(2, correct ? 0x70d68a : 0xff5d7a, 0.75));
    const text = correct
      ? `Corretto · combo x${this.firewallStreak} · diagnosi: ${signal.diagnosis}`
      : `Da correggere: serviva ${this.firewallActionLabel(signal.correctAction)} · diagnosi: ${signal.diagnosis}`;
    this.ft(this.add.text(640, 568, text, { fontFamily: "Inter, Arial", fontSize: "15px", color: correct ? "#9ff5c0" : "#ffd0da", align: "center", wordWrap: { width: 1000 } }).setOrigin(0.5));
    this.ft(this.add.text(640, 612, signal.reason, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#dbefff", align: "center", wordWrap: { width: 1000 } }).setOrigin(0.5));
    this.ft(this.add.text(640, 638, this.firewallReflection(signal), { fontFamily: "Inter, Arial", fontSize: "12px", color: "#f7d37a", align: "center", wordWrap: { width: 980 } }).setOrigin(0.5));
    const burst = this.ft(this.add.graphics());
    burst.lineStyle(4, correct ? 0x70d68a : 0xff5d7a, 0.82);
    burst.strokeCircle(correct ? 760 : 496, 300, 42);
    burst.lineStyle(2, correct ? 0x9ff5e9 : 0xffd0da, 0.58);
    burst.lineBetween(628, 300, correct ? 806 : 450, 300);
    this.ft(this.add.text(correct ? 838 : 416, 300, correct ? `+stabilità ${this.firewallStability}%` : `stabilità ${this.firewallStability}%`, { fontFamily: "Inter, Arial", fontSize: "13px", color: correct ? "#9ff5c0" : "#ffd0da", fontStyle: "bold" }).setOrigin(0.5));
    this.tracked.forEach((object) => {
      if (object instanceof Button) object.disableInteractive();
    });
    if (!settingsSystem.effectsReduced()) {
      this.tweens.add({ targets: this.firewallPacket, x: correct ? 760 : 496, duration: 260, yoyo: true, ease: "Cubic.easeOut" });
      this.tweens.add({ targets: burst, scale: 1.18, alpha: 0.22, duration: 520, ease: "Cubic.easeOut" });
    }
    this.time.delayedCall(2400, () => {
      this.firewallIndex += 1;
      this.firewallRevealed = new Set();
      this.firewallScansLeft = this.firewallScanLimit();
      this.drawFirewallRound();
    });
  }

  private revealFirewallAnswer(signal: FirewallSignal): void {
    this.firewallRevealed = new Set<FirewallLens>(["identity", "content", "route", "priority"]);
    this.firewallStatus?.setText(`Protocollo: ${this.firewallActionLabel(signal.correctAction)} · ${signal.diagnosis}`);
  }

  private firewallReflection(signal: FirewallSignal): string {
    switch (signal.correctAction) {
      case "allow":
        return "Idea chiave: sicurezza non significa bloccare tutto; significa riconoscere quando un segnale e' coerente.";
      case "block":
        return "Idea chiave: una minaccia attiva va fermata, non solo messa da parte.";
      case "quarantine":
        return "Idea chiave: quando il dato e' incompleto o rumoroso, isolare protegge senza perdere informazione utile.";
      case "inspect":
        return signal.payload === "criptato"
          ? "Idea chiave: se il contenuto non e' leggibile, prima si analizza e solo dopo si decide."
          : "Idea chiave: un dubbio tecnico non e' ancora una minaccia certa; richiede controllo.";
    }
  }

  private finishFirewall(): void {
    audioManager.play(this.firewallErrors === 0 ? "circuitOn" : "success");
    const total = Math.max(1, this.firewallSignals.length);
    const accuracy = accuracyPercent(this.firewallCorrect, total);
    const score = firewallScore({ correct: this.firewallCorrect, total, level: this.gymLevel, stability: this.firewallStability, bestStreak: this.firewallBestStreak, errors: this.firewallErrors });
    const award = Math.min(24, 6 + this.firewallCorrect * 2 + Math.floor(this.gymLevel / 2));
    const summary = `Rete stabilizzata: ${this.firewallCorrect}/${total} segnali corretti, precisione ${accuracy}%, stabilità ${this.firewallStability}%, combo migliore x${this.firewallBestStreak}.`;
    this.finishActivity("firewall", "Firewall NORA", score, ["trasversali.logica", "pensieroCritico"], award, summary);
  }

  private firewallActionLabel(action: FirewallAction): string {
    switch (action) {
      case "allow": return "Consenti";
      case "block": return "Blocca";
      case "quarantine": return "Quarantena";
      case "inspect": return "Ispeziona";
    }
  }

  private firewallActionColor(action: FirewallAction): number {
    switch (action) {
      case "allow": return 0x70d68a;
      case "block": return 0xff5d7a;
      case "quarantine": return 0xf6c85f;
      case "inspect": return 0x5ec8ff;
    }
  }

  private firewallActionFill(action: FirewallAction): number {
    switch (action) {
      case "allow": return 0x173b36;
      case "block": return 0x40202d;
      case "quarantine": return 0x3d3218;
      case "inspect": return 0x143247;
    }
  }

  private firewallSignalColor(color: FirewallSignal["color"]): number {
    switch (color) {
      case "blu": return 0x5ec8ff;
      case "verde": return 0x70d68a;
      case "rosso": return 0xff5d7a;
      case "ambra": return 0xf6c85f;
      case "viola": return 0x9f8cff;
    }
  }

  private firewallSignatureColor(signature: FirewallSignal["signature"]): number {
    switch (signature) {
      case "stabile": return 0x70d68a;
      case "mancante": return 0xf6c85f;
      case "alterata": return 0xff5d7a;
      case "incerta": return 0x5ec8ff;
    }
  }

  private firewallPayloadColor(payload: FirewallPayload): number {
    switch (payload) {
      case "pulito": return 0x70d68a;
      case "rumoroso": return 0xf6c85f;
      case "criptato": return 0x5ec8ff;
      case "esca": return 0xff5d7a;
    }
  }

  private firewallRouteColor(route: FirewallRoute): number {
    switch (route) {
      case "interna": return 0x70d68a;
      case "esterna": return 0xf6c85f;
      case "sconosciuta": return 0x9f8cff;
    }
  }

  // -- Shared outcome -----------------------------------------------------

  private bonusStats(key: GymActivityKey): { correct: number; total: number; bestCombo: number } {
    switch (key) {
      case "tables": return { correct: this.tablesCorrect, total: this.tablesTotal, bestCombo: this.tablesBestCombo };
      case "mental": return { correct: this.mentalCorrect, total: this.mentalTotal, bestCombo: this.mentalBestCombo };
      case "geo": return { correct: this.geoCorrect, total: this.geoTotal, bestCombo: this.geoBestCombo };
      case "geoPhysical": return { correct: this.physCorrect, total: this.physTotal, bestCombo: this.physBestCombo };
      default: return { correct: 0, total: 0, bestCombo: 0 };
    }
  }

  private finishMissionBonus(key: LogicGymBonusActivityKey, label: string, score: number, comps: string[], award: number, summary: string): void {
    const stats = this.bonusStats(key);
    const result = missionBonusResult({
      id: this.bonusId,
      activityKey: key,
      label,
      level: this.gymLevel,
      score,
      summary,
      stats,
    });
    if (result.passed && award > 0) {
      competencyTracker.award(comps, Math.min(10, Math.max(4, Math.ceil(award / 2))));
      saveSystem.persistData();
    }

    this.time.delayedCall(80, () => {
      this.clearScreen();
      const tone = result.passed ? 0xf6c85f : 0xff5d7a;
      this.t(this.add.rectangle(640, 360, 880, 382, 0x0b1922, 0.98).setStrokeStyle(2, tone, 0.78));
      this.t(this.add.text(640, 226, result.passed ? "Frattura stabilizzata" : "Frattura instabile", {
        fontFamily: "Inter, Arial",
        fontSize: "28px",
        color: result.passed ? "#f7d37a" : "#ffd0da",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.t(this.add.text(640, 270, `${label} · ${stats.correct}/${stats.total} · precisione ${result.accuracy}%`, {
        fontFamily: "Inter, Arial",
        fontSize: "18px",
        color: "#f5fbff",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.t(this.add.text(640, 326, summary, {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: "#c7dce7",
        align: "center",
        wordWrap: { width: 760 },
        lineSpacing: 4,
      }).setOrigin(0.5));
      this.t(this.add.text(640, 394, result.passed
        ? `Bonus missione: +${result.energyAward} energia${result.timeAwardMs > 0 ? ` · +${Math.round(result.timeAwardMs / 1000)}s stabilità timer` : ""}`
        : "Nessun malus: la missione riprende dal punto in cui era.", {
        fontFamily: "Inter, Arial",
        fontSize: "15px",
        color: result.passed ? "#9ff5e9" : "#ffd0da",
        fontStyle: "bold",
      }).setOrigin(0.5));
      this.t(new Button(this, 640, 482, "Torna alla missione", () => this.returnFromMissionBonus(result), {
        width: 300,
        height: 54,
        fill: result.passed ? 0x1f5a51 : 0x263743,
        stroke: tone,
        fontSize: 17,
      }));
    });
  }

  private abortMissionBonus(): void {
    const activity = this.activities().find((item) => item.key === this.bonusActivity);
    const activityKey = this.isMissionBonusActivity(this.bonusActivity) ? this.bonusActivity : "mental";
    this.returnFromMissionBonus({
      id: this.bonusId,
      activityKey,
      label: activity?.title ?? "Frattura energetica",
      level: this.gymLevel,
      rounds: this.bonusRoundOverride ?? 0,
      correct: 0,
      score: 0,
      accuracy: 0,
      passed: false,
      perfect: false,
      energyAward: 0,
      timeAwardMs: 0,
      summary: "Evento bonus interrotto: la missione riprende senza premio e senza penalita.",
    });
  }

  private returnFromMissionBonus(result: LogicGymBonusResult): void {
    this.clearScreen();
    this.scene.start(this.bonusReturnScene, { missionBonusResult: result });
  }

  private finishActivity(key: string, label: string, score: number, comps: string[], award: number, summary: string): void {
    const activityKey = key as GymActivityKey;
    if (this.bonusMode && this.isMissionBonusActivity(activityKey)) {
      this.finishMissionBonus(activityKey, label, score, comps, award, summary);
      return;
    }
    const previous = this.bestForLevel(activityKey, this.gymLevel);
    const record = score > previous;
    const best = saveSystem.data.logicGym?.best ?? {};
    const bestByLevel = saveSystem.data.logicGym?.bestByLevel ?? {};
    saveSystem.data.logicGym = {
      best: { ...best, [key]: Math.max(best[key] ?? 0, score) },
      bestByLevel: {
        ...bestByLevel,
        [key]: {
          ...(bestByLevel[key] ?? {}),
          [String(this.gymLevel)]: Math.max(previous, score),
        },
      },
      level: this.gymLevel,
    };
    if (award > 0) {
      competencyTracker.award(comps, award);
    }
    saveSystem.persistData();

    this.time.delayedCall(key === "simon" || key === "code" ? 600 : 50, () => {
      this.clearScreen();
      this.t(this.add.rectangle(640, 360, 880, 360, 0x0b1922, 0.97).setStrokeStyle(2, 0xf6c85f, 0.7));
      this.t(this.add.text(640, 250, `${label} · Profondità ${this.gymLevel}`, { fontFamily: "Inter, Arial", fontSize: "26px", color: "#f5fbff", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 312, `Punteggio: ${score}${record ? "   ★ NUOVO RECORD DI PROFONDITÀ!" : `   (record profondità ${this.gymLevel}: ${Math.max(previous, score)})`}`, { fontFamily: "Inter, Arial", fontSize: "20px", color: record ? "#f6c85f" : "#9ff5e9", fontStyle: "bold" }).setOrigin(0.5));
      this.t(this.add.text(640, 360, summary, { fontFamily: "Inter, Arial", fontSize: "15px", color: "#c7dce7", align: "center", wordWrap: { width: 760 } }).setOrigin(0.5));
      if (award > 0) {
        this.t(this.add.text(640, 408, `+${award} competenze Trasversali`, { fontFamily: "Inter, Arial", fontSize: "13px", color: "#70d68a" }).setOrigin(0.5));
      }
      const restart = this.currentRestart ?? (() => this.showHub());
      this.t(new Button(this, 440, 470, "Riprova", () => restart(), { width: 220, height: 50, fill: 0x1f5a51, stroke: 0xf6c85f }));
      this.t(new Button(this, 700, 470, "Palestra", () => this.showHub(), { width: 200, height: 50, fill: 0x263743 }));
      this.t(new Button(this, 920, 470, "Menu", () => this.scene.start("MainMenuScene"), { width: 160, height: 50, fill: 0x263743 }));
    });
  }
}
