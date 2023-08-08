// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct EffectCache {
  uint256 next;
  EffectData[] effects;
  uint16[] indexes; 
}

using { EffectLib.getEffect } for EffectCache global;

import "forge-std/Test.sol";
import { Player, Board, Creature, Hero, Piece, Effect, EffectData } from "../codegen/Tables.sol";
import { EventType, Attribute } from "../codegen/Types.sol";
import { RTPiece } from "./RunTimePiece.sol";

library EffectLib {
  uint24 constant EFFECT_WITH_MODIFIER_MASK = 1 << 23;
  uint24 constant EFFECT_EVENT_TYPE_MASK = ((1 << 4) - 1) << 12;
  uint24 constant MODIFICATION_MASK = (1 << 20) - 1;
  uint16 constant CHANGE_OPPERATION_MASK = 1 << 15;
  uint16 constant CHANGE_SIGN_MASK = 1 << 14;

  function NewEffectCache(uint256 _length) pure internal returns (EffectCache memory cache) {
    return EffectCache({
      next: 0,
      effects: new EffectData[](_length),
      indexes: new uint16[](_length)
    });
  }

  function getEffect(EffectCache memory _cache, uint16 _effectIndex) view internal returns (EffectData memory data) {
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

  function applyModification(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect) view internal {
    uint16 index = uint16(_effect >> 8);
    if (index < EFFECT_WITH_MODIFIER_MASK) {
      return;
    }
    EffectData memory effectData = _cache.getEffect(index);
    uint160 modification = effectData.modification;
    uint24 singleModification = uint24(modification) & MODIFICATION_MASK;
    while (singleModification > 0) {
      _applyModification(_piece, singleModification);
      modification >>= 20;
      singleModification = uint24(modification) & MODIFICATION_MASK;
    }
  }

  function _applyModification(RTPiece memory _piece, uint24 _modification) pure private {
    (uint8 attributeIndex, uint16 changeInfo) = _parseModification(_modification);
    if (attributeIndex == uint8(Attribute.STATUS)) {
      _piece.status = uint16(_applyStatusChange(_piece.status, changeInfo));
    } else if (attributeIndex == uint8(Attribute.HEALTH)) {
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
  function _parseModification(uint24 _modification) pure private returns (uint8 attributeIndex, uint16 changeInfo) {
    attributeIndex = uint8(_modification >> 16);
    changeInfo = uint16(_modification);
  }

  function _applyChangeInfo(uint256 _original, uint16 _changeInfo) pure private returns (uint256 updated) {
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

  function _applyStatusChange(uint256 _original, uint16 _changeInfo) pure private returns (uint256 updated) {
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

  function _effectMatchEvenType(uint16 _effectIndex, EventType _eventType) pure private returns (bool matched) {
    if (((_effectIndex & EFFECT_EVENT_TYPE_MASK) >> 12) == uint8(_eventType)) {
      matched = true;
    }
  }

  /*//////////////////////////////////////////////////////
                        trigger
  //////////////////////////////////////////////////////*/

  function triggerPieceEffects(RTPiece memory _piece, EffectCache memory _cache, uint256 _eventData, EventType _eventType) view internal returns (uint256 eventData, uint256 subAction) {
    uint24[8] memory effects = _piece.effects;
    uint256 num = effects.length;
    for (uint256 i; i < num; ++i) {
      uint24 effect = effects[i];
      uint16 index = uint16(effect >> 8);
      if (_effectMatchEvenType(index, _eventType)) {
        uint96 trigger = _cache.getEffect(index).trigger;
        // todo detail trigger and pull it
      }
    }
  }
}