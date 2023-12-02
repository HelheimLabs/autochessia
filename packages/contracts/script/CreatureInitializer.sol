// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {Creature, CreatureUri, GameConfig} from "../src/codegen/index.sol";
import {CreatureRace, CreatureClass} from "../src/codegen/common.sol";

library CreatureInitializer {
    // creature internal index start from 1
    function _increCreatureCounter(uint256 _rarity) private returns (uint256 current) {
        uint256 counter = GameConfig.getCreatureCounter(0);
        counter += 1 << ((_rarity - 1) * 8);
        current = uint8(counter >> ((_rarity - 1) * 8));
        GameConfig.setCreatureCounter(0, uint40(counter));
    }

    function _genCreatureIndex(uint256 _tier, uint256 _rarity, uint256 _index) private pure returns (uint24 index) {
        return uint24((_tier << 16) + ((_rarity - 1) << 8) + _index);
    }

    function _initOneKindOfCreature(
        IWorld _world,
        uint8 _rarity,
        CreatureRace _race,
        CreatureClass _class,
        uint32 _health,
        uint32 _attack,
        uint32 _range,
        uint32 _defense,
        uint32 _speed,
        uint32 _movement,
        string memory _uri
    ) private {
        uint256 internalIndex = _increCreatureCounter(_rarity);
        Creature.set(
            _genCreatureIndex(0, _rarity, internalIndex),
            _race,
            _class,
            _health,
            _attack,
            _range,
            _defense,
            _speed,
            _movement
        );
        Creature.set(
            _genCreatureIndex(1, _rarity, internalIndex),
            _race,
            _class,
            _health * 210 / 100,
            _attack * 210 / 100,
            _range,
            _defense * 210 / 100,
            _speed,
            _movement
        );
        Creature.set(
            _genCreatureIndex(2, _rarity, internalIndex),
            _race,
            _class,
            _health * 330 / 100,
            _attack * 330 / 100,
            _range,
            _defense * 330 / 100,
            _speed,
            _movement
        );
        CreatureUri.set(uint16(_genCreatureIndex(0, _rarity, internalIndex)), _uri);
    }

    function init(IWorld _world) internal {
        // Huskar
        _initOneKindOfCreature(
            _world,
            5, // rarity
            CreatureRace.TROLL,
            CreatureClass.KNIGHT,
            1000, // health
            90, // attack
            3, // range
            10, // defense
            208, // speed
            2, // movement
            "https://www.dota2.com/hero/huskar" // uri
        );
        // Dazzle
        _initOneKindOfCreature(
            _world,
            2, // rarity
            CreatureRace.TROLL,
            CreatureClass.WARLOCK,
            550, // health
            62, // attack
            3, // range
            5, // defense
            304, // speed
            2, // movement
            "https://www.dota2.com/hero/dazzle" // uri
        );
        // Batrider
        _initOneKindOfCreature(
            _world,
            1, // rarity
            CreatureRace.TROLL,
            CreatureClass.KNIGHT,
            500, // health
            47, // attack
            3, // range
            5, // defense
            302, // speed
            2, // movement
            "https://www.dota2.com/hero/batrider" // uri
        );
        // Brewmaster
        _initOneKindOfCreature(
            _world,
            2, // rarity
            CreatureRace.PANDAREN,
            CreatureClass.ASSASSIN,
            800, // health
            55, // attack
            1, // range
            4, // defense
            102, // speed
            2, // movement
            "https://www.dota2.com/hero/brewmaster" // uri
        );
        // Ember Spirit
        _initOneKindOfCreature(
            _world,
            3, // rarity
            CreatureRace.PANDAREN,
            CreatureClass.ASSASSIN,
            800, // health
            75, // attack
            1, // range
            5, // defense
            101, // speed
            3, // movement
            "https://www.dota2.com/hero/emberspirit" // uri
        );
        // Storm Spirit
        _initOneKindOfCreature(
            _world,
            3, // rarity
            CreatureRace.PANDAREN,
            CreatureClass.MAGE,
            700, // health
            75, // attack
            3, // range
            3, // defense
            103, // speed
            3, // movement
            "https://www.dota2.com/hero/stormspirit" // uri
        );
        // Earth Spirit
        _initOneKindOfCreature(
            _world,
            3, // rarity
            CreatureRace.PANDAREN,
            CreatureClass.ASSASSIN,
            900, // health
            65, // attack
            1, // range
            9, // defense
            103, // speed
            3, // movement
            "https://www.dota2.com/hero/earthspirit" // uri
        );
        // Juggernaut
        _initOneKindOfCreature(
            _world,
            2, // rarity
            CreatureRace.ORC,
            CreatureClass.WARRIOR,
            600, // health
            69, // attack
            1, // range
            5, // defense
            202, // speed
            2, // movement
            "https://www.dota2.com/hero/juggernaut" // uri
        );
        // Axe
        _initOneKindOfCreature(
            _world,
            1, // rarity
            CreatureRace.ORC,
            CreatureClass.WARRIOR,
            700, // health
            52, // attack
            1, // range
            5, // defense
            203, // speed
            2, // movement
            "https://www.dota2.com/hero/axe" // uri
        );
        // Witch Doctor
        _initOneKindOfCreature(
            _world,
            2, // rarity
            CreatureRace.ORC,
            CreatureClass.WARLOCK,
            550, // health
            45, // attack
            3, // range
            5, // defense
            308, // speed
            1, // movement
            "https://www.dota2.com/hero/witchdoctor" // uri
        );
        // Disruptor
        _initOneKindOfCreature(
            _world,
            4, // rarity
            CreatureRace.ORC,
            CreatureClass.WARLOCK,
            800, // health
            47, // attack
            4, // range
            5, // defense
            309, // speed
            1, // movement
            "https://www.dota2.com/hero/disruptor" // uri
        );
        // Omniknight
        _initOneKindOfCreature(
            _world,
            3, // rarity
            CreatureRace.HUMAN,
            CreatureClass.KNIGHT,
            750, // health
            55, // attack
            1, // range
            10, // defense
            204, // speed
            2, // movement
            "https://www.dota2.com/hero/omniknight" // uri
        );
        // Crystal Maiden
        _initOneKindOfCreature(
            _world,
            1, // rarity
            CreatureRace.HUMAN,
            CreatureClass.MAGE,
            500, // health
            50, // attack
            4, // range
            5, // defense
            305, // speed
            1, // movement
            "https://www.dota2.com/hero/crystalmaiden" // uri
        );
        // Lina
        _initOneKindOfCreature(
            _world,
            3, // rarity
            CreatureRace.HUMAN,
            CreatureClass.MAGE,
            500, // health
            62, // attack
            4, // range
            5, // defense
            301, // speed
            1, // movement
            "https://www.dota2.com/hero/lina" // uri
        );
        // Kunkka
        _initOneKindOfCreature(
            _world,
            4, // rarity
            CreatureRace.HUMAN,
            CreatureClass.WARRIOR,
            900, // health
            82, // attack
            1, // range
            8, // defense
            205, // speed
            2, // movement
            "https://www.dota2.com/hero/kunkka" // uri
        );
        // Zeus
        _initOneKindOfCreature(
            _world,
            5, // rarity
            CreatureRace.GOD,
            CreatureClass.MAGE,
            950, // health
            60, // attack
            3, // range
            0, // defense
            306, // speed
            2, // movement
            "https://www.dota2.com/hero/zeus" // uri
        );
        // Mars
        _initOneKindOfCreature(
            _world,
            1, // rarity
            CreatureRace.GOD,
            CreatureClass.WARRIOR,
            800, // health
            0, // attack
            1, // range
            6, // defense
            209, // speed
            2, // movement
            "https://www.dota2.com/hero/mars" // uri
        );
    }
}
