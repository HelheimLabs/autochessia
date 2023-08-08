import React, { useState, useEffect, useMemo, useRef } from "react";
import { Card, Modal } from "antd";
import { HeroBaseAttr } from "@/hooks/useChessboard";

type HeroListItem = HeroBaseAttr | null;

interface IShopProps {
  heroList: HeroListItem[];
  handleBuy: (index: number) => void;
  isModalOpen: boolean;
  handleCancel: () => void;
  srcObj: any;
  buyRefreshHero: () => void;
}

const Shop: React.FC<IShopProps> = ({
  heroList: heroItems,
  isModalOpen,
  srcObj,
  handleBuy,
  handleCancel,
  buyRefreshHero,
}) => {
  console.log(heroItems);
  // const [heroItems, setHeroItems] = useState<HeroListItem[]>(heroList)

  // const oriHeroList = useRef(heroList)

  // useEffect(() => {
  //   if (heroList?.length == 5) {
  //     oriHeroList.current = heroList
  //     setHeroItems(heroList)
  //   } else {

  //     setHeroItems(compareAndFill(oriHeroList.current, heroList))

  //   }

  // }, [heroList])

  return (
    <div className="hero-area my-4" style={{ display: "flex" }}>
      <Modal
        wrapClassName="shop-modal"
        title=""
        closable={false}
        width={800}
        open={isModalOpen}
        onCancel={handleCancel}
        footer={null}
      >
        <div className="flex items-center justify-center">
          {heroItems?.map((hero: HeroListItem, index: number) => (
            <div
              className={`${
                !hero?.creature ? "invisible" : " block"
              } mr-8 last:mr-0`}
              key={hero?.url + index}
              onClick={() => handleBuy(index)}
            >
              <Card
                hoverable
                style={{ width: 120 }}
                cover={
                  <img
                    src={hero.url}
                    alt={hero?.url}
                    style={{ width: "100%", height: 120 }}
                  />
                }
              >
                <span className="text-block-200 mr-2 text-xl">
                  Lv: {hero?.lv}
                </span>
                <span className="text-yellow-400 text-xl">
                  Cost: {hero?.cost}
                </span>
              </Card>
            </div>
          ))}
        </div>
        <div className="flex justify-center items-center mt-11">
          <button
            onClick={buyRefreshHero}
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-full focus:outline-none"
          >
            Refresh Hero
          </button>
        </div>
      </Modal>
    </div>
  );
};

export default Shop;
