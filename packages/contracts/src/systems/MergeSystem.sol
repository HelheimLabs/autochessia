// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";
import {Hero, Player, Game, HeroData} from "../codegen/index.sol";
import {GameStatus} from "src/codegen/common.sol";
import {Utils} from "../library/Utils.sol";
import {IWorld} from "src/codegen/world/IWorld.sol";

contract MergeSystem is System {
    uint8 public constant mergeNum = 3;

    function merge(address _player, uint256 _hero) public returns (bool merged, uint256 mergedHero) {
        IWorld world = IWorld(_world());
        // tier max = 2
        if (Utils.getHeroTier(_hero) > 1) {
            return (false, _hero);
        }
        uint256[2] memory indexes;
        bool[2] memory onBoard;
        uint256 num;
        // search priority: hero on board higher than hero in inventory
        uint256 length = Player.lengthHeroes(_player);
        for (uint256 i; i < length; ++i) {
            bytes32 heroId = Player.getItemHeroes(_player, i);
            if (_hero == Hero.getCreatureId(heroId)) {
                indexes[num] = i;
                onBoard[num] = true;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return (true, Utils.levelUpHero(_hero));
            }
        }

        length = Player.lengthInventory(_player);
        for (uint256 i; i < length; ++i) {
            if (_hero == Player.getItemInventory(_player, i)) {
                indexes[num] = i;
                ++num;
            }
            if (num == 2) {
                mergeHero(_player, indexes, onBoard);
                return (true, Utils.levelUpHero(_hero));
            }
        }

        mergedHero = _hero;
    }

    /**
     *
     * @param _player player address
     * @param _indexes an array of indexes of player's hero on board or in inventory that he wants to merge
     * @param _onBoard an array of bool which indicates whether the corresponding index is based on Player.heroes
     */
    function mergeHero(address _player, uint256[2] memory _indexes, bool[2] memory _onBoard) private {
        // delete hero on board and hero in inventory
        // start from the last index to the first index.
        // Because the indexes are put into array from lower to higher, then
        // pop a lower index would influent later popping a higher index.
        if (_onBoard[1]) {
            Utils.deleteHeroByIndex(_player, _indexes[1]);
        } else {
            Utils.popInventoryByIndex(_player, _indexes[1]);
        }

        if (_onBoard[0]) {
            Utils.deleteHeroByIndex(_player, _indexes[0]);
        } else {
            Utils.popInventoryByIndex(_player, _indexes[0]);
        }
    }
}
