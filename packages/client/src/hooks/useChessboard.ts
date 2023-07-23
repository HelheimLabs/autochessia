import { useEffect, useState } from 'react';
import { useComponentValue, useRows, useRow } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { decodeHero } from '../lib/ulits';

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
  ava: string
  color: string
  mono: string
  void: string
  perUrl: string
}


const srcObj = {
  ava: '/avatar.gif',
  color: '/colorful.png',
  mono: '/monochrome.png',
  void: '/void.png',
  perUrl: 'https://autochessia.4everland.store/creatures/'
}

const useChessboard = () => {


  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: { placeToBoard, changeHeroCoordinate },
    network: { localAccount, playerEntity, storeCache, },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const [PiecesList, setPiecesList] = useState<boardInterface[]>()
  const [BattlePieceList, setBattlePieceList] = useState<boardInterface[]>()


  const ShopConfig = useRow(storeCache, { table: "ShopConfig", key: { index: 0 } });

  const PieceListori = useRows(storeCache, { table: "Hero" })
  const PieceInBattleList = useRows(storeCache, { table: "Piece" })

  const Creature = useRows(storeCache, { table: "Creature" })

  const tierPrice = ShopConfig?.value?.tierPrice


  const decodeHeroFn = (arr: any[]) => {
    const decodeArr = arr?.map((item: any) => decodeHero(item))
    return decodeArr?.map((item: any[]) => ({
      cost: tierPrice?.[item?.[1]],
      lv: item?.[1] + 1,
      url: srcObj.perUrl + item?.[0] + srcObj.ava,
      creature: item?.[0]
    }))
  }


  const creatureMap = new Map(Creature.map(c => [Number(c.key.index), c.value]));



  const generateBattlePieces = (boardList: { pieces: string | any[]; enemyPieces: string | any[]; }, pieces: any[]) => {

    const battlePieces: any[] = [];

    if (boardList) {
      pieces.forEach((piece: {
        [x: string]: any; key: any;
      }) => {
        const isOwner = boardList.pieces.includes(piece.key.key);
        const isEnemy = boardList.enemyPieces.includes(piece.key.key);

        if (isOwner || isEnemy) {
          battlePieces.push({
            enemy: isEnemy,
            ...piece.value
          });
        }
      });
    }


    setBattlePieceList(battlePieces);
  }
  const mergePieceData = (heroId: string) => {
    const piece = PieceListori.find(p => p.key.key === heroId);
    
    if (piece) {
      const creature = creatureMap.get(piece.value.creatureId);
      return { ...piece.value, ...creature };
    }
  }

  const setupChessboard = () => {

    if (playerObj?.heroes.length) {

      for (let heroId of playerObj.heroes) {
        const piece = mergePieceData(heroId);
        if (piece) setPiecesList([piece])
      }
    } else {
      setPiecesList([])
    }

  }

  useEffect(() => {
    setupChessboard()
    generateBattlePieces(BoardList!, PieceInBattleList);
  }, [PieceInBattleList, BoardList, PieceListori])

  const { heroAltar, inventory } = playerObj!


  return {
    placeToBoard,
    changeHeroCoordinate,
    PiecesList,
    BattlePieceList,
    srcObj,
    heroList: decodeHeroFn(heroAltar),
    inventoryList: decodeHeroFn(inventory)
  };
}

export default useChessboard;