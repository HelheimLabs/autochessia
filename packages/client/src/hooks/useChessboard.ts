import { useMemo } from "react";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import {
  Entity,
  getComponentValue,
  getComponentValueStrict,
  Has,
} from "@latticexyz/recs";
import { useMUD } from "../MUDContext";
import {
  generateAvatar,
  shortenAddress,
  padAddress,
  encodeCreatureEntity,
  decodeHero,
} from "../lib/utils";
import { useSystemConfig } from "./useSystemConfig";
import { HeroClass, HeroRace, srcObj } from "./useHeroAttr";
import { encodeEntity } from "@latticexyz/store-sync/recs";
import { numberToHex } from "viem";

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
  [x: string]: number | string;
  race: HeroRace;
  class: HeroClass;
  attack: number;
  cost: number;
  creature: number;
  defense: number;
  health: number;
  image: string;
  key: string;
  tier: number;
  lv: number;
  maxHealth: number;
  movement: number;
  oriHero: number;
  range: number;
  speed: number;
  url: string;
}

const useChessboard = () => {
  const {
    components: { Board, Player, PlayerGlobal, Hero, Piece, Game, Creature },
    systemCalls: { placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const { gameConfig, shopConfig } = useSystemConfig();

  const PieceInBattleList = useEntityQuery([Has(Piece)]).map((row) => ({
    ...getComponentValue(Piece, row),
    key: row,
  }));

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValue(Game, currentGameId!);

  const getHeroImg = (heroId: number) => {
    const { heroIdString } = decodeHero(heroId);
    return srcObj.perUrl + heroIdString + ".png";
  };

  const creatureMap = new Map(
    useEntityQuery([Has(Creature)])
      ?.map((row) => ({
        ...getComponentValueStrict(Creature, row),
        key: row,
      }))
      .map((c) => [Number(c.key), c])
  );

  const BattlePieceList = useMemo(() => {
    if (PieceInBattleList.length > 0) {
      const battlePieces: any[] = [];

      PieceInBattleList.forEach((piece) => {
        const isOwner = BoardList?.pieces.includes(piece.key);
        const isEnemy = BoardList?.enemyPieces.includes(piece.key);

        if (isOwner || isEnemy) {
          const creature = creatureMap.get(Number(piece.creatureId));

          if (!creature) {
            return;
          }

          const decodeHeroData = decodeHero(
            piece.creatureId as unknown as bigint
          );

          battlePieces.push({
            enemy: isEnemy,
            image: getHeroImg(piece.creatureId),
            ...decodeHeroData,
            ...creature,
            ...piece,
            maxHealth: creature?.health,
          });
        }
      });

      return battlePieces;
    }
    return [];
  }, [BoardList, PieceInBattleList, creatureMap]);

  const PiecesList = playerObj?.heroes.map((row, _index: any) => {
    const hero = getComponentValue(
      Hero,
      encodeEntity({ id: "bytes32" }, { id: numberToHex(row, { size: 32 }) })
    );

    if (!hero) {
      return undefined;
    }

    const creature = getComponentValue(
      Creature,
      encodeCreatureEntity(hero.creatureId)
    );

    const decodeHeroData = decodeHero(hero.creatureId);

    return {
      ...hero,
      ...creature,
      key: row,
      _index,
      ...decodeHeroData,
      image: getHeroImg(hero.creatureId),
      maxHealth: creature?.health,
    };
  });

  const playerListData = currentGame?.players?.map((_player: string) => {
    const item = getComponentValue(Player, padAddress(_player) as Entity);
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
    isSinglePlay: currentGame?.single,
    playerListData,
    localAccount,
    playerObj,
    roundInterval: gameConfig?.roundInterval,
    expUpgrade: gameConfig?.expUpgrade,
  };
};

export default useChessboard;
