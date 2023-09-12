import { HeroClass, HeroRace } from "@/hooks/useHeroAttr";
import { Entity } from "@latticexyz/recs";

export const initEntity: Entity =
  "0x0000000000000000000000000000000000000000000000000000000000000000" as Entity;

export const RaceSynergy: Record<
  HeroRace,
  {
    unlockWhen: number[];
    unlockValue: { [x: number]: number };
    description: (x: number) => string;
  }
> = {
  [HeroRace.UNKNOWN]: {
    unlockWhen: [],
    unlockValue: {},
    description: (x: number) => "",
  },
  [HeroRace.ORC]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 100, 3: 100, 4: 300 },
    description: (x: number) => `increase HP by ${x}`,
  },
  [HeroRace.TROLL]: {
    unlockWhen: [2],
    unlockValue: { 0: 0, 1: 0, 2: 10, 3: 10 },
    description: (x: number) => `increase the rate of ${x}% to attack twice`,
  },
  [HeroRace.PANDAREN]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 20, 3: 20, 4: 30 },
    description: (x: number) => `increase the rate of evasion by ${x}%`,
  },
  [HeroRace.HUMAN]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 15, 3: 15, 4: 30 },
    description: (x: number) => `all decrease ${x}% damage if it's not alone`,
  },
  [HeroRace.GOD]: {
    unlockWhen: [2],
    unlockValue: { 0: 0, 1: 0, 2: 20 },
    description: (x: number) => `increase all attack by ${x}%`,
  },
};

export const ClassSynergy: Record<
  HeroClass,
  {
    unlockWhen: number[];
    unlockValue: { [x: number]: number };
    description: (x: number) => string;
  }
> = {
  [HeroClass.UNKNOWN]: {
    unlockWhen: [],
    unlockValue: {},
    description: (x: number) => "",
  },
  [HeroClass.KNIGHT]: {
    unlockWhen: [2],
    unlockValue: { 0: 0, 1: 0, 2: 10, 3: 10 },
    description: (x: number) => `all have a rate of ${x}% to immune attack`,
  },
  [HeroClass.WARRIOR]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 5, 3: 5, 4: 10 },
    description: (x: number) => `increase all piece defense by ${x}`,
  },
  [HeroClass.ASSASSIN]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 10, 3: 10, 4: 20 },
    description: (x: number) => `increase all rate of critical hit by ${x}%`,
  },
  [HeroClass.MAGE]: {
    unlockWhen: [2, 4],
    unlockValue: { 0: 0, 1: 0, 2: 20, 3: 20, 4: 40 },
    description: (x: number) => `decrease enemy defense by ${x}%`,
  },
  [HeroClass.WARLOCK]: {
    unlockWhen: [2],
    unlockValue: { 0: 0, 1: 0, 2: 10, 3: 10 },
    description: (x: number) =>
      `all have a rate ${x}% to dizz enemy for a turn on attack`,
  },
};
