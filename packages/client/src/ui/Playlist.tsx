import React from "react";
import useChessboard from "@/hooks/useChessboard";

interface Player {
  id: string;
  avatar: string;
  level: number;
  hp: number;
  coin: number;
}

interface Props {
  players: Player[];
  currentUserId: string;
}

const PlayerList: React.FC = () => {
  const {
    playerListData,
    localAccount: currentUserId,
    isSinglePlay,
  } = useChessboard();

  const isCurrentUserFn = (id: string) =>
    id.toLocaleLowerCase() === currentUserId.toLocaleLowerCase();

  const mapList = isSinglePlay
    ? playerListData?.filter((player) => isCurrentUserFn(player.id))
    : playerListData;

  return (
    <div className="playerList fixed right-4 top-[160px]">
      <div className="playerList-tit mx-[10px]">Players Info</div>
      {mapList?.map((player) => {
        const isCurrentUser = isCurrentUserFn(player.id);
        const healthPercentage = (player.hp / player.maxHp) * 100;
        return (
          <div
            key={player.id}
            className={`players flex  p-2 mt-[10px] ${
              isCurrentUser ? "border border-blue-500" : ""
            }`}
            onClick={() => redirectToGame(player.id)}
          >
            <img
              className="w-[60px] h-[60px] rounded-full mr-4"
              src={player.avatar}
            />
            <div className="flex-1 grid content-around ">
              <div className=" flex justify-between">
                <span className="player-addr">{player.name}</span>
                <span className="player-coin">${player.coin}</span>
                <span className="player-lv">Lv. {player.level}</span>
              </div>
              <div className=" w-full h-4 bg-[#96c0a9] relative rounded-lg">
                <div
                  className={`absolute h-4 text-center rounded-lg  flex justify-center items-center bg-[#4EF395] `}
                  style={{ width: `${healthPercentage}%` }}
                ></div>
                <span className="player-hp h-4 leading-none absolute left-1/2 transform -translate-x-1/2">
                  {player.hp}/{player.maxHp} HP
                </span>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
};

const redirectToGame = (userId: string) => {
  return;
};

export default PlayerList;
