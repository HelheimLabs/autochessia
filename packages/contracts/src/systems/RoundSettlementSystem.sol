// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { IWorld } from "src/codegen/world/IWorld.sol";

import { Game } from "src/codegen/Tables.sol";

contract RoundSettlementSystem is System {
  /**
   * @notice call as sub system internally
   * @notice settle the all user status after a round end
   */
  function settleRound(uint32 gameId) public {
    // TODO: check Game status

    // settle player
    address[] memory players = Game.getPlayers(gameId);
    uint256 num = players.length;
    for (uint256 i; i < num; ++i) {
      _settlePlayer(gameId, players[i]);
    }
  }

  function _settlePlayer(uint32 gameId, address player) internal {
    // add experience
    IWorld(_world()).addExperience(player, 1);

    // add coin
    IWorld(_world()).updatePlayerCoin(gameId, player);

    // refresh heros
    IWorld(_world()).refreshHeroes(player);
  }
}
