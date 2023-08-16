// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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
    uint16 creatureId;
    uint24[8] effects;
}

using RTPieceUtils for RTPiece global;

import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {Piece} from "../codegen/Tables.sol";
import {EffectLib, EffectCache} from "./EffectLib.sol";
import {Event, EventLib} from "./EventLib.sol";
import {EventType} from "../codegen/Types.sol";
import {Queue} from "./Q.sol";

library RTPieceUtils {
    uint8 public constant MAX_EFFECT_NUM = 8;

    function sliceEffects(uint192 _effects) internal pure returns (uint24[8] memory effects) {
        uint24 effect = uint24(_effects);
        uint256 index;
        while (effect > 0) {
            effects[index] = effect;
            ++index;
            _effects >>= 24;
            effect = uint24(_effects);
        }
    }

    function packEffects(uint24[8] memory _effects) internal pure returns (uint192 effects) {
        for (uint256 i = MAX_EFFECT_NUM; i > 0; --i) {
            // we don't check if it's an enmpty effect in order to save gas for `if`
            effects += _effects[i - 1];
            effects <<= 24;
        }
    }

    function triggerEffectsDirect(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache)
        internal
        view
        returns (uint256 subAction)
    {
        return _triggerEffects(_pieces, _eve, _cache, true);
    }

    function triggerEffectsIndirect(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache)
        internal
        view
        returns (uint256 subAction)
    {
        return _triggerEffects(_pieces, _eve, _cache, false);
    }

    /*////////////////////////////////////////////////////////////
                        RTPiece Utils 
    ////////////////////////////////////////////////////////////*/

    function endTurn(RTPiece memory _piece) internal pure {
        uint24[MAX_EFFECT_NUM] memory effects = _piece.effects;
        uint24[MAX_EFFECT_NUM] memory updated;
        uint256 index;
        for (uint256 i; i < MAX_EFFECT_NUM; ++i) {
            uint24 effect = effects[i];
            if (effect == 0) {
                break;
            }
            effect = EffectLib.endTurn(effect);
            if (effect > 0) {
                updated[index++] = effect;
            }
        }
        _piece.effects = updated;
    }

    function writeBack(RTPiece memory _piece) internal {
        _piece.endTurn();
        Piece.set(_piece.id, _piece.x, _piece.y, _piece.health, _piece.creatureId, packEffects(_piece.effects));
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

    function applyNewEffect(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect, uint256 _multiplier)
        internal
        view
    {
        EffectLib.applyModification(_piece, _cache, _effect, _multiplier);
        if (EffectLib.effectHasTrigger(_effect) || EffectLib.getEffectDuration(_effect) > 1) {
            uint256 index;
            while (_piece.effects[index] > 0) {
                ++index;
            }
            if (index < MAX_EFFECT_NUM) {
                _piece.effects[index] = _effect;
            }
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

    function canAct(RTPiece memory _piece) internal pure returns (bool) {
        return (_piece.status & CAN_ACT) > 0;
    }

    function canMove(RTPiece memory _piece) internal pure returns (bool) {
        return (_piece.status & CAN_MOVE) > 0;
    }

    function canAttack(RTPiece memory _piece) internal pure returns (bool) {
        return (_piece.status & CAN_ATTACK) > 0;
    }

    function canCast(RTPiece memory _piece) internal pure returns (bool) {
        return (_piece.status & CAN_CAST) > 0;
    }

    function cast(RTPiece memory _piece) internal pure returns (uint256 power) {
        // todo
    }

    function atk(RTPiece memory _piece, uint256 _targetIndex, Queue memory _eventQ)
        internal
        pure
        returns (uint256 power)
    {
        power = _piece.attack;
        if (power == 0) {
            return power;
        }

        // todo attack cool down

        _eventQ.AddElement(EventLib.genOnAttack(_piece.index, _targetIndex, power));
    }

    function receiveDamage(RTPiece memory _piece, uint256 _source, uint256 _damage, Queue memory _eventQ)
        internal
        pure
    {
        // todo various type of damage
        uint256 realDamage = _damage > _piece.defense ? _damage - _piece.defense : 0;
        if (realDamage == 0) {
            return;
        }
        _piece.health = realDamage > _piece.health ? 0 : _piece.health - uint32(realDamage);
        _eventQ.AddElement(EventLib.genOnDamage(_piece.index, _source, realDamage));
        if (_piece.health == 0) {
            _eventQ.AddElement(EventLib.genOnDeath(_piece.index, _source));
        }
    }

    function moveTo(RTPiece memory _piece, uint8[][] memory _map, uint256 _dest, Queue memory _eventQ) internal pure {
        _setToWalkable(_map, _piece.x, _piece.y);
        (uint256 X, uint256 Y) = Coord.decompose(_dest);
        // uint256 distance = Coord.distance( _piece.x, _piece.y, X, Y);
        _piece.x = uint8(X);
        _piece.y = uint8(Y);
        _setToObstacle(_map, _piece.x, _piece.x);
        _eventQ.AddElement(EventLib.genOnMove(_piece.index, X, Y));
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

    function _triggerEffects(RTPiece[] memory _pieces, Event memory _eve, EffectCache memory _cache, bool _direct)
        private
        view
        returns (uint256 subAction)
    {
        uint24[MAX_EFFECT_NUM] memory effects = _direct ? _pieces[_eve.direct].effects : _pieces[_eve.indirect].effects;
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

    function _setToWalkable(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 0;
    }

    function _setToObstacle(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 1;
    }
}
