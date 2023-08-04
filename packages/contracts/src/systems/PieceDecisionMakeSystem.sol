// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { CreatureConfig, GameConfig } from "../codegen/Tables.sol";
import { Player, Board, Creature, Hero, Piece } from "../codegen/Tables.sol";
import { CreatureData, PieceData } from "../codegen/Tables.sol";
import { PQ, PriorityQueue } from "../library/PQ.sol";
import { JPS } from "../library/JPS.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";
import { PieceAction, Action } from "../library/PieceAction.sol";
import { RTPiece } from "../library/RunTimePiece.sol";

contract PieceDecisionMakeSystem is System {
  using PQ for PriorityQueue;

  uint32 private constant ATTACK_MODE_KILL_FIRST = (100 << 16) + 100;

  function startTurn(address _player) public returns (uint8 winner, uint256 damageTaken) {
    // generate and align pieces
    RTPiece[] memory pieces = _genAndAlignPieces(_player);
    uint256 num = pieces.length;
    // generate map
    uint8[][] memory map = _genMap(pieces);
    for (uint256 i; i < num; ++i) {
      uint256 action = decide(pieces, map, i);
      _simulateAction(pieces, map, i, action);
    }

    // end turn, update pieces
    _updatePieces(pieces);
    (winner, damageTaken) = _getWinner(pieces);
  }

  function decide(
    RTPiece[] memory _pieces,
    uint8[][] memory _map,
    uint256 _index
  ) internal returns (uint256 action) {
    RTPiece memory piece = _pieces[_index];
    if (piece.health == 0) {
      return 0;
    }

    PriorityQueue memory optionsQueue = PQ.New(_pieces.length);

    // todo skill
    // exploreSkillOption(_map, optionsQueue, piece, _pieces, SKILL_MODE_KILL_FIRST);

    exploreAttackOption(_map, optionsQueue, piece, _pieces, ATTACK_MODE_KILL_FIRST);

    action = optionsQueue.PopTask();
  }

  function exploreAttackOption(
    uint8[][] memory _map,
    PriorityQueue memory _pq,
    RTPiece memory _attacker,
    RTPiece[] memory _pieces,
    uint256 _mode
  ) internal {
    (uint256 killScore, uint256 damageScore) = (_mode >> 16, uint16(_mode));
    // simulate attacking each enemies and add score in queue
    uint256 length = _pieces.length;
    console.log("piece %d start turn, (%d,%d)", uint256(_attacker.id), _attacker.x, _attacker.y);
    console.log("attack range %d", _attacker.range);
    _setToWalkable(_map, _attacker.x, _attacker.y);
    for (uint256 i; i < length; ++i) {
      RTPiece memory enemy = _pieces[i];
      if (enemy.health == 0 || enemy.owner == _attacker.owner) {
        continue;
      }
      // enemy in attack range
      if (Coord.distance(_attacker.x, _attacker.y, enemy.x, enemy.y) <= _attacker.range) {
        console.log("  piece %d in its attack range, at position (%d,%d)", uint256(enemy.id), enemy.x, enemy.y);
        uint256 damage = _attacker.attack > enemy.defense ? _attacker.attack - enemy.defense : 0;
        if (enemy.health > damage) {
          // todo global index
          _pq.AddTask(
            PieceAction.generateAction(_attacker.x, _attacker.y, i, damage),
            type(uint256).max - ((damage * damageScore) / _attacker.attack)
          );
          continue;
        } else {
          _pq.AddTask(
            PieceAction.generateAction(_attacker.x, _attacker.y, i, damage),
            type(uint256).max - ((damage * damageScore) / _attacker.attack + killScore)
          );
          continue;
        }
      }
      // find attack position
      (uint256 dst, uint256 X, uint256 Y) = _findBestAttackPosition(_map, _attacker, enemy);
      if (dst > _attacker.movement) {
        // (uint256 X, uint256 Y) = Coord.decompose(coord);
        console.log("out of range, move to (%d,%d)", X, Y);
        _pq.AddTask(PieceAction.generateAction(X, Y, i, 0), type(uint256).max);
      } else {
        uint256 damage = _attacker.attack > enemy.defense ? _attacker.attack - enemy.defense : 0;
        if (enemy.health > damage) {
          // (uint256 X, uint256 Y) = Coord.decompose(coord);
          console.log("move to (%d,%d), cause damage %d", X, Y, damage);
          _pq.AddTask(
            PieceAction.generateAction(X, Y, i, damage),
            type(uint256).max - ((damage * damageScore) / _attacker.attack)
          );
          continue;
        } else {
          // (uint256 X, uint256 Y) = Coord.decompose(coord);
          _pq.AddTask(
            PieceAction.generateAction(X, Y, i, damage),
            type(uint256).max - ((damage * damageScore) / _attacker.attack + killScore)
          );
          continue;
        }
      }
    }
    _setToObstacle(_map, _attacker.x, _attacker.y);
  }

  function _simulateAction(
    RTPiece[] memory _pieces,
    uint8[][] memory _map,
    uint256 _index,
    uint256 _action
  ) internal {
    if (_action == 0) {
      return;
    }
    RTPiece memory piece = _pieces[_index];
    Action memory action = PieceAction.parseAction(_action);
    if (action.x != piece.x || action.y != piece.y) {
      _setToWalkable(_map, piece.x, piece.y);
      piece.x = action.x;
      piece.y = action.y;
      _setToObstacle(_map, action.x, action.y);
      piece.updated = true;
      _pieces[_index] = piece;
    }
    if (action.actionType == 1) {
      RTPiece memory attacked = _pieces[action.targetIndex];
      uint256 health = attacked.health;
      uint256 damage = action.value;
      if (health > damage) {
        attacked.health = uint32(health - damage);
      } else {
        attacked.health = 0;
        _setToWalkable(_map, attacked.x, attacked.y);
      }
      attacked.updated = true;
      _pieces[action.targetIndex] = attacked;
    }
  }

  /**
   * @notice generate a sorted array of run-time pieces.
   */
  function _genAndAlignPieces(address _player) internal view returns (RTPiece[] memory pieces) {
    bytes32[] memory ids1 = Board.getPieces(_player);
    bytes32[] memory ids2 = Board.getEnemyPieces(_player);
    uint256 num1 = ids1.length;
    uint256 num2 = ids2.length;
    uint256 length = num1 + num2;
    pieces = new RTPiece[](length);
    for (uint256 i; i < length; ++i) {
      bytes32 id = i < num1 ? ids1[i] : ids2[i - num1];
      PieceData memory piece = Piece.get(id);
      if (piece.health == 0) {
        continue;
      }
      RTPiece memory rtPiece = RTPiece({
        id: id,
        updated: false,
        tier: piece.tier,
        owner: i < num1 ? 0 : 1,
        index: i < num1 ? uint8(i) : uint8(i - num1),
        x: piece.x,
        y: piece.y,
        health: piece.health,
        maxHealth: piece.maxHealth,
        attack: piece.attack,
        range: piece.range,
        defense: piece.defense,
        speed: piece.speed,
        movement: piece.movement,
        creatureId: piece.creatureId
      });
      // insert sorting according to speed in ascending direction
      uint256 j = i;
      while ((j > 0) && (pieces[j - 1].speed > rtPiece.speed)) {
        pieces[j] = pieces[j - 1];
        --j;
      }
      pieces[j] = rtPiece;
    }
  }

  function _genMap(RTPiece[] memory _pieces) internal view returns (uint8[][] memory map) {
    uint256 length = GameConfig.getLength(0) * 2;
    uint256 width = GameConfig.getWidth(0);
    map = new uint8[][](length);
    for (uint256 i; i < length; ++i) {
      map[i] = new uint8[](width);
    }
    uint256 num = _pieces.length;
    for (uint256 i; i < num; ++i) {
      RTPiece memory piece = _pieces[i];
      map[piece.x][piece.y] = 1;
    }
  }

  function _findBestAttackPosition(
    uint8[][] memory _map,
    RTPiece memory _piece,
    RTPiece memory _target
  )
    internal
    view
    returns (
      uint256 dst,
      uint256 X,
      uint256 Y
    )
  {
    int256 left;
    int256 right;
    int256 directionX = 1;
    {
      uint256 x = _target.x;
      uint256 range = _piece.range;
      left = x > range ? int256(x - range) : int256(0);
      uint256 length = _map.length;
      right = (x + range) < length ? int256(x + range) : int256(length - 1);
      if (_piece.x > x) {
        directionX = -1;
        (left, right) = (right, left);
      }
    }

    int256 up;
    int256 down;
    int256 directionY = 1;
    {
      uint256 y = _target.y;
      uint256 range = _piece.range;
      down = y > range ? int256(y - range) : int256(0);
      uint256 width = _map[0].length;
      up = (y + range) < width ? int256(y + range) : int256(width - 1);
      if (_piece.y > y) {
        directionY = -1;
        (up, down) = (down, up);
      }
    }

    right += directionX;
    up += directionY;
    while (left != right) {
      int256 temp = down;
      while (down != up) {
        if (_map[uint256(left)][uint256(down)] == 0) {
          uint256[] memory path = JPS.findPath(_map, _piece.x, _piece.y, uint256(left), uint256(down));
          dst = path.length;
          if (dst > 0) {
            // console.log("    attack position (%d,%d), dst %d", left, down, dst);
            // coord = path[dst];
            --dst;
            if (dst > _piece.movement) {
              (X, Y) = Coord.decompose(path[_piece.movement]);
            } else {
              (X, Y) = Coord.decompose(path[dst]);
            }
            return (dst, X, Y);
          }
        }
        down = down + directionY;
      }
      down = temp;
      left = left + directionX;
    }
    return (dst, X, Y);
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

  /**
   * @param winner: 0: nobody, 1: player1, 2：player2, 3: draw
   */
  function _getWinner(RTPiece[] memory _pieces) private returns (uint8 winner, uint256 damageTaken) {
    uint256 allyHPSum;
    uint256 enemyHPSum;
    uint256 num = _pieces.length;
    for (uint256 i; i < num; ++i) {
      RTPiece memory piece = _pieces[i];
      if (piece.health == 0) {
        continue;
      }
      if (piece.owner == 0) {
        allyHPSum += piece.health;
      } else {
        enemyHPSum += piece.health;
        damageTaken += piece.tier + 1;
      }
    }

    if (allyHPSum == 0 && enemyHPSum == 0) {
      return (3, damageTaken);
    }
    if (allyHPSum == 0) {
      return (2, damageTaken);
    }
    if (enemyHPSum == 0) {
      return (1, damageTaken);
    }
    return (0, 0);
  }

  function _updatePieces(RTPiece[] memory _pieces) internal {
    uint256 num = _pieces.length;
    for (uint256 i; i < num; ++i) {
      _pieces[i].writeBack();
    }
  }
}
