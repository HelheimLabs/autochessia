import React from "react";
import { Modal } from "antd";
import { HeroBaseAttr } from "@/hooks/useChessboard";
import { useMUD } from "@/MUDContext";
import { useComponentValue } from "@latticexyz/react";
import { useHeroesAttr } from "@/hooks/useHeroAttr";

type HeroListItem = HeroBaseAttr | null;

interface IShopProps {
  isModalOpen: boolean;
  handleCancel: () => void;
}

const SHOWINFOLIST = ["health", "attack", "defense", "range"] as const;

const Shop: React.FC<IShopProps> = ({ isModalOpen, handleCancel }) => {
  const {
    components: { Player },
    systemCalls: { buyHero, buyRefreshHero },
    network: { playerEntity },
  } = useMUD();

  // const [n, forceRender] = useState(0);

  const playerValue = useComponentValue(Player, playerEntity);
  const heroAttrs = useHeroesAttr(playerValue?.heroAltar || []);

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
                          $ {hero?.cost}
                        </span>
                      </div>
                      {/* TODO: add icon */}
                      {SHOWINFOLIST.map((attr) => (
                        <div className="mt-[3px] flex justify-between">
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
            <button
              onClick={() => {
                buyRefreshHero();
              }}
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
