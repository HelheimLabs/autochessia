import { HeroBaseAttr } from "@/hooks/useChessboard";
import React from "react";

interface HeroInfoProps {
  hero: HeroBaseAttr;
}

const HeroInfo: React.FC<HeroInfoProps> = ({ hero }) => {
  if (!hero || !hero.health) {
    return null;
  }
  const { attack, health, defense, lv, tier, range, speed, url, image } = hero;

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
        <span className="ml-2">{lv || tier}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Range:</span>
        <span className="ml-2">{range}</span>
      </div>

      <div className="flex items-center mt-2 justify-between">
        <span className="font-bold">Speed:</span>
        <span className="ml-2">{speed}</span>
      </div>

      <div className="flex justify-center">
        <img
          src={url || image}
          alt="Hero Image"
          className="w-20 h-20 mt-4 rounded"
        />
      </div>
    </div>
  );
};

export default HeroInfo;
