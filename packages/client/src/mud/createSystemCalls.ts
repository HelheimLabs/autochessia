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


  const joinRoom = async (gameId: PromiseOrValue<BytesLike>) => {
    const tx = await worldSend("joinRoom", [gameId]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };

  const leaveRoom = async (gameId: PromiseOrValue<BytesLike>) => {
    const tx = await worldSend("leaveRoom", [gameId]);
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

  const placeBackInventory = async (index: PromiseOrValue<BigNumberish>) => {
    const tx = await worldSend("placeBackInventory", [index]);
    await awaitStreamValue(txReduced$, (txHash) => txHash === tx.hash);
  };



  return {
    autoBattle,
    joinRoom,
    leaveRoom,
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
