import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useEffect, useState } from "react";

export function useBoardStatus() {
  const {
    components: { Board },
    network: { playerEntity },
  } = useMUD();

  const BoardList = useComponentValue(Board, playerEntity);

  const [currentBoardStatus, setCurrentBoardStatus] = useState(0);
  useEffect(() => {
    setCurrentBoardStatus(BoardList?.status || 0);
  }, [BoardList, BoardList?.status]);

  return { currentBoardStatus };
}
