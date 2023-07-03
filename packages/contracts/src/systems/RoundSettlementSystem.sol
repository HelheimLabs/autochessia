// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { IWorld } from "src/codegen/world/IWorld.sol";

contract RoundSettlementSystem is System {
  /**
   * @notice call as sub system internally
   * @notice settle the all user status after a round end
   */
  function settleRound(uint32 gameId, address[] memory players) public {
    // TODO: check Game status
    for (uint256 i = 0; i < players.length; ) {
      address player = players[0];
      // add experience
      IWorld(_world()).addExperience(player, 1);

      // add coin
      IWorld(_world()).updatePlayerCoin(gameId, player);

      // refresh heros
      IWorld(_world()).refreshHeros(player);

      unchecked {
        i++;
      }
    }
  }
}
