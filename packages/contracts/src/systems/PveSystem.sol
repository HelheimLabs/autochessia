// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig, ShopConfig, Rank} from "../codegen/Tables.sol";
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
        console2.log("block.timestamp", uint256(block.timestamp), Game.getStartFrom(_gameId));

        require(gameStatus != GameStatus.FINISHED, "bad game status");

        if (gameStatus == GameStatus.PREPARING) {
            require(uint256(block.timestamp) >= Game.getStartFrom(_gameId), "preparing time");
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

    function _getHeroIdx(address player) internal returns (bytes32 idx) {
        uint32 i = Player.getHeroOrderIdx(player);

        idx = bytes32(uint256((uint160(player) << 32) + ++i));

        Player.setHeroOrderIdx(player, i);
    }

    // TODO Upgrade piece with round
    function _botSetPiece(uint32 _gameId, address _player) internal {
        uint32 round = Game.getRound(_gameId);

        uint256[] memory r = Utils.getRandomValues(4);

        // if (round % 2 == 1) {
        address bot = Utils.getBotAddress(_player);

        bytes32 pieceKey = _getHeroIdx(_player);

        IWorld(_world()).refreshHeroes(bot);

        uint24 creatureId = Player.getItemHeroAltar(bot, r[2] % 5);

        uint32 x = uint32(r[0] % 4);
        uint32 y = uint32((r[1] / 4) % 8);

        // Utils.checkCorValidity(bot, x, y);

        // create piece
        Hero.set(pieceKey, creatureId, x, y);
        // add piece to player
        Player.pushHeroes(bot, pieceKey);
        // }
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
            uint32 turn = Board.getTurn(_player);
            uint32 score = Rank.getScore(_player);

            if (turn >= score) {
                console.log(turn, score, "score");
                Rank.set(_player, uint32(block.timestamp), turn);
            }
            Utils.clearPlayer(_gameId, Utils.getBotAddress(_player));
            Utils.clearPlayer(_gameId, _player);
        } else {
            Game.setFinishedBoard(_gameId, Game.getFinishedBoard(_gameId) + 1);
        }
    }
}
