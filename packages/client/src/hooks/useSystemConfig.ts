import { useMUD } from "@/MUDContext";
import { initEntity } from "@/constant";
import { useComponentValue } from "@latticexyz/react";

export function useSystemConfig() {
  const {
    components: { ShopConfig, GameConfig },
  } = useMUD();

  const shopConfig = useComponentValue(ShopConfig, initEntity);
  const gameConfig = useComponentValue(GameConfig, initEntity);

  return { shopConfig, gameConfig };
}
