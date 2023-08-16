// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {Creature, CreatureUri, GameConfig} from "../src/codegen/Tables.sol";

library CreatureInitializer {
    function _genCreatureIndex(uint256 _tier, uint256 _index) private returns (uint16 index) {
        index = uint16((_tier << 8) + _index);
    }

    function _initOneKindOfCreature(
        IWorld _world,
        uint8 _index,
        uint32 _health,
        uint32 _attack,
        uint32 _range,
        uint32 _defense,
        uint32 _speed,
        uint32 _movement,
        string memory _uri
    ) private {
        Creature.set(_world, _genCreatureIndex(0, _index), _health, _attack, _range, _defense, _speed, _movement);
        Creature.set(
            _world,
            _genCreatureIndex(1, _index),
            _health * 210 / 100,
            _attack * 210 / 100,
            _range,
            _defense * 210 / 100,
            _speed,
            _movement
        );
        Creature.set(
            _world,
            _genCreatureIndex(2, _index),
            _health * 330 / 100,
            _attack * 330 / 100,
            _range,
            _defense * 330 / 100,
            _speed,
            _movement
        );
        CreatureUri.set(_world, _index, _uri);
    }

    function init(IWorld _world) internal {
        // creature id start from 1
        // BREWMASTER
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
        _initOneKindOfCreature(
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
