// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig} from "../codegen/Tables.sol";
import {Hero, HeroData} from "../codegen/Tables.sol";
import {RaceSynergyEffect, ClassSynergyEffect} from "../codegen/Tables.sol";
import {Piece, PieceData} from "../codegen/Tables.sol";
import {RTPiece, RTPieceUtils} from "../library/RunTimePiece.sol";
import {EffectCache, EffectLib} from "../library/EffectLib.sol";
import {Player} from "../codegen/Tables.sol";
import {getUniqueEntity} from "@latticexyz/world/src/modules/uniqueentity/getUniqueEntity.sol";
import {Utils} from "../library/Utils.sol";

contract PieceInitializerSystem is System {
    uint256 constant RACE_NUMBER = 5;
    uint256 constant CLASS_NUMBER = 5;

    function initPieces(address _player, bool _atHome) public returns (bytes32[] memory ids) {
        bytes32[] memory heroIds = Player.getHeroes(_player);
        uint256 num = heroIds.length;
        // *Counter = uint4 *_1 | uint4 *_2 | uint4 *_3 | uint4 *_4 | uint4 *_5 |
        uint256 raceCounter;
        uint256 classCounter;
        uint256[5] memory creatureBitMap;
        ids = new bytes32[](num);
        PieceData[] memory pieces = new PieceData[](num);
        for (uint256 i; i < num; ++i) {
            bytes32 heroId = heroIds[i];
            bytes32 pieceId = _atHome ? heroId : getUniqueEntity();
            HeroData memory hero = Hero.get(heroId);
            CreatureData memory data = Creature.get(hero.creatureId);
            if (_setCreatureBitMap(creatureBitMap, hero.creatureId)) {
                raceCounter += 1 << ((uint256(data.race) - 1) * 4);
                classCounter += 1 << ((uint256(data.class) - 1) * 4);
            }
            pieces[i] = PieceData({
                x: _atHome ? uint8(hero.x) : uint8(GameConfig.getLength(0) * 2 - 1 - hero.x),
                y: uint8(hero.y),
                // todo change health back to uint32
                health: uint24(data.health),
                creatureId: hero.creatureId,
                effects: 0
            });
            ids[i] = pieceId;
        }

        // console.log("class counter %x, race counter %x", classCounter, raceCounter);

        // synergy
        uint256 synergyEffects = _addClassSynergy(classCounter, _addRaceSynergy(raceCounter, 0));

        // console.log("synergy effect %x", synergyEffects);

        // write pieces into store

        EffectCache memory cache = EffectLib.NewEffectCache(RTPieceUtils.MAX_EFFECT_NUM);
        for (uint256 i; i < num; ++i) {
            pieces[i].effects = uint192(synergyEffects);
            // update health
            RTPiece memory rtPiece;
            rtPiece.maxHealth = pieces[i].health;
            rtPiece.effects = RTPieceUtils.sliceEffects(uint192(synergyEffects));
            rtPiece.updateAttribute(cache);
            pieces[i].health = uint24(rtPiece.maxHealth);
            // write into store
            Piece.set(ids[i], pieces[i]);
        }
    }

    function _setCreatureBitMap(uint256[5] memory _bitMap, uint24 _creatureId) private pure returns (bool set) {
        uint256 rarity = Utils.getHeroRarity(_creatureId);
        uint256 internalIndex = Utils.getHeroCreatureInternalIndex(_creatureId);
        if ((_bitMap[rarity] & (1 << internalIndex)) == 0) {
            set = true;
            _bitMap[rarity] += 1 << internalIndex;
            return set;
        }
    }

    function _addRaceSynergy(uint256 _counter, uint256 _effects) private view returns (uint256) {
        uint256 mask = 2 ** 4 - 1;
        uint256 base = 1;
        for (uint256 i; i < RACE_NUMBER; ++i) {
            uint256 count = _counter & mask;
            if (count / (4 * base) > 0) {
                uint256 effect = RaceSynergyEffect.get(4 * base);
                console.log("add race synergy key %x, value %x", 4 * base, effect);
                _effects = (_effects << 24) + effect;
            } else if (count / (2 * base) > 0) {
                uint256 effect = RaceSynergyEffect.get(2 * base);
                console.log("add race synergy key %x, value %x", 2 * base, effect);
                _effects = (_effects << 24) + effect;
            }
            mask <<= 4;
            base <<= 4;
        }
        return _effects;
    }

    function _addClassSynergy(uint256 _counter, uint256 _effects) private view returns (uint256) {
        uint256 mask = 2 ** 4 - 1;
        uint256 base = 1;
        for (uint256 i; i < CLASS_NUMBER; ++i) {
            uint256 count = _counter & mask;
            if (count / (4 * base) > 0) {
                uint256 effect = ClassSynergyEffect.get(4 * base);
                console.log("add class synergy key %x, value %x", 4 * base, effect);
                _effects == (_effects << 24) + effect;
            } else if (count / (2 * base) > 0) {
                uint256 effect = ClassSynergyEffect.get(2 * base);
                console.log("add class synergy key %x, value %x", 2 * base, effect);
                _effects == (_effects << 24) + effect;
            }
            mask <<= 4;
            base <<= 4;
        }
        return _effects;
    }
}
