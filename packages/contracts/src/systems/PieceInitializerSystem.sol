// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../library/RunTimePiece.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig} from "../codegen/index.sol";
import {Hero, HeroData} from "../codegen/index.sol";
import {
    RaceSynergyEffect, RaceSynergyEffectData, ClassSynergyEffect, ClassSynergyEffectData
} from "../codegen/index.sol";
import {Piece, PieceData} from "../codegen/index.sol";
import {EffectCache, EffectLib} from "../library/EffectLib.sol";
import {Player} from "../codegen/index.sol";
import {getUniqueEntity} from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import {Utils} from "../library/Utils.sol";

contract PieceInitializerSystem is System {
    uint256 constant RACE_NUMBER = 5;
    uint256 constant CLASS_NUMBER = 5;

    function initPieces(address _player, address _opponent)
        public
        returns (bytes32[] memory allies, bytes32[] memory enemies)
    {
        uint256[5] memory creatureBitMap;
        bytes32[] memory allyHeroIds = Player.getHeroes(_player);
        bytes32[] memory enemyHeroIds = Player.getHeroes(_opponent);
        uint256 allyNum = allyHeroIds.length;
        uint256 enemyNum = enemyHeroIds.length;
        RTPiece[] memory pieces = new RTPiece[](allyNum + enemyNum);
        allies = new bytes32[](allyNum);
        enemies = new bytes32[](enemyNum);

        // init ally piece
        // *Counter = uint4 *_1 | uint4 *_2 | uint4 *_3 | uint4 *_4 | uint4 *_5 |
        uint256 raceCounter;
        uint256 classCounter;
        for (uint256 i; i < allyNum; ++i) {
            bytes32 pieceId = allyHeroIds[i];
            HeroData memory hero = Hero.get(pieceId);
            CreatureData memory data = Creature.get(hero.creatureId);
            if (_setCreatureBitMap(creatureBitMap, hero.creatureId)) {
                raceCounter += 1 << ((uint256(data.race) - 1) * 4);
                classCounter += 1 << ((uint256(data.class) - 1) * 4);
            }
            pieces[i] = RTPieceUtils.NewRTPiece(pieceId, 0, i, hero, data);
            allies[i] = pieceId;
        }
        uint256 allySynergy;
        uint256 enemySynergy;
        (allySynergy, enemySynergy) = _addRaceSynergy(raceCounter, allySynergy, enemySynergy);
        (allySynergy, enemySynergy) = _addClassSynergy(classCounter, allySynergy, enemySynergy);

        (raceCounter, classCounter) = (0, 0);
        creatureBitMap = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
        // init enemy piece
        for (uint256 i; i < enemyNum; ++i) {
            bytes32 pieceId = getUniqueEntity();
            HeroData memory hero = Hero.get(enemyHeroIds[i]);
            CreatureData memory data = Creature.get(hero.creatureId);
            if (_setCreatureBitMap(creatureBitMap, hero.creatureId)) {
                raceCounter += 1 << ((uint256(data.race) - 1) * 4);
                classCounter += 1 << ((uint256(data.class) - 1) * 4);
            }
            pieces[i + allyNum] = RTPieceUtils.NewRTPiece(pieceId, 1, i + allyNum, hero, data);
            enemies[i] = pieceId;
        }
        (enemySynergy, allySynergy) = _addRaceSynergy(raceCounter, enemySynergy, allySynergy);
        (enemySynergy, allySynergy) = _addClassSynergy(classCounter, enemySynergy, allySynergy);

        EffectCache memory cache = EffectLib.NewEffectCache(PIECE_MAX_EFFECT_NUM);
        // apply synergy to ally
        if (allySynergy > 0) {
            console.log("ally synergy %x", allySynergy);
            for (uint256 i; i < allyNum; ++i) {
                pieces[i].applyNewEffects(cache, allySynergy, 1);
            }
        }

        // apply synergy to enemy
        if (enemySynergy > 0) {
            console.log("enemy synergy %x", enemySynergy);
            for (uint256 i; i < enemyNum; ++i) {
                pieces[i + allyNum].applyNewEffects(cache, enemySynergy, 1);
            }
        }

        // write pieces into store
        for (uint256 i; i < allyNum + enemyNum; ++i) {
            pieces[i].writeBack();
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

    function _addRaceSynergy(uint256 _counter, uint256 _effects, uint256 _enemyEffects)
        private
        view
        returns (uint256, uint256)
    {
        uint256 mask = 2 ** 4 - 1;
        uint256 base = 1;
        for (uint256 i; i < RACE_NUMBER; ++i) {
            uint256 count = _counter & mask;
            RaceSynergyEffectData memory data;
            if (count >= 4 * base) {
                data = RaceSynergyEffect.get(4 * base);
            }
            if (data.effect <= 0 && count >= 2 * base) {
                data = RaceSynergyEffect.get(2 * base);
            }
            if (data.effect > 0) {
                if (data.applyTo == 0) {
                    _effects = (_effects << 24) + data.effect;
                } else {
                    _enemyEffects = (_enemyEffects << 24) + data.effect;
                }
            }
            mask <<= 4;
            base <<= 4;
        }
        return (_effects, _enemyEffects);
    }

    function _addClassSynergy(uint256 _counter, uint256 _effects, uint256 _enemyEffects)
        private
        view
        returns (uint256, uint256)
    {
        uint256 mask = 2 ** 4 - 1;
        uint256 base = 1;
        for (uint256 i; i < CLASS_NUMBER; ++i) {
            uint256 count = _counter & mask;
            ClassSynergyEffectData memory data;
            if (count >= 4 * base) {
                data = ClassSynergyEffect.get(4 * base);
            }
            if (data.effect <= 0 && count >= 2 * base) {
                data = ClassSynergyEffect.get(2 * base);
            }
            if (data.effect > 0) {
                if (data.applyTo == 0) {
                    _effects = (_effects << 24) + data.effect;
                } else {
                    _enemyEffects = (_enemyEffects << 24) + data.effect;
                }
            }
            mask <<= 4;
            base <<= 4;
        }
        return (_effects, _enemyEffects);
    }
}
