'use client'
import React, { useMemo, useState } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { formatBytes32String } from 'ethers/lib/utils';

import { Input } from 'antd';

interface JoinGameProps {
}

enum PlayerStatus {
  "UNINITIATED",
  "INGAME"
}

const JoinGame = ({ }: JoinGameProps) => {

  const {
    components: { Counter, Board, Game, PieceInBattle, Piece, Creatures, CreatureConfig, Player, ShopConfig, GameConfig },
    systemCalls: { increment, joinRoom, autoBattle, buyRefreshHero, buyHero, sellHero, buyExp, placeToBoard, changePieceCoordinate, placeBackInventory },
    network: { singletonEntity, localAccount, playerEntity, network, storeCache },
  } = useMUD();


  const params = new URLSearchParams(window.location.search);

  const roomId=params?.get("roomId")

  console.log(`now roomId${roomId}`)

  const [value, setValue] = useState(roomId??'')


  const playerObj = useComponentValue(Player, playerEntity);

  const joinRoomFn = async () => {
    await joinRoom(formatBytes32String(value??''))
  }

  console.log(playerObj, 'playerObj')

  const status = Object.keys(PlayerStatus).find(key => {
    return PlayerStatus[key] === playerObj?.status
  })

  // const status = playerObj?.status as PlayerStatus

  const onChange = (e: { target: { value: React.SetStateAction<string | null>; }; }) => {
    setValue(e.target.value)
  }

  return (
    <div className="JoinGame">
      <div className="flex justify-center items-center h-20 bg-transparent absolute top-20  left-0 right-0 z-10  "> <h1 className="text-5xl font-bold">Autochessia</h1> </div>
      <div className="absolute top-0 left-0">{status}</div>
      <div className="fixed w-full h-full bg-indigo-100 flex flex-col items-center justify-center">
        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 via-indigo-600 to-indigo-700 animate-spin"></div>
        <div className="flex justify-center mt-20">
          {/* {playerObj ?  */}
          <Input value={value} onChange={onChange} placeholder={'roomId'} defaultValue={roomId ?? ''} />
          <div
            className="ml-10 cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            onClick={joinRoomFn}
          >
            join
          </div>
          {/* : 'loading...'
          } */}
        </div>
      </div>
    </div>
  );
}

export default JoinGame;