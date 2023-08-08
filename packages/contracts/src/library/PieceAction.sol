// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Action {
  uint8 actionType; // 1: cast 2: attack 3: move
  uint8 executorIndex;
  uint8 targetIndex;
  uint16 value;
}

import "forge-std/Test.sol";
import { Player, Board, Creature, Hero, Piece } from "../codegen/Tables.sol";
import { RTPiece } from "./RunTimePiece.sol";
import { EffectCache, EffectLib } from "./EffectLib.sol";
import { Coordinate as Coord } from "./Coordinate.sol";

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
    // RTPiece memory piece = _pieces[action.executorIndex];
    uint8 actionType = action.actionType;
    uint256[] memory subActions;
    if (actionType == 1) {
      subActions = _cast();
    } else if (actionType == 2) {
      subActions = _attack(_pieces, _cache, action.executorIndex, action.targetIndex);
    } else if (actionType == 3) {
      subActions = _move(_pieces, _map, _cache, action.executorIndex, action.value);
    }
    doSubActions(_pieces, _cache, subActions);
  }

  function doSubActions(
    RTPiece[] memory _pieces,
    EffectCache memory _cache,
    uint256[] memory _subActions
  ) view private {
    uint256 num = _subActions.length;
    for (uint256 i; i < num; ++i) {
      uint256 subAction = _subActions[i];
      if (subAction == 0) {
        continue;
      }
      // todo 
      // case 1 attribute modification
      // case 2 cast sub ability
      // case 3 deal real damage directly
    }
  }

  function _cast() view private returns (uint256[] memory subActions) {
    // cast a spell
    // todo
  }

  function _attack(
    RTPiece[] memory _pieces,
    EffectCache memory _cache,
    uint256 _attackerIndex,
    uint256 _targetIndex
  ) view private returns (uint256[] memory subActions) {
    subActions = new uint256[](3);

    RTPiece memory attacker = _pieces[_attackerIndex];
    uint256 damage;
    (damage, subActions[0]) = attacker.atk(_cache);
    
    RTPiece memory target = _pieces[_targetIndex];
    uint256 realDamage;
    (realDamage, subActions[1]) = target.receiveDamage(_cache, damage);

    subActions[2] = attacker.dealDamage(_cache, realDamage);

    _pieces[_attackerIndex] = attacker;
    _pieces[_targetIndex] = target;
  }

  function _move(
    RTPiece[] memory _pieces,
    uint8[][] memory _map,
    EffectCache memory _cache,
    uint256 _moverIndex,
    uint256 _destination
  ) view private returns (uint256[] memory subActions) {
    subActions = new uint256[](1);
    // move a piece to a specific positon
    RTPiece memory piece = _pieces[_moverIndex];
    subActions[0] = piece.moveTo(_cache, _map, _destination);
    _pieces[_moverIndex] = piece;
  }
}
