import {
  OverridableComponent,
  getComponentValueStrict,
} from "@latticexyz/recs";
import { ClientComponents } from "../mud/createClientComponents";
import { SetupNetworkResult } from "../mud/setupNetwork";
import { uuid } from "@latticexyz/utils";
import { initEntity } from "@/constant";
import { decodeHero } from "@/lib/ulits";

export function opRunSellHero(
  { playerEntity }: SetupNetworkResult,
  { Player, ShopConfig }: ClientComponents,
  index: number
): string {
  const sellId = uuid();

  const oldPlayerData = getComponentValueStrict(Player, playerEntity);
  // check hero not null
  const heroData = oldPlayerData.inventory[index];

  if (heroData === 0) {
    throw new Error("Null hero");
  }

  const [tier, ,] = decodeHero(heroData);

  // remove from hero inventory
  const newInventory = oldPlayerData.inventory.map((v, i) => {
    if (i === index) {
      return 0;
    }
    return v;
  });

  const prices = getComponentValueStrict(ShopConfig, initEntity).tierPrice;

  // add coin back
  const newCoin = oldPlayerData.coin + prices[tier - 1];

  Player.addOverride(sellId, {
    entity: playerEntity,
    value: {
      inventory: newInventory,
      coin: newCoin,
    },
  });

  return sellId;
}
