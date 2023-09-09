import React, { useCallback, useState } from "react";
import { Button, Modal, message } from "antd";
import { HeroBaseAttr } from "@/hooks/useChessboard";
import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useHeroesAttr } from "@/hooks/useHeroAttr";
import { decodeHero, numberArrayToBigIntArray } from "@/lib/utils";
import { getClassImage, getRaceImage } from "./Synergy";

type HeroListItem = HeroBaseAttr | null;

interface IShopProps {
  isModalOpen: boolean;
  handleCancel: () => void;
}

const SHOW_INFO_LIST = ["health", "attack", "defense", "range"] as const;

export const BG_COLOR = [
  "bg-white",
  "bg-green-500",
  "bg-blue-500",
  "bg-purple-500",
  "bg-yellow-500",
];

const Shop: React.FC<IShopProps> = ({ isModalOpen, handleCancel }) => {
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
    <>
      {contextHolder}
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
                      key={String(index) + hero?.url}
                      onClick={() => buyHeroFn(index, hero)}
                    >
                      <div className="shopItem">
                        <img
                          src={hero?.url}
                          alt={hero?.url}
                          style={{ width: "100%", height: 120 }}
                          className={`w-[120px] h-[120px] bg-blue-600 rounded-lg opacity-100 ${
                            BG_COLOR[Number(hero.rarity || 0)]
                          }`}
                        />
                        <div>
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
                        {SHOW_INFO_LIST.map((attr, _index) => (
                          <div
                            key={String(_index) + "attr" + String(index)}
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
    </>
  );
};

export default Shop;
