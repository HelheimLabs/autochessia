import useChessboard from "@/hooks/useChessboard";
import useTick from "@/hooks/useTick";
import dayjs from "dayjs";
import duration from "dayjs/plugin/duration";
import Logo from "../../public/logo.png";
import { Tooltip } from "antd";
import { useMUD } from "../MUDContext";

dayjs.extend(duration);

function GameStatusBar({ showModal }) {
  const {
    systemCalls: { buyExp },
  } = useMUD();
  const { currentGame, playerObj } = useChessboard();
  const { status, expUpgrade, width, timeLeft } = useTick();

  const time = dayjs.duration(timeLeft, "seconds").format("ss");

  return (
    <div className="grid justify-center pt-[12px] mx-auto mb-[12px]">
      <div className="flex items-center justify-center">
        <Tooltip title="EXP +4 , COST $4">
          <div
            onClick={() => buyExp()}
            className=" cursor-pointer flag-bg grid items-center justify-center text-center mx-0"
          >
            <span className="flag-text">EXP</span>
            {expUpgrade && (
              <span className="flag-text">
                {playerObj?.exp}/{expUpgrade[playerObj?.tier as number]}
              </span>
            )}
          </div>
        </Tooltip>

        <Tooltip title={`Lv ${playerObj?.tier + 1}`}>
          <div className="cursor-pointer flag-bg grid items-center justify-center text-center ">
            <span className="flag-text">PIECE</span>
            <span className="flag-text">
              {playerObj?.heroes?.length}/{(playerObj?.tier as number) + 1}
            </span>
          </div>
        </Tooltip>
        <Tooltip title={`OPEN SHOP`}>
          <div className="cursor-pointer " onClick={() => showModal()}>
            <img src={Logo} alt="" />
          </div>
        </Tooltip>

        <div className="flag-bg grid items-center justify-center text-center ">
          <span className="flag-text">ROUND</span>
          <span className="flag-text">{currentGame?.round}</span>
        </div>
        <div className="flag-bg grid items-center justify-center text-center mx-0">
          <span className="flag-text">COIN</span>
          <span className="flag-text">{playerObj?.coin}</span>
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
              <span className="ml-[20px]">{timeLeft >= 0 ? time : null}</span>
            )}
          </span>
        </div>
      </div>
    </div>
  );
}

export default GameStatusBar;
