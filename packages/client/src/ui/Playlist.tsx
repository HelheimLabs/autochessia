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
  const { playerListData, localAccount: currentUserId } = useChessboard();

  return (
    <div className="w-[250px] fixed right-4 top-[120px]">
      {playerListData?.map((player) => {
        const isCurrentUser = player.id === currentUserId;
        return (
          <div
            key={player.id}
            className={`flex items-center p-2 ${
              isCurrentUser ? "bg-blue-500" : "bg-gray-200"
            }`}
            onClick={() => redirectToGame(player.id)}
          >
            <img className="w-12 h-12 rounded-full mr-4" src={player.avatar} />

            <div className="flex-1">
              <div className="flex justify-between">
                <span className="text-lg font-medium">{player.name}</span>
                <span className="text-gray-600">Lv. {player.level}</span>
              </div>

              <div className="flex justify-between text-sm mt-1">
                <div>{player.coin} Coins</div>
                <div>
                  {player.hp}/{player.maxHp} HP
                </div>
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
