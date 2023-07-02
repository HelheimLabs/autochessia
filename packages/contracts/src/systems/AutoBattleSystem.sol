// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Creatures, CreaturesData, GameConfig } from "../codegen/Tables.sol";
import { Board, BoardData } from "../codegen/Tables.sol";
import { Piece, PieceData } from "../codegen/Tables.sol";
import { JPS } from "../library/JPS.sol";
import { BoardStatus } from "../codegen/Types.sol";

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
  bytes32 id;
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
    uint256 num = pieces.length;
    for (uint i; i < num; ++i) {
      RTPiece memory piece = pieces[i];
      if (piece.curHealth == 0) {
        continue;
      }
      uint256[] memory enemyList = piece.owner == 1 ? board.enemyList1 : board.enemyList2;
      // uint256 enemyNum = enemyList.length;
      // find a target
      uint256 targetIndex = type(uint256).max;
      // RTPiece memory target;
      console.log("piece %d start turn, x %d, y %d", i, piece.x, piece.y);
      for (uint j; j < enemyList.length; ++j) {
        RTPiece memory enemy = pieces[enemyList[j]];
        if (enemy.curHealth == 0) {
          continue;
        }
        // enemy in attack range
        if (JPS.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          targetIndex = enemyList[j];
          console.log("  piece %d in its attack range, at position x %d y %d", enemyList[j], enemy.x, enemy.y);
          break;
        }
      }
      // if no target in attack range, find an available closest target and move towards to it.
      if (targetIndex == type(uint256).max) {
        console.log("  no enemy in attack range, finding closest attackable enemy");
        uint256 minDst = type(uint256).max;
        uint256 finalX = type(uint256).max;
        uint256 finalY = type(uint256).max;
        for (uint j; j < enemyList.length; ++j) {
          RTPiece memory enemy = pieces[enemyList[j]];
          if (enemy.curHealth == 0) {
            continue;
          }
          board.field[piece.x][piece.y] = 0;
          (uint256 dst, uint256 x, uint256 y) = findBestAttackPosition(board.field, piece, enemy);
          if ((dst > 0) && (dst < minDst)) {
            targetIndex = enemyList[j];
            minDst = dst;
            piece.x = x;
            piece.y = y;
            // todo update field
            console.log("  find closer attackable enemy, piece %d at x %d y %d", enemyList[j], enemy.x, enemy.y);
            console.log("  best attack position is x %d y %d", x, y);
          }
        }
      }
      // attack the target if it's in the piece's attack range
      if (targetIndex < type(uint256).max) {
        RTPiece memory enemy = pieces[targetIndex];
        if (JPS.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          uint256 damage = piece.attack > enemy.defense ? piece.attack - enemy.defense : 0;
          enemy.curHealth = enemy.curHealth > damage ? enemy.curHealth - damage : 0;
          pieces[targetIndex] = enemy;
          console.log("  attack target %d, cause damage %d, its current hp %d", targetIndex, damage, enemy.curHealth);
        }
      }
      pieces[i] = piece;
    }
    board.pieces = pieces;
    endTurn(board);
  }

  function createRTBoard(bytes32 _boardId) internal returns (RTBoard memory rtBoard) {
    BoardData memory board = Board.get(_boardId);
    require(board.status == BoardStatus.INBATTLE, "bad status");
    uint256 length = GameConfig.getLength();
    uint256 width = GameConfig.getWidth();
    console.log("board length %d, width %d", length, width);
    uint256[][] memory fieldInput = new uint256[][](length);
    for (uint i; i < length; ++i) {
      fieldInput[i] = new uint256[](width);
    }

    (RTPiece[] memory rtPieces, uint256 pieceNumOfPlayer1) = createRTPieces(Board.getPieces(_boardId));
    uint256 pieceNum = rtPieces.length;
    console.log("total piece num %d, num of piece owned by player1 %d", pieceNum, pieceNumOfPlayer1);
    uint256[] memory enemyList1 = new uint256[](pieceNum - pieceNumOfPlayer1);
    uint256[] memory enemyList2 = new uint256[](pieceNumOfPlayer1);
    for ((uint i, uint j, uint k) = (0, 0, 0); i < pieceNum; ++i) {
      RTPiece memory piece = rtPieces[i];
      fieldInput[piece.x][piece.y] = 1;
      if (piece.owner == 1) {
        enemyList2[j++] = i;
      } else {
        enemyList1[k++] = i;
      }
    }
    uint256[][] memory field = JPS.generateField(fieldInput);

    rtBoard = RTBoard({
      id: _boardId,
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
  function createRTPieces(bytes32[] memory _piecesId) internal view returns (RTPiece[] memory rtPieces, uint256 numPlayer1) {
    uint256 num = _piecesId.length;
    rtPieces = new RTPiece[](num);
    for (uint i; i < num; ++i) {
      PieceData memory piece = Piece.get(_piecesId[i]);
      if (piece.curHealth == 0) {
        continue;
      }
      if (piece.owner == 1) {
        ++numPlayer1;
      }
      CreaturesData memory data = Creatures.get(piece.creature);
      RTPiece memory rtPiece = RTPiece({
        id: _piecesId[i],
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

  function endTurn(RTBoard memory _board) internal {
    uint256 winner = getWinnerOfRound(_board);
    updateBoard(winner, _board);
  }

  /*
   * @param winner: 0: nobody, 1: player1, 2：player2, 3: draw
   */
  function getWinnerOfRound(RTBoard memory _board) private returns (uint256 winner) {
    RTPiece[] memory pieces = _board.pieces;
    uint256[] memory enemyList = _board.enemyList1;
    uint256 sumHealth;
    uint256 length = enemyList.length;
    for (uint i; i < length; ++i) {
      sumHealth += pieces[enemyList[i]].curHealth;
    }
    if (sumHealth == 0) {
      winner = 1;
    }
    enemyList = _board.enemyList2;
    length = enemyList.length;
    sumHealth = 0;
    for (uint i; i < length; ++i) {
      sumHealth += pieces[enemyList[i]].curHealth;
    }
    if (sumHealth == 0) {
      if (winner == 1) {
        winner = 3;
      } else {
        winner = 2;
      }
    }
  }

  function updateBoard(uint256 _winner, RTBoard memory _board) private {
    RTPiece[] memory pieces = _board.pieces;
    uint256 length = pieces.length;
    // update pieces
    for (uint i; i < length; ++i) {
      RTPiece memory piece = pieces[i];
      bytes32 id = piece.id;
      Piece.setCurHealth(id, uint32(piece.curHealth));
      Piece.setX(id, uint32(piece.x));
      Piece.setY(id, uint32(piece.y));
    }
    // update board
    if (_winner == 0) {
      Board.setTurn(_board.id, uint32(_board.turn + 1));
    } else {
      bytes32 id = _board.id;
      Board.setTurn(id, 0);
      Board.setRound(id, uint32(_board.round + 1));
      Board.setStatus(id, BoardStatus.PREPARING);
      Board.setLastWinner(id, uint8(_winner));
    }
  }
}
