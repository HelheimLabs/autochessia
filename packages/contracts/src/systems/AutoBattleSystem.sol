// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { Creatures, CreaturesData, GameConfig } from "../codegen/Tables.sol";
import { Board, BoardData } from "../codegen/Tables.sol";
import { Piece, PieceData } from "../codegen/Tables.sol";
import { PieceInBattle, PieceInBattleData } from "../codegen/Tables.sol";
import { Game, GameData } from "../codegen/Tables.sol";
import { Player } from "../codegen/Tables.sol";
import { GameStatus, BoardStatus, PlayerStatus } from "../codegen/Types.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";

/**
 * @notice run-time piece
 */
struct RTPiece {
  bytes32 id; //pieceInBattleId
  bytes32 pieceId;
  uint256 owner;
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

/**
 * @notice run-time board
 */
struct RTBoard {
  uint32 gameId;
  address player;
  address opponent;
  bytes32[] ids; // all pieces in battle on this board including one with 0 current health
  RTPiece[] pieces; // only living pieces in battle
  uint256[][] map;
  uint256 round;
  uint256 turn;
  uint256[] allyList;
  uint256[] enemyList;
}

contract AutoBattleSystem is System {
  function autoBattle(uint32 _gameId, address _player) public returns (uint256) {
    // pre. create run-time board
    RTBoard memory board = createRTBoard(_gameId, _player);

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
      uint256[] memory enemyList = piece.owner == 1 ? board.enemyList : board.allyList;

      // find a target
      uint256 targetIndex = type(uint256).max;
      // RTPiece memory target;
      console.log("piece %d start turn, (%d,%d)", i, piece.x, piece.y);
      for (uint j; j < enemyList.length; ++j) {
        RTPiece memory enemy = pieces[enemyList[j]];
        if (enemy.curHealth == 0) {
          continue;
        }
        // enemy in attack range
        if (Coord.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          targetIndex = enemyList[j];
          console.log("  piece %d in its attack range, at position (%d,%d)", enemyList[j], enemy.x, enemy.y);
          break;
        }
      }

      // if no target in attack range, find an available closest target and move towards to it.
      if (targetIndex == type(uint256).max) {
        console.log("  no enemy in attack range, finding closest attackable enemy");
        uint256 minDst = type(uint256).max;
        // set piece's current position to walkable
        board.map[piece.x][piece.y] = 0;
        uint256 availPositionX = piece.x;
        uint256 availPositionY = piece.y;
        for (uint j; j < enemyList.length; ++j) {
          RTPiece memory enemy = pieces[enemyList[j]];
          console.log("  checking enemy index %d, (%d,%d)", enemyList[j], enemy.x, enemy.y);
          if (enemy.curHealth == 0) {
            continue;
          }
          (uint256 dst, uint256 coord) = findBestAttackPosition(board.map, piece, enemy);
          if ((dst > 0) && (dst < minDst)) {
            targetIndex = enemyList[j];
            minDst = dst;
            (availPositionX, availPositionY) = Coord.decompose(coord);
          }
        }
        piece.x = availPositionX;
        piece.y = availPositionY;
        // set piece's current position to obstacle
        board.map[piece.x][piece.y] = 1;
        console.log("  move towards cloest and attackable enemy, end at (%d,%d)", piece.x, piece.y);
      }

      // attack the target if it's in the piece's attack range
      if (targetIndex < type(uint256).max) {
        RTPiece memory enemy = pieces[targetIndex];
        if (Coord.distance(piece.x, piece.y, enemy.x, enemy.y) <= piece.range) {
          uint256 damage = piece.attack > enemy.defense ? piece.attack - enemy.defense : 0;
          if (enemy.curHealth > damage) {
            enemy.curHealth = enemy.curHealth - damage;
          } else {
            enemy.curHealth = 0;
            // set enemy's current position to walkable
            board.map[piece.x][piece.y] = 0;
          }
          pieces[targetIndex] = enemy;
          console.log("  attack target %d, cause damage %d, its current hp %d", targetIndex, damage, enemy.curHealth);
        }
      }
      pieces[i] = piece;
    }
    board.pieces = pieces;
    endTurn(board);
  }

