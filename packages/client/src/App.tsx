import { useComponentValue, useRows } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
import AutoChess from "./ui/ChessMain";
import JoinGame from "./ui/JoinGame";
import "./index.css";
import { SelectNetwork } from "./ui/SelectNetwork";
import Feedback from "./ui/Feedback";

export const App = () => {
  const {
    components: { PlayerGlobal },
    systemCalls: { surrender },
    network: { playerEntity },
  } = useMUD();

  const playerObj = useComponentValue(PlayerGlobal, playerEntity);

  const isPlay = playerObj?.status == 1;

  return (
    <>
      {isPlay ? <AutoChess /> : <JoinGame />}
      <div className="absolute top-4 right-4 grid">
        <SelectNetwork />
        <button
          className="flex items-center px-3 py-1 mt-1 text-white bg-gray-500 rounded hover:bg-gray-600"
          onClick={() => surrender()}
        >
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
            <path d="M17.114,3.923h-4.589V2.527c0-0.252-0.207-0.459-0.46-0.459H7.935c-0.252,0-0.459,0.207-0.459,0.459v1.396h-4.59c-0.252,0-0.459,0.205-0.459,0.459c0,0.252,0.207,0.459,0.459,0.459h1.51v12.732c0,0.252,0.207,0.459,0.459,0.459h10.29c0.254,0,0.459-0.207,0.459-0.459V4.841h1.511c0.252,0,0.459-0.207,0.459-0.459C17.573,4.127,17.366,3.923,17.114,3.923M8.394,2.527c0-0.253,0.205-0.459,0.459-0.459h4.059c0.252,0,0.459,0.206,0.459,0.459v1.396h-4.059V2.527z M16.971,16.015c0,0.253-0.205,0.459-0.459,0.459H5.502c-0.253,0-0.459-0.206-0.459-0.459V4.841h11.469V16.015z M13.882,8.732c0-0.253,0.205-0.459,0.459-0.459c0.253,0,0.458,0.206,0.458,0.459v4.059c0,0.252-0.205,0.459-0.458,0.459c-0.253,0-0.459-0.207-0.459-0.459V8.732z M12.948,13.917c0.124-0.125,0.124-0.329,0-0.453l-1.918-1.918c-0.124-0.125-0.33-0.125-0.452,0s-0.125,0.33,0,0.453l1.918,1.918c0.124,0.125,0.33,0.125,0.452,0S12.848,14.042,12.948,13.917z" />
          </svg>

          <span className="ml-2">Reset</span>
        </button>
      </div>
      <Feedback />
    </>
  );
};
