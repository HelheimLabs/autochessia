// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";

import { PlayerGlobal, Player, ShopConfig, GameConfig } from "src/codegen/Tables.sol";

import { IWorld } from "src/codegen/world/IWorld.sol";

contract RefreshHeroesSystem is System {
  /**
   * @dev refresh implementation
   */
  function getRefreshedHeroes(uint32 gameId) public view returns (uint64[] memory char) {
    uint256 r = IWorld(_world()).getRandomNumberInGame(gameId);

    uint256 slotNumber = ShopConfig.getSlotNum(0);
    uint256 creatureCount = GameConfig.getCreatureIndex(0);
    char = new uint64[](slotNumber);
    // loop for each tier rate
    uint8[] memory tierRate = ShopConfig.getTierRate(0);
    for (uint256 i = 0; i < slotNumber; ) {
      // get new random number on each loop
      r = uint256(keccak256(abi.encode(r)));

      for (uint256 j = 0; j < tierRate.length; ) {
        uint256 remainder = r % 100;
        // it means the rate locates in j+1 tier
        if (remainder < tierRate[j]) {
          // creature Id + tier packed
          // creature Id start from 1
          char[i] = IWorld(_world()).encodeHero(uint32(r % creatureCount) + 1, uint32(j));

          break;
        }
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
    Player.setHeroAltar(player, getRefreshedHeroes(PlayerGlobal.getGameId(player)));
  }
}
