// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";
import {SystemSwitch} from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";

import {PlayerGlobal, Player, ShopConfig, GameConfig} from "src/codegen/index.sol";

import {IWorld} from "src/codegen/world/IWorld.sol";

import {Utils} from "src/library/Utils.sol";

import "forge-std/Test.sol";

contract RefreshHeroesSystem is System {
    /**
     * @dev refresh implementation
     */
    function getRefreshedHeroes(uint32 gameId, uint8 playerTier) public returns (uint24[] memory char) {
        uint256 r =
            abi.decode(SystemSwitch.call(abi.encodeCall(IWorld(_world()).getRandomNumberInGame, (gameId))), (uint256));

        uint256 slotNumber = ShopConfig.getSlotNum(0);
        uint256 creatureCounter = GameConfig.getCreatureCounter(0);
        char = new uint24[](slotNumber);
        uint40 rarityRate = ShopConfig.getItemRarityRate(0, playerTier);
        for (uint256 i = 0; i < slotNumber;) {
            // get new random number on each loop
            r = uint256(keccak256(abi.encode(r)));
            uint256 rarityRateCopy = rarityRate;
            uint256 remainder = r % 100;
            r >>= 8;
            for (uint256 j; j < 5;) {
                if (remainder < uint8(rarityRateCopy)) {
                    // creature Id = tier | rarity | internal Id
                    // internal Id start from 1
                    uint256 count = uint8(creatureCounter >> (j * 8));
                    char[i] = uint24(Utils.encodeHero(0, (j << 8) + (r % count) + 1));
                    break;
                }
                remainder -= uint8(rarityRateCopy);
                rarityRateCopy >>= 8;
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev refresh heros for one player
     * @dev called as sub-system
     * @dev two place to call it
     * @dev 1. refresh on every round start
     * @dev 2. refersh when user buy refresh
     */
    function refreshHeroes(address player) public {
        Player.setHeroAltar(player, getRefreshedHeroes(PlayerGlobal.getGameId(player), Player.getTier(player)));
    }
}
