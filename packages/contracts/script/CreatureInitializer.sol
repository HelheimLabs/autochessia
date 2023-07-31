// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { console } from "forge-std/console.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Creature, GameConfig } from "../src/codegen/Tables.sol";

library CreatureInitializer {
  function init(IWorld _world) internal {
    // creature id start from 1
    // BREWMASTER
    Creature.set(
      _world,
      1, // index
      520, // health
      60, // attack
      1, // range
      0, // defense
      102, // speed
      16, // movement
      "https://www.dota2.com/hero/brewmaster" // uri
    );
    // OMNIKNIGHT
    Creature.set(
      _world,
      2, // index
      650, // health
      60, // attack
      1, // range
      5, // defense
      204, // speed
      2, // movement
      "https://www.dota2.com/hero/omniknight" // uri
    );
    // CRYSTAL MAIDEN
    Creature.set(
      _world,
      3, // index
      650, // health
      65, // attack
      4, // range
      0, // defense
      305, // speed
      1, // movement
      "https://www.dota2.com/hero/crystalmaiden" // uri
    );
    // RIKI
    Creature.set(
      _world,
      4, // index
      520, // health
      60, // attack
      1, // range
      0, // defense
      104, // speed
      16, // movement
      "https://www.dota2.com/hero/riki" // uri
    );
    // RUBICK
    Creature.set(
      _world,
      5, // index
      650, // health
      65, // attack
      3, // range
      0, // defense
      307, // speed
      1, // movement
      "https://www.dota2.com/hero/rubick" // uri
    );
    // ZEUS
    Creature.set(
      _world,
      6, // index
      650, // health
      60, // attack
      1, // range
      5, // defense
      206, // speed
      2, // movement
      "https://www.dota2.com/hero/zeus" // uri
    );
    // HUSKAR
    Creature.set(
      _world,
      7, // index
      650, // health
      60, // attack
      1, // range
      5, // defense
      208, // speed
      2, // movement
      "https://www.dota2.com/hero/huskar" // uri
    );
    // JUGGERNAUT
    Creature.set(
      _world,
      8, // index
      650, // health
      60, // attack
      1, // range
      5, // defense
      202, // speed
      2, // movement
      "https://www.dota2.com/hero/juggernaut" // uri
    );
  }
}
