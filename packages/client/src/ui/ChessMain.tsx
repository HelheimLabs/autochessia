import React, { useState, useRef } from 'react';
import './Chessboard.css';
import Chessboard from './Chessboard';
import PieceImg from './Piece';
import { decodeHero } from '../lib/ulits';

import { useComponentValue, useRows, useEntityQuery } from "@latticexyz/react";
import { Has, HasValue, getComponentValueStrict } from "@latticexyz/recs";
import { useMUD } from "../MUDContext";
import { hexToArray } from "@latticexyz/utils";
import { DollarTwoTone } from '@ant-design/icons';
import { useDrop, useDrag } from 'ahooks';


import { Card, Statistic, Modal, Button } from 'antd';

const { Meta } = Card;

const srcList = [
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/48b4-imztzhn1606827.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/86ed-imztzhn1610595.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/99ee-imztzhn1610686.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/7eef-imztzhn1610766.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/87d0-imztzhn1610842.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/40b6-imztzhn1610905.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/8a32-imztzhn1610955.jpg',
  'https://n.sinaimg.cn/sinacn20122/488/w644h644/20200112/8a32-imztzhn1610955.jpg',
]

const initHero = () => {

  const heroes = []
  for (let i = 0; i < 5; i++) {
    const lv = Math.floor(Math.random() * 2) + 1;
    const cost = lv === 1 ? 1 : 3;
    const name = `Hero ${i + 1}`;
    const src = srcList[i];

    heroes.push({
      name,
      lv,
      cost,
      src
    })
  }

  return heroes;
}

interface GameProps {

}

interface boardInterface {
  creature: number;
  tier: number;
  x: number;
  y: number;
}


