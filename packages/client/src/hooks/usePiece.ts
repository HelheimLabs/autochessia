import { numberToHex } from "viem";
import { getHeroImg, getHeroTier } from "./useHero";
import { useEffect, useState } from "react";
import { useCreatureMap } from "./useCreatureMap";
import { useMUD } from "@/MUDContext";
import { Entity, getComponentValueStrict } from "@latticexyz/recs";
import { useComponentValue } from "@latticexyz/react";

export interface PieceAttr {
  enemy: boolean;
  image: string;
  tier: number;
  maxHealth: number;
  x: number;
  y: number;
  attack: number;
  range: number;
  defense: number;
  speed: number;
  movement: number;
}

export function usePiece() {
  const {
    components: { Player, Hero, Creature },
    network: { playerEntity },
  } = useMUD();

  const creatureMap = useCreatureMap();

  const pieceList = useComponentValue(Player, playerEntity)?.heroes;

  const [pieceListData, setPieceListData] = useState<PieceAttr[]>();

  useEffect(() => {
    const data = pieceList?.map((p: string) => {
      const heroData = getComponentValueStrict(Hero, p as Entity);
      const creature = creatureMap.get(heroData.creatureId);
      const CreatureData = getComponentValueStrict(
        Creature,
        numberToHex(heroData.creatureId, { size: 32 }) as Entity
      );

      return {
        enemy: false,
        image: getHeroImg(heroData.creatureId),
        tier: getHeroTier(heroData.creatureId),
        maxHealth: CreatureData.health,
        x: heroData.x,
        y: heroData.y,
        attack: creature?.attack || 0,
        range: creature?.range || 0,
        defense: creature?.defense || 0,
        speed: creature?.speed || 0,
        movement: creature?.movement || 0,
      };
    });
    setPieceListData(data);
  }, [Creature, pieceList, Hero, creatureMap]);

  return { pieceListData };
}
