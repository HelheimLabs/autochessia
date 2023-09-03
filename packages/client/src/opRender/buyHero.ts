import {
  ComponentValue,
  Entity,
  getComponentValueStrict,
} from "@latticexyz/recs";
import { ClientComponents } from "../mud/createClientComponents";
import { SetupNetworkResult } from "../mud/setupNetwork";
import { uuid } from "@latticexyz/utils";
import { decodeHero, encodeHero } from "@/lib/ulits";
import { popArrayByIndexes } from "./utils";

/// @note should run override at last step
export function opRunBuyHero(
  { playerEntity }: SetupNetworkResult,
  { Player, Hero }: ClientComponents,
  index: number
): string {
  // function
  function recruitHero(
    playerData: ComponentValue<typeof Player.schema>,
    hero: number
  ) {
    // run merge twice, as it merger at most twice
    // first
    let mergeResult = mergeHero(playerData, hero);
    playerData = mergeResult.playerData;
    hero = mergeResult.newHero;

    // second
    mergeResult = mergeHero(playerData, hero);
    playerData = mergeResult.playerData;
    hero = mergeResult.newHero;

    // find first empty slot in inventory
    const emptyIndex = playerData.inventory.findIndex((e) => e === 0);
    // if no empty slot in inventory, throw error
    if (emptyIndex === -1) {
      throw new Error("inventory full");
    }

    // update object
    playerData.inventory = playerData.inventory.map((v, i) => {
      if (i === emptyIndex) {
        return hero;
      }
      return v;
    });

    return playerData;
  }

  function mergeHero(
    playerData: ComponentValue<typeof Player.schema>,
    newHero: number
  ): {
    playerData: ComponentValue<typeof Player.schema>;
    newHero: number;
    merged: boolean;
  } {
    let merged = false;
    const [tier, creatureIndex] = decodeHero(newHero);

    const toMergedOnBoard: number[] = [];
    const toMergedOnInventory: number[] = [];
    // search board
    playerData.heroes.forEach((h: string, idx: number) => {
      const d = getComponentValueStrict(Hero, h as Entity);
      const [t, c] = decodeHero(d.creatureId);
      if (creatureIndex === c && tier === t) {
        toMergedOnBoard.push(idx);
      }
    });

    // search inventory
    playerData.inventory.forEach((v, inventoryIndex) => {
      const [t, heroIndex] = decodeHero(v);
      if (creatureIndex === heroIndex && t === tier) {
        toMergedOnInventory.push(inventoryIndex);
      }
    });

    // tier 1 and tier 2 can be merged
    if (
      tier <= 2 &&
      toMergedOnBoard.length + toMergedOnInventory.length === 2
    ) {
      // remove from user board
      playerData.heroes = popArrayByIndexes(playerData.heroes, toMergedOnBoard);

      // remove from inventory
      toMergedOnInventory.forEach((i) => {
        playerData.inventory[i] = 0;
      });

      // set hero to upgraded one
      newHero = encodeHero(tier + 1, creatureIndex);
      merged = true;
    }

    console.log("playerData: ", playerData, "merged: ", merged);

    return { playerData, newHero, merged };
  }

  let playerData = getComponentValueStrict(Player, playerEntity);
  const heroData = playerData.heroAltar[index];

  if (heroData === 0) {
    throw new Error("null hero in altar");
  }
  // remove from hero altar
  playerData.heroAltar = playerData.heroAltar.map((v, i) => {
    if (i === index) {
      return 0;
    }
    return v;
  });
  // charge coin
  if (playerData.coin < 1) {
    throw new Error("coin is not enough");
  }
  playerData.coin = playerData.coin - 1;

  // recruit hero
  playerData = recruitHero(playerData, heroData);

  console.log("data before override:", playerData);

  // do every check before first override
  const buyId = uuid();
  Player.addOverride(buyId, {
    entity: playerEntity,
    value: {
      coin: playerData.coin,
      inventory: playerData.inventory,
      heroAltar: playerData.heroAltar,
    },
  });

  return buyId;
}
