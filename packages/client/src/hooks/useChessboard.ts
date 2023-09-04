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

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValueStrict(Game, currentGameId!);

  const creatureMap = useCreatureMap();

  const HeroTable = useEntityQuery([Has(Hero)]).map((row) => ({
    ...getComponentValueStrict(Hero, row),
    key: row,
  }));

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
