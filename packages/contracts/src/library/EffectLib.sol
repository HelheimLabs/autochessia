// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct EffectCache {
    uint256 next;
    EffectData[] effects;
    uint16[] indexes;
}

struct Checker {
    EnvExtractor extractor;
    uint8 data;
    uint8 selector;
}

struct Trigger {
    Checker checker;
    bool hasSubAction;
    uint256 subAction;
    ApplyTo[] applyTos;
    uint24[] effects;
}

using {EffectLib.getEffect} for EffectCache global;

import "forge-std/Test.sol";
import "./Constant.sol";
import "./RunTimePiece.sol";
import {Player, Board, Creature, Hero, Piece, Effect, EffectData} from "../codegen/index.sol";
import {EventType, Attribute, EnvExtractor, ApplyTo} from "src/codegen/common.sol";
import {Event} from "./EventLib.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";

library EffectLib {
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
        return uint8((getEffectIndex(_effect) & EFFECT_EVENT_TYPE_MASK) >> 11);
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

    function decreDuration(uint24 _effect) internal pure returns (uint24 effect) {
        return _effect - 1;
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

    function applyModification(
        RTPiece memory _piece,
        EffectCache memory _cache,
        uint24 _effect,
        uint256 _multiplier,
        bool _isNew
    ) internal view {
        if (!effectHasModification(_effect)) {
            return;
        }
        // console.log("apply modification to piece %s, effect %x, mul %d", uint256(_piece.id), _effect, _multiplier);
        uint16 index = getEffectIndex(_effect);
        EffectData memory effectData = _cache.getEffect(index);
        // console.log("effect modification %x, trigger %x", effectData.modification, effectData.trigger);
        uint160 modification = effectData.modification;
        uint24 singleModification = uint24(modification) & MODIFICATION_MASK;
        while (singleModification > 0) {
            _applyModification(_piece, singleModification, _multiplier, _isNew);
            modification >>= 20;
            singleModification = uint24(modification) & MODIFICATION_MASK;
        }
    }

    // temporary comment out unmodified attributes
    // TODO use bisection method to reduce number of if...else...
    function _applyModification(RTPiece memory _piece, uint24 _modification, uint256 _multiplier, bool _isNew)
        private
        view
    {
        (uint8 attributeIndex, uint16 changeInfo) = _parseModification(_modification);
        if (attributeIndex == uint8(Attribute.STATUS)) {
            _piece.status = uint16(_applyStatusChange(_piece.status, changeInfo));
        } else if (attributeIndex == uint8(Attribute.HEALTH)) {
            uint32 updated = uint32(_applyChangeInfo(_piece.health, changeInfo, _multiplier));
            _piece.health = updated > _piece.maxHealth ? _piece.maxHealth : updated;
        } else if (attributeIndex == uint8(Attribute.MAX_HEALTH)) {
            uint32 before = _piece.maxHealth;
            uint32 updated = uint32(_applyChangeInfo(_piece.maxHealth, changeInfo, _multiplier));
            if (_isNew) {
                _piece.health = (_piece.health * updated) / before;
            }
            _piece.maxHealth = updated;
        } else if (attributeIndex == uint8(Attribute.ATTACK)) {
            _piece.attack = uint32(_applyChangeInfo(_piece.attack, changeInfo, _multiplier));
            // } else if (attributeIndex == uint8(Attribute.RANGE)) {
            //     _piece.range = uint8(_applyChangeInfo(_piece.range, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.DEFENSE)) {
            _piece.defense = uint32(_applyChangeInfo(_piece.defense, changeInfo, _multiplier));
            // } else if (attributeIndex == uint8(Attribute.SPEED)) {
            //     _piece.speed = uint32(_applyChangeInfo(_piece.speed, changeInfo, _multiplier));
            // } else if (attributeIndex == uint8(Attribute.MOVEMENT)) {
            //     _piece.movement = uint8(_applyChangeInfo(_piece.movement, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.CRIT)) {
            _piece.crit = uint8(_applyChangeInfo(_piece.crit, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.DMG_REDUCTION)) {
            _piece.dmgReduction = uint8(_applyChangeInfo(_piece.dmgReduction, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.EVASION)) {
            _piece.evasion = uint8(_applyChangeInfo(_piece.evasion, changeInfo, _multiplier));
        } else if (attributeIndex == uint8(Attribute.IMMUNITY)) {
            _piece.immunity = uint8(_applyChangeInfo(_piece.immunity, changeInfo, _multiplier));
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

    function _applyStatusChange(uint256 _original, uint16 _changeInfo) private view returns (uint256 updated) {
        bool isOr = (_changeInfo & CHANGE_OPPERATION_MASK) > 0;
        if (isOr) {
            updated = _original | uint256(_changeInfo);
        } else {
            // is p AND (NOT q)
            updated = _original & (~uint256(_changeInfo));
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
    /**
     *
     * @param _cache effect cache
     * @param _effect effect of which trigger is parsed
     * @return trigger is the generated Trigger
     */

    function parseTrigger(EffectCache memory _cache, uint24 _effect) internal view returns (Trigger memory trigger) {
        uint16 index = getEffectIndex(_effect);
        uint96 input = _cache.getEffect(index).trigger;
        trigger.checker = _parseChecker(input >> 72);
        uint64 data = uint64(input & TRIGGER_DATA_MASK);
        if ((input & TRIGGER_SUB_ACTION_SELECTOR_MASK) > 0) {
            trigger.hasSubAction = true;
            trigger.subAction = data;
        } else {
            trigger.applyTos = new ApplyTo[](EFFECT_NUM_IN_TRIGGER);
            trigger.effects = new uint24[](EFFECT_NUM_IN_TRIGGER);
            for (uint256 i; i < EFFECT_NUM_IN_TRIGGER; ++i) {
                uint24 effect = uint24(data);
                data >>= 24;
                trigger.effects[i] = effect;
                trigger.applyTos[i] = ApplyTo(uint8(data));
                data >>= 8;
            }
        }
    }

    function applyTriggerEffects(
        Trigger memory _trigger,
        RTPiece[] memory _pieces,
        Event memory _eve,
        EffectCache memory _cache,
        uint256 _actorIndex
    ) internal view {
        for (uint256 i; i < EFFECT_NUM_IN_TRIGGER; ++i) {
            uint256 target = getTargetIndex(_pieces, _eve, _actorIndex, _trigger.applyTos[i]);
            _pieces[target].applyNewEffect(_cache, uint24(_trigger.effects[i]), 1);
        }
    }

    function removeTriggerEffects(
        Trigger memory _trigger,
        RTPiece[] memory _pieces,
        Event memory _eve,
        EffectCache memory _cache,
        uint256 _actorIndex
    ) internal view {
        for (uint256 i; i < EFFECT_NUM_IN_TRIGGER; ++i) {
            uint256 target = getTargetIndex(_pieces, _eve, _actorIndex, _trigger.applyTos[i]);
            _pieces[target].removeEffect(_cache, uint24(_trigger.effects[i]));
        }
    }

    function _parseChecker(uint256 _input) private pure returns (Checker memory checker) {
        checker = Checker(EnvExtractor(uint8(_input >> 16)), uint8(_input >> 8), uint8(_input));
    }

    function getTargetIndex(RTPiece[] memory _pieces, Event memory _eve, uint256 _actorIndex, ApplyTo _applyTo)
        internal
        pure
        returns (uint256)
    {
        if (_applyTo == ApplyTo.SELF) {
            return _actorIndex;
        } else if (_applyTo == ApplyTo.DIRECT) {
            return _eve.direct;
        } else if (_applyTo == ApplyTo.INDIRECT) {
            return _eve.indirect;
        }
    }
}
