// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {GameConfig, ShopConfig} from "../src/codegen/index.sol";

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
            0, // GameConfig key
            0, // game index
            0, // creature index
            4, // length
            8, // width
            60, // round interval second
            0, // revenue
            0, // revenueGrowthPeriod
            6, // inventory slot num
            expUpgrade //expUpgrade
        );
    }

    function initShopConfig(IWorld _world) internal {
        uint40[] memory rarityRate = new uint40[](10);
        rarityRate[0] = 0x0000000064; // 0  0  0  0  100
        rarityRate[1] = 0x0000001e46; // 0  0  0  30 70
        rarityRate[2] = 0x000005233c; // 0  0  5  35 60
        rarityRate[3] = 0x00000f282d; // 0  0  15 40 45
        rarityRate[4] = 0x0002172823; // 0  2  23 40 35
        rarityRate[5] = 0x00071e211e; // 0  7  30 33 30
        rarityRate[6] = 0x000a1e1e1e; // 0  10 30 30 30
        rarityRate[7] = 0x01131e1919; // 1  19 30 25 25
        rarityRate[8] = 0x031b191914; // 3  27 25 25 20
        rarityRate[9] = 0x071f19160f; // 7  31 25 22 15

        ShopConfig.set(
            _world,
            0,
            5, // slot num
            2, // refresh price
            4, // exp price
            rarityRate
        );
    }
}
