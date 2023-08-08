import { useState, useEffect } from "react";
import useChessboard from "@/hooks/useChessboard";
import useBlockNumber from "@/hooks/useBlockNumber";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";

dayjs.extend(duration);

function GameStatusBar() {
  const { currentGame, playerObj } = useChessboard();
  const { blockNumber, startBlockNumber } = useBlockNumber();

  useEffect(() => {}, []);

  return (
    <div className="flex justify-center">
      <div className="w-[160px]">Current block: {blockNumber}</div>
      <div className="w-[120px] ml-2">
        Time left:
        {startBlockNumber >= 0
          ? dayjs.duration(startBlockNumber, "seconds").format("mm:ss")
          : "--:--"}
      </div>
      <div className="ml-2">round:{currentGame?.value.round}</div>
    </div>
  );
}

export default GameStatusBar;
