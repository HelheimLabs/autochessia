import React, { useState, useRef, useEffect } from 'react';
import './Chessboard.css';
import Chessboard from './Chessboard';
import PieceImg from './Piece';
import { decodeHero } from '../lib/ulits';

import { useComponentValue, useRows, useEntityQuery } from "@latticexyz/react";
import { Has, HasValue, getComponentValueStrict } from "@latticexyz/recs";
import { useMUD } from "../MUDContext";
import { useDrop, useDrag } from 'ahooks';


import { Card, Statistic, Modal, Button } from 'antd';

const { Meta } = Card;


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

enum BoardStatus {
  "UNINITIATED",
  "INBATTLE",
  "FINISHED"
}

const BoardStatusText = ['准备阶段', '战斗进行中', '等待对手战局结束']
// const BoardStatusText = ['Preparing', 'In Progress', 'Awaiting Opponent'] 
const { Countdown } = Statistic;

interface GameProps {

}

interface boardInterface {
  pieceId: any;
  creature: number;
  tier: number;
  x: number;
  y: number;
}


const ShowInfoMain = ({ playerObj, BoardList }) => {

  return (
    <>
      <span> Coin:{playerObj.coin}</span>
      <span> Lv:{playerObj.tier}</span>
      <span> Exp:{playerObj.exp}</span>
      <span> Heal:{playerObj.health}</span>
      <span> Status:{BoardStatusText[BoardList?.status]}</span>
    </>
  )
}


const Game = (props: GameProps) => {

  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, GameConfig },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory },
    network: { singletonEntity, localAccount, playerEntity, storeCache,  },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);


  const ShopConfig = useRows(storeCache, { table: "ShopConfig" });
  const PieceListori = useRows(storeCache, { table: "Piece" })
  const PieceInBattleList = useRows(storeCache, { table: "PieceInBattle" })

  const GameRow = useRows(storeCache, { table: "Game" });

  const gameStatus = GameRow.find(item => Number(item.key.index) == playerObj?.gameId)||{value:''}

  const { round='', startFrom='' } = gameStatus?.value


  const GameConfigRow = useRows(storeCache, { table: "GameConfig" })?.[0];

  // console.log({currentBlockNumber})
  console.log({ GameConfigRow })

  const [isCalculating, setIsCalculating] = useState(false)

  useEffect(() => {
    let calculateInterval: any;

    if (isCalculating) {
      calculateInterval = setInterval(async () => {
        // await autoBattle(playerObj?.gameId,localAccount);
        console.log('执行autobattle')
      }, 1500);
    }

    return () => {
      if (calculateInterval) {
        console.log('取消')
        clearInterval(calculateInterval);
      }
    };
  }, [isCalculating]);

   



  const PieceList: boardInterface[] = []

  const enemyList: boardInterface[] = []

  const enemyListLast: boardInterface[] = []

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


  BoardList!.enemyPieces?.forEach(item => {
    PieceInBattleList.forEach(PieceInBattleItem => {
      if (PieceInBattleItem.key.key == item) {
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
          creature: PieceListoriItem.value.creature,
          tier: PieceListoriItem.value.tier,
        })
      }
    })
  })


  const tierPrice = ShopConfig?.[0]?.value?.tierPrice

  const dropRef = useRef(null);

  useDrop(dropRef, {
    onDom: (content: any, e) => {
      console.log(content, 'content')
      if (content.pieceId && !content.enemy) {
        const moveIndex = PieceList.findIndex(item => item.pieceId == content.pieceId)
        placeBackInventory(moveIndex)
      }
    },
  });


  if (!playerObj) return null
  const { coin, heroAltar, pieces, inventory, gameId, health, roomId, status, streakCount, tier, exp } = playerObj!


  const DecodeHeroList = heroAltar.map(item => decodeHero(item))

  // const getName = (index:number) => 

  const decodeHeroFn = (arr) => {
    const decodeArr = arr.map(item => decodeHero(item))

    return decodeArr.map(item => ({
      cost: tierPrice?.[item?.[1]],
      lv: item?.[1] + 1,
      url: srcObj.perUrl + item?.[0] + srcObj.ava,
      creature: item?.[0]
    }))
  }


  const heroList = decodeHeroFn(heroAltar)

  const inventoryList = decodeHeroFn(inventory)


  const handleBuy = async (index: number) => {
    await buyHero(index)
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


  const deadline = 0

  const onFinish = () => {
    console.log('onFinish')
  }

  return (
    <div className="game">
      <div className="fixed left-2 top-2 align-text-bottom grid">

        <ShowInfoMain playerObj={playerObj} BoardStatusText={BoardStatusText} BoardList={BoardList} />

        <Button onClick={showModal} >openHeroShop</Button>
        <Button onClick={() => autoBattle(playerObj.gameId, localAccount!)} >autoBattle</Button>
        {/* <Statistic title="Coins" value={playerObj.coin} precision={0} prefix={<DollarTwoTone />} /> */}
      </div>
      {/* <div className="mx-auto my-4 text-center">
        {BoardList?.status != 2 && <Countdown title={BoardStatusText[BoardList?.status]} value={deadline} onFinish={onFinish} />}
      </div> */}

      <div className="hero-area my-4" style={{ display: 'flex' }} >
        <Modal title="" closable={false} width={800} open={isModalOpen} onOk={handleOk} onCancel={handleCancel} footer={null}>
          <div className="flex">
            {heroList.map((hero, index) => (
              <div className="mr-8 last:mr-0" key={hero.url + index} onClick={() => handleBuy(index)}>
                <Card
                  hoverable
                  style={{ width: 120 }}
                  cover={<img src={`${srcObj.perUrl}${hero.creature}${srcObj.ava}`} alt={hero.url} style={{ width: '100%', height: 120 }} />}
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
          <div className="flex justify-center items-center mt-11">
            <button onClick={buyRefreshHero} className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-full focus:outline-none">Refresh Hero</button>
          </div>
        </Modal>

      </div>

      <Chessboard srcObj={srcObj} enemyListLast={enemyListLast} piecesList={PieceList} />

      <div className="bench-area bg-stone-500 mt-4 ml-40 mr-40  border-cyan-700  border-r-8 text-center " ref={dropRef}>
        {inventoryList.map((hero, index) => (
          <div key={hero.url + index} >
            <PieceImg sellHero={sellHero} srcObj={srcObj} index={index} hero={hero} src={`${srcObj.perUrl}${hero.creature}${srcObj.color}`} alt={hero.url} />
          </div>
        ))}
      </div>

    </div>
  );
}

export default Game;
