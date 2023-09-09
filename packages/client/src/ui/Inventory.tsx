import { useMUD } from "@/MUDContext";
import { srcObj, useHeroesAttr } from "@/hooks/useHeroAttr";
import { useComponentValue } from "@latticexyz/react";
import PieceImg from "./Piece";
import { numberArrayToBigIntArray } from "@/lib/utils";
import { HeroBaseAttr } from "@/hooks/useChessboard";

// eslint-disable-next-line react/prop-types
export function Inventory({ setAcHeroFn }) {
  const {
    components: { Player },
    network: { playerEntity },
  } = useMUD();

  const playerValue = useComponentValue(Player, playerEntity);

  const heroAttrs = useHeroesAttr(
    numberArrayToBigIntArray(playerValue?.inventory)
  );

  return (
    <div className="bench-area bg-stone-500  border-cyan-700   text-center  w-[560px]  mx-auto">
      <div className="h-[50px]" />
      <div className="bench-area-hero flex  justify-center">
        {heroAttrs?.map((hero: HeroBaseAttr, index: number) => (
          <div key={index} onClick={() => setAcHeroFn(hero)}>
            <PieceImg
              index={index}
              hero={hero}
              src={hero.image}
              alt={hero.url}
            />
          </div>
        ))}
      </div>
    </div>
  );
}
