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
    <div className="hero-area" style={{ display: "flex" }}>
      <Modal
        wrapClassName="shop-modal"
        title=""
        closable={false}
        width={900}
        open={isModalOpen}
        onCancel={handleCancel}
        footer={null}
      >
        <div className="grid  shop-wrap">
          <div className="flex items-center justify-around">
            {heroItems?.map((hero: HeroListItem, index: number) => (
              <div
                className={`${!hero?.creature ? "invisible" : " block"} `}
                key={index}
                onClick={() => handleBuy(index)}
              >
                <div className="shopItem">
                  <img
                    src={hero?.url}
                    alt={hero?.url}
                    style={{ width: "100%", height: 120 }}
                    className="w-[120px] h-[120px] bg-blue-600 rounded-lg opacity-100"
                  />
                  <div className="mt-[13px] flex justify-between">
                    <div className=" text-base ">
                      {Array(hero?.["lv"])
                        .fill(hero?.["lv"])
                        ?.map((item, index) => (
                          <span
                            className={
                              item > index
                                ? "text-yellow-400 mr-[10px]"
                                : "text-gray-500 mr-[10px]"
                            }
                            key={index}
                          >
                            &#9733;
                          </span>
                        ))}
                    </div>
                    <span className="text-white text-base">$ {hero?.cost}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="flex justify-center items-center mt-[50px]">
            <button
              onClick={buyRefreshHero}
              className="refrsh hover:bg-blue-500 rounded-full focus:outline-none"
            >
              Refresh Hero $2
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};

export default Shop;
