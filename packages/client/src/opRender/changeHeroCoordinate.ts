import { ClientComponents } from "@/mud/createClientComponents";
import { SetupNetworkResult } from "@/mud/setupNetwork";
import { Entity, getComponentValueStrict } from "@latticexyz/recs";
import { uuid } from "@latticexyz/utils";

export function opRunChangeHeroCoordinate(
  { playerEntity }: SetupNetworkResult,
  { Player, Hero }: ClientComponents,
  index: number,
  x: number,
  y: number
): string {
  const id = uuid();
  const playerData = getComponentValueStrict(Player, playerEntity);
  Hero.addOverride(id, {
    entity: playerData.heroes[index] as Entity,
    value: { x, y },
  });
  return id;
}
