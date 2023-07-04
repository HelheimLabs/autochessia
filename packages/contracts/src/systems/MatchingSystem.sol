// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";
import { Player, Game, WaitingRoom, GameConfig, Board } from "../codegen/Tables.sol";
import { PlayerStatus, GameStatus } from "../codegen/Types.sol";

contract MatchingSystem is System {
    function joinRoom(bytes32 _roomId) public {
        require(_roomId != bytes32(0), "invalid room id");
        address player = _msgSender();
        require(Player.getStatus(player) == PlayerStatus.UNINITIATED, "still in game");
        bytes32 prevRoomId = Player.getRoomId(player);
        require(Player.getRoomId(player) != _roomId, "already in room");
        if (prevRoomId != bytes32(0)) {
            _leaveRoom(prevRoomId, player);
        }

        if (WaitingRoom.getPlayer1(_roomId) == address(0)) {
            WaitingRoom.setPlayer1(_roomId, player);
            Player.setRoomId(player, _roomId);
        } else {
            address player1 = WaitingRoom.getPlayer1(_roomId);
            // start a game
            startGame(player1, player);
            // delete waiting room
            WaitingRoom.deleteRecord(_roomId);
        }
    }

    function leaveRoom(bytes32 _roomId) public {
        require(_roomId != bytes32(0), "invalid room id");
        _leaveRoom(_roomId, _msgSender());
    }

    function _leaveRoom(bytes32 _roomId, address player) internal {
        if (WaitingRoom.getPlayer1(_roomId) == player) {
            WaitingRoom.deleteRecord(_roomId);
        }
    }

    function startGame(address _player1, address _player2) internal {
        uint32 gameIndex = GameConfig.getGameIndex();
        uint64 roundInterval = GameConfig.getRoundInterval();
        Game.set(
            gameIndex,
            _player1,
            _player2,
            GameStatus.PREPARING,
            0, // round
            uint64(block.number) + roundInterval, // start from
            0, // finished board
            0,  // winner
            0   // global random number, initially set it to 0
        );

        /// @dev request global random number
        /// @dev but skip some development network
        if (block.chainid != 31337) {
            IWorld(_world()).requestGlobalRandomNumber(gameIndex);
        }

        Player.set(_player1, bytes32(0), gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        Player.set(_player2, bytes32(0), gameIndex, PlayerStatus.INGAME, 100, 0, 0, 0, 0, new bytes32[](0), new uint64[](0), new uint64[](0));
        Board.setEnemy(_player1, _player2);
        Board.setEnemy(_player2, _player1);
        // init round 0 for each player
        IWorld(_world()).settleRound(gameIndex);
        GameConfig.setGameIndex(gameIndex+1);
    }
}