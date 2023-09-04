import { useMUD } from "@/MUDContext";
import { useCreatureMap } from "./useCreatureMap";
import { Entity, getComponentValueStrict } from "@latticexyz/recs";
import { useComponentValue } from "@latticexyz/react";
import { getHeroImg, getHeroTier } from "./useHero";
import { useEffect, useState } from "react";
import { numberToHex } from "viem";

export interface PieceInBattleAttr {
  enemy: boolean;
  image: string;
  tier: number;
  maxHealth: number;
  x: number;
  y: number;
  health: number;
  attack: number;
  range: number;
  defense: number;
  speed: number;
  movement: number;
}

export function usePieceInBattle() {
  const {
    components: { Board, Piece, Creature },
    network: { playerEntity },
  } = useMUD();

  const creatureMap = useCreatureMap();

  const pieceInBattleList = useComponentValue(Board, playerEntity)?.pieces;

  const [pieceInBattleData, setPieceInBattleData] =
    useState<PieceInBattleAttr[]>();

  useEffect(() => {
    const data = pieceInBattleList?.map((p: string) => {
      const pieceData = getComponentValueStrict(Piece, p as Entity);
      const creature = creatureMap.get(pieceData.creatureId);
      const CreatureData = getComponentValueStrict(
        Creature,
        numberToHex(pieceData.creatureId, { size: 32 }) as Entity
      );

      return {
        enemy: false,
        image: getHeroImg(pieceData.creatureId),
        tier: getHeroTier(pieceData.creatureId),
        maxHealth: CreatureData.health,
        x: pieceData.x,
        y: pieceData.y,
        health: pieceData.health,
        attack: creature?.attack || 0,
        range: creature?.range || 0,
        defense: creature?.defense || 0,
        speed: creature?.speed || 0,
        movement: creature?.movement || 0,
      };
    });
    setPieceInBattleData(data);
  }, [Creature, pieceInBattleList, Piece, creatureMap]);

  return { pieceInBattleData };
}

export function useEnemyPieceInBattle() {
  const {
    components: { Board, Piece, Creature },
    network: { playerEntity },
  } = useMUD();

  const creatureMap = useCreatureMap();

  const enemyPieceInBattleList = useComponentValue(
    Board,
    playerEntity
  )?.enemyPieces;

  const [enemyPieceInBattleData, setEnemyPieceInBattleData] =
    useState<PieceInBattleAttr[]>();

  useEffect(() => {
    const data = enemyPieceInBattleList?.map((p: string) => {
      const pieceData = getComponentValueStrict(Piece, p as Entity);
      const creature = creatureMap.get(pieceData.creatureId);
      const CreatureData = getComponentValueStrict(
        Creature,
        numberToHex(pieceData.creatureId, { size: 32 }) as Entity
      );

      return {
        enemy: true,
        image: getHeroImg(pieceData.creatureId),
        tier: getHeroTier(pieceData.creatureId),
        maxHealth: CreatureData.health,
        x: pieceData.x,
        y: pieceData.y,
        health: pieceData.health,
        attack: creature?.attack || 0,
        range: creature?.range || 0,
        defense: creature?.defense || 0,
        speed: creature?.speed || 0,
        movement: creature?.movement || 0,
      };
    });

    setEnemyPieceInBattleData(data);
  }, [Creature, enemyPieceInBattleList, Piece, creatureMap]);

  return { enemyPieceInBattleData };
}
