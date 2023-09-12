import useChessboard from "@/hooks/useChessboard";
import useTick from "@/hooks/useTick";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";
import Logo from "/assets/logo.png";
import { Tooltip } from "antd";
import { useMUD } from "../MUDContext";

dayjs.extend(duration);

function GameStatusBar({ showModal, customRef, customRef2 }) {
  const {
    systemCalls: { buyExp },
  } = useMUD();
  const { currentGame, playerObj } = useChessboard();
  const { status, expUpgrade, width, timeLeft } = useTick();

  const time = Math.floor(timeLeft);

  return (
    <div
      className="grid justify-center pt-[12px] mx-auto mb-[12px] "
      ref={customRef2}
    >
      <div className="flex items-center justify-center">
        <Tooltip title="EXP +4 , COST $4">
          <div
            onClick={() => buyExp()}
            className="notice-board  bg-blue-500 cursor-pointer"
          >
            <span className="flag-text">EXP</span>
            {expUpgrade && (
              <span className="flag-text notice-board-text ">
                {playerObj?.exp}/{expUpgrade[playerObj?.tier as number]}
              </span>
            )}
          </div>
        </Tooltip>

        <Tooltip title={`Lv ${(playerObj?.tier as number) + 1}`}>
          <div className="notice-board mx-[50px] bg-[#EB6E1C]">
            <span className="flag-text">PIECE</span>
            <span className="flag-text notice-board-text">
              {playerObj?.heroes?.length}/{(playerObj?.tier as number) + 1}
            </span>
          </div>
        </Tooltip>
        <Tooltip title={`OPEN SHOP`}>
          <div
            ref={customRef}
            className="cursor-pointer mx-[20px]"
            onClick={() => showModal()}
          >
            <img src={Logo} alt="" />
          </div>
        </Tooltip>
        <div className="notice-board mx-[50px] bg-[#CF2E3D]">
          <span className="flag-text">ROUND</span>
          <span className="flag-text  notice-board-text">
            {currentGame?.round}
          </span>
        </div>

        <div className="notice-board  bg-[#323846]">
          <span className="flag-text">COIN</span>
          <span className="flag-text  notice-board-text">
            {playerObj?.coin}
          </span>
        </div>
      </div>
      <div className="flex items-center justify-center mt-3 ">
        <div className="w-[500px] relative text-center">
          <div
            className={`${
              width <= 0 ? "bg-transparent" : "bg-blue-500"
            } transition-all absolute inset-x-0 top-[-5px] mx-auto h-[60px] -z-5 rounded-lg`}
            style={{ width: width + "%" }}
          ></div>
          <span className="timeleft mx-auto z-20  ">
            <span className="uppercase  whitespace-nowrap">{status}</span>
            {status == "Preparing" && (
              <span className="ml-[20px]">{timeLeft >= 0 ? time : null}</span>
            )}
          </span>
        </div>
      </div>
    </div>
  );
}

export default GameStatusBar;
