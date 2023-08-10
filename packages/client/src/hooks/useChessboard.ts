import { useEffect, useMemo, useState } from "react";
import { useComponentValue, useRows, useRow } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { decodeHero, generateAvatar, shortenAddress } from "../lib/ulits";

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

const useChessboard = () => {
  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: { autoBattle, placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity, storeCache, getCurrentBlockNumber },
  } = useMUD();

  const _playerList = useRows(storeCache, { table: "Player" });

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const [PiecesList, setPiecesList] = useState<boardInterface[]>();
  const [BattlePieceList, setBattlePieceList] = useState<boardInterface[]>();

  const ShopConfig = useRow(storeCache, {
    table: "ShopConfig",
    key: { index: 0 },
  });
  const GameConfig = useRow(storeCache, {
    table: "GameConfig",
    key: { index: 0 },
  });

  const PieceListori = useRows(storeCache, { table: "Hero" });
  const PieceInBattleList = useRows(storeCache, { table: "Piece" });

  const Creature = useRows(storeCache, { table: "Creature" });
  const CreatureConfig = useRow(storeCache, {
    table: "CreatureConfig",
    key: { index: 0 },
  });

  // console.log(CreatureConfig)

  const currentGame = useRow(storeCache, {
    table: "Game",
    key: { index: _playerlayerGlobal?.gameId as number },
  });

  const tierPrice = ShopConfig?.value?.tierPrice;

  const decodeHeroFn = (arr: any[]) => {
    const decodeArr = arr?.map((item: any) => decodeHero(item));
    return decodeArr?.map((item: any[]) => {
      return {
        cost: tierPrice?.[item?.[1]],
        lv: item?.[1] + 1,
        url: item?.[0] > 0 ? srcObj.perUrl + item?.[0] + srcObj.ava : "",
        image: item?.[0] > 0 ? srcObj.perUrl + item?.[0] + srcObj.color : "",
        creature: item?.[0],
        oriHero: item?.[2],
      };
    }) as HeroBaseAttr[];
  };

  const creatureMap = new Map(
    Creature.map((c) => [Number(c.key.index), c.value])
  );

  const generateBattlePieces = (
    boardList: { pieces: string | any[]; enemyPieces: string | any[] },
    pieces: any[]
  ) => {
    const battlePieces: any[] = [];

    if (boardList) {
      pieces.forEach((piece: { [x: string]: any; key: any }) => {
        const isOwner = boardList.pieces.includes(piece.key.key);
        const isEnemy = boardList.enemyPieces.includes(piece.key.key);

        // console.log(piece.value, CreatureConfig);

        if (isOwner || isEnemy) {
          battlePieces.push({
            enemy: isEnemy,
            image: srcObj.perUrl + piece.value.creatureId + srcObj.color,
            maxHealth:
              piece.value.tier > 0
                ? piece.value.health +
                  CreatureConfig?.value.healthAmplifier[piece.value.tier - 1]
                : piece.value.health,
            ...piece.value,
          });
        }
      });
    }

    setBattlePieceList(battlePieces);
  };
  const mergePieceData = (heroId: string) => {
    const piece = PieceListori.find((p) => p.key.key === heroId);
    if (piece) {
      const creature = creatureMap.get(piece.value.creatureId);

      return {
        ...piece.value,
        ...creature,
        image: srcObj.perUrl + piece.value.creatureId + srcObj.color,
        maxHealth:
          piece.value.tier > 0
            ? creature.health +
              CreatureConfig?.value.healthAmplifier[piece.value.tier - 1]
            : creature.health,
      };
    }
  };

  const setupChessboard = () => {
    if (playerObj?.heroes.length) {
      const pieceArr = [];
      let index = 0;
      for (const heroId of playerObj.heroes) {
        const piece = mergePieceData(heroId);
        if (piece) {
          pieceArr.push({
            ...piece,
            _index: index++,
          });
        }
      }
      setPiecesList(pieceArr);
    } else {
      setPiecesList([]);
    }
  };

  const playerListData = useMemo(() => {
    const players = currentGame?.value.players;
    if (players) {
      let playersList: any[] = [];
      players.map((player) => {
        const item = _playerList.find(
          (_player) => _player.key.addr.toLocaleLowerCase() == player
        );
        if (item) {
          playersList.push({
            id: item.key.addr,
            name: shortenAddress(item.key.addr),
            avatar: generateAvatar(item.key.addr),
            level: item.value.tier + 1,
            hp: item.value.health,
            maxHp: 30,
            coin: item.value.coin,
          });
        }
      });
      return playersList;
    }
  }, [_playerList, currentGame?.value.players]);

  useEffect(() => {
    setupChessboard();
    generateBattlePieces(BoardList!, PieceInBattleList);
  }, [PieceInBattleList, BoardList, PieceListori, CreatureConfig]);

  const { heroAltar, inventory } = playerObj!;

  const autoBattleFn = async () => {
    await autoBattle(_playerlayerGlobal!.gameId, localAccount);
  };

  // console.log({currentGame})

  return {
    placeToBoard,
    changeHeroCoordinate,
    PiecesList,
    BattlePieceList,
    BoardList,
    currentBoardStatus: BoardList?.status,
    srcObj,
    heroList: (tierPrice && decodeHeroFn(heroAltar)) ?? [],
    inventoryList: decodeHeroFn(inventory),
    currentGame,
    startFrom: currentGame?.value.startFrom,
    currentGameStatus: currentGame?.value.status,
    playerListData,
    localAccount,
    playerObj,
    getCurrentBlockNumber,
    roundInterval: GameConfig?.value.roundInterval,
    expUpgrade: GameConfig?.value.expUpgrade,
    autoBattleFn,
  };
};

export default useChessboard;
