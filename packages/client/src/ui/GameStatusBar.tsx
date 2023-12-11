import useChessboard from "@/hooks/useChessboard";
import useTick from "@/hooks/useTick";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";
import { useMUD } from "../MUDContext";

import { Tooltip } from "antd";

dayjs.extend(duration);

interface IHangSign {
  name?: string;
  value?: string;
  tip?: string;
}

export function HangSign({ name, value, tip }: IHangSign) {
  return (
    <Tooltip title={tip}>
      <div className="flex flex-col h-[82px] w-28 mx-6 bg-cover bg-[url('/assets/status_board.png')]">
        <div className="mt-6 ml-3">
          <div className="text-white">{name}</div>
        </div>
        <div className="flex flow-row justify-end mr-3">
          <div className="text-white">{value}</div>
        </div>
      </div>
    </Tooltip>
  );
}

export function ProgressBar() {
  const { status, expUpgrade, width, timeLeft } = useTick();
  const time = Math.floor(timeLeft);

  return (
    <div className="bg-[url('assets/status_bar.png')] bg-center bg-contain bg-no-repeat w-[19rem] h-[6rem] top-4 relative text-center flex flex-col mx-auto z-20 items-center justify-center">
      {/* <div
        className={`${
          width <= 0 ? "bg-transparent" : "bg-blue-500"
        } transition-all absolute inset-x-0 top-[-5px] mx-auto h-[60px] -z-5 rounded-lg`}
        style={{ width: width + "%" }}
      ></div> */}
      <div className="uppercase text-3xl whitespace-nowrap top">{status}</div>
      <div className={`text-center ${time >= 0 ? "" : "invisible"}`}>
        {time}
      </div>
    </div>
  );
}

function GameStatusBar({ customRef2 }) {
  const {
    systemCalls: { buyExp },
  } = useMUD();
  const { currentGame, playerObj } = useChessboard();
  const { status, expUpgrade, width, timeLeft } = useTick();

  const time = Math.floor(timeLeft);

  return (
    <div className="grid justify-center mx-auto" ref={customRef2}>
      <div className="flex items-center justify-center">
        <HangSign
          name="EXP"
          value={`${playerObj?.exp}/${expUpgrade?.[playerObj?.tier as number]}`}
          tip="EXP +4 , COST 4"
        />
        <HangSign
          tip={`Lv ${(playerObj?.tier as number) + 1}`}
          name="PIECE"
          value={`${playerObj?.heroes?.length}/${
            (playerObj?.tier as number) + 1
          }`}
        />

        <ProgressBar />

        <HangSign name="ROUND" value={`${currentGame?.round}`} />
        <HangSign name="COIN" value={`${playerObj?.coin}`} />
      </div>
      <div className="flex items-center justify-center mt-3 "></div>
    </div>
  );
}

export default GameStatusBar;
