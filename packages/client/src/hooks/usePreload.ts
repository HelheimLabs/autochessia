import { useMUD } from "@/MUDContext";
import { decodeHeroCount, encodeHeroIdString } from "@/lib/utils";
import { useComponentValue } from "@latticexyz/react";
import { Entity } from "@latticexyz/recs";
import { useEffect } from "react";

export default function usePreload() {
  const {
    components: { GameConfig },
  } = useMUD();

  const initEntity: Entity =
    "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

  const _GameConfig = useComponentValue(GameConfig, initEntity);
  const heroDistribution = decodeHeroCount(
    BigInt(_GameConfig?.creatureCounter || 0)
  );

  // loading hero image
  useEffect(() => {
    if (heroDistribution.totalCount) {
      const urls: string[] = [];

      // legend
      for (let i = 1n; i <= heroDistribution.legendCount; i++) {
        urls.push(
          `https://autochessia.4everland.store/autochess-v0.0.2/hero/${encodeHeroIdString(
            4n,
            i
          )}.png`
        );
      }
      // epic
      for (let i = 1n; i <= heroDistribution.epicCount; i++) {
        urls.push(
          `https://autochessia.4everland.store/autochess-v0.0.2/hero/${encodeHeroIdString(
            3n,
            i
          )}.png`
        );
      }
      // rare
      for (let i = 1n; i <= heroDistribution.rareCount; i++) {
        urls.push(
          `https://autochessia.4everland.store/autochess-v0.0.2/hero/${encodeHeroIdString(
            2n,
            i
          )}.png`
        );
      }
      // uncommon
      for (let i = 1n; i <= heroDistribution.uncommonCount; i++) {
        urls.push(
          `https://autochessia.4everland.store/autochess-v0.0.2/hero/${encodeHeroIdString(
            1n,
            i
          )}.png`
        );
      }
      // common
      for (let i = 1n; i <= heroDistribution.commonCount; i++) {
        urls.push(
          `https://autochessia.4everland.store/autochess-v0.0.2/hero/${encodeHeroIdString(
            0n,
            i
          )}.png`
        );
      }
      urls.forEach((url) => {
        const img = new Image();
        img.src = url;
      });
    }
  }, [heroDistribution]);
}
