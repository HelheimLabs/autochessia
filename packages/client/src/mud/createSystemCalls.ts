import { getComponentValue } from "@latticexyz/recs";
import { awaitStreamValue } from "@latticexyz/utils";
import { ClientComponents } from "./createClientComponents";
import { SetupNetworkResult } from "./setupNetwork";
import { PromiseOrValue } from "contracts/types/ethers-contracts/common";
import { BigNumberish, BytesLike } from "ethers";

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
  { worldSend, txReduced$, singletonEntity }: SetupNetworkResult,
  // { Board, Game,  Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig }: ClientComponents
) {

  const autoBattle = async (gameId: PromiseOrValue<BigNumberish>, player: PromiseOrValue<string>) => {
    const tx = await worldSend("tick", [gameId, player]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const createRoom = async (roomId: PromiseOrValue<BytesLike>, seatNum: PromiseOrValue<number>, password: PromiseOrValue<BytesLike>) => {
    const tx = await worldSend("createRoom", [roomId, seatNum, password]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const joinRoom = async (gameId: PromiseOrValue<BytesLike>) => {
    const tx = await worldSend("joinRoom", [gameId]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const joinPrivateRoom = async (roomId: PromiseOrValue<BytesLike>, a: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>], b: [[PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>], [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]], c: [PromiseOrValue<BigNumberish>, PromiseOrValue<BigNumberish>]) => {
    const tx = await worldSend("joinPrivateRoom", [roomId, a, b, c]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const startGame = async (roomId: PromiseOrValue<BytesLike>) => {
    const tx = await worldSend("startGame", [roomId]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const leaveRoom = async (gameId: PromiseOrValue<BytesLike>, index: PromiseOrValue<number>) => {
    const tx = await worldSend("leaveRoom", [gameId, index]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const surrender = async () => {
    const tx = await worldSend("surrender", []);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };


  const buyRefreshHero = async () => {
    const tx = await worldSend("buyRefreshHero", []);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const buyHero = async (index: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("buyHero", [index]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };


  const sellHero = async (index: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("sellHero", [index]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const buyExp = async () => {
    const tx = await worldSend("buyExp", []);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };


  const placeToBoard = async (index: PromiseOrValue<BigNumberish>, x: PromiseOrValue<BigNumberish>, y: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("placeToBoard", [index, x, y]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const changeHeroCoordinate = async (index: PromiseOrValue<BigNumberish>, x: PromiseOrValue<BigNumberish>, y: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("changeHeroCoordinate", [index, x, y]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const placeBackInventory = async (herosIndex: PromiseOrValue<BigNumberish>,invIdx: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("placeBackInventoryAndSwap", [herosIndex,invIdx]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };



  return {
    autoBattle,
    createRoom,
    joinRoom,
    joinPrivateRoom,
    leaveRoom,
    startGame,
    surrender,
    buyRefreshHero,
    buyHero,
    sellHero,
    buyExp,
    placeToBoard,
    changeHeroCoordinate,
    placeBackInventory,
  };
}
