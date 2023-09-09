import { HeroBaseAttr } from "@/hooks/useChessboard";
import React from "react";
import { BG_COLOR } from "./Shop";
import { getClassImage, getRaceImage } from "./Synergy";

interface HeroInfoProps {
  hero: HeroBaseAttr;
}

const HeroInfo: React.FC<HeroInfoProps> = ({ hero }) => {
  if (!hero || !hero.health) {
    return null;
  }
  const {
    attack,
    health,
    defense,
    lv,
    tier,
    range,
    speed,
    url,
    image,
    cost,
    rarity,
  } = hero;

  return (
    <div className="hero-info-box shadow fixed top-[300px] left-[10px]">
      <div className="flex items-center justify-between">
        <span className="font-bold">Health:</span>
        <span className="ml-2">{health}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Attack:</span>
        <span className="ml-2">{attack}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Defense:</span>
        <span className="ml-2">{defense}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Level:</span>
        <span className="ml-2">{Number(lv || tier)}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Cost:</span>
        <span className="ml-2">{Number(lv) || Number(tier)}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Range:</span>
        <span className="ml-2">{range}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Speed:</span>
        <span className="ml-2">{speed}</span>
      </div>

      <div>
        {/* show class and race */}
        <div className="flex felx-row">
          <img
            className="w-[30px] h-[30px] mx-1"
            src={getRaceImage(hero.race as number)}
          ></img>
          <img
            className="w-[30px] h-[30px] mx-1"
            src={getClassImage(hero.class as number)}
          ></img>
        </div>
      </div>

      <div className="flex justify-center">
        <img
          src={url || image}
          alt="Hero Image"
          className={`w-20 h-20 mt-4 rounded ${BG_COLOR[Number(rarity || 0)]}`}
        />
      </div>
    </div>
  );
};

export default HeroInfo;
