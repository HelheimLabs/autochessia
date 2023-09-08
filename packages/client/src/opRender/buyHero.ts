import {
  ComponentValue,
  Entity,
  getComponentValueStrict,
} from "@latticexyz/recs";
import { ClientComponents } from "../mud/createClientComponents";
import { SetupNetworkResult } from "../mud/setupNetwork";
import { uuid } from "@latticexyz/utils";
import { decodeHero, encodeHero } from "@/lib/utils";
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
    creature: bigint
  ) {
    // run merge twice, as it merger at most twice
    // first
    let mergeResult = mergeHero(playerData, creature);
    playerData = mergeResult.playerData;
    creature = mergeResult.newCreature;

    // second
    mergeResult = mergeHero(playerData, creature);
    playerData = mergeResult.playerData;
    creature = mergeResult.newCreature;

    // find first empty slot in inventory
    const emptyIndex = playerData.inventory.findIndex((e) => Number(e) === 0);
    // if no empty slot in inventory, throw error
    if (emptyIndex === -1) {
      throw new Error("inventory full");
    }

    // update object
    playerData.inventory = playerData.inventory.map((v, i) => {
      if (i === emptyIndex) {
        return Number(creature);
      }
      return v;
    });

    return playerData;
  }

  function mergeHero(
    playerData: ComponentValue<typeof Player.schema>,
    newCreature: bigint
  ): {
    playerData: ComponentValue<typeof Player.schema>;
    newCreature: bigint;
    merged: boolean;
  } {
    let merged = false;
    const { tier, heroId, creatureId } = decodeHero(newCreature);

    const toMergedOnBoard: number[] = [];
    const toMergedOnInventory: number[] = [];
    // search board
    playerData.heroes.forEach((h: string, idx: number) => {
      const d = getComponentValueStrict(Hero, h as Entity);
      const { tier: t, creatureId: c } = decodeHero(BigInt(d.creatureId));
      if (creatureId === c && tier === t) {
        toMergedOnBoard.push(idx);
      }
    });

    // search inventory
    playerData.inventory.forEach((v, inventoryIndex) => {
      const { tier: t, internalIndex: heroIndex } = decodeHero(BigInt(v));
      if (creatureId === heroIndex && t === tier) {
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
      newCreature = encodeHero(tier + 1n, heroId);
      merged = true;
    }

    return { playerData, newCreature, merged };
  }

  let playerData = getComponentValueStrict(Player, playerEntity);
  const creatureData = playerData.heroAltar[index];

  if (creatureData === 0) {
    throw new Error("null hero in altar");
  }
  // remove from hero altar
  playerData.heroAltar = playerData.heroAltar.map((v, i) => {
    if (i === index) {
      return 0;
    }
    return v;
  });

  // price equal tier
  const { tier } = decodeHero(BigInt(creatureData));
  const price = Number(tier);
  // charge coin
  if (playerData.coin < price) {
    throw new Error("coin is not enough");
  }
  playerData.coin = playerData.coin - price;

  // recruit hero
  playerData = recruitHero(playerData, BigInt(creatureData));

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
