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
  return (
    <div className="hero-area my-4" style={{ display: "flex" }}>
      <Modal
        wrapClassName="shop-modal"
        title=""
        closable={false}
        width={900}
        open={isModalOpen}
        onCancel={handleCancel}
        footer={null}
      >
        <div className="flex items-center justify-center shop-wrap">
          {heroItems?.map((hero: HeroListItem, index: number) => (
            <div
              className={`${
                !hero?.creature ? "invisible" : " block"
              } mr-8 last:mr-0`}
              key={(hero?.url as string) + index}
              onClick={() => handleBuy(index)}
            >
              {/* <Card
                hoverable
                style={{ width: 120 }}
                cover={
                  <img
                    src={hero?.url}
                    alt={hero?.url}
                    style={{ width: "100%", height: 120 }}
                  />
                }
              > */}
              <div className="shopItem">
                <img
                  src={hero?.url}
                  alt={hero?.url}
                  style={{ width: "100%", height: 120 }}
                  className="w-[120px] h-[120px] bg-blue-600 rounded-lg opacity-100"
                />
                <div className="mt-[13px] flex justify-between">
                  <div className="text-yellow-400   text-base ">
                    {Array(hero?.["lv"])
                      .fill(null)
                      ?.map((item, index) => (
                        <span className="" key={index}>
                          &#9733;
                        </span>
                      ))}
                  </div>
                  <span className="text-white text-base">$ {hero?.cost}</span>
                </div>

                {/* <span className="text-block-200 mr-2 text-xl">
                  Lv: {hero?.lv}
                </span> */}
              </div>
              {/* </Card> */}
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
