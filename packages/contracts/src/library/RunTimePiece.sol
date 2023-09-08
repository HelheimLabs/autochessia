// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @notice run-time piece
 */
struct RTPiece {
    bytes32 id; //pieceId
    uint16 status;
    uint8 owner;
    uint8 index;
    uint8 x; // position x
    uint8 y; // position y
    uint32 health;
    uint32 maxHealth;
    uint32 attack;
    uint8 crit;
    uint8 range;
    uint8 evasion;
    uint8 immunity;
    uint32 defense;
    uint8 dmgReduction;
    uint32 speed;
    uint8 movement;
    uint24 creatureId;
    uint24[PIECE_MAX_EFFECT_NUM] effects;
}

using RTPieceUtils for RTPiece global;

import "forge-std/Test.sol";
import "./Constant.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {GameConfig, HeroData, Piece, PieceData, Creature, CreatureData} from "../codegen/Tables.sol";
import {EffectLib, EffectCache} from "./EffectLib.sol";
import {Event, EventLib} from "./EventLib.sol";
import {DamageLib} from "./DamageLib.sol";
import {EventType, DamageType} from "../codegen/Types.sol";
import {Queue} from "./Q.sol";

library RTPieceUtils {
    function NewRTPiece(
        bytes32 _id,
        uint256 _owner,
        uint256 _index,
        PieceData memory _piece,
        CreatureData memory _creature
    ) internal pure returns (RTPiece memory piece) {
        piece = _newRTPiece(
            _id, _owner, _index, _piece.x, _piece.y, _piece.health, _piece.creatureId, _piece.effects, _creature
        );
    }

    function NewRTPiece(
        bytes32 _id,
        uint256 _owner,
        uint256 _index,
        HeroData memory _hero,
        CreatureData memory _creature
    ) internal view returns (RTPiece memory piece) {
        piece = _newRTPiece(
            _id,
            _owner,
            _index,
            _owner == 0 ? _hero.x : GameConfig.getLength(0) * 2 - 1 - _hero.x,
            _hero.y,
            _creature.health,
            _hero.creatureId,
            0,
            _creature
        );
    }

    function _newRTPiece(
        bytes32 _id,
        uint256 _owner,
        uint256 _index,
        uint256 _x,
        uint256 _y,
        uint256 _health,
        uint256 _creatureId,
        uint256 _effects,
        CreatureData memory _creature
    ) private pure returns (RTPiece memory piece) {
        piece = RTPiece({
            id: _id,
            status: 0x3800,
            owner: uint8(_owner),
            index: uint8(_index),
            x: uint8(_x),
            y: uint8(_y),
            health: uint32(_health),
            maxHealth: _creature.health,
            attack: _creature.attack,
            crit: 0,
            range: uint8(_creature.range),
            evasion: 0,
            immunity: 0,
            defense: _creature.defense,
            dmgReduction: 0,
            speed: _creature.speed,
            movement: uint8(_creature.movement),
            creatureId: uint24(_creatureId),
            effects: sliceEffects(uint192(_effects))
        });
    }

    function sliceEffects(uint192 _effects) internal pure returns (uint24[8] memory effects) {
        uint24 effect = uint24(_effects);
        uint256 index;
        while (effect > 0) {
            effects[index++] = effect;
            _effects >>= 24;
            effect = uint24(_effects);
        }
    }

    function packEffects(uint24[8] memory _effects) internal pure returns (uint192 effects) {
        for (uint256 i = PIECE_MAX_EFFECT_NUM; i > 0; --i) {
            // we don't check if it's an enmpty effect in order to save gas for `if`
            effects <<= 24;
            effects += _effects[i - 1];
        }
    }

    /*////////////////////////////////////////////////////////////
                        RTPiece Utils 
    ////////////////////////////////////////////////////////////*/

    function getTier(RTPiece memory _piece) internal pure returns (uint256) {
        return uint8(_piece.creatureId >> 8);
    }

    function timeFly(RTPiece memory _piece) internal pure {
        uint24[PIECE_MAX_EFFECT_NUM] memory effects = _piece.effects;
        uint24[PIECE_MAX_EFFECT_NUM] memory updated;
        uint256 index;
        for (uint256 i; i < PIECE_MAX_EFFECT_NUM; ++i) {
            uint24 effect = effects[i];
            if (effect == 0) {
                break;
            }
            effect = EffectLib.decreDuration(effect);
            if (EffectLib.getEffectDuration(effect) > 0) {
                updated[index++] = effect;
            }
        }
        _piece.effects = updated;
    }

    function writeBack(RTPiece memory _piece) internal {
        // todo change health back to uint32
        Piece.set(_piece.id, _piece.x, _piece.y, uint24(_piece.health), _piece.creatureId, packEffects(_piece.effects));
    }

    function updateAttribute(RTPiece memory _piece, EffectCache memory _cache) internal view {
        uint24[PIECE_MAX_EFFECT_NUM] memory effects = _piece.effects;
        for (uint256 i; i < PIECE_MAX_EFFECT_NUM; ++i) {
            uint24 effect = effects[i];
            if (effect == 0) {
                break;
            }
            EffectLib.applyModification(_piece, _cache, effect, 1, false);
        }
    }

    function applyNewEffects(RTPiece memory _piece, EffectCache memory _cache, uint256 _effects, uint256 _multiplier)
        internal
        view
    {
        uint256 index;
        while (_piece.effects[index] > 0) {
            ++index;
        }
        while (index < PIECE_MAX_EFFECT_NUM) {
            uint24 effect = uint24(_effects);
            if (effect == 0) {
                return;
            }
            EffectLib.applyModification(_piece, _cache, effect, _multiplier, true);
            _piece.effects[index++] = effect;
            _effects >>= 24;
        }
    }

    function applyNewEffect(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect, uint256 _multiplier)
        internal
        view
    {
        if (_effect == 0) {
            return;
        }
        uint256 index;
        while (_piece.effects[index] > 0) {
            if (EffectLib.getEffectIndex(_piece.effects[index]) == EffectLib.getEffectIndex(_effect)) {
                if (EffectLib.getEffectDuration(_piece.effects[index]) < EffectLib.getEffectDuration(_effect)) {
                    break;
                }
                return;
            }
            ++index;
        }
        if (index < PIECE_MAX_EFFECT_NUM) {
            if (_piece.effects[index] == 0) {
                EffectLib.applyModification(_piece, _cache, _effect, _multiplier, true);
            }
            _piece.effects[index] = _effect;
        }
    }

    function removeEffect(RTPiece memory _piece, EffectCache memory _cache, uint24 _effect) internal view {
        if (_effect == 0) {
            return;
        }
        uint256 effectIndex = EffectLib.getEffectIndex(_effect);
        for (uint256 i; i < PIECE_MAX_EFFECT_NUM; ++i) {
            if (EffectLib.getEffectIndex(_piece.effects[i]) == effectIndex) {
                _piece.effects[i] = 0;
                for (uint256 j = i + 1; j < PIECE_MAX_EFFECT_NUM; ++j) {
                    _piece.effects[j - 1] = _piece.effects[j];
                }
                // TODO regenerate piece attributes
                // _piece.regenerateAttribute(_cache);
                return;
            }
        }
    }

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
        view
        returns (uint256 dmg)
    {
        uint256 power = _piece.attack;
        if (power == 0) {
            return 0;
        }

        dmg = DamageLib.genDamage(DamageType.PHYSICAL, _piece.crit, 200, /* default crit value*/ power);

        // todo attack cool down

        _eventQ.AddElement(EventLib.genOnAttack(_piece.index, _targetIndex, power));
    }

    function receiveDamage(RTPiece memory _piece, uint256 _source, uint256 _damage, Queue memory _eventQ, uint256 _rand)
        internal
        view
    {
        uint256 damageValue = DamageLib.getDmgValue(_damage, uint8(_rand));
        _rand >>= 8;
        // check evasion and immunity
        if (_evade(_piece.evasion, uint8(_rand))) {
            console.log("    piece evaded, evasion %d", _piece.evasion);
            return;
        } else if (_immune(_piece.immunity, uint8(_rand >> 8))) {
            console.log("    piece immune, immunity %d", _piece.immunity);
            return;
        }
        // damage reduction
        damageValue = (damageValue * (100 - _piece.dmgReduction)) / 100;

        // defense
        damageValue = damageValue > _piece.defense ? damageValue - _piece.defense : 0;

        if (damageValue == 0) {
            return;
        }
        _piece.health = damageValue > _piece.health ? 0 : _piece.health - uint32(damageValue);
        _eventQ.AddElement(EventLib.genOnDamage(_piece.index, _source, damageValue));
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

    function _evade(uint8 _evasion, uint8 _rand) private pure returns (bool res) {
        res = (_rand % 100) < _evasion;
    }

    function _immune(uint8 _immunity, uint8 _rand) private pure returns (bool res) {
        res = (_rand % 100) < _immunity;
    }

    function _setToWalkable(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 0;
    }

    function _setToObstacle(uint8[][] memory _map, uint256 _x, uint256 _y) private pure {
        _map[_x][_y] = 1;
    }
}
