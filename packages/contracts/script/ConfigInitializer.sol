// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { GameConfig, ShopConfig, CreatureConfig } from "../src/codegen/Tables.sol";

library ConfigInitializer {
  function initGameConfig(IWorld _world) internal {
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
      6,  // inventory slot num
      expUpgrade //expUpgrade
    );
  }

  function initShopConfig(IWorld _world) internal {
    uint8[] memory tierPrice = new uint8[](2);
    tierPrice[0] = 1;
    tierPrice[1] = 5;
    uint8[] memory tierRate = new uint8[](2);
    tierRate[0] = 80;
    tierRate[1] = 100;
    ShopConfig.set(
      _world,
      5,
      2,
      4,
      tierPrice,
      tierRate
    );
  }

  function initCreatureConfig(IWorld _world) internal {
    uint16[] memory tierAmplifier = new uint16[](2);
    tierAmplifier[0] = 210;
    tierAmplifier[1] = 330;
    CreatureConfig.set(
      _world,
      tierAmplifier,
      tierAmplifier,
      tierAmplifier
    );
  }
}