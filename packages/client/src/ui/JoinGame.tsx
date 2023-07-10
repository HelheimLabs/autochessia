'use client'
import React, { useMemo, useState } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue, useRows } from "@latticexyz/react";
import { formatBytes32String, parseBytes32String } from 'ethers/lib/utils';

import { Input, Button, Table } from 'antd';
import type { ColumnsType } from 'antd/es/table';

interface JoinGameProps {
}

type AddressType = `0x${string}`;

interface DataType {
  key: AddressType;
  room: AddressType;
  player: AddressType;
}


const JoinGame = ({ }: JoinGameProps) => {

  const {
    components: { Player },
    systemCalls: { joinRoom, leaveRoom },
    network: { playerEntity, storeCache },
  } = useMUD();


  const params = new URLSearchParams(window.location.search);

  const roomId = params?.get("roomId")

  // console.log(`now roomId${roomId}`)

  const [value, setValue] = useState(roomId ?? '')


  const playerObj = useComponentValue(Player, playerEntity);

  const WaitingRoomList = useRows(storeCache, { table: "WaitingRoom" });

  const roomData: DataType[] = WaitingRoomList.map(item => ({
    key: item.key.key,
    room: item.key.key,
    player: item.value.player1
  }))

  const joinRoomFn = async (_roomId: AddressType | null) => {
    if (_roomId) {
      await joinRoom(_roomId)

    } else {
      await joinRoom(formatBytes32String(value ?? ''))
    }
  }

  const LeaveRoomFn = async (_roomId: AddressType) => {
    await leaveRoom(_roomId)
  }


  console.log(playerObj, 'playerObj', WaitingRoomList)


  const onChange = (e: { target: { value: string | null }; }) => {
    if (e.target.value) {
      setValue(e.target.value);
    }
  }

  const columns: ColumnsType<DataType> = [
    {
      title: 'RoomId',
      dataIndex: 'room',
      render: (text: AddressType) => <span className=' text-orange-600'>{parseBytes32String(text)}</span>
    },
    {
      title: 'Player',
      dataIndex: 'player',
      render: (text: AddressType) => <span className=' text-cyan-400'>{(text)}</span>

    },
    {
      title: 'Action',
      key: 'operation',
      render: (item) => (
        <div>
          {playerObj?.roomId === item.room
            ? <Button onClick={() => LeaveRoomFn(item.room)}>Leave</Button>
            : <Button onClick={() => joinRoomFn(item.room)}>Join</Button>
          }
        </div>
      )
    },
  ];

  return (
    <div className="JoinGame">
      <div className="flex justify-center items-center h-20 bg-transparent absolute top-20  left-0 right-0 z-10  "> <h1 className="text-5xl font-bold">Autochessia</h1> </div>
      <div className="fixed w-full h-full bg-indigo-100 flex flex-col items-center justify-center">
        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 via-indigo-600 to-indigo-700 animate-spin"></div>
        <div className="flex justify-center mt-20">
          {/* {playerObj ?  */}
          <Input value={value} onChange={onChange} placeholder={'roomId'} defaultValue={roomId ?? ''} />
          <Button
            className="ml-10 cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
            onClick={() => joinRoomFn(null)}
          >
            Create Or Join
          </Button>
          {/* : 'loading...'
          } */}
        </div>
        <div className="mt-20">
          <Table columns={columns} dataSource={roomData} pagination={false} />
        </div>
      </div>
    </div>
  );
}

export default JoinGame;