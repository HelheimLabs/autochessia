"use client";
import { useState } from "react";
import { useEffect } from "react";
import { useMUD } from "../MUDContext";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Entity, getComponentValueStrict, Has } from "@latticexyz/recs";
import {
  BytesLike,
  concat,
  formatBytes32String,
  parseBytes32String,
  sha256,
  toUtf8Bytes,
} from "ethers/lib/utils";
import { Input, Button, Table, Modal, message, Tooltip } from "antd";
import type { ColumnsType } from "antd/es/table";
import { BigNumberish } from "ethers";
import { shortenAddress } from "../lib/utils";
import { Hex, numberToHex, stringToHex, toHex } from "viem";
import { useSetState } from "react-use";
import Logo from "/assets/logo.png";
import dayjs from "dayjs";
import relativeTime from "dayjs/plugin/relativeTime";

dayjs.extend(relativeTime);

type AddressType = `0x${string}`;

interface DataType {
  name: Entity;
  seatNum: number;
  withPassword: boolean;
  createdAtBlock: bigint;
  updatedAtBlock: bigint;
  players: string[];
  key: Entity;
  room: Entity;
}

const importSnarkjs = () => {
  useEffect(() => {
    const script = document.createElement("script");

    script.src = "snarkjs.min.js";
    script.async = true;

    document.body.appendChild(script);

    return () => {
      document.body.removeChild(script);
    };
  });
};

