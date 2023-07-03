// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creatures, GameConfig } from "../src/codegen/Tables.sol";

library CreatureInitializer {
    function init(IWorld _world) internal {
        // JUGGERNAUT
        Creatures.set(
            _world,
            0,  // index
            650, // health
            60,  // attack
            1,  // range
            5,  // defense
            202,  // speed
            2,  // movement
            "https://www.dota2.com/hero/juggernaut"// uri
        );
        // BREWMASTER
        Creatures.set(
            _world,
            1,  // index
            520, // health
            60,  // attack
            1,  // range
            0,  // defense
            102,  // speed
            16,  // movement
            "https://www.dota2.com/hero/brewmaster"// uri
        );
        // OMNIKNIGHT
        Creatures.set(
            _world,
            2,  // index
            650, // health
            60,  // attack
            1,  // range
            5,  // defense
            204,  // speed
            2,  // movement
            "https://www.dota2.com/hero/omniknight"// uri
        );
        // CRYSTAL MAIDEN
        Creatures.set(
            _world,
            3,  // index
            650, // health
            65,  // attack
            4,  // range
            0,  // defense
            305,  // speed
            1,  // movement
            "https://www.dota2.com/hero/crystalmaiden"// uri
        );
        // RIKI
        Creatures.set(
            _world,
            4,  // index
            520, // health
            60,  // attack
            1,  // range
            0,  // defense
            104,  // speed
            16,  // movement
            "https://www.dota2.com/hero/riki"// uri
        );
        // RUBICK
        Creatures.set(
            _world,
            5,  // index
            650, // health
            65,  // attack
            3,  // range
            0,  // defense
            307,  // speed
            1,  // movement
            "https://www.dota2.com/hero/rubick"// uri
        );
        // ZEUS
        Creatures.set(
            _world,
            6,  // index
            650, // health
            60,  // attack
            1,  // range
            5,  // defense
            206,  // speed
            2,  // movement
            "https://www.dota2.com/hero/zeus"// uri
        );
        // HUSKAR
        Creatures.set(
            _world,
            7,  // index
            650, // health
            60,  // attack
            1,  // range
            5,  // defense
            208,  // speed
            2,  // movement
            "https://www.dota2.com/hero/huskar"// uri
        );

    }
}