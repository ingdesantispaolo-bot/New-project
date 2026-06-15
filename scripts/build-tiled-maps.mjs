import fs from "node:fs/promises";
import path from "node:path";

const sourceDir = path.resolve("src/assets/maps");
const outputDir = path.join(sourceDir, "tiled");
const runtimeDir = path.join(sourceDir, "runtime");
const mapWidth = 80;
const mapHeight = 45;
const tileSize = 16;

const labRuntimeIds = {
  CircuitPanel: "electric-panel",
  CorruptedMessage: "corrupted-message",
  Door: "final-door",
  FloorTrace: "floor-trace",
  Journal: "journal-station",
  NoraCore: "nora-core",
  ObservationWindow: "observation-window",
  RobotDock: "robot",
  Terminal: "terminal",
  Workbench: "workbench",
};

const radiusByLabEntity = {
  CircuitPanel: 56,
  CorruptedMessage: 42,
  Door: 72,
  FloorTrace: 34,
  Journal: 38,
  NoraCore: 38,
  ObservationWindow: 42,
  RobotDock: 56,
  Terminal: 62,
  Workbench: 36,
};

const buildTargets = [
  {
    source: "main-hub.ldtk.json",
    level: "MainMenu",
    output: "main-menu.tiled.json",
    theme: "academy",
    expectedIds: [
      "menu:title",
      "menu:subtitle",
      "menu:copy",
      "menu:newMission",
      "menu:continue",
      "menu:journal",
      "menu:procedural",
      "menu:portal",
    ],
  },
  {
    source: "main-hub.ldtk.json",
    level: "HubAccademia",
    output: "hub-academy.tiled.json",
    theme: "academy",
    expectedIds: [
      "hub:missionCard",
      "hub:title",
      "hub:copy",
      "hub:primary",
      "hub:journal",
      "hub:procedural",
      "hub:reviewLab",
      "hub:portal",
      "hub:wing:num",
      "hub:wing:bio",
      "hub:wing:arc",
    ],
  },
  {
    source: "academy-lab.ldtk.json",
    level: "LaboratorioSpento",
    output: "academy-lab.tiled.json",
    theme: "lab",
    expectedIds: Object.values(labRuntimeIds),
  },
  {
    source: "greenhouse.ldtk.json",
    level: "SerraBiologica",
    output: "greenhouse.tiled.json",
    theme: "greenhouse",
    expectedIds: [
      "greenhouse:header",
      "greenhouse:plant:0",
      "greenhouse:plant:1",
      "greenhouse:plant:2",
      "greenhouse:dataPanel",
      "greenhouse:objectivePanel",
      "greenhouse:graph",
      "greenhouse:sensorTable",
      "greenhouse:readSensors",
      "greenhouse:advanceTurn",
    ],
  },
  {
    source: "factory.ldtk.json",
    level: "FabbricaNumeri",
    output: "factory.tiled.json",
    theme: "factory",
    expectedIds: [
      "factory:header",
      "factory:machine:0",
      "factory:machine:1",
      "factory:machine:2",
      "factory:machine:3",
      "factory:machine:4",
      "factory:machine:5",
      "factory:machine:6",
      "factory:machine:7",
      "factory:machine:8",
      "factory:core",
      "factory:controlPanel",
      "factory:scanLine",
      "factory:resetCore",
      "factory:checkOrder",
    ],
  },
  {
    source: "archive.ldtk.json",
    level: "ArchivioParole",
    output: "archive.tiled.json",
    theme: "archive",
    expectedIds: [
      "archive:header",
      "archive:shelves",
      "archive:message:0",
      "archive:message:1",
      "archive:message:2",
      "archive:terminal",
      "archive:objectivePanel",
      "archive:repairPanel",
      "archive:evidencePanel",
      "archive:instructionPanel",
      "archive:reportPanel",
    ],
  },
];

await fs.mkdir(outputDir, { recursive: true });
await fs.mkdir(runtimeDir, { recursive: true });

