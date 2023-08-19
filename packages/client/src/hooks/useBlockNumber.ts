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

  const [width, setWidth] = useState(100);
  const [timeLeft, setTimeLeft] = useState(roundIntervalTime);

  useEffect(() => {
    const interval = setInterval(() => {
      if (width > 0) {
        setTimeLeft(timeLeft - 0.1);
        setWidth(width - (100 / roundIntervalTime) * 0.1);
      }

      if (timeLeft <= 0) {
        clearInterval(interval);
      }
    }, 100);
    return () => clearInterval(interval);
  }, [roundIntervalTime, width]);

  useEffect(() => {
    if (currentBoardStatus == 0) {
      setTimeLeft(roundIntervalTime);
      setWidth(100);
    } else {
      setTimeLeft(0);
      setWidth(0);
    }
  }, [currentBoardStatus, roundIntervalTime]);

  useEffect(() => {
    const interval = setInterval(async () => {
      const number = await getCurrentBlockNumber();
      const startTime = Number(startFrom);

      if (startTime < number && timeLeft <= 0 && currentBoardStatus == 0) {
        // First tick
        console.log("first tick");
        await autoBattleFn();
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
    startBlockNumber,
    currentBoardStatus,
    blockNumber,
    timeLeft,
  ]);

  return {
    blockNumber,
    roundInterval,
    startBlockNumber,
    roundIntervalTime,
    currentBoardStatus,
    expUpgrade,
    status: BoardStatus[currentBoardStatus as number] ?? "Preparing",
    autoBattleFn,
    width,
    timeLeft,
  };
};

export default useBlockNumber;
