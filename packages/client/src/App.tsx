import { useComponentValue, useRows } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
import AutoChess from "./ui/ChessMain";
import JoinGame from "./ui/JoinGame";
import "./index.css";
import { SelectNetwork } from "./ui/SelectNetwork";

export const App = () => {
  const {
    components: {
      Counter,
      Board,
      Game,
      PieceInBattle,
      Piece,
      Creatures,
      CreatureConfig,
      Player,
      ShopConfig,
      GameConfig,
      WaitingRoom,
    },
    systemCalls: {
      increment,
      joinRoom,
      autoBattle,
      buyRefreshHero,
      buyHero,
      sellHero,
      buyExp,
      placeToBoard,
      changePieceCoordinate,
      placeBackInventory,
    },
    network: {
      singletonEntity,
      localAccount,
      playerEntity,
      network,
      singletonEntityId,
      storeCache,
    },
  } = useMUD();

  const counter = useComponentValue(Counter, singletonEntity);
  const playerObj = useComponentValue(Player, playerEntity);

  //todo 大厅多玩家任意匹配
  const WaitingRoomList = useRows(storeCache, { table: "WaitingRoom" });
  const OwnRoom = WaitingRoomList.some(
    (room) => room.value.player1 == localAccount
  );

  const isPlay = playerObj?.status == 1;

  // console.log(OwnRoom, 'OwnRoom')
  // console.log(localAccount, 'localAccount', playerEntity, singletonEntity);
  // console.log(WaitingRoomList, 'WaitingRoomList')

  // const roomId = 'mud1';

  return (
    <>
      {isPlay ? <AutoChess /> : <JoinGame />}
      {/* <JoinGame  /> */}
      <div className="absolute top-4 right-4">
        <SelectNetwork />
      </div>
    </>
  );
};
