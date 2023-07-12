// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

struct Action {
  uint8 x;
  uint8 y;
  // todo enum
  uint8 actionType; // 1: attack
  uint8 targetIndex;
  uint16 value;
}

import "forge-std/Test.sol";
import { Player, Board, Creature, Hero, Piece } from "../codegen/Tables.sol";
import { RTPiece } from "./RunTimePiece.sol";

library PieceAction {
  function doAction(
    address _player,
    uint256 _index,
    uint256 _action
  ) internal {
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

  function generateAction(
    uint256 _x,
    uint256 _y,
    uint256 _targetIndex,
    uint256 _value
  ) internal pure returns (uint256 action) {
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
  }

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

  function _move(
    bytes32 _pieceId,
    uint8 _x,
    uint8 _y
  ) private {
    // move to a specific positon
    Piece.setX(_pieceId, _x);
    Piece.setY(_pieceId, _y);
  }

  function _defend() private {
    // todo, defend
  }
}
