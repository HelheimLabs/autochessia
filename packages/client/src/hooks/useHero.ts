import { srcObj } from "./useHeroAttr";

export function getHeroImg(heroId: number) {
  const id = heroId & 0xff;
  return srcObj.perUrl + id + srcObj.color;
}

export function getHeroTier(hero: number) {
  const tier = (hero >> 8) + 1;
  return tier;
}
