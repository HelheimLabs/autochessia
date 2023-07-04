import React, { useMemo, useState, useRef, useEffect } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue, useRows } from "@latticexyz/react";
import { useDrop, useDrag } from 'ahooks';

import { convertToPos, convertToIndex } from '../lib/ulits'


import './Chessboard.css';

type ListType = {
  creature: number,
  tier: number,
  x: number,
  y: number
}

interface ChessboardProps {
  piecesList: ListType[]
  srcList: string[]
  squares: any[]
  enemyListLast: ListType[]
}

const Chessboard = (props: ChessboardProps) => {

  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig, WaitingRoom },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory, checkCorValidity },
    network: { singletonEntity, localAccount, playerEntity, network, singletonEntityId, storeCache },
  } = useMUD();

  console.log(props, 'props Chessboard')

  const { piecesList, squares: oriSquares, enemyListLast, srcList } = props

  const [squares, setSquares] = useState(Array(64).fill(null))

  const [isHovering, setIsHovering] = useState(false);

  const dropRef = useRef(null);

  useDrop(dropRef, {
    onText: (text, e) => {
      console.log(e);
      alert(`'text: ${text}' dropped`);
    },
    onFiles: (files, e) => {
      console.log(e, files);
      alert(`${files.length} file dropped`);
    },
    onUri: (uri, e) => {
      console.log(e);
      alert(`uri: ${uri} dropped`);
    },
    onDom: (content: string, e) => {
      // alert(`custom: ${content} dropped`);
      const index = (e as any).srcElement.dataset.index
      console.log(index, content)
      const [x, y] = convertToPos(index)
      placeToBoard(content.index, x, y)

    },
    onDragEnter: () => setIsHovering(true),
    onDragLeave: () => setIsHovering(false),
  });

  console.log(isHovering, 'isHovering')

  const playerObj = useComponentValue(Player, playerEntity);

  // const squares = props.squares

  useEffect(() => {
    console.log(1)
    const changeSquares = () => {

      let newSquares = Array(64).fill(null)


      piecesList?.map(item => {
        const position = convertToIndex(item.x, item.y)

        newSquares[position] = {
          src: props.srcList[item.creature]
        }
      })
      console.log(newSquares)

      props.enemyListLast?.map(item => {
        const position = convertToIndex(item.x, item.y)

        newSquares[position] = {
          src: props.srcList[item.creature],
          enemy: true
        }
      })
      console.log(newSquares)



      setSquares(newSquares)
    }

    changeSquares()


    return () => { }

  }, [oriSquares, piecesList, enemyListLast, srcList])

  const renderSquare = (i) => {
    const [x] = convertToPos(i)
    const className =
      x < 4 ?
        'bg-zinc-600' :    // 左边
        'even-square';  // 右边
    return (
      <div
        key={i}
        className={`${className} square ${squares[i] === 'X' ? 'black' : ''}`}
        data-index={i}
      // onClick={() => handleClick(i)}
      >
        {squares[i] ? <img src={`${squares[i]['src']}`} alt={squares[i]['src'].name} style={{ width: 50, opacity: squares[i]['enemy'] ? 0.5 : 1 }} /> : null}
      </div>
    );
  }

  const renderBoard = useMemo(() => {
    const board = [];
    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 8; j++) {
        board.push(renderSquare(i * 8 + j));
      }
    }
    console.log({ squares })

    return board;
  }, [squares])

  return (
    <div className="board " ref={dropRef}>
      {renderBoard}
    </div>
  );
}

export default Chessboard;