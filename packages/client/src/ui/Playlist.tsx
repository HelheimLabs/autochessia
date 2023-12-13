import React, { useEffect, useState } from "react";
import useChessboard from "@/hooks/useChessboard";

interface IPlayerStatus {
  id: string;
  name: string;
  isCurrent: boolean;
  avatar: string;
  level: number;
  hp: number;
  maxHp: number;
  coin: number;
}

function PlayerStatus({
  id,
  name,
  isCurrent,
  avatar,
  level,
  hp,
  maxHp,
  coin,
}: IPlayerStatus) {
  const healthPercentage = (hp / maxHp) * 100;

  return (
    <div
      key={id}
      className={`flex justify-center items-center  p-2 mt-[10px] ${
        isCurrent ? "border border-blue-500" : ""
      }`}
    >
      <img className="w-11 h-11" src={avatar} />
      <div className="flex flex-col w-11 h-11 justify-center">
        <span className="text-black text-center">Lv. {level}</span>
        <div className="flex items-center">
          <img className="w-5 h-6" src="/assets/gold.png"></img>
          <span className="text-black"> {coin}</span>
        </div>
      </div>
      <div className="flex-1 grid w-11 h-11 content-around ml-2 items-center">
        <div className="text-black">{name}</div>
        <div className="w-full h-4 relative rounded-lg">
          <div
            className={`absolute h-4 text-center rounded-lg  flex justify-center items-center bg-[#00FF05] `}
            style={{ width: `${healthPercentage}%` }}
          ></div>
          <span className="h-4 leading-none absolute left-1/2 transform -translate-x-1/2">
            <div className="text-black">
              {hp}/{maxHp}
            </div>
          </span>
        </div>
      </div>
    </div>
  );
}

const PlayerList: React.FC = () => {
  const {
    playerListData,
    localAccount: currentUserId,
    isSinglePlay,
  } = useChessboard();

  const [showList, setShowList] = useState(true);

  const isCurrentUserFn = (id: string) =>
    id.toLocaleLowerCase() === currentUserId.toLocaleLowerCase();

  const mapList = isSinglePlay
    ? playerListData?.filter((player) => isCurrentUserFn(player.id))
    : playerListData;

  // monitor windows size to decide whether show player
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth / window.innerHeight < 1400 / 980) {
        setShowList(false);
      } else {
        setShowList(true);
      }
    };
    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  if (!showList) {
    return <div></div>;
  }

  return (
    <div className="fixed right-4 top-[100px] h-[820px] bg-contain bg-no-repeat bg-[url('/assets/player_info.png')]">
      <div className="ml-4 mt-6 text-black">Players Info</div>
      <div className="pl-4 pr-2 mt-2 w-72 h-20 ">
        {mapList?.map((player) => {
          const isCurrent = isCurrentUserFn(player.id);
          return (
            <PlayerStatus
              key={player.id}
              {...{ ...player, isCurrent: isCurrent }}
            />
          );
        })}
      </div>
    </div>
  );
};

const redirectToGame = (userId: string) => {
  return;
};

export default PlayerList;
