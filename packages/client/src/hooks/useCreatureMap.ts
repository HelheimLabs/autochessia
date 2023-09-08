import { useMUD } from "@/MUDContext";
import { useEntityQuery } from "@latticexyz/react";
import { Has, getComponentValueStrict } from "@latticexyz/recs";
import { useEffect, useMemo } from "react";

export function useCreatureMap() {
  const {
    components: { Creature },
  } = useMUD();
  const _Creature = useEntityQuery([Has(Creature)], {
    updateOnValueChange: true,
  });

  const creatureMap = useMemo(() => {
    return new Map(
      _Creature
        .map((row) => ({
          ...getComponentValueStrict(Creature, row),
          key: row,
        }))
        .map((c) => [Number(c.key), c])
    );
  }, [_Creature, Creature]);

  return creatureMap;
}
