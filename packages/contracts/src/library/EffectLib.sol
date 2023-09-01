// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct EffectCache {
    uint256 next;
    EffectData[] effects;
    uint16[] indexes;
}

using {EffectLib.getEffect} for EffectCache global;

import "forge-std/Test.sol";
import {Player, Board, Creature, Hero, Piece, Effect, EffectData} from "../codegen/Tables.sol";
import {EventType, Attribute} from "../codegen/Types.sol";
import {RTPiece} from "./RunTimePiece.sol";
import {Event} from "./EventLib.sol";

library EffectLib {
    uint16 constant EFFECT_WITH_MODIFIER_MASK = 1 << 15;
    uint16 constant EFFECT_EVENT_TYPE_MASK = ((1 << 4) - 1) << 11;
    uint16 constant EFFECT_IS_DIRECT_MASK = 1 << 10;
    uint24 constant MODIFICATION_MASK = (1 << 20) - 1;
    uint16 constant CHANGE_OPPERATION_MASK = 1 << 15;
    uint16 constant CHANGE_SIGN_MASK = 1 << 14;

    /*//////////////////////////////////////////////////////
                        effect
    //////////////////////////////////////////////////////*/

    function getEffectIndex(uint24 _effect) internal pure returns (uint16 index) {
        return uint16(_effect >> 8);
    }

    function getEffectDuration(uint24 _effect) internal pure returns (uint8 duration) {
        return uint8(_effect);
    }

    function getEffectEventType(uint24 _effect) internal pure returns (uint8 eventType) {
        return uint8((getEffectIndex(_effect) & EFFECT_EVENT_TYPE_MASK) >> 12);
    }

    function effectHasModification(uint24 _effect) internal pure returns (bool has) {
        return getEffectIndex(_effect) > EFFECT_WITH_MODIFIER_MASK;
    }

    function effectHasTrigger(uint24 _effect) internal pure returns (bool has) {
        return getEffectEventType(_effect) > 0;
    }

    function effectTriggerOnDirect(uint24 _effect) internal pure returns (bool isDirect) {
        return (getEffectIndex(_effect) & EFFECT_IS_DIRECT_MASK) > 0;
    }

    function endTurn(uint24 _effect) internal pure returns (uint24 effect) {
        if (getEffectDuration(_effect) > 1) {
            effect = _effect - 1;
        }
    }

    /*//////////////////////////////////////////////////////
                        effect cache
    //////////////////////////////////////////////////////*/

    function NewEffectCache(uint256 _length) internal pure returns (EffectCache memory cache) {
        return EffectCache({next: 0, effects: new EffectData[](_length), indexes: new uint16[](_length)});
    }

    function getEffect(EffectCache memory _cache, uint16 _effectIndex) internal view returns (EffectData memory data) {
        uint256 length = _cache.effects.length;
        uint256 i;
        for (; i < length; ++i) {
            if (_cache.indexes[i] == _effectIndex) {
                data = _cache.effects[i];
                break;
            }
        }
        if (i == length) {
            data = Effect.get(_effectIndex);
        }
        _cache.effects[_cache.next] = data;
        _cache.indexes[_cache.next] = _effectIndex;
        _cache.next = (_cache.next + 1) % length;
    }

    /*//////////////////////////////////////////////////////
                        modification
    //////////////////////////////////////////////////////*/

    function applyModification(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect, uint256 _multiplier)
        internal
        view
    {
        if (!effectHasModification(_effect)) {
            return;
        }
        uint16 index = getEffectIndex(_effect);
        EffectData memory effectData = _cache.getEffect(index);
        uint160 modification = effectData.modification;
        uint24 singleModification = uint24(modification) & MODIFICATION_MASK;
        while (singleModification > 0) {
            _applyModification(_piece, singleModification, _multiplier);
            modification >>= 20;
            singleModification = uint24(modification) & MODIFICATION_MASK;
        }
    }

    function _applyModification(RTPiece memory _piece, uint24 _modification, uint256 _multiplier) private pure {
        (uint8 attributeIndex, uint16 changeInfo) = _parseModification(_modification);
        if (attributeIndex == uint8(Attribute.STATUS)) {
            _piece.status = uint16(_applyStatusChange(_piece.status, changeInfo));
        } else if (attributeIndex == uint8(Attribute.HEALTH)) {
            uint32 updated = uint32(_applyChangeInfo(_piece.health, changeInfo, _multiplier));
            _piece.health = updated > _piece.maxHealth ? _piece.maxHealth : updated;
        } else if (attributeIndex == uint8(Attribute.MAX_HEALTH)) {
            uint32 before = _piece.maxHealth;
            _piece.maxHealth = uint32(_applyChangeInfo(_piece.maxHealth, changeInfo, _multiplier));
            _piece.health = _piece.health * _piece.maxHealth / before;
        } else if (attributeIndex == uint8(Attribute.ATTACK)) {
            _piece.attack = uint32(_applyChangeInfo(_piece.attack, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.RANGE)) {
            _piece.range = uint8(_applyChangeInfo(_piece.range, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.DEFENSE)) {
            _piece.defense = uint32(_applyChangeInfo(_piece.defense, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.SPEED)) {
            _piece.speed = uint32(_applyChangeInfo(_piece.speed, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.MOVEMENT)) {
            _piece.movement = uint8(_applyChangeInfo(_piece.movement, changeInfo, _multiplier));
        }
    }

    /**
     * @notice _modification(24bits) = 0000 | attributeIndex(4bits) | operation(1bit) | sign(1bit) | changes(14bits)
     * @param _modification single attribute modification
     * @return attributeIndex affected attribute index
     * @return changeInfo operation(1bit) | sign(1bit) | changes(14bits)
     */
    function _parseModification(uint24 _modification) private pure returns (uint8 attributeIndex, uint16 changeInfo) {
        attributeIndex = uint8(_modification >> 16);
        changeInfo = uint16(_modification);
    }

    function _applyChangeInfo(uint256 _original, uint16 _changeInfo, uint256 _multiplier)
        private
        pure
        returns (uint256 updated)
    {
        bool isMultiply = (_changeInfo & CHANGE_OPPERATION_MASK) > 0;
        uint16 signedValue = _changeInfo & (CHANGE_OPPERATION_MASK - 1);
        bool negative = (signedValue & CHANGE_SIGN_MASK) > 0;
        uint256 value = (signedValue & (CHANGE_SIGN_MASK - 1)) * _multiplier;
        if (isMultiply) {
            updated = (_original * 100) / value;
        } else {
            if (negative) {
                updated = _original > value ? _original - value : 0;
            } else {
                updated = _original + value;
            }
        }
    }

    function _applyStatusChange(uint256 _original, uint16 _changeInfo) private pure returns (uint256 updated) {
        bool isOr = (_changeInfo & CHANGE_OPPERATION_MASK) > 0;
        if (isOr) {
            updated = _original | uint256(_changeInfo);
        } else {
            // is XOR
            updated = _original ^ uint256(_changeInfo);
        }
    }

    /*//////////////////////////////////////////////////////
                        utils
    //////////////////////////////////////////////////////*/

    function effectMatchEvenType(uint24 _effect, EventType _eventType, bool _isDirect)
        internal
        pure
        returns (bool matched)
    {
        if (getEffectEventType(_effect) == uint8(_eventType) && effectTriggerOnDirect(_effect) == _isDirect) {
            matched = true;
        }
    }

    /*//////////////////////////////////////////////////////
                        trigger
    //////////////////////////////////////////////////////*/

    uint8 constant EFFECT_NUM_IN_TRIGGER = 3;
    uint96 constant TRIGGER_SUB_ACTION_DESCRIPTION_MASK = (1 << 95) - 1;
    uint88 constant TRIGGER_EFFECTS_MASK = (1 << 84) - 1;
    uint32 constant TRIGGER_EFFECT_APPLY_TO_MASK = 7 << 24;
    uint32 constant TRIGGER_EFFECT_X_MASK = 1 << 27;

    function triggerEffect(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache, uint24 _effect)
        internal
        view
        returns (uint256)
    {
        (
            bool[EFFECT_NUM_IN_TRIGGER] memory xs,
            uint256[EFFECT_NUM_IN_TRIGGER] memory applyTos,
            uint256[EFFECT_NUM_IN_TRIGGER] memory effects,
            uint256 subAction
        ) = EffectLib.parseTrigger(_cache, _effect);
        if (subAction > 0) {
            return subAction;
        } else {
            for (uint256 i; i < EFFECT_NUM_IN_TRIGGER; ++i) {
                uint24 effect = uint24(effects[i]);
                if (effect == 0) {
                    break;
                }
                uint256 applyTo = applyTos[i] == 0 ? _eve.direct : _eve.indirect;
                RTPiece memory piece = _pieces[applyTo];
                piece.applyNewEffect(_cache, effect, xs[i] ? _eve.data : 1);
                _pieces[applyTo] = piece;
            }
        }
    }

    /**
     *
     * @param _cache effect cache
     * @param _effect effect of which trigger is parsed
     * @return xs whether the effect within trigger is affected by event data
     * @return applyTos represent the piece to which the effect within trigger will be applied
     * @return effects the effect within trigger
     * @return subAction the sub-action within trigger instead of effects
     */

    function parseTrigger(EffectCache memory _cache, uint24 _effect)
        internal
        view
        returns (
            bool[EFFECT_NUM_IN_TRIGGER] memory xs,
            uint256[EFFECT_NUM_IN_TRIGGER] memory applyTos,
            uint256[EFFECT_NUM_IN_TRIGGER] memory effects,
            uint256 subAction
        )
    {
        uint16 index = getEffectIndex(_effect);
        uint96 trigger = _cache.getEffect(index).trigger;
        if (trigger > (1 << 95)) {
            subAction = trigger & TRIGGER_SUB_ACTION_DESCRIPTION_MASK;
        } else {
            trigger &= TRIGGER_EFFECTS_MASK;
            for (uint256 i; i < EFFECT_NUM_IN_TRIGGER; ++i) {
                uint24 effect = uint24(trigger);
                if (effect == 0) {
                    break;
                }
                effects[i] = effect;
                applyTos[i] = (trigger & TRIGGER_EFFECT_APPLY_TO_MASK) >> 24;
                xs[i] = (trigger & TRIGGER_EFFECT_X_MASK) > 0;
                trigger >>= 28;
            }
        }
    }
}
