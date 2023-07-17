// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { Creature, CreatureData, GameConfig, CreatureConfig } from "../codegen/Tables.sol";
import { Board, BoardData } from "../codegen/Tables.sol";
import { Hero, HeroData } from "../codegen/Tables.sol";
import { Piece, PieceData } from "../codegen/Tables.sol";
import { Game, GameData } from "../codegen/Tables.sol";
import { PlayerGlobal, Player } from "../codegen/Tables.sol";
import { GameStatus, BoardStatus, PlayerStatus } from "../codegen/Types.sol";
import { Coordinate as Coord } from "../library/Coordinate.sol";
import { PieceAction } from "../library/PieceAction.sol";
import { RTPiece } from "../library/RunTimePiece.sol";
import { Utils } from "../library/Utils.sol";

contract AutoBattleSystem is System {
  function tick(uint32 _gameId, address _player) public {
    beforeTurn(_gameId, _player);

    (uint8 winner, uint256 damageTaken) = IWorld(_world()).startTurn(_player);

    endTurn(_gameId, _player, winner, damageTaken);
  }

  function beforeTurn(uint32 _gameId, address _player) internal {
    require(PlayerGlobal.getGameId(_player) == _gameId, "mismatch game");
    GameStatus gameStatus = Game.getStatus(_gameId);
    require(gameStatus != GameStatus.FINISHED, "bad game status");
    if (gameStatus == GameStatus.PREPARING) {
      require(block.number >= Game.getStartFrom(_gameId), "preparing time");
    }
    BoardStatus boardStatus = Board.getStatus(_player);
    require(boardStatus != BoardStatus.FINISHED, "bad board status");

    if (boardStatus == BoardStatus.UNINITIATED) {
      // select another player as opponent of _player
      address opponent;
      address player1 = Game.getPlayer1(_gameId);
      if (player1 == _player) {
        opponent = Game.getPlayer2(_gameId);
      } else {
        opponent = player1;
      }
      _initPieceOnBoard(_player, opponent);
      Game.setStatus(_gameId, GameStatus.INBATTLE);
    }
  }

  function endTurn(
    uint32 _gameId,
    address _player,
    uint256 _winner,
    uint256 _damageTaken
  ) private {
    if (_winner == 0) {
      _updateWhenBoardNotFinished(_player);
      return;
    }

    (uint256 playerHealth, bool roundEnded) = _updateWhenBoardFinished(_gameId, _player, _winner, _damageTaken);

    if (!roundEnded) {
      _updateWhenRoundNotEnd();
      return;
    }

    // end round
    _updateWhenRoundEnded(_gameId, _player);

    uint8 gameWinner = _getGameWinner(_gameId, _player, playerHealth);

    if (gameWinner == 0) {
      _updateWhenGameNotFinished(_gameId);
    } else {
      // end game
      _updateWhenGameFinished(_gameId, _player, gameWinner);
    }
  }

  function _initPieceOnBoard(address _player, address _opponent) internal {
    Board.set(
      _player,
      BoardData({
        enemy: _opponent,
        status: BoardStatus.INBATTLE,
        turn: 0,
        pieces: Utils.createPieces(_player, true),
        enemyPieces: Utils.createPieces(_opponent, false)
      })
    );
  }

  /**
   * @notice this round is not yet finished
   */
  function _updateWhenBoardNotFinished(address _player) internal {
    Board.setTurn(_player, Board.getTurn(_player) + 1);
  }

  function _updateWhenBoardFinished(
    uint32 _gameId,
    address _player,
    uint256 _winner,
    uint256 _damageTaken
  ) internal returns (uint256 playerHealth, bool roundEnded) {
    // update board status
    Board.setStatus(_player, BoardStatus.FINISHED);

    // delete piece in battle
    Utils.deleteAllPieces(_player);

    // update player's health and streak
    Utils.updatePlayerStreakCount(_player, _winner);
    playerHealth = Utils.updatePlayerHealth(_player, _winner, _damageTaken);

    // update finished board num
    roundEnded = Utils.incrementFinishedBoard(_gameId);
  }

  function _updateWhenRoundNotEnd() internal {
    // do nothing
  }

  function _updateWhenRoundEnded(uint32 _gameId, address _player) internal {
    Game.setRound(_gameId, Game.getRound(_gameId) + 1);
    // loop each player in this game, todo for multiplayer
    address opponent = Board.getEnemy(_player);
    Board.setStatus(_player, BoardStatus.UNINITIATED);
    Board.setStatus(opponent, BoardStatus.UNINITIATED);
    // settle round moved to _updateWhenGameNotFinished for saving gas
  }

  function _updateWhenGameFinished(
    uint32 _gameId,
    address _player,
    uint8 _winner
  ) internal {
    Game.setStatus(_gameId, GameStatus.FINISHED);
    // loop each player in this game, todo for multiplayer
    PlayerGlobal.setStatus(_player, PlayerStatus.UNINITIATED);
    Player.deleteRecord(_player);
    address opponent = Board.getEnemy(_player);
    PlayerGlobal.setStatus(opponent, PlayerStatus.UNINITIATED);
    Player.deleteRecord(opponent);
    Game.setWinner(_gameId, _winner);
  }

  function _updateWhenGameNotFinished(uint32 _gameId) internal {
    Game.setStatus(_gameId, GameStatus.PREPARING);
    uint64 roundInterval = GameConfig.getRoundInterval();
    Game.setStartFrom(_gameId, uint64(block.number) + roundInterval);
    IWorld(_world()).settleRound(_gameId);
  }

  function _getGameWinner(
    uint32 _gameId,
    address _player,
    uint256 _playerHealth
  ) internal returns (uint8 winner) {
    address opponent = Board.getEnemy(_player);
    uint256 opponentHealth = Player.getHealth(opponent);
    address player1 = Game.getPlayer1(_gameId);

    if (_playerHealth == 0 || opponentHealth == 0) {
      if (_playerHealth == 0 && opponentHealth == 0) {
        winner = 3;
      } else if (_playerHealth == 0) {
        if (player1 == opponent) {
          winner = 1;
        } else {
          winner = 2;
        }
      } else if (opponentHealth == 0) {
        if (player1 == opponent) {
          winner = 2;
        } else {
          winner = 1;
        }
      }
    }
  }
}
