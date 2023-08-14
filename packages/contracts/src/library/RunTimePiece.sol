// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { Piece } from "../codegen/Tables.sol";
import { EffectLib, EffectCache } from "./EffectLib.sol";
import { Event } from "./EventLib.sol";
import { EventType } from "../codegen/Types.sol";

/**
 * @notice run-time piece
 */
struct RTPiece {
  bytes32 id; //pieceId
  uint16 status;
  uint8 tier;
  uint8 owner;
  uint8 index;
  uint8 x; // position x
  uint8 y; // position y
  uint32 health;
  uint32 maxHealth;
  uint32 attack;
  uint8 range;
  uint32 defense;
  uint32 speed;
  uint8 movement;
  uint32 creatureId;
  uint24[8] effects;
}

using RTPieceUtils for RTPiece global;

import { Coordinate as Coord } from "./Coordinate.sol";

library RTPieceUtils {
  uint8 constant public MAX_EFFECT_NUM = 8;

  function sliceEffects(uint192 _effects) pure internal returns (uint24[8] memory effects) {
    uint24 effect = uint24(_effects);
    uint256 index;
    while (effect > 0) {
      effects[index] = effect;
      ++index;
      _effects >>= 24;
      effect = uint24(_effects);
    }
  }

  function packEffects(uint24[8] memory _effects) pure internal returns (uint192 effects) {
    for (uint256 i = MAX_EFFECT_NUM - 1; i >= 0; --i) {
      effects <<= 24;
      effects += _effects[i];
    }
  }

  function triggerEffectsDirect(
    RTPiece[] memory _pieces,
    Event memory _eve,
    EffectCache memory _cache
  ) view internal returns (uint256 subAction) {
    return _triggerEffects(_pieces, _eve, _cache, true);
  }

  function triggerEffectsIndirect(
    RTPiece[] memory _pieces,
    Event memory _eve,
    EffectCache memory _cache
  ) view internal returns (uint256 subAction) {
    return _triggerEffects(_pieces, _eve, _cache, false);
  }

  /*////////////////////////////////////////////////////////////
                        RTPiece Utils 
  ////////////////////////////////////////////////////////////*/

  function writeBack(RTPiece memory _piece) internal {
    Piece.set(
      _piece.id,
      _piece.x,
      _piece.y,
      _piece.tier,
      _piece.health,
      _piece.attack,
      _piece.range,
      _piece.defense,
      _piece.speed,
      _piece.movement,
      _piece.maxHealth,
      _piece.creatureId,
      packEffects(_piece.effects)
    );
  }

  function updateAttribute(RTPiece memory _piece, EffectCache memory _cache) internal view {
    uint24[MAX_EFFECT_NUM] memory effects = _piece.effects;
    for (uint256 i; i < MAX_EFFECT_NUM; ++i) {
      uint24 effect = effects[i];
      if (effect == 0) {
        break;
      }
      EffectLib.applyModification(_piece, _cache, effect, 1);
    }
  }

  function applyNewEffect(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect, uint256 _multiplier) view internal {
    uint256 index;
    while (_piece.effects[index] > 0) {
      ++index;
    }
    if (index < MAX_EFFECT_NUM) {
      EffectLib.applyModification(_piece, _cache, _effect, _multiplier);
      _piece.effects[index] = _effect;
    }
  }

  /**
   * @notice status (uint16) doc
   * 1st bit: can act
   * 2nd bit: can move
   * 3rd bit: can attack
   * 4th bit: can cast spells
   */

  uint16 constant CAN_ACT = 1 << 15;
  uint16 constant CAN_MOVE = 1 << 14;
  uint16 constant CAN_ATTACK = 1 << 13;
  uint16 constant CAN_CAST = 1 << 12;

  function canAct(RTPiece memory _piece) pure internal returns (bool) {
    return (_piece.status & CAN_ACT) > 0;
  }

  function canMove(RTPiece memory _piece) pure internal returns (bool) {
    return (_piece.status & CAN_MOVE) > 0;
  }

  function canAttack(RTPiece memory _piece) pure internal returns (bool) {
    return (_piece.status & CAN_ATTACK) > 0;
  }

  function canCast(RTPiece memory _piece) pure internal returns (bool) {
    return (_piece.status & CAN_CAST) > 0;
  }

  function cast(RTPiece memory _piece) pure internal returns (uint256 power) {
    // todo
  }

  function atk(RTPiece memory _piece) pure internal returns (uint256 power) {
    // todo attack cool down
    power = _piece.attack;
  }

  function receiveDamage(RTPiece memory _piece, uint256 _damage) pure internal returns (uint256 realDamage) {
    // todo various type of damage
    realDamage = _damage > _piece.defense ? _damage - _piece.defense : 0;
    _piece.health = realDamage > _piece.health ? 0 : _piece.health - uint32(realDamage);
  }

  function moveTo(RTPiece memory _piece, uint8[][] memory _map, uint256 _dest) pure internal returns (uint256 distance) {
    _setToWalkable(_map, _piece.x, _piece.y);
    (uint256 X, uint256 Y) = Coord.decompose(_dest);
    distance = Coord.distance( _piece.x, _piece.y, X, Y);
    _piece.x = uint8(X);
    _piece.y = uint8(Y);
    _setToObstacle(_map, _piece.x, _piece.x);
  }

  // function onCast(RTPiece memory _piece, Event memory _eve, EffectCache memory _cache) view internal returns (uint256 subAction) {
  //   return _triggerEffects(_piece, _eve.data, EventType.ON_CAST_SPELL, _cache);
  // }

  // function onAttack(RTPiece memory _piece, Event memory _eve, EffectCache memory _cache) view internal returns (uint256 subAction) {
  //   return _triggerEffects(_piece, _eve.data, EventType.ON_ATTACK, _cache);
  // }

  // function onReceiveDamage(RTPiece memory _piece, Event memory _eve, EffectCache memory _cache) view internal returns (uint256 subAction) {
  //   return _triggerEffects(_piece, _eve.data, EventType.ON_RECEIVE_DAMAGE, _cache);
  // }

  // function onMove(RTPiece memory _piece, Event memory _eve, EffectCache memory _cache) view internal returns (uint256 subAction) {
  //   return _triggerEffects(_piece, _eve.data, EventType.ON_MOVE, _cache);
  // }

  // function onDealDamage(RTPiece memory _piece, Event memory _eve, EffectCache memory _cache) view internal returns (uint256 subAction) {
  //   return _triggerEffects(_piece, _eve.data, EventType.ON_DEAL_DAMAGE, _cache);
  // }

  function _triggerEffects(
    RTPiece[] memory _pieces,
    Event memory _eve,
    EffectCache memory _cache,
    bool _direct
  ) view private returns (uint256 subAction) {
    uint24[MAX_EFFECT_NUM] memory effects = _direct? _pieces[_eve.direct].effects : _pieces[_eve.indirect].effects;
    for (uint256 i; i < MAX_EFFECT_NUM; ++i) {
      uint24 effect = effects[i];
      if (effect == 0) {
        break;
      }
      // we limit that only one(the last) sub-action is executed during each trigger process
      if (EffectLib.effectMatchEvenType(effect, _eve.eventType, _direct)) {
        subAction = EffectLib.triggerEffect(_pieces, _eve, _cache, effect);
      }
    }
  }


  function _setToWalkable(
    uint8[][] memory _map,
    uint256 _x,
    uint256 _y
  ) private pure {
    _map[_x][_y] = 0;
  }

  function _setToObstacle(
    uint8[][] memory _map,
    uint256 _x,
    uint256 _y
  ) private pure {
    _map[_x][_y] = 1;
  }
}
