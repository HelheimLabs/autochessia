import { useState, useRef, useEffect } from "react";
import "./Chessboard.css";
import Chessboard from "./Chessboard";
import ShopCom from "./Shop";
import PlayerList from "./Playlist";
import GameStatusBar from "./GameStatusBar";

import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "../MUDContext";
import { useDrop } from "ahooks";
import useChessboard, { HeroBaseAttr } from "@/hooks/useChessboard";
import usePreload from "@/hooks/usePreload";

import { Button, Popconfirm } from "antd";
import { Inventory } from "./Inventory";
import HeroInfo from "./HeroInfo";
import { shallowEqual } from "@/lib/utils";

export interface boardInterface {
  creatureId?: any;
  creature?: number;
  tier?: number;
  x: number;
  y: number;
}

const Game = () => {
  const {
    components: { Board, Player, PlayerGlobal },
    systemCalls: { autoBattle, buyHero, placeBackInventory, surrender },
    network: { localAccount, playerEntity },
  } = useMUD();

  usePreload();

  const { PiecesList } = useChessboard();

  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const BoardList = useComponentValue(Board, playerEntity);

  const [isCalculating, setIsCalculating] = useState(false);

  const [acHero, setAcHero] = useState<HeroBaseAttr | null>(null);

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

  const [isModalOpen, setIsModalOpen] = useState(false);

  const showModal = () => {
    setIsModalOpen(true);
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };

  const setAcHeroFn = (newAcHero: HeroBaseAttr) => {
    if (shallowEqual(newAcHero, acHero)) {
      setAcHero(null);
    } else {
      setAcHero(newAcHero);
    }
  };

  return (
    <div className="bg-black text-white fixed w-full h-full">
      <GameStatusBar showModal={showModal} />
      <div className="fixed left-2  top-36 align-text-bottom grid  text-white">
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
      <ShopCom isModalOpen={isModalOpen} handleCancel={handleCancel} />
      <Chessboard setAcHeroFn={setAcHeroFn} />
      <PlayerList />
      <Inventory setAcHeroFn={setAcHeroFn} />
      <HeroInfo hero={acHero as HeroBaseAttr} />
    </div>
  );
};

export default Game;
