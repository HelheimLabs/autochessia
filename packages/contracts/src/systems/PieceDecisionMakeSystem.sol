// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { CreatureConfig, GameConfig } from "../codegen/Tables.sol";
import { Player, Board, Creatures, Piece, PieceInBattle } from "../codegen/Tables.sol";
import { CreaturesData, PieceInBattleData } from "../codegen/Tables.sol";
import { PQ, PriorityQueue } from "../library/PQ.sol";
import { JPS } from "../library/JPS.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";
import { PieceAction } from "../library/PieceAction.sol";


/**
 * @notice run-time piece
 */
struct RTPiece {
  bytes32 id; //pieceId
  uint256 tier;
  uint256 x; // position x
  uint256 y; // position y
  uint256 curHealth;
  uint256 maxHealth;
  uint256 attack;
  uint256 range;
  uint256 defense;
  uint256 speed;
  uint256 movement;
}

contract PieceDecisionMakeSystem is System {
  using PQ for PriorityQueue;

  uint32 private constant ATTACK_MODE_KILL_FIRST = (100 << 16) + 100;

  function decide(address _player, bytes32 _pieceId) public returns (uint256 action) {
    // assume that non-zero health check is done before calling act
    // if (PieceInBattle.getCurHealth(_pieceId) == 0) {
    //   return;
    // }

    (RTPiece[] memory allies, RTPiece[] memory enemies) = _getPieces(_player, _pieceId);
    uint256[][] memory map = _generateMap(allies, enemies);

    PriorityQueue memory optionsQueue = PQ.New(enemies.length);
    exploreAttackOption(map, optionsQueue, allies[0], enemies, ATTACK_MODE_KILL_FIRST);

    action = optionsQueue.PopTask();
  }

  function _generateMap(RTPiece[] memory allies, RTPiece[] memory enemies) internal view returns (uint256[][] memory map) {
    uint256 length = GameConfig.getLength() * 2;
    uint256 width = GameConfig.getWidth();
    map = new uint256[][](length);
    for (uint256 i; i < length; ++i) {
      map[i] = new uint256[](width);
    }
    uint256 num = allies.length;
    for (uint256 i; i < num; ++i) {
      RTPiece memory piece = allies[i];
      map[piece.x][piece.y] = 1;
    }
    num = enemies.length;
    for (uint256 i; i < num; ++i) {
      RTPiece memory piece = enemies[i];
      map[piece.x][piece.y] = 1;
    }
  }

  function _getPieces(address _player, bytes32 _pieceId) internal view returns (RTPiece[] memory allies, RTPiece[] memory enemies) {
    bytes32[] memory ids1 = Board.getPieces(_player);
    bytes32[] memory ids2 = Board.getEnemyPieces(_player);
    uint256 num1 = ids1.length;
    uint256 num2 = ids1.length;
    uint256 length = num1 + num2;
    allies = new RTPiece[](num1);
    enemies = new RTPiece[](num2);
    uint256 index;
    for (uint256 i; i < length; ++i) {
      bytes32 id = i < num1 ? ids1[i] : ids2[i-num1];
      if (id == _pieceId) {
        index = i;
      }
      PieceInBattleData memory pieceInBattle = PieceInBattle.get(id);
      if (pieceInBattle.curHealth == 0) {
        continue;
      }
      CreaturesData memory data = Creatures.get(Piece.getCreature(pieceInBattle.pieceId));
      uint256 tier = Piece.getTier(pieceInBattle.pieceId);
      bool needAmplify = tier > 0;
      RTPiece memory rtPiece = RTPiece({
        id: id,
        tier: tier,
        x: uint256(pieceInBattle.x),
        y: uint256(pieceInBattle.y),
        curHealth: uint256(pieceInBattle.curHealth),
        maxHealth: needAmplify
          ? (uint256(data.health) * CreatureConfig.getItemHealthAmplifier(tier - 1)) / 100
          : uint256(data.health),
        attack: needAmplify
          ? (uint256(data.attack) * CreatureConfig.getItemAttackAmplifier(tier - 1)) / 100
          : uint256(data.attack),
        range: uint256(data.range),
        defense: needAmplify
          ? (uint256(data.defense) * CreatureConfig.getItemDefenseAmplifier(tier - 1)) / 100
          : uint256(data.defense),
        speed: uint256(data.speed),
        movement: uint256(data.movement)
      });
      if (i < num1) {
        allies[i] = rtPiece;
      } else {
        enemies[i-num1] = rtPiece;
      }
    }

    if (index < num1 && index > 0) {
      (allies[0], allies[index]) = (allies[index], allies[0]);
    } else if (index > num1) {
      (enemies[0], enemies[index-num1]) = (enemies[index-num1], enemies[0]);
      (allies, enemies) = (enemies, allies);
    }
  }

  function exploreAttackOption(uint256[][] memory map, PriorityQueue memory _pq, RTPiece memory attacker, RTPiece[] memory enemies, uint256 _mode) internal {
    (uint256 killScore, uint256 damageScore) = (_mode >> 16, uint16(_mode));
    // simulate attacking each enemies and add score in queue
    uint256 length = enemies.length;
    // console.log("piece %d start turn, (%d,%d)", i, piece.x, piece.y);
    _setToWalkable(map, attacker.x, attacker.y);
    for (uint256 i; i < length; ++i) {
      RTPiece memory enemy = enemies[i];
      if (enemy.curHealth == 0) {
        continue;
      }
      // enemy in attack range
      if (Coord.distance(attacker.x, attacker.y, enemy.x, enemy.y) <= attacker.range) {
        // console.log("  piece %d in its attack range, at position (%d,%d)", enemyList[j], enemy.x, enemy.y);
        uint256 damage = attacker.attack > enemy.defense ? attacker.attack - enemy.defense : 0;
        if (enemy.curHealth > damage) {
          _pq.AddTask(PieceAction.generateAction(attacker.x, attacker.y, i, damage), type(uint256).max - (damage * damageScore / attacker.attack));
          continue;
        } else {
          _pq.AddTask(PieceAction.generateAction(attacker.x, attacker.y, i, damage), type(uint256).max - (damage * damageScore / attacker.attack + killScore));
          continue;
        }
      }
      // find attack position
      (uint256 dst, uint256 coord) = findBestAttackPosition(map, attacker, enemy);
      if (dst > attacker.movement) {
        (uint256 X, uint256 Y) = Coord.decompose(coord);
        _pq.AddTask(PieceAction.generateAction(X, Y, i, 0), type(uint256).max);
      } else {
        uint256 damage = attacker.attack > enemy.defense ? attacker.attack - enemy.defense : 0;
        if (enemy.curHealth > damage) {
          _pq.AddTask(PieceAction.generateAction(attacker.x, attacker.y, i, damage), type(uint256).max - (damage * damageScore / attacker.attack));
          continue;
        } else {
          _pq.AddTask(PieceAction.generateAction(attacker.x, attacker.y, i, damage), type(uint256).max - (damage * damageScore / attacker.attack + killScore));
          continue;
        }
      }
    }
    _setToObstacle(map, attacker.x, attacker.y);
  }

  function findBestAttackPosition(
    uint256[][] memory _map,
    RTPiece memory _piece,
    RTPiece memory _target
  ) internal view returns (uint256 dst, uint256 coord) {
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
          dst = path.length - 1;
          if (dst > 0) {
            // console.log("    attack position (%d,%d), dst %d", left, down, dst);
            coord = path[dst];
            if (dst > _piece.movement) {
              coord = path[_piece.movement];
            }
            return (dst, coord);
          }
        }
        down = down + directionY;
      }
      down = temp;
      left = left + directionX;
    }
    return (dst, coord);
  }

  function _setToWalkable(
    uint256[][] memory _map,
    uint256 _x,
    uint256 _y
  ) private pure {
    _map[_x][_y] = 0;
  }

  function _setToObstacle(
    uint256[][] memory _map,
    uint256 _x,
    uint256 _y
  ) private pure {
    _map[_x][_y] = 1;
  }
}
