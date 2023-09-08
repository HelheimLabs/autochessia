import { HeroBaseAttr } from "@/hooks/useChessboard";
import React from "react";

interface HeroInfoProps {
  hero: HeroBaseAttr;
}

const HeroInfo: React.FC<HeroInfoProps> = ({ hero }) => {
  if (!hero) {
    return null;
  }
  const { attack, health, defense, lv, tier, range, speed, url, image } = hero;

  return (
    <div className="bg-gray-400 p-4 rounded-lg shadow fixed top-[300px] left-[10px]">
      <div className="flex items-center">
        <span className="font-bold">Health:</span>
        <span className="ml-2">{health}</span>
      </div>

      <div className="flex items-center mt-2">
        <span className="font-bold">Attack:</span>
        <span className="ml-2">{attack}</span>
      </div>

      <div className="flex items-center mt-2">
        <span className="font-bold">Defense:</span>
        <span className="ml-2">{defense}</span>
      </div>

      <div className="flex items-center mt-2">
        <span className="font-bold">Level:</span>
        <span className="ml-2">{lv || tier}</span>
      </div>

      <div className="flex items-center mt-2">
        <span className="font-bold">Range:</span>
        <span className="ml-2">{range}</span>
      </div>

      <div className="flex items-center mt-2">
        <span className="font-bold">Speed:</span>
        <span className="ml-2">{speed}</span>
      </div>

      <img
        src={url || image}
        alt="Hero Image"
        className="w-20 h-20 mt-4 rounded"
      />
    </div>
  );
};

export default HeroInfo;
