import { useState, useEffect } from "react";
import useChessboard from "@/hooks/useChessboard";
import useBlockNumber from "@/hooks/useBlockNumber";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";

dayjs.extend(duration);

function GameStatusBar() {
  const { currentGame, playerObj } = useChessboard();
  const { blockNumber, startBlockNumber, roundIntervalTime } = useBlockNumber();
  const [width, setWidth] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      if (width >= 0) {
        const dec = 100 / ((roundIntervalTime * 1000) / 100);
        let timeLeft = width - dec;
        setWidth(timeLeft);
      }
    }, 100);
    return () => clearInterval(interval);
  }, [roundIntervalTime, width]);

  useEffect(() => {
    if (startBlockNumber == roundIntervalTime) {
      setWidth(100);
    }
  }, [startBlockNumber, roundIntervalTime]);

  return (
    <div className={`flex justify-center  mx-auto mt-1`}>
      <div className="w-[200px] text-right ">
        <span className="w-[100px] relative text-center ">Current block: </span>
        <span className="w-[100px] relative text-center ">{blockNumber}</span>
      </div>
      <div className="w-[300px] relative text-center">
        <span className="w-[80px] relative text-center  inline-block">
          {" "}
          Time left:
        </span>
        <span className="w-[80px] relative text-center  inline-block">
          {startBlockNumber >= 0
            ? dayjs.duration(startBlockNumber, "seconds").format("mm:ss")
            : "--:--"}
        </span>
        <div
          className={`${
            width <= 0 ? "bg-transparent" : "bg-blue-500"
          } transition-all absolute inset-x-0 top-0 mx-auto h-[25px] -z-10 rounded-lg`}
          style={{ width: width + "%" }}
        >
          {" "}
        </div>
      </div>
      <div className="w-[200px] text-left">
        round:{currentGame?.value.round}
      </div>
    </div>
  );
}

export default GameStatusBar;
