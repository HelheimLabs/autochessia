import { ClientComponents } from "@/mud/createClientComponents";
import { SetupNetworkResult } from "@/mud/setupNetwork";
import { getComponentValueStrict } from "@latticexyz/recs";
import { addElementToArray, popArrayByIndex } from "./utils";
import { uuid } from "@latticexyz/utils";
import { encodeHeroEntity } from "@/lib/utils";

export function opRunPlaceBackInventory(
  { playerEntity }: SetupNetworkResult,
  { Player, Hero }: ClientComponents,
  herosIndex: number,
  invIdx: number
): string {
  const playerData = getComponentValueStrict(Player, playerEntity);
  const heroData = getComponentValueStrict(
    Hero,
    encodeHeroEntity(BigInt(playerData.heroes[herosIndex]))
  ).creatureId;

  // remove hero
  playerData.heroes = popArrayByIndex(playerData.heroes, herosIndex);

  if (playerData.inventory.indexOf(0n) === -1) {
    throw Error("Inventory full");
  }

  // add to inventory
  playerData.inventory = addElementToArray(
    playerData.inventory,
    heroData,
    invIdx
  );

  const id = uuid();
  Player.addOverride(id, {
    entity: playerEntity,
    value: {
      heroes: playerData.heroes,
      inventory: playerData.inventory,
    },
  });

  return id;
}
