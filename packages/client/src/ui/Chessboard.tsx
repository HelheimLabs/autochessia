import { useMemo, useState, useRef, useEffect } from "react";
import { useDrop, useDrag } from "ahooks";

import { convertToPos, convertToIndex } from "../lib/utils";

import { Progress, Tooltip } from "antd";

import "./Chessboard.css";
import { boardInterface } from "./ChessMain";

import useChessboard from "@/hooks/useChessboard";

interface ListType extends boardInterface {
  curHealth?: number;
  creature?: number;
  attack: number;
  defense: number;
  health: number;
  movement: number;
  range: number;
  speed: number;
  tier: number;
  x: number;
  y: number;
  creatureId: string;
}

const DragItem = ({ data, children }) => {
  const dragRef = useRef(null);

  useDrag(data, dragRef, {
    onDragStart: () => {},
    onDragEnd: () => {},
  });
  return <div ref={dragRef}>{children}</div>;
};

const Chessboard = ({ setAcHeroFn }: { setAcHeroFn: (any) => void }) => {
  const {
    PiecesList,
    BattlePieceList,
    placeToBoard,
    changeHeroCoordinate,
    currentBoardStatus = 0,
    BoardList,
  } = useChessboard();

  const turn = (BoardList?.turn as number) || 0;

  const dropRef = useRef(null);

  const [dragIng, setDragIng] = useState(false);

  useDrop(dropRef, {
    onDom: (content: any, e) => {
      if (currentBoardStatus !== 0) {
        return;
      }
      const index = (e as any).srcElement.dataset.index;
      const [x, y] = convertToPos(index);

      if (x > 3) {
        return;
      }

      if (content?.index >= 0) {
        placeToBoard(content.index, x, y);
      } else {
        // const moveIndex = PiecesList?.findIndex(item => item.creatureId == content.creatureId)
        changeHeroCoordinate(content._index!, x, y);
      }
    },

    onDragEnter: (e) => {
      // if (currentBoardStatus !== 0) {
      //   return;
      // }
      if (!dragIng && !BattlePieceList.length) {
        setDragIng(true);
      }
    },
    onDrop: (e) => {
      // console.log(currentBoardStatus);
      // if (currentBoardStatus !== 0) {
      //   return;
      // }
      setDragIng(false);
    },
    onDragLeave: (e) => {
      setDragIng(false);
    },
  });

  const squares = useMemo(() => {
    const newSquares = Array(64).fill(null);
    if (BattlePieceList?.length) {
      BattlePieceList?.map((item) => {
        const position = convertToIndex(item.x, item.y);
        newSquares[position] = {
          ...item,
        };
      });
    } else {
      PiecesList?.map((item) => {
        if (!item) {
          return;
        }
        const position = convertToIndex(item.x, item.y);
        newSquares[position] = {
          ...item,
        };
      });
    }
    return newSquares;
  }, [PiecesList, BattlePieceList]);

  const renderSquare = (i) => {
    const [x, y] = convertToPos(i);
    const className = dragIng
      ? x < 4
        ? "draging" // left
        : "bg-red-600" // right
      : "";

    const percent =
      squares[i] &&
      Number(
        squares[i]?.["health"] /
          (squares[i]?.["maxHealth"] || squares[i]?.["health"])
      ) * 100;
    let src = "";
    let strokeColor = "";
    if (squares[i]) {
      src = squares[i]["image"];
      strokeColor = squares[i]["enemy"] ? "red" : "#4096ff";
    }
    // console.log(squares[i]);

    const showHP =
      BattlePieceList?.length > 0 ? `HP ${squares[i]?.["health"]}` : null;
    // `HP ${squares[i]?.["maxHealth"]}`;

    const dynamicKey = i + "key" + squares[i]?.["health"] + turn;

    return (
      <div key={dynamicKey} className={`${className} square `} data-index={i}>
        {squares[i] && percent ? (
          <DragItem key={i} data={squares[i]}>
            <Tooltip title={showHP}>
              <div
                className="relative animate-shake-horizontal"
                onClick={() => setAcHeroFn(squares[i])}
              >
                <div className=" absolute  -top-5 -left-1">
                  <Progress
                    status="active"
                    showInfo={false}
                    percent={percent}
                    steps={5}
                    strokeColor={strokeColor}
                  />
                </div>
                <img
                  src={src}
                  data-index={i}
                  alt={squares[i]["creatureId"]}
                  style={{ width: 80 }}
                />
                <div className="flex items-center justify-center ">
                  <div className="text-yellow-400  text-sm absolute top-0 -left-0">
                    {Array(Number(squares[i]["tier"]))
                      .fill(null)
                      ?.map((item, index) => (
                        <span className="" key={index}>
                          &#9733;
                        </span>
                      ))}
                  </div>
                </div>
              </div>
            </Tooltip>
          </DragItem>
        ) : null}
      </div>
    );
  };

  const renderBoard = useMemo(() => {
    const board = [];
    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 8; j++) {
        board.push(renderSquare(i * 8 + j));
      }
    }

    return board;
  }, [squares]);

  return (
    <div className="relative">
      <div className="board" ref={dropRef}>
        {renderBoard}
      </div>
      {/* <div className="board-bg absolute left-0 top-0"></div> */}
    </div>
  );
};

export default Chessboard;
