// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { System } from "@latticexyz/world/src/System.sol";
import { Creatures, CreaturesData, GameConfig } from "../codegen/Tables.sol";
import { Board, BoardData } from "../codegen/Tables.sol";
import { Piece, PieceData } from "../codegen/Tables.sol";
import { JPS } from "../library/JPS.sol";

/*
 * @note run-time piece
 */
struct RTPiece {
    bytes32 id;
    uint256 owner;
    uint256 x; // position x
    uint256 y; // position y
    uint256 curHealth;
    uint256 maxHealth;
    uint256 attack;
    uint256 range;
    uint256 defense;
    uint256 speed;
}

/*
 * @note run-time board
 */
struct RTBoard {
    RTPiece[] pieces;
    uint256[][] field;
    uint256 round;
    uint256 turn;
    uint256[] enemyList1;
    uint256[] enemyList2;
}

contract AutoBattleSystem is System {
  function autoBattle(bytes32 _boardId) public returns (uint256) {
    // pre. create run-time board
    RTBoard memory board = createRTBoard(_boardId);
    // for each piece
    // 1. find a target, rules: a) an enemy in attack range b) the closest and attackable enemy
    // note. If a piece is surrounded by other pieces, it cannot be attacked by pieces with an attack range of 1 
    // 2. if the target is in attack range, jump to 3. if else, move towards to the targe
    // 3. attack the target if the piece can.
    RTPiece[] memory pieces = board.pieces;
    // uint256 num = pieces.length;
    for (uint i; i < pieces.length; ++i) {
      RTPiece memory piece = pieces[i];
      if (piece.curHealth == 0) {
        continue;
      }
      uint256[] memory enemyList = piece.owner == 0 ? board.enemyList2 : board.enemyList1;
      // uint256 enemyNum = enemyList.length;
      // find a target
      uint256 targetIndex;
      // RTPiece memory target;
      for (uint j; j < enemyList.length; ++j) {
        RTPiece memory enemy = pieces[enemyList[j]];
        if (enemy.curHealth == 0) {
          continue;
        }
        // enemy in attack range
        if (JPS.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          targetIndex = enemyList[j];
          break;
        }
      }
      // if no target in attack range, find an available closest target and move towards to it.
      if (pieces[targetIndex].maxHealth == 0) {
        uint256 minDst = type(uint256).max;
        for (uint j; j < enemyList.length; ++j) {
          RTPiece memory enemy = pieces[enemyList[j]];
          if (enemy.curHealth == 0) {
            continue;
          }
          (uint256 dst, uint256 x, uint256 y) = findBestAttackPosition(board.field, piece, enemy);
          if ((dst > 0) && (dst < minDst)) {
            targetIndex = enemyList[j];
            minDst = dst;
            piece.x = x;
            piece.y = y;
          }
        }
      }
      // attack the target if it's in the piece's attack range
      if (pieces[targetIndex].maxHealth > 0) {
        RTPiece memory enemy = pieces[targetIndex];
        if (JPS.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          uint256 damage = piece.attack > enemy.defense ? piece.attack - enemy.defense : 0;
          enemy.curHealth = enemy.curHealth > damage ? enemy.curHealth - damage : 0;
          pieces[targetIndex] = enemy;
        }
      }
      pieces[i] = piece;
    }
    endTurn();
  }

  function createRTBoard(bytes32 _boardId) internal returns (RTBoard memory rtBoard) {
    BoardData memory board = Board.get(_boardId);
    uint256 length = GameConfig.getLength();
    uint256 width = GameConfig.getWidth();
    uint256[][] memory fieldInput = new uint256[][](length);
    for (uint i; i < length; ++i) {
      fieldInput[i] = new uint256[](width);
    }

    (RTPiece[] memory rtPieces, uint256 pieceNumOfPlayer1) = createRTPieces(Board.getPieces(_boardId));
    uint256 pieceNum = rtPieces.length;
    uint256[] memory enemyList1 = new uint256[](pieceNum - pieceNumOfPlayer1);
    uint256[] memory enemyList2 = new uint256[](pieceNumOfPlayer1);
    for ((uint i, uint j, uint k) = (0, 0, 0); i < pieceNum; ++i) {
      RTPiece memory piece = rtPieces[i];
      fieldInput[piece.x][piece.y] = 1;
      if (piece.owner == 0) {
        enemyList1[j++] = i;
      } else {
        enemyList2[k++] = i;
      }
    }
    uint256[][] memory field = JPS.generateField(fieldInput);

    rtBoard = RTBoard({
      pieces: rtPieces,
      field: field,
      round: board.round,
      turn: board.turn,
      enemyList1: enemyList1,
      enemyList2: enemyList2
    });
  }

  /*
   * @note create a sorted array of run-time pieces.
   */
  function createRTPieces(bytes32[] memory _piecesId) public view returns (RTPiece[] memory rtPieces, uint256 numPlayer1) {
    uint256 num = _piecesId.length;
    rtPieces = new RTPiece[](num);
    for (uint i; i < num; ++i) {
      PieceData memory piece = Piece.get(_piecesId[i]);
      if (piece.owner == 0) {
        ++numPlayer1;
      }
      CreaturesData memory data = Creatures.get(piece.id);
      RTPiece memory rtPiece = RTPiece({
        id: piece.id,
        owner: uint256(piece.owner),
        x: uint256(piece.x),
        y: uint256(piece.y),
        curHealth: uint256(piece.curHealth),
        maxHealth: uint256(data.health),
        attack: uint256(data.attack),
        range: uint256(data.range),
        defense: uint256(data.defense),
        speed: uint256(data.speed)
      });
      uint j = i;
      while ((j > 0) && (rtPieces[j-1].speed < rtPiece.speed)) {
          rtPieces[j] = rtPieces[j-1];
          --j;
      }
      rtPieces[j] = rtPiece;
    }
  }

  function findBestAttackPosition(
    uint256[][] memory _field,
    RTPiece memory _piece,
    RTPiece memory _target
  ) internal view returns (uint256, uint256, uint256) {
    uint256 left;
    uint256 right;
    int256 directionX = 1;
    {
      uint256 x = _target.x;
      uint256 range = _piece.range;
      left = x > range ? x - range : 0;
      uint256 length = _field.length - 2;
      right = (x + range) < length ? x + range : length;
      if (_piece.x > x) {
        directionX = -1;
        (left, right) = (right, left);
      }
    }
    
    uint256 up;
    uint256 down;
    int256 directionY = 1;
    {
      uint256 y = _target.y;
      uint256 range = _piece.range;
      down = y > range ? y - range : 0;
      uint256 width = _field[0].length - 2;
      up = (y + range) < width ? y + range : width;
      if (_piece.y > y) {
        directionY = -1;
        (up, down) = (down, up);
      }
    }

    while (left != right) {
      while (down != up) {
        if (JPS.fieldNotObstacle(_field, left, down)) {
          uint256[] memory path = JPS.findPath(_field, _piece.x, _piece.y, left, down);
          // todo , now assuming infinit moving speed
          if (path.length > 0) {
            return (path.length, left, down);
          }
        }
        down = uint256(int256(down) + directionY);
      }
      left = uint256(int256(left) + directionX);
    }
    return (0, _piece.x, _piece.y);
  }

  function endTurn() internal {
    // todo
  }
}
