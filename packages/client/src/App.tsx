import { useComponentValue, useRows } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
import { formatBytes32String } from 'ethers/lib/utils';
import AutoChess from './ui/ChessMain'
import JoinGame from "./ui/JoinGame";
import './index.css'



export const App = () => {
  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig, WaitingRoom },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory, checkCorValidity },
    network: { singletonEntity, localAccount, playerEntity, network, singletonEntityId, storeCache },
  } = useMUD();

  const counter = useComponentValue(Counter, singletonEntity);
  const playerObj = useComponentValue(Player, playerEntity);

  //todo 大厅多玩家任意匹配
  const WaitingRoomList = useRows(storeCache, { table: "WaitingRoom" });
  const OwnRoom = WaitingRoomList.some(room => room.value.player1 == localAccount)


  const isPlay = playerObj?.status == 1

  console.log(OwnRoom, 'OwnRoom')
  console.log(localAccount, 'localAccount', playerEntity, singletonEntity);
  console.log(WaitingRoomList, 'WaitingRoomList')

  const roomId = 'mud1';
  const bytes32Str = formatBytes32String(roomId);

  return (
    <>
      {/* <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await joinRoom(bytes32Str));
        }}
      >
        joinRoom
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await autoBattle(playerObj.gameId, singletonEntityId));
        }}
      >
        autoBattle
      </button>

      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new autoBattle value:", await buyRefreshHero());
          console.log(playerObj)
        }}
      >
        buyRefreshHero
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await buyHero(2));
          console.log(playerObj)
        }}
      >
        buyHero
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await sellHero(0));
        }}
      >
        sellHero
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await buyExp());
        }}
      >
        buyExp
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await placeToBoard(0,0,0));
        }}
      >
        placeToBoard
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await changePieceCoordinate(0,0,0));
        }}
      >
        changePieceCoordinate
      </button>
      <button
        type="button"
        onClick={async (event) => {
          event.preventDefault();
          console.log("new joinRoom value:", await placeBackInventory(0));
        }}
      >
        placeBackInventory
      </button> */}

      {isPlay
        ? <AutoChess />
        :<JoinGame roomId={bytes32Str} />
      }


    </>
  );
};
