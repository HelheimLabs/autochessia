import { useMUD } from "@/MUDContext";
import { initEntity } from "@/constant";
import { useComponentValue } from "@latticexyz/react";
import { Tooltip } from "antd";

export const PlayerTier = () => {
  const {
    network: { playerEntity },
    components: { Player, GameConfig },
    systemCalls: { buyExp },
  } = useMUD();

  const playerData = useComponentValue(Player, playerEntity);
  const tier = playerData?.tier + 1;
  const gameConfig = useComponentValue(GameConfig, initEntity);

  console.log("gameConfig?.expUpgrade: ", gameConfig?.expUpgrade);
  return (
    <div className="fixed top-[42rem] left-[12rem]">
      <Tooltip title="EXP +4 , COST 4">
        <div
          className=" bg-[url('/assets/up_level.png')] bg-contain bg-no-repeat w-28 h-14"
          onClick={buyExp}
        >
          <div className="relative left-14 top-1">
            {"Lv. "}
            {tier}
            <div className="-mt-1  left-0.5">
              {playerData?.exp} / {gameConfig?.expUpgrade[tier]}
            </div>
          </div>
        </div>
      </Tooltip>
    </div>
  );
};
