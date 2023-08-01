// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { GameConfig, Game, Player } from "src/codegen/Tables.sol";

contract ExperienceSystem is System {
  /**
   * @dev call as sub-system
   * @dev increase exp and upgrade if meet
   * @param player player address
   */
  function addExperience(address player, uint256 increasedExp) public {
    uint256 exp = Player.getExp(player);
    uint256 tier = Player.getTier(player);

    uint256 currentExp = exp + increasedExp;

    // recusive upgrade tier
    while ((currentExp > GameConfig.getExpUpgrade(0)[tier])) {
      currentExp -= GameConfig.getExpUpgrade(0)[tier];
      tier++;
    }

    // set tier
    Player.setExp(player, uint32(currentExp));
    Player.setTier(player, uint8(tier));
  }
}
