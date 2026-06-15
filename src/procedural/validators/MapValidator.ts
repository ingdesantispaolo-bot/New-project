import type { GeneratedRoomMap } from "../ProceduralTypes";

export class MapValidator {
  validate(map: GeneratedRoomMap): boolean {
    const ids = new Set(map.hotspots.map((hotspot) => hotspot.id));
    const puzzleHotspots = map.hotspots.filter((hotspot) => Boolean(hotspot.puzzleId));
    const hasRequired = ids.has("door") && puzzleHotspots.length >= 1;
    const puzzleIds = new Set(puzzleHotspots.map((hotspot) => hotspot.puzzleId));
    const coherentFocus = puzzleHotspots.length === 1 || puzzleIds.size === puzzleHotspots.length;
    const nonOverlapping = map.hotspots.every((hotspot, index) =>
      map.hotspots.every((other, otherIndex) => {
        if (index === otherIndex) {
          return true;
        }
        const distance = Math.hypot(hotspot.x - other.x, hotspot.y - other.y);
        return distance > hotspot.radius + other.radius + 18;
      }),
    );
    return hasRequired && coherentFocus && nonOverlapping;
  }
}
