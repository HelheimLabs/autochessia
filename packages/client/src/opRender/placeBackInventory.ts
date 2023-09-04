import { ClientComponents } from "@/mud/createClientComponents";
import { SetupNetworkResult } from "@/mud/setupNetwork";
import { Entity, getComponentValueStrict } from "@latticexyz/recs";
import { addElementToArray, popArrayByIndex } from "./utils";
import { uuid } from "@latticexyz/utils";

export function opRunPlaceBackInventory(
  { playerEntity }: SetupNetworkResult,
  { Player, Hero }: ClientComponents,
  herosIndex: number,
  invIdx: number
): string {
  const playerData = getComponentValueStrict(Player, playerEntity);
  const heroData = getComponentValueStrict(
    Hero,
    playerData.heroes[herosIndex] as Entity
  ).creatureId;

  // remove hero
  playerData.heroes = popArrayByIndex(playerData.heroes, herosIndex);

  if (playerData.inventory.indexOf(0) === -1) {
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
