import { decodeHero } from "@/lib/ulits";
import { useSystemConfig } from "./useSystemConfig";
import { HeroBaseAttr } from "./useChessboard";
import { useCreatureMap } from "./useCreatureMap";
import { useEffect, useState } from "react";

export interface srcObjType {
  ava: string;
  color: string;
  mono: string;
  void: string;
  perUrl: string;
}

export const srcObj = {
  ava: "/avatar.gif",
  color: "/colorful.png",
  mono: "/monochrome.png",
  void: "/void.png",
  perUrl: "https://autochessia.4everland.store/creatures/",
};

export function useHeroesAttr(arr: number[]): HeroBaseAttr[] {
  const creatureMap = useCreatureMap();

  const { shopConfig } = useSystemConfig();

  const [attrs, setAttrs] = useState<HeroBaseAttr[]>([]);

  useEffect(() => {
    setAttrs(
      arr
        ?.map((item: number) => decodeHero(item))
        ?.map((item: number[]) => {
          const creature = creatureMap.get(item?.[2]);

          if (creature) {
            return {
              cost: shopConfig?.tierPrice?.[item?.[0] - 1],
              lv: item?.[0],
              url: item?.[0] > 0 ? srcObj.perUrl + item?.[1] + srcObj.ava : "",
              image:
                item?.[0] > 0 ? srcObj.perUrl + item?.[1] + srcObj.color : "",
              creature: item?.[0],
              oriHero: item?.[2],
              ...creature,
              maxHealth: creature?.health,
            };
          }
          return {};
        }) as HeroBaseAttr[]
    );
  }, [arr, creatureMap, shopConfig?.tierPrice]);

  return attrs;
}
