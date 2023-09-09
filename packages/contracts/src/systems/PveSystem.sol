// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig} from "../codegen/Tables.sol";
import {Board, BoardData} from "../codegen/Tables.sol";
import {Hero, HeroData} from "../codegen/Tables.sol";
import {Piece, PieceData} from "../codegen/Tables.sol";
import {GameRecord, Game, GameData} from "../codegen/Tables.sol";
import {PlayerGlobal, Player} from "../codegen/Tables.sol";
import {GameStatus, BoardStatus, PlayerStatus} from "../codegen/Types.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {RTPiece} from "../library/RunTimePiece.sol";
import {Utils} from "../library/Utils.sol";

contract PveSystem is System {
    function pveTick(uint32 _gameId, address _player) public {
        if (_singleTickInit(_gameId, _player)) {
            return;
        }

        (uint8 winner, uint256 damageTaken) = IWorld(_world()).startBattle(_player);

        endTurnForSinglePlayer(_gameId, _player, winner, damageTaken);
    }

    function _singleTickInit(uint32 _gameId, address _player) private returns (bool firstTurn) {
        require(PlayerGlobal.getStatus(_player) == PlayerStatus.INGAME, "not in game");
        require(PlayerGlobal.getGameId(_player) == _gameId, "mismatch game id");
        GameStatus gameStatus = Game.getStatus(_gameId);
        require(gameStatus != GameStatus.FINISHED, "bad game status");

        if (gameStatus == GameStatus.PREPARING) {
            require(block.timestamp >= Game.getStartFrom(_gameId), "preparing time");
        }
        BoardStatus boardStatus = Board.getStatus(_player);

        if (boardStatus == BoardStatus.UNINITIATED) {
            _botSetPiece(_gameId, _player);
            _initPieceOnBoardBot(_player);
            Game.setStatus(_gameId, GameStatus.INBATTLE);
            firstTurn = true;
        }
    }

    // TODO
    function endTurnForSinglePlayer(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken) private {
        if (_winner == 0) {
            Board.setTurn(_player, Board.getTurn(_player) + 1);
        } else {
            _updateWhenBoardFinished(_gameId, _player, _winner, _damageTaken);
            IWorld(_world()).endRoundPublic(_gameId);
        }
    }

    function _initPieceOnBoardBot(address _player) internal {
        address bot = Utils.getBotAddress(_player);
        (bytes32[] memory allies, bytes32[] memory enemies) = IWorld(_world()).initPieces(_player, bot);

        Board.set(
            _player,
            BoardData({enemy: bot, status: BoardStatus.INBATTLE, turn: 0, pieces: allies, enemyPieces: enemies})
        );
    }

    // TODO Upgrade piece with round
    function _botSetPiece(uint32 _gameId, address _player) internal {
        uint32 round = Game.getRound(_gameId);

        if (round % 2 == 1) {
            address bot = Utils.getBotAddress(_player);

            uint32 i = Player.getHeroOrderIdx(bot);

            bytes32 pieceKey = bytes32(uint256((uint160(bot) << 32) + ++i));

            Player.setHeroOrderIdx(bot, i);

            uint256 r = IWorld(_world()).getRandomNumberInGame(_gameId);

            uint32 x = uint32(r % 4);
            uint32 y = uint32((r / 4) % 8);

            // Utils.checkCorValidity(bot, x, y);

            // create piece
            Hero.set(pieceKey, uint24((r % 8 + 1)), x, y);
            // add piece to player
            Player.pushHeroes(bot, pieceKey);
        }
    }

    function _updateWhenBoardFinished(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken)
        internal
    {
        // update board status  fix status
        Board.setStatus(_player, BoardStatus.UNINITIATED);

        // delete piece in battle
        Utils.deleteAllPieces(_player);

        // update player's health and streak
        Utils.updatePlayerStreakCount(_player, _winner);
        uint256 playerHealth = Utils.updatePlayerHealth(_player, _winner, _damageTaken);

        // clear player if it's defeated, update finishedBoard if else
        if (playerHealth == 0) {
            Utils.clearPlayer(_gameId, _player);
            bool isSinglePlay = Game.getSingle(_gameId);
            if (isSinglePlay) {
                Utils.clearPlayer(_gameId, Utils.getBotAddress(_player));
            }
        } else {
            Game.setFinishedBoard(_gameId, Game.getFinishedBoard(_gameId) + 1);
        }
    }
}
