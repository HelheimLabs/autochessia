import React, { useCallback, useState } from "react";
import { Button, Modal, Tooltip, message } from "antd";
import { HeroBaseAttr } from "@/hooks/useChessboard";
import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useHeroesAttr } from "@/hooks/useHeroAttr";
import { decodeHero, numberArrayToBigIntArray } from "@/lib/utils";
import { getClassImage, getRaceImage } from "./Synergy";

type HeroListItem = HeroBaseAttr | null;

const SHOW_INFO_LIST = ["health", "attack", "defense", "range"] as const;

export const BG_COLOR = [
  "bg-white",
  "bg-green-500",
  "bg-blue-500",
  "bg-purple-500",
  "bg-yellow-500",
];

const Shop = () => {
  const {
    components: { Player },
    systemCalls: { buyHero, buyRefreshHero },
    network: { playerEntity },
  } = useMUD();
  const [messageApi, contextHolder] = message.useMessage();

  const [loading, setLoading] = useState<boolean>(false);

  const buyRefreshHeroFn = useCallback(async () => {
    setLoading(true);
    buyRefreshHero()
      .catch((e) => {
        console.error(e);
      })
      .finally(() => {
        setLoading(false);
      });
  }, [buyRefreshHero]);

  // const [n, forceRender] = useState(0);

  const playerValue = useComponentValue(Player, playerEntity);

  const heroAttrs = useHeroesAttr(
    numberArrayToBigIntArray(playerValue?.heroAltar)
  );

  const buyHeroFn = (index: number, hero: HeroBaseAttr) => {
    if (Number(hero.cost) + 1 > (playerValue?.coin as number)) {
      messageApi.open({
        type: "error",
        content: "Not enough coins",
      });
      return;
    } else {
      buyHero(index);
    }
  };

  return (
    <div className="flex justify-center">
      {contextHolder}
      <div className="flex justify-center items-start w-[800px] h-40 bg-contain bg-no-repeat bg-[url('/assets/shop_bg.png')]">
        <div className="flex">
          <div className="flex items-center justify-around ml-4 mt-4">
            {heroAttrs?.map(
              (hero: HeroListItem, index: number) =>
                hero && (
                  <div
                    className={`${!hero?.creature ? "invisible" : ""} `}
                    key={String(index) + hero?.url}
                    onClick={() => buyHeroFn(index, hero)}
                  >
                    <div className="flex flex-col border-1 items-start">
                      <div className="flex justify-center w-[95px] h-[130px] rounded-lg opacity-100 bg-contain bg-no-repeat bg-center bg-[url('assets/hero_bg.png')] mx-2">
                        <img
                          className="w-auto h-auto object-contain"
                          src={hero?.url}
                          alt={hero?.url}
                        />
                      </div>
                      {/* show class and race */}
                      <div className="flex flex-row -mt-8 ml-7">
                        <img
                          className="w-[20px] h-[20px] mx-1"
                          src={getRaceImage(hero.race as number)}
                        ></img>
                        <img
                          className="w-[20px] h-[20px] mx-1"
                          src={getClassImage(hero.class as number)}
                        ></img>
                      </div>
                      {/* <div className="mt-[13px] flex justify-between">
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

                        <span className="text-white text-base">
                          $ {Number(hero?.cost) + 1}
                        </span>
                      </div> */}
                      {/* TODO: add icon */}
                      {/* {SHOW_INFO_LIST.map((attr, _index) => (
                        <div
                          key={String(_index) + "attr" + String(index)}
                          className="mt-[3px] flex justify-between"
                        >
                          <span className="text-white text-base">{attr}</span>
                          <span className="text-white text-base">
                            {hero[attr]}
                          </span>
                        </div>
                      ))} */}
                    </div>
                  </div>
                )
            )}
          </div>

          <div className="flex justify-center items-center mt-4 ml-6">
            <button
              onClick={() => {
                buyRefreshHeroFn();
              }}
              className="flex items-center justify-center refresh h-16 w-[102px] bg-contain bg-no-repeat bg-[url('assets/refresh.png')]"
            >
              <div className="flex item-center justify-center w-4/5 h-auto text-black">
                {!loading && "Refresh 2$"}
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Shop;
