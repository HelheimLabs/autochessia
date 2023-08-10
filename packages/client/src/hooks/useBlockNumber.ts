import { useState, useEffect, useRef } from "react";
import useChessboard from "./useChessboard";

const roundIntervalTime = 30;
// const BoardStatus = ["PREPARING", "INBATTLE", "FINISHED"];
const BoardStatus = ["Preparing", "In Progress", "Awaiting Opponent"];

const useBlockNumber = () => {
  const {
    getCurrentBlockNumber,
    roundInterval,
    startFrom,
    autoBattleFn,
    currentGameStatus,
    currentBoardStatus = 0,
    expUpgrade,
  } = useChessboard();

  // console.log(status, "status", currentGameStatus);
  const [blockNumber, setBlockNumber] = useState<number>();
  const [startBlockNumber, setStartBlockNumber] =
    useState<number>(roundIntervalTime);

  useEffect(() => {
    const interval = setInterval(async () => {
      const number = await getCurrentBlockNumber();
      const startTime = Number(startFrom);
      if (currentBoardStatus == 0) {
        setStartBlockNumber((prev) => prev - 1);
        setBlockNumber(number);
      }

      if (
        startTime < number &&
        startBlockNumber <= 0 &&
        currentBoardStatus == 0
      ) {
        // First tick
        console.log("first tick");
        await autoBattleFn();
      } else if (currentBoardStatus == 0 && startBlockNumber <= 0) {
        // End tick
        console.log("End tick");
        setStartBlockNumber(roundIntervalTime);
      } else if (currentBoardStatus == 1) {
        // Running tick
        console.log("Running tick");
        await autoBattleFn();
      }
    }, 1000);
    return () => {
      clearInterval(interval);
    };
  }, [
    startFrom,
    roundInterval,
    getCurrentBlockNumber,
    currentGameStatus,
    startBlockNumber,
    currentBoardStatus,
    blockNumber,
  ]);

  return {
    blockNumber,
    roundInterval,
    startBlockNumber,
    roundIntervalTime,
    currentBoardStatus,
    expUpgrade,
    status: BoardStatus[currentBoardStatus as number] ?? "Preparing",
  };
};

export default useBlockNumber;
