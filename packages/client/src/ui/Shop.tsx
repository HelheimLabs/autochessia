import React, { useCallback, useState } from "react";
import { Button, Modal } from "antd";
import { HeroBaseAttr } from "@/hooks/useChessboard";
import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useHeroesAttr } from "@/hooks/useHeroAttr";
import { numberArrayToBigIntArray } from "@/lib/utils";
import { getClassImage, getRaceImage } from "./Synergy";

type HeroListItem = HeroBaseAttr | null;

interface IShopProps {
  isModalOpen: boolean;
  handleCancel: () => void;
}

const SHOW_INFO_LIST = ["health", "attack", "defense", "range"] as const;

const Shop: React.FC<IShopProps> = ({ isModalOpen, handleCancel }) => {
  const {
    components: { Player },
    systemCalls: { buyHero, buyRefreshHero },
    network: { playerEntity },
  } = useMUD();

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
        <div className="grid shop-wrap">
          <div className="flex items-center justify-around">
            {heroAttrs?.map(
              (hero: HeroListItem, index: number) =>
                hero && (
                  <div
                    className={`${!hero?.creature ? "invisible" : " block"} `}
                    key={index}
                    onClick={() => buyHero(index)}
                  >
                    <div className="shopItem">
                      <img
                        src={hero?.url}
                        alt={hero?.url}
                        style={{ width: "100%", height: 120 }}
                        className="w-[120px] h-[120px] bg-blue-600 rounded-lg opacity-100"
                      />
                      {/* show class and race */}
                      <div className="flex felx-row">
                        <img
                          className="w-[30px] h-[30px] mx-1"
                          src={getRaceImage(hero.race)}
                        ></img>
                        <img
                          className="w-[30px] h-[30px] mx-1"
                          src={getClassImage(hero.class)}
                        ></img>
                      </div>
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
                        <span className="text-white text-base">
                          $ {Number(hero?.cost) + 1}
                        </span>
                      </div>
                      {/* TODO: add icon */}
                      {SHOW_INFO_LIST.map((attr) => (
                        <div
                          key={hero[attr]}
                          className="mt-[3px] flex justify-between"
                        >
                          <span className="text-white text-base">{attr}</span>
                          <span className="text-white text-base">
                            {hero[attr]}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )
            )}
          </div>

          <div className="flex justify-center items-center mt-[50px]">
            <Button
              loading={loading}
              onClick={() => {
                buyRefreshHeroFn();
              }}
              className="refresh rounded-full w-44 bg-red-500 hover:bg-white"
            >
              {!loading && "Refresh Hero $2"}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
};

export default Shop;