const Game = (props: GameProps) => {

  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, GameConfig },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory, checkCorValidity },
    network: { singletonEntity, localAccount, playerEntity, storeCache },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const bigIntFn = BigInt(BoardList!.enemy);

  const bigIntFnvalue = bigIntFn.toString(16).padStart(64, "0");


  const enemyBoardList = useRows(storeCache, { table: "Board" })


  console.log(BoardList, 'BoardList')
  console.log(enemyBoardList, 'enemyBoardList', bigIntFnvalue,)


  let enemy2row = []
  enemyBoardList?.forEach(item => {
    console.log(item.key.addr, BoardList!.enemy)
    if (item.key.addr.toLowerCase() == BoardList!.enemy) {
      enemy2row=(item.value)
    }
  })

  console.log(enemy2row, 'enemy2row')
  console.log(playerObj, 'obj')


  const CreaturesArr = useRows(storeCache, { table: "Creatures" });
  const ShopConfig = useRows(storeCache, { table: "ShopConfig" });
  const PieceListori = useRows(storeCache, { table: "Piece" })
  const PieceInBattleList = useRows(storeCache, { table: "PieceInBattle" })


  const PieceList: boardInterface[] = []

  const enemyList: boardInterface[] = []

  const enemyListLast: boardInterface[] = []

  const ememy2 = []
  // 
  BoardList!.pieces?.forEach(item => {
    PieceInBattleList.forEach(PieceInBattleItem => {
      if (PieceInBattleItem.key.key == item) {
        PieceListori.forEach(PieceListoriItem => {
          if (PieceListoriItem.key.key == item) {
            PieceList.push({
              ...PieceListoriItem.value,
              ...PieceInBattleItem.value
            })
          }
        })
      }
    })
  });

  // enemy2row!.enemyPieces?.forEach(item => {
  //   PieceInBattleList.forEach(PieceInBattleItem => {
  //     if (PieceInBattleItem.key.key == item) {
  //       console.log(item)
  //       enemyList.push({
  //         ...PieceInBattleItem.value
  //       })
  //     }
  //   })
  // });

  BoardList!.enemyPieces?.forEach(item => {
    PieceInBattleList.forEach(PieceInBattleItem => {
      if (PieceInBattleItem.key.key == item) {
        console.log(item,PieceInBattleItem)
        enemyList.push({
          ...PieceInBattleItem.value
        })
      }
    })
  });
  enemyList.forEach(item => {
    PieceListori.forEach(PieceListoriItem => {
      if (PieceListoriItem.key.key == item.pieceId) {
        enemyListLast.push({
          ...item,
          creature: PieceListoriItem.value.creature
        })
      }
    })
  })


  const tierPrice = ShopConfig?.[0]?.value?.tierPrice

  console.log({ PieceList, enemyListLast })
  // console.log(CreaturesArr, 'CreaturesArr', playerObj, ShopConfig)

  const [isHovering, setIsHovering] = useState(false);

  const dropRef = useRef(null);

  useDrop(dropRef, {
    onText: (text, e) => {
      console.log(e);
      alert(`'text: ${text}' dropped`);
    },
    onFiles: (files, e) => {
      console.log(e, files);
      alert(`${files.length} file dropped`);
    },
    onUri: (uri, e) => {
      console.log(e);
      alert(`uri: ${uri} dropped`);
    },
    onDom: (content: string, e) => {
      alert(`custom: ${content} dropped`);
    },
    onDragEnter: () => setIsHovering(true),
    onDragLeave: () => setIsHovering(false),
  });

  const [coins, setCoins] = useState(10);
  const [bench, setBench] = useState([]);
  const [placement, setPlacement] = useState([]);
  const [heroes, setHeroes] = useState(initHero());

  const [squares, setSquares] = useState(Array(64).fill(null));
  const [position, setPosition] = useState({ x: 0, y: 0 });

  if (!playerObj) return null
  const { coin, heroAltar, pieces, inventory, gameId, health, roomId, status, streakCount, tier, exp } = playerObj!


  const DecodeHeroList = heroAltar.map(item => decodeHero(item))

  // const getName = (index:number) => 

  const decodeHeroFn = (arr) => {
    const decodeArr = arr.map(item => decodeHero(item))

    return decodeArr.map(item => ({
      cost: tierPrice?.[item?.[1]],
      lv: item?.[1] + 1,
      url: srcList[item?.[0]],
      // name: `hero ${item?.[0]}`
    }))
  }



  const heroList = decodeHeroFn(heroAltar)

  const inventoryList = decodeHeroFn(inventory)

  // const piecesList = [] || decodeHeroFn(pieces)

  console.log(heroAltar, inventory, pieces, DecodeHeroList, heroList, inventoryList)




  const movePiece = ({
    site, hero
  }) => {
    const newSquares = squares.map((item, index) => {
      if (index == site) {
        item = hero
      }
      return item
    })
    setSquares(newSquares)
  }




  function handleDrag(e) {
    // 计算当前鼠标位置对应的格子
    const gridX = Math.floor(e.clientX / 50);
    const gridY = Math.floor((e.clientY / 50) - 1);

    console.log(gridX, gridY)
    // 设置新的坐标
    setPosition({ x: gridX, y: gridY });

  }

  const handleBuy = async (index) => {
    await buyHero(index)
  }

  const handleMoveToBoard = (hero: never) => {
    setBench(bench.filter(h => h !== hero));
    setPlacement([...placement, hero]);
  }

  const handleMoveToBench = (hero) => {
    setPlacement(placement.filter(h => h !== hero));
    setBench([...bench, hero]);
  }

  const refresh = () => {
    setHeroes(initHero())
    setCoins(coins => coins -= 2);

  }

  const [isModalOpen, setIsModalOpen] = useState(false);

  const showModal = () => {
    setIsModalOpen(true);
  };

  const handleOk = () => {
    setIsModalOpen(false);
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };


  const autoBattleFn = async () => {
    const joinres = await autoBattle(1, '1')
    console.log(joinres)
  }




  return (
    <div className="game">
      <div className="fixed left-2 top-2 align-text-bottom grid">
        <span> Coin:{playerObj.coin}</span>
        {/* <div className="" onClick={buyRefreshHero}>refresh hero</div> */}
        {/* <div className="" onClick={showModal}>openHeroShop</div> */}
        <Button onClick={buyRefreshHero} >refreshHero</Button>
        <Button onClick={showModal} >openHeroShop</Button>
        <Button onClick={() => autoBattle(playerObj.gameId, localAccount!)} >autoBattle</Button>
        {/* <Statistic title="Coins" value={playerObj.coin} precision={0} prefix={<DollarTwoTone />} /> */}
      </div>
      {/* <div className="coin-area" onClick={() => setCoins(c => c += 1)}>add coins</div> */}

      {/* <div className="coin-area" onClick={autoBattleFn}>autoBattle</div> */}

      <div className="hero-area" style={{ display: 'flex' }} >

        <Modal title="" closable={false} width={800} open={isModalOpen} onOk={handleOk} onCancel={handleCancel} footer={null}>
          <div className="flex justify-around">

            {heroList.map((hero, index) => (
              <div key={hero.url + index} onClick={() => handleBuy(index)}>
                <Card
                  hoverable
                  style={{ width: 120 }}
                  cover={<img src={`${hero.url}`} alt={hero.url} style={{ width: '100%', height: 120 }} />}
                >
                  <span className=" text-block-200 mr-2 text-xl">
                    Lv: {hero.lv}
                  </span>
                  <span className=" text-yellow-400 text-xl">
                    Cost: {hero.cost}
                  </span>

                </Card>
              </div>
            ))}
          </div>

        </Modal>

      </div>

      <Chessboard enemyListLast={enemyListLast} srcList={srcList} squares={squares} piecesList={PieceList} bench={bench} placement={placement} add={handleMoveToBoard} remove={handleMoveToBench} />

      <div className="bench-area">
        {console.log(inventoryList)}
        {inventoryList.map((hero, index) => (
          <div key={hero.url + index} onClick={() => handleMoveToBoard(hero)}>
            {/* <img src={`${hero.url}`} alt={hero.url} style={{ height:60 }}  /> */}

            <PieceImg index={index} hero={hero} src={`${hero.url}`} alt={hero.url} movePiece={movePiece} />
            {/* <span>{hero.name}</span> */}
          </div>
        ))}
      </div>

    </div>
  );
}

export default Game;