for (const target of buildTargets) {
  const raw = await fs.readFile(path.join(sourceDir, target.source), "utf8");
  const source = JSON.parse(raw);
  const level = source.levels.find((item) => item.identifier === target.level);
  if (!level) {
    throw new Error(`Missing level ${target.level} in ${target.source}`);
  }

  const entities = level.layerInstances.flatMap((layer) => layer.entityInstances ?? []);
  const objects = entities.map((entity, index) => toTiledObject(entity, index + 1, target.output === "academy-lab.tiled.json"));
  const foundIds = new Set(objects.map((object) => runtimeId(object)));
  const missing = target.expectedIds.filter((id) => !foundIds.has(id));
  if (missing.length > 0) {
    throw new Error(`${target.output} missing required layout IDs: ${missing.join(", ")}`);
  }

  const artLayers = buildArtLayers(target.theme);
  const tiledMap = {
    compressionlevel: -1,
    height: 45,
    infinite: false,
    layers: [
      makeTileLayer(1, "floor", artLayers.floor, 0.95),
      makeTileLayer(2, "set_dressing", artLayers.details, 0.82),
      {
        draworder: "topdown",
        id: 3,
        name: "layout",
        objects,
        opacity: 1,
        type: "objectgroup",
        visible: true,
        x: 0,
        y: 0,
      },
      makeTileLayer(4, "foreground_light", artLayers.lights, 0.58),
    ],
    nextlayerid: 5,
    nextobjectid: objects.length + 1,
    orientation: "orthogonal",
    renderorder: "right-down",
    tiledversion: "1.11.0",
    tileheight: tileSize,
    tilesets: [
      {
        columns: 8,
        firstgid: 1,
        image: "../../tiles/eli-production-tileset.png",
        imageheight: 64,
        imagewidth: 128,
        margin: 0,
        name: "eli-production-tileset",
        spacing: 0,
        tilecount: 32,
        tileheight: tileSize,
        tilewidth: tileSize,
      },
    ],
    tilewidth: tileSize,
    type: "map",
    version: "1.10",
    width: mapWidth,
  };

  await fs.writeFile(path.join(outputDir, target.output), `${JSON.stringify(tiledMap, null, 2)}\n`);
  await fs.writeFile(
    path.join(runtimeDir, target.output.replace(".tiled.json", ".layout.json")),
    `${JSON.stringify({ objects: toRuntimeLayout(objects) }, null, 2)}\n`,
  );
  console.log(`Built ${path.join("src/assets/maps/tiled", target.output)} (${objects.length} objects)`);
}

function makeTileLayer(id, name, data, opacity) {
  return {
    data,
    height: mapHeight,
    id,
    name,
    opacity,
    type: "tilelayer",
    visible: true,
    width: mapWidth,
    x: 0,
    y: 0,
  };
}

function buildArtLayers(theme) {
  const floor = filledLayer(themeBaseTile(theme));
  const details = emptyLayer();
  const lights = emptyLayer();

  addGrid(details, theme === "factory" ? 9 : theme === "archive" ? 12 : theme === "greenhouse" ? 7 : 3);
  addBorder(details, theme === "factory" ? 11 : theme === "archive" ? 12 : theme === "greenhouse" ? 6 : 18);
  addSceneMotifs(theme, details, lights);

  return { floor, details, lights };
}

function themeBaseTile(theme) {
  if (theme === "factory") return 9;
  if (theme === "greenhouse") return 7;
  if (theme === "archive") return 12;
  if (theme === "lab") return 18;
  return 3;
}

function emptyLayer() {
  return Array.from({ length: mapWidth * mapHeight }, () => 0);
}

function filledLayer(gid) {
  return Array.from({ length: mapWidth * mapHeight }, () => gid);
}

function setTile(layer, x, y, gid) {
  if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
    return;
  }
  layer[y * mapWidth + x] = gid;
}

function addGrid(layer, gid) {
  for (let x = 0; x < mapWidth; x += 7) {
    for (let y = 0; y < mapHeight; y += 1) setTile(layer, x, y, gid);
  }
  for (let y = 4; y < mapHeight; y += 6) {
    for (let x = 0; x < mapWidth; x += 1) setTile(layer, x, y, gid);
  }
}

function addBorder(layer, gid) {
  for (let x = 0; x < mapWidth; x += 1) {
    setTile(layer, x, 0, gid);
    setTile(layer, x, mapHeight - 1, gid);
  }
  for (let y = 0; y < mapHeight; y += 1) {
    setTile(layer, 0, y, gid);
    setTile(layer, mapWidth - 1, y, gid);
  }
}

