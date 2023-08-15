// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {System} from "@latticexyz/world/src/System.sol";

import {Game, Player} from "src/codegen/Tables.sol";
import {Math} from "@openzeppelin-contracts/utils/math/Math.sol";

contract CoinIncomeSystem is System {
    /**
     * @note coin source:
     * 1. basic income: quotient of the current round divided by 5
     * 2. interest: quotient of the current coin divided by 10
     * 3. win streak bonus: win streak plus 1
     * 4. lose streak bonus: lost streak plus 1
     */

    /**
     * @dev only called when game to next round, and update each user
     * @dev work as internal sub system
     */

    function updatePlayerCoin(uint32 gameId, address player) public {
        uint256 coinBefore = Player.getCoin(player);

        uint256 coinNow = coinBefore + getBasicIncome(gameId) + getInterestIncome(player) + getStreakBonus(player);

        Player.setCoin(player, uint32(coinNow));
    }

    /**
     * @dev get basic income
     * @dev maximum 5
     */
    function getBasicIncome(uint32 _gameId) public view returns (uint256) {
        return Math.min(1 + uint256(Game.get(_gameId).round) / 5, 5);
    }

    /**
     * @dev get interest income
     * @dev maximum 5
     */
    function getInterestIncome(address player) public view returns (uint256) {
        return Math.min((uint256(Player.getCoin(player)) / 10), 5);
    }

    /**
     * @dev get win streak bonus
     * @dev when win, give 1 coin
     * @dev when win once, give 0 for streak
     * @dev when win twice give 1 for streak
     * @dev when lose, give 0 coin
     * @dev when lose once, give 0 for streak
     * @dev when lose twice, give 1 for streak
     * @dev maximum streak reward is 3
     */
    function getStreakBonus(address player) public view returns (uint256) {
        int8 streak = Player.getStreakCount(player);
        if (streak == 0) {
            return 0;
        }
        if (streak > 0) {
            return Math.min(uint256(uint8(streak)) - 1, 3) + 1;
        } else {
            return Math.min(uint256(uint8(0 - streak)) - 1, 3);
        }
    }
}
