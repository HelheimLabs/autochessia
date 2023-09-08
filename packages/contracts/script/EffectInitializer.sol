// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../src/library/Constant.sol";
import "../src/library/PieceActionLib.sol";
import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {Effect, EffectData, RaceSynergyEffect, ClassSynergyEffect} from "../src/codegen/Tables.sol";
import {EventType, Attribute, EnvExtractor, ApplyTo} from "../src/codegen/Types.sol";

library EffectInitializer {
    function init(IWorld _world) internal {
        _initEffects(_world);
        _initSynergy(_world);
    }

    function _initSynergy(IWorld _world) private {
        // race synergy
        //     orc: + max health 100/300
        RaceSynergyEffect.set(_world, 0x000200, 0, 0x8080_ff);
        RaceSynergyEffect.set(_world, 0x000400, 0, 0x8081_ff);
        //     god: + attack 20%
        RaceSynergyEffect.set(_world, 0x020000, 0, 0x8082_ff);
        //     pandaren: + evasion 20/30
        RaceSynergyEffect.set(_world, 0x000020, 0, 0x8083_ff);
        RaceSynergyEffect.set(_world, 0x000040, 0, 0x8084_ff);
        //     human: + dmg_reduction 10/20 when at least one ally is around
        RaceSynergyEffect.set(_world, 0x002000, 0, 0x0c80_ff);
        RaceSynergyEffect.set(_world, 0x004000, 0, 0x0c81_ff);
        //     troll: + 10% attack the enemy twice
        RaceSynergyEffect.set(_world, 0x000002, 0, 0x1c80_ff);

        // class synergy
        //     mage: - enemy defense 20%/40%
        ClassSynergyEffect.set(_world, 0x020000, 1, 0x8100_ff);
        ClassSynergyEffect.set(_world, 0x040000, 1, 0x8101_ff);
        //     warrior: + defense 5/10
        ClassSynergyEffect.set(_world, 0x002000, 0, 0x8102_ff);
        ClassSynergyEffect.set(_world, 0x004000, 0, 0x8103_ff);
        //     knight: + immunity 10
        ClassSynergyEffect.set(_world, 0x000002, 0, 0x8104_ff);
        //     assassin: + crit 10/20
        ClassSynergyEffect.set(_world, 0x000200, 0, 0x8105_ff);
        ClassSynergyEffect.set(_world, 0x000400, 0, 0x8106_ff);
        //     warlock: + 10% stun enemy for 1 turn on attack
        ClassSynergyEffect.set(_world, 0x000020, 0, 0x1d00_ff);
    }

    function _initEffects(IWorld _world) private {
        // index = binary(1_0000_0_001000_0000) = 0x8080
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            8, /* place_holder */
            0,
            _newModifier([Attribute.MAX_HEALTH], [false], [false], [uint16(100)]),
            0
        );
        // index = binary(1_0000_0_001000_0001) = 0x8081
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            8, /* place_holder */
            1,
            _newModifier([Attribute.MAX_HEALTH], [false], [false], [uint16(300)]),
            0
        );
        // index = binary(1_0000_0_001000_0002) = 0x8082
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            8, /* place_holder */
            2,
            _newModifier([Attribute.ATTACK], [true], [false], [uint16(120)]),
            0
        );
        // index = binary(1_0000_0_001000_0003) = 0x8083
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            8, /* place_holder */
            3,
            _newModifier([Attribute.EVASION], [false], [false], [uint16(20)]),
            0
        );
        // index = binary(1_0000_0_001000_0004) = 0x8084
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            8, /* place_holder */
            4,
            _newModifier([Attribute.EVASION], [false], [false], [uint16(30)]),
            0
        );
        // index = binary(1_0000_0_010000_0000) = 0x8100
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            0,
            _newModifier([Attribute.DEFENSE], [true], [false], [uint16(80)]),
            0
        );
        // index = binary(1_0000_0_010000_0001) = 0x8101
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            1,
            _newModifier([Attribute.DEFENSE], [true], [false], [uint16(60)]),
            0
        );
        // index = binary(1_0000_0_010000_0002) = 0x8102
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            2,
            _newModifier([Attribute.DEFENSE], [false], [false], [uint16(5)]),
            0
        );
        // index = binary(1_0000_0_010000_0003) = 0x8103
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            3,
            _newModifier([Attribute.DEFENSE], [false], [false], [uint16(10)]),
            0
        );
        // index = binary(1_0000_0_010000_0004) = 0x8104
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            4,
            _newModifier([Attribute.IMMUNITY], [false], [false], [uint16(10)]),
            0
        );
        // index = binary(1_0000_0_010000_0005) = 0x8105
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            5,
            _newModifier([Attribute.CRIT], [false], [false], [uint16(10)]),
            0
        );
        // index = binary(1_0000_0_010000_0006) = 0x8106
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            16, /* place_holder */
            6,
            _newModifier([Attribute.CRIT], [false], [false], [uint16(20)]),
            0
        );
        // index = binary(1_0000_0_000100_0000) = 0x8040
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            4, /* place_holder */
            0,
            _newModifier([Attribute.STATUS], [false], [false], [CAN_ACT]),
            0
        );
        // index = binary(1_0000_0_000100_0001) = 0x8041
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            4, /* place_holder */
            1,
            _newModifier([Attribute.DMG_REDUCTION], [false], [false], [uint16(15)]),
            0
        );
        // index = binary(1_0000_0_000100_0002) = 0x8042
        _newEffect(
            _world,
            true,
            EventType.NONE,
            false,
            4, /* place_holder */
            2,
            _newModifier([Attribute.DMG_REDUCTION], [false], [false], [uint16(30)]),
            0
        );

        // with event ON_ATTACK
        //   class synergy
        // index = binary(0_0011_1_010000_0000) = 0x1d00
        _newEffect(
            _world,
            false,
            EventType.ON_ATTACK,
            true,
            16, /* place_holder */
            0,
            0,
            _newTriggerWithoutSubAction(
                _newTriggerChecker(EnvExtractor.POSSIBILITY, 10, 0), [ApplyTo.INDIRECT], [0x804001]
            )
        );
        //   race synergy
        // index = binary(0_0011_1_001000_0000) = 0x1c80
        _newEffect(
            _world,
            false,
            EventType.ON_ATTACK,
            true,
            8, /* place_holder */
            0,
            0,
            _newTriggerWithSubAction(
                _newTriggerChecker(EnvExtractor.POSSIBILITY, 90, 0),
                PieceActionLib.generateAttackSubAction(ApplyTo.INDIRECT)
            )
        );

        // with event ON_START
        // index = binary(0_0001_1_001000_0000) = 0x0c80
        _newEffect(
            _world,
            false,
            EventType.ON_START,
            true,
            8, /* place_holder */
            0,
            0,
            _newTriggerWithoutSubAction(
                _newTriggerChecker(EnvExtractor.ALLY_AROUND_NUMBER, 1, 1), [ApplyTo.SELF], [0x804101]
            )
        );
        // index = binary(0_0001_1_001000_0001) = 0x0c81
        _newEffect(
            _world,
            false,
            EventType.ON_START,
            true,
            8, /* place_holder */
            1,
            0,
            _newTriggerWithoutSubAction(
                _newTriggerChecker(EnvExtractor.ALLY_AROUND_NUMBER, 1, 1), [ApplyTo.SELF], [0x804201]
            )
        );
    }

    function _newTriggerWithoutSubAction(uint24 _checker, ApplyTo[1] memory _applyTos, uint24[1] memory _effects)
        private
        pure
        returns (uint96 trigger)
    {
        trigger += _checker;
        trigger <<= 72;
        uint64 data;
        for (uint256 i; i < 1; ++i) {
            data <<= 8;
            data += uint8(_applyTos[i]);
            data <<= 24;
            data += _effects[i];
        }
        trigger += data;
    }

    function _newTriggerWithSubAction(uint24 _checker, uint64 _description) private pure returns (uint96 trigger) {
        trigger += _checker;
        trigger <<= 8;
        trigger += 0x80;
        trigger <<= 64;
        trigger += _description;
    }

    function _newTriggerChecker(EnvExtractor _extractor, uint8 _data, uint8 _selector)
        private
        pure
        returns (uint24 checker)
    {
        checker += uint8(_extractor);
        checker <<= 8;
        checker += _data;
        checker <<= 8;
        checker += _selector;
    }

    function _newEffect(
        IWorld _world,
        bool _withModifier,
        EventType _eventType,
        bool _direct,
        uint8 _placeHolder,
        uint8 _internalIndex,
        uint160 _modifier,
        uint96 _trigger
    ) private returns (uint16 index) {
        index = _withModifier ? 1 : 0;
        index <<= 4;
        index += uint8(_eventType) & 0x0f;
        index <<= 1;
        index += _direct ? 1 : 0;
        index <<= 6;
        index += _placeHolder & 0x3f;
        index <<= 4;
        index += _internalIndex & 0x0f;

        Effect.set(_world, index, EffectData(_modifier, _trigger));
    }

    function _newModifier(
        Attribute[1] memory _attributes,
        bool[1] memory _muls,
        bool[1] memory _negs,
        uint16[1] memory _changes
    ) private pure returns (uint160 res) {
        for (uint256 i; i < 1; ++i) {
            res <<= 4;
            res += uint8(_attributes[i]) & 0x0f;
            res <<= 1;
            res += _muls[i] ? 1 : 0;
            res <<= 1;
            res += _negs[i] ? 1 : 0;
            res <<= 14;
            res += _changes[i] & 0x3fff;
        }
    }

    function _newModifier(
        Attribute[2] memory _attributes,
        bool[2] memory _muls,
        bool[2] memory _negs,
        uint16[2] memory _changes
    ) private pure returns (uint160 res) {
        for (uint256 i; i < 2; ++i) {
            res <<= 4;
            res += uint8(_attributes[i]) & 0x0f;
            res <<= 1;
            res += _muls[i] ? 1 : 0;
            res <<= 1;
            res += _negs[i] ? 1 : 0;
            res <<= 14;
            res += _changes[i] & 0x3fff;
        }
    }
}
