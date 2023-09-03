import { ClientComponents } from "./createClientComponents";
import { SetupNetworkResult } from "./setupNetwork";
import { opRunChangeHeroCoordinate, opRunPlaceBackInventory } from "@/opRender";

export type SystemCalls = ReturnType<typeof createSystemCalls>;

export function createSystemCalls(
  setupNetworkResult: SetupNetworkResult,
  clientComponents: ClientComponents
) {
  const { Player, Hero } = clientComponents;
  const { worldContract, waitForTransaction, playerEntity } =
    setupNetworkResult;

  const autoBattle = async (gameId: number, player: `0x${string}`) => {
    const tx = await worldContract.write.tick([gameId, player]);
    await waitForTransaction(tx);
    // TODO: update next tick
    // return getComponentValue(Counter, singletonEntity);
  };

  const createRoom = async (
    roomId: `0x${string}`,
    seatNum: number,
    password: `0x${string}`
  ) => {
    const tx = await worldContract.write.createRoom([
      roomId,
      seatNum,
      password,
    ]);
    await waitForTransaction(tx);
  };

  const joinRoom = async (gameId: `0x${string}`) => {
    const tx = await worldContract.write.joinRoom([gameId]);
    await waitForTransaction(tx);
  };

  const joinPrivateRoom = async (
    roomId: `0x${string}`,
    a: readonly [bigint, bigint],
    b: readonly [readonly [bigint, bigint], readonly [bigint, bigint]],
    c: readonly [bigint, bigint]
  ) => {
    const tx = await worldContract.write.joinPrivateRoom([roomId, a, b, c]);
    await waitForTransaction(tx);
  };

  const startGame = async (roomId: `0x${string}`) => {
    const tx = await worldContract.write.startGame([roomId]);
    await waitForTransaction(tx);
  };

  const leaveRoom = async (gameId: `0x${string}`, index: bigint) => {
    const tx = await worldContract.write.leaveRoom([gameId, index]);
    await waitForTransaction(tx);
  };

  const surrender = async () => {
    const tx = await worldContract.write.surrender();
    await waitForTransaction(tx);
  };

  const buyRefreshHero = async () => {
    const tx = await worldContract.write.buyRefreshHero();
    await waitForTransaction(tx);
  };

  const buyHero = async (index: number) => {
    const playerOverride = opRunBuyHero(
      setupNetworkResult,
      clientComponents,
      index
    );
    try {
      const tx = await worldContract.write.buyHero([BigInt(index)]);
      await waitForTransaction(tx);
    } catch (e) {
      console.error(e);
    } finally {
      Player.removeOverride(playerOverride);
    }
  };

  const sellHero = async (index: number) => {
    const id = opRunSellHero(setupNetworkResult, clientComponents, index);

    try {
      const tx = await worldContract.write.sellHero([index]);
      await waitForTransaction(tx);
    } catch (e) {
      console.error(e);
    } finally {
      Player.removeOverride(id);
    }
  };

  const buyExp = async () => {
    const tx = await worldContract.write.buyExp();
    await waitForTransaction(tx);
  };

  const placeToBoard = async (index: bigint, x: number, y: number) => {
    const tx = await worldContract.write.placeToBoard([index, x, y]);
    await waitForTransaction(tx);
  };

  const changeHeroCoordinate = async (index: number, x: number, y: number) => {
    const id = opRunChangeHeroCoordinate(
      setupNetworkResult,
      clientComponents,
      index,
      x,
      y
    );

    try {
      const tx = await worldContract.write.changeHeroCoordinate([
        BigInt(index),
        x,
        y,
      ]);
      await waitForTransaction(tx);
    } catch (e) {
      console.error(e);
    } finally {
      Hero.removeOverride(id);
    }
  };

  const placeBackInventory = async (herosIndex: number, invIdx: number) => {
    const id = opRunPlaceBackInventory(
      setupNetworkResult,
      clientComponents,
      herosIndex,
      invIdx
    );

    try {
      const tx = await worldContract.write.placeBackInventoryAndSwap([
        BigInt(herosIndex),
        BigInt(invIdx),
      ]);
      await waitForTransaction(tx);
    } catch (e) {
      console.error(e);
    } finally {
      Player.removeOverride(id);
    }
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
