// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { Game, Player } from "src/codegen/Tables.sol";

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
  function updateCoin(uint32 gameId) public {
    // update player1
    _updatePlayerCoin(gameId, Game.getPlayer1(gameId));

    // update player2
    _updatePlayerCoin(gameId, Game.getPlayer2(gameId));
  }

  function _updatePlayerCoin(uint32 gameId, address player) internal {
    uint256 coinBefore = Player.getCoin(player);

    uint256 coinNow = coinBefore + getBasicIncome(gameId) + getInterestIncome(player) + getStreakBonus(player);

    Player.setCoin(player, uint32(coinNow));
  }

  /**
   * @dev get basic income
   */
  function getBasicIncome(uint32 _gameId) public view returns (uint256) {
    return (1 + uint256(Game.get(_gameId).round)) / 5;
  }

  /**
   * @dev get interest income
   */
  function getInterestIncome(address player) public view returns (uint256) {
    return (uint256(Player.getCoin(player)) / 10);
  }

  /**
   * @dev get win streak bonus
   */
  function getStreakBonus(address _player) public view returns (uint256) {
    // TODO: get real streak
    int8 streak = 0;
    if (streak > 0) {
      return uint256(uint8(streak)) + 2;
    } else {
      return uint256(uint8(0 - streak)) + 2;
    }
  }
}
