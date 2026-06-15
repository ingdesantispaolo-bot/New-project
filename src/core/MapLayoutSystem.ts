import academyLabLayout from "../assets/maps/runtime/academy-lab.layout.json";
import archiveLayout from "../assets/maps/runtime/archive.layout.json";
import factoryLayout from "../assets/maps/runtime/factory.layout.json";
import greenhouseLayout from "../assets/maps/runtime/greenhouse.layout.json";
import hubLayout from "../assets/maps/runtime/hub-academy.layout.json";
import mainMenuLayout from "../assets/maps/runtime/main-menu.layout.json";

export interface MapLayoutRect {
  x: number;
  y: number;
  width?: number;
  height?: number;
  radius?: number;
}

export type MapHotspotLayout = MapLayoutRect;

type RuntimeLayout = {
  objects: Record<string, MapLayoutRect>;
};

class MapLayoutSystem {
  getMainMenuLayout(): Record<string, MapLayoutRect> {
    return this.cloneLayout(mainMenuLayout as RuntimeLayout);
  }

  getHubLayout(): Record<string, MapLayoutRect> {
    return this.cloneLayout(hubLayout as RuntimeLayout);
  }

  getGreenhouseLayout(): Record<string, MapLayoutRect> {
    return this.cloneLayout(greenhouseLayout as RuntimeLayout);
  }

  getFactoryLayout(): Record<string, MapLayoutRect> {
    return this.cloneLayout(factoryLayout as RuntimeLayout);
  }

  getArchiveLayout(): Record<string, MapLayoutRect> {
    return this.cloneLayout(archiveLayout as RuntimeLayout);
  }

  getLaboratoryHotspots(): Record<string, MapHotspotLayout> {
    return this.cloneLayout(academyLabLayout as RuntimeLayout);
  }

  private cloneLayout(layout: RuntimeLayout): Record<string, MapLayoutRect> {
    return Object.fromEntries(
      Object.entries(layout.objects).map(([id, rect]) => [id, { ...rect }]),
    );
  }
}

export const mapLayoutSystem = new MapLayoutSystem();
