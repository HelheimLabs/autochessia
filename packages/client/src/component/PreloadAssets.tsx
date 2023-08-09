import { useMUD } from "@/MUDContext";
import { useRow } from "@latticexyz/react";
import { useEffect, useState } from "react";

export default function PreLoadAssets() {
  const {
    network: { storeCache },
  } = useMUD();
  const gameConf = useRow(storeCache, {
    table: "GameConfig",
    key: { index: 0 },
  });

  const maxId = gameConf?.value.creatureIndex;

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

  return <></>;
}
