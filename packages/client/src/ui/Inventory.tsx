import { useMUD } from "@/MUDContext";
import { srcObj, useHeroesAttr } from "@/hooks/useHeroAttr";
import { useComponentValue } from "@latticexyz/react";
import { useEffect, useState } from "react";
import PieceImg from "./Piece";

export function Inventory({ setAcHeroFn }) {
  const {
    components: { Player },
    systemCalls: { placeBackInventory, sellHero },
    network: { playerEntity },
  } = useMUD();

  const playerValue = useComponentValue(Player, playerEntity);

  useEffect(() => {
    console.log(playerValue?.inventory);
  }, [playerValue?.inventory]);

  const heroAttrs = useHeroesAttr(playerValue?.inventory || []);

  return (
    <div className="bench-area bg-stone-500  border-cyan-700   text-center  w-[560px]  mx-auto">
      <div className="h-[50px]" />
      <div className="bench-area-hero flex  justify-center">
        {heroAttrs?.map(
          (
            hero: { url: string; creature: number; image: string },
            index: number
          ) => (
            <div key={index} onClick={() => setAcHeroFn(hero)}>
              <PieceImg
                placeBackInventory={placeBackInventory}
                sellHero={sellHero}
                srcObj={srcObj}
                index={index}
                hero={hero}
                src={hero.image}
                alt={hero.url}
              />
            </div>
          )
        )}
      </div>
    </div>
  );
}
