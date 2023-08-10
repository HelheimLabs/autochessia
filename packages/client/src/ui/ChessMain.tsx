import React, { useState, useRef, useEffect } from "react";
import "./Chessboard.css";
import Chessboard from "./Chessboard";
import PieceImg from "./Piece";
import ShopCom from "./Shop";
import PlayerList from "./Playlist";
import GameStatusBar from "./GameStatusBar";

import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { useDrop } from "ahooks";
import useChessboard from "@/hooks/useChessboard";

import { Card, Modal, Button, Popconfirm } from "antd";
import PreLoadAssets from "@/component/PreloadAssets";

const BoardStatusText = ["准备阶段", "战斗进行中", "等待对手战局结束"];
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
      <span> Status:{BoardStatusText[BoardList?.status] ?? "准备阶段"}</span>
    </>
  );
};

const Game = () => {
  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: {
      autoBattle,
      buyRefreshHero,
      buyHero,
      sellHero,
      buyExp,
      placeBackInventory,
      surrender,
    },
    network: { localAccount, playerEntity, storeCache },
  } = useMUD();

  const {
    heroList,
    srcObj,
    PiecesList,
    inventoryList,
    placeToBoard,
    changeHeroCoordinate,
  } = useChessboard();

  const playerObj = useComponentValue(Player, playerEntity);
  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const [isCalculating, setIsCalculating] = useState(false);

  useEffect(() => {
    let calculateInterval: any;

    if (isCalculating && BoardList?.status == 1) {
      calculateInterval = setInterval(async () => {
        await autoBattle(_playerlayerGlobal!.gameId, localAccount);
        console.log("autobattle");
      }, 1500);
    }

    return () => {
      if (calculateInterval) {
        console.log("close");
        clearInterval(calculateInterval);
      }
    };
  }, [isCalculating, BoardList?.status]);

  const autoBattleFn = async () => {
    await autoBattle(_playerlayerGlobal!.gameId, localAccount);
    setIsCalculating(true);
  };

  const buyExpFn = async () => {
    await buyExp();
  };

  const surrenderFn = async () => {
    await surrender();
  };

  const dropRef = useRef(null);

  useDrop(dropRef, {
    onDom: (content: any) => {
      // console.log(content, "content", dropRef);
      const moveIndex = PiecesList!.findIndex(
        (item) => item.creatureId == content.creatureId
      );
      placeBackInventory(moveIndex, 0);
    },
  });

  const handleBuy = async (index: number) => {
    await buyHero(index);
  };

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
    <div className="bg-black text-white fixed w-full">
      {/* <div className="fixed left-2 top-2 align-text-bottom grid">
        <ShowInfoMain playerObj={playerObj} BoardList={BoardList} />
      </div> */}
      <GameStatusBar showModal={showModal} />
      <div className="fixed left-2  top-36 align-text-bottom grid  text-white">
        {/* <Button className="my-4 text-white-wrap" onClick={showModal}>
          openHeroShop
        </Button>
        <Button className="my-4 text-white-wrap" onClick={buyExpFn}>
          buyExp
        </Button> */}
        <Button className="my-4 text-white-wrap" onClick={autoBattleFn}>
          Manual Battle
        </Button>
        <Popconfirm
          placement="topLeft"
          title={"leaveRoom"}
          onConfirm={surrenderFn}
          okText="Yes"
          cancelText="No"
        >
          <Button danger className="my-4">
            Quit
          </Button>
        </Popconfirm>
      </div>
      <ShopCom
        heroList={heroList}
        isModalOpen={isModalOpen}
        srcObj={srcObj}
        handleBuy={handleBuy}
        handleCancel={handleCancel}
        buyRefreshHero={buyRefreshHero}
      />
      <Chessboard />
      <PlayerList />

      <div className="bench-area bg-stone-500 mt-4  border-cyan-700   text-center min-h-[90px] w-[600px] flex  justify-center mx-auto">
        {inventoryList?.map(
          (
            hero: { url: string; creature: any; image: string },
            index: number
          ) => (
            <div key={hero.url + index}>
              <PieceImg
                placeBackInventory={placeBackInventory}
                sellHero={sellHero}
                srcObj={srcObj}
                index={index}
                hero={hero}
                src={hero.image}
                alt={hero.url}
              />
            </div>
          )
        )}
      </div>
      <PreLoadAssets />
    </div>
  );
};

export default Game;
