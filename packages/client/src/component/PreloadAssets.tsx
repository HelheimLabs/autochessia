import { useMUD } from "@/MUDContext";
import { useRow } from "@latticexyz/react";
import { useEffect, useState } from "react";

const usePreloadImages = (imageUrls: string[]) => {
  useEffect(() => {
    imageUrls?.forEach((url) => {
      const img = new Image();
      img.src = url;
    });
  }, [imageUrls]);
};

function usePreloadImagesUrls(maxId?: number): string[] {
  const [urls, setUrls] = useState<string[]>([]);

  useEffect(() => {
    setUrls(
      [
        ...Array.from({ length: maxId || 0 }, (_, i) => i + 1).map((id) => {
          return [
            `https://autochessia.4everland.store/creatures/${id}/avatar.gif`,
            `https://autochessia.4everland.store/creatures/${id}/colorful.png`,
          ];
        }),
      ][0]
    );
  }, [maxId]);

  return urls;
}

export default function PreLoadAssets() {
  const {
    network: { storeCache },
  } = useMUD();
  const gameConf = useRow(storeCache, {
    table: "GameConfig",
    key: { index: 0 },
  });

  const maxId = gameConf?.value.creatureIndex;

  const urls = usePreloadImagesUrls(maxId);

  usePreloadImages(urls);

  return <></>;
}
