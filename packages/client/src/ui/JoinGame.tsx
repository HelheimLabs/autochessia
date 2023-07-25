"use client";
import { useState } from "react";
import { useEffect } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue, useRows } from "@latticexyz/react";
import {
  Bytes,
  formatBytes32String,
  parseBytes32String,
} from "ethers/lib/utils";

import { Input, Button, Table } from "antd";
import type { ColumnsType } from "antd/es/table";
import { BigNumberish } from "ethers";


// import { createRequire } from 'module';
// const require = createRequire(import.meta.url);
// const snarkjs = require('src/lib/snarkjs.min.js');
// import { generatePwProof } from "../snarkjsHelper/snarkjsHelper.cjs";
// import * as snarkjs from "../lib/snarkjs.min.js";

interface JoinGameProps {}

type AddressType = `0x${string}`;

interface DataType {
  key: AddressType;
  room: AddressType;
  player: AddressType;
}

const importSnarkjs = () => {
  useEffect(() => {
    const script = document.createElement('script');

    script.src = "snarkjs.min.js";
    script.async = true;
    console.log(window.location.href);

    document.body.appendChild(script);

    return () => {
      document.body.removeChild(script);
    }
  });
};

const JoinGame = ({}: JoinGameProps) => {
  importSnarkjs();
  const {
    components: { PlayerGlobal },
    systemCalls: { joinRoom, joinPrivateRoom, leaveRoom, surrender },
    network: { playerEntity, storeCache },
  } = useMUD();

  const params = new URLSearchParams(window.location.search);

  const roomId = params?.get("roomId");

  // console.log(`now roomId${roomId}`)

  const [value, setValue] = useState(roomId ?? "");

  const playerObj = useComponentValue(PlayerGlobal, playerEntity);

  const WaitingRoomList = useRows(storeCache, { table: "WaitingRoom" });

  const roomData: DataType[] = WaitingRoomList.map((item) => ({
    key: item.key.key,
    room: item.key.key,
    player: item.value.players[0],
  }));

  const joinRoomFn = async (_roomId: AddressType | null) => {
    if (_roomId) {
      await joinRoom(_roomId);
    } else {
      await joinRoom(formatBytes32String(value ?? ""));
    }
  };

  interface snarkProof {
    pi_a: BigNumberish[];
    pi_b: BigNumberish[][];
    pi_c: BigNumberish[];
  }

  const joinPrivateRoomFn = async (
    _roomId: AddressType,
    _player: AddressType,
    _password: Bytes
  ) => {
    try {
      const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        { player: _player, password: _password },
        "known_password.wasm",
        "pw_0001.zkey"
      );
      const p: snarkProof = proof as snarkProof;
      const _a: [BigNumberish, BigNumberish] = [p.pi_a[0], p.pi_a[1]];
      const _b: [[BigNumberish, BigNumberish], [BigNumberish, BigNumberish]] = [
        [p.pi_b[0][0], p.pi_b[0][1]],
        [p.pi_b[1][0], p.pi_b[1][1]],
      ];
      const _c: [BigNumberish, BigNumberish] = [p.pi_c[0], p.pi_c[1]];
      console.log(JSON.stringify(proof));
      console.log(JSON.stringify(_a));
      console.log(JSON.stringify(_b));
      console.log(JSON.stringify(_c));
      console.log(JSON.stringify(publicSignals));
      const vkey = await fetch("verification_key.json").then( function(res) {
          return res.json();
      });

      const res = await snarkjs.groth16.verify(vkey, publicSignals, proof);
      console.log(res);
    } catch (e) {
      console.error(e);
    }
  };

  const LeaveRoomFn = async (_roomId: AddressType) => {
    await leaveRoom(_roomId);
  };

  console.log(playerObj, "playerObj", WaitingRoomList);

  const onChange = (e: { target: { value: string | null } }) => {
    if (e.target.value) {
      setValue(e.target.value);
    }
  };

  const columns: ColumnsType<DataType> = [
    {
      title: "RoomId",
      dataIndex: "room",
      render: (text: AddressType) => (
        <span className=" text-orange-600">{parseBytes32String(text)}</span>
      ),
    },
    {
      title: "Player",
      dataIndex: "player",
      render: (text: AddressType) => (
        <span className=" text-cyan-400">{text}</span>
      ),
    },
    {
      title: "Action",
      key: "operation",
      render: (item) => (
        <div>
          {playerObj?.roomId === item.room ? (
            <Button onClick={() => LeaveRoomFn(item.room)}>Leave</Button>
          ) : (
            <Button onClick={() => joinRoomFn(item.room)}>Join</Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="JoinGame">
      <div className="flex justify-center items-center h-20 bg-transparent absolute top-20  left-0 right-0 z-10  ">
        {" "}
        <h1 className="text-5xl font-bold">Autochessia</h1>{" "}
      </div>
      <div className="fixed w-full h-full bg-indigo-100 flex flex-col items-center justify-center">
        <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 via-indigo-600 to-indigo-700 animate-spin"></div>
        <div className="flex justify-center mt-20">
          {/* {playerObj ?  */}
          <Input
            value={value}
            onChange={onChange}
            placeholder={"roomId"}
            defaultValue={roomId ?? ""}
          />
          <Button
            className="ml-10 cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
            onClick={() => joinRoomFn(null)}
          >
            Create Or Join
          </Button>

          <Button
            className="ml-10 cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
            // todo fill in correct _roomId, _player, and _password
            onClick={() => joinPrivateRoomFn("0x1", "0x1", [0,0,0,0,0,0,0,0,0,0])}
          >
            Join private room
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
};

export default JoinGame;
