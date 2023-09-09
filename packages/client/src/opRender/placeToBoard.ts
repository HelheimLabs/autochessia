import { ClientComponents } from "@/mud/createClientComponents";
import { SetupNetworkResult } from "@/mud/setupNetwork";
import { getComponentValueStrict } from "@latticexyz/recs";
import { encodeXY } from "./changeHeroCoordinate";
import { Hex, hexToNumber, numberToHex } from "viem";
import { uuid } from "@latticexyz/utils";
import { encodeEntity } from "@latticexyz/store-sync/recs";
import { pushToArray, removeElementByIndex } from "./utils";
import { encodeHeroEntity } from "@/lib/utils";

export function opRunPlaceToBoard(
  { playerEntity }: SetupNetworkResult,
  { Player, Hero }: ClientComponents,
  heroIndex: number,
  x: number,
  y: number
): { heroOverrideId: string; playerOverrideId: string } {
  const playerData = getComponentValueStrict(Player, playerEntity);
  // ensure this place is not occupied
  if (
    playerData.heroes
      .map((h) => {
        const heroValue = getComponentValueStrict(
          Hero,
          encodeHeroEntity(BigInt(h))
        );
        return encodeXY(heroValue.x, heroValue.y);
      })
      .indexOf(encodeXY(x, y)) !== -1
  ) {
    throw Error("this coordination is occupied");
  }

  // calculate hero entity
  const heroEntity = encodeEntity(
    { id: "bytes32" },
    {
      id: numberToHex(
        (hexToNumber(playerEntity as Hex) << 32) + playerData.heroOrderIdx + 1,
        { size: 32 }
      ),
    }
  );

  // get hero creatureId
  const creatureId = playerData.inventory[heroIndex];

  // pop hero from inventory
  playerData.inventory = removeElementByIndex(playerData.inventory, heroIndex);
  // add to heroes array
  playerData.heroes = pushToArray(playerData.heroes, heroEntity.toString());

  // override hero
  const heroOverrideId = uuid();

  Hero.addOverride(heroOverrideId, {
    entity: heroEntity,
    value: {
      creatureId: creatureId,
      x: x,
      y: y,
    },
  });

  // override player
  const playerOverrideId = uuid();
  Player.addOverride(playerOverrideId, {
    entity: playerEntity,
    value: {
      inventory: playerData.inventory,
      heroes: playerData.heroes,
      heroOrderIdx: playerData.heroOrderIdx + 1,
    },
  });

  return { heroOverrideId, playerOverrideId };
}
