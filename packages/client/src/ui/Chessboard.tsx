import React, { useMemo, useState, useRef, useEffect, Children } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue, useRows } from "@latticexyz/react";
import { useDrop, useDrag } from 'ahooks';

import { convertToPos, convertToIndex } from '../lib/ulits'

import { Progress, Tooltip } from 'antd';
import { red, green, blue } from '@ant-design/colors';

import './Chessboard.css';
import { srcObjType } from './ChessMain';

type ListType = {
  curHealth: number
  creature: number,
  tier: number,
  x: number,
  y: number
  pieceId: string
}

interface ChessboardProps {
  piecesList: ListType[]
  srcList: string[]
  squares: any[]
  enemyListLast: ListType[]
  srcObj: srcObjType
}

enum BoardStatus {
  "UNINITIATED",
  "INBATTLE",
  "FINISHED"
}

const DragItem = ({ data, children }) => {
  const dragRef = useRef(null);


  useDrag(data, dragRef, {
    onDragStart: (e) => {
    },
    onDragEnd: (e) => {
    },
  });
  return (
    <div
      ref={dragRef}
    >
      {children}
    </div>
  );
};

const Chessboard = (props: ChessboardProps) => {

  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig, WaitingRoom },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory, checkCorValidity },
    network: { singletonEntity, localAccount, playerEntity, network, singletonEntityId, storeCache },
  } = useMUD();



  const playerObj = useComponentValue(Player, playerEntity);


  const { piecesList,  enemyListLast,  srcObj } = props

  // console.log(props)

  const [squares, setSquares] = useState<ListType | any>(Array(64).fill(null))

  const [fullHealth, setFullHealth] = useState()


  const BoardObj = useComponentValue(Board, playerEntity);


  useEffect(() => {

    if (BoardObj?.status !== 1) {

      let newFullHealthArr: ListType[] = [...piecesList, ...enemyListLast]
      let newFullHealth: React.SetStateAction<any> = []
      newFullHealthArr.forEach((item: ListType) => {
        newFullHealth.push({
          id: [item.pieceId],
          value: item.curHealth
        })
      })

      setFullHealth(newFullHealth)
    }

  }, [BoardObj?.status, enemyListLast, piecesList])

  const dropRef = useRef(null);

  useDrop(dropRef, {
    
    onDom: (content: string, e) => {
      const index = (e as any).srcElement.dataset.index
      const [x, y] = convertToPos(index)
      if (content?.index>=0) {
        placeToBoard(content.index, x, y)

      }else{
        const moveIndex=piecesList.findIndex(item => item.pieceId== content.pieceId) 
        changePieceCoordinate(moveIndex, x, y)
      }

    },
   
  });

 

  useEffect(() => {
    const changeSquares = () => {

      let newSquares = Array(64).fill(null)


      piecesList?.map(item => {
        const position = convertToIndex(item.x, item.y)

        newSquares[position] = {
          ...item,
          fullHealth: fullHealth?.find((heal: { id: string; }) => heal.id == item.pieceId)?.value,
        }
      })

      props.enemyListLast?.map(item => {
        const position = convertToIndex(item.x, item.y)

        newSquares[position] = {
          enemy: true,
          // fullHealth: item.curHealth,
          fullHealth: fullHealth?.find((heal: { id: string; }) => heal.id == item.pieceId)?.value,
          ...item
        }
      })



      setSquares(newSquares)
    }

    changeSquares()


    return () => { }

  }, [ piecesList, enemyListLast, fullHealth])

  const renderSquare = (i) => {
    const [x] = convertToPos(i)
    const className =
      x < 4 ?
        'bg-slate-50' :    // left
        'bg-green-200';  // right

    const percent = squares[i] && Number((squares[i]?.['curHealth']) / (squares[i]?.['fullHealth'])) * 100
    let src = ''
    let strokeColor = ''
    if (squares[i]) {
      src = srcObj.perUrl + squares[i]['creature'] + srcObj.color
      strokeColor = squares[i]['enemy'] ? red[5] : blue[5]
    }

    return (
      <div
        key={i}
        className={`   ${className} square  `}
        data-index={i}
      >
        {squares[i]&&percent ?
          <DragItem key={i} data={squares[i]} >

            <Tooltip title={`HP ${squares[i]?.['curHealth']}`}>
              <div className="relative">
                <div className=" absolute  -top-5 -left-1">
                  <Progress status="active" showInfo={false} percent={percent} steps={5} strokeColor={strokeColor} />
                </div>
                <img src={src} data-index={i} alt={squares[i]['pieceId']} style={{ width: 80, }} />
                <div className="flex items-center justify-center ">
                  <div className="text-yellow-400  text-sm absolute top-0 -left-0">
                    {Array(squares[i]['tier'] + 1).fill(null)?.map((item, index) => (
                      <span className="" key={index}>&#9733;</span>
                    ))}
                  </div>
                </div>
              </div>
            </Tooltip>
          </DragItem>
          : null}
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

    return board;
  }, [squares])

  return (
    <div className="board " ref={dropRef}>
      {renderBoard}
    </div>
  );
}

export default Chessboard;