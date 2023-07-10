import { useComponentValue, useRows } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
import AutoChess from "./ui/ChessMain";
import JoinGame from "./ui/JoinGame";
import "./index.css";
import { SelectNetwork } from "./ui/SelectNetwork";

export const App = () => {
  const {
    components: {
      Player,
    },
    network: {
      playerEntity,
    },
  } = useMUD();

  const playerObj = useComponentValue(Player, playerEntity);

  const isPlay = playerObj?.status == 1;


  return (
    <>
      {isPlay ? <AutoChess /> : <JoinGame />}
      <div className="absolute top-4 right-4">
        <SelectNetwork />
      </div>
    </>
  );
};
