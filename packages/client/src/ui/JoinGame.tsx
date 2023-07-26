"use client";
import { useState } from "react";
import { useEffect } from 'react';
import { useMUD } from "../MUDContext";
import { useComponentValue, useRows } from "@latticexyz/react";
import {
  Bytes,
  BytesLike,
  arrayify,
  concat,
  formatBytes32String,
  hexlify,
  parseBytes32String,
  sha256,
  toUtf8Bytes,
} from "ethers/lib/utils";

import { Input, Button, Table, Modal, message } from "antd";
import type { ColumnsType } from "antd/es/table";
import { BigNumberish } from "ethers";

interface JoinGameProps { }

type AddressType = `0x${string}`;

interface DataType {
  key: AddressType;
  room: AddressType;
  players: AddressType[];
  seatNum: number;
  withPassword: boolean;
}

const importSnarkjs = () => {
  useEffect(() => {
    const script = document.createElement('script');

    script.src = "snarkjs.min.js";
    script.async = true;

    document.body.appendChild(script);

    return () => {
      document.body.removeChild(script);
    }
  });
};

const JoinGame = ({ }: JoinGameProps) => {
  importSnarkjs();
  const {
    components: { PlayerGlobal },
    systemCalls: { createRoom, joinRoom, joinPrivateRoom, leaveRoom, startGame },
    network: { playerEntity, storeCache, localAccount },
  } = useMUD();

  const params = new URLSearchParams(window.location.search);

  const roomId = params?.get("roomId");

  // console.log(`now roomId${roomId}`)
  const [messageApi, contextHolder] = message.useMessage();

  const [value, setValue] = useState(roomId ?? "");
  const [seatNum, setSeatNum] = useState(2);
  const [password, setPassword] = useState("");

  const playerObj = useComponentValue(PlayerGlobal, playerEntity);

  const WaitingRoomList = useRows(storeCache, { table: "WaitingRoom" });

  const roomData: DataType[] = WaitingRoomList.map((item) => ({
    key: item.key.key,
    room: item.key.key,
    players: item.value.players,
    seatNum: item.value.seatNum,
    withPassword: item.value.withPassword
  }));

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isPrivateOpen, setIsPrivateOpen] = useState<DataType | null>(null);

  const showModal = () => {
    setIsModalOpen(true);
  };

  const handleOk = () => {
    setIsModalOpen(false);
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };

  const joinRoomFn = async (_roomId: AddressType | null) => {
    if (_roomId) {
      await joinRoom(_roomId);
    } else {
      await joinRoom(formatBytes32String(value ?? ""));
    }
  };

  const parsePassword = (_password: string) => {
    const pw = concat([toUtf8Bytes(_password), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]).slice(0, 10);
    let res = new Array<number>;
    for (var i = 0; i < pw.length; i++) {
      res[i] = pw[i];
    }
    return res;
  }

  const createRoomFn = async (_roomId: string, _seatNum: number, _password: string) => {
    if (_roomId != "") {
      console.log(hexlify(parsePassword(_password)));
      console.log(sha256(parsePassword(_password)));
      const pwd = _password ? sha256(parsePassword(_password)) : formatBytes32String('')
      await createRoom(formatBytes32String(_roomId), _seatNum, pwd);
      setIsModalOpen(false)
      messageApi.open({
        type: 'success',
        content: 'Create Room Success!',
      });
    }
  }

  interface snarkProof {
    pi_a: BigNumberish[];
    pi_b: BigNumberish[][];
    pi_c: BigNumberish[];
  }

  const joinPrivateRoomFn = async (
    _roomId: string,
    _player: AddressType,
    _password: string
  ) => {
    try {
      const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        { player: _player, password: parsePassword(_password) },
        "known_password.wasm",
        "password.zkey"
      );
      const p: snarkProof = proof as snarkProof;
      const _a: [BigNumberish, BigNumberish] = [p.pi_a[0], p.pi_a[1]];
      const _b: [[BigNumberish, BigNumberish], [BigNumberish, BigNumberish]] = [
        [p.pi_b[0][1], p.pi_b[0][0]],
        [p.pi_b[1][1], p.pi_b[1][0]],
      ];
      const _c: [BigNumberish, BigNumberish] = [p.pi_c[0], p.pi_c[1]];
      // console.log(JSON.stringify(_a));
      // console.log(JSON.stringify(_b));
      // console.log(JSON.stringify(_c));
      // console.log(JSON.stringify(publicSignals));
      const vkey = await fetch("verification_key_password.json").then(function (res) {
        return res.json();
      });

      const res = await snarkjs.groth16.verify(vkey, publicSignals, proof);
      if (res as boolean) {
        console.log("valid proof generated");
        try {
          await joinPrivateRoom(_roomId, _a, _b, _c);
          setIsPrivateOpen(null)
        } catch (error) {
          console.error(error, JSON.stringify(error), error.message);
          const match = error.message.match(/execution reverted: (.+?)"/);
          messageApi.open({
            type: 'error',
            content: match[1],
          });
        }
      }

    } catch (e) {
      console.error(e);
    }
  };

  const LeaveRoomFn = async (_roomId: AddressType, _index: number) => {
    await leaveRoom(_roomId, _index);
  };

  // console.log(playerObj, "playerObj", WaitingRoomList);

  const onChange = (e: { target: { value: string } }) => {

    setValue(e.target.value);

  };

  const disabled = !!(playerObj?.roomId && (parseBytes32String(playerObj?.roomId as BytesLike) != ''))


  const columns: ColumnsType<DataType> = [
    {
      title: "RoomName",
      dataIndex: "room",
      render: (text: AddressType) => (
        <span className=" text-orange-600">{parseBytes32String(text)}</span>
      ),
    },
    {
      title: "Players",
      dataIndex: "players",
      width: 380,
      render: (players: AddressType[]) => (
        <div className="grid">
          {players?.map((player: AddressType) => <span key={player} className={` ${player == localAccount ? ' text-red-600' : 'text-cyan-400'}`}>{player}</span>)}
        </div>
      ),
    },
    {
      title: "Online",
      dataIndex: "seatNum",
      render: (seatNum: AddressType[], item) => (
        <div className="flex">
          <span className="text-center"> {item.players.length}/{seatNum}</span>
          <span className="ml-1">{item.withPassword ? '🔒' : ''}</span>
        </div>
      ),
    },
    {
      title: "Action",
      key: "room",
      render: (item: DataType,) => (
        <div>
          {playerObj?.roomId === item.room ? (
            <>
              <Button onClick={() => LeaveRoomFn(item.room, item.players.findIndex((player: string) => player == localAccount))}>Leave</Button>
              {item.players[0] == localAccount && <Button onClick={() => startGame(item.room)}>StartGame</Button>}
            </>

          ) : (
            item.withPassword
              ? <Button disabled={disabled} onClick={() => setIsPrivateOpen(item)}>Join</Button>
              : <Button disabled={disabled} onClick={() => joinRoomFn(item.room)}>Join</Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <>
      {contextHolder}
      <div className="JoinGame">
        <div className="flex justify-center items-center h-20 bg-transparent absolute top-20  left-0 right-0 z-10  ">
          <h1 className="text-5xl font-bold">Autochessia</h1>
        </div>
        <div className="fixed w-full h-full bg-indigo-100 flex flex-col items-center justify-center">
          <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 via-indigo-600 to-indigo-700 animate-spin"></div>
          <div className="flex justify-center mt-20">
            <Button
              className="cursor-pointer btn bg-blue-500  text-white font-bold  px-4 rounded"
              onClick={showModal}
              disabled={disabled}
            >
              ➕ Create Room
            </Button>
            {/* : 'loading...'
          } */}
          </div>
          <div className="mt-20">
            <Table columns={columns} dataSource={roomData} pagination={false} />
          </div>
          <Modal wrapClassName="room-setting" footer={null} title="Create Room Setting" open={isModalOpen} onOk={handleOk} onCancel={handleCancel}>
            <div className="flex flex-col space-y-4">
              <Input
                value={value}
                onChange={onChange}
                placeholder={"RoomName"}
              />
              <Input
                value={seatNum}
                onChange={e => setSeatNum(e.target.value as unknown as number)}
                min={2}
                type="number"
                placeholder={"seatNum"}
              />
              <Input
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder={"password"}
                maxLength={10}
                defaultValue={password ?? ""}
              />
              <Button
                className="ml-[350px] cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
                onClick={() => createRoomFn(value, Number(seatNum), password)}
              >
                Create Room
              </Button>

            </div>

          </Modal>

          <Modal wrapClassName="room-setting" footer={null} title="Join Private Room" open={isPrivateOpen!!} onCancel={() => setIsPrivateOpen(null)}>
            <div className="flex flex-col space-y-4">
              <Input
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder={"password"}
                maxLength={10}
                defaultValue={password ?? ""}
              />
              <Button
                className="ml-[350px] cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
                // todo fill in correct _roomId, _player, and _password
                onClick={() => joinPrivateRoomFn(isPrivateOpen!.room, localAccount as AddressType, password)}
              >
                Join
              </Button>
            </div>

          </Modal>


        </div>
      </div >
    </>

  );
};

export default JoinGame;
