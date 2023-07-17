import React, { useState, useRef, useEffect } from 'react';
import './Chessboard.css';
import Chessboard from './Chessboard';
import PieceImg from './Piece';

import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { useDrop } from 'ahooks';
import useChessboard from '@/hooks/useChessboard';


import { Card, Modal, Button, Popconfirm } from 'antd';


const BoardStatusText = ['准备阶段', '战斗进行中', '等待对手战局结束']
// const BoardStatusText = ['Preparing', 'In Progress', 'Awaiting Opponent'] 


export interface boardInterface {
  creatureId?: any;
  creature?: number;
  tier?: number;
  x: number;
  y: number;
}


const ShowInfoMain = ({ playerObj, BoardList }) => {

  return (
    <>
      <span> Coin:{playerObj.coin}</span>
      <span> Lv:{playerObj.tier + 1}</span>
      <span> Exp:{playerObj.exp}</span>
      <span> Heal:{playerObj.health}</span>
      <span> Status:{BoardStatusText[BoardList?.status] ?? '准备阶段'}</span>
    </>
  )
}


const Game = () => {

  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: { autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeBackInventory, surrender },
    network: { localAccount, playerEntity, storeCache, },
  } = useMUD();

  const { heroList, srcObj, PiecesList, inventoryList, placeToBoard, changeHeroCoordinate } = useChessboard()


  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const [isCalculating, setIsCalculating] = useState(false)

  useEffect(() => {
    let calculateInterval: any;

    if (isCalculating && BoardList?.status == 1) {
      calculateInterval = setInterval(async () => {
        await autoBattle(_playerlayerGlobal!.gameId, localAccount);
        console.log('autobattle')
      }, 1500);
    }

    return () => {
      if (calculateInterval) {
        console.log('close')
        clearInterval(calculateInterval);
      }
    };
  }, [isCalculating, BoardList?.status]);

  const autoBattleFn = async () => {

    await autoBattle(_playerlayerGlobal!.gameId, localAccount);
    setIsCalculating(true)

  }

  const buyExpFn = async () => {

    await buyExp()
  }

  const surrenderFn = async () => {

    await surrender()
  }


  const dropRef = useRef(null);

  useDrop(dropRef, {
    onDom: (content: any) => {
      console.log(content, 'content')
      const moveIndex = PiecesList!.findIndex(item => item.creatureId == content.creatureId)
      placeBackInventory(moveIndex)
    },
  });



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




  return (
    <div className="game">
      <div className="fixed left-2 top-2 align-text-bottom grid">
        <ShowInfoMain playerObj={playerObj}  BoardList={BoardList} />
      </div>
      <div className="fixed left-2  top-36 align-text-bottom grid">
        <Button className="my-4" onClick={showModal} >openHeroShop</Button>
        <Button className="my-4" onClick={buyExpFn} >buyExp</Button>
        <Button className="my-4" onClick={autoBattleFn} >autoBattle</Button>
        <Popconfirm
          placement="topLeft"
          title={"leaveRoom"}
          onConfirm={surrenderFn}
          okText="Yes"
          cancelText="No"
        >
          <Button danger className="my-4"  >Quit</Button>
        </Popconfirm>
        {/* <Statistic title="Coins" value={playerObj.coin} precision={0} prefix={<DollarTwoTone />} /> */}
      </div>
      {/* <div className="mx-auto my-4 text-center">
        {BoardList?.status != 2 && <Countdown title={BoardStatusText[BoardList?.status]} value={deadline} onFinish={onFinish} />}
      </div> */}

      <div className="hero-area my-4" style={{ display: 'flex' }} >
        <Modal title="" closable={false} width={800} open={isModalOpen} onOk={handleOk} onCancel={handleCancel} footer={null}>
          <div className="flex">
            {heroList?.map((hero: { url: string | undefined; creature: any; lv: string | number | boolean | React.ReactElement<any, string | React.JSXElementConstructor<any>> | React.ReactFragment | React.ReactPortal | null | undefined; cost: string | number | boolean | React.ReactElement<any, string | React.JSXElementConstructor<any>> | React.ReactFragment | React.ReactPortal | null | undefined; }, index: number) => (
              <div className="mr-8 last:mr-0" key={index} onClick={() => handleBuy(index)}>
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

      <Chessboard />

      <div className="bench-area bg-stone-500 mt-4 ml-40 mr-40  border-cyan-700   text-center min-h-[90px]" ref={dropRef}>
        {inventoryList?.map((hero: { url: string; creature: any; }, index: number) => (
          <div key={hero.url + index} >
            <PieceImg sellHero={sellHero} srcObj={srcObj} index={index} hero={hero} src={`${srcObj.perUrl}${hero.creature}${srcObj.color}`} alt={hero.url} />
          </div>
        ))}
      </div>

    </div>
  );
}

export default Game;