const JoinGame = (/**{}: JoinGameProps */) => {
  importSnarkjs();
  const {
    components: { PlayerGlobal, WaitingRoom },
    systemCalls: {
      createRoom,
      joinRoom,
      joinPrivateRoom,
      leaveRoom,
      startGame,
    },
    network: { playerEntity, localAccount },
  } = useMUD();

  const params = new URLSearchParams(window.location.search);

  const roomId = params?.get("roomId");

  const [messageApi, contextHolder] = message.useMessage();

  const [value, setValue] = useState(roomId ?? "");
  const [seatNum, setSeatNum] = useState(8);
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useSetState<{
    createRoom: boolean;
    joinRoom: boolean;
    leaveRoom: boolean;
    startGame: boolean;
  }>({
    createRoom: false,
    joinRoom: false,
    leaveRoom: false,
    startGame: false,
  });

  const playerObj = useComponentValue(PlayerGlobal, playerEntity);

  const WaitingRoomLists = useEntityQuery([Has(WaitingRoom)]);
  const WaitingRoomList = WaitingRoomLists.map((room) => {
    return {
      ...getComponentValueStrict(WaitingRoom, room),
      room,
    };
  });

  const roomData = WaitingRoomList?.map((item) => {
    return {
      key: item.room,
      ...item,
    };
  })?.sort((a, b) => Number(b.updatedAtBlock) - Number(a.updatedAtBlock));

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isPrivateOpen, setIsPrivateOpen] = useState<DataType | undefined>(
    undefined
  );

  const showModal = () => {
    setIsModalOpen(true);
  };

  const handleOk = () => {
    setIsModalOpen(false);
  };

  const handleCancel = () => {
    setIsModalOpen(false);
  };

  const startGameFn = (roomId: string) => {
    setLoading({ startGame: true });
    startGame(roomId).finally(() => {
      setLoading({ startGame: false });
    });
  };

  const joinRoomFn = async (_roomId: AddressType | null) => {
    setLoading({ joinRoom: true });
    if (_roomId) {
      joinRoom(_roomId).finally(() => {
        setLoading({ joinRoom: false });
      });
    } else {
      joinRoom(formatBytes32String(value ?? "")).finally(() => {
        setLoading({ joinRoom: false });
      });
    }
  };

  const parsePassword = (_password: string) => {
    const pw = concat([
      toUtf8Bytes(_password),
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]).slice(0, 10);
    const res = new Array<number>();
    for (let i = 0; i < pw.length; i++) {
      res[i] = pw[i];
    }
    return res;
  };

  const createRoomFn = async (
    _roomId: string,
    _seatNum: number,
    _password: string
  ) => {
    if (_roomId !== "") {
      setLoading({ createRoom: true });

      const pwd = _password
        ? (sha256(parsePassword(_password)) as Hex)
        : numberToHex(0, { size: 32 });
      createRoom(stringToHex(_roomId, { size: 32 }), _seatNum, pwd)
        .then(() => {
          messageApi.open({
            type: "success",
            content: "Create Room Success!",
          });
        })
        .catch((error) => {
          messageApi.open({
            type: "error",
            content: error?.message,
          });
        })
        .finally(() => {
          setLoading({ createRoom: false });
          setIsModalOpen(false);
        });
    }
  };

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
    setLoading({ joinRoom: true });

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

    const vkey = await fetch("verification_key_password.json").then(function (
      res
    ) {
      return res.json();
    });

    const res = await snarkjs.groth16.verify(vkey, publicSignals, proof);
    if (res as boolean) {
      joinPrivateRoom(_roomId, _a, _b, _c)
        .catch((error) => {
          messageApi.open({
            type: "error",
            content: error.message,
          });
        })
        .finally(() => {
          setLoading({ joinRoom: false });
          setIsPrivateOpen(undefined);
        });
    }
  };

  const LeaveRoomFn = async (_roomId: AddressType, _index: bigint) => {
    setLoading({ leaveRoom: true });
    leaveRoom(_roomId, _index).finally(() => {
      setLoading({ leaveRoom: false });
    });
  };

  const onChange = (e: { target: { value: string } }) => {
    setValue(e.target.value);
  };

  const disabled = !!(
    playerObj?.roomId &&
    parseBytes32String(playerObj?.roomId as BytesLike) != ""
  );

  const columns: ColumnsType<DataType> = [
    {
      title: "RoomName",
      dataIndex: "room",
      render: (text: AddressType) => (
        <span className=" text-orange-600 text-xl">
          {parseBytes32String(text)}
        </span>
      ),
    },
    {
      title: "Players",
      dataIndex: "players",
      width: "auto",
      render: (players: AddressType[]) => (
        <div className="grid">
          {players?.map((player: AddressType) => (
            <Tooltip key={player} title={player}>
              <span
                className={` ${
                  player == localAccount ? " text-red-600" : "text-cyan-400"
                }`}
              >
                {shortenAddress(player)}
                {player == localAccount && "🧙"}
              </span>
            </Tooltip>
          ))}
        </div>
      ),
    },
    {
      title: "Online",
      dataIndex: "seatNum",
      render: (seatNum: AddressType[], item) => (
        <div className="flex">
          <span className="text-center">
            {" "}
            {item.players?.length}/{seatNum}
          </span>
          <span className="ml-1">{item.withPassword ? "🔒" : ""}</span>
        </div>
      ),
    },
    {
      title: "UpdateTime",
      dataIndex: "updatedAtBlock",
      render: (text: any) => (
        <div className="d-none d-sm-block text-end ms-2 ms-sm-0">
          <Tooltip
            title={dayjs(Number(text) * 1000).format("YYYY-MM-DD HH:mm:ss")}
          >
            <span className="rounded border border-teal-400 text-gray-700 py-1.5 px-2">
              {dayjs(Number(text) * 1000).fromNow()}
            </span>
          </Tooltip>
        </div>
      ),
    },
    {
      title: "createdTime",
      dataIndex: "createdAtBlock",
      render: (text: any) => (
        <div className="d-none d-sm-block text-end ms-2 ms-sm-0">
          <Tooltip
            title={dayjs(Number(text) * 1000).format("YYYY-MM-DD HH:mm:ss")}
          >
            <span className="rounded border border-teal-400 text-gray-700 py-1.5 px-2">
              {dayjs(Number(text) * 1000).fromNow()}
            </span>
          </Tooltip>
        </div>
      ),
    },
    {
      title: "Action",
      key: "room",
      render: (item: DataType) => {
        const Leave = (
          <Button
            loading={loading.leaveRoom}
            type="primary"
            onClick={() => {
              LeaveRoomFn(
                item.room as `0x${string}`,
                item.players?.findIndex(
                  (player: string) => player == localAccount
                ) as unknown as bigint
              );
            }}
          >
            Leave
          </Button>
        );

        const StartGame = item.players?.[0] == localAccount && (
          <Button
            loading={loading.startGame}
            type="primary"
            className="ml-2"
            onClick={() => {
              startGameFn(item.room);
            }}
          >
            StartGame
          </Button>
        );

        const Join = item.withPassword ? (
          <Button
            disabled={disabled}
            type="primary"
            onClick={() => {
              setIsPrivateOpen(item);
            }}
          >
            Join
          </Button>
        ) : (
          <Button
            loading={loading.joinRoom}
            disabled={disabled}
            type="primary"
            onClick={() => {
              joinRoomFn(item.room);
            }}
          >
            Join
          </Button>
        );

        return (
          <div>
            {playerObj?.roomId === item.room ? (
              <>
                {Leave}
                {StartGame}
              </>
            ) : (
              Join
            )}
          </div>
        );
      },
    },
  ];

  return (
    <>
      {contextHolder}
      <div className="JoinGame bg-indigo-100">
        <div className="grid justify-items-center h-20 bg-transparent absolute top-20  left-0 right-0 z-10  ">
          {/* <h1 className="text-5xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-pink-500 to-blue-500">
            Autochessia
          </h1> */}
          <div>
            <img src={Logo} />
          </div>
          <div className="mt-[40px] w-8 h-8 bg-gradient-to-br from-indigo-500 via-indigo-600 to-indigo-700 animate-spin"></div>
          <div className="  flex flex-col items-center justify-center">
            <div className="flex justify-center mt-20">
              <Button
                className="cursor-pointer btn bg-blue-500  text-white font-bold  px-4 rounded"
                onClick={showModal}
                disabled={disabled}
                loading={loading.createRoom}
                type="primary"
              >
                ➕ Create Room
              </Button>
            </div>
            <div className="mt-20 ">
              <Table
                columns={columns}
                dataSource={roomData}
                pagination={false}
              />
            </div>
          </div>
          <Modal
            wrapClassName="room-setting"
            footer={null}
            title="Create Room Setting"
            open={isModalOpen}
            onOk={handleOk}
            onCancel={handleCancel}
          >
            <div className="flex flex-col space-y-4">
              <div className="flex justify-center items-center">
                <span className="w-[15px]  text-red-700">*</span>
                <span className="w-[150px]">RoomName</span>
                <Input
                  value={value}
                  onChange={onChange}
                  placeholder={"RoomName"}
                />
              </div>
              <div className="flex justify-center items-center">
                <span className="w-[15px]"></span>

                <span className="w-[150px]">Password</span>
                {/* <Switch className="w-[100px]" onChange={(checked) => setIsChecked(checked)} /> */}
                <Input
                  // disabled={!isChecked}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={"password"}
                  maxLength={10}
                  defaultValue={password ?? ""}
                />
              </div>

              <Button
                loading={loading.createRoom}
                className="ml-[auto] cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
                onClick={() => createRoomFn(value, Number(seatNum), password)}
              >
                Create Room
              </Button>
            </div>
          </Modal>

          <Modal
            wrapClassName="room-setting"
            footer={null}
            title="Join Private Room"
            open={isPrivateOpen}
            onCancel={() => setIsPrivateOpen(undefined)}
          >
            <div className="flex flex-col space-y-4">
              <Input
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={"password"}
                maxLength={10}
                defaultValue={password ?? ""}
              />
              <Button
                loading={loading.joinRoom}
                className="ml-[350px] cursor-pointer btn bg-blue-500 hover:bg-blue-700 text-white font-bold  px-4 rounded"
                // todo fill in correct _roomId, _player, and _password
                onClick={() =>
                  joinPrivateRoomFn(
                    isPrivateOpen!.room,
                    localAccount as AddressType,
                    password
                  )
                }
              >
                Join
              </Button>
            </div>
          </Modal>
        </div>
      </div>
    </>
  );
};

export default JoinGame;