function addRect(layer, x, y, width, height, gid) {
  for (let yy = y; yy < y + height; yy += 1) {
    for (let xx = x; xx < x + width; xx += 1) {
      setTile(layer, xx, yy, gid);
    }
  }
}

function addLine(layer, x1, y1, x2, y2, gid) {
  const steps = Math.max(Math.abs(x2 - x1), Math.abs(y2 - y1));
  for (let i = 0; i <= steps; i += 1) {
    const t = steps === 0 ? 0 : i / steps;
    setTile(layer, Math.round(x1 + (x2 - x1) * t), Math.round(y1 + (y2 - y1) * t), gid);
  }
}

function addSceneMotifs(theme, details, lights) {
  if (theme === "academy") {
    addRect(details, 52, 9, 18, 24, 6);
    addRect(details, 12, 34, 25, 3, 4);
    addRect(lights, 55, 12, 12, 16, 15);
    addLine(details, 42, 35, 62, 18, 4);
    return;
  }
  if (theme === "lab") {
    addRect(details, 26, 14, 10, 9, 21);
    addRect(details, 61, 14, 15, 8, 20);
    addRect(details, 45, 7, 10, 14, 19);
    addLine(details, 58, 31, 29, 18, 4);
    addLine(details, 29, 18, 67, 17, 4);
    addLine(details, 67, 17, 35, 31, 4);
    addRect(lights, 43, 8, 14, 14, 15);
    return;
  }
  if (theme === "greenhouse") {
    addRect(details, 4, 8, 46, 30, 6);
    addRect(details, 10, 22, 4, 12, 8);
    addRect(details, 25, 21, 4, 13, 8);
    addRect(details, 39, 22, 4, 12, 8);
    addRect(lights, 9, 11, 36, 20, 16);
    return;
  }
  if (theme === "factory") {
    addRect(details, 6, 21, 42, 4, 11);
    addRect(details, 54, 18, 23, 19, 10);
    addLine(details, 7, 21, 48, 21, 10);
    addRect(lights, 24, 17, 15, 10, 16);
    return;
  }
  if (theme === "archive") {
    addRect(details, 3, 8, 47, 30, 12);
    for (let y = 10; y < 35; y += 6) addRect(details, 5, y, 42, 1, 12);
    for (let x = 6; x < 46; x += 4) addRect(details, x, 11, 1, 4, x % 8 === 0 ? 13 : 14);
    addRect(lights, 8, 10, 34, 22, 15);
  }
}

function toTiledObject(entity, id, useLabRuntimeIds) {
  const width = entity.width ?? 32;
  const height = entity.height ?? 32;
  const centerX = entity.px?.[0] ?? 0;
  const centerY = entity.px?.[1] ?? 0;
  const runtime = (useLabRuntimeIds ? labRuntimeIds[entity.__identifier] : undefined) ?? fieldValue(entity, "id") ?? entity.__identifier;
  const radius = useLabRuntimeIds ? radiusByLabEntity[entity.__identifier] : undefined;
  const properties = [
    { name: "runtimeId", type: "string", value: runtime },
    { name: "anchor", type: "string", value: "center" },
  ];
  if (radius) {
    properties.push({ name: "radius", type: "int", value: radius });
  }

  return {
    height,
    id,
    name: runtime,
    properties,
    rotation: 0,
    type: entity.__identifier,
    visible: true,
    width,
    x: centerX - width / 2,
    y: centerY - height / 2,
  };
}

function fieldValue(entity, fieldId) {
  const field = entity.fieldInstances?.find((item) => item.__identifier === fieldId);
  return typeof field?.__value === "string" ? field.__value : undefined;
}

function runtimeId(object) {
  const property = object.properties.find((item) => item.name === "runtimeId");
  return property?.value ?? object.name;
}

function toRuntimeLayout(objects) {
  return Object.fromEntries(objects.map((object) => {
    const id = runtimeId(object);
    const radius = object.properties.find((item) => item.name === "radius")?.value;
    return [
      id,
      {
        x: object.x + object.width / 2,
        y: object.y + object.height / 2,
        width: object.width,
        height: object.height,
        ...(typeof radius === "number" ? { radius } : {}),
      },
    ];
  }));
}
