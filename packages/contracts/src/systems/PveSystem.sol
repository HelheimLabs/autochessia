// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {System} from "@latticexyz/world/src/System.sol";
import {SystemSwitch} from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";

import {IWorld} from "../codegen/world/IWorld.sol";
import {Creature, CreatureData, GameConfig, ShopConfig, Rank} from "../codegen/index.sol";
import {Board, BoardData} from "../codegen/index.sol";
import {Hero, HeroData} from "../codegen/index.sol";
import {Piece, PieceData} from "../codegen/index.sol";
import {GameRecord, Game, GameData} from "../codegen/index.sol";
import {PlayerGlobal, Player} from "../codegen/index.sol";
import {GameStatus, BoardStatus, PlayerStatus} from "src/codegen/common.sol";
import {Coordinate as Coord} from "cement/utils/Coordinate.sol";
import {RTPiece} from "../library/RunTimePiece.sol";
import {Utils} from "../library/Utils.sol";

contract PveSystem is System {
    function pveTick(uint32 _gameId, address _player) public {
        if (_singleTickInit(_gameId, _player)) {
            return;
        }

        (uint8 winner, uint256 damageTaken) =
            abi.decode(SystemSwitch.call(abi.encodeCall(IWorld(_world()).startBattle, (_player))), (uint8, uint256));

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
            SystemSwitch.call(abi.encodeCall(IWorld(_world())._botSetPiece, (_gameId, _player)));
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

            SystemSwitch.call(abi.encodeCall(IWorld(_world()).endRoundPublic, (_gameId)));
        }
    }

    function _initPieceOnBoardBot(address _player) internal {
        address bot = Utils.getBotAddress(_player);
        (bytes32[] memory allies, bytes32[] memory enemies) = abi.decode(
            SystemSwitch.call(abi.encodeCall(IWorld(_world()).initPieces, (_player, bot))), (bytes32[], bytes32[])
        );

        Board.set(
            _player,
            BoardData({enemy: bot, status: BoardStatus.INBATTLE, turn: 0, pieces: allies, enemyPieces: enemies})
        );
    }

    function _updateWhenBoardFinished(uint32 _gameId, address _player, uint256 _winner, uint256 _damageTaken)
        internal
    {
        uint32 turn = Board.getTurn(_player);

        // update board status  fix status
        Board.setStatus(_player, BoardStatus.UNINITIATED);

        // delete piece in battle
        Utils.deleteAllPieces(_player);

        // update player's health and streak
        Utils.updatePlayerStreakCount(_player, _winner);
        uint256 playerHealth = Utils.updatePlayerHealth(_player, _winner, _damageTaken);

        // clear player if it's defeated, update finishedBoard if else
        if (playerHealth == 0) {
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
