// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {console} from "forge-std/console.sol";
import {IWorld} from "../src/codegen/world/IWorld.sol";
import {Effect, EffectData, RaceSynergyEffect, ClassSynergyEffect} from "../src/codegen/Tables.sol";
import {EventType, Attribute} from "../src/codegen/Types.sol";

library EffectInitializer {
    function init(IWorld _world) internal {
        _initEffects(_world);
        _initSynergy(_world);
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
    }

    function _initSynergy(IWorld _world) private {
        // race synergy
        RaceSynergyEffect.set(_world, 0x000200, 0xff8080);
        RaceSynergyEffect.set(_world, 0x000400, 0xff8081);

        // class synergy
    }

    function _newTriggerWithoutSubAction(bool[] memory _xs, uint8[] memory _applyTos, uint24[] memory _effects)
        private
        pure
        returns (uint96 trigger)
    {
        uint256 num = _xs.length;
        require(num < 4, "EffectInitializer: at most 3 effects within a trigger");
        for (uint256 i; i < num; ++i) {
            trigger <<= 1;
            trigger += _xs[i] ? 1 : 0;
            trigger <<= 3;
            trigger += _applyTos[i] & 0x07;
            trigger << 24;
            trigger += _effects[i];
        }
    }

    function _newTriggerWithSubAction(uint96 _description) private pure returns (uint96 trigger) {
        trigger = (1 << 95) | _description;
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
