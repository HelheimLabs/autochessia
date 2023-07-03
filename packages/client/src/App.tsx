import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
// import AutoChess from './ui/ChessMain'
import { formatBytes32String } from 'ethers/lib/utils';



export const App = () => {
  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp,placeToBoard,changePieceCoordinate,placeBackInventory,checkCorValidity },
    network: { singletonEntity, localAccount, playerEntity, network },
  } = useMUD();

  const counter = useComponentValue(Counter, singletonEntity);
  const playerObj = useComponentValue(Player, playerEntity);

  console.log(localAccount, 'localAccount', playerEntity, singletonEntity);
  // console.log(playerObj)
  console.log(network.signer)

  const roomid = 'mud1';
  const bytes32Str = formatBytes32String(roomid);

  return (
    <>
      <button
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
          console.log("new joinRoom value:", await autoBattle(0, localAccount));
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
          console.log("new joinRoom value:", await buyHero(0));
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
      </button>
      

      {/* <AutoChess/> */}
    </>
  );
};
