import { useState, useEffect, useRef } from "react";
import useChessboard from "./useChessboard";

const roundIntervalTime = 30;

const useBlockNumber = () => {
  const {
    getCurrentBlockNumber,
    roundInterval,
    startFrom,
    autoBattleFn,
    BoardList,
  } = useChessboard();

  const [blockNumber, setBlockNumber] = useState<number>();
  const [startBlockNumber, setStartBlockNumber] =
    useState<number>(roundIntervalTime);

  useEffect(() => {
    const interval = setInterval(async () => {
      const number = await getCurrentBlockNumber();
      const startTime = Number(startFrom);
      setStartBlockNumber((prev) => prev - 1);
      setBlockNumber(number);

      // console.log(startTime < number, startBlockNumber, BoardList?.status);

      if (
        startTime < number &&
        startBlockNumber <= 0 &&
        (BoardList?.status == 0 || !BoardList?.status)
      ) {
        // First tick
        console.log("first tick");
        await autoBattleFn();
      } else if (BoardList?.status == 0 && startBlockNumber < 0) {
        // End tick
        console.log("End tick");
        setStartBlockNumber(roundIntervalTime);
      } else if (BoardList?.status == 1) {
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
    BoardList?.status,
    startBlockNumber,
  ]);

  return {
    blockNumber,
    roundInterval,
    startBlockNumber,
    roundIntervalTime,
  };
};

export default useBlockNumber;
