// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig, CreatureConfig} from "../codegen/Tables.sol";
import {Board, BoardData} from "../codegen/Tables.sol";
import {Hero, HeroData} from "../codegen/Tables.sol";
import {Piece, PieceData} from "../codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../codegen/Tables.sol";
import {PlayerGlobal, Player} from "../codegen/Tables.sol";
import {GameStatus, BoardStatus, PlayerStatus} from "../codegen/Types.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {PieceAction} from "../library/PieceAction.sol";
import {RTPiece} from "../library/RunTimePiece.sol";
import {Utils} from "../library/Utils.sol";

contract AutoBattleSystem is System {
    function tick(uint32 _gameId, address _player) public {
        // the first tick for every board would be initializing pieces from heroes
        if (beforeTurn(_gameId, _player)) {
            return;
        }

        (uint8 winner, uint256 damageTaken) = IWorld(_world()).startTurn(_player);

        endTurn(_gameId, _player, winner, damageTaken);
    }

    function beforeTurn(uint32 _gameId, address _player) internal returns (bool firstTurn) {
        require(PlayerGlobal.getStatus(_player) == PlayerStatus.INGAME, "not in game");
        require(PlayerGlobal.getGameId(_player) == _gameId, "mismatch game id");
        GameStatus gameStatus = Game.getStatus(_gameId);
        require(gameStatus != GameStatus.FINISHED, "bad game status");
        if (gameStatus == GameStatus.PREPARING) {
            require(block.timestamp >= Game.getStartFrom(_gameId), "preparing time");
        }
        BoardStatus boardStatus = Board.getStatus(_player);
        require(boardStatus != BoardStatus.FINISHED, "waiting for others");

        if (boardStatus == BoardStatus.UNINITIATED) {
            // select next player as opponent of _player
            (uint256 index, address[] memory players) = Utils.getIndexOfLivingPlayers(_gameId, _player);
            address opponent;
            if (players.length > 1) {
                opponent = players[(index + 1) % players.length];
            }
            // if in whatever reason(someone surrendered) there are less than 2 players, we use 0 address as opponent.
            _initPieceOnBoard(_player, opponent);
            Game.setStatus(_gameId, GameStatus.INBATTLE);
            firstTurn = true;
        }
    }

    function endTurn(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken) private {
        if (_winner == 0) {
            _updateWhenBoardNotFinished(_player);
        } else {
            _updateWhenBoardFinished(_gameId, _player, _winner, _damageTaken);
            endRound(_gameId);
        }
    }

    function endRound(uint32 _gameId) private {
        if (_roundEnded(_gameId)) {
            _updateWhenRoundEnded(_gameId);
            endGame(_gameId);
        } else {
            _updateWhenRoundNotEnd();
        }
    }

    function endGame(uint32 _gameId) private {
        if (_gameFinished(_gameId)) {
            _updateWhenGameFinished(_gameId);
        } else {
            _updateWhenGameNotFinished(_gameId);
        }
    }

    function surrender() public {
        address player = _msgSender();
        require(PlayerGlobal.getStatus(player) == PlayerStatus.INGAME, "not in game");
        uint32 gameId = PlayerGlobal.getGameId(player);
        // require(Game.getStatus(gameId) == GameStatus.PREPARING, "only during preparing");

        BoardStatus boardStatus = Board.getStatus(player);
        if (boardStatus == BoardStatus.INBATTLE) {
            // clear board
            Utils.deleteAllPieces(player);
            // clear player
            Utils.clearPlayer(gameId, player);
            // check whether this round is ended and the game is finished
            endRound(gameId);
        } else if (boardStatus == BoardStatus.FINISHED) {
            // update finished board number
            Game.setFinishedBoard(gameId, Game.getFinishedBoard(gameId) - 1);
            // clear player
            Utils.clearPlayer(gameId, player);
            // at least one player is still in battle, so we don't need to check either of round or game status
        } else if (boardStatus == BoardStatus.UNINITIATED) {
            // clear player
            Utils.clearPlayer(gameId, player);
            // check whether game is finished
            endGame(gameId);
        }
    }

    function _initPieceOnBoard(address _player, address _opponent) internal {
        Board.set(
            _player,
            BoardData({
                enemy: _opponent,
                status: BoardStatus.INBATTLE,
                turn: 0,
                pieces: IWorld(_world()).initPieces(_player, true),
                enemyPieces: IWorld(_world()).initPieces(_opponent, false)
            })
        );
    }

    /**
     * @notice this round is not yet finished
     */
    function _updateWhenBoardNotFinished(address _player) internal {
        Board.setTurn(_player, Board.getTurn(_player) + 1);
    }

    function _updateWhenBoardFinished(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken)
        internal
    {
        // update board status
        Board.setStatus(_player, BoardStatus.FINISHED);

        // delete piece in battle
        Utils.deleteAllPieces(_player);

        // update player's health and streak
        Utils.updatePlayerStreakCount(_player, _winner);
        uint256 playerHealth = Utils.updatePlayerHealth(_player, _winner, _damageTaken);

        // clear player if it's defeated, update finishedBoard if else
        if (playerHealth == 0) {
            Utils.clearPlayer(_gameId, _player);
        } else {
            Game.setFinishedBoard(_gameId, Game.getFinishedBoard(_gameId) + 1);
        }
    }

    function _roundEnded(uint32 _gameId) private returns (bool) {
        return Game.getFinishedBoard(_gameId) == Game.lengthPlayers(_gameId);
    }

    function _updateWhenRoundNotEnd() internal {
        // do nothing
    }

    function _updateWhenRoundEnded(uint32 _gameId) internal {
        Game.setFinishedBoard(_gameId, 0);
        uint32 round = Game.getRound(_gameId);
        Game.setRound(_gameId, ++round);
        // update round time
        // loop each still living player in this game
        address[] memory players = Game.getPlayers(_gameId);
        uint256 num = players.length;
        for (uint256 i; i < num; ++i) {
            Board.deleteRecord(players[i]);
        }
        // settle round moved to _updateWhenGameNotFinished for saving gas
    }

    function _gameFinished(uint32 _gameId) private returns (bool) {
        return Game.lengthPlayers(_gameId) < 2;
    }

    function _updateWhenGameFinished(uint32 _gameId) internal {
        // push winner into GameRecord
        address[] memory players = Game.getPlayers(_gameId);
        uint256 num = players.length;
        assert(num < 2);
        if (num == 1) {
            address winner = players[0];
            Utils.clearPlayer(_gameId, winner);
        }
        Game.deleteRecord(_gameId);
    }

    function _updateWhenGameNotFinished(uint32 _gameId) internal {
        Game.setStatus(_gameId, GameStatus.PREPARING);
        uint32 roundInterval = GameConfig.getRoundInterval(0);
        Game.setStartFrom(_gameId, uint32(block.timestamp) + roundInterval);
        IWorld(_world()).settleRound(_gameId);
    }
}