  function createRTBoard(uint32 _gameId, address _player) internal returns (RTBoard memory rtBoard) {
    GameData memory game = Game.get(_gameId);
    require(game.status != GameStatus.FINISHED, "bad game status");
    require(game.player1 == _player || game.player2 == _player, "player mismatch game");
    require(Board.getStatus(_player) != BoardStatus.FINISHED, "bad board status");

    // create run-time pieces
    (RTPiece[] memory rtPieces, uint256[] memory allyList, uint256[] memory enemyList, bytes32[] memory ids) = createRTPieces(_player);
    uint256 pieceNum = rtPieces.length;

    // create map
    uint256 length = GameConfig.getLength() * 2;
    uint256 width = GameConfig.getWidth();
    uint256[][] memory map = new uint256[][](length);
    for (uint i; i < length; ++i) {
      map[i] = new uint256[](width);
    }
    for (uint i; i < pieceNum; ++i) {
      RTPiece memory piece = rtPieces[i];
      map[piece.x][piece.y] = 1;
    }

    rtBoard = RTBoard({
      gameId: _gameId,
      player: _player,
      opponent: game.player1 == _player ? game.player2 : game.player1,
      ids: ids,
      pieces: rtPieces,
      map: map,
      round: game.round,
      turn: uint256(Board.getTurn(_player)),
      allyList: allyList,
      enemyList: enemyList
    });
  }

  /**
   * @notice create a sorted array of run-time pieces.
   */
  function createRTPieces(address _player) internal view returns (RTPiece[] memory rtPieces, uint256[] memory allyList,  uint256[] memory enemyList, bytes32[] memory ids) {
    uint256 num1;
    (rtPieces, num1, ids) = createRTPiecesFromPiecesInBattle(_player);

    // generate ally and enemy lists
    uint256 num = rtPieces.length;
    allyList = new uint256[](num1);
    enemyList = new uint256[](num - num1);
    for ((uint i, uint j, uint k) = (0, 0, 0); i < num; ++i) {
      RTPiece memory piece = rtPieces[i];
      if (piece.owner == 1) {
        allyList[j++] = i;
      } else {
        enemyList[k++] = i;
      }
    }
  }

  function createRTPiecesFromPiecesInBattle(address _player) internal view returns (RTPiece[] memory rtPieces, uint256 liveNum1, bytes32[] memory ids) {
    // create run-time piece from pieces in battle on player1's board
    bytes32[] memory pieceInBattleIds1 = Board.getPieces(_player);
    bytes32[] memory pieceInBattleIds2 = Board.getEnemyPieces(_player);
    uint256 liveNum;
    
    {
      uint256 num1 = pieceInBattleIds1.length;
      uint256 num = num1 + pieceInBattleIds2.length; 
      ids = new bytes32[](num);
      for (uint i; i < num; ++i) {
        bytes32 id = i < num1 ? pieceInBattleIds1[i] : pieceInBattleIds2[i-num1];
        if (PieceInBattle.getCurHealth(id) == 0) {
          ids[num-1-(i-liveNum)] = id;
        } else {
          ids[liveNum++] = id;
          if (i < num1) {
            ++liveNum1;
          }
        }
      }
    }

    rtPieces = new RTPiece[](liveNum);
    for (uint i; i < liveNum; ++i) {
      bytes32 id = ids[i];
      PieceInBattleData memory pieceInBattle = PieceInBattle.get(id);
      CreaturesData memory data = Creatures.get(Piece.getCreature(pieceInBattle.pieceId));
      RTPiece memory rtPiece = RTPiece({
        id: id,
        pieceId: pieceInBattle.pieceId,
        owner: i < liveNum1 ? 1 : 2,
        tier: uint256(Piece.getTier(pieceInBattle.pieceId)),
        x: uint256(pieceInBattle.x),
        y: uint256(pieceInBattle.y),
        curHealth: uint256(pieceInBattle.curHealth),
        maxHealth: uint256(data.health),
        attack: uint256(data.attack),
        range: uint256(data.range),
        defense: uint256(data.defense),
        speed: uint256(data.speed),
        movement: uint256(data.movement)
      });
      // insert sorting according to speed in ascending direction
      uint j = i;
      while ((j > 0) && (rtPieces[j-1].speed > rtPiece.speed)) {
          rtPieces[j] = rtPieces[j-1];
          --j;
      }
      rtPieces[j] = rtPiece;
    }
  }

