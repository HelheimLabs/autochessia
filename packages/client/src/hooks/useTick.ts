import { useState, useEffect } from "react";
import useChessboard from "./useChessboard";
import dayjs from "dayjs";
import { useMUD } from "../MUDContext";

import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Entity, getComponentValueStrict, Has, Not } from "@latticexyz/recs";

import { useAutoBattle } from "./useAutoBattle";
import { useBoardStatus } from "./useBoardStatus";

// const BoardStatus = ["PREPARING", "INBATTLE", "FINISHED"];
const BoardStatus = ["Preparing", "In Progress", "Awaiting Opponent"];

const useTick = () => {
  // const {
  //   roundInterval,
  //   startFrom,
  //   currentRoundStartTime,
  //   expUpgrade,
  // } = useChessboard();

  const initEntity: Entity =
    "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

  const {
    components: { PlayerGlobal, GameConfig, Game },
    systemCalls: { autoBattle, placeToBoard, changeHeroCoordinate },
    network: { playerEntity },
  } = useMUD();

  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const _GameConfig = useComponentValue(GameConfig, initEntity);

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValueStrict(Game, currentGameId!);

  const roundInterval = _GameConfig?.roundInterval;
  const expUpgrade = _GameConfig?.expUpgrade;
  const currentRoundStartTime = currentGame?.startFrom;

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
    width,
    timeLeft,
  };
};

export default useTick;
