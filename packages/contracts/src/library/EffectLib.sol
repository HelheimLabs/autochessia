// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct RTEffect {
  uint160 modification;
  uint96 trigger;
  uint16 index;
  EventType eventType;
  uint8 duration;
}

using EffectLib for RTEffect global;

import "forge-std/Test.sol";
import { Player, Board, Creature, Hero, Piece, Effect, EffectData } from "../codegen/Tables.sol";
import { EventType, Attribute } from "../codegen/Types.sol";
import { RTPiece } from "./RunTimePiece.sol";

library EffectLib {
  uint24 constant EFFECT_WITH_MODIFIER_MASK = 1 << 23;
  uint24 constant MODIFICATION_MASK = (1 << 20) - 1;
  uint16 constant CHANGE_OPPERATION_MASK = 1 << 15;
  uint16 constant CHANGE_SIGN_MASK = 1 << 14;

  function parseEffect(uint24 _effectInput) internal returns (RTEffect memory effect) {
    uint16 index = uint16(_effectInput >> 8);
    effect.index = index;
    effect.duration = uint8(_effectInput);
    effect.eventType = EventType(index >> 12);
    EffectData memory effectData = Effect.get(index);
    effect.modification = effectData.modification;
    effect.trigger = effectData.trigger;
  }

  function toUint24(RTEffect memory _effect) pure internal returns (uint24 effectOutput) {
    return (uint24(_effect.index) << 16) + _effect.duration;
  }

  function applyModification(RTPiece memory _piece, uint24 _effect) internal {
    uint16 index = uint16(_effect >> 8);
    if (index < EFFECT_WITH_MODIFIER_MASK) {
      return;
    }
    EffectData memory effectData = Effect.get(index);
    uint160 modification = effectData.modification;
    uint24 singleModification = uint24(modification) & MODIFICATION_MASK;
    while (singleModification > 0) {
        _applyModification(_piece, singleModification);
        modification >>= 20;
        singleModification = uint24(modification) & MODIFICATION_MASK;
    }
  }

  function _applyModification(RTPiece memory _piece, uint24 _modification) pure internal {
    (uint8 attributeIndex, uint16 changeInfo) = _parseModification(_modification);
    if (attributeIndex == uint8(Attribute.HEALTH)) {
        uint32 updated = uint32(_applyChangeInfo(_piece.health, changeInfo));
        _piece.health = updated > _piece.maxHealth ? _piece.maxHealth : updated;
    } else if (attributeIndex == uint8(Attribute.MAX_HEALTH)) {
        uint32 before = _piece.maxHealth;
        _piece.maxHealth = uint32(_applyChangeInfo(_piece.maxHealth, changeInfo));
        _piece.health = _piece.health * _piece.maxHealth / before;
    } else if (attributeIndex == uint8(Attribute.ATTACK)) {
        _piece.attack = uint32(_applyChangeInfo(_piece.attack, changeInfo));
    } else if (attributeIndex == uint8(Attribute.RANGE)) {
        _piece.range = uint8(_applyChangeInfo(_piece.range, changeInfo));
    } else if (attributeIndex == uint8(Attribute.DEFENSE)) {
        _piece.defense = uint32(_applyChangeInfo(_piece.defense, changeInfo));
    } else if (attributeIndex == uint8(Attribute.SPEED)) {
        _piece.speed = uint32(_applyChangeInfo(_piece.speed, changeInfo));
    } else if (attributeIndex == uint8(Attribute.MOVEMENT)) {
        _piece.movement = uint8(_applyChangeInfo(_piece.movement, changeInfo));
    }
  }

  /**
   * @notice _modification(24bits) = 0000 | attributeIndex(4bits) | operation(1bit) | sign(1bit) | changes(15bits)
   * @param _modification single attribute modification
   * @return attributeIndex affected attribute index
   * @return changeInfo operation(1bit) | sign(1bit) | changes(15bits)
   */
  function _parseModification(uint24 _modification) pure internal returns (uint8 attributeIndex, uint16 changeInfo) {
    attributeIndex = uint8(_modification >> 16);
    changeInfo = uint16(_modification);
  }

  function _applyChangeInfo(uint256 _original, uint16 _changeInfo) pure internal returns (uint256 updated) {
    bool isMultiply = (_changeInfo & CHANGE_OPPERATION_MASK) > 0;
    uint16 signedValue = _changeInfo & (CHANGE_OPPERATION_MASK - 1);
    bool negative = (signedValue & CHANGE_SIGN_MASK) > 0;
    uint16 value = signedValue & (CHANGE_SIGN_MASK - 1);
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
}