  function findBestAttackPosition(
    uint256[][] memory _map,
    RTPiece memory _piece,
    RTPiece memory _target
  ) internal view returns (uint256 dst, uint256 coord) {
    uint256 left;
    uint256 right;
    int256 directionX = 1;
    {
      uint256 x = _target.x;
      uint256 range = _piece.range;
      left = x > range ? x - range : 0;
      uint256 length = _map.length;
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
      uint256 width = _map[0].length;
      up = (y + range) < width ? y + range : width;
      if (_piece.y > y) {
        directionY = -1;
        (up, down) = (down, up);
      }
    }

    while (left != right) {
      uint256 temp = down;
      while (down != up) {
        if (_map[left][down] == 0) {
          uint256[] memory path = IWorld(_world()).findPath(_map, _piece.x, _piece.y, left, down);
          dst = path.length - 1;
          if (dst > 0) {
            console.log("    attack position (%d,%d), dst %d", left, down, dst);
            coord = path[dst];
            if (dst > _piece.movement) {
              coord = path[_piece.movement];
            }
            return (dst, coord);
          }
        }
        down = uint256(int256(down) + directionY);
      }
      down = temp;
      left = uint256(int256(left) + directionX);
    }
    return (dst, coord);
  }

  function endTurn(RTBoard memory _board) internal {
    (uint256 winner, uint256 damageTaken) = getWinnerOfRound(_board);
    updateStorage(_board, winner, damageTaken);
  }

  /**
   * @param winner: 0: nobody, 1: player1, 2：player2, 3: draw
   */
  function getWinnerOfRound(RTBoard memory _board) private returns (uint256 winner, uint256 damageTaken) {
    RTPiece[] memory pieces = _board.pieces;
    uint256[] memory list = _board.enemyList;
    uint256 sumHealth;
    uint256 length = list.length;
    for (uint i; i < length; ++i) {
      RTPiece memory piece = pieces[list[i]];
      if (piece.curHealth != 0) {
        sumHealth += piece.curHealth;
        damageTaken += piece.tier + 1;
      }
    }
    // if all enemy died, winner is player1 or draw in case where all allies died also
    if (sumHealth == 0) {
      winner = 1;
    }
    list = _board.allyList;
    length = list.length;
    sumHealth = 0;
    for (uint i; i < length; ++i) {
      sumHealth += pieces[list[i]].curHealth;
    }
    // if all allies died
    if (sumHealth == 0) {
      // if all enemy died also
      if (winner == 1) {
        // draw
        winner = 3;
      } else {
        // winner is player2
        winner = 2;
      }
    } 
    if (winner == 0) {
      damageTaken = 0;
    }
  }

  function updateStorage(RTBoard memory _board, uint256 _winner, uint256 _damageTaken) private {
    RTPiece[] memory pieces = _board.pieces;
    uint32 gameId = _board.gameId;
    address player = _board.player;

    if (_winner == 0) {
      _updateWhenBoardNotFinished(_board);
      return;
    }

    (uint256 playerHealth, bool roundEnded) = _updateWhenBoardFinished(gameId, player, _winner, _damageTaken);

    if (!roundEnded) {
      _updateWhenRoundNotEnd(_board);
      return;
    }
    
    uint8 gameWinner = _getGameWinner(_board, playerHealth);

    if (gameWinner == 0) {
      _updateWhenRoundEndedButGameNotFinished(_board);
    } else {
      _updateWhenGameFinished(_board);
    }
  }

  /**
   * @notice this round is not yet finished, update all pieces in battle
   */
  function _updateWhenBoardNotFinished(RTBoard memory _board) internal {
    RTPiece[] memory pieces = _board.pieces;
    uint256[] memory list = _board.allyList;
    uint256 num = list.length;
    for (uint i; i < num; ++i) {
      RTPiece memory piece = pieces[list[i]];
      PieceInBattle.setCurHealth(piece.id, uint32(piece.curHealth));
      PieceInBattle.setX(piece.id, uint32(piece.x));
      PieceInBattle.setY(piece.id, uint32(piece.y));
    }
    list = _board.enemyList;
    num = list.length;
    for (uint i; i < num; ++i) {
      RTPiece memory piece = pieces[list[i]];
      PieceInBattle.setCurHealth(piece.id, uint32(piece.curHealth));
      PieceInBattle.setX(piece.id, uint32(piece.x));
      PieceInBattle.setY(piece.id, uint32(piece.y));
    }
    address player = _board.player;
    uint256 turn = _board.turn;
    Board.setTurn(player, uint32(turn + 1));
    // modify status of board and game if it's the first turn
    if (turn == 0) {
      Game.setStatus(_board.gameId, GameStatus.INBATTLE);
      Board.setStatus(player, BoardStatus.INBATTLE);
    }
  }

