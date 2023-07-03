import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
// import AutoChess from './ui/ChessMain'
import { formatBytes32String } from 'ethers/lib/utils';



export const App = () => {
  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp },
    network: { singletonEntity, localAccount,playerEntity },
  } = useMUD();

  const counter = useComponentValue(Counter, singletonEntity);
  const playerObj=useComponentValue(Player, playerEntity);

  // console.log(localAccount, 'localAccount',playerEntity,singletonEntity);
  // console.log(playerObj)

  const roomid = 'mud';
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
          console.log("new joinRoom value:", await autoBattle(0,localAccount));
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

      {/* <AutoChess/> */}
    </>
  );
};
