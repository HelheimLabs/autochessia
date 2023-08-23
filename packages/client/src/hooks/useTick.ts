import { useState, useEffect } from "react";
import useChessboard from "./useChessboard";
import dayjs from "dayjs";
import { useAutoBattle } from "./useAutoBattle";
import { useBoardStatus } from "./useBoardStatus";

// const BoardStatus = ["PREPARING", "INBATTLE", "FINISHED"];
const BoardStatus = ["Preparing", "In Progress", "Awaiting Opponent"];

const useTick = () => {
  const {
    getCurrentBlockNumber,
    roundInterval,
    startFrom,
    autoBattleFn,
    currentRoundStartTime,
    expUpgrade,
  } = useChessboard();
  const { currentBoardStatus } = useBoardStatus();

  // console.log(status, "status", currentGameStatus);
  const [width, setWidth] = useState(100);
  const [timeLeft, setTimeLeft] = useState<number>(Infinity);
  const { shouldRun, setShouldRun, isRunning } = useAutoBattle();

  // reduce progress bar and time
  useEffect(() => {
    const interval = setInterval(() => {
      if (width > 0) {
        const timeLeft =
          (Number(currentRoundStartTime) * 1000 - dayjs().valueOf()) / 1000;

        setTimeLeft(timeLeft);
        setWidth((timeLeft / roundInterval) * 100);
      }

      if (timeLeft <= 0) {
        clearInterval(interval);
      }
    }, 100);
    return () => clearInterval(interval);
  }, [width, timeLeft, roundInterval]);

  useEffect(() => {
    if (currentBoardStatus == 0) {
      const timeLeft =
        (Number(currentRoundStartTime) * 1000 - dayjs().valueOf()) / 1000;
      setTimeLeft(timeLeft);
      setWidth((timeLeft / roundInterval) * 100);
    } else {
      setTimeLeft(0);
      setWidth(0);
    }
  }, [currentBoardStatus, roundInterval, currentRoundStartTime]);

  useEffect(() => {
    if (
      (timeLeft <= 0 && currentBoardStatus === 0) ||
      currentBoardStatus === 1
    ) {
      setShouldRun(true);
    } else {
      setShouldRun(false);
    }
  }, [timeLeft, currentBoardStatus, setShouldRun]);

  return {
    roundInterval,
    currentBoardStatus,
    expUpgrade,
    status: BoardStatus[currentBoardStatus as number] ?? "Preparing",
    autoBattleFn,
    width,
    timeLeft,
  };
};

export default useTick;