  function _updateWhenBoardFinished(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken) internal returns (uint256 playerHealth, bool roundEnded) {
    // update board status
    Board.setStatus(_player, BoardStatus.FINISHED);

    // update player's health and streak
    _updatePlayerStreakCount(_player, _winner);
    playerHealth = _updatePlayerHealth(_player, _winner, _damageTaken);

    // update finished board num
    roundEnded = _updateFinishedBoard(_gameId);
  }

  function _updateWhenRoundNotEnd(RTBoard memory _board) internal {
    _resetAllPiecesInBattle(_board);
  }

  function _updateWhenGameFinished(RTBoard memory _board) internal {
    Game.setStatus(gameId, GameStatus.FINISHED);
    Player.setStatus(player, PlayerStatus.UNINITIATED);
    Player.setStatus(_board.opponent, PlayerStatus.UNINITIATED);
    Game.setWinner(gameId, winner);
    _removeAllPiecesInBattle(_board);
  }

  function _updateWhenRoundEndedButGameNotFinished(RTBoard memory _board) {
    Game.setRound(gameId, uint32(_board.round + 1));
    Game.setStatus(gameId, GameStatus.PREPARING);
    Board.setStatus(player, BoardStatus.UNINITIATED);
    Board.setStatus(_board.opponent, BoardStatus.UNINITIATED);
    _resetAllPiecesInBattle(_board);
    IWorld(_world()).settleRound(gameId);
  }

  function _getGameWinner(RTBoard memory _board, uint256 _playerHealth) internal returns (uint8 winner) {
    address opponent = _board.opponent;
    uint256 opponentHealth = Player.getHealth(opponent);

    if (_playerHealth == 0 || opponentHealth == 0) {
      if (_playerHealth == 0 && opponentHealth == 0) {
        winner = 3;
      } else if (_playerHealth == 0) {
        winner = 2;
      } else if (opponentHealth == 0) {
        winner = 1;
      }
    }
  }

  function _updateGameIfFinished(RTBoard memory _board, uint256 _playerHealth) internal returns (bool gameFinished) {
    uint32 gameId = _board.gameId;
    address player = _board.player;
    address opponent = _board.opponent;
    uint256 opponentHealth = Player.getHealth(opponent);

    if (_playerHealth == 0 || opponentHealth == 0) {
      Game.setStatus(gameId, GameStatus.FINISHED);
      Player.setStatus(player, PlayerStatus.UNINITIATED);
      Player.setStatus(_board.opponent, PlayerStatus.UNINITIATED);
      gameFinished = true;
    } else {
      return false;
    }
    if (_playerHealth == 0 && opponentHealth == 0) {
      Game.setWinner(gameId, 3);
    } else if (_playerHealth == 0) {
      Game.setWinner(gameId, 2);
    } else if (opponentHealth == 0) {
      Game.setWinner(gameId, 2);
    }
  }

  function _updatePlayerStreakCount(address _player, uint256 _winner) internal {
    int256 streakCount = Player.getStreakCount(_player);
    if (_winner == 1) {
      streakCount = streakCount > 0 ? streakCount + 1 : int256(1);
    } else if (_winner == 2) {
      streakCount = streakCount < 0 ? streakCount - 1 : int256(-1);
    } else {
      // _winner == 3
      streakCount == 0;
    }
    Player.setStreakCount(_player, int8(streakCount));
  }

  function _updatePlayerHealth(address _player, uint256 _winner, uint256 _damageTaken) internal returns (uint256 health) {
    health = Player.getHealth(_player);
    if (_winner == 2) {
      health = health > _damageTaken ? health - _damageTaken : 0;
      Player.setHealth(_player, uint8(health));
    }
  }

  function _updateFinishedBoard(uint32 _gameId) internal returns (bool roundEnded) {
    uint256 finishedBoard = Game.getFinishedBoard(_gameId);
    ++finishedBoard;
    if (finishedBoard == 2) {
      roundEnded = true;
      finishedBoard = 0;
    }
    Game.setFinishedBoard(_gameId, uint8(finishedBoard));
  }

  function _resetAllPiecesInBattle(RTBoard memory _board) internal {

  }

  function _removeAllPiecesInBattle(RTBoard memory _board) internal {
    // remove all pieces in battle since this round for player1 has finished
    {
      bytes32[] memory ids = _board.ids;
      uint256 num = ids.length;
      for (uint i; i < num; ++i) {
        PieceInBattle.deleteRecord(ids[i]);
      }
    }
  }
}
