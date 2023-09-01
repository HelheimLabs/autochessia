import { useMUD } from "@/MUDContext";
import { useComponentValue, useEntityQuery } from "@latticexyz/react";
import { Entity, getComponentValueStrict, Has, Not } from "@latticexyz/recs";
import { useEffect, useState } from "react";

export default function usePreload() {
  const {
    components: { GameConfig },
  } = useMUD();

  const initEntity: Entity =
    "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

  const _GameConfig = useComponentValue(GameConfig, initEntity);
  const maxId = _GameConfig?.creatureIndex as number;

  useEffect(() => {
    if (maxId) {
      for (let i = 1; i <= maxId; i++) {
        const urls = [
          `https://autochessia.4everland.store/creatures/${i}/avatar.gif`,
          `https://autochessia.4everland.store/creatures/${i}/colorful.png`,
        ];

        urls.forEach((url) => {
          const img = new Image();
          img.src = url;
        });
      }
    }
  }, [maxId]);
}
