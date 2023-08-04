import { useState, useEffect, useRef } from "react";
import useChessboard from "./useChessboard";

const useBlockNumber = () => {
  const {
    getCurrentBlockNumber,
    roundInterval,
    startFrom,
    autoBattleFn,
    BoardList,
  } = useChessboard();

  const [blockNumber, setBlockNumber] = useState<number>();
  const [startBlockNumber, setStartBlockNumber] = useState<number>();

  const [isCalculating, setIsCalculating] = useState(false);

  useEffect(() => {
    const initStart = async () => {
      const number = await getCurrentBlockNumber();
      const startTime = Number(startFrom) + Number(roundInterval);
      const Timeleft = startTime - number;
      console.log("init battle", Timeleft);

      if (Timeleft <= 0) {
        await autoBattleFn();
        setIsCalculating(true);
      }
    };
    initStart();
  }, []);

  useEffect(() => {
    const interval = setInterval(async () => {
      const number = await getCurrentBlockNumber();
      const startTime = Number(startFrom) + Number(roundInterval);
      const Timeleft = startTime - number;
      setStartBlockNumber(Timeleft);
      setBlockNumber(number);
      if (Timeleft == 0) {
        await autoBattleFn();
        setIsCalculating(true);
      }

      if (Timeleft < 0 && !isCalculating) {
        await autoBattleFn();
        setIsCalculating(true);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [startFrom, roundInterval, getCurrentBlockNumber, isCalculating]);

  useEffect(() => {
    let calculateInterval: any;

    if (BoardList?.status == 1 && isCalculating) {
      calculateInterval = setInterval(async () => {
        await autoBattleFn();
      }, 1500);
    }

    return () => {
      if (calculateInterval) {
        clearInterval(calculateInterval);
      }
    };
  }, [isCalculating, BoardList?.status]);

  return {
    blockNumber,
    roundInterval,
    startBlockNumber,
  };
};

export default useBlockNumber;
