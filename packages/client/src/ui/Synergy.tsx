import { useMUD } from "@/MUDContext";
import { ClassSynergy, RaceSynergy } from "@/constant";
import { HeroClass, HeroRace, useHeroesAttr } from "@/hooks/useHeroAttr";
import {
  decodeHero,
  encodeCreatureEntity,
  encodeHeroEntity,
  numberArrayToBigIntArray,
} from "@/lib/utils";
import { StringForUnion } from "@latticexyz/common/type-utils";
import { useComponentValue } from "@latticexyz/react";
import { getComponentValue, getComponentValueStrict } from "@latticexyz/recs";

export function useUniqueHero(heroIds: string[]) {
  const {
    components: { Hero },
  } = useMUD();

  const uniqueHeroes: bigint[] = [];

  return heroIds.reduce((uniqueCreatureIds, id) => {
    const hero = getComponentValue(Hero, encodeHeroEntity(BigInt(id)));
    const { heroId, creatureId } = decodeHero(hero?.creatureId);

    if (uniqueHeroes.indexOf(heroId) === -1) {
      uniqueHeroes.push(heroId);
      uniqueCreatureIds.push(creatureId);
    }
    return uniqueCreatureIds;
  }, [] as bigint[]);
}

export function useSynergyCount(uniqueCreatureIds: bigint[]) {
  const {
    components: { Creature },
  } = useMUD();

  const raceSynergy: Record<HeroRace, number> = {
    [HeroRace.UNKNOWN]: 0,
    [HeroRace.GOD]: 0,
    [HeroRace.HUMAN]: 0,
    [HeroRace.ORC]: 0,
    [HeroRace.TROLL]: 0,
    [HeroRace.PANDAREN]: 0,
  };
  const classSynergy: Record<HeroClass, number> = {
    [HeroClass.UNKNOWN]: 0,
    [HeroClass.ASSASSIN]: 0,
    [HeroClass.KNIGHT]: 0,
    [HeroClass.MAGE]: 0,
    [HeroClass.WARLOCK]: 0,
    [HeroClass.WARRIOR]: 0,
  };

  uniqueCreatureIds.forEach((v) => {
    const creatureValue = getComponentValueStrict(
      Creature,
      encodeCreatureEntity(v)
    );

    raceSynergy[creatureValue.race as HeroRace] += 1;
    classSynergy[creatureValue.class as HeroClass] += 1;
  });

  return { raceSynergy, classSynergy };
}

export function useSynergy() {
  const {
    components: { Player },
    network: { playerEntity },
  } = useMUD();
  const playerValue = useComponentValue(Player, playerEntity);
  const heroes = playerValue?.heroes || [];

  const synergyData = useSynergyCount(useUniqueHero(heroes));

  return synergyData;
}

export function Synergy() {
  const { raceSynergy, classSynergy } = useSynergy();

  return (
    <div className="">
      <div className="flex flex-row w-[560px] justify-center pt-3">
        {Object.keys(raceSynergy).map((r) => {
          const race = Number(r) as HeroRace;
          if (race === HeroRace.UNKNOWN) return;
          const count = raceSynergy[race];
          return (
            <SynergyItem
              key={race + "race"}
              count={count}
              index={race}
              active={false}
              type="Race"
              url={getRaceImage(race)}
            />
          );
        })}

        {Object.keys(classSynergy).map((r) => {
          const c = Number(r) as HeroClass;
          if (c === HeroClass.UNKNOWN) return;
          const count = classSynergy[c];
          return (
            <SynergyItem
              key={c + "class"}
              count={count}
              index={c}
              active={true}
              type="Class"
              url={getClassImage(c)}
            />
          );
        })}
      </div>
    </div>
  );
}

export interface synergyItemProps {
  url: string;
  count: number;
  active?: boolean;
  type: "Class" | "Race";
  index: HeroRace | HeroClass;
}

export function SynergyItem({
  url,
  active,
  type,
  index,
  count,
}: synergyItemProps) {
  if (type === "Class") {
    if (count >= ClassSynergy[index].unlockWhen[0]) {
      active = true;
    } else {
      active = false;
    }
  } else {
    if (count >= RaceSynergy[index].unlockWhen[0]) {
      active = true;
    } else {
      active = false;
    }
  }

  return (
    <div className="group">
      <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-200 z-10 pointer-events-none">
        {type === "Class"
          ? ClassSynergy[index].description(
              ClassSynergy[index].unlockValue[count]
            )
          : RaceSynergy[index].description(
              RaceSynergy[index].unlockValue[count]
            )}
      </div>
      <img
        className={`w-[40px] h-[40px] mx-1 border-1.5 border-blue-100 rounded-full shadow-lg bri ${
          active ? "brightness-200" : "brightness-50"
        }`}
        src={url}
      ></img>
    </div>
  );
}

export function getRaceImage(race: HeroRace) {
  return `https://autochessia.4everland.store/autochess-v0.0.2/synergy/race/${race}.png`;
}

export function getClassImage(heroClass: HeroClass) {
  return `https://autochessia.4everland.store/autochess-v0.0.2/synergy/class/${heroClass}.png`;
}
