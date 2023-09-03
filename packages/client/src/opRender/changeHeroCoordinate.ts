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

  // confirm the x,y is not occupied by other now.
  if (
    playerData.heroes
      .map((h) => {
        const heroValue = getComponentValueStrict(Hero, h as Entity);
        return encodeXY(heroValue.x, heroValue.y);
      })
      .indexOf(encodeXY(x, y)) !== -1
  ) {
    throw Error("this coordination is occupied");
  }

  Hero.addOverride(id, {
    entity: playerData.heroes[index] as Entity,
    value: { x, y },
  });
  return id;
}

function encodeXY(x: number, y: number) {
  return (x << 8) + y;
}
