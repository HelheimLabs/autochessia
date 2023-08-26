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

export interface srcObjType {
  ava: string;
  color: string;
  mono: string;
  void: string;
  perUrl: string;
}

export interface HeroBaseAttr {
  cost: number;
  lv: number;
  url: string;
  creature: number;
  image: string;
}

const srcObj = {
  ava: "/avatar.gif",
  color: "/colorful.png",
  mono: "/monochrome.png",
  void: "/void.png",
  perUrl: "https://autochessia.4everland.store/creatures/",
};

const initEntity: Entity =
  "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

const useChessboard = () => {
  const {
    components: {
      Board,
      Player,
      PlayerGlobal,
      ShopConfig,
      GameConfig,
      Hero,
      Piece,
      Creature,
      Game,
    },
    systemCalls: { autoBattle, placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const _ShopConfig = useComponentValue(ShopConfig, initEntity);

  const _GameConfig = useComponentValue(GameConfig, initEntity);

  const PieceInBattleList = useEntityQuery([Has(Piece)]).map((row) => ({
    ...getComponentValueStrict(Piece, row),
    key: row,
  }));

  const _Creature = useEntityQuery([Has(Creature)]).map((row) => ({
    ...getComponentValueStrict(Creature, row),
    key: row,
  }));

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValueStrict(Game, currentGameId!);

  const tierPrice = _ShopConfig?.tierPrice;

  const creatureMap = useMemo(() => {
    return new Map(
      _Creature.map(
        (c: {
          key: any;
          health?: any;
          attack?: any;
          range?: any;
          defense?: any;
          speed?: any;
          movement?: any;
        }) => [Number(c.key), c]
      )
    );
  }, [_Creature]);

  const getHeroImg = (HeroId: number) => {
    const id = HeroId & 0xff;
    return srcObj.perUrl + id + srcObj.color;
  };

  const getHeroTier = (hero: any) => {
    const tier = (hero >> 8) + 1;
    return tier;
  };

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
      let battlePieces: any[] = [];

      PieceInBattleList.forEach((piece) => {
        const isOwner = BoardList?.pieces.includes(piece.key);
        const isEnemy = BoardList?.enemyPieces.includes(piece.key);

        if (isOwner || isEnemy) {
          const creature = creatureMap.get(piece.creatureId);

          battlePieces.push({
            enemy: isEnemy,
            image: getHeroImg(piece.creatureId),
            tier: getHeroTier(piece.creatureId),
            ...piece,
            ...creature,
            maxHealth: creature?.health,
          });
        }
      });

      return battlePieces;
    }
    return [];
  }, [BoardList, PieceInBattleList]);

  const { heroAltar, inventory } = playerObj!;

  const heroList = useMemo(() => {
    return (tierPrice && decodeHeroFn(heroAltar)) ?? [];
  }, [tierPrice, heroAltar]);

  const inventoryList = useMemo(() => {
    return decodeHeroFn(inventory);
  }, [inventory, creatureMap]);

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
    srcObj,
    heroList,
    inventoryList,
    currentGame,
    currentRoundStartTime: currentGame?.startFrom,
    startFrom: currentGame?.startFrom,
    currentGameStatus: currentGame?.status,
    playerListData,
    localAccount,
    playerObj,
    roundInterval: _GameConfig?.roundInterval,
    expUpgrade: _GameConfig?.expUpgrade,
  };
};

export default useChessboard;
