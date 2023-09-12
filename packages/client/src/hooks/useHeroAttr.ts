import { decodeHero } from "@/lib/utils";
import { HeroBaseAttr } from "./useChessboard";
import { useEffect, useState } from "react";
import { numberToHex } from "viem";
import { encodeEntity } from "@latticexyz/store-sync/recs";
import { getComponentValue } from "@latticexyz/recs";
import { useMUD } from "@/MUDContext";

export interface srcObjType {
  ava: string;
  color: string;
  mono: string;
  void: string;
  perUrl: string;
}

export enum HeroRace {
  UNKNOWN = 0,
  TROLL = 1,
  PANDAREN = 2,
  ORC = 3,
  HUMAN = 4,
  GOD = 5,
}

export enum HeroClass {
  UNKNOWN = 0,
  KNIGHT = 1,
  WARLOCK = 2,
  ASSASSIN = 3,
  WARRIOR = 4,
  MAGE = 5,
}

export const srcObj = {
  perUrl: "https://autochessia.4everland.store/autochess-v0.0.2/hero/",
};

export function useHeroesAttr(arr: bigint[]): HeroBaseAttr[] {
  const {
    components: { Creature },
  } = useMUD();
  const [attrs, setAttrs] = useState<HeroBaseAttr[]>([]);

  useEffect(() => {
    setAttrs(
      arr
        ?.map((item: bigint) => decodeHero(item))
        ?.map((item) => {
          const entity = encodeEntity(
            { id: "bytes32" },
            { id: numberToHex(item.creatureId, { size: 32 }) }
          );
          const creature = getComponentValue(Creature, entity);

          if (creature) {
            return {
              ...item,
              cost: item.rarity,
              lv: item.tier,
              url: srcObj.perUrl + item.heroIdString + ".png",
              image: srcObj.perUrl + item.heroIdString + ".png",
              creature: item.creatureId,
              oriHero: item.creatureId,
              ...creature,
              maxHealth: creature?.health,
            };
          }
          return {};
        }) as HeroBaseAttr[]
    );
  }, [arr, Creature]);

  return attrs;
}
