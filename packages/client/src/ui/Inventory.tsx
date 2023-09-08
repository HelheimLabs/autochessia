import { useMUD } from "@/MUDContext";
import { srcObj, useHeroesAttr } from "@/hooks/useHeroAttr";
import { useComponentValue } from "@latticexyz/react";
import PieceImg from "./Piece";
import { numberArrayToBigIntArray } from "@/lib/utils";

// eslint-disable-next-line react/prop-types
export function Inventory({ setAcHeroFn }) {
  const {
    components: { Player },
    systemCalls: { placeBackInventory, sellHero },
    network: { playerEntity },
  } = useMUD();

  const playerValue = useComponentValue(Player, playerEntity);

  const heroAttrs = useHeroesAttr(
    numberArrayToBigIntArray(playerValue?.inventory)
  );

  return (
    <div className="bench-area bg-stone-500 mt-4  border-cyan-700   text-center min-h-[90px] w-[600px] flex  justify-center mx-auto">
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
  );
}
