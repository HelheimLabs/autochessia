// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Action {
<<<<<<< HEAD
  uint8 actionType; // 1: cast 2: attack 3: move
  uint8 executorIndex;
  uint8 targetIndex;
  uint16 value;
=======
    uint8 x;
    uint8 y;
    // todo enum
    uint8 actionType; // 1: attack
    uint8 targetIndex;
    uint16 value;
>>>>>>> develop
}

struct SubAction {
  uint8 actionType; // 1: cast 2: attack 3: move
  uint16 target; // if target > uint8.max, it's a coordinate. targetIndex if else
  uint16 value; // e.g. ability index
}

import "forge-std/Test.sol";
<<<<<<< HEAD
import { Player, Board, Creature, Hero, Piece } from "../codegen/Tables.sol";
import { RTPiece, RTPieceUtils } from "./RunTimePiece.sol";
import { EffectCache, EffectLib } from "./EffectLib.sol";
import { Event, EventLib } from "./EventLib.sol";
import { Coordinate as Coord } from "./Coordinate.sol";
import { Queue, Q } from "./Q.sol";

library PieceAction {
  function generateCastAction(uint256 _casterIndex, uint256 _targetIndex, uint256 _abilityIndex) internal pure returns (uint256 action) {
    action += 1 << 32;
    action += _casterIndex << 24;
    action += _abilityIndex;
  }

  function generateAttackAction(uint256 _attackerIndex, uint256 _targetIndex) internal pure returns (uint256 action) {
    action += 2 << 32;
    action += _attackerIndex << 24;
    action += _targetIndex << 16;
  }

  function generateMoveAction(uint256 _moverIndex, uint256 _x, uint256 _y) internal pure returns (uint256 action) {
    action += 3 << 32;
    action += _moverIndex << 24;
    action += _x << 8;
    action += _y;
  }

  function parseAction(uint256 _action) internal pure returns (Action memory action) {
    action = Action({
      actionType: uint8(_action >> 32),
      executorIndex: uint8(_action >> 24),
      targetIndex: uint8(_action >> 16),
      value: uint16(_action)
    });
  }

  function doAction(
    RTPiece[] memory _pieces,
    uint8[][] memory _map,
    EffectCache memory _cache,
    uint256 _action
  ) view internal {
    if (_action == 0) {
      return;
    }
    Action memory action = parseAction(_action);
    Queue memory q = Q.New(_pieces.length);
    uint8 actionType = action.actionType;
    if (actionType == 1) {
      _cast(_pieces, q, action.executorIndex, action.targetIndex);
    } else if (actionType == 2) {
      _attack(_pieces, q, action.executorIndex, action.targetIndex);
    } else if (actionType == 3) {
      _move(_pieces, _map, q, action.executorIndex, action.value);
    }
    while (!q.IsEmpty()) {
      uint256 eve = q.PopElement();
      _emitEvent(_pieces, EventLib.parseEvent(eve), _cache);
=======
import {Player, Board, Creature, Hero, Piece} from "../codegen/Tables.sol";
import {RTPiece} from "./RunTimePiece.sol";

library PieceAction {
    function doAction(address _player, uint256 _index, uint256 _action) internal {
        if (_action == 0) {
            return;
        }
        uint256 allyNum = Board.lengthPieces(_player);
        bytes32 id = _index < allyNum
            ? Board.getItemPieces(_player, _index)
            : Board.getItemEnemyPieces(_player, _index - allyNum);
        Action memory action = parseAction(_action);
        _move(id, action.x, action.y);
        if (action.actionType == 1) {
            _attack(id);
            bytes32 attacked = action.targetIndex < allyNum
                ? Board.getItemPieces(_player, action.targetIndex)
                : Board.getItemEnemyPieces(_player, action.targetIndex - allyNum);
            _takeDamage(attacked, action.value);
        }
    }

    function generateAction(uint256 _x, uint256 _y, uint256 _targetIndex, uint256 _value)
        internal
        pure
        returns (uint256 action)
    {
        action += _x << 40;
        action += _y << 32;
        action += 1 << 24;
        action += _targetIndex << 16;
        action += _value;
    }

    function parseAction(uint256 _action) internal pure returns (Action memory action) {
        action = Action({
            x: uint8(_action >> 40),
            y: uint8(_action >> 32),
            actionType: uint8(_action >> 24),
            targetIndex: uint8(_action >> 16),
            value: uint16(_action)
        });
>>>>>>> develop
    }

<<<<<<< HEAD
  function _cast(
    RTPiece[] memory _pieces,
    Queue memory _eventQ,
    uint256 _casterIndex,
    uint256 _targetIndex
  ) view private {
    _pieces[_casterIndex].cast();

    // todo find all affected piece, if it's an ability with damage, for each affected piece, call receiveDamage
    // if else, do what is defined by this ability's description

    _pieces[_targetIndex].receiveDamage(_casterIndex, 0, _eventQ);
  }

  function _attack(
    RTPiece[] memory _pieces,
    Queue memory _eventQ,
    uint256 _attackerIndex,
    uint256 _targetIndex
  ) view private {
    uint256 power = _pieces[_attackerIndex].atk(_targetIndex, _eventQ);

    _pieces[_targetIndex].receiveDamage(_attackerIndex, power, _eventQ);
  }

  function _move(
    RTPiece[] memory _pieces,
    uint8[][] memory _map,
    Queue memory _eventQ,
    uint256 _moverIndex,
    uint256 _destination
  ) view private {
    _pieces[_moverIndex].moveTo(_map, _destination, _eventQ);
  }

  function _emitEvent(
    RTPiece[] memory _pieces,
    Event memory _eve,
    EffectCache memory _cache
  ) view private {
    uint256 subAction = RTPieceUtils.triggerEffectsDirect(_pieces, _eve, _cache);
    _doSubAction(_pieces, _eve, _cache, subAction);

    subAction = RTPieceUtils.triggerEffectsIndirect(_pieces, _eve, _cache);
    _doSubAction(_pieces, _eve, _cache, subAction);
  }

  // function _triggerOnCastSpell(
  //   RTPiece[] memory _pieces,
  //   Event memory _eve,
  //   EffectCache memory _cache
  // ) view private {
  //   uint256 subAction = _pieces[_eve.emitFrom].onCast(_eve, _cache);
  //   _doSubAction(_pieces, _eve, _cache, subAction);
  // }

  // function _triggerOnAttack(
  //   RTPiece[] memory _pieces,
  //   Event memory _eve,
  //   EffectCache memory _cache
  // ) view private {
  //   uint256 subAction = _pieces[_eve.emitFrom].onAttack(_eve, _cache);
  //   _doSubAction(_pieces, _eve, _cache, subAction);
  // }

  // function _triggerOnReceiveDamage(
  //   RTPiece[] memory _pieces,
  //   Event memory _eve,
  //   EffectCache memory _cache
  // ) view private {
  //   uint256 subAction = _pieces[_eve.emitFrom].onDealDamage(_eve, _cache);
  //   _doSubAction(_pieces, _eve, _cache, subAction);

  //   subAction = _pieces[_eve.applyTo].onReceiveDamage(_eve, _cache);
  //   _doSubAction(_pieces, _eve, _cache, subAction);
  // }

  // function _triggerOnMove(
  //   RTPiece[] memory _pieces,
  //   Event memory _eve,
  //   EffectCache memory _cache
  // ) view private {
  //   uint256 subAction = _pieces[_eve.applyTo].onMove(_eve, _cache);
  //   _doSubAction(_pieces, _eve, _cache, subAction);
  // }

  function _doSubAction(
    RTPiece[] memory _pieces,
    Event memory _eve,
    EffectCache memory _cache,
    uint256 _subAction
  ) view private {
    if (_subAction == 0) {
      return;
    }
    // todo
  }
=======
    function _takeDamage(bytes32 _pieceId, uint256 _damage) private {
        uint256 health = Piece.getHealth(_pieceId);
        if (health > _damage) {
            Piece.setHealth(_pieceId, uint32(health - _damage));
        } else {
            Piece.setHealth(_pieceId, 0);
        }
    }

    function _spell() private {
        // cast a spell
        // todo start cooling spell
    }

    function _attack(bytes32 _pieceId) private {
        // attack an enemy
        // todo start cooling attack
    }

    function _move(bytes32 _pieceId, uint8 _x, uint8 _y) private {
        // move to a specific positon
        Piece.setX(_pieceId, _x);
        Piece.setY(_pieceId, _y);
    }

    function _defend() private {
        // todo, defend
    }
>>>>>>> develop
}
