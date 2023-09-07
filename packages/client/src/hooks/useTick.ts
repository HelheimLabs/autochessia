import { useState, useEffect, useRef } from "react";
import useChessboard from "./useChessboard";
import dayjs from "dayjs";
import { useMUD } from "../MUDContext";

import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Entity, getComponentValueStrict, Has, Not } from "@latticexyz/recs";

import { useAutoBattle } from "./useAutoBattle";
import { useBoardStatus } from "./useBoardStatus";

const BoardStatus = ["Preparing", "In Progress", "Awaiting Opponent"];

const useTick = () => {
  const initEntity: Entity =
    "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

  const {
    components: { PlayerGlobal, GameConfig, Game, Board },
    systemCalls: { autoBattle, placeToBoard, changeHeroCoordinate },
    network: { playerEntity },
  } = useMUD();

  const _playerlayerGlobal = useComponentValue(PlayerGlobal, playerEntity);

  const _GameConfig = useComponentValue(GameConfig, initEntity);

  const currentGameId = useEntityQuery([Has(Game)]).find(
    (row) => (_playerlayerGlobal?.gameId as unknown as Entity) == row
  );

  const currentGame = getComponentValueStrict(Game, currentGameId!);

  const roundInterval = _GameConfig?.roundInterval as number;
  const expUpgrade = _GameConfig?.expUpgrade;
  const currentRoundStartTime = currentGame?.startFrom;

  const { currentBoardStatus } = useBoardStatus();

  const [width, setWidth] = useState(100);
  const [timeLeft, setTimeLeft] = useState<number>(Infinity);
  const { shouldRun, setShouldRun } = useAutoBattle();

  const timeRef = useRef(timeLeft);
  timeRef.current = timeLeft;

  // reduce progress bar and time
  useEffect(() => {
    const interval = setInterval(() => {
      const timeLeft = dayjs.unix(currentRoundStartTime).diff(dayjs()) / 1000;

      if (timeLeft > -1) {
        setTimeLeft(timeLeft);
        setWidth((timeLeft / roundInterval) * 100);
      } else {
        clearInterval(interval);
      }
    }, 100);
    return () => clearInterval(interval);
  }, [width, timeLeft, roundInterval]);

  useEffect(() => {
    if (currentBoardStatus == 0) {
      const timeLeft = dayjs.unix(currentRoundStartTime).diff(dayjs()) / 1000;

      setTimeLeft(timeLeft);
      setWidth((timeLeft / roundInterval) * 100);
    }
  }, [currentBoardStatus, roundInterval, currentRoundStartTime]);

  useEffect(() => {
    if (
      (timeRef.current <= 0 && currentBoardStatus === 0) ||
      currentBoardStatus === 1
    ) {
      setShouldRun(true);
    } else {
      setShouldRun(false);
    }
  }, [timeRef.current, currentBoardStatus, setShouldRun]);

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
