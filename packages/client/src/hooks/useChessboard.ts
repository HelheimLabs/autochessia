import { useCallback, useEffect, useMemo, useState } from "react";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Entity, getComponentValueStrict, Has, Not } from "@latticexyz/recs";
import { useMUD } from "../MUDContext";
import {
  decodeHero,
  generateAvatar,
  shortenAddress,
  padAddress,
} from "../lib/ulits";
import { useSystemConfig } from "./useSystemConfig";
import { useCreatureMap } from "./useCreatureMap";
import { srcObj } from "./useHeroAttr";

export interface boardInterface {
  attack?: number;
  creatureId?: number;
  defense?: number;
  health?: number;
  maxHealth?: number;
  movement?: number;
  range?: number;
  speed?: number;
  tier: number;
  x: number;
  y: number;
  owner?: boolean;
}

export interface HeroBaseAttr {
  cost: number;
  lv: number;
  url: string;
  creature: number;
  image: string;
}

const useChessboard = () => {
  const {
    components: { Board, Player, PlayerGlobal, Hero, Piece, Game },
    systemCalls: { placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const { gameConfig, shopConfig } = useSystemConfig();

  const PieceInBattleList = useEntityQuery([Has(Piece)]).map((row) => ({
    ...getComponentValueStrict(Piece, row),
    key: row,
  }));

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValueStrict(Game, currentGameId!);

  const tierPrice = shopConfig?.tierPrice;

  const getHeroImg = (HeroId: number) => {
    const id = HeroId & 0xff;
    return srcObj.perUrl + id + srcObj.color;
  };

  const getHeroTier = (hero: any) => {
    const tier = (hero >> 8) + 1;
    return tier;
  };

  const creatureMap = useCreatureMap();

  const decodeHeroFn = (arr: any[]) => {
    const decodeArr = arr?.map((item: any) => decodeHero(item));

    return decodeArr?.map((item: any[]) => {
      const creature = creatureMap.get(item?.[2]);

      if (creature) {
        return {
          cost: tierPrice?.[item?.[0] - 1],
          lv: item?.[0],
          url: item?.[0] > 0 ? srcObj.perUrl + item?.[1] + srcObj.ava : "",
          image: item?.[0] > 0 ? srcObj.perUrl + item?.[1] + srcObj.color : "",
          creature: item?.[0],
          oriHero: item?.[2],
          ...creature,
          maxHealth: creature?.health,
        };
      }
      return {};
    }) as HeroBaseAttr[];
  };

  const BattlePieceList = useMemo(() => {
    if (PieceInBattleList.length > 0) {
      const battlePieces: any[] = [];

      PieceInBattleList.forEach((piece) => {
        const isOwner = BoardList?.pieces.includes(piece.key);
        const isEnemy = BoardList?.enemyPieces.includes(piece.key);

        if (isOwner || isEnemy) {
          const creature = creatureMap.get(piece.creatureId);

          battlePieces.push({
            enemy: isEnemy,
            image: getHeroImg(piece.creatureId),
            tier: getHeroTier(piece.creatureId),
            ...creature,
            ...piece,
            maxHealth: creature?.health,
          });
        }
      });

      return battlePieces;
    }
    return [];
  }, [BoardList, PieceInBattleList]);

  const inventory = playerObj?.inventory;

  // disable use memo for op render
  const heroList = useMemo(() => {
    return (tierPrice && decodeHeroFn(playerObj?.heroAltar || [])) ?? [];
  }, [tierPrice, playerObj?.heroAltar, decodeHeroFn]);

  const inventoryList = useMemo(() => {
    return decodeHeroFn(inventory || []);
  }, [inventory, decodeHeroFn]);

  const HeroTable = useEntityQuery([Has(Hero)]).map((row) => ({
    ...getComponentValueStrict(Hero, row),
    key: row,
  }));

  const PiecesList = useMemo(() => {
    return playerObj?.heroes.map((row, _index: any) => {
      const hero = getComponentValueStrict(Hero, row as Entity);
      const creature = creatureMap.get(hero.creatureId);
      return {
        ...hero,
        ...creature,
        key: row,
        _index,
        tier: getHeroTier(hero.creatureId),
        image: getHeroImg(hero.creatureId),
        maxHealth: creature?.health,
      };
    });
  }, [playerObj?.heroes, HeroTable]);

  const playerListData = currentGame?.players?.map((_player: string) => {
    const item = getComponentValueStrict(Player, padAddress(_player) as Entity);
    return {
      ...item,
      addr: _player,
      id: _player,
      name: shortenAddress(_player),
      avatar: generateAvatar(_player),
      level: item.tier + 1 || 1,
      hp: item.health,
      maxHp: 30,
      coin: item.coin,
    };
  });

  return {
    placeToBoard,
    changeHeroCoordinate,
    PiecesList,
    BattlePieceList,
    BoardList,
    currentBoardStatus: BoardList?.status,
    currentGame,
    currentRoundStartTime: currentGame?.startFrom,
    startFrom: currentGame?.startFrom,
    currentGameStatus: currentGame?.status,
    playerListData,
    localAccount,
    playerObj,
    roundInterval: gameConfig?.roundInterval,
    expUpgrade: gameConfig?.expUpgrade,
  };
};

export default useChessboard;
