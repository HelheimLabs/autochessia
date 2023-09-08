import { initEntity } from "@/constant";
import { ClientComponents } from "@/mud/createClientComponents";
import { SetupNetworkResult } from "@/mud/setupNetwork";
import { getComponentValueStrict } from "@latticexyz/recs";
import { uuid } from "@latticexyz/utils";

export function opRunBuyRefreshHero(
  { playerEntity }: SetupNetworkResult,
  { Player }: ClientComponents
): string {
  const playerData = getComponentValueStrict(Player, playerEntity);
  const id = uuid();

  // clear hero altar for op run
  playerData.heroAltar = Array.from(
    { length: playerData.heroAltar.length },
    () => 0
  );

  Player.addOverride(id, {
    entity: playerEntity,
    value: {
      heroAltar: playerData.heroAltar,
    },
  });

  return id;
}
