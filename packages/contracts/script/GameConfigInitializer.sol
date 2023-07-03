// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameConfig } from "../src/codegen/Tables.sol";

library GameConfigInitializer {
  function init(IWorld _world) internal {
    uint8[] memory expUpgrade = new uint8[](8);
    expUpgrade[0] = 1;
    expUpgrade[1] = 1;
    expUpgrade[2] = 4;
    expUpgrade[3] = 8;
    expUpgrade[4] = 16;
    expUpgrade[5] = 32;
    expUpgrade[6] = 48;
    expUpgrade[7] = 56;
    
    GameConfig.set(
      _world,
      0, // game index
      8, // creature index
      4, // length
      8, // width
      0, // revenue
      0, // revenueGrowthPeriod
      0,  // inventory slot num
      expUpgrade //expUpgrade
    );
  }
}