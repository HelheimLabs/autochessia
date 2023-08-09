import { useState, useEffect } from "react";
import useChessboard from "@/hooks/useChessboard";
import useBlockNumber from "@/hooks/useBlockNumber";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";
import Logo from "../../public/logo.png";

dayjs.extend(duration);

function GameStatusBar() {
  const { currentGame, playerObj } = useChessboard();
  const { status, startBlockNumber, roundIntervalTime } = useBlockNumber();
  const [width, setWidth] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      if (width >= 0) {
        const dec = 100 / ((roundIntervalTime * 1000) / 100);
        let timeLeft = width - dec;
        setWidth(timeLeft >= 0 ? timeLeft : 0);
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
    <div className="grid justify-center pt-[12px] mx-auto mb-[12px]">
      <div className="flex items-center justify-center">
        <div className="flag-bg grid items-center justify-center text-center ">
          <span className="flag-text">PIECE</span>
          <span className="flag-text">7/7</span>
        </div>
        <img src={Logo} alt="" />
        <div className="flag-bg grid items-center justify-center text-center ">
          <span className="flag-text">ROUND</span>
          <span className="flag-text">{currentGame?.value.round}</span>
        </div>
      </div>
      <div className="flex items-center justify-center">
        <div className="w-[500px] relative text-center">
          <div
            className={`${
              width <= 0 ? "bg-transparent" : "bg-blue-500"
            } transition-all absolute inset-x-0 top-[5px] mx-auto h-[50px] -z-5 rounded-lg`}
            style={{ width: width + "%" }}
          ></div>
          <span className="timeleft mx-auto z-20 ">
            <span className="">{status}</span>
            {status == "Preparing" && (
              <span className="ml-[20px]">
                {startBlockNumber >= 0
                  ? dayjs.duration(startBlockNumber, "seconds").format("ss")
                  : null}
              </span>
            )}
          </span>
        </div>
      </div>
    </div>
  );
}

export default GameStatusBar;